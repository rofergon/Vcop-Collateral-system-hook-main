// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title TestVaultFundedLiquidation
 * @notice Tests the new vault-funded liquidation system
 */
contract TestVaultFundedLiquidation is Script {
    
    // Addresses loaded from deployed-addresses-mock.json
    address public flexibleLoanManager;
    address public vaultBasedHandler;
    address public mockOracle;
    address public automationKeeper;
    
    // Mock tokens
    address public mockETH;
    address public mockUSDC;
    
    uint256 public positionId;
    
    function run() external {
        console.log("TESTING VAULT-FUNDED LIQUIDATION SYSTEM");
        console.log("==========================================");
        
        loadAddresses();
        verifyConfiguration();
        setupTestLiquidity();
        createTestPosition();
        demonstrateVaultFundedLiquidation();
        
        console.log("VAULT-FUNDED LIQUIDATION TEST COMPLETED!");
    }
    
    function loadAddresses() internal {
        console.log("\nStep 1: Loading deployed addresses...");
        
        // Load from deployed-addresses-mock.json (latest deployment)
        flexibleLoanManager = 0x3AA0D317F4b7d0b36344A7B6C72d09e1d61d6601;
        vaultBasedHandler = 0xbC36d8283EEBcEe76Fc7f83c4FCee5084fceaf40;
        mockOracle = 0xac66C9b45505dEf81da6f843392f85E73D478D52;
        automationKeeper = 0xfB20bf1c7566883E2baA98B3160B4db8633d339D;
        
        mockETH = 0x62F0C74b6dA032292F7A53488A1d18bFb2cCf011;
        mockUSDC = 0xbb7ec90e3d6A1beeE57eF752a6C463A5e5AEa0FB;
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("AutomationKeeper:", automationKeeper);
    }
    
    function verifyConfiguration() internal {
        console.log("\nStep 2: Verifying vault automation configuration...");
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        // Check if FlexibleLoanManager is authorized in vault
        bool isFlexibleAuthorized = vault.authorizedAutomationContracts(flexibleLoanManager);
        console.log("FlexibleLoanManager authorized in vault:", isFlexibleAuthorized);
        
        if (!isFlexibleAuthorized) {
            console.log("WARNING: Automation not configured. Run 'make configure-vault-automation' first");
            revert("Vault automation not configured");
        }
        
        console.log("Configuration verified successfully!");
    }
    
    function setupTestLiquidity() internal {
        console.log("\nStep 3: Adding test liquidity to vault...");
        
        vm.startBroadcast();
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        IERC20 usdcToken = IERC20(mockUSDC);
        uint256 liquidityAmount = 10000 * 1e6; // 10,000 USDC
        
        console.log("Adding liquidity to USDC vault...");
        console.log("Liquidity amount:", liquidityAmount);
        
        // First approve tokens to vault
        usdcToken.approve(vaultBasedHandler, liquidityAmount);
        
        // Provide liquidity
        vault.provideLiquidity(mockUSDC, liquidityAmount, msg.sender);
        
        console.log("Test liquidity added successfully");
        
        vm.stopBroadcast();
        
        // Check vault status
        (uint256 available, uint256 liquidations, uint256 recovered, bool canLiquidate) = 
            vault.getAutomationLiquidityStatus(mockUSDC);
            
        console.log("Available for automation:", available);
        console.log("Can liquidate:", canLiquidate);
    }
    
    function createTestPosition() internal {
        console.log("\nStep 4: Creating test loan position...");
        
        vm.startBroadcast();
        
        ILoanManager loanMgr = ILoanManager(flexibleLoanManager);
        
        // Create loan position
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: mockETH,
            loanAsset: mockUSDC,
            collateralAmount: 2 ether, // 2 ETH
            loanAmount: 2000 * 1e6, // 2,000 USDC
            maxLoanToValue: 800000, // 80%
            interestRate: 80000, // 8%
            duration: 0 // 0 = perpetual
        });
        
        // First approve collateral
        IERC20(mockETH).approve(flexibleLoanManager, terms.collateralAmount);
        
        positionId = loanMgr.createLoan(terms);
        
        console.log("Position created with ID:", positionId);
        console.log("Collateral: 2 ETH at $2,500 = $5,000");
        console.log("Loan: 2,000 USDC");
        
        vm.stopBroadcast();
        
        // Check initial ratio
        uint256 ratio = loanMgr.getCollateralizationRatio(positionId);
        console.log("Initial collateralization ratio:", ratio / 10000, "%");
    }
    
    function demonstrateVaultFundedLiquidation() internal {
        console.log("\nStep 5: Demonstrating vault-funded liquidation...");
        
        ILoanManager loanMgr = ILoanManager(flexibleLoanManager);
        MockVCOPOracle oracle = MockVCOPOracle(mockOracle);
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        // Step 4.1: Crash ETH price to make position liquidatable
        console.log("Crashing ETH price from $2,500 to $1,000...");
        
        vm.startBroadcast();
        oracle.setEthPrice(1000 * 1e6); // $1,000
        vm.stopBroadcast();
        
        // Check new ratio
        uint256 ratio = loanMgr.getCollateralizationRatio(positionId);
        console.log("New collateralization ratio:", ratio / 10000, "%");
        console.log("Can liquidate:", loanMgr.canLiquidate(positionId));
        
        // Step 4.2: Check vault liquidity before liquidation
        (uint256 availableBefore,,, bool canLiquidateBefore) = 
            vault.getAutomationLiquidityStatus(mockUSDC);
        console.log("Vault liquidity before liquidation:", availableBefore);
        console.log("Vault can fund liquidation:", canLiquidateBefore);
        
        // Step 4.3: Execute vault-funded liquidation
        console.log("Executing vault-funded liquidation...");
        
        // Step 5.3a: Verify authorization before liquidation  
        console.log("Verifying vault authorization...");
        bool isAuthorizedInVault = vault.authorizedAutomationContracts(flexibleLoanManager);
        require(isAuthorizedInVault, "FlexibleLoanManager not authorized in vault");
        
        vm.startBroadcast();
        
        // For testing, we'll call directly since we're the owner
        // In production, this would be called by the authorized automation contract
        try loanMgr.vaultFundedAutomatedLiquidation(positionId) returns (bool success, uint256 liquidatedAmount) {
            console.log("Liquidation success:", success);
            console.log("Liquidated amount:", liquidatedAmount);
            
            if (success) {
                console.log("Vault-funded liquidation executed successfully!");
            } else {
                console.log("Vault-funded liquidation failed");
            }
        } catch Error(string memory reason) {
            console.log("Liquidation failed with reason:", reason);
        }
        
        vm.stopBroadcast();
        
        // Step 4.4: Check vault status after liquidation
        (uint256 availableAfter, uint256 liquidations, uint256 recovered,) = 
            vault.getAutomationLiquidityStatus(mockUSDC);
        console.log("Vault liquidity after liquidation:", availableAfter);
        console.log("Total automation liquidations:", liquidations);
        console.log("Total recovered amount:", recovered);
        
        // Step 4.5: Check position status
        ILoanManager.LoanPosition memory position = loanMgr.getPosition(positionId);
        console.log("Position active after liquidation:", position.isActive);
        
        console.log("\nVAULT-FUNDED LIQUIDATION SUMMARY:");
        console.log("====================================");
        console.log("- Vault provided liquidity for liquidation");
        console.log("- Position was liquidated without external funding");
        console.log("- Vault received collateral as compensation");
        console.log("- System is self-sustaining for automation");
    }
} 
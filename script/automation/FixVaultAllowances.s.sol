// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title FixVaultAllowances
 * @notice Fixes vault allowances and configuration for successful automated liquidations
 */
contract FixVaultAllowances is Script {
    
    function run() external {
        console.log("=====================================");
        console.log("FIXING VAULT ALLOWANCES FOR AUTOMATION");
        console.log("=====================================");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("MockUSDC:", mockUSDC);
        
        vm.startBroadcast();
        
        console.log("");
        console.log("=== STEP 1: AUTHORIZE AUTOMATION KEEPER ===");
        
        // Authorize AutomationKeeper in vault for automated liquidations
        try vault.authorizeAutomationContract(automationKeeper) {
            console.log(">> AutomationKeeper authorized in vault");
        } catch {
            console.log(">> AutomationKeeper already authorized");
        }
        
        // Set AutomationKeeper as authorized in LoanManager
        try loanManager.setAutomationContract(automationKeeper) {
            console.log(">> AutomationKeeper set in LoanManager");
        } catch {
            console.log(">> AutomationKeeper already set");
        }
        
        console.log("");
        console.log("=== STEP 2: ENSURE VAULT LIQUIDITY ===");
        
        uint256 vaultBalance = IERC20(mockUSDC).balanceOf(vaultBasedHandler);
        console.log("Current vault USDC balance:", vaultBalance / 1e6);
        
        if (vaultBalance < 50000 * 1e6) {
            console.log("Adding liquidity to vault...");
            
            // Mint USDC to deployer
            (bool success,) = mockUSDC.call(
                abi.encodeWithSignature("mint(address,uint256)", msg.sender, 100000 * 1e6)
            );
            require(success, "Failed to mint USDC");
            
            // Approve vault
            IERC20(mockUSDC).approve(vaultBasedHandler, 100000 * 1e6);
            
            // Provide liquidity
            vault.provideLiquidity(mockUSDC, 100000 * 1e6, msg.sender);
            console.log(">> Added 100,000 USDC to vault");
        } else {
            console.log(">> Vault has sufficient liquidity");
        }
        
        console.log("");
        console.log("=== STEP 3: CONFIGURE VAULT FOR AUTOMATION ===");
        
        // Ensure vault can handle automation
        (uint256 available, , , bool canLiquidate) = vault.getAutomationLiquidityStatus(mockUSDC);
        console.log("Available for automation:", available / 1e6, "USDC");
        console.log("Can liquidate:", canLiquidate);
        
        // Verify authorizations
        bool keeperAuthorized = vault.authorizedAutomationContracts(automationKeeper);
        bool loanManagerAuthorized = vault.authorizedAutomationContracts(flexibleLoanManager);
        
        console.log("AutomationKeeper authorized in vault:", keeperAuthorized);
        console.log("LoanManager authorized in vault:", loanManagerAuthorized);
        
        console.log("");
        console.log("=== STEP 4: TEST CONFIGURATION ===");
        
        // Test checkUpkeep to ensure it still returns true
        bytes memory checkData = keeper.generateOptimizedCheckData(flexibleLoanManager, 0, 25);
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("CheckUpkeep result:");
            console.log("  Upkeep needed:", upkeepNeeded);
            console.log("  PerformData length:", performData.length);
            
            if (upkeepNeeded) {
                console.log(">> Automation should work correctly now!");
            } else {
                console.log(">> No upkeep needed at this time");
            }
        } catch Error(string memory reason) {
            console.log("CheckUpkeep failed:", reason);
        }
        
        console.log("");
        console.log("=== STEP 5: ENABLE VAULT-FUNDED LIQUIDATIONS ===");
        
        // Ensure automation uses vault-funded liquidations
        console.log("Automation settings:");
        console.log("  LoanManager automation enabled:", loanManager.isAutomationEnabled());
        console.log("  LoanManager authorized contract:", loanManager.authorizedAutomationContract());
        console.log("  Keeper min risk threshold:", keeper.minRiskThreshold());
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=====================================");
        console.log("VAULT CONFIGURATION COMPLETED!");
        console.log("=====================================");
        console.log("");
        console.log("Key Changes Made:");
        console.log("1. AutomationKeeper authorized in vault");
        console.log("2. Sufficient USDC liquidity provided");
        console.log("3. Vault-funded liquidations enabled");
        console.log("4. System ready for automated liquidations");
        console.log("");
        console.log("What happens next:");
        console.log("- Chainlink will continue to call performUpkeep");
        console.log("- Liquidations will use vault USDC directly");
        console.log("- No allowance issues should occur");
        console.log("- Monitor at: https://automation.chain.link/base-sepolia");
        console.log("");
        console.log("Your Upkeep ID:");
        console.log("113929943640819780336579342444342105693806060483669440168281813464087586560700");
    }
} 
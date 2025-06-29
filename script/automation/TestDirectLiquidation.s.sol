// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";

/**
 * @title TestDirectLiquidation
 * @notice Prueba directamente vaultFundedAutomatedLiquidation para identificar el fallo específico
 */
contract TestDirectLiquidation is Script {
    
    address public flexibleLoanManager;
    address public automationAdapter;
    address public vaultBasedHandler;
    address public automationKeeper;
    address public mockUSDC;
    
    function run() external {
        console.log("=== TESTING DIRECT LIQUIDATION ===");
        console.log("");
        
        loadAddresses();
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        testDirectLiquidation();
        
        vm.stopBroadcast();
    }
    
    function loadAddresses() internal {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        automationAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("AutomationAdapter:", automationAdapter);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("");
    }
    
    function testDirectLiquidation() internal {
        console.log("=== DIRECT LIQUIDATION TEST ===");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        // Test position 6 (should be liquidatable)
        uint256 testPositionId = 6;
        
        console.log("Testing liquidation of position", testPositionId);
        console.log("");
        
        // Step 1: Check position status
        console.log("STEP 1: Position Status Check");
        checkPositionStatus(testPositionId);
        
        // Step 2: Check cooldowns
        console.log("STEP 2: Cooldown Check");
        checkCooldowns(testPositionId);
        
        // Step 3: Check vault authorization chain
        console.log("STEP 3: Authorization Chain Check");
        checkAuthorizationChain();
        
        // Step 4: Test direct liquidation via adapter
        console.log("STEP 4: Direct Liquidation via Adapter");
        testAdapterLiquidation(testPositionId);
        
        // Step 5: Test direct liquidation via FlexibleLoanManager
        console.log("STEP 5: Direct Liquidation via FlexibleLoanManager");
        testLoanManagerLiquidation(testPositionId);
    }
    
    function checkPositionStatus(uint256 positionId) internal view {
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        try loanManager.getPosition(positionId) returns (FlexibleLoanManager.LoanPosition memory position) {
            console.log("Position exists:", position.borrower != address(0));
            console.log("Position active:", position.isActive);
            console.log("Collateral:", position.collateralAmount / 1e18, "ETH");
            console.log("Loan amount:", position.loanAmount / 1e6, "USDC");
            
            // Check total debt
            try loanManager.getTotalDebt(positionId) returns (uint256 totalDebt) {
                console.log("Total debt:", totalDebt / 1e6, "USDC");
            } catch {
                console.log("Error getting total debt");
            }
            
            // Check ratio
            try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
                console.log("Collateral ratio:", ratio / 10000, "%");
            } catch {
                console.log("Error getting ratio");
            }
            
            // Check if liquidatable
            try loanManager.canLiquidate(positionId) returns (bool canLiq) {
                console.log("Can liquidate:", canLiq);
            } catch {
                console.log("Error checking liquidation status");
            }
            
            // Check tracking
            bool isTracked = adapter.isPositionTracked(positionId);
            console.log("Tracked in adapter:", isTracked);
        } catch {
            console.log("Error getting position");
        }
        
        console.log("");
    }
    
    function checkCooldowns(uint256 positionId) internal view {
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        console.log("Checking cooldown periods...");
        
        // Get liquidation cooldown
        uint256 cooldown = adapter.liquidationCooldown();
        console.log("Liquidation cooldown:", cooldown, "seconds");
        
        // Get last liquidation attempt (this may not be accessible, but let's try)
        try adapter.lastLiquidationAttempt(positionId) returns (uint256 lastAttempt) {
            console.log("Last liquidation attempt:", lastAttempt);
            console.log("Current timestamp:", block.timestamp);
            
            if (lastAttempt > 0) {
                uint256 timeSinceAttempt = block.timestamp - lastAttempt;
                console.log("Time since last attempt:", timeSinceAttempt, "seconds");
                console.log("Cooldown satisfied:", timeSinceAttempt >= cooldown);
            } else {
                console.log("No previous liquidation attempts");
            }
        } catch {
            console.log("Could not check last liquidation attempt");
        }
        
        console.log("");
    }
    
    function checkAuthorizationChain() internal view {
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        console.log("Checking authorization chain...");
        
        // Check automation enabled
        bool automationEnabled = loanManager.isAutomationEnabled();
        console.log("LoanManager automation enabled:", automationEnabled);
        
        // Check authorized contract
        address authorizedContract = loanManager.authorizedAutomationContract();
        console.log("Authorized automation contract:", authorizedContract);
        console.log("Should be AutomationKeeper:", automationKeeper);
        console.log("Authorization correct:", authorizedContract == automationKeeper);
        
        // Check vault authorization
        bool lmAuthorizedInVault = vault.authorizedAutomationContracts(flexibleLoanManager);
        console.log("LoanManager authorized in vault:", lmAuthorizedInVault);
        
        // Check vault liquidity
        try vault.getAutomationLiquidityStatus(mockUSDC) returns (
            uint256 available,
            uint256 totalLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("Vault USDC available:", available / 1e6, "USDC");
            console.log("Vault can liquidate:", canLiquidate);
        } catch {
            console.log("Error checking vault liquidity");
        }
        
        console.log("");
    }
    
    function testAdapterLiquidation(uint256 positionId) internal {
        console.log("Testing liquidation via AutomationAdapter...");
        
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        try adapter.vaultFundedAutomatedLiquidation(positionId) returns (bool success, uint256 liquidatedAmount) {
            console.log("Adapter liquidation result:", success);
            console.log("Liquidated amount:", liquidatedAmount / 1e6, "USDC");
            
            if (success) {
                console.log("[SUCCESS] Position liquidated via adapter!");
            } else {
                console.log("[FAILED] Adapter liquidation returned false");
            }
        } catch Error(string memory reason) {
            console.log("[ERROR] Adapter liquidation failed:", reason);
        } catch {
            console.log("[ERROR] Adapter liquidation failed with unknown error");
        }
        
        console.log("");
    }
    
    function testLoanManagerLiquidation(uint256 positionId) internal {
        console.log("Testing liquidation via FlexibleLoanManager...");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        
        // First check if position still exists
        try loanManager.getPosition(positionId) returns (FlexibleLoanManager.LoanPosition memory position) {
            if (!position.isActive) {
                console.log("Position already liquidated by adapter test");
                return;
            }
        } catch {
            console.log("Position no longer exists");
            return;
        }
        
        try loanManager.vaultFundedAutomatedLiquidation(positionId) returns (bool success, uint256 liquidatedAmount) {
            console.log("LoanManager liquidation result:", success);
            console.log("Liquidated amount:", liquidatedAmount / 1e6, "USDC");
            
            if (success) {
                console.log("[SUCCESS] Position liquidated via LoanManager!");
            } else {
                console.log("[FAILED] LoanManager liquidation returned false");
            }
        } catch Error(string memory reason) {
            console.log("[ERROR] LoanManager liquidation failed:", reason);
        } catch {
            console.log("[ERROR] LoanManager liquidation failed with unknown error");
        }
        
        console.log("");
    }
} 
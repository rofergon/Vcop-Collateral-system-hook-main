// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title TestManualPerformUpkeep
 * @notice Prueba manualmente performUpkeep para identificar dónde falla el proceso
 */
contract TestManualPerformUpkeep is Script {
    
    address public automationKeeper;
    address public automationAdapter;
    address public flexibleLoanManager;
    address public vaultBasedHandler;
    address public mockUSDC;
    
    function run() external {
        console.log("=== TESTING MANUAL PERFORMUPKEEP ===");
        console.log("");
        
        loadAddresses();
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        testPerformUpkeepExecution();
        
        vm.stopBroadcast();
    }
    
    function loadAddresses() internal {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        automationAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        console.log("AutomationKeeper:", automationKeeper);
        console.log("AutomationAdapter:", automationAdapter);
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("");
    }
    
    function testPerformUpkeepExecution() internal {
        console.log("=== MANUAL PERFORMUPKEEP TEST ===");
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        // First get checkUpkeep data
        bytes memory checkData = abi.encode(automationAdapter, uint256(1), uint256(10));
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("Step 1 - CheckUpkeep result:", upkeepNeeded);
            console.log("PerformData length:", performData.length);
            
            if (!upkeepNeeded || performData.length == 0) {
                console.log("[ERROR] CheckUpkeep failed - no liquidations needed");
                return;
            }
            
            // Decode performData to see what positions are being liquidated
            (address loanManager, uint256[] memory positions, uint256[] memory riskLevels, uint256 timestamp) = 
                abi.decode(performData, (address, uint256[], uint256[], uint256));
                
            console.log("");
            console.log("Step 2 - PerformData decoded:");
            console.log("Loan Manager:", loanManager);
            console.log("Positions to liquidate:", positions.length);
            
            for (uint256 i = 0; i < positions.length && i < 3; i++) {
                console.log("  Position", positions[i], "- Risk Level:", riskLevels[i]);
            }
            
            console.log("");
            console.log("Step 3 - Vault status before liquidation:");
            checkVaultStatus();
            
            console.log("");
            console.log("Step 4 - Executing performUpkeep...");
            
            // Execute performUpkeep manually
            try keeper.performUpkeep(performData) {
                console.log("[SUCCESS] PerformUpkeep executed successfully!");
                
                console.log("");
                console.log("Step 5 - Checking results:");
                checkLiquidationResults(positions);
                
            } catch Error(string memory reason) {
                console.log("[ERROR] PerformUpkeep failed:", reason);
                
                console.log("");
                console.log("Step 5 - Diagnosing failure:");
                diagnoseLiquidationFailure(positions[0]); // Test first position
                
            } catch (bytes memory lowLevelData) {
                console.log("[ERROR] PerformUpkeep failed with low-level error");
                console.log("Error data length:", lowLevelData.length);
            }
            
        } catch Error(string memory reason) {
            console.log("[ERROR] CheckUpkeep failed:", reason);
        }
    }
    
    function checkVaultStatus() internal view {
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        try vault.getAutomationLiquidityStatus(mockUSDC) returns (
            uint256 available,
            uint256 totalLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("Vault USDC available:", available / 1e6, "USDC");
            console.log("Can liquidate:", canLiquidate);
            console.log("Previous liquidations:", totalLiquidations);
            
            if (!canLiquidate) {
                console.log("[PROBLEM] Vault cannot liquidate!");
            }
        } catch {
            console.log("[ERROR] Could not get vault status");
        }
        
        // Check authorization
        bool isAuthorized = vault.authorizedAutomationContracts(flexibleLoanManager);
        console.log("FlexibleLoanManager authorized in vault:", isAuthorized);
        
        if (!isAuthorized) {
            console.log("[PROBLEM] FlexibleLoanManager not authorized in vault!");
        }
    }
    
    function checkLiquidationResults(uint256[] memory positions) internal view {
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        console.log("Checking liquidation results:");
        
        uint256 liquidatedCount = 0;
        
        for (uint256 i = 0; i < positions.length && i < 3; i++) {
            uint256 positionId = positions[i];
            
            try loanManager.getPosition(positionId) returns (FlexibleLoanManager.LoanPosition memory position) {
                if (!position.isActive) {
                    console.log("Position", positionId, ": LIQUIDATED [SUCCESS]");
                    liquidatedCount++;
                } else {
                    console.log("Position", positionId, ": Still active [FAILED]");
                    
                    // Check why it wasn't liquidated
                    try loanManager.canLiquidate(positionId) returns (bool canLiq) {
                        console.log("  Can still liquidate:", canLiq);
                    } catch {}
                }
            } catch {
                console.log("Position", positionId, ": Error getting status");
            }
        }
        
        console.log("");
        console.log("Total liquidated:", liquidatedCount, "/", positions.length);
        
        // Check vault statistics
        try vault.getAutomationLiquidityStatus(mockUSDC) returns (
            uint256 available,
            uint256 totalLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("Vault liquidations after:", totalLiquidations);
            console.log("Vault available after:", available / 1e6, "USDC");
        } catch {
            console.log("Error getting final vault status");
        }
    }
    
    function diagnoseLiquidationFailure(uint256 positionId) internal view {
        console.log("Diagnosing liquidation failure for position", positionId, ":");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        // Check position status
        try loanManager.getPosition(positionId) returns (FlexibleLoanManager.LoanPosition memory position) {
            console.log("Position exists and active:", position.isActive);
            
            if (position.isActive) {
                // Check if still liquidatable
                try loanManager.canLiquidate(positionId) returns (bool canLiq) {
                    console.log("Can liquidate:", canLiq);
                } catch Error(string memory reason) {
                    console.log("canLiquidate failed:", reason);
                }
                
                // Check debt amount
                try loanManager.getTotalDebt(positionId) returns (uint256 totalDebt) {
                    console.log("Total debt:", totalDebt / 1e6, "USDC");
                    
                    // Check if vault has enough liquidity
                    try vault.getAutomationLiquidityStatus(mockUSDC) returns (
                        uint256 available,
                        uint256 totalLiquidations,
                        uint256 totalRecovered,
                        bool canLiquidate
                    ) {
                        console.log("Vault available:", available / 1e6, "USDC");
                        console.log("Sufficient funds:", available >= totalDebt);
                    } catch {
                        console.log("Error checking vault liquidity");
                    }
                } catch {
                    console.log("Error getting total debt");
                }
                
                // Check collateralization ratio
                try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
                    console.log("Current ratio:", ratio / 10000, "%");
                } catch {
                    console.log("Error getting ratio");
                }
            }
        } catch {
            console.log("Error getting position data");
        }
        
        // Check automation authorization
        address authorizedContract = loanManager.authorizedAutomationContract();
        console.log("Authorized automation contract:", authorizedContract);
        console.log("Should be AutomationKeeper:", automationKeeper);
        console.log("Authorization correct:", authorizedContract == automationKeeper);
    }
} 
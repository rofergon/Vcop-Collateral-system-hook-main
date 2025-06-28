// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";

/**
 * @title DiagnoseCheckUpkeep
 * @notice Diagnostica exactamente por qué checkUpkeep no está funcionando
 */
contract DiagnoseCheckUpkeep is Script {
    
    uint256 constant POSITION_ID = 3;
    
    function run() external view {
        console.log("=== DIAGNOSE CHECKUPKEEP ISSUE ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        
        console.log("CONTRACTS:");
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("");
        
        // ========== 1. CHECK KEEPER CONFIGURATION ==========
        console.log("1. KEEPER CONFIGURATION");
        console.log("========================");
        
        try keeper.emergencyPause() returns (bool isPaused) {
            console.log("Emergency Paused:", isPaused ? "YES (PROBLEM!)" : "NO");
        } catch {
            console.log("Could not check emergency pause");
        }
        
        try keeper.registeredManagers(flexibleLoanManager) returns (bool isRegistered) {
            console.log("LoanManager Registered:", isRegistered ? "YES" : "NO (PROBLEM!)");
        } catch {
            console.log("Could not check manager registration");
        }
        
        console.log("");
        
        // ========== 2. CHECK ADAPTER CONFIGURATION ==========
        console.log("2. ADAPTER CONFIGURATION");
        console.log("========================");
        
        try adapter.isAutomationEnabled() returns (bool enabled) {
            console.log("Automation Enabled:", enabled ? "YES" : "NO (PROBLEM!)");
        } catch {
            console.log("Could not check automation enabled");
        }
        
        try adapter.getTotalActivePositions() returns (uint256 total) {
            console.log("Total Tracked Positions:", total);
        } catch {
            console.log("Could not get total positions");
        }
        
        try adapter.isPositionTracked(POSITION_ID) returns (bool tracked) {
            console.log("Position 3 Tracked:", tracked ? "YES" : "NO (PROBLEM!)");
        } catch {
            console.log("Could not check if position tracked");
        }
        
        console.log("");
        
        // ========== 3. GENERATE AND TEST CHECKDATA ==========
        console.log("3. CHECKDATA TESTING");
        console.log("====================");
        
        // Generate checkData
        bytes memory checkData = keeper.generateOptimizedCheckData(
            loanAdapter,  // Should point to adapter, not loan manager
            0,
            25
        );
        
        console.log("Generated CheckData:");
        console.logBytes(checkData);
        console.log("");
        
        // Decode checkData to verify
        try keeper.decodeCheckData(checkData) returns (
            address targetManager,
            uint256 startIndex,
            uint256 batchSize
        ) {
            console.log("Decoded CheckData:");
            console.log("  Target Manager:", targetManager);
            console.log("  Start Index:", startIndex);
            console.log("  Batch Size:", batchSize);
            console.log("");
            
            // Check if target matches adapter
            if (targetManager == loanAdapter) {
                console.log("SUCCESS: CheckData points to LoanAdapter (CORRECT)");
            } else if (targetManager == flexibleLoanManager) {
                console.log("ERROR: CheckData points to FlexibleLoanManager (INCORRECT!)");
                console.log("   It should point to LoanAdapter:", loanAdapter);
            } else {
                console.log("ERROR: CheckData points to unknown address");
            }
        } catch {
            console.log("Could not decode checkData");
        }
        
        console.log("");
        
        // ========== 4. MANUAL CHECKUPKEEP TEST ==========
        console.log("4. MANUAL CHECKUPKEEP TEST");
        console.log("==========================");
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("Upkeep Needed:", upkeepNeeded ? "YES" : "NO");
            console.log("PerformData Length:", performData.length);
            
            if (!upkeepNeeded) {
                console.log("");
                console.log("ERROR: checkUpkeep returns false");
                console.log("   Debugging why...");
                
                // Test adapter directly
                console.log("");
                console.log("5. ADAPTER DIRECT TEST");
                console.log("======================");
                
                try adapter.getPositionsInRange(0, 10) returns (uint256[] memory positions) {
                    console.log("Positions in range 0-10:", positions.length);
                    for (uint256 i = 0; i < positions.length && i < 5; i++) {
                        console.log("  Position", i + 1, "ID:", positions[i]);
                        
                        try adapter.isPositionAtRisk(positions[i]) returns (bool isAtRisk, uint256 riskLevel) {
                            console.log("    At Risk:", isAtRisk ? "YES" : "NO");
                            console.log("    Risk Level:", riskLevel);
                        } catch {
                            console.log("    Could not check risk");
                        }
                    }
                } catch {
                    console.log("Could not get positions from adapter");
                }
            }
        } catch Error(string memory reason) {
            console.log("checkUpkeep failed:", reason);
        } catch {
            console.log("checkUpkeep failed with unknown error");
        }
        
        console.log("");
        console.log("=== DIAGNOSIS COMPLETE ===");
    }
} 
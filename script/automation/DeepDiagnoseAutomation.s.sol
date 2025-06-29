// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title DeepDiagnoseAutomation
 * @notice Diagnóstico profundo para entender exactamente por qué no funciona el automation
 */
contract DeepDiagnoseAutomation is Script {
    
    function run() external view {
        console.log("=== DEEP AUTOMATION DIAGNOSIS ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        console.log("CONTRACTS:");
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        // ========== 1. VERIFY LOAN ADAPTER REGISTRATION ==========
        console.log("1. LOAN ADAPTER REGISTRATION CHECK");
        console.log("===================================");
        
        try keeper.registeredManagers(loanAdapter) returns (bool isRegistered) {
            console.log("LoanAdapter Registered:", isRegistered ? "YES" : "NO (PROBLEM!)");
            
            if (isRegistered) {
                try keeper.managerPriority(loanAdapter) returns (uint256 priority) {
                    console.log("LoanAdapter Priority:", priority);
                } catch {
                    console.log("Could not get priority");
                }
            }
        } catch {
            console.log("Could not check LoanAdapter registration");
        }
        
        console.log("");
        
        // ========== 2. VERIFY AUTOMATION INTERFACE ==========
        console.log("2. AUTOMATION INTERFACE VERIFICATION");
        console.log("====================================");
        
        try adapter.isAutomationEnabled() returns (bool enabled) {
            console.log("Adapter Automation Enabled:", enabled ? "YES" : "NO");
        } catch {
            console.log("Adapter does not implement isAutomationEnabled");
        }
        
        try adapter.getTotalActivePositions() returns (uint256 total) {
            console.log("Adapter Total Positions:", total);
        } catch {
            console.log("Adapter does not implement getTotalActivePositions");
        }
        
        console.log("");
        
        // ========== 3. DETAILED CHECKUPKEEP SIMULATION ==========
        console.log("3. DETAILED CHECKUPKEEP SIMULATION");
        console.log("===================================");
        
        // Generate correct checkData pointing to LoanAdapter
        bytes memory checkData = abi.encode(loanAdapter, uint256(0), uint256(25));
        
        console.log("CheckData (pointing to LoanAdapter):");
        console.logBytes(checkData);
        console.log("");
        
        // Test checkUpkeep step by step
        console.log("Step-by-step checkUpkeep simulation:");
        
        // Check 1: Emergency pause
        try keeper.emergencyPause() returns (bool isPaused) {
            console.log("  Step 1 - Emergency Pause:", isPaused ? "PAUSED (BLOCKED)" : "NOT PAUSED (OK)");
            if (isPaused) {
                console.log("    PROBLEM: Emergency pause is active!");
                return;
            }
        } catch {
            console.log("  Step 1 - Could not check emergency pause");
        }
        
        // Check 2: Manager registration
        try keeper.registeredManagers(loanAdapter) returns (bool isRegistered) {
            console.log("  Step 2 - Manager Registered:", isRegistered ? "YES (OK)" : "NO (BLOCKED)");
            if (!isRegistered) {
                console.log("    PROBLEM: LoanAdapter is not registered!");
                return;
            }
        } catch {
            console.log("  Step 2 - Could not check manager registration");
        }
        
        // Check 3: Automation enabled on adapter
        try adapter.isAutomationEnabled() returns (bool enabled) {
            console.log("  Step 3 - Automation Enabled:", enabled ? "YES (OK)" : "NO (BLOCKED)");
            if (!enabled) {
                console.log("    PROBLEM: Automation is disabled on adapter!");
                return;
            }
        } catch {
            console.log("  Step 3 - Could not check automation enabled");
        }
        
        // Check 4: Total positions
        try adapter.getTotalActivePositions() returns (uint256 total) {
            console.log("  Step 4 - Total Positions:", total);
            if (total == 0) {
                console.log("    PROBLEM: No positions to check!");
                return;
            }
        } catch {
            console.log("  Step 4 - Could not get total positions");
        }
        
        // Check 5: Get positions in range
        try adapter.getPositionsInRange(1, 50) returns (uint256[] memory positions) {
            console.log("  Step 5 - Positions in range 1-50:", positions.length);
            
            if (positions.length == 0) {
                console.log("    PROBLEM: No positions found in range!");
                return;
            }
            
            // Check 6: Verify positions at risk
            uint256 riskCount = 0;
            for (uint256 i = 0; i < positions.length && i < 5; i++) {
                                 try adapter.isPositionAtRisk(positions[i]) returns (bool isAtRisk, uint256 riskLevel) {
                     console.log("    Position ID:", positions[i]);
                     console.log("      At Risk:", isAtRisk ? "YES" : "NO");
                     console.log("      Risk Level:", riskLevel);
                    
                    if (isAtRisk && riskLevel >= 85) { // Default threshold
                        riskCount++;
                    }
                                 } catch {
                     console.log("    Position ID:", positions[i]);
                     console.log("      Could not check risk");
                 }
            }
            
            console.log("  Step 6 - Liquidatable positions:", riskCount);
            
            if (riskCount == 0) {
                console.log("    PROBLEM: No positions meet risk threshold!");
            }
            
        } catch {
            console.log("  Step 5 - Could not get positions in range");
        }
        
        console.log("");
        
        // ========== 4. FINAL CHECKUPKEEP TEST ==========
        console.log("4. FINAL CHECKUPKEEP TEST");
        console.log("=========================");
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("Final Result:");
            console.log("  Upkeep Needed:", upkeepNeeded ? "YES - SUCCESS!" : "NO - FAILED");
            console.log("  PerformData Length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("  SUCCESS: checkUpkeep is working!");
                console.log("  The automation should now trigger on Chainlink!");
            } else {
                console.log("  FAILED: checkUpkeep still returns false");
                console.log("  Check the step-by-step results above for the cause");
            }
        } catch Error(string memory reason) {
            console.log("checkUpkeep failed with error:", reason);
        } catch {
            console.log("checkUpkeep failed with unknown error");
        }
        
        console.log("");
        console.log("=== DEEP DIAGNOSIS COMPLETE ===");
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title ManualCheckUpkeepTest
 * @notice Simula exactamente el flujo de checkUpkeep paso a paso
 */
contract ManualCheckUpkeepTest is Script {
    
    function run() external view {
        console.log("=== MANUAL CHECKUPKEEP SIMULATION ===");
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
        
        // SIMULATE EXACT CHECKUPKEEP LOGIC
        console.log("SIMULATING CHECKUPKEEP LOGIC:");
        console.log("==============================");
        
        // Step 1: Decode checkData
        bytes memory checkData = abi.encode(loanAdapter, uint256(0), uint256(10));
        console.log("CheckData:");
        console.logBytes(checkData);
        
        (address loanManager, uint256 startIndex, uint256 batchSize) = 
            abi.decode(checkData, (address, uint256, uint256));
        
        console.log("Decoded - Manager:", loanManager);
        console.log("Decoded - StartIndex:", startIndex);
        console.log("Decoded - BatchSize:", batchSize);
        console.log("");
        
        // Step 2: Check emergency pause
        try keeper.emergencyPause() returns (bool isPaused) {
            console.log("Step 2 - Emergency Pause:", isPaused ? "PAUSED" : "OK");
            if (isPaused) return;
        } catch {
            console.log("Step 2 - Could not check pause");
        }
        
        // Step 3: Check registration
        try keeper.registeredManagers(loanManager) returns (bool isRegistered) {
            console.log("Step 3 - Manager Registered:", isRegistered ? "YES" : "NO");
            if (!isRegistered) {
                console.log("PROBLEM: Manager not registered!");
                return;
            }
        } catch {
            console.log("Step 3 - Could not check registration");
        }
        
        // Step 4: Check automation enabled
        try adapter.isAutomationEnabled() returns (bool enabled) {
            console.log("Step 4 - Automation Enabled:", enabled ? "YES" : "NO");
            if (!enabled) {
                console.log("PROBLEM: Automation disabled!");
                return;
            }
        } catch {
            console.log("Step 4 - Could not check automation");
        }
        
        // Step 5: Get total positions
        try adapter.getTotalActivePositions() returns (uint256 total) {
            console.log("Step 5 - Total Positions:", total);
            if (total == 0) {
                console.log("PROBLEM: No positions!");
                return;
            }
        } catch {
            console.log("Step 5 - Could not get total");
        }
        
        console.log("");
        
        // Step 6: THE CRITICAL CONVERSION
        console.log("Step 6 - INDEX CONVERSION (THE PROBLEM!):");
        console.log("==========================================");
        uint256 startPositionId = startIndex == 0 ? 1 : startIndex; // This is the bug!
        console.log("Original startIndex:", startIndex);
        console.log("Converted startPositionId:", startPositionId);
        console.log("This is WRONG for adapter - should stay 0!");
        console.log("");
        
        // Step 7: Calculate batch size
        uint256 optimalBatchSize = batchSize > 0 ? batchSize : 20;
        uint256 endPositionId = startPositionId + optimalBatchSize - 1;
        console.log("Step 7 - Batch Calculation:");
        console.log("Optimal batch size:", optimalBatchSize);
        console.log("End position ID:", endPositionId);
                 console.log("Will call getPositionsInRange with start:", startPositionId);
         console.log("And end:", endPositionId);
        console.log("");
        
        // Step 8: Get positions with WRONG indices
        console.log("Step 8 - Get Positions (WRONG INDICES):");
        console.log("========================================");
        try adapter.getPositionsInRange(startPositionId, endPositionId) returns (uint256[] memory positions) {
            console.log("Positions found with WRONG indices:", positions.length);
            console.log("This should be 0 because we're searching indices 1-10");
            console.log("But position is at array index 0");
        } catch {
            console.log("getPositionsInRange failed");
        }
        
        // Step 9: Test with CORRECT indices
        console.log("");
        console.log("Step 9 - Get Positions (CORRECT INDICES):");
        console.log("==========================================");
        try adapter.getPositionsInRange(0, 9) returns (uint256[] memory positions) {
            console.log("Positions found with CORRECT indices:", positions.length);
            console.log("This should be 1 - our position at index 0");
            
            if (positions.length > 0) {
                console.log("Position ID found:", positions[0]);
                
                // Check if it's at risk
                try adapter.isPositionAtRisk(positions[0]) returns (bool isAtRisk, uint256 riskLevel) {
                    console.log("Position at risk:", isAtRisk ? "YES" : "NO");
                    console.log("Risk level:", riskLevel);
                    
                    try keeper.minRiskThreshold() returns (uint256 threshold) {
                        console.log("Meets threshold:", riskLevel >= threshold ? "YES" : "NO");
                        
                        if (isAtRisk && riskLevel >= threshold) {
                            console.log("");
                            console.log("SUCCESS: If we used correct indices, automation would work!");
                        }
                    } catch {}
                } catch {
                    console.log("Could not check risk");
                }
            }
        } catch {
            console.log("getPositionsInRange(0,9) failed");
        }
        
        console.log("");
        console.log("=== CONCLUSION ===");
        console.log("The AutomationKeeper converts startIndex=0 to startPositionId=1");
        console.log("But the adapter needs array indices starting from 0");
        console.log("This is the root cause of the problem!");
    }
} 
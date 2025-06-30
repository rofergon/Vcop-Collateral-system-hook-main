// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title TestAdapterIndexing
 * @notice Verifica y corrige el problema de indexación en el adapter
 */
contract TestAdapterIndexing is Script {
    
    function run() external view {
        console.log("=== ADAPTER INDEXING TEST ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        // ========== 1. CHECK TRACKING DATA ==========
        console.log("1. ADAPTER TRACKING DATA");
        console.log("========================");
        
        try adapter.getTotalActivePositions() returns (uint256 total) {
            console.log("Total Tracked Positions:", total);
            
            if (total > 0) {
                console.log("");
                console.log("Testing different ranges:");
                
                // Test range 0-10 (array indices)
                try adapter.getPositionsInRange(0, 10) returns (uint256[] memory positions) {
                    console.log("Range 0-10 (array indices):", positions.length);
                    for (uint256 i = 0; i < positions.length && i < 3; i++) {
                        console.log("  Index", i, "Position ID:", positions[i]);
                        
                        // Verify position tracking
                        try adapter.isPositionTracked(positions[i]) returns (bool tracked) {
                            console.log("    Tracked:", tracked ? "YES" : "NO");
                        } catch {
                            console.log("    Could not check tracking");
                        }
                    }
                } catch {
                    console.log("Range 0-10: FAILED");
                }
                
                console.log("");
                
                // Test range 1-50 (what automation uses)
                try adapter.getPositionsInRange(1, 50) returns (uint256[] memory positions) {
                    console.log("Range 1-50 (automation range):", positions.length);
                    for (uint256 i = 0; i < positions.length && i < 3; i++) {
                        console.log("  Position ID:", positions[i]);
                    }
                } catch {
                    console.log("Range 1-50: FAILED");
                }
                
                console.log("");
                
                // Check specific position
                console.log("2. SPECIFIC POSITION CHECK");
                console.log("==========================");
                
                uint256 positionId = 3;
                try adapter.isPositionTracked(positionId) returns (bool tracked) {
                    console.log("Position 3 Tracked:", tracked ? "YES" : "NO");
                    
                    if (tracked) {
                        try adapter.positionIndexMap(positionId) returns (uint256 index) {
                            console.log("Position 3 Array Index:", index);
                        } catch {
                            console.log("Could not get array index");
                        }
                    }
                } catch {
                    console.log("Could not check Position 3 tracking");
                }
                
            } else {
                console.log("No positions tracked - this is the problem!");
            }
            
        } catch {
            console.log("Could not get total positions");
        }
        
        console.log("");
        console.log("3. DIAGNOSIS");
        console.log("============");
        console.log("The issue is likely:");
        console.log("- getPositionsInRange expects ARRAY INDICES (0,1,2...)");
        console.log("- But automation is passing POSITION IDS (1,50)");
        console.log("- Position 3 is at array index 0");
        console.log("- So range(1,50) finds nothing, range(0,0) finds position 3");
        
        console.log("");
        console.log("=== TEST COMPLETE ===");
    }
} 
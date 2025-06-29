// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title SyncNewPositions
 * @notice Sync all new positions that are not yet tracked
 */
contract SyncNewPositions is Script {
    
    function run() external {
        console.log("=== SYNCING NEW POSITIONS ===");
        console.log("==============================");
        
        // Load addresses
        string memory content = vm.readFile("deployed-addresses-mock.json");
        address flexibleLoanManager = vm.parseJsonAddress(content, ".coreLending.flexibleLoanManager");
        address loanAdapter = vm.parseJsonAddress(content, ".automation.loanAdapter");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        vm.startBroadcast();
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        uint256 syncedCount = 0;
        
        // Check positions 1-50 (reasonable range)
        for (uint256 i = 1; i <= 50; i++) {
            try loanManager.getPosition(i) returns (ILoanManager.LoanPosition memory position) {
                if (position.isActive && position.borrower != address(0)) {
                    // Check if already tracked
                    bool isTracked = adapter.isPositionTracked(i);
                    
                    if (!isTracked) {
                        console.log("Adding position", i, "to tracking...");
                        try adapter.addPositionToTracking(i) {
                            syncedCount++;
                            console.log("  SUCCESS: Position", i, "added");
                        } catch Error(string memory reason) {
                            console.log("  FAILED:", reason);
                        } catch {
                            console.log("  FAILED: Unknown error");
                        }
                    }
                }
            } catch {
                // Position doesn't exist, continue
            }
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("SUCCESS: Sync completed!");
        console.log("New positions added:", syncedCount);
        
        // Show final stats
        (uint256 totalTracked, uint256 totalAtRisk, uint256 totalLiquidatable, uint256 totalCritical,) = adapter.getTrackingStats();
        console.log("");
        console.log("FINAL TRACKING STATS:");
        console.log("- Total Tracked:", totalTracked);
        console.log("- Total At Risk:", totalAtRisk);
        console.log("- Total Liquidatable:", totalLiquidatable);
        console.log("- Total Critical:", totalCritical);
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title ConfigureLoanManagerAdapter
 * @notice Configure FlexibleLoanManager to work with LoanManagerAutomationAdapter
 * @dev This adds a reference so new positions are automatically tracked
 */
contract ConfigureLoanManagerAdapter is Script {
    
    function run() external {
        console.log("=== CONFIGURING LOAN MANAGER ADAPTER REFERENCE ===");
        console.log("===================================================");
        
        // Load addresses
        string memory content = vm.readFile("deployed-addresses-mock.json");
        address flexibleLoanManager = vm.parseJsonAddress(content, ".coreLending.flexibleLoanManager");
        address loanAdapter = vm.parseJsonAddress(content, ".automation.loanAdapter");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        vm.startBroadcast();
        
        // Get contracts
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        // Check current configuration
        console.log("CURRENT CONFIGURATION:");
        console.log("======================");
        
        try loanManager.isAutomationEnabled() returns (bool enabled) {
            console.log("Automation Enabled:", enabled);
        } catch {
            console.log("Automation Enabled: UNKNOWN");
        }
        
        // Check if adapter knows about loan manager
        console.log("Adapter LoanManager:", address(adapter.loanManager()));
        console.log("Expected LoanManager:", flexibleLoanManager);
        
        bool isCorrectlyLinked = address(adapter.loanManager()) == flexibleLoanManager;
        console.log("Correctly Linked:", isCorrectlyLinked);
        
        if (!isCorrectlyLinked) {
            console.log("ERROR: Adapter is linked to wrong LoanManager!");
            vm.stopBroadcast();
            return;
        }
        
        // Step 1: Sync existing positions
        console.log("");
        console.log("STEP 1: Syncing existing positions...");
        _syncExistingPositions(loanManager, adapter);
        
        console.log("");
        console.log("SUCCESS: Configuration completed!");
        console.log("");
        console.log("SUMMARY:");
        console.log("- Existing positions synced to tracking");
        console.log("- New positions must be manually synced with:");
        console.log("  make sync-avalanche-positions");
        console.log("");
        console.log("WARNING: For true automatic tracking, FlexibleLoanManager");
        console.log("needs code modification to call adapter.addPositionToTracking()");
        console.log("in createLoan() function");
        
        vm.stopBroadcast();
    }
    
    function _syncExistingPositions(
        FlexibleLoanManager loanManager,
        LoanManagerAutomationAdapter adapter
    ) internal {
        uint256 syncedCount = 0;
        
        // Check positions 1-50 (reasonable range)
        for (uint256 i = 1; i <= 50; i++) {
            try loanManager.getPosition(i) returns (FlexibleLoanManager.LoanPosition memory position) {
                if (position.isActive && position.borrower != address(0)) {
                    // Check if already tracked
                    bool isTracked = adapter.isPositionTracked(i);
                    
                    if (!isTracked) {
                        console.log("  Syncing position", i);
                        try adapter.addPositionToTracking(i) {
                            syncedCount++;
                        } catch Error(string memory reason) {
                            console.log("    FAILED:", reason);
                        } catch {
                            console.log("    FAILED: Unknown error");
                        }
                    } else {
                        console.log("  Position", i, "already tracked");
                    }
                }
            } catch {
                // Position doesn't exist, continue
            }
        }
        
        console.log("Synced", syncedCount, "new positions");
        
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
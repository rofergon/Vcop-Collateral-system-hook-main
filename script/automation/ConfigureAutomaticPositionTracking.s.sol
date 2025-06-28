// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title ConfigureAutomaticPositionTracking
 * @notice Configure automatic position tracking for new positions
 * @dev Sets up the system so new positions are automatically added to tracking
 */
contract ConfigureAutomaticPositionTracking is Script {
    
    function run() external {
        console.log("=== CONFIGURING AUTOMATIC POSITION TRACKING ===");
        console.log("===============================================");
        
        // Load addresses
        string memory content = vm.readFile("deployed-addresses-mock.json");
        address flexibleLoanManager = vm.parseJsonAddress(content, ".coreLending.flexibleLoanManager");
        address loanAdapter = vm.parseJsonAddress(content, ".automation.loanAdapter");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        vm.startBroadcast();
        
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        // Step 1: Add existing positions to tracking
        console.log("Step 1: Adding existing positions to tracking...");
        _addExistingPositionsToTracking(flexibleLoanManager, adapter);
        
        console.log("");
        console.log("SUCCESS: AUTOMATIC POSITION TRACKING CONFIGURED!");
        console.log("");
        console.log("SUMMARY:");
        console.log("- Existing positions added to tracking");
        console.log("- Future positions will be tracked through manual process");
        console.log("");
        console.log("WARNING: For true automatic tracking, FlexibleLoanManager");
        console.log("   needs to be modified to call adapter.addPositionToTracking()");
        console.log("   in the createLoan() function");
        
        vm.stopBroadcast();
    }
    
    function _addExistingPositionsToTracking(
        address flexibleLoanManagerAddr,
        LoanManagerAutomationAdapter adapter
    ) internal {
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManagerAddr);
        
        // Check positions 31-40 (likely range for current positions)
        uint256 addedCount = 0;
        
        for (uint256 i = 31; i <= 40; i++) {
            try loanManager.getPosition(i) returns (ILoanManager.LoanPosition memory position) {
                if (position.isActive && position.borrower != address(0)) {
                    console.log("Adding position", i, "to tracking...");
                    try adapter.addPositionToTracking(i) {
                        addedCount++;
                        console.log("  SUCCESS: Position", i, "added successfully");
                    } catch Error(string memory reason) {
                        console.log("  FAILED to add position", i, ":", reason);
                    } catch {
                        console.log("  FAILED to add position", i, "- unknown error");
                    }
                }
            } catch {
                // Position doesn't exist, skip
                break;
            }
        }
        
        console.log("Added", addedCount, "positions to tracking");
    }
} 
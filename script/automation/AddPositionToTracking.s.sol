// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title AddPositionToTracking
 * @notice Add position 30 to LoanAdapter tracking
 */
contract AddPositionToTracking is Script {
    
    function run() external {
        console.log("=== ADDING POSITION 30 TO TRACKING ===");
        console.log("======================================");
        
        // Load LoanAdapter address
        string memory content = vm.readFile("deployed-addresses-mock.json");
        address loanAdapter = vm.parseJsonAddress(content, ".automation.loanAdapter");
        
        console.log("LoanAdapter:", loanAdapter);
        console.log("Adding Position ID: 30");
        
        // Start broadcasting
        vm.startBroadcast();
        
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        // Add position 30 to tracking
        adapter.addPositionToTracking(30);
        
        vm.stopBroadcast();
        
        console.log("SUCCESS: Position 30 added to tracking!");
        console.log("");
        console.log("Now test checkUpkeep again:");
        console.log("make test-avalanche-checkupkeep");
    }
} 
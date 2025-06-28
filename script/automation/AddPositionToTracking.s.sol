// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title AddPositionToTracking
 * @notice Agrega la posición 3 al tracking del adapter para que el automation la detecte
 */
contract AddPositionToTracking is Script {
    
    uint256 constant POSITION_ID = 3; // Position created by avalanche-quick-test
    
    function run() external {
        console.log("=== ADDING POSITION TO AUTOMATION TRACKING ===");
        console.log("");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        console.log("LoanAdapter:", loanAdapter);
        console.log("Position ID to track:", POSITION_ID);
        console.log("");
        
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        vm.startBroadcast();
        
        // Add position to tracking
        console.log("Adding position to tracking...");
        adapter.addPositionToTracking(POSITION_ID);
        
        vm.stopBroadcast();
        
        console.log("SUCCESS: Position", POSITION_ID, "added to tracking!");
        console.log("");
        console.log("Now the automation should detect this liquidatable position.");
        console.log("Check the Chainlink dashboard within 1-2 minutes for execution.");
    } 
} 
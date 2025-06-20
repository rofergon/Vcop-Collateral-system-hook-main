// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

contract RegisterLoanManagerInAutomation is Script {
    
    function run() external {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        
        console.log("Registering LoanManager in AutomationKeeper...");
        console.log("  AutomationKeeper:", automationKeeper);
        console.log("  FlexibleLoanManager:", flexibleLoanManager);
        
        vm.startBroadcast();
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        // Register with priority 100 (highest)
        keeper.registerLoanManager(flexibleLoanManager, 100);
        
        vm.stopBroadcast();
        
        console.log("FlexibleLoanManager registered successfully!");
    }
} 
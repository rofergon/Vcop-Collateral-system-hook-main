// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title RegisterLoanAdapter
 * @notice Registra el LoanAdapter en el AutomationKeeper para que funcione el checkData
 */
contract RegisterLoanAdapter is Script {
    
    function run() external {
        console.log("=== REGISTERING LOAN ADAPTER IN AUTOMATION KEEPER ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        vm.startBroadcast();
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        // Register the LoanAdapter with high priority
        keeper.registerLoanManager(loanAdapter, 100); // Max priority
        
        console.log("SUCCESS: LoanAdapter registered with priority 100");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== REGISTRATION COMPLETE ===");
        console.log("Now the checkData pointing to LoanAdapter should work!");
    }
} 
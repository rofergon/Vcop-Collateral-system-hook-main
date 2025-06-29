// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";

/**
 * @title SetAutomationAdapterReference
 * @notice Configure FlexibleLoanManager with automation adapter reference for automatic tracking
 * @dev This enables automatic position tracking when new positions are created
 */
contract SetAutomationAdapterReference is Script {
    
    function run() external {
        console.log("=== SETTING AUTOMATION ADAPTER REFERENCE ===");
        console.log("=============================================");
        
        // Load addresses
        string memory content = vm.readFile("deployed-addresses-mock.json");
        address flexibleLoanManager = vm.parseJsonAddress(content, ".coreLending.flexibleLoanManager");
        address loanAdapter = vm.parseJsonAddress(content, ".automation.loanAdapter");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        vm.startBroadcast();
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        
        // Check current configuration
        console.log("CURRENT CONFIGURATION:");
        console.log("======================");
        
        address currentAdapter = loanManager.automationAdapter();
        console.log("Current Automation Adapter:", currentAdapter);
        console.log("Target Automation Adapter:", loanAdapter);
        
        if (currentAdapter == loanAdapter) {
            console.log("Automation adapter already configured correctly!");
            vm.stopBroadcast();
            return;
        }
        
        // Set the automation adapter reference
        console.log("");
        console.log("SETTING AUTOMATION ADAPTER REFERENCE:");
        console.log("====================================");
        
        loanManager.setAutomationAdapter(loanAdapter);
        
        console.log("SUCCESS: Automation adapter reference set!");
        
        // Verify configuration
        address newAdapter = loanManager.automationAdapter();
        console.log("");
        console.log("VERIFICATION:");
        console.log("=============");
        console.log("New Automation Adapter:", newAdapter);
        console.log("Configuration Correct:", newAdapter == loanAdapter);
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("SUCCESS: AUTOMATION ADAPTER REFERENCE CONFIGURED!");
        console.log("");
        console.log("AUTOMATIC POSITION TRACKING ENABLED!");
        console.log("====================================");
        console.log("From now on, when createLoan() is called:");
        console.log("1. Position will be created normally");
        console.log("2. Position will be AUTOMATICALLY added to automation tracking");
        console.log("3. Chainlink automation will monitor it for liquidation");
        console.log("");
        console.log("No more manual sync required!");
    }
} 
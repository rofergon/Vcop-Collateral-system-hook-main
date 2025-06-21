// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract ManualCheckData is Script {
    
    function run() external view {
        console.log("=== MANUAL CHECKDATA GENERATION FOR REBUILT SYSTEM ===");
        console.log("");
        
        // Load NEW deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        console.log("REBUILT SYSTEM ADDRESSES:");
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        console.log("=== CHAINLINK UPKEEP UPDATE INFO ===");
        console.log("");
        console.log("Current Upkeep ID:");
        console.log("46805872671117145146553122992407690125028698493033788667420198686266813282039");
        console.log("");
        
        console.log("OLD AutomationKeeper (to replace):");
        console.log("0xDfab700985Fd7666047e28D5374609F04c0780e2");
        console.log("");
        
        console.log("NEW AutomationKeeper (use this):");
        console.log(automationKeeper);
        console.log("");
        
        // Generate checkData manually
        bytes memory checkData = abi.encode(loanAdapter, 0, 25);
        
        console.log("NEW CheckData (hex):");
        console.logBytes(checkData);
        console.log("");
        
        // Pretty print for easy copying
        console.log("NEW CheckData (formatted for Chainlink UI):");
        string memory hexString = vm.toString(checkData);
        console.log(hexString);
        console.log("");
        
        console.log("=== STEP-BY-STEP UPDATE INSTRUCTIONS ===");
        console.log("");
        console.log("1. Go to: https://automation.chain.link/");
        console.log("2. Connect your wallet");
        console.log("3. Find upkeep ID: 46805872671117145146553122992407690125028698493033788667420198686266813282039");
        console.log("4. Click 'Edit' or 'Manage'");
        console.log("5. Update these fields:");
        console.log("   - Target Contract:", automationKeeper);
        console.log("   - Check Data: (copy hex above)");
        console.log("   - Gas Limit: 2000000 (keep same)");
        console.log("6. Save changes");
        console.log("");
        console.log("=== VERIFICATION ===");
        console.log("After update, the upkeep should call the NEW AutomationKeeper");
        console.log("which will monitor the NEW FlexibleLoanManager");
        console.log("");
        console.log("System is READY for automated liquidations!");
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

interface IAutomationKeeper {
    function generateOptimizedCheckData(
        address loanManager,
        uint256 startIndex,
        uint256 batchSize
    ) external pure returns (bytes memory);
}

contract GenerateNewCheckData is Script {
    
    function run() external {
        console.log("=== GENERATING CHECKDATA FOR REBUILT SYSTEM ===");
        console.log("");
        
        // Load NEW deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        console.log("NEW SYSTEM ADDRESSES:");
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        IAutomationKeeper keeper = IAutomationKeeper(automationKeeper);
        
        // Generate checkData for FlexibleLoanManager
        console.log("=== CHECKDATA FOR CHAINLINK UPKEEP ===");
        
        bytes memory checkData = keeper.generateOptimizedCheckData(
            loanAdapter,  // Use LoanAdapter as the target
            0,           // startIndex (0 = auto-start from position 1)
            25           // batchSize
        );
        
        console.log("Target Contract (for Chainlink):", automationKeeper);
        console.log("CheckData (hex):");
        console.logBytes(checkData);
        console.log("");
        
        // Manual checkData generation for reference
        bytes memory manualCheckData = abi.encode(loanAdapter, 0, 25);
        console.log("Manual CheckData (should be same):");
        console.logBytes(manualCheckData);
        console.log("");
        
        console.log("=== CHAINLINK UPKEEP UPDATE INSTRUCTIONS ===");
        console.log("1. Go to https://automation.chain.link/");
        console.log("2. Find your upkeep ID: 46805872671117145146553122992407690125028698493033788667420198686266813282039");
        console.log("3. UPDATE these settings:");
        console.log("   Target Contract:", automationKeeper);
        console.log("   CheckData: (copy the hex above)");
        console.log("   Gas Limit: 2000000 (unchanged)");
        console.log("");
        console.log("=== SYSTEM READY FOR AUTOMATION ===");
        console.log("New system is fully deployed and configured!");
    }
} 
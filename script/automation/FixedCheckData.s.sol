// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract FixedCheckData is Script {
    
    function run() external view {
        console.log("=== FIXED CHECKDATA GENERATION ===");
        console.log("");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        
        console.log("Target Contract (AutomationKeeper):");
        console.log(automationKeeper);
        console.log("");
        
        console.log("LoanAdapter being monitored:");
        console.log(loanAdapter);
        console.log("");
        
        // Generate checkData: abi.encode(loanAdapter, startIndex=0, batchSize=25)
        bytes memory checkData = abi.encode(loanAdapter, uint256(0), uint256(25));
        
        console.log("CheckData details:");
        console.log("- loanAdapter:", loanAdapter);
        console.log("- startIndex: 0");
        console.log("- batchSize: 25");
        console.log("");
        
        console.log("CheckData length:", checkData.length);
        console.log("");
        
        // Print each component separately to avoid line breaks
        console.log("=== COPY THIS CHECKDATA (without line breaks) ===");
        
        // Convert to hex manually to ensure no line breaks
        bytes memory hexChars = "0123456789abcdef";
        bytes memory result = new bytes(2 + checkData.length * 2);
        result[0] = "0";
        result[1] = "x";
        
        for (uint256 i = 0; i < checkData.length; i++) {
            result[2 + i * 2] = hexChars[uint8(checkData[i]) / 16];
            result[2 + i * 2 + 1] = hexChars[uint8(checkData[i]) % 16];
        }
        
        console.log("CHECKDATA (copy this entire line):");
        console.log(string(result));
        console.log("");
        
        console.log("=== CHAINLINK UPDATE INSTRUCTIONS ===");
        console.log("1. Go to: https://automation.chain.link/");
        console.log("2. Find upkeep: 46805872671117145146553122992407690125028698493033788667420198686266813282039");
        console.log("3. Update:");
        console.log("   Target Contract:", automationKeeper);
        console.log("   Check Data: (copy the line above starting with 0x)");
        console.log("   Gas Limit: 2000000");
        console.log("");
        console.log("IMPORTANT: Copy the entire hex string in one line without spaces or breaks!");
    }
} 
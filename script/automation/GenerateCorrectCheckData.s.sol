// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title GenerateCorrectCheckData
 * @notice Genera el checkData CORRECTO usando índices de array 0-based
 */
contract GenerateCorrectCheckData is Script {
    
    function run() external view {
        console.log("=== CORRECT CHECKDATA GENERATOR ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        // ========== GENERATE CORRECT CHECKDATA ==========
        console.log("CORRECT CHECKDATA FOR CHAINLINK:");
        console.log("=================================");
        
        // Use array indices: startIndex=0, batchSize=10
        // This will search array indices 0-9, which includes position at index 0
        bytes memory correctCheckData = keeper.generateOptimizedCheckData(
            loanAdapter,  // LoanAdapter address
            0,           // startIndex (array index, not position ID)
            10           // batchSize (reasonable batch for array indices)
        );
        
        console.log("Target Contract (Keeper):");
        console.log(automationKeeper);
        console.log("");
        
        console.log("CORRECT CheckData (use this):");
        console.logBytes(correctCheckData);
        console.log("");
        
        // Verify this checkData works
        console.log("VERIFICATION:");
        console.log("=============");
        
        try keeper.checkUpkeep(correctCheckData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("Upkeep Needed:", upkeepNeeded ? "YES - SUCCESS!" : "NO - Still broken");
            console.log("PerformData Length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("");
                console.log("SUCCESS! This checkData works!");
                console.log("Your automation should now trigger!");
            } else {
                console.log("");
                console.log("Still not working - there may be another issue");
            }
        } catch Error(string memory reason) {
            console.log("checkUpkeep failed:", reason);
        }
        
        console.log("");
        console.log("=== INSTRUCTIONS ===");
        console.log("1. Copy the CheckData hex above");
        console.log("2. Go to your Chainlink upkeep in the dashboard");
        console.log("3. Update the Check Data with the correct hex");
        console.log("4. Save and wait for automation to trigger");
        
        console.log("");
        console.log("=== DASHBOARD LINKS ===");
        console.log("Avalanche Fuji Dashboard:");
        console.log("https://automation.chain.link/avalanche-fuji");
        
        console.log("");
        console.log("=== GENERATION COMPLETE ===");
    }
} 
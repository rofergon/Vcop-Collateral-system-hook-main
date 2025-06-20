// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";

/**
 * @title FixAutomationKeeper
 * @notice Script to fix automation keeper configuration
 */
contract FixAutomationKeeper is Script {
    
    function run() external {
        console.log("FIXING AUTOMATION KEEPER CONFIGURATION");
        console.log("=====================================");
        
        // Read addresses from JSON
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        
        console.log("AutomationKeeper:", automationKeeper);
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        
        vm.startBroadcast();
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        
        // Check current state
        console.log("");
        console.log("=== CHECKING CURRENT STATE ===");
        
        // Check if manager is registered
        try keeper.registeredManagers(flexibleLoanManager) returns (bool isRegistered) {
            console.log("Manager is registered:", isRegistered);
        } catch {
            console.log("ERROR: Cannot check if manager is registered");
        }
        
        // Re-register the loan manager (safe to call multiple times)
        console.log("");
        console.log("=== RE-REGISTERING LOAN MANAGER ===");
        try keeper.registerLoanManager(flexibleLoanManager, 100) {
            console.log("Loan manager re-registered successfully");
        } catch Error(string memory reason) {
            console.log("Failed to register loan manager:", reason);
        }
        
        // Test position count
        console.log("");
        console.log("=== TESTING POSITION ACCESS ===");
        try loanManager.nextPositionId() returns (uint256 nextId) {
            console.log("Next position ID:", nextId);
            console.log("Estimated active positions:", nextId > 0 ? nextId - 1 : 0);
        } catch Error(string memory reason) {
            console.log("Failed to get next position ID:", reason);
        }
        
        // Test position details if any exist
        try loanManager.nextPositionId() returns (uint256 nextId) {
            if (nextId > 1) {
                console.log("Testing position 1...");
                try loanManager.canLiquidate(1) returns (bool canLiquidate) {
                    console.log("Position 1 can liquidate:", canLiquidate);
                    
                    try loanManager.getCollateralizationRatio(1) returns (uint256 ratio) {
                        console.log("Position 1 collateralization ratio:", ratio);
                    } catch Error(string memory reason) {
                        console.log("Failed to get collateralization ratio:", reason);
                    }
                } catch Error(string memory reason) {
                    console.log("Failed to check if position can liquidate:", reason);
                }
            }
        } catch {
            console.log("Could not access position data");
        }
        
        // Test automation keeper
        console.log("");
        console.log("=== TESTING AUTOMATION KEEPER ===");
        
        // Prepare checkUpkeep data
        bytes memory checkData = abi.encode(flexibleLoanManager, 0, 1); // start=0, batch=1
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("CheckUpkeep success! Upkeep needed:", upkeepNeeded);
            console.log("Perform data length:", performData.length);
        } catch Error(string memory reason) {
            console.log("CheckUpkeep failed:", reason);
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== AUTOMATION KEEPER FIX COMPLETED ===");
    }
} 
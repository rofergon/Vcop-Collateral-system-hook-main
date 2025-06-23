// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title FixAutomationAdapter
 * @notice Fixes LoanAdapter configuration to track positions properly
 */
contract FixAutomationAdapter is Script {
    
    function run() external {
        console.log("=================================");
        console.log("FIXING AUTOMATION ADAPTER CONFIG");
        console.log("=================================");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        
        console.log("LoanAdapter:", loanAdapter);
        console.log("AutomationKeeper:", automationKeeper);
        
        vm.startBroadcast();
        
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        console.log("");
        console.log("Step 1: Configuring adapter...");
        
        // Set automation contract in adapter
        adapter.setAutomationContract(address(keeper));
        console.log(">> Automation contract set in adapter");
        
        // Enable automation
        adapter.setAutomationEnabled(true);
        console.log(">> Automation enabled in adapter");
        
        // Add existing positions to tracking
        console.log("");
        console.log("Step 2: Adding positions to tracking...");
        
        // Add test positions (2, 3, 4) to adapter tracking
        uint256[] memory positionIds = new uint256[](3);
        positionIds[0] = 2;
        positionIds[1] = 3;
        positionIds[2] = 4;
        
        adapter.initializePositionTracking(positionIds);
        console.log(">> Positions 2, 3, 4 added to adapter tracking");
        
        console.log("");
        console.log("Step 3: Configuring keeper...");
        
        // Register adapter in keeper
        try keeper.registerLoanManager(address(adapter), 100) {
            console.log(">> Adapter registered in keeper");
        } catch {
            console.log(">> Adapter already registered");
        }
        
        // Verify configuration
        console.log("");
        console.log("Step 4: Verification...");
        console.log("Adapter automation enabled:", adapter.isAutomationEnabled());
        console.log("Adapter authorized contract:", adapter.authorizedAutomationContract());
        console.log("Total tracked positions:", adapter.getTotalActivePositions());
        
        vm.stopBroadcast();
        
        console.log("");
        console.log(">> AUTOMATION ADAPTER FIXED!");
        console.log("");
        console.log("Next steps:");
        console.log("1. Test automation: make test-automation-flow");
        console.log("2. Check Chainlink dashboard for upkeep execution");
        console.log("3. Monitor positions at: https://automation.chain.link/base-sepolia");
    }
} 
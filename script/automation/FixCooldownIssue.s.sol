// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title FixCooldownIssue
 * @notice Reduce el cooldown de liquidación para permitir liquidaciones automáticas más frecuentes
 */
contract FixCooldownIssue is Script {
    
    address public automationAdapter;
    address public automationKeeper;
    
    function run() external {
        console.log("=== FIXING COOLDOWN ISSUE ===");
        console.log("");
        
        loadAddresses();
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        fixCooldowns();
        
        vm.stopBroadcast();
        
        verifyCooldowns();
        
        console.log("=== COOLDOWN FIX COMPLETED ===");
    }
    
    function loadAddresses() internal {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        automationAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        
        console.log("AutomationAdapter:", automationAdapter);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("");
    }
    
    function fixCooldowns() internal {
        console.log("=== REDUCING COOLDOWN PERIODS ===");
        
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        // Check current cooldowns
        uint256 currentAdapterCooldown = adapter.liquidationCooldown();
        uint256 currentKeeperCooldown = keeper.liquidationCooldown();
        
        console.log("Current Adapter cooldown:", currentAdapterCooldown, "seconds");
        console.log("Current Keeper cooldown:", currentKeeperCooldown, "seconds");
        console.log("");
        
        // Reduce Adapter cooldown to 30 seconds (minimum for testing)
        console.log("Setting Adapter cooldown to 30 seconds...");
        adapter.setLiquidationCooldown(30);
        
        // Reduce Keeper cooldown to 30 seconds  
        console.log("Setting Keeper cooldown to 30 seconds...");
        keeper.setLiquidationCooldown(30);
        
        console.log("Cooldowns reduced successfully!");
        console.log("");
    }
    
    function verifyCooldowns() internal view {
        console.log("=== VERIFYING NEW COOLDOWNS ===");
        
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        uint256 newAdapterCooldown = adapter.liquidationCooldown();
        uint256 newKeeperCooldown = keeper.liquidationCooldown();
        
        console.log("New Adapter cooldown:", newAdapterCooldown, "seconds");
        console.log("New Keeper cooldown:", newKeeperCooldown, "seconds");
        
        if (newAdapterCooldown == 30 && newKeeperCooldown == 30) {
            console.log("[SUCCESS] Cooldowns set to 30 seconds");
            console.log("Liquidations should now work automatically!");
        } else {
            console.log("[ERROR] Cooldown configuration failed");
        }
        
        console.log("");
        console.log("NEXT STEPS:");
        console.log("1. Wait 30 seconds after any previous liquidation attempt");
        console.log("2. Create a new position and crash market");
        console.log("3. Monitor Chainlink Automation execution");
        console.log("4. Positions should liquidate automatically within 30 seconds");
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title AdjustAutomationThreshold
 * @notice Ajusta el risk threshold para trabajar con ratios 100-110%
 */
contract AdjustAutomationThreshold is Script {
    
    function run() external {
        console.log("=== AJUSTANDO AUTOMATION RISK THRESHOLD ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        
        console.log("AutomationKeeper:", automationKeeper);
        console.log("");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        // Check current settings
        console.log("CONFIGURACION ACTUAL:");
        console.log("====================");
        uint256 currentThreshold = keeper.minRiskThreshold();
        console.log("Current Risk Threshold:", currentThreshold);
        
        // Adjust to work with 100-110% range
        // Risk threshold should be lower since we're liquidating closer to 100%
        console.log("");
        console.log("NUEVA CONFIGURACION:");
        console.log("====================");
        console.log("New Risk Threshold: 70 (para liquidar posiciones cercanas a 100-110%)");
        keeper.setMinRiskThreshold(70); // Lower threshold for conservative liquidations
        
        console.log("New Cooldown: 120 seconds (2 minutos)");
        keeper.setLiquidationCooldown(120); // Faster liquidations for testing
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("AJUSTES COMPLETADOS");
        console.log("===================");
        console.log("- Risk Threshold: 85 -> 70");
        console.log("- Liquidation Cooldown: 300 -> 120 segundos");
        console.log("");
        console.log("Esto permitira liquidar posiciones en el rango 100-110%");
        console.log("con menos restricciones de risk level");
    }
} 
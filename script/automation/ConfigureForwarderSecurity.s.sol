// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

interface LoanAutomationKeeperInterface {
    function setChainlinkForwarder(address forwarder) external;
    function setForwarderRestriction(bool restricted) external;
    function registerLoanManager(address manager, uint256 priority) external;
    function owner() external view returns (address);
    function chainlinkForwarder() external view returns (address);
    function forwarderRestricted() external view returns (bool);
}

/**
 * @title ConfigureForwarderSecurity
 * @notice Script para configurar la seguridad del Forwarder después del registro del upkeep
 */
contract ConfigureForwarderSecurity is Script {
    
    function run() external {
        // Leer direcciones desde variables de entorno
        address automationKeeper = vm.envAddress("AUTOMATION_KEEPER_ADDRESS");
        address flexibleLoanManager = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        address forwarderAddress = vm.envAddress("CHAINLINK_FORWARDER_ADDRESS");
        
        console.log("=== CONFIGURING FORWARDER SECURITY ===");
        console.log("Automation Keeper:", automationKeeper);
        console.log("Flexible Loan Manager:", flexibleLoanManager);
        console.log("Chainlink Forwarder:", forwarderAddress);
        console.log("");
        
        vm.startBroadcast();
        
        LoanAutomationKeeperInterface keeper = LoanAutomationKeeperInterface(automationKeeper);
        
        // 1. Configurar la dirección del Forwarder
        console.log("1. Setting Chainlink Forwarder address...");
        keeper.setChainlinkForwarder(forwarderAddress);
        console.log("   Forwarder address set successfully");
        
        // 2. Registrar el FlexibleLoanManager en el keeper
        console.log("2. Registering FlexibleLoanManager...");
        keeper.registerLoanManager(flexibleLoanManager, 100); // Prioridad máxima
        console.log("   FlexibleLoanManager registered with priority 100");
        
        // 3. Activar la restricción del Forwarder para seguridad
        console.log("3. Enabling Forwarder restriction for security...");
        keeper.setForwarderRestriction(true);
        console.log("   Forwarder restriction enabled");
        
        vm.stopBroadcast();
        
        // 4. Verificar configuración
        console.log("");
        console.log("=== CONFIGURATION VERIFICATION ===");
        console.log("Owner:", keeper.owner());
        console.log("Forwarder Address:", keeper.chainlinkForwarder());
        console.log("Forwarder Restricted:", keeper.forwarderRestricted());
        console.log("");
        console.log("SECURITY SETUP COMPLETE!");
        console.log("Your automation is now ready and secured with Chainlink Forwarder.");
    }
} 
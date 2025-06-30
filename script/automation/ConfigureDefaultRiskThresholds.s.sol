// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title ConfigureDefaultRiskThresholds
 * @notice Configura los risk thresholds a los valores por defecto del sistema
 * @dev Establece los valores óptimos según el diseño original del sistema
 */
contract ConfigureDefaultRiskThresholds is Script {
    
    function run() external {
        console.log("CONFIGURANDO RISK THRESHOLDS A VALORES POR DEFECTO");
        console.log("=====================================================");
        console.log("");
        
        // Load addresses from deployed-addresses-mock.json
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        console.log("Direcciones de contratos:");
        console.log("   AutomationKeeper:", automationKeeper);
        console.log("   LoanAdapter:", loanAdapter);
        console.log("");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        console.log("CONFIGURACION ACTUAL:");
        console.log("========================");
        console.log("AutomationKeeper:");
        console.log("   Min Risk Threshold:", keeper.minRiskThreshold());
        console.log("   Liquidation Cooldown:", keeper.liquidationCooldown(), "segundos");
        console.log("");
        console.log("LoanAdapter:");
        console.log("   Critical Threshold:", adapter.criticalRiskThreshold());
        console.log("   Danger Threshold:", adapter.dangerRiskThreshold());
        console.log("   Warning Threshold:", adapter.warningRiskThreshold());
        console.log("");
        
        console.log("APLICANDO VALORES POR DEFECTO:");
        console.log("==================================");
        
        // NOTA: Los valores originales del código son 105, 95, 90
        // Pero la función setRiskThresholds tiene restrict: critical <= 100
        // Por tanto usamos los valores máximos válidos que respetan el diseño original
        
        console.log("1. LoanAdapter Risk Thresholds:");
        console.log("   Critical: 100 (liquidacion inmediata - maximo permitido)");
        console.log("   Danger: 95 (liquidacion alta prioridad)");
        console.log("   Warning: 90 (liquidacion regular)");
        
        adapter.setRiskThresholds(
            100,  // Critical threshold (era 105 pero limitado a 100)
            95,   // Danger threshold (valor original)
            90    // Warning threshold (valor original)
        );
        
        console.log("2. AutomationKeeper Settings:");
        console.log("   Min Risk Threshold: 85 (detectar posiciones en warning)");
        console.log("   Liquidation Cooldown: 180 segundos (3 minutos - balance optimo)");
        
        keeper.setMinRiskThreshold(85); // Detectar desde warning level
        keeper.setLiquidationCooldown(180); // 3 minutos - valor por defecto
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("CONFIGURACION COMPLETADA!");
        console.log("=============================");
        console.log("");
        console.log("RESUMEN DE CAMBIOS:");
        console.log("=====================");
        console.log("LoanAdapter:");
        console.log("   Critical: 95 -> 100 (maximo impacto)");
        console.log("   Danger: 85 -> 95 (alta prioridad)");
        console.log("   Warning: 75 -> 90 (monitoreo estandar)");
        console.log("");
        console.log("AutomationKeeper:");
        console.log("   Min Risk: 96 -> 85 (mas sensible)");
        console.log("   Cooldown: 180 -> 180 (sin cambio)");
        console.log("");
        console.log("COMPORTAMIENTO ESPERADO:");
        console.log("===========================");
        console.log("- Risk Level 90-94: Monitoreo (warning)");
        console.log("- Risk Level 95-99: Alta prioridad (danger)");
        console.log("- Risk Level 100+: Liquidacion inmediata (critical)");
        console.log("");
        console.log("PROXIMOS PASOS:");
        console.log("==================");
        console.log("1. Verificar configuracion: make check-avalanche-status");
        console.log("2. Crear posicion de prueba: make create-avalanche-test-loan");
        console.log("3. Monitorear automation: make monitor-avalanche-automation");
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title FixRatiosWithBuffer
 * @notice Corrige ratios agregando buffer de seguridad para evitar liquidaciones prematuras
 * @dev Objetivo: Liquidar solo cuando LTV > 96% (con buffer de 1% sobre el 95% objetivo)
 */
contract FixRatiosWithBuffer is Script {
    
    function run() external {
        console.log("CORRIGIENDO RATIOS CON BUFFER DE SEGURIDAD");
        console.log("==========================================");
        console.log("");
        
        // Cargar direcciones
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address vaultHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        
        address ethToken = vm.parseJsonAddress(json, ".tokens.mockETH");
        address usdcToken = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address wbtcToken = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        console.log("CONTRATOS:");
        console.log("  VaultBasedHandler:", vaultHandler);
        console.log("  AutomationKeeper:", automationKeeper);
        console.log("");
        
        console.log("OBJETIVO DEL AJUSTE:");
        console.log("====================");
        console.log("- Liquidar SOLO cuando LTV > 96% (buffer de 1%)");
        console.log("- LTV 96% = Ratio de liquidacion 104.17%");
        console.log("- Esto evita liquidaciones por fluctuaciones menores");
        console.log("");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        VaultBasedHandler vaultHandler_contract = VaultBasedHandler(vaultHandler);
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        console.log("CONFIGURANDO RATIOS CON BUFFER DE SEGURIDAD:");
        console.log("===========================================");
        
        // Nuevo ratio de liquidacion: 104.17% = 96% LTV
        // Esto significa que se liquida cuando LTV > 96%, dando buffer de 1%
        uint256 newLiquidationRatio = 1041700; // 104.17%
        uint256 newCollateralRatio = 1500000;  // 150% (permite crear hasta 66.67% LTV)
        
        console.log("1. MockETH (buffer 1% sobre objetivo 95%):");
        console.log("   - Collateral: 150% (permite crear hasta 66.67% LTV)");
        console.log("   - Liquidacion: 104.17% (liquida cuando LTV > 96%)");
        console.log("   - Buffer de seguridad: 1% sobre el 95% objetivo");
        vaultHandler_contract.updateBothRatios(
            ethToken,
            newCollateralRatio,
            newLiquidationRatio
        );
        
        console.log("2. MockUSDC (buffer 1% sobre objetivo 95%):");
        console.log("   - Collateral: 150% (permite crear hasta 66.67% LTV)");
        console.log("   - Liquidacion: 104.17% (liquida cuando LTV > 96%)");
        console.log("   - Buffer de seguridad: 1% sobre el 95% objetivo");
        vaultHandler_contract.updateBothRatios(
            usdcToken,
            newCollateralRatio,
            newLiquidationRatio
        );
        
        console.log("3. MockWBTC (buffer 1% sobre objetivo 95%):");
        console.log("   - Collateral: 150% (permite crear hasta 66.67% LTV)");
        console.log("   - Liquidacion: 104.17% (liquida cuando LTV > 96%)");
        console.log("   - Buffer de seguridad: 1% sobre el 95% objetivo");
        vaultHandler_contract.updateBothRatios(
            wbtcToken,
            newCollateralRatio,
            newLiquidationRatio
        );
        
        console.log("");
        console.log("CONFIGURANDO AUTOMATION PARA DETECCION PRECISA:");
        console.log("===============================================");
        console.log("- Risk Threshold: 96 (detectar solo cuando LTV > 96%)");
        console.log("- Cooldown: 180 segundos (evitar spam pero ser responsivo)");
        
        keeper.setMinRiskThreshold(96); // Detect only when LTV > 96%
        keeper.setLiquidationCooldown(180); // 3 minutes cooldown
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("VERIFICACION DE CALCULOS:");
        console.log("=========================");
        console.log("Nuevo ratio de liquidacion: 104.17%");
        console.log("LTV de liquidacion: 100/104.17 * 100 = 96.0%");
        console.log("Buffer sobre objetivo 95%: 1.0%");
        console.log("");
        
        console.log("COMPORTAMIENTO ESPERADO:");
        console.log("=======================");
        console.log("[OK] LTV <= 95%: SEGURO (no liquida)");
        console.log("[BUFFER] LTV 95-96%: ZONA BUFFER (no liquida)"); 
        console.log("[LIQUIDATE] LTV > 96%: LIQUIDABLE (automation actua)");
        console.log("");
        
        console.log("PROXIMOS PASOS:");
        console.log("===============");
        console.log("1. Ejecutar: make check-avalanche-balances");
        console.log("2. Crear posicion de prueba con LTV ~90%");
        console.log("3. Verificar que NO se liquida automaticamente");
        console.log("4. Aumentar LTV a 97% y verificar que SI se liquida");
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title ImplementAggressiveRatios
 * @notice Implementa ratios muy agresivos: liquidacion a partir del 95% LTV
 */
contract ImplementAggressiveRatios is Script {
    
    function run() external {
        console.log("=== IMPLEMENTANDO RATIOS ULTRA-AGRESIVOS ===");
        console.log("Liquidacion a partir del 95% LTV");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        
        address ethToken = vm.parseJsonAddress(json, ".tokens.mockETH");
        address usdcToken = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address wbtcToken = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        VaultBasedHandler vaultHandler = VaultBasedHandler(vaultBasedHandler);
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        console.log("CALCULOS:");
        console.log("=========");
        console.log("95% LTV = 105.26% collateralization ratio");
        console.log("94% LTV = 106.38% ratio (SEGURO)");
        console.log("96% LTV = 104.17% ratio (LIQUIDABLE)");
        console.log("");
        
        console.log("NUEVA CONFIGURACION ULTRA-AGRESIVA:");
        console.log("====================================");
        console.log("");
        
        // Configuración ultra-agresiva para todos los assets
        // Liquidation ratio: 105.2% (95% LTV)
        // Collateral ratio: 120% (permitir crear posiciones hasta 83% LTV)
        
        console.log("1. MockETH (Liquidacion 95% LTV):");
        console.log("   - Collateral: 120% (permite 83% LTV max)");
        console.log("   - Liquidacion: 105.2% (95% LTV limite)");
        console.log("   - Buffer: 14.8%");
        vaultHandler.updateBothRatios(
            ethToken,
            1200000,  // 120% collateral ratio (permite 83% LTV)
            1052000   // 105.2% liquidation ratio (95% LTV exacto)
        );
        
        console.log("2. MockUSDC (Liquidacion 95% LTV):");
        console.log("   - Collateral: 120% (permite 83% LTV max)");
        console.log("   - Liquidacion: 105.2% (95% LTV limite)");
        console.log("   - Buffer: 14.8%");
        vaultHandler.updateBothRatios(
            usdcToken,
            1200000,  // 120% collateral ratio
            1052000   // 105.2% liquidation ratio
        );
        
        console.log("3. MockWBTC (Liquidacion 95% LTV):");
        console.log("   - Collateral: 120% (permite 83% LTV max)");
        console.log("   - Liquidacion: 105.2% (95% LTV limite)");
        console.log("   - Buffer: 14.8%");
        vaultHandler.updateBothRatios(
            wbtcToken,
            1200000,  // 120% collateral ratio
            1052000   // 105.2% liquidation ratio
        );
        
        console.log("");
        console.log("AJUSTANDO AUTOMATION PARA SISTEMA AGRESIVO:");
        console.log("===========================================");
        console.log("- Risk Threshold: 85 (muy sensible)");
        console.log("- Cooldown: 60 segundos (liquidaciones rapidas)");
        
        keeper.setMinRiskThreshold(85); // Very sensitive for aggressive system
        keeper.setLiquidationCooldown(60); // Fast liquidations
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== SISTEMA ULTRA-AGRESIVO CONFIGURADO ===");
        console.log("");
        console.log("RESULTADO:");
        console.log("- Liquidacion exacta a 95% LTV (105.2% ratio)");
        console.log("- Maximo LTV permitido: 83%");
        console.log("- Buffer muy pequeno: 14.8%");
        console.log("");
        console.log("RANGOS DE SEGURIDAD:");
        console.log("====================");
        console.log("LTV 80% (125% ratio) = MUY SEGURO");
        console.log("LTV 85% (118% ratio) = SEGURO");
        console.log("LTV 90% (111% ratio) = RIESGO MEDIO");
        console.log("LTV 94% (106% ratio) = ALTO RIESGO");
        console.log("LTV 95% (105% ratio) = LIQUIDACION INMEDIATA");
        console.log("");
        console.log("ADVERTENCIAS:");
        console.log("=============");
        console.log("1. Sistema MUY arriesgado");
        console.log("2. Volatilidad del 5% puede liquidar posiciones");
        console.log("3. Monitoreo constante requerido");
        console.log("4. Solo usar en testnet o con cantidades pequenas");
        console.log("");
        console.log("COMPARACION:");
        console.log("- Protocolos tradicionales: 75-85% LTV");
        console.log("- Tu sistema: Hasta 95% LTV (ULTRA-AGRESIVO)");
    }
} 
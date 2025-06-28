// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title FixRatiosFor95LTV
 * @notice Corrige los ratios para liquidar SOLO cuando LTV > 95%
 */
contract FixRatiosFor95LTV is Script {
    
    function run() external {
        console.log("=== CONFIGURACION CORRECTA PARA 95% LTV ===");
        console.log("Solo liquidar cuando LTV > 95%");
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
        
        console.log("MATEMATICA:");
        console.log("===========");
        console.log("LTV 95% = 105.26% collateralization ratio");
        console.log("LTV 94% = 106.38% ratio (SEGURO)");
        console.log("LTV 96% = 104.17% ratio (LIQUIDABLE)");
        console.log("");
        
        console.log("CONFIGURACION CORREGIDA:");
        console.log("========================");
        console.log("");
        
        // CONFIGURACION CORRECTA:
        // - Collateral ratio: 150% (permite crear hasta 66.67% LTV)
        // - Liquidation ratio: 105.26% (liquidar solo cuando LTV > 95%)
        
        console.log("1. MockETH (liquidar solo si LTV > 95%):");
        console.log("   - Collateral: 150% (permite hasta 66.67% LTV)");
        console.log("   - Liquidacion: 105.26% (95% LTV exacto)");
        console.log("   - Buffer seguro: 44.74%");
        vaultHandler.updateBothRatios(
            ethToken,
            1500000,  // 150% collateral ratio (permite crear hasta 66.67% LTV)
            1052600   // 105.26% liquidation ratio (exacto 95% LTV)
        );
        
        console.log("2. MockUSDC (liquidar solo si LTV > 95%):");
        console.log("   - Collateral: 150% (permite hasta 66.67% LTV)");
        console.log("   - Liquidacion: 105.26% (95% LTV exacto)");
        console.log("   - Buffer seguro: 44.74%");
        vaultHandler.updateBothRatios(
            usdcToken,
            1500000,  // 150% collateral ratio
            1052600   // 105.26% liquidation ratio
        );
        
        console.log("3. MockWBTC (liquidar solo si LTV > 95%):");
        console.log("   - Collateral: 150% (permite hasta 66.67% LTV)");
        console.log("   - Liquidacion: 105.26% (95% LTV exacto)");
        console.log("   - Buffer seguro: 44.74%");
        vaultHandler.updateBothRatios(
            wbtcToken,
            1500000,  // 150% collateral ratio
            1052600   // 105.26% liquidation ratio
        );
        
        console.log("");
        console.log("AUTOMATION PARA DETECCION PRECISA:");
        console.log("===================================");
        console.log("- Risk Threshold: 90 (detectar solo criticos)");
        console.log("- Cooldown: 120 segundos (evitar spam)");
        
        keeper.setMinRiskThreshold(90); // Only detect critical positions
        keeper.setLiquidationCooldown(120); // Reasonable cooldown
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== RATIOS CORREGIDOS PARA 95% LTV ===");
        console.log("");
        console.log("RESULTADO:");
        console.log("- Liquidacion SOLO cuando LTV > 95%");
        console.log("- Posiciones con LTV <= 95% son SEGURAS");
        console.log("- Maximo LTV permitido para crear: 66.67%");
        console.log("- Buffer de seguridad: 28.33%");
        console.log("");
        console.log("RANGOS DE SEGURIDAD:");
        console.log("====================");
        console.log("LTV 50% (200% ratio) = ULTRA SEGURO");
        console.log("LTV 66% (150% ratio) = MUY SEGURO (limite creacion)");
        console.log("LTV 80% (125% ratio) = SEGURO");
        console.log("LTV 90% (111% ratio) = MONITOREADO");
        console.log("LTV 95% (105% ratio) = UMBRAL CRITICO");
        console.log("LTV 96%+ (<105% ratio) = LIQUIDACION INMEDIATA");
        console.log("");
        console.log("COMO PROBAR:");
        console.log("=============");
        console.log("1. Crear posicion con 80% LTV = SEGURA");
        console.log("2. Aumentar loan para llevar a 96% LTV = LIQUIDABLE");
        console.log("3. O crashear mercado 6%+ = LIQUIDABLE");
        console.log("");
        console.log("La posicion actual (83% ratio = 120% LTV) SI es liquidable");
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";

/**
 * @title AnalyzeOptimalRatios
 * @notice Analiza y recomienda ratios optimos para el sistema
 */
contract AnalyzeOptimalRatios is Script {
    
    function run() external view {
        console.log("=== ANALISIS DE RATIOS OPTIMOS PARA TU SISTEMA ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address ethToken = vm.parseJsonAddress(json, ".tokens.mockETH");
        address usdcToken = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address wbtcToken = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        console.log("PROBLEMA ACTUAL:");
        console.log("================");
        console.log("- Estas creando posiciones con 80% LTV");
        console.log("- 80% LTV = 125% collateralization ratio");
        console.log("- Ratios de liquidacion actuales: 108-110%");
        console.log("- RESULTADO: Liquidacion inmediata!");
        console.log("");
        
        // Current configuration
        console.log("CONFIGURACION ACTUAL:");
        console.log("=====================");
        _showCurrentRatios(vaultBasedHandler, ethToken, "MockETH");
        _showCurrentRatios(vaultBasedHandler, usdcToken, "MockUSDC");
        _showCurrentRatios(vaultBasedHandler, wbtcToken, "MockWBTC");
        console.log("");
        
        console.log("ANALISIS DE DIFERENTES ESCENARIOS:");
        console.log("===================================");
        console.log("");
        
        console.log("ESCENARIO 1: SISTEMA CONSERVADOR (Recomendado para produccion)");
        console.log("--------------------------------------------------------------");
        console.log("Target LTV maximo: 75%");
        console.log("Ratio minimo creacion: 133% (1/0.75)");
        console.log("Ratio de liquidacion: 115%");
        console.log("Buffer de seguridad: 18% (133% - 115%)");
        console.log("Ventajas: Muy seguro, pocas liquidaciones");
        console.log("Desventajas: Menor eficiencia de capital");
        console.log("");
        
        console.log("ESCENARIO 2: SISTEMA BALANCEADO (Recomendado para tu caso)");
        console.log("-----------------------------------------------------------");
        console.log("Target LTV maximo: 80%");
        console.log("Ratio minimo creacion: 125% (1/0.80)");
        console.log("Ratio de liquidacion: 105-107%");
        console.log("Buffer de seguridad: 18-20% (125% - 105/107%)");
        console.log("Ventajas: Balance entre seguridad y eficiencia");
        console.log("Desventajas: Requiere monitoreo activo");
        console.log("");
        
        console.log("ESCENARIO 3: SISTEMA AGRESIVO (Solo para testing)");
        console.log("--------------------------------------------------");
        console.log("Target LTV maximo: 85%");
        console.log("Ratio minimo creacion: 118% (1/0.85)");
        console.log("Ratio de liquidacion: 102-105%");
        console.log("Buffer de seguridad: 13-16% (118% - 102/105%)");
        console.log("Ventajas: Maxima eficiencia de capital");
        console.log("Desventajas: Alto riesgo de liquidacion");
        console.log("");
        
        console.log("RECOMENDACION PARA TU SISTEMA:");
        console.log("===============================");
        console.log("Basado en tu LTV del 80%, sugiero ESCENARIO 2:");
        console.log("");
        console.log("RATIOS RECOMENDADOS:");
        console.log("- MockETH (volatil):  Liquidacion 107%, Collateral 135%");
        console.log("- MockUSDC (estable): Liquidacion 105%, Collateral 125%");
        console.log("- MockWBTC (volatil): Liquidacion 107%, Collateral 135%");
        console.log("");
        console.log("AUTOMATION SETTINGS:");
        console.log("- Risk Threshold: 75-80 (detectar riesgo temprano)");
        console.log("- Cooldown: 180 segundos (balance entre spam y eficiencia)");
        console.log("");
        
        console.log("COMPARACION CON PROTOCOLOS CONOCIDOS:");
        console.log("=====================================");
        console.log("AAVE V3:");
        console.log("- ETH:  LTV 82.5%, Liquidation 86%");
        console.log("- USDC: LTV 90%,   Liquidation 95%");
        console.log("- WBTC: LTV 70%,   Liquidation 75%");
        console.log("");
        console.log("COMPOUND V3:");
        console.log("- ETH:  LTV ~83%,  Liquidation ~85%");
        console.log("- USDC: LTV ~92%,  Liquidation ~95%");
        console.log("");
        console.log("MAKERDAO:");
        console.log("- ETH-A: LTV 74%,  Liquidation 80%");
        console.log("- WBTC:  LTV 70%,  Liquidation 75%");
        console.log("");
        
        console.log("IMPLEMENTACION SUGERIDA:");
        console.log("=========================");
        console.log("1. Ajustar ratios de liquidacion a 105-107%");
        console.log("2. Mantener LTV del 80% pero con ratios correctos");
        console.log("3. Configurar automation threshold a 75");
        console.log("4. Testear con posiciones pequenas");
        console.log("5. Monitorear comportamiento antes de escalar");
    }
    
    function _showCurrentRatios(address handler, address token, string memory tokenName) internal view {
        VaultBasedHandler vaultHandler = VaultBasedHandler(handler);
        
        try vaultHandler.getAssetConfig(token) returns (IAssetHandler.AssetConfig memory config) {
            uint256 maxLTV = 100000000 / config.collateralRatio; // Calculate max LTV (as percentage)
            console.log("Asset:", tokenName);
            console.log("  Liquidation %:", config.liquidationRatio / 10000);
            console.log("  Collateral %:", config.collateralRatio / 10000);
            console.log("  Max LTV %:", maxLTV);
            console.log("  Buffer:", (config.collateralRatio - config.liquidationRatio) / 10000);
        } catch {
            console.log("Asset:", tokenName, "- ERROR reading config");
        }
    }
} 
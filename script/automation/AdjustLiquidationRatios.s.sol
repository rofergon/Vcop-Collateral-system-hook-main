// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";

/**
 * @title AdjustLiquidationRatios
 * @notice Ajusta los ratios de liquidacion al rango 100-110%
 */
contract AdjustLiquidationRatios is Script {
    
    function run() external {
        console.log("=== AJUSTANDO RATIOS DE LIQUIDACION ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        
        address ethToken = vm.parseJsonAddress(json, ".tokens.mockETH");
        address usdcToken = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address wbtcToken = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        VaultBasedHandler vaultHandler = VaultBasedHandler(vaultBasedHandler);
        
        console.log("AJUSTES PARA RANGO 100-110%:");
        console.log("=============================");
        
        // MockETH: Ya está bien (110%), no cambiar
        console.log("MockETH: Mantener 110% liquidation (ya correcto)");
        
        // MockUSDC: Cambiar de 105% a 108%
        console.log("MockUSDC: Cambiar de 105% a 108% liquidation");
        vaultHandler.updateBothRatios(
            usdcToken,
            1180000,  // Collateral ratio: 118% (conservative)
            1080000   // Liquidation ratio: 108% (dentro del rango 100-110%)
        );
        
        // MockWBTC: Cambiar de 115% a 110%
        console.log("MockWBTC: Cambiar de 115% a 110% liquidation");
        vaultHandler.updateBothRatios(
            wbtcToken,
            1200000,  // Collateral ratio: 120% (conservative)
            1100000   // Liquidation ratio: 110% (limite superior del rango)
        );
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== VERIFICACION NUEVA CONFIGURACION ===");
        _verifyNewRatios(vaultHandler, ethToken, "MockETH");
        _verifyNewRatios(vaultHandler, usdcToken, "MockUSDC");
        _verifyNewRatios(vaultHandler, wbtcToken, "MockWBTC");
        
        console.log("");
        console.log("RATIOS AJUSTADOS AL RANGO 100-110%");
        console.log("");
        console.log("RESULTADO:");
        console.log("- MockETH:  110% liquidation (sin cambios)");
        console.log("- MockUSDC: 108% liquidation (menos agresivo)");
        console.log("- MockWBTC: 110% liquidation (menos agresivo)");
        console.log("");
        console.log("Ahora solo se liquidaran posiciones muy cerca del rango critico");
        console.log("Crear nuevas posiciones de prueba con: make create-avalanche-test-loan");
    }
    
    function _verifyNewRatios(VaultBasedHandler handler, address token, string memory tokenName) internal view {
        try handler.getAssetConfig(token) returns (IAssetHandler.AssetConfig memory config) {
            console.log("Asset:", tokenName);
            console.log("  Collateral %:", config.collateralRatio / 10000);
            console.log("  Liquidation %:", config.liquidationRatio / 10000);
        } catch {
            console.log("Asset:", tokenName, "- ERROR reading config");
        }
    }
} 
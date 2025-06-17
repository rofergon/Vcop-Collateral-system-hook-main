// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FlexibleLoanManager} from "../src/core/FlexibleLoanManager.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {FlexibleAssetHandler} from "../src/core/FlexibleAssetHandler.sol";
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";
import {IAssetHandler} from "../src/interfaces/IAssetHandler.sol";

/**
 * @title DiagnosticLiquidation
 * @notice Script para diagnosticar por qué las posiciones no son liquidables
 */
contract DiagnosticLiquidation is Script {
    
    // Direcciones desplegadas en Base Sepolia (ACTUALIZADAS)
    address constant GENERIC_LOAN_MANAGER = 0xd66706C24920eF1eA2b919F349ae56b5C995b431;
    address constant FLEXIBLE_LOAN_MANAGER = 0x92ea2E50733b23F23d0958dab79BBcA1e49F627a;
    address constant FLEXIBLE_ASSET_HANDLER = 0xA5688b57eD0854807085B9c73046FdE548cc43CD;
    
    // Mock tokens (ACTUALIZADOS)
    address constant MOCK_ETH = 0xBec09f97BA8730D7e58CeD55CB5957B0dccD1BE7;
    address constant MOCK_USDC = 0x19F3d0Ca2b49A1097906cFc641a4789807BBC497;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==================================================");
        console.log("DIAGNOSTICO DE LIQUIDACION");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("");
        
        // Analizar posiciones del deployer
        _analyzeUserPositions(deployer);
        
        // Analizar configuraciones de assets
        _analyzeAssetConfigurations();
        
        // Test de liquidación con diferentes ratios
        _testLiquidationLogic();
    }
    
    function _analyzeUserPositions(address user) internal view {
        console.log("=== ANALIZANDO POSICIONES DEL USUARIO ===");
        
        // Revisar posiciones en GenericLoanManager
        GenericLoanManager genericManager = GenericLoanManager(GENERIC_LOAN_MANAGER);
        uint256[] memory genericPositions = genericManager.getUserPositions(user);
        
        console.log("Posiciones en GenericLoanManager:", genericPositions.length);
        for (uint i = 0; i < genericPositions.length; i++) {
            uint256 positionId = genericPositions[i];
            console.log("");
            console.log("--- Posicion ID:", positionId, " ---");
            
            ILoanManager.LoanPosition memory position = genericManager.getPosition(positionId);
            if (!position.isActive) {
                console.log("X Posicion INACTIVA");
                continue;
            }
            
            uint256 collateralizationRatio = genericManager.getCollateralizationRatio(positionId);
            uint256 totalDebt = genericManager.getTotalDebt(positionId);
            bool canLiquidate = genericManager.canLiquidate(positionId);
            
            console.log("Colateral:", position.collateralAmount / 1e18, "ETH");
            console.log("Prestamo:", position.loanAmount / 1e6, "USDC");
            console.log("Deuda total:", totalDebt / 1e6, "USDC");
            console.log("Ratio colateralizacion:", collateralizationRatio / 10000, "%");
            console.log("Es liquidable:", canLiquidate);
            
            // Obtener config del asset handler
            FlexibleAssetHandler assetHandler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
            IAssetHandler.AssetConfig memory config = assetHandler.getAssetConfig(position.collateralAsset);
            
            console.log("Umbral liquidacion configurado:", config.liquidationRatio / 10000, "%");
            console.log("Comparacion: ratio actual vs umbral");
            console.log("  Ratio actual:", collateralizationRatio / 10000, "%");
            console.log("  Umbral:", config.liquidationRatio / 10000, "%");
                
            if (collateralizationRatio < config.liquidationRatio) {
                console.log("V DEBERIA ser liquidable (ratio < umbral)");
            } else {
                console.log("X NO deberia ser liquidable (ratio >= umbral)");
            }
        }
        
        // Revisar posiciones en FlexibleLoanManager
        FlexibleLoanManager flexibleManager = FlexibleLoanManager(FLEXIBLE_LOAN_MANAGER);
        uint256[] memory flexiblePositions = flexibleManager.getUserPositions(user);
        
        console.log("");
        console.log("Posiciones en FlexibleLoanManager:", flexiblePositions.length);
        for (uint i = 0; i < flexiblePositions.length; i++) {
            uint256 positionId = flexiblePositions[i];
            console.log("");
            console.log("--- Posicion FLEXIBLE ID:", positionId, " ---");
            
            ILoanManager.LoanPosition memory position = flexibleManager.getPosition(positionId);
            if (!position.isActive) {
                console.log("X Posicion INACTIVA");
                continue;
            }
            
            uint256 collateralizationRatio = flexibleManager.getCollateralizationRatio(positionId);
            uint256 totalDebt = flexibleManager.getTotalDebt(positionId);
            bool canLiquidate = flexibleManager.canLiquidate(positionId);
            
            console.log("Colateral:", position.collateralAmount / 1e18, "ETH");
            console.log("Prestamo:", position.loanAmount / 1e6, "USDC");
            console.log("Deuda total:", totalDebt / 1e6, "USDC");
            console.log("Ratio colateralizacion:", collateralizationRatio / 10000, "%");
            console.log("Es liquidable:", canLiquidate);
            
            // FlexibleLoanManager usa lógica especial
            FlexibleAssetHandler assetHandler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
            IAssetHandler.AssetConfig memory config = assetHandler.getAssetConfig(position.collateralAsset);
            
            console.log("Umbral liquidacion configurado:", config.liquidationRatio / 10000, "%");
            console.log("Umbral FLEXIBLE (dividido por 2):", (config.liquidationRatio / 2) / 10000, "%");
            console.log("Comparacion FLEXIBLE:");
            console.log("  Ratio actual:", collateralizationRatio / 10000, "%");
            console.log("  Umbral/2:", (config.liquidationRatio / 2) / 10000, "%");
                
            if (collateralizationRatio < (config.liquidationRatio / 2)) {
                console.log("V DEBERIA ser liquidable en modo FLEXIBLE");
            } else {
                console.log("X NO deberia ser liquidable en modo FLEXIBLE");
            }
        }
    }
    
    function _analyzeAssetConfigurations() internal view {
        console.log("");
        console.log("=== CONFIGURACIONES DE ASSETS ===");
        
        FlexibleAssetHandler assetHandler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
        
        // Analizar ETH
        console.log("");
        console.log("--- MOCK ETH ---");
        IAssetHandler.AssetConfig memory ethConfig = assetHandler.getAssetConfig(MOCK_ETH);
        console.log("Colateral Ratio:", ethConfig.collateralRatio / 10000, "%");
        console.log("Liquidation Ratio:", ethConfig.liquidationRatio / 10000, "%");
        console.log("Es activo:", ethConfig.isActive);
        
        // Analizar USDC
        console.log("");
        console.log("--- MOCK USDC ---");
        IAssetHandler.AssetConfig memory usdcConfig = assetHandler.getAssetConfig(MOCK_USDC);
        console.log("Colateral Ratio:", usdcConfig.collateralRatio / 10000, "%");
        console.log("Liquidation Ratio:", usdcConfig.liquidationRatio / 10000, "%");
        console.log("Es activo:", usdcConfig.isActive);
    }
    
    function _testLiquidationLogic() internal view {
        console.log("");
        console.log("=== PRUEBA DE LOGICA DE LIQUIDACION ===");
        
        FlexibleAssetHandler assetHandler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
        IAssetHandler.AssetConfig memory ethConfig = assetHandler.getAssetConfig(MOCK_ETH);
        
        console.log("");
        console.log("Con umbral de liquidacion de", ethConfig.liquidationRatio / 10000, "%:");
        
        // Simular diferentes ratios
        uint256[] memory testRatios = new uint256[](8);
        testRatios[0] = 4000000; // 400%
        testRatios[1] = 2000000; // 200%
        testRatios[2] = 1500000; // 150%
        testRatios[3] = 1200000; // 120%
        testRatios[4] = 1100000; // 110%
        testRatios[5] = 1050000; // 105%
        testRatios[6] = 1020000; // 102%
        testRatios[7] = 1000000; // 100%
        
        for (uint i = 0; i < testRatios.length; i++) {
            uint256 ratio = testRatios[i];
            bool liquidableGeneric = ratio < ethConfig.liquidationRatio;
            bool liquidableFlexible = ratio < (ethConfig.liquidationRatio / 2);
            
            console.log("Ratio", ratio / 10000, "%:");
            console.log("  Generic:", liquidableGeneric ? "LIQUIDABLE" : "SEGURO");
            console.log("  Flexible:", liquidableFlexible ? "LIQUIDABLE" : "SEGURO");
        }
        
        console.log("");
        console.log("RESUMEN:");
        console.log("- GenericLoanManager: liquida cuando ratio <", ethConfig.liquidationRatio / 10000, "%");
        console.log("- FlexibleLoanManager: liquida cuando ratio <", (ethConfig.liquidationRatio / 2) / 10000, "%");
        console.log("");
        console.log("PROBLEMA IDENTIFICADO:");
        console.log("El FlexibleLoanManager es DEMASIADO PERMISIVO!");
        console.log("Solo liquida en ratios EXTREMADAMENTE bajos:", (ethConfig.liquidationRatio / 2) / 10000, "%");
    }
} 
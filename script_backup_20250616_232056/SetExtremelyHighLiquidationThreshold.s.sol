// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title SetExtremelyHighLiquidationThreshold
 * @notice Configura liquidation threshold extremadamente alto para testing
 */
contract SetExtremelyHighLiquidationThreshold is Script {
    
    // Handler que está siendo usado por GenericLoanManager
    address constant VAULT_BASED_HANDLER = 0xFE9cc4DC386606B00Dcb057F4F3425a0Cbd8Bd3f;
    address constant MOCK_ETH = 0x388F7D72FD879725E40d893Fc1b5455036C7fd19;
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("========================================");
        console.log("CONFIGURANDO LIQUIDATION THRESHOLD EXTREMO");
        console.log("========================================");
        console.log("VaultBasedHandler:", VAULT_BASED_HANDLER);
        console.log("Target: Hacer liquidable posicion con ~599,000% ratio");
        console.log("");
        
        vm.startBroadcast(privateKey);
        
        // Configurar ETH con liquidation threshold MUY ALTO (700,000%)
        // Esto hará que cualquier posición con ratio menor a 700,000% sea liquidable
        
        console.log("Configurando ETH con:");
        console.log("  Collateral Ratio: 800,000% (8x multiplicador)");
        console.log("  Liquidation Ratio: 700,000% (7x multiplicador)");
        console.log("  Max Loan: 1000 ETH");
        console.log("  Interest Rate: 10,000%");
        console.log("");
        
        // Llamar directamente la función configureAsset
        // Función: configureAsset(address,AssetType,uint256,uint256,uint256,uint256)
        // Parámetros: token, tipo, collateralRatio, liquidationRatio, maxLoan, interestRate
        
        bytes memory callData = abi.encodeWithSignature(
            "configureAsset(address,uint8,uint256,uint256,uint256,uint256)",
            MOCK_ETH,           // token
            1,                  // AssetType.VAULT_BASED
            800000000,          // 800,000% collateral ratio
            700000000,          // 700,000% liquidation ratio (EXTREMO!)
            1000 * 1e18,        // 1000 ETH max loan
            100000000           // 10,000% interest rate
        );
        
        console.log("Enviando configuracion...");
        (bool success, bytes memory returnData) = VAULT_BASED_HANDLER.call(callData);
        
        if (success) {
            console.log("CONFIGURACION EXITOSA!");
            console.log("Ahora cualquier posicion ETH con ratio < 700,000% sera liquidable");
            console.log("");
            console.log("Posicion ID 2 con ~599,000% ratio AHORA DEBERIA SER LIQUIDABLE!");
            console.log("");
            console.log("Verifica con:");
            console.log("cast call", VAULT_BASED_HANDLER);
            console.log("Function: canLiquidate(uint256) 2");
        } else {
            console.log("FALLO EN CONFIGURACION");
            console.logBytes(returnData);
        }
        
        vm.stopBroadcast();
        
        console.log("========================================");
        console.log("THRESHOLD EXTREMO CONFIGURADO");
        console.log("========================================");
    }
} 
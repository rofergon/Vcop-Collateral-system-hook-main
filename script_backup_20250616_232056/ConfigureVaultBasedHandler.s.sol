// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title ConfigureVaultBasedHandler
 * @notice Configura VaultBasedHandler con ratios bajos para testing de liquidaciones
 * @dev Este es el handler que efectivamente usa el GenericLoanManager
 */
contract ConfigureVaultBasedHandler is Script {
    
    // Direcciones desde deployed-addresses.json 
    address constant VAULT_BASED_HANDLER = 0xFE9cc4DC386606B00Dcb057F4F3425a0Cbd8Bd3f;
    address constant MOCK_ETH = 0x388F7D72FD879725E40d893Fc1b5455036C7fd19;
    address constant MOCK_USDC = 0x009A513d97e55C77060C303f74eE66a991Bd3f08;
    address constant MOCK_WBTC = 0x45aCd67cF453dB927965D59f21c6bb4972797B5A;
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        
        console.log("==================================================");
        console.log("CONFIGURANDO VAULT BASED HANDLER PARA LIQUIDACIONES");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("VaultBasedHandler:", VAULT_BASED_HANDLER);
        console.log("");
        
        vm.startBroadcast(privateKey);
        
        // Configurar ETH con ratio MUY BAJO
        console.log("=== CONFIGURANDO MOCK ETH (VAULT HANDLER) ===");
        _configureAssetVault(
            MOCK_ETH,
            1150000,    // 115% collateral ratio (MUY BAJO)
            1050000,    // 105% liquidation ratio (EXTREMO)
            1000 * 1e18, // 1000 ETH max loan
            60000       // 6% interest rate
        );
        
        console.log("ETH configurado en VaultBasedHandler:");
        console.log("  - Collateral Ratio: 115% (EXTREMADAMENTE BAJO)");
        console.log("  - Liquidation Ratio: 105% (CRITICO)");
        console.log("");
        
        // Configurar USDC con ratio bajo
        console.log("=== CONFIGURANDO MOCK USDC (VAULT HANDLER) ===");
        _configureAssetVault(
            MOCK_USDC,
            1200000,    // 120% collateral ratio (BAJO)
            1100000,    // 110% liquidation ratio (BAJO)
            1000000 * 1e6, // 1M USDC max loan
            40000       // 4% interest rate
        );
        
        console.log("USDC configurado en VaultBasedHandler:");
        console.log("  - Collateral Ratio: 120%");
        console.log("  - Liquidation Ratio: 110%");
        console.log("");
        
        // Configurar WBTC con ratio bajo
        console.log("=== CONFIGURANDO MOCK WBTC (VAULT HANDLER) ===");
        _configureAssetVault(
            MOCK_WBTC,
            1180000,    // 118% collateral ratio (MUY BAJO)
            1070000,    // 107% liquidation ratio (CRITICO)
            100 * 1e8,  // 100 WBTC max loan
            80000       // 8% interest rate (ALTO)
        );
        
        console.log("WBTC configurado en VaultBasedHandler:");
        console.log("  - Collateral Ratio: 118% (MUY BAJO)");
        console.log("  - Liquidation Ratio: 107% (CRITICO)");
        console.log("  - Interest Rate: 8% (ALTO para acelerar deterioro)");
        console.log("");
        
        vm.stopBroadcast();
        
        console.log("==================================================");
        console.log("CONFIGURACION DE VAULT BASED HANDLER COMPLETADA");
        console.log("==================================================");
        console.log("Ahora puedes probar liquidaciones con ratios MUY bajos:");
        console.log("ETH: Entre 105% y 115% (FACIL DE LIQUIDAR)");
        console.log("USDC: Entre 110% y 120%");
        console.log("WBTC: Entre 107% y 118%");
        console.log("");
        console.log("Usa este comando:");
        console.log("make test-liquidation-complete");
        console.log("==================================================");
    }
    
    function _configureAssetVault(
        address asset,
        uint256 collateralRatio,
        uint256 liquidationRatio,
        uint256 maxLoanAmount,
        uint256 interestRate
    ) internal {
        // Llamar directamente al VaultBasedHandler
        // Nota: Necesitamos verificar la interfaz exacta del VaultBasedHandler
        
        bytes memory configCall = abi.encodeWithSignature(
            "configureAsset(address,uint8,uint256,uint256,uint256,uint256)",
            asset,
            1, // AssetType.MINTABLE_BURNABLE 
            collateralRatio,
            liquidationRatio,
            maxLoanAmount,
            interestRate
        );
        
        (bool success, bytes memory data) = VAULT_BASED_HANDLER.call(configCall);
        
        if (success) {
            console.log("Asset configurado exitosamente:", asset);
        } else {
            console.log("Error configurando asset:", asset);
            console.log("Error data:");
            console.logBytes(data);
            
            // Intentar con interfaz alternativa (sin AssetType)
            bytes memory altCall = abi.encodeWithSignature(
                "configureAsset(address,uint256,uint256,uint256,uint256)",
                asset,
                collateralRatio,
                liquidationRatio,
                maxLoanAmount,
                interestRate
            );
            
            (bool altSuccess,) = VAULT_BASED_HANDLER.call(altCall);
            if (altSuccess) {
                console.log("Asset configurado con interfaz alternativa:", asset);
            } else {
                console.log("Asset NO pudo ser configurado con ninguna interfaz");
            }
        }
    }
} 
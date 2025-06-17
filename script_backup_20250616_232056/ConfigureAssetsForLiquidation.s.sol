// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {FlexibleAssetHandler} from "../src/core/FlexibleAssetHandler.sol";
import {IAssetHandler} from "../src/interfaces/IAssetHandler.sol";

/**
 * @title ConfigureAssetsForLiquidation
 * @notice Configura los assets con umbrales de liquidación específicos para testing
 */
contract ConfigureAssetsForLiquidation is Script {
    
    // NUEVAS DIRECCIONES desplegadas en Base Sepolia (ACTUALIZADAS)
    address constant FLEXIBLE_ASSET_HANDLER = 0x111444Fd9B2E748308057aB8983DdDa8C262cEeC;
    
    // NUEVOS Mock tokens (ACTUALIZADOS)
    address constant MOCK_ETH = 0xca09D6c5f9f5646A20b5EF71986EED5f8A86add0;
    address constant MOCK_WBTC = 0x6C2AAf9cFb130d516401Ee769074F02fae6ACb91;
    address constant MOCK_USDC = 0xAdc9649EF0468d6C73B56Dc96fF6bb527B8251A0;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==================================================");
        console.log("CONFIGURANDO ASSETS PARA TESTING DE LIQUIDACION");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("FlexibleAssetHandler:", FLEXIBLE_ASSET_HANDLER);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        FlexibleAssetHandler assetHandler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
        
        // Configurar ETH con umbral de liquidación MUY BAJO para testing
        console.log("=== CONFIGURANDO MOCK ETH ===");
        assetHandler.configureAsset(
            MOCK_ETH,
            IAssetHandler.AssetType.VAULT_BASED,
            1050000,  // 105% collateral ratio (muy agresivo)
            1020000,  // 102% liquidation ratio (SUPER BAJO para testing)
            1000 * 1e18,  // Max 1000 ETH
            200000    // 20% interest rate
        );
        console.log("ETH configurado:");
        console.log("  - Collateral Ratio: 105%");
        console.log("  - Liquidation Ratio: 102% (CRITICO)");
        console.log("");
        
        // Configurar USDC con configuración estándar
        console.log("=== CONFIGURANDO MOCK USDC ===");
        assetHandler.configureAsset(
            MOCK_USDC,
            IAssetHandler.AssetType.VAULT_BASED,
            1500000,  // 150% collateral ratio
            1200000,  // 120% liquidation ratio
            1000000 * 1e6,  // Max 1M USDC
            100000    // 10% interest rate
        );
        console.log("USDC configurado:");
        console.log("  - Collateral Ratio: 150%");
        console.log("  - Liquidation Ratio: 120%");
        console.log("");
        
        // Configurar WBTC 
        console.log("=== CONFIGURANDO MOCK WBTC ===");
        assetHandler.configureAsset(
            MOCK_WBTC,
            IAssetHandler.AssetType.VAULT_BASED,
            1400000,  // 140% collateral ratio
            1150000,  // 115% liquidation ratio
            100 * 1e8,  // Max 100 WBTC
            150000    // 15% interest rate
        );
        console.log("WBTC configurado:");
        console.log("  - Collateral Ratio: 140%");
        console.log("  - Liquidation Ratio: 115%");
        console.log("");
        
        vm.stopBroadcast();
        
        console.log("==================================================");
        console.log("CONFIGURACION DE ASSETS COMPLETADA");
        console.log("==================================================");
        console.log("Ahora puedes ejecutar test de liquidacion con:");
        console.log("ETH ratio objetivo: ~103% (entre 102% y 105%)");
        console.log("==================================================");
    }
} 
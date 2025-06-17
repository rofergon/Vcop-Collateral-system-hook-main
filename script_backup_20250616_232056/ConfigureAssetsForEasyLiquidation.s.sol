// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleAssetHandler} from "../src/core/FlexibleAssetHandler.sol";
import {IAssetHandler} from "../src/interfaces/IAssetHandler.sol";

/**
 * @title ConfigureAssetsForEasyLiquidation
 * @notice Configura assets con parámetros que facilitan el testing de liquidaciones
 * @dev Ratios más bajos para hacer liquidaciones más fáciles de alcanzar
 */
contract ConfigureAssetsForEasyLiquidation is Script {
    
    // Direcciones from deployed system
    address constant FLEXIBLE_ASSET_HANDLER = 0x111444Fd9B2E748308057aB8983DdDa8C262cEeC;
    address constant MOCK_ETH = 0xca09D6c5f9f5646A20b5EF71986EED5f8A86add0;
    address constant MOCK_USDC = 0xAdc9649EF0468d6C73B56Dc96fF6bb527B8251A0;
    address constant MOCK_WBTC = 0x6C2AAf9cFb130d516401Ee769074F02fae6ACb91;
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        
        console.log("==================================================");
        console.log("CONFIGURANDO ASSETS PARA TESTING DE LIQUIDACION FACIL");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("FlexibleAssetHandler:", FLEXIBLE_ASSET_HANDLER);
        console.log("");
        
        vm.startBroadcast(privateKey);
        
        FlexibleAssetHandler handler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
        
        // ETH - Configuración más fácil para liquidación
        console.log("=== CONFIGURANDO MOCK ETH (FACIL) ===");
        handler.configureAsset(
            MOCK_ETH,
            IAssetHandler.AssetType.MINTABLE_BURNABLE,
            1200000,    // 120% collateral ratio (MUY BAJO)
            1050000,    // 105% liquidation ratio (MUY BAJO)
            1000 * 1e18, // 1000 ETH max loan
            80000       // 8% interest rate
        );
        console.log("ETH configurado:");
        console.log("  - Collateral Ratio: 120% (FACIL)");
        console.log("  - Liquidation Ratio: 105% (MUY CRITICO)");
        console.log("");
        
        // USDC - También más fácil
        console.log("=== CONFIGURANDO MOCK USDC (FACIL) ===");
        handler.configureAsset(
            MOCK_USDC,
            IAssetHandler.AssetType.MINTABLE_BURNABLE,
            1300000,    // 130% collateral ratio
            1100000,    // 110% liquidation ratio
            1000000 * 1e6, // 1M USDC max loan
            50000       // 5% interest rate
        );
        console.log("USDC configurado:");
        console.log("  - Collateral Ratio: 130%");
        console.log("  - Liquidation Ratio: 110%");
        console.log("");
        
        // WBTC - Similar configuración fácil
        console.log("=== CONFIGURANDO MOCK WBTC (FACIL) ===");
        handler.configureAsset(
            MOCK_WBTC,
            IAssetHandler.AssetType.MINTABLE_BURNABLE,
            1250000,    // 125% collateral ratio (BAJO)
            1080000,    // 108% liquidation ratio (MUY BAJO)
            100 * 1e8,  // 100 WBTC max loan
            90000       // 9% interest rate (ALTO para acelerar)
        );
        console.log("WBTC configurado:");
        console.log("  - Collateral Ratio: 125% (BAJO)");
        console.log("  - Liquidation Ratio: 108% (CRITICO)");
        console.log("  - Interest Rate: 9% (ALTO)");
        console.log("");
        
        vm.stopBroadcast();
        
        console.log("==================================================");
        console.log("CONFIGURACION DE ASSETS FACIL COMPLETADA");
        console.log("==================================================");
        console.log("Ahora puedes probar liquidaciones con ratios bajos:");
        console.log("ETH: Entre 105% y 120%");
        console.log("USDC: Entre 110% y 130%");
        console.log("WBTC: Entre 108% y 125%");
        console.log("");
        console.log("Usa este comando:");
        console.log("make test-liquidation-complete");
        console.log("==================================================");
    }
} 
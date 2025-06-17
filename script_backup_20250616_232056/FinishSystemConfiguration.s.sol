// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {FlexibleLoanManager} from "../src/core/FlexibleLoanManager.sol";
import {FlexibleAssetHandler} from "../src/core/FlexibleAssetHandler.sol";
import {IAssetHandler} from "../src/interfaces/IAssetHandler.sol";
import {MockETH} from "../src/mocks/MockETH.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {MockWBTC} from "../src/mocks/MockWBTC.sol";

/**
 * @title FinishSystemConfiguration
 * @notice Completa la configuración del sistema después del deploy
 */
contract FinishSystemConfiguration is Script {
    
    // Direcciones desde deployed-addresses.json
    address constant GENERIC_LOAN_MANAGER = 0xd66706C24920eF1eA2b919F349ae56b5C995b431;
    address constant FLEXIBLE_LOAN_MANAGER = 0x92ea2E50733b23F23d0958dab79BBcA1e49F627a;
    address constant FLEXIBLE_ASSET_HANDLER = 0xA5688b57eD0854807085B9c73046FdE548cc43CD;
    
    // Mock tokens
    address constant MOCK_ETH = 0xBec09f97BA8730D7e58CeD55CB5957B0dccD1BE7;
    address constant MOCK_WBTC = 0x2C91b854245Be779dBDB8246FB46bf7789c1e69f;
    address constant MOCK_USDC = 0x19F3d0Ca2b49A1097906cFc641a4789807BBC497;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==================================================");
        console.log("COMPLETANDO CONFIGURACION DEL SISTEMA");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Configurar FlexibleLoanManager
        console.log("=== Configurando FlexibleLoanManager ===");
        FlexibleLoanManager flexibleManager = FlexibleLoanManager(FLEXIBLE_LOAN_MANAGER);
        FlexibleAssetHandler flexibleHandler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
        
        // Configurar asset handler
        try flexibleManager.setAssetHandler(IAssetHandler.AssetType.VAULT_BASED, FLEXIBLE_ASSET_HANDLER) {
            console.log("FlexibleLoanManager handler configurado");
        } catch {
            console.log("FlexibleLoanManager handler ya configurado");
        }
        
        // Configurar assets
        console.log("=== Configurando Assets ===");
        
        try flexibleHandler.configureAsset(
            MOCK_ETH,
            IAssetHandler.AssetType.VAULT_BASED,
            1300000,  // 130% collateral ratio
            1100000,  // 110% liquidation ratio
            1000 * 1e18,
            80000
        ) {
            console.log("ETH configurado");
        } catch {
            console.log("ETH ya configurado");
        }
        
        try flexibleHandler.configureAsset(
            MOCK_USDC,
            IAssetHandler.AssetType.VAULT_BASED,
            1100000,  // 110% collateral ratio
            1050000,  // 105% liquidation ratio
            1000000 * 1e6,
            40000
        ) {
            console.log("USDC configurado");
        } catch {
            console.log("USDC ya configurado");
        }
        
        // Proporcionar liquidez
        console.log("=== Proporcionando Liquidez ===");
        
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        
        // Mint tokens si es necesario
        uint256 currentETH = mockETH.balanceOf(deployer);
        uint256 currentUSDC = mockUSDC.balanceOf(deployer);
        
        console.log("Balance actual ETH:", currentETH / 1e18);
        console.log("Balance actual USDC:", currentUSDC / 1e6);
        
        if (currentETH < 200 * 1e18) {
            mockETH.mint(deployer, 200 * 1e18);
            console.log("200 ETH minteados");
        }
        
        if (currentUSDC < 500000 * 1e6) {
            mockUSDC.mint(deployer, 500000 * 1e6);
            console.log("500,000 USDC minteados");
        }
        
        // Proporcionar liquidez
        uint256 ethToProvide = 50 * 1e18;
        uint256 usdcToProvide = 125000 * 1e6;
        
        mockETH.approve(FLEXIBLE_ASSET_HANDLER, ethToProvide);
        mockUSDC.approve(FLEXIBLE_ASSET_HANDLER, usdcToProvide);
        
        try flexibleHandler.provideLiquidity(MOCK_ETH, ethToProvide, deployer) {
            console.log("Liquidez ETH proporcionada:", ethToProvide / 1e18);
        } catch {
            console.log("Error proporcionando liquidez ETH");
        }
        
        try flexibleHandler.provideLiquidity(MOCK_USDC, usdcToProvide, deployer) {
            console.log("Liquidez USDC proporcionada:", usdcToProvide / 1e6);
        } catch {
            console.log("Error proporcionando liquidez USDC");
        }
        
        vm.stopBroadcast();
        
        // Verificar liquidez
        console.log("=== Verificando Liquidez ===");
        uint256 ethLiquidity = flexibleHandler.getAvailableLiquidity(MOCK_ETH);
        uint256 usdcLiquidity = flexibleHandler.getAvailableLiquidity(MOCK_USDC);
        
        console.log("Liquidez ETH disponible:", ethLiquidity / 1e18);
        console.log("Liquidez USDC disponible:", usdcLiquidity / 1e6);
        
        console.log("==================================================");
        console.log("CONFIGURACION COMPLETADA");
        console.log("SISTEMA LISTO PARA TESTING");
        console.log("==================================================");
    }
} 
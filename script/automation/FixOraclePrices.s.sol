// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title FixOraclePrices
 * @notice Corrige los precios del MockOracle para testing realista
 */
contract FixOraclePrices is Script {
    
    function run() external {
        console.log("CORRIGIENDO PRECIOS DEL MOCKORACLE");
        console.log("==================================");
        console.log("");
        
        // Cargar direcciones
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        console.log("CONTRATOS:");
        console.log("  MockVCOPOracle:", mockOracle);
        console.log("");
        
        console.log("TOKENS:");
        console.log("  MockETH:", mockETH);
        console.log("  MockUSDC:", mockUSDC);
        console.log("  MockWBTC:", mockWBTC);
        console.log("");
        
        MockVCOPOracle oracle = MockVCOPOracle(mockOracle);
        
        // Verificar precios actuales
        console.log("PRECIOS ACTUALES:");
        console.log("=================");
        
        uint256 ethPrice = oracle.getPrice(mockETH, address(0));
        uint256 usdcPrice = oracle.getPrice(mockUSDC, address(0));
        uint256 wbtcPrice = oracle.getPrice(mockWBTC, address(0));
        
        console.log("ETH precio actual:", ethPrice);
        console.log("USDC precio actual:", usdcPrice);
        console.log("WBTC precio actual:", wbtcPrice);
        console.log("");
        
        // Calcular precios corregidos
        console.log("CALCULANDO PRECIOS CORREGIDOS:");
        console.log("==============================");
        
        // Oracle usa 6 decimales para precios
        uint256 newETHPrice = 2500000000; // $2500.00 * 1e6
        uint256 newUSDCPrice = 1000000;   // $1.00 * 1e6  
        uint256 newWBTCPrice = 50000000000; // $50000.00 * 1e6
        
        console.log("Nuevo ETH precio: $2500.00 =", newETHPrice);
        console.log("Nuevo USDC precio: $1.00 =", newUSDCPrice);
        console.log("Nuevo WBTC precio: $50000.00 =", newWBTCPrice);
        console.log("");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("APLICANDO PRECIOS CORREGIDOS:");
        console.log("=============================");
        
        // Configurar precios realistas
        oracle.setMockPrice(mockETH, mockUSDC, newETHPrice);
        console.log("[OK] ETH precio configurado a $2500");
        
        oracle.setMockPrice(mockUSDC, mockUSDC, newUSDCPrice);
        console.log("[OK] USDC precio configurado a $1");
        
        oracle.setMockPrice(mockWBTC, mockUSDC, newWBTCPrice);
        console.log("[OK] WBTC precio configurado a $50000");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("VERIFICACION POST-CONFIGURACION:");
        console.log("================================");
        
        uint256 verifyETH = oracle.getPrice(mockETH, address(0));
        uint256 verifyUSDC = oracle.getPrice(mockUSDC, address(0));
        uint256 verifyWBTC = oracle.getPrice(mockWBTC, address(0));
        
        console.log("ETH precio verificado:", verifyETH);
        console.log("USDC precio verificado:", verifyUSDC);
        console.log("WBTC precio verificado:", verifyWBTC);
        console.log("");
        
        // Calcular LTV ejemplo
        console.log("CALCULO DE LTV EJEMPLO:");
        console.log("=======================");
        console.log("Collateral: 1 ETH = $2500");
        console.log("Loan: 2250 USDC = $2250");
        console.log("LTV esperado: 2250/2500 = 90%");
        console.log("Ratio esperado: 2500/2250 = 111.11%");
        console.log("");
        
        console.log("RESULTADO ESPERADO CON PRECIOS CORREGIDOS:");
        console.log("==========================================");
        console.log("- 1 ETH collateral = $2500 valor");
        console.log("- 2250 USDC loan = $2250 valor");
        console.log("- LTV = 90% (SEGURO)");
        console.log("- Ratio = 111.11% (por encima del limite 104.17%)");
        console.log("- NO deberia liquidarse");
        console.log("");
        
        console.log("PROXIMOS PASOS:");
        console.log("===============");
        console.log("1. Verificar posicion existente con precios corregidos");
        console.log("2. Si sigue siendo liquidable, el problema esta en otro lado");
        console.log("3. Crear nueva posicion de prueba");
    }
} 
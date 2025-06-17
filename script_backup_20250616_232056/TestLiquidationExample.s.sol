// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {LiquidationHelper} from "./LiquidationHelper.sol";

/**
 * @title TestLiquidationExample
 * @notice Script de ejemplo que muestra cómo usar el LiquidationHelper
 * @dev Este script solo despliega el helper y muestra ejemplos de uso
 */
contract TestLiquidationExample is Script {
    
    // Direcciones de contratos desplegados en Base Sepolia
    address constant GENERIC_LOAN_MANAGER = 0xF8724317315B1BA8ac1a0f30Ac407e9fCf20442B;
    address constant FLEXIBLE_LOAN_MANAGER = 0xFf120b0Eb71131EFA1f8C93331B042cB4C0F8Ec7;
    address constant MOCK_ETH = 0x87bb55de00f7D2791dbF3461A110D99bB47cF62F;
    address constant MOCK_WBTC = 0x4Cd911B122e27e5EF684e3553B8187525725a399;
    address constant MOCK_USDC = 0xcbeC2cAa97A660434aA5420d667b3f1e60E2C17B;
    
    LiquidationHelper public liquidationHelper;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==================================================");
        console.log("DESPLEGANDO Y CONFIGURANDO LIQUIDATION HELPER");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy LiquidationHelper
        liquidationHelper = new LiquidationHelper();
        
        vm.stopBroadcast();
        
        console.log("LiquidationHelper desplegado en:", address(liquidationHelper));
        console.log("");
        
        // Show usage examples
        _showUsageExamples();
        
        // Show contract information
        _showContractInfo();
        
        console.log("==================================================");
        console.log("DESPLIEGUE COMPLETADO");
        console.log("Helper Address:", address(liquidationHelper));
        console.log("==================================================");
    }
    
    function _showUsageExamples() internal view {
        console.log("==================================================");
        console.log("EJEMPLOS DE USO DEL LIQUIDATION HELPER");
        console.log("==================================================");
        console.log("");
        
        console.log("1. CREAR POSICION RIESGOSA:");
        console.log("   helper.createRiskyPosition(");
        console.log("     loanManager,    // Direccion del loan manager");
        console.log("     collateralAsset, // Token de colateral (ETH/WBTC)");
        console.log("     loanAsset,      // Token de prestamo (USDC)");
        console.log("     collateralAmount, // Cantidad de colateral");
        console.log("     loanAmount,     // Cantidad a pedir prestado");
        console.log("     borrower        // Direccion del borrower");
        console.log("   )");
        console.log("");
        
        console.log("2. VERIFICAR LIQUIDABILIDAD:");
        console.log("   (bool canLiquidate, uint256 ratio, uint256 debt) = helper.checkLiquidationStatus(");
        console.log("     loanManager,");
        console.log("     positionId");
        console.log("   )");
        console.log("");
        
        console.log("3. EJECUTAR LIQUIDACION:");
        console.log("   helper.executeLiquidation(");
        console.log("     loanManager,");
        console.log("     positionId,");
        console.log("     liquidator      // Quien recibe las recompensas");
        console.log("   )");
        console.log("");
    }
    
    function _showContractInfo() internal view {
        console.log("==================================================");
        console.log("DIRECCIONES DE CONTRATOS (Base Sepolia)");
        console.log("==================================================");
        console.log("");
        
        console.log("LOAN MANAGERS:");
        console.log("  GenericLoanManager: ", GENERIC_LOAN_MANAGER);
        console.log("  FlexibleLoanManager:", FLEXIBLE_LOAN_MANAGER);
        console.log("");
        
        console.log("MOCK TOKENS:");
        console.log("  ETH: ", MOCK_ETH);
        console.log("  WBTC:", MOCK_WBTC);
        console.log("  USDC:", MOCK_USDC);
        console.log("");
        
        console.log("LIQUIDATION HELPER:");
        console.log("  Helper:", address(liquidationHelper));
        console.log("");
        
        console.log("==================================================");
        console.log("PASOS PARA TESTEAR LIQUIDACIONES:");
        console.log("==================================================");
        console.log("1. Obtener tokens mock (ETH, WBTC, USDC)");
        console.log("2. Aprobar tokens al LiquidationHelper");
        console.log("3. Crear posicion riesgosa con createRiskyPosition()");
        console.log("4. Esperar acumulacion de interes o cambio de precios");
        console.log("5. Verificar liquidabilidad con checkLiquidationStatus()");
        console.log("6. Ejecutar liquidacion con executeLiquidation()");
        console.log("7. Verificar recompensas recibidas");
        console.log("");
    }
} 
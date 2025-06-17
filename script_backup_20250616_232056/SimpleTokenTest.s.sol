// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {LiquidationHelper} from "./LiquidationHelper.sol";
import {MockETH} from "../src/mocks/MockETH.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

/**
 * @title SimpleTokenTest
 * @notice Script simple para mintear tokens y probar liquidaciones
 */
contract SimpleTokenTest is Script {
    
    // Direcciones desplegadas
    address constant GENERIC_LOAN_MANAGER = 0xF8724317315B1BA8ac1a0f30Ac407e9fCf20442B;
    address constant LIQUIDATION_HELPER = 0xbD2329ad3cCcc4932B847014572F429bc8B4b2f5;
    address constant MOCK_ETH = 0x87bb55de00f7D2791dbF3461A110D99bB47cF62F;
    address constant MOCK_USDC = 0xcbeC2cAa97A660434aA5420d667b3f1e60E2C17B;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== TEST SIMPLE DE TOKENS Y LIQUIDACION ===");
        console.log("Deployer:", deployer);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        LiquidationHelper helper = LiquidationHelper(LIQUIDATION_HELPER);
        
        // Paso 1: Mintear tokens
        console.log("Paso 1: Minteando tokens...");
        mockETH.mint(deployer, 100 * 1e18);
        mockUSDC.mint(deployer, 1000000 * 1e6);
        
        console.log("Balances despues de mintear:");
        console.log("  ETH:", mockETH.balanceOf(deployer) / 1e18);
        console.log("  USDC:", mockUSDC.balanceOf(deployer) / 1e6);
        console.log("");
        
        // Paso 2: Crear posicion riesgosa
        console.log("Paso 2: Creando posicion riesgosa...");
        mockETH.approve(LIQUIDATION_HELPER, 5 * 1e18);
        
        uint256 positionId = helper.createRiskyPosition(
            GENERIC_LOAN_MANAGER,
            MOCK_ETH,
            MOCK_USDC,
            5 * 1e18,        // 5 ETH collateral
            12000 * 1e6,     // 12,000 USDC loan (80% LTV)
            deployer
        );
        
        console.log("Posicion creada con ID:", positionId);
        
        // Paso 3: Verificar estado
        (bool canLiquidate, uint256 ratio, uint256 debt) = 
            helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        console.log("Estado inicial:");
        console.log("  Ratio:", ratio);
        console.log("  Deuda:", debt / 1e6, "USDC");
        console.log("  Liquidable:", canLiquidate);
        console.log("");
        
        // Paso 4: Simular tiempo para acumular interes
        console.log("Paso 4: Simulando 2 anos de interes...");
        vm.warp(block.timestamp + 730 days); // 2 años
        
        helper.accrueInterest(GENERIC_LOAN_MANAGER, positionId);
        
        (bool canLiquidateAfter, uint256 ratioAfter, uint256 debtAfter) = 
            helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        console.log("Estado despues de 2 anos:");
        console.log("  Ratio:", ratioAfter);
        console.log("  Deuda:", debtAfter / 1e6, "USDC");
        console.log("  Liquidable:", canLiquidateAfter);
        console.log("");
        
        // Paso 5: Intentar liquidacion si es posible
        if (canLiquidateAfter) {
            console.log("Paso 5: Ejecutando liquidacion...");
            
            uint256 ethBefore = mockETH.balanceOf(deployer);
            uint256 usdcBefore = mockUSDC.balanceOf(deployer);
            
            mockUSDC.approve(LIQUIDATION_HELPER, debtAfter);
            helper.executeLiquidation(GENERIC_LOAN_MANAGER, positionId, deployer);
            
            uint256 ethAfter = mockETH.balanceOf(deployer);
            uint256 usdcAfter = mockUSDC.balanceOf(deployer);
            
            console.log("Resultados:");
            console.log("  ETH antes:", ethBefore / 1e18);
            console.log("  ETH despues:", ethAfter / 1e18);
            console.log("  USDC antes:", usdcBefore / 1e6);
            console.log("  USDC despues:", usdcAfter / 1e6);
            
            if (ethAfter > ethBefore) {
                console.log("EXITO: Ganancia de", (ethAfter - ethBefore) / 1e18, "ETH");
            }
            
        } else {
            console.log("Paso 5: Posicion aun no liquidable");
        }
        
        vm.stopBroadcast();
        
        console.log("=== TEST COMPLETADO ===");
    }
} 
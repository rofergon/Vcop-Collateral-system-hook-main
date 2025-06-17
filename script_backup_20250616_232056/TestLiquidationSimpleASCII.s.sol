// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MockETH} from "../src/mocks/MockETH.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";
import {LiquidationHelper} from "./LiquidationHelper.sol";

/**
 * @title TestLiquidationSimpleASCII
 * @notice Test de liquidacion completo sin caracteres Unicode
 * @dev Crea posicion segura, simula deterioro, ejecuta liquidacion
 */
contract TestLiquidationSimpleASCII is Script {
    
    // Direcciones desde deployed-addresses.json (ACTUALIZADAS)
    address constant GENERIC_LOAN_MANAGER = 0xe2AA5803F1baD51f092650De840Ea79547F26b7d;
    address constant LIQUIDATION_HELPER = 0xbD2329ad3cCcc4932B847014572F429bc8B4b2f5;
    address constant MOCK_ETH = 0x388F7D72FD879725E40d893Fc1b5455036C7fd19;
    address constant MOCK_USDC = 0x009A513d97e55C77060C303f74eE66a991Bd3f08;
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        
        console.log("================================================");
        console.log("TEST DE LIQUIDACION COMPLETO");
        console.log("================================================");
        console.log("Deployer:", deployer);
        console.log("GenericLoanManager:", GENERIC_LOAN_MANAGER);
        console.log("LiquidationHelper:", LIQUIDATION_HELPER);
        console.log("");
        
        vm.startBroadcast(privateKey);
        
        // FASE 1: Crear posicion SEGURA (ratio alto)
        _createSafePosition(deployer);
        
        vm.stopBroadcast();
    }
    
    function _createSafePosition(address user) internal {
        LiquidationHelper helper = LiquidationHelper(LIQUIDATION_HELPER);
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        
        console.log("=== FASE 1: CREANDO POSICION SEGURA ===");
        
        // Verificar balances iniciales
        uint256 ethBalance = mockETH.balanceOf(user) / 1e18;
        uint256 usdcBalance = mockUSDC.balanceOf(user) / 1e6;
        
        console.log("Balances iniciales:");
        console.log("  ETH:", ethBalance);
        console.log("  USDC:", usdcBalance);
        
        // Configurar approvals para el helper
        mockETH.approve(LIQUIDATION_HELPER, type(uint256).max);
        mockUSDC.approve(LIQUIDATION_HELPER, type(uint256).max);
        console.log("Approvals configurados");
        console.log("");
        
        // CREAR POSICION SEGURA
        // ETH = $2,500, entonces:
        // 2 ETH = $5,000 colateral
        // $1,500 USDC loan = 30% LTV = 333% collateral ratio
        uint256 collateralETH = 2 * 1e18;  // 2 ETH ($5,000)
        uint256 loanUSDC = 1500 * 1e6;     // $1,500 USDC (30% LTV)
        
        console.log("Configuracion de posicion SEGURA:");
        console.log("  Colateral: 2 ETH (~$5,000)");
        console.log("  Prestamo: 1,500 USDC");
        console.log("  LTV esperado: 30%");
        console.log("  Collateral Ratio esperado: 333%");
        console.log("");
        
        // Crear la posicion
        uint256 positionId = helper.createRiskyPosition(
            GENERIC_LOAN_MANAGER,
            MOCK_ETH,
            MOCK_USDC,
            collateralETH,
            loanUSDC,
            user
        );
        
        console.log("POSICION SEGURA creada con ID:", positionId);
        
        // Verificar estado inicial
        (bool canLiquidateInitial, uint256 initialRatio, uint256 initialDebt) = 
            helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        console.log("Estado inicial:");
        console.log("  Ratio colateralizacion:", initialRatio / 10000, "%");
        console.log("  Deuda total:", initialDebt / 1e6, "USDC");
        console.log("  Es liquidable:", canLiquidateInitial ? "SI" : "NO");
        console.log("");
        
        if (canLiquidateInitial) {
            console.log("ERROR: La posicion NO deberia ser liquidable inicialmente!");
            return;
        }
        
        console.log("POSICION SEGURA CREADA CORRECTAMENTE");
        console.log("");
        
        // FASE 2: Simular deterioro de la posicion
        _simulatePositionDeterioration(helper, positionId);
        
        // FASE 3: Ejecutar liquidacion si es posible
        _executeLiquidationIfPossible(helper, positionId, user);
    }
    
    function _simulatePositionDeterioration(LiquidationHelper helper, uint256 positionId) internal {
        console.log("=== FASE 2: SIMULANDO DETERIORO DE POSICION ===");
        
        // Acelerar tiempo para acumular interes
        console.log("Acelerando tiempo 365 dias para acumular interes...");
        vm.warp(block.timestamp + 365 days);
        
        // Acumular interes
        helper.accrueInterest(GENERIC_LOAN_MANAGER, positionId);
        
        // Verificar nuevo estado
        (bool canLiquidateAfter, uint256 ratioAfter, uint256 debtAfter) = 
            helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        console.log("Estado despues de 1 anio:");
        console.log("  Ratio colateralizacion:", ratioAfter / 10000, "%");
        console.log("  Deuda total:", debtAfter / 1e6, "USDC");
        console.log("  Es liquidable:", canLiquidateAfter ? "SI" : "NO");
        console.log("");
        
        // Si aun no es liquidable, acelerar mas tiempo
        if (!canLiquidateAfter) {
            console.log("Posicion aun segura. Acelerando 2 anios adicionales...");
            vm.warp(block.timestamp + 2 * 365 days);
            helper.accrueInterest(GENERIC_LOAN_MANAGER, positionId);
            
            (canLiquidateAfter, ratioAfter, debtAfter) = 
                helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
            
            console.log("Estado despues de 3 anios TOTAL:");
            console.log("  Ratio colateralizacion:", ratioAfter / 10000, "%");
            console.log("  Deuda total:", debtAfter / 1e6, "USDC");
            console.log("  Es liquidable:", canLiquidateAfter ? "SI" : "NO");
            console.log("");
        }
    }
    
    function _executeLiquidationIfPossible(LiquidationHelper helper, uint256 positionId, address user) internal {
        console.log("=== FASE 3: EJECUTANDO LIQUIDACION ===");
        
        (bool canLiquidate, uint256 currentRatio, uint256 currentDebt) = 
            helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        if (!canLiquidate) {
            console.log("La posicion AUN NO es liquidable.");
            console.log("Ratio actual:", currentRatio / 10000, "%");
            console.log("Para probar liquidaciones, necesitas:");
            console.log("  1. Ratio < 110% (liquidation threshold)");
            console.log("  2. Mas acumulacion de interes");
            console.log("  3. O reducir el collateral ratio en la configuracion");
            return;
        }
        
        console.log("POSICION ES LIQUIDABLE!");
        console.log("Ratio actual:", currentRatio / 10000, "%");
        console.log("Deuda a pagar:", currentDebt / 1e6, "USDC");
        console.log("");
        
        // Obtener balances del liquidador antes
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        
        uint256 ethBalanceBefore = mockETH.balanceOf(user);
        uint256 usdcBalanceBefore = mockUSDC.balanceOf(user);
        
        console.log("Balances del liquidador ANTES:");
        console.log("  ETH:", ethBalanceBefore / 1e18);
        console.log("  USDC:", usdcBalanceBefore / 1e6);
        console.log("");
        
        // Ejecutar liquidacion
        console.log("Ejecutando liquidacion...");
        try helper.executeLiquidation(GENERIC_LOAN_MANAGER, positionId, user) {
            console.log("LIQUIDACION EXITOSA!");
            
            // Verificar balances despues
            uint256 ethBalanceAfter = mockETH.balanceOf(user);
            uint256 usdcBalanceAfter = mockUSDC.balanceOf(user);
            
            console.log("Balances del liquidador DESPUES:");
            console.log("  ETH:", ethBalanceAfter / 1e18);
            console.log("  USDC:", usdcBalanceAfter / 1e6);
            console.log("");
            
            console.log("GANANCIAS DE LA LIQUIDACION:");
            console.log("  ETH ganado:", (ethBalanceAfter - ethBalanceBefore) / 1e18);
            console.log("  USDC gastado:", (usdcBalanceBefore - usdcBalanceAfter) / 1e6);
            console.log("");
            
            // Verificar que la posicion fue cerrada
            (bool stillLiquidable,,) = helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
            if (!stillLiquidable) {
                console.log("Posicion cerrada correctamente");
            } else {
                console.log("Posicion aun existe - posible liquidacion parcial");
            }
            
        } catch Error(string memory reason) {
            console.log("LIQUIDACION FALLO:", reason);
        } catch {
            console.log("LIQUIDACION FALLO: Error desconocido");
        }
        
        console.log("");
        console.log("=== TEST DE LIQUIDACION COMPLETADO ===");
    }
} 
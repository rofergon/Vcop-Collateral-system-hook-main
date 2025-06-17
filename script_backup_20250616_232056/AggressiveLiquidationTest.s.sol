// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {LiquidationHelper} from "./LiquidationHelper.sol";
import {MockETH} from "../src/mocks/MockETH.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

/**
 * @title AggressiveLiquidationTest
 * @notice Script con ratios agresivos para forzar liquidaciones
 */
contract AggressiveLiquidationTest is Script {
    
    address constant GENERIC_LOAN_MANAGER = 0xF8724317315B1BA8ac1a0f30Ac407e9fCf20442B;
    address constant LIQUIDATION_HELPER = 0xbD2329ad3cCcc4932B847014572F429bc8B4b2f5;
    address constant MOCK_ETH = 0x87bb55de00f7D2791dbF3461A110D99bB47cF62F;
    address constant MOCK_USDC = 0xcbeC2cAa97A660434aA5420d667b3f1e60E2C17B;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== TEST AGRESIVO DE LIQUIDACION ===");
        console.log("Deployer:", deployer);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        LiquidationHelper helper = LiquidationHelper(LIQUIDATION_HELPER);
        
        // Asegurar tokens suficientes
        mockETH.mint(deployer, 50 * 1e18);
        mockUSDC.mint(deployer, 500000 * 1e6);
        
        console.log("Tokens disponibles:");
        console.log("  ETH:", mockETH.balanceOf(deployer) / 1e18);
        console.log("  USDC:", mockUSDC.balanceOf(deployer) / 1e6);
        console.log("");
        
        // TEST 1: Posicion muy agresiva (84% LTV inicial)
        console.log("=== TEST 1: POSICION 84% LTV ===");
        _testAggressivePosition(helper, mockETH, mockUSDC, deployer, 1, 2520); // 1 ETH -> 2520 USDC (84% de 3000)
        
        // TEST 2: Posicion extremadamente agresiva (90% LTV inicial)
        console.log("=== TEST 2: POSICION 90% LTV ===");
        _testAggressivePosition(helper, mockETH, mockUSDC, deployer, 1, 2700); // 1 ETH -> 2700 USDC (90% de 3000)
        
        // TEST 3: Posicion al limite (95% LTV inicial)
        console.log("=== TEST 3: POSICION 95% LTV ===");
        _testAggressivePosition(helper, mockETH, mockUSDC, deployer, 1, 2850); // 1 ETH -> 2850 USDC (95% de 3000)
        
        vm.stopBroadcast();
        
        console.log("=== TODOS LOS TESTS COMPLETADOS ===");
    }
    
    function _testAggressivePosition(
        LiquidationHelper helper,
        MockETH mockETH,
        MockUSDC mockUSDC,
        address user,
        uint256 ethAmount,
        uint256 usdcLoan
    ) internal {
        mockETH.approve(LIQUIDATION_HELPER, ethAmount * 1e18);
        
        uint256 positionId = helper.createRiskyPosition(
            GENERIC_LOAN_MANAGER,
            MOCK_ETH,
            MOCK_USDC,
            ethAmount * 1e18,
            usdcLoan * 1e6,
            user
        );
        
        console.log("Posicion creada - ID:", positionId);
        console.log("  Colateral:", ethAmount, "ETH");
        console.log("  Prestamo:", usdcLoan, "USDC");
        
        // Estado inicial
        (bool canLiquidateInitial, uint256 initialRatio, uint256 initialDebt) = 
            helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        console.log("Estado inicial:");
        console.log("  Ratio:", initialRatio);
        console.log("  Deuda:", initialDebt / 1e6, "USDC");
        console.log("  Liquidable:", canLiquidateInitial);
        
        if (canLiquidateInitial) {
            console.log("  RESULTADO: Liquidable desde el inicio!");
            _executeLiquidation(helper, mockETH, mockUSDC, user, positionId);
            return;
        }
        
        // Probar con 30 dias
        vm.warp(block.timestamp + 30 days);
        helper.accrueInterest(GENERIC_LOAN_MANAGER, positionId);
        
        (bool canLiquidate30, uint256 ratio30, uint256 debt30) = 
            helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        console.log("Despues de 30 dias:");
        console.log("  Ratio:", ratio30);
        console.log("  Deuda:", debt30 / 1e6, "USDC");
        console.log("  Liquidable:", canLiquidate30);
        
        if (canLiquidate30) {
            console.log("  RESULTADO: Liquidable despues de 30 dias!");
            _executeLiquidation(helper, mockETH, mockUSDC, user, positionId);
            return;
        }
        
        // Probar con 90 dias
        vm.warp(block.timestamp + 60 days); // +60 más = 90 total
        helper.accrueInterest(GENERIC_LOAN_MANAGER, positionId);
        
        (bool canLiquidate90, uint256 ratio90, uint256 debt90) = 
            helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        console.log("Despues de 90 dias:");
        console.log("  Ratio:", ratio90);
        console.log("  Deuda:", debt90 / 1e6, "USDC");
        console.log("  Liquidable:", canLiquidate90);
        
        if (canLiquidate90) {
            console.log("  RESULTADO: Liquidable despues de 90 dias!");
            _executeLiquidation(helper, mockETH, mockUSDC, user, positionId);
        } else {
            console.log("  RESULTADO: Aun no liquidable despues de 90 dias");
        }
        
        console.log("");
    }
    
    function _executeLiquidation(
        LiquidationHelper helper,
        MockETH mockETH,
        MockUSDC mockUSDC,
        address user,
        uint256 positionId
    ) internal {
        (, , uint256 debt) = helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        uint256 ethBefore = mockETH.balanceOf(user);
        uint256 usdcBefore = mockUSDC.balanceOf(user);
        
        console.log("  Ejecutando liquidacion...");
        console.log("    ETH antes:", ethBefore / 1e18);
        console.log("    USDC antes:", usdcBefore / 1e6);
        console.log("    Deuda a pagar:", debt / 1e6, "USDC");
        
        mockUSDC.approve(LIQUIDATION_HELPER, debt);
        helper.executeLiquidation(GENERIC_LOAN_MANAGER, positionId, user);
        
        uint256 ethAfter = mockETH.balanceOf(user);
        uint256 usdcAfter = mockUSDC.balanceOf(user);
        
        console.log("    ETH despues:", ethAfter / 1e18);
        console.log("    USDC despues:", usdcAfter / 1e6);
        
        int256 ethGain = int256(ethAfter) - int256(ethBefore);
        int256 usdcCost = int256(usdcBefore) - int256(usdcAfter);
        
        console.log("  Resultados:");
        if (ethGain > 0) {
            console.log("    ETH ganado:", uint256(ethGain) / 1e18);
        }
        console.log("    USDC gastado:", uint256(usdcCost) / 1e6);
        
        if (ethGain > 0) {
            console.log("    LIQUIDACION EXITOSA CON RECOMPENSAS!");
        } else {
            console.log("    LIQUIDACION SIN RECOMPENSAS");
        }
    }
} 
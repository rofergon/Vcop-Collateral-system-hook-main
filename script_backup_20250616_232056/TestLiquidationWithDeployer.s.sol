// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {LiquidationHelper} from "./LiquidationHelper.sol";

// Import mock contracts
import {MockETH} from "../src/mocks/MockETH.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {MockWBTC} from "../src/mocks/MockWBTC.sol";

/**
 * @title TestLiquidationWithDeployer
 * @notice Script que usa el deployer como borrower y liquidator para evitar problemas de approvals
 * @dev Usa las direcciones reales desplegadas en Base Sepolia
 */
contract TestLiquidationWithDeployer is Script {
    
    // Direcciones de contratos desplegados en Base Sepolia
    address constant GENERIC_LOAN_MANAGER = 0xF8724317315B1BA8ac1a0f30Ac407e9fCf20442B;
    address constant FLEXIBLE_LOAN_MANAGER = 0xFf120b0Eb71131EFA1f8C93331B042cB4C0F8Ec7;
    address constant LIQUIDATION_HELPER = 0xbD2329ad3cCcc4932B847014572F429bc8B4b2f5;
    
    // Mock tokens
    address constant MOCK_ETH = 0x87bb55de00f7D2791dbF3461A110D99bB47cF62F;
    address constant MOCK_WBTC = 0x4Cd911B122e27e5EF684e3553B8187525725a399;
    address constant MOCK_USDC = 0xcbeC2cAa97A660434aA5420d667b3f1e60E2C17B;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==================================================");
        console.log("TESTEANDO LIQUIDACIONES CON DEPLOYER");
        console.log("==================================================");
        console.log("Deployer (Borrower/Liquidator):", deployer);
        console.log("LiquidationHelper:", LIQUIDATION_HELPER);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Mint additional tokens if needed
        console.log("PASO 1: Verificando y minteando tokens adicionales...");
        _ensureTokenBalances(deployer);
        
        // Step 2: Test liquidation scenario
        console.log("PASO 2: Ejecutando test de liquidacion...");
        _testLiquidationScenario(deployer);
        
        vm.stopBroadcast();
        
        console.log("==================================================");
        console.log("TEST DE LIQUIDACION COMPLETADO");
        console.log("==================================================");
    }
    
    function _ensureTokenBalances(address user) internal {
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        MockWBTC mockWBTC = MockWBTC(MOCK_WBTC);
        
        uint256 ethBalance = mockETH.balanceOf(user);
        uint256 usdcBalance = mockUSDC.balanceOf(user);
        uint256 wbtcBalance = mockWBTC.balanceOf(user);
        
        console.log("Balances actuales:");
        console.log("  ETH:", ethBalance / 1e18);
        console.log("  USDC:", usdcBalance / 1e6);
        console.log("  WBTC:", wbtcBalance / 1e8);
        
        // Mint additional tokens if needed
        if (ethBalance < 20 * 1e18) {
            mockETH.mint(user, 50 * 1e18);
            console.log("  Minteado 50 ETH adicionales");
        }
        
        if (usdcBalance < 200000 * 1e6) {
            mockUSDC.mint(user, 500000 * 1e6);
            console.log("  Minteado 500,000 USDC adicionales");
        }
        
        if (wbtcBalance < 5 * 1e8) {
            mockWBTC.mint(user, 10 * 1e8);
            console.log("  Minteado 10 WBTC adicionales");
        }
        
        console.log("Nuevos balances:");
        console.log("  ETH:", mockETH.balanceOf(user) / 1e18);
        console.log("  USDC:", mockUSDC.balanceOf(user) / 1e6);
        console.log("  WBTC:", mockWBTC.balanceOf(user) / 1e8);
        console.log("");
    }
    
    function _testLiquidationScenario(address user) internal {
        LiquidationHelper helper = LiquidationHelper(LIQUIDATION_HELPER);
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        
        console.log("=== CREANDO POSICION RIESGOSA ===");
        
        // Approve helper to spend user's ETH
        mockETH.approve(LIQUIDATION_HELPER, 2 * 1e18);
        console.log("Aprobado 2 ETH para LiquidationHelper");
        
        // Create risky position (2 ETH collateral, 4800 USDC loan = ~80% LTV)
        uint256 positionId = helper.createRiskyPosition(
            GENERIC_LOAN_MANAGER,
            MOCK_ETH,
            MOCK_USDC,
            2 * 1e18,        // 2 ETH collateral (~$6000)
            4800 * 1e6,      // 4800 USDC loan (80% LTV)
            user
        );
        
        console.log("Posicion creada con ID:", positionId);
        
        // Check initial status
        (bool canLiquidateInitial, uint256 initialRatio, uint256 initialDebt) = 
            helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        console.log("Estado inicial:");
        console.log("  Ratio colateralizacion:", initialRatio);
        console.log("  Deuda total:", initialDebt / 1e6, "USDC");
        console.log("  Es liquidable:", canLiquidateInitial);
        console.log("");
        
        console.log("=== SIMULANDO ACUMULACION DE INTERES (180 DIAS) ===");
        
        // Fast forward time to accrue more interest (6 months)
        vm.warp(block.timestamp + 180 days); 
        
        // Update interest
        helper.accrueInterest(GENERIC_LOAN_MANAGER, positionId);
        
        // Check status after interest accrual
        (bool canLiquidateAfter, uint256 ratioAfter, uint256 debtAfter) = 
            helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        console.log("Estado despues de 180 dias:");
        console.log("  Ratio colateralizacion:", ratioAfter);
        console.log("  Deuda total:", debtAfter / 1e6, "USDC");
        console.log("  Es liquidable:", canLiquidateAfter);
        console.log("");
        
        // If still not liquidatable, try with even more extreme conditions
        if (!canLiquidateAfter) {
            console.log("=== PROBANDO CON CONDICIONES MAS EXTREMAS ===");
            
            // Try 1 year forward
            vm.warp(block.timestamp + 365 days);
            helper.accrueInterest(GENERIC_LOAN_MANAGER, positionId);
            
            (bool canLiquidateExtreme, uint256 ratioExtreme, uint256 debtExtreme) = 
                helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
            
            console.log("Estado despues de 1.5 anios:");
            console.log("  Ratio colateralizacion:", ratioExtreme);
            console.log("  Deuda total:", debtExtreme / 1e6, "USDC");
            console.log("  Es liquidable:", canLiquidateExtreme);
            
            if (canLiquidateExtreme) {
                canLiquidateAfter = true;
                debtAfter = debtExtreme;
            }
        }
        
        if (canLiquidateAfter) {
            console.log("=== EJECUTANDO LIQUIDACION ===");
            
            // Get user balances before
            uint256 userETHBefore = mockETH.balanceOf(user);
            uint256 userUSDCBefore = mockUSDC.balanceOf(user);
            
            console.log("Balances antes de liquidacion:");
            console.log("  ETH:", userETHBefore / 1e18);
            console.log("  USDC:", userUSDCBefore / 1e6);
            
            // Approve helper to spend user's USDC for liquidation
            mockUSDC.approve(LIQUIDATION_HELPER, debtAfter);
            console.log("Aprobado", debtAfter / 1e6, "USDC para liquidacion");
            
            // Execute liquidation (user liquidates their own position for testing)
            helper.executeLiquidation(GENERIC_LOAN_MANAGER, positionId, user);
            
            // Get user balances after
            uint256 userETHAfter = mockETH.balanceOf(user);
            uint256 userUSDCAfter = mockUSDC.balanceOf(user);
            
            console.log("Balances despues de liquidacion:");
            console.log("  ETH:", userETHAfter / 1e18);
            console.log("  USDC:", userUSDCAfter / 1e6);
            
            // Calculate results
            int256 ethChange = int256(userETHAfter) - int256(userETHBefore);
            int256 usdcChange = int256(userUSDCAfter) - int256(userUSDCBefore);
            
            console.log("Cambios en balance:");
            if (ethChange >= 0) {
                console.log("  ETH ganado:", uint256(ethChange) / 1e18);
            } else {
                console.log("  ETH perdido:", uint256(-ethChange) / 1e18);
            }
            
            if (usdcChange >= 0) {
                console.log("  USDC ganado:", uint256(usdcChange) / 1e6);
            } else {
                console.log("  USDC gastado:", uint256(-usdcChange) / 1e6);
            }
            
            if (ethChange > 0 || usdcChange > 0) {
                console.log("EXITO: Liquidacion completada con recompensas!");
            } else {
                console.log("ADVERTENCIA: Liquidacion no genero ganancias netas");
            }
            
        } else {
            console.log("RESULTADO: Posicion aun no es liquidable");
            console.log("Nota: Puede necesitar ratios mas riesgosos o mas tiempo");
        }
        
        console.log("");
    }
} 
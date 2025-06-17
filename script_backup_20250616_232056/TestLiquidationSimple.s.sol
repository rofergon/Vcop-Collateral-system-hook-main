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
 * @title TestLiquidationSimple
 * @notice Simplified liquidation test using deployer as main actor
 * @dev Avoids complex approval issues by using deployer for all operations
 */
contract TestLiquidationSimple is Script {
    
    // NEWEST DIRECCIONES con _getAssetValue CORREGIDO
    address constant GENERIC_LOAN_MANAGER = 0xf27d7DC43EB841dA532e637eF0a875c035001d5A;
    address constant FLEXIBLE_LOAN_MANAGER = 0x2c52369349A10395bc0ae52D6622cDc5A770F1e8;
    address constant LIQUIDATION_HELPER = 0xbD2329ad3cCcc4932B847014572F429bc8B4b2f5;
    
    // NUEVOS Mock tokens (ACTUALIZADOS)
    address constant MOCK_ETH = 0xca09D6c5f9f5646A20b5EF71986EED5f8A86add0;
    address constant MOCK_WBTC = 0x6C2AAf9cFb130d516401Ee769074F02fae6ACb91;
    address constant MOCK_USDC = 0xAdc9649EF0468d6C73B56Dc96fF6bb527B8251A0;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==================================================");
        console.log("LIQUIDATION TEST SIMPLIFICADO");
        console.log("==================================================");
        console.log("Deployer (Actor Principal):", deployer);
        console.log("LiquidationHelper:", LIQUIDATION_HELPER);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Setup tokens and balances
        console.log("PASO 1: Configurando tokens...");
        _setupTokens(deployer);
        
        // Step 2: Setup approvals
        console.log("PASO 2: Configurando approvals...");
        _setupApprovals(deployer);
        
        // Step 3: Execute liquidation test
        console.log("PASO 3: Ejecutando test de liquidacion...");
        _executeLiquidationTest(deployer);
        
        vm.stopBroadcast();
        
        console.log("==================================================");
        console.log("TEST COMPLETADO");
        console.log("==================================================");
    }
    
    function _setupTokens(address user) internal {
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        MockWBTC mockWBTC = MockWBTC(MOCK_WBTC);
        
        // Check current balances
        uint256 ethBalance = mockETH.balanceOf(user);
        uint256 usdcBalance = mockUSDC.balanceOf(user);
        uint256 wbtcBalance = mockWBTC.balanceOf(user);
        
        console.log("Balances actuales:");
        console.log("  ETH:", ethBalance / 1e18);
        console.log("  USDC:", usdcBalance / 1e6);
        console.log("  WBTC:", wbtcBalance / 1e8);
        
        // Mint additional tokens if needed for testing
        if (ethBalance < 10 * 1e18) {
            mockETH.mint(user, 20 * 1e18);
            console.log("  Minteado 20 ETH adicionales");
        }
        
        if (usdcBalance < 50000 * 1e6) {
            mockUSDC.mint(user, 100000 * 1e6);
            console.log("  Minteado 100,000 USDC adicionales");
        }
        
        console.log("Balances finales:");
        console.log("  ETH:", mockETH.balanceOf(user) / 1e18);
        console.log("  USDC:", mockUSDC.balanceOf(user) / 1e6);
        console.log("");
    }
    
    function _setupApprovals(address user) internal {
        // The deployer (user) approves helper to spend tokens
        IERC20(MOCK_ETH).approve(LIQUIDATION_HELPER, type(uint256).max);
        IERC20(MOCK_USDC).approve(LIQUIDATION_HELPER, type(uint256).max);
        IERC20(MOCK_WBTC).approve(LIQUIDATION_HELPER, type(uint256).max);
        
        console.log("Approvals configurados para LiquidationHelper");
        console.log("");
    }
    
    function _executeLiquidationTest(address user) internal {
        LiquidationHelper helper = LiquidationHelper(LIQUIDATION_HELPER);
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        
        console.log("=== CREANDO POSICION RIESGOSA ===");
        
        // Crear posición con LTV más conservador
        uint256 collateralETH = 1 * 1e18;        // 1 ETH colateral (~$2500)
        uint256 loanUSDC = 1800 * 1e6;           // $1800 USDC (LTV = 72%, Collateral Ratio = 138%)
        
        console.log("Configuracion:");
        console.log("  Colateral ETH:", collateralETH / 1e18);
        console.log("  Prestamo USDC:", loanUSDC / 1e6);
        console.log("  LTV: 72% (COLLATERAL RATIO: 138%)");
        console.log("");
        
        // Crear posición
        uint256 positionId = helper.createRiskyPosition(
            GENERIC_LOAN_MANAGER,
            MOCK_ETH,
            MOCK_USDC,
            collateralETH,
            loanUSDC,
            user  // deployer es el borrower
        );
        
        console.log("Posicion creada con ID:", positionId);
        
        // Verificar estado inicial
        (bool canLiquidateInitial, uint256 initialRatio, uint256 initialDebt) = 
            helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        console.log("Estado inicial:");
        console.log("  Ratio colateralizacion:", initialRatio / 10000, "%");
        console.log("  Deuda total:", initialDebt / 1e6, "USDC");
        console.log("  Es liquidable:", canLiquidateInitial);
        console.log("");
        
        // Si no es liquidable, acelerar tiempo para acumular interés
        if (!canLiquidateInitial) {
            console.log("=== ACUMULANDO INTERES ===");
            
            // Acelerar tiempo 6 meses
            vm.warp(block.timestamp + 180 days);
            helper.accrueInterest(GENERIC_LOAN_MANAGER, positionId);
            
            (bool canLiquidateAfter, uint256 ratioAfter, uint256 debtAfter) = 
                helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
            
            console.log("Estado despues de 180 dias:");
            console.log("  Ratio colateralizacion:", ratioAfter / 10000, "%");
            console.log("  Deuda total:", debtAfter / 1e6, "USDC");
            console.log("  Es liquidable:", canLiquidateAfter);
            console.log("");
            
            canLiquidateInitial = canLiquidateAfter;
            initialDebt = debtAfter;
        }
        
        if (canLiquidateInitial) {
            console.log("=== EJECUTANDO LIQUIDACION ===");
            
            uint256 ethBefore = mockETH.balanceOf(user);
            uint256 usdcBefore = mockUSDC.balanceOf(user);
            
            console.log("Balances antes:");
            console.log("  ETH:", ethBefore / 1e18);
            console.log("  USDC:", usdcBefore / 1e6);
            
            // El deployer liquida su propia posición (self-liquidation para testing)
            helper.executeLiquidation(GENERIC_LOAN_MANAGER, positionId, user);
            
            uint256 ethAfter = mockETH.balanceOf(user);
            uint256 usdcAfter = mockUSDC.balanceOf(user);
            
            console.log("Balances despues:");
            console.log("  ETH:", ethAfter / 1e18);
            console.log("  USDC:", usdcAfter / 1e6);
            
            // Calcular cambios
            int256 ethChange = int256(ethAfter) - int256(ethBefore);
            int256 usdcChange = int256(usdcAfter) - int256(usdcBefore);
            
            console.log("Resultados:");
            if (ethChange >= 0) {
                console.log("  ETH ganado/conservado:", uint256(ethChange) / 1e18);
            } else {
                console.log("  ETH usado como colateral:", uint256(-ethChange) / 1e18);
            }
            
            if (usdcChange >= 0) {
                console.log("  USDC ganado:", uint256(usdcChange) / 1e6);
            } else {
                console.log("  USDC gastado para pagar deuda:", uint256(-usdcChange) / 1e6);
            }
            
            console.log("EXITO: Liquidacion completada!");
            
        } else {
            console.log("RESULTADO: Posicion aun no es liquidable");
            console.log("Sugerencia: Usar ratio inicial mas riesgoso (ej. 101%)");
        }
        
        console.log("");
    }
} 
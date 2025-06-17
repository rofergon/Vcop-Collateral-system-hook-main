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
 * @title TestLiquidationWithTokens
 * @notice Script que mintea tokens mock y testa liquidaciones completas
 * @dev Usa las direcciones reales desplegadas en Base Sepolia
 */
contract TestLiquidationWithTokens is Script {
    
    // Direcciones de contratos desplegados en Base Sepolia
    address constant GENERIC_LOAN_MANAGER = 0xF8724317315B1BA8ac1a0f30Ac407e9fCf20442B;
    address constant FLEXIBLE_LOAN_MANAGER = 0xFf120b0Eb71131EFA1f8C93331B042cB4C0F8Ec7;
    address constant LIQUIDATION_HELPER = 0xbD2329ad3cCcc4932B847014572F429bc8B4b2f5;
    
    // Mock tokens
    address constant MOCK_ETH = 0x87bb55de00f7D2791dbF3461A110D99bB47cF62F;
    address constant MOCK_WBTC = 0x4Cd911B122e27e5EF684e3553B8187525725a399;
    address constant MOCK_USDC = 0xcbeC2cAa97A660434aA5420d667b3f1e60E2C17B;
    
    // Test accounts
    address borrower;
    address liquidator;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Create test accounts
        borrower = address(0x1111111111111111111111111111111111111111);
        liquidator = address(0x2222222222222222222222222222222222222222);
        
        console.log("==================================================");
        console.log("TESTEANDO LIQUIDACIONES CON TOKENS REALES");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("Borrower:", borrower);
        console.log("Liquidator:", liquidator);
        console.log("LiquidationHelper:", LIQUIDATION_HELPER);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Mint tokens to test accounts
        console.log("PASO 1: Minteando tokens a cuentas de testing...");
        _mintTokensToTestAccounts();
        
        // Step 2: Test liquidation scenario
        console.log("PASO 2: Ejecutando test de liquidacion...");
        _testLiquidationScenario();
        
        vm.stopBroadcast();
        
        console.log("==================================================");
        console.log("TEST DE LIQUIDACION COMPLETADO");
        console.log("==================================================");
    }
    
    function _mintTokensToTestAccounts() internal {
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        MockWBTC mockWBTC = MockWBTC(MOCK_WBTC);
        
        // Mint tokens to borrower (collateral)
        mockETH.mint(borrower, 10 * 1e18);      // 10 ETH
        mockWBTC.mint(borrower, 2 * 1e8);       // 2 WBTC
        
        // Mint tokens to liquidator (for repaying debt)
        mockUSDC.mint(liquidator, 100000 * 1e6); // 100,000 USDC
        mockETH.mint(liquidator, 5 * 1e18);      // 5 ETH
        
        console.log("Tokens minteados:");
        console.log("  Borrower ETH:", mockETH.balanceOf(borrower) / 1e18);
        console.log("  Borrower WBTC:", mockWBTC.balanceOf(borrower) / 1e8);
        console.log("  Liquidator USDC:", mockUSDC.balanceOf(liquidator) / 1e6);
        console.log("  Liquidator ETH:", mockETH.balanceOf(liquidator) / 1e18);
        console.log("");
    }
    
    function _testLiquidationScenario() internal {
        LiquidationHelper helper = LiquidationHelper(LIQUIDATION_HELPER);
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        
        console.log("=== CREANDO POSICION RIESGOSA (CERCA DEL 110%) ===");
        
        // Calcular exactamente una posición con ratio ~108% (debajo del umbral de 110%)
        uint256 collateralETH = 1 * 1e18;        // 1 ETH colateral
        uint256 ethPriceUSD = 2500;              // Asumimos ETH = $2500
        uint256 collateralValueUSD = collateralETH * ethPriceUSD / 1e18; // $2500
        
        // Para ratio 108%: deuda = collateralValue / 1.08
        uint256 targetRatio = 1080000; // 108% en formato 6 decimales
        uint256 loanUSDC = (collateralValueUSD * 1000000 * 1e6) / targetRatio; // Corregir para USDC decimals
        
        console.log("Configuracion calculada:");
        console.log("  Colateral ETH:", collateralETH / 1e18);
        console.log("  Valor colateral USD:", collateralValueUSD);
        console.log("  Prestamo USDC:", loanUSDC / 1e6);
        console.log("  Ratio objetivo:", targetRatio / 10000, "%");
        
        // Ensure minimum loan amount (some protocols have minimums)
        if (loanUSDC < 100 * 1e6) {
            loanUSDC = 100 * 1e6; // Minimum 100 USDC
            console.log("  Prestamo ajustado a minimo:", loanUSDC / 1e6, "USDC");
        }
        
        // Set up approvals correctly
        vm.stopBroadcast();
        
        // Give borrower enough ETH and approve helper
        vm.startPrank(borrower);
        mockETH.approve(LIQUIDATION_HELPER, type(uint256).max);
        vm.stopPrank();
        
        // Give liquidator enough USDC and approve helper  
        vm.startPrank(liquidator);
        mockUSDC.approve(LIQUIDATION_HELPER, type(uint256).max);
        vm.stopPrank();
        
        // Continue with deployer
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        
        // Create risky position with calculated values
        uint256 positionId = helper.createRiskyPosition(
            GENERIC_LOAN_MANAGER,
            MOCK_ETH,
            MOCK_USDC,
            collateralETH,
            loanUSDC,
            borrower
        );
        
        console.log("Posicion creada con ID:", positionId);
        
        // Check initial status
        (bool canLiquidateInitial, uint256 initialRatio, uint256 initialDebt) = 
            helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
        
        console.log("Estado inicial:");
        console.log("  Ratio colateralizacion:", initialRatio / 10000, "%");
        console.log("  Deuda total:", initialDebt / 1e6, "USDC");
        console.log("  Es liquidable:", canLiquidateInitial);
        console.log("");
        
        // Si no es liquidable inicialmente, acumular interés
        if (!canLiquidateInitial) {
            console.log("=== ACUMULANDO INTERES PARA FORZAR LIQUIDACION ===");
            
            // Fast forward time to accrue significant interest
            vm.warp(block.timestamp + 180 days); // 180 days (6 meses)
            
            // Update interest
            helper.accrueInterest(GENERIC_LOAN_MANAGER, positionId);
            
            // Check status after interest accrual
            (bool canLiquidateAfter, uint256 ratioAfter, uint256 debtAfter) = 
                helper.checkLiquidationStatus(GENERIC_LOAN_MANAGER, positionId);
            
            console.log("Estado despues de 180 dias:");
            console.log("  Ratio colateralizacion:", ratioAfter / 10000, "%");
            console.log("  Deuda total:", debtAfter / 1e6, "USDC");
            console.log("  Es liquidable:", canLiquidateAfter);
            console.log("");
            
            // Update variables for liquidation
            canLiquidateInitial = canLiquidateAfter;
            initialRatio = ratioAfter;
            initialDebt = debtAfter;
        }
        
        if (canLiquidateInitial) {
            console.log("=== EJECUTANDO LIQUIDACION ===");
            
            // Get liquidator balances before
            uint256 liquidatorETHBefore = mockETH.balanceOf(liquidator);
            uint256 liquidatorUSDCBefore = mockUSDC.balanceOf(liquidator);
            
            console.log("Balances liquidator antes:");
            console.log("  ETH:", liquidatorETHBefore / 1e18);
            console.log("  USDC:", liquidatorUSDCBefore / 1e6);
            
            // Execute liquidation
            helper.executeLiquidation(GENERIC_LOAN_MANAGER, positionId, liquidator);
            
            // Get liquidator balances after
            uint256 liquidatorETHAfter = mockETH.balanceOf(liquidator);
            uint256 liquidatorUSDCAfter = mockUSDC.balanceOf(liquidator);
            
            console.log("Balances liquidator despues:");
            console.log("  ETH:", liquidatorETHAfter / 1e18);
            console.log("  USDC:", liquidatorUSDCAfter / 1e6);
            
            // Calculate rewards
            uint256 ethGained = liquidatorETHAfter - liquidatorETHBefore;
            uint256 usdcSpent = liquidatorUSDCBefore - liquidatorUSDCAfter;
            
            console.log("Resultados liquidacion:");
            console.log("  ETH ganado:", ethGained / 1e18);
            console.log("  USDC gastado:", usdcSpent / 1e6);
            console.log("  Beneficio estimado USD:", (ethGained * 2500 / 1e18) - (usdcSpent / 1e6));
            
            if (ethGained > 0) {
                console.log("EXITO: Liquidacion completada con recompensas!");
            } else {
                console.log("ERROR: Liquidacion no genero recompensas");
            }
            
        } else {
            console.log("ADVERTENCIA: Posicion aun no es liquidable");
            console.log("Intenta:");
            console.log("  - Aumentar el tiempo de acumulacion de interes");
            console.log("  - Crear un ratio inicial mas bajo (~105%)");
            console.log("  - Simular caida de precio del colateral");
        }
        
        console.log("");
    }
} 
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
 * @title TestLiquidationWithPermit2
 * @notice Simplified liquidation testing script with better approval handling
 * @dev Uses a cleaner approach to avoid vm.startPrank/stopPrank complications
 */
contract TestLiquidationWithPermit2 is Script {
    
    // Direcciones de contratos desplegados en Base Sepolia
    address constant GENERIC_LOAN_MANAGER = 0xF8724317315B1BA8ac1a0f30Ac407e9fCf20442B;
    address constant FLEXIBLE_LOAN_MANAGER = 0xFf120b0Eb71131EFA1f8C93331B042cB4C0F8Ec7;
    address constant LIQUIDATION_HELPER = 0xbD2329ad3cCcc4932B847014572F429bc8B4b2f5;
    
    // Mock tokens
    address constant MOCK_ETH = 0x87bb55de00f7D2791dbF3461A110D99bB47cF62F;
    address constant MOCK_WBTC = 0x4Cd911B122e27e5EF684e3553B8187525725a399;
    address constant MOCK_USDC = 0xcbeC2cAa97A660434aA5420d667b3f1e60E2C17B;
    
    // Test accounts - usando addresses determinísticas
    address constant BORROWER = 0x1111111111111111111111111111111111111111;
    address constant LIQUIDATOR = 0x2222222222222222222222222222222222222222;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==================================================");
        console.log("LIQUIDATION TEST CON MANEJO SIMPLIFICADO DE APPROVALS");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("Borrower:", BORROWER);
        console.log("Liquidator:", LIQUIDATOR);
        console.log("LiquidationHelper:", LIQUIDATION_HELPER);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Setup tokens and approvals
        console.log("PASO 1: Configurando tokens y approvals...");
        _setupTokensAndApprovals();
        
        // Step 2: Execute liquidation test
        console.log("PASO 2: Ejecutando test de liquidacion...");
        _executeLiquidationTest();
        
        vm.stopBroadcast();
        
        console.log("==================================================");
        console.log("TEST COMPLETADO EXITOSAMENTE");
        console.log("==================================================");
    }
    
    function _setupTokensAndApprovals() internal {
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        MockWBTC mockWBTC = MockWBTC(MOCK_WBTC);
        
        // Mint tokens to test accounts
        mockETH.mint(BORROWER, 10 * 1e18);      // 10 ETH
        mockWBTC.mint(BORROWER, 2 * 1e8);       // 2 WBTC
        mockUSDC.mint(LIQUIDATOR, 100000 * 1e6); // 100,000 USDC
        mockETH.mint(LIQUIDATOR, 5 * 1e18);      // 5 ETH
        
        console.log("Tokens minteados:");
        console.log("  Borrower ETH:", mockETH.balanceOf(BORROWER) / 1e18);
        console.log("  Borrower WBTC:", mockWBTC.balanceOf(BORROWER) / 1e8);
        console.log("  Liquidator USDC:", mockUSDC.balanceOf(LIQUIDATOR) / 1e6);
        console.log("  Liquidator ETH:", mockETH.balanceOf(LIQUIDATOR) / 1e18);
        
        // Setup approvals using a more direct approach
        _setupApprovals();
    }
    
    function _setupApprovals() internal {
        // Detener broadcast temporalmente para manejar aprobaciones
        vm.stopBroadcast();
        
        // Setup approvals para BORROWER
        vm.startPrank(BORROWER);
        IERC20(MOCK_ETH).approve(LIQUIDATION_HELPER, type(uint256).max);
        IERC20(MOCK_USDC).approve(LIQUIDATION_HELPER, type(uint256).max);
        IERC20(MOCK_WBTC).approve(LIQUIDATION_HELPER, type(uint256).max);
        vm.stopPrank();
        
        // Setup approvals para LIQUIDATOR
        vm.startPrank(LIQUIDATOR);
        IERC20(MOCK_ETH).approve(LIQUIDATION_HELPER, type(uint256).max);
        IERC20(MOCK_USDC).approve(LIQUIDATION_HELPER, type(uint256).max);
        IERC20(MOCK_WBTC).approve(LIQUIDATION_HELPER, type(uint256).max);
        vm.stopPrank();
        
        // Reanudar broadcast con la private key del deployer
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Approvals configurados para todos los tokens y usuarios");
        console.log("");
    }
    
    function _executeLiquidationTest() internal {
        LiquidationHelper helper = LiquidationHelper(LIQUIDATION_HELPER);
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        
        console.log("=== CREANDO POSICION RIESGOSA ===");
        
        // Configuración para una posición con ratio ~108%
        uint256 collateralETH = 1 * 1e18;        // 1 ETH colateral
        uint256 loanUSDC = 2315 * 1e6;           // ~$2315 USDC (ratio ~108% si ETH=$2500)
        
        console.log("Configuracion:");
        console.log("  Colateral ETH:", collateralETH / 1e18);
        console.log("  Prestamo USDC:", loanUSDC / 1e6);
        console.log("  Ratio estimado: ~108%");
        console.log("");
        
        // Crear posición usando el helper
        uint256 positionId = helper.createRiskyPosition(
            GENERIC_LOAN_MANAGER,
            MOCK_ETH,
            MOCK_USDC,
            collateralETH,
            loanUSDC,
            BORROWER
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
        
        // Acelerar tiempo para acumular interés
        if (!canLiquidateInitial) {
            console.log("=== ACUMULANDO INTERES (180 dias) ===");
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
        }
        
        if (canLiquidateInitial) {
            console.log("=== EJECUTANDO LIQUIDACION ===");
            
            uint256 liquidatorETHBefore = mockETH.balanceOf(LIQUIDATOR);
            uint256 liquidatorUSDCBefore = mockUSDC.balanceOf(LIQUIDATOR);
            
            console.log("Balances liquidator antes:");
            console.log("  ETH:", liquidatorETHBefore / 1e18);
            console.log("  USDC:", liquidatorUSDCBefore / 1e6);
            
            helper.executeLiquidation(GENERIC_LOAN_MANAGER, positionId, LIQUIDATOR);
            
            uint256 liquidatorETHAfter = mockETH.balanceOf(LIQUIDATOR);
            uint256 liquidatorUSDCAfter = mockUSDC.balanceOf(LIQUIDATOR);
            
            console.log("Balances liquidator despues:");
            console.log("  ETH:", liquidatorETHAfter / 1e18);
            console.log("  USDC:", liquidatorUSDCAfter / 1e6);
            
            uint256 ethGained = liquidatorETHAfter - liquidatorETHBefore;
            uint256 usdcSpent = liquidatorUSDCBefore - liquidatorUSDCAfter;
            
            console.log("Resultados liquidacion:");
            console.log("  ETH ganado:", ethGained / 1e18);
            console.log("  USDC gastado:", usdcSpent / 1e6);
            
            if (ethGained > 0) {
                console.log("EXITO: Liquidacion completada con recompensas!");
            } else {
                console.log("ERROR: Liquidacion no genero recompensas");
            }
        } else {
            console.log("ADVERTENCIA: Posicion aun no es liquidable");
        }
    }
    
    /**
     * @dev Helper para verificar balances y approvals
     */
    function checkSetup() external view {
        console.log("=== VERIFICACION DE SETUP ===");
        
        address[] memory tokens = new address[](3);
        tokens[0] = MOCK_ETH;
        tokens[1] = MOCK_USDC;
        tokens[2] = MOCK_WBTC;
        
        address[] memory users = new address[](2);
        users[0] = BORROWER;
        users[1] = LIQUIDATOR;
        
        for (uint i = 0; i < users.length; i++) {
            address user = users[i];
            console.log("Usuario:", user);
            
            for (uint j = 0; j < tokens.length; j++) {
                address token = tokens[j];
                uint256 balance = IERC20(token).balanceOf(user);
                uint256 allowance = IERC20(token).allowance(user, LIQUIDATION_HELPER);
                
                console.log("  Token:", token);
                console.log("    Balance:", balance);
                console.log("    Allowance:", allowance);
                console.log("    Ready:", (balance > 0 && allowance > 0) ? "YES" : "NO");
            }
            console.log("");
        }
    }
} 
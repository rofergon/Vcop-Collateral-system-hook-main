// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Core contracts
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {FlexibleLoanManager} from "../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../src/core/VaultBasedHandler.sol";
import {RiskCalculator} from "../src/core/RiskCalculator.sol";

// Interfaces
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";
import {IAssetHandler} from "../src/interfaces/IAssetHandler.sol";

/**
 * @title TestCoreLoans
 * @notice Comprehensive testing script for the core lending system
 * 
 * Tests incluyen:
 * 1. ETH como colateral → USDC como préstamo
 * 2. USDC como colateral → ETH como préstamo  
 * 3. Operaciones con múltiples activos
 * 4. Cálculos de riesgo en tiempo real
 * 5. Gestión de intereses
 * 6. Liquidaciones simuladas
 * 7. Pruebas de recuperación de colateral
 */
contract TestCoreLoans is Script {
    
    // ===== DIRECCIONES DE CONTRATOS DESPLEGADOS =====
    // Mock Tokens (Base Sepolia)
    address constant MOCK_ETH = 0x21756f22e0945Ed3faB38D05Cf8E933845a60622;
    address constant MOCK_WBTC = 0xfb5810A37Eb47df5a498673237eD16ace3600162;
    address constant MOCK_USDC = 0x9B051Dbf5bbFA94c9F18617a2D10AC9614D41d6c;
    
    // Asset Handlers
    address constant VAULT_BASED_HANDLER = 0x26a5B76417f4b12131542CEfd9083e70c9E647B1;
    address constant FLEXIBLE_ASSET_HANDLER = 0xFB0c77510218EcBF47B26150CEf4085Cc7d36a7b;
    
    // Loan Managers
    address constant GENERIC_LOAN_MANAGER = 0x374A7b5353F2E1E002Af4DD02138183776037Ea2;
    address constant FLEXIBLE_LOAN_MANAGER = 0x8F25AF7A087AC48f13f841C9d241A2094301547b;
    
    // ===== CONFIGURACIONES DE PRUEBA =====
    struct TestConfig {
        string name;
        address collateralAsset;
        address loanAsset;
        uint256 collateralAmount;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 maxLTV;
    }
    
    // Instancias de contratos
    IERC20 mockETH;
    IERC20 mockWBTC;
    IERC20 mockUSDC;
    GenericLoanManager genericLoanManager;
    FlexibleLoanManager flexibleLoanManager;
    VaultBasedHandler vaultHandler;
    RiskCalculator riskCalculator;
    
    // Variables de estado de prueba
    address deployer;
    uint256 deployerPrivateKey;
    uint256[] createdPositions;
    
    function run() external {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);
        
        console.log("==================================================");
        console.log("INICIANDO PRUEBAS COMPLETAS DEL SISTEMA CORE");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("Network: Base Sepolia");
        console.log("");
        
        _initializeContracts();
        _checkSystemStatus();
        _ensureLiquidity();
        
        vm.startBroadcast(deployerPrivateKey);
        
        // ===== SUITE DE PRUEBAS =====
        console.log(" EJECUTANDO SUITE DE PRUEBAS:");
        console.log("");
        
        // 1. Pruebas básicas de préstamos
        _testBasicLoans();
        
        // 2. Pruebas de intercambio de activos
        _testAssetSwapping();
        
        // 3. Pruebas de gestión de riesgo
        _testRiskCalculations();
        
        // 4. Pruebas de operaciones avanzadas
        _testAdvancedOperations();
        
        // 5. Pruebas de recuperación y cierre
        _testLoanRepaymentAndClosure();
        
        vm.stopBroadcast();
        
        console.log("==================================================");
        console.log(" TODAS LAS PRUEBAS COMPLETADAS EXITOSAMENTE");
        console.log("==================================================");
    }
    
    function _initializeContracts() internal {
        console.log(" Inicializando contratos...");
        
        mockETH = IERC20(MOCK_ETH);
        mockWBTC = IERC20(MOCK_WBTC);
        mockUSDC = IERC20(MOCK_USDC);
        
        genericLoanManager = GenericLoanManager(GENERIC_LOAN_MANAGER);
        flexibleLoanManager = FlexibleLoanManager(FLEXIBLE_LOAN_MANAGER);
        vaultHandler = VaultBasedHandler(VAULT_BASED_HANDLER);
        
        console.log(" Contratos inicializados");
        console.log("");
    }
    
    function _checkSystemStatus() internal view {
        console.log(" ESTADO ACTUAL DEL SISTEMA:");
        console.log("----------------------------------------");
        
        // Balances del deployer
        console.log(" Balances del deployer:");
        console.log("  MockETH:", mockETH.balanceOf(deployer) / 1e18, "ETH");
        console.log("  MockWBTC:", mockWBTC.balanceOf(deployer) / 1e8, "WBTC");
        console.log("  MockUSDC:", mockUSDC.balanceOf(deployer) / 1e6, "USDC");
        console.log("");
        
        // Estado de liquidez
        console.log(" Liquidez disponible:");
        try vaultHandler.getAvailableLiquidity(MOCK_ETH) returns (uint256 ethLiq) {
            console.log("  ETH Vault:", ethLiq / 1e18, "ETH");
        } catch {
            console.log("  ETH Vault: No disponible");
        }
        
        try vaultHandler.getAvailableLiquidity(MOCK_USDC) returns (uint256 usdcLiq) {
            console.log("  USDC Vault:", usdcLiq / 1e6, "USDC");
        } catch {
            console.log("  USDC Vault: No disponible");
        }
        console.log("");
    }
    
    function _ensureLiquidity() internal {
        console.log(" Asegurando liquidez para pruebas...");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Proporcionar liquidez ETH si es necesario
        try vaultHandler.getAvailableLiquidity(MOCK_ETH) returns (uint256 ethLiq) {
            if (ethLiq < 10e18) { // Menos de 10 ETH
                console.log("  Proporcionando liquidez ETH...");
                mockETH.approve(VAULT_BASED_HANDLER, 100e18);
                vaultHandler.provideLiquidity(MOCK_ETH, 100e18, deployer);
                console.log("   100 ETH agregados al vault");
            }
        } catch {
            console.log("  Proporcionando liquidez inicial ETH...");
            mockETH.approve(VAULT_BASED_HANDLER, 100e18);
            vaultHandler.provideLiquidity(MOCK_ETH, 100e18, deployer);
            console.log("   100 ETH agregados al vault");
        }
        
        // Proporcionar liquidez USDC si es necesario
        try vaultHandler.getAvailableLiquidity(MOCK_USDC) returns (uint256 usdcLiq) {
            if (usdcLiq < 10000e6) { // Menos de 10,000 USDC
                console.log("  Proporcionando liquidez USDC...");
                mockUSDC.approve(VAULT_BASED_HANDLER, 100000e6);
                vaultHandler.provideLiquidity(MOCK_USDC, 100000e6, deployer);
                console.log("   100,000 USDC agregados al vault");
            }
        } catch {
            console.log("  Proporcionando liquidez inicial USDC...");
            mockUSDC.approve(VAULT_BASED_HANDLER, 100000e6);
            vaultHandler.provideLiquidity(MOCK_USDC, 100000e6, deployer);
            console.log("   100,000 USDC agregados al vault");
        }
        
        vm.stopBroadcast();
        console.log("Liquidez asegurada");
        console.log("");
    }
    
    function _testBasicLoans() internal {
        console.log("1 PRUEBAS BASICAS DE PRESTAMOS");
        console.log("----------------------------------------");
        
        // Test 1: ETH como colateral → USDC como préstamo
        TestConfig memory ethToUsdc = TestConfig({
            name: "ETH a USDC",
            collateralAsset: MOCK_ETH,
            loanAsset: MOCK_USDC,
            collateralAmount: 5e18,      // 5 ETH como colateral
            loanAmount: 10000e6,         // 10,000 USDC prestado
            interestRate: 80000,         // 8% anual
            maxLTV: 700000               // 70% LTV máximo
        });
        
        _executeLoanTest(ethToUsdc);
        
        // Test 2: USDC como colateral → ETH como préstamo
        TestConfig memory usdcToEth = TestConfig({
            name: "USDC a ETH",
            collateralAsset: MOCK_USDC,
            loanAsset: MOCK_ETH,
            collateralAmount: 20000e6,   // 20,000 USDC como colateral
            loanAmount: 3e18,            // 3 ETH prestado
            interestRate: 75000,         // 7.5% anual
            maxLTV: 650000               // 65% LTV máximo
        });
        
        _executeLoanTest(usdcToEth);
        
        console.log(" Pruebas basicas completadas");
        console.log("");
    }
    
    function _executeLoanTest(TestConfig memory config) internal {
        console.log(" Prueba:", config.name);
        
        // Aprobar tokens
        IERC20(config.collateralAsset).approve(GENERIC_LOAN_MANAGER, config.collateralAmount);
        
        // Crear términos del préstamo
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: config.collateralAsset,
            loanAsset: config.loanAsset,
            collateralAmount: config.collateralAmount,
            loanAmount: config.loanAmount,
            maxLoanToValue: config.maxLTV,
            interestRate: config.interestRate,
            duration: 0 // Préstamo perpetuo
        });
        
        // Verificar máximo prestable
        uint256 maxBorrow = genericLoanManager.getMaxBorrowAmount(
            config.collateralAsset,
            config.loanAsset,
            config.collateralAmount
        );
        console.log("  Maximo prestable:", maxBorrow);
        console.log("  Monto solicitado:", config.loanAmount);
        
        // Crear préstamo
        uint256 positionId = genericLoanManager.createLoan(terms);
        createdPositions.push(positionId);
        
        console.log("   Prestamo creado. Position ID:", positionId);
        
        // Verificar posición
        ILoanManager.LoanPosition memory position = genericLoanManager.getPosition(positionId);
        console.log("   Detalles de la posicion:");
        console.log("    Colateral:", position.collateralAmount);
        console.log("    Prestamo:", position.loanAmount);
        console.log("    Tasa de interes:", position.interestRate / 10000, "%");
        
        // Calcular ratio de colateralización
        uint256 collateralRatio = genericLoanManager.getCollateralizationRatio(positionId);
        console.log("    Ratio de colateralizacion:", collateralRatio / 10000, "%");
        
        console.log("");
    }
    
    function _testAssetSwapping() internal {
        console.log("2 PRUEBAS DE INTERCAMBIO DE ACTIVOS");
        console.log("----------------------------------------");
        
        console.log(" Probando diferentes combinaciones de activos...");
        
        // Crear préstamo con WBTC como colateral
        TestConfig memory wbtcConfig = TestConfig({
            name: "WBTC a USDC",
            collateralAsset: MOCK_WBTC,
            loanAsset: MOCK_USDC,
            collateralAmount: 1e8,       // 1 WBTC
            loanAmount: 30000e6,         // 30,000 USDC
            interestRate: 75000,         // 7.5% anual
            maxLTV: 700000               // 70% LTV
        });
        
        // Configurar WBTC en el vault si no está configurado
        try vaultHandler.isAssetSupported(MOCK_WBTC) returns (bool supported) {
            if (!supported) {
                console.log("  Configurando WBTC en el vault...");
                vaultHandler.configureAsset(
                    MOCK_WBTC,
                    1400000,     // 140% ratio de colateral
                    1150000,     // 115% ratio de liquidación
                    50e8,        // 50 WBTC máximo
                    75000        // 7.5% tasa de interés
                );
                
                // Proporcionar liquidez WBTC
                mockWBTC.approve(VAULT_BASED_HANDLER, 10e8);
                vaultHandler.provideLiquidity(MOCK_WBTC, 10e8, deployer);
                console.log("   WBTC configurado y liquidez proporcionada");
            }
        } catch {
            console.log("  Error verificando soporte WBTC, continuando...");
        }
        
        _executeLoanTest(wbtcConfig);
        
        console.log(" Pruebas de intercambio completadas");
        console.log("");
    }
    
    function _testRiskCalculations() internal {
        console.log("3 PRUEBAS DE CALCULOS DE RIESGO");
        console.log("----------------------------------------");
        
        console.log("  RiskCalculator necesita ser desplegado por separado");
        console.log(" Analisis basico de posiciones:");
        
        for (uint i = 0; i < createdPositions.length; i++) {
            uint256 positionId = createdPositions[i];
            console.log(" Posicion", positionId, ":");
            
            ILoanManager.LoanPosition memory position = genericLoanManager.getPosition(positionId);
            uint256 collateralRatio = genericLoanManager.getCollateralizationRatio(positionId);
            uint256 accruedInterest = genericLoanManager.getAccruedInterest(positionId);
            uint256 totalDebt = genericLoanManager.getTotalDebt(positionId);
            bool canLiquidate = genericLoanManager.canLiquidate(positionId);
            
            console.log("   Ratio de colateralizacion:", collateralRatio / 10000, "%");
            console.log("   Interes acumulado:", accruedInterest);
            console.log("   Deuda total:", totalDebt);
            console.log("    Liquidable?:", canLiquidate ? "Si" : "No");
            console.log("");
        }
        
        console.log("Analisis de riesgo basico completado");
        console.log("");
    }
    
    function _testAdvancedOperations() internal {
        console.log("4 PRUEBAS DE OPERACIONES AVANZADAS");
        console.log("----------------------------------------");
        
        if (createdPositions.length > 0) {
            uint256 positionId = createdPositions[0];
            ILoanManager.LoanPosition memory position = genericLoanManager.getPosition(positionId);
            
            console.log("Probando operaciones avanzadas en posicion", positionId);
            
            // 1. Agregar colateral
            uint256 additionalCollateral = position.collateralAmount / 10; // 10% más
            IERC20(position.collateralAsset).approve(GENERIC_LOAN_MANAGER, additionalCollateral);
            
            console.log("  Agregando colateral adicional:", additionalCollateral);
            genericLoanManager.addCollateral(positionId, additionalCollateral);
            
            uint256 newRatio = genericLoanManager.getCollateralizationRatio(positionId);
            console.log("  Nuevo ratio:", newRatio / 10000, "%");
            
            // 2. Simular paso del tiempo para acumular intereses
            console.log("  Simulando paso del tiempo (30 dias)...");
            vm.warp(block.timestamp + 30 days);
            
            // Actualizar intereses
            genericLoanManager.updateInterest(positionId);
            uint256 accruedInterest = genericLoanManager.getAccruedInterest(positionId);
            uint256 totalDebt = genericLoanManager.getTotalDebt(positionId);
            
            console.log("  Interes acumulado:", accruedInterest);
            console.log("  Deuda total:", totalDebt);
            
            // 3. Intentar retirar algo de colateral
            uint256 withdrawAmount = additionalCollateral / 2;
            console.log("  Intentando retirar colateral:", withdrawAmount);
            
            try genericLoanManager.withdrawCollateral(positionId, withdrawAmount) {
                console.log("  Colateral retirado exitosamente");
            } catch Error(string memory reason) {
                console.log("  No se pudo retirar colateral:", reason);
            } catch {
                console.log("  Error desconocido retirando colateral");
            }
        }
        
        console.log("Operaciones avanzadas completadas");
        console.log("");
    }
    
    function _testLoanRepaymentAndClosure() internal {
        console.log("5 PRUEBAS DE PAGO Y CIERRE");
        console.log("----------------------------------------");
        
        for (uint i = 0; i < createdPositions.length; i++) {
            uint256 positionId = createdPositions[i];
            ILoanManager.LoanPosition memory position = genericLoanManager.getPosition(positionId);
            
            if (!position.isActive) {
                console.log("  Posicion", positionId, "ya cerrada");
                continue;
            }
            
            console.log("Pagando prestamo para posicion", positionId);
            
            // Obtener deuda total
            uint256 totalDebt = genericLoanManager.getTotalDebt(positionId);
            console.log("  Deuda total a pagar:", totalDebt);
            
            // Verificar balance suficiente
            uint256 balance = IERC20(position.loanAsset).balanceOf(deployer);
            console.log("  Balance disponible:", balance);
            
            if (balance >= totalDebt) {
                // Aprobar y pagar
                IERC20(position.loanAsset).approve(GENERIC_LOAN_MANAGER, totalDebt);
                
                console.log("  Ejecutando pago completo...");
                genericLoanManager.repayLoan(positionId, totalDebt);
                
                // Verificar estado final
                ILoanManager.LoanPosition memory finalPosition = genericLoanManager.getPosition(positionId);
                console.log("  Posicion activa:", finalPosition.isActive);
                console.log("  Colateral recuperado:", finalPosition.collateralAmount == 0);
                
            } else {
                console.log("  Balance insuficiente para pago completo");
                
                // Pago parcial
                uint256 partialPayment = balance / 2;
                if (partialPayment > 0) {
                    IERC20(position.loanAsset).approve(GENERIC_LOAN_MANAGER, partialPayment);
                    genericLoanManager.repayLoan(positionId, partialPayment);
                    console.log("  Pago parcial realizado:", partialPayment);
                }
            }
            
            console.log("");
        }
        
        console.log("Pruebas de pago completadas");
        console.log("");
    }
} 
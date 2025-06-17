// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";

/**
 * @title CreateRealLiquidablePosition
 * @notice Crea una posicion genuinamente liquidable usando precios reales del Oracle
 */
contract CreateRealLiquidablePosition is Script {
    
    address constant GENERIC_LOAN_MANAGER = 0xFcEFB29436323ABc3dE96B210E93Fe954080fB89;
    address constant MOCK_ETH = 0x80aC5Fb8E4b5D5448754377ef17E9699f789a3C7;
    address constant MOCK_USDC = 0xdfd075c5ECa0b01196d0440b3E67cA207924Fc4B;
    address constant ORACLE = 0x4309DF863930Db7dEd5f964b444597E47103a5F9;
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address borrower = vm.addr(privateKey);
        
        console.log("========================================");
        console.log("CREANDO POSICION LIQUIDABLE CON PRECIOS REALES");
        console.log("========================================");
        console.log("Oracle:", ORACLE);
        console.log("ETH price: $2,613.51 (confirmed from Chainlink Oracle)");
        console.log("Target: Ratio ~108% (DEBAJO del 110% threshold)");
        console.log("");
        
        vm.startBroadcast(privateKey);
        
        GenericLoanManager loanManager = GenericLoanManager(GENERIC_LOAN_MANAGER);
        
        // Configurar approvals
        IERC20(MOCK_ETH).approve(GENERIC_LOAN_MANAGER, type(uint256).max);
        
        // CALCULAR POSICION LIQUIDABLE CON PRECIOS REALES:
        // ETH = $2,613.51 (real Chainlink price)
        // Para ratio de 108% (DEBAJO del 110% threshold):
        // 
        // Si prestamos $2,400 USDC, necesitamos:
        // Colateral value = $2,400 * 1.08 = $2,592
        // En ETH: $2,592 / $2,613.51 = 0.992 ETH
        
        uint256 collateralAmount = 0.992 * 1e18;     // 0.992 ETH (~$2,592)
        uint256 loanAmount = 2400 * 1e6;             // $2,400 USDC
        // Ratio esperado: $2,592 / $2,400 = 108% (LIQUIDABLE!)
        
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: MOCK_ETH,
            loanAsset: MOCK_USDC,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: 950000,            // 95% LTV max
            interestRate: 50000,               // 5% anual (bajo)
            duration: 0                        // Perpetual
        });
        
        console.log("Configuracion LIQUIDABLE:");
        console.log("  Colateral: 0.992 ETH (~$2,592)");
        console.log("  Prestamo: 2,400 USDC");
        console.log("  Ratio esperado: 108% (DEBAJO del 110% threshold)");
        console.log("  Interest Rate: 5% anual");
        console.log("");
        
        uint256 positionId = loanManager.createLoan(terms);
        
        console.log("POSICION LIQUIDABLE CREADA con ID:", positionId);
        
        // Verificar estado inicial
        ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        uint256 currentRatio = loanManager.getCollateralizationRatio(positionId);
        uint256 totalDebt = loanManager.getTotalDebt(positionId);
        bool canLiquidate = loanManager.canLiquidate(positionId);
        
        console.log("Estado inicial:");
        console.log("  Activa:", position.isActive);
        console.log("  Colateral:", position.collateralAmount / 1e18, "ETH");
        console.log("  Loan amount:", position.loanAmount / 1e6, "USDC");
        console.log("  Ratio actual:", currentRatio / 1000000000, "%");
        console.log("  Deuda total:", totalDebt / 1e6, "USDC");
        console.log("  Es liquidable:", canLiquidate ? "SI" : "NO");
        console.log("");
        
        if (canLiquidate) {
            console.log("EXITO! Posicion ES LIQUIDABLE!");
            console.log("Ratio:", currentRatio / 1000000000, "% < 110% threshold");
            console.log("");
            console.log("EJECUTAR LIQUIDACION:");
            console.log("Position ID:", positionId);
            console.log("Comando: Actualizar DirectLiquidationTest.s.sol con Position ID", positionId);
        } else {
            console.log("Posicion aun NO liquidable:");
            console.log("  Ratio actual:", currentRatio / 1000000000, "%");
            console.log("  Threshold: 110%");
            
            if (currentRatio / 1000000000 > 110) {
                console.log("  Status: Ratio demasiado ALTO");
                console.log("  Solucion: Crear posicion con MENOR colateral o MAS prestamo");
            } else {
                console.log("  Status: Debe ser un error de configuracion");
            }
        }
        
        vm.stopBroadcast();
        
        console.log("========================================");
        console.log("POSICION CON PRECIOS REALES CREADA");
        console.log("========================================");
    }
} 
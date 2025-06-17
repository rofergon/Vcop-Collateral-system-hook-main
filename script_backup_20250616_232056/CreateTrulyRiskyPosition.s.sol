// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";

/**
 * @title CreateTrulyRiskyPosition
 * @notice Crea una posicion MUY CERCA del liquidation threshold (110%)
 */
contract CreateTrulyRiskyPosition is Script {
    
    address constant GENERIC_LOAN_MANAGER = 0xe2AA5803F1baD51f092650De840Ea79547F26b7d;
    address constant MOCK_ETH = 0x388F7D72FD879725E40d893Fc1b5455036C7fd19;
    address constant MOCK_USDC = 0x009A513d97e55C77060C303f74eE66a991Bd3f08;
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address borrower = vm.addr(privateKey);
        
        console.log("========================================");
        console.log("CREANDO POSICION MUY CERCA DE LIQUIDACION");
        console.log("========================================");
        console.log("Target: Ratio inicial ~115% (muy cerca del 110% threshold)");
        console.log("Borrower:", borrower);
        console.log("");
        
        vm.startBroadcast(privateKey);
        
        GenericLoanManager loanManager = GenericLoanManager(GENERIC_LOAN_MANAGER);
        
        // Configurar approvals
        IERC20(MOCK_ETH).approve(GENERIC_LOAN_MANAGER, type(uint256).max);
        IERC20(MOCK_USDC).approve(GENERIC_LOAN_MANAGER, type(uint256).max);
        
        // Crear posición MUY RIESGOSA
        // ETH = $2,500, liquidation threshold = 110%
        // 
        // Para 115% ratio:
        // Si prestamos $2,000 USDC, necesitamos:
        // Colateral value = 2,000 * 1.15 = $2,300 
        // En ETH: $2,300 / $2,500 = 0.92 ETH
        
        uint256 collateralAmount = 0.92 * 1e18;      // 0.92 ETH (~$2,300)
        uint256 loanAmount = 2000 * 1e6;             // $2,000 USDC
        // Ratio esperado: 2,300 / 2,000 = 115%
        
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: MOCK_ETH,
            loanAsset: MOCK_USDC,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: 950000,            // 95% LTV max (muy alto)
            interestRate: 200000,              // 20% anual (normal)
            duration: 0                        // Perpetual
        });
        
        console.log("Configuracion de posicion RIESGOSA:");
        console.log("  Colateral: 0.92 ETH (~$2,300)");
        console.log("  Prestamo: 2,000 USDC");
        console.log("  Ratio esperado: ~115% (MUY CERCA del 110% threshold)");
        console.log("  Interest Rate: 20% anual");
        console.log("");
        
        uint256 positionId = loanManager.createLoan(terms);
        
        console.log("POSICION RIESGOSA CREADA con ID:", positionId);
        
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
            console.log("EXITO! Posicion ES liquidable inmediatamente!");
            console.log("Position ID para liquidar:", positionId);
            console.log("");
            console.log("Ejecuta liquidacion con:");
            console.log("Position ID:", positionId);
        } else {
            console.log("Posicion AUN NO liquidable.");
            console.log("Ratio actual:", currentRatio / 1000000000, "%");
            console.log("Necesita estar por debajo de 110%");
            
            uint256 ratioGap = (currentRatio / 1000000000) - 110;
            console.log("Gap restante:", ratioGap, "puntos porcentuales");
            console.log("");
            console.log("Con 20% interest rate, sera liquidable en pocas horas.");
        }
        
        vm.stopBroadcast();
        
        console.log("========================================");
        console.log("POSICION RIESGOSA CREADA");
        console.log("========================================");
    }
} 
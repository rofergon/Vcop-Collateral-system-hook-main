// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";

/**
 * @title CreateHighInterestPosition
 * @notice Crea una posición con interés extremadamente alto para testing de liquidaciones
 */
contract CreateHighInterestPosition is Script {
    
    // Direcciones actualizadas
    address constant GENERIC_LOAN_MANAGER = 0xe2AA5803F1baD51f092650De840Ea79547F26b7d;
    address constant MOCK_ETH = 0x388F7D72FD879725E40d893Fc1b5455036C7fd19;
    address constant MOCK_USDC = 0x009A513d97e55C77060C303f74eE66a991Bd3f08;
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address borrower = vm.addr(privateKey);
        
        console.log("========================================");
        console.log("CREANDO POSICION CON INTERES EXTREMO");
        console.log("========================================");
        console.log("Borrower:", borrower);
        console.log("GenericLoanManager:", GENERIC_LOAN_MANAGER);
        console.log("");
        
        vm.startBroadcast(privateKey);
        
        GenericLoanManager loanManager = GenericLoanManager(GENERIC_LOAN_MANAGER);
        
        // Configurar approvals
        IERC20(MOCK_ETH).approve(GENERIC_LOAN_MANAGER, type(uint256).max);
        IERC20(MOCK_USDC).approve(GENERIC_LOAN_MANAGER, type(uint256).max);
        
        // Crear posición con interés extremo para testing
        // ETH = $2,500, entonces:
        // 1.5 ETH = $3,750 colateral  
        // $2,500 USDC loan = 67% LTV = 150% collateral ratio
        // PERO con 10,000% interest rate anual
        
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: MOCK_ETH,
            loanAsset: MOCK_USDC,
            collateralAmount: 1.5 * 1e18,      // 1.5 ETH ($3,750)
            loanAmount: 2500 * 1e6,            // $2,500 USDC (67% LTV)
            maxLoanToValue: 900000,            // 90% LTV max
            interestRate: 100000000,           // 10,000% anual (EXTREMO!)
            duration: 0                        // Perpetual
        });
        
        console.log("Configuracion de posicion EXTREMA:");
        console.log("  Colateral: 1.5 ETH (~$3,750)");
        console.log("  Prestamo: 2,500 USDC");
        console.log("  LTV: 67%");
        console.log("  Interest Rate: 10,000% ANUAL!!!");
        console.log("  Expected ratio inicial: 150%");
        console.log("");
        
        uint256 positionId = loanManager.createLoan(terms);
        
        console.log("POSICION CREADA con ID:", positionId);
        
        // Verificar estado inicial
        ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        console.log("Estado inicial:");
        console.log("  Activa:", position.isActive);
        console.log("  Borrower:", position.borrower);
        console.log("  Colateral:", position.collateralAmount / 1e18, "ETH");
        console.log("  Loan amount:", position.loanAmount / 1e6, "USDC");
        console.log("  Interest rate:", position.interestRate / 10000, "% anual");
        console.log("");
        
        uint256 currentRatio = loanManager.getCollateralizationRatio(positionId);
        uint256 totalDebt = loanManager.getTotalDebt(positionId);
        bool canLiquidate = loanManager.canLiquidate(positionId);
        
        console.log("Metricas iniciales:");
        console.log("  Ratio actual:", currentRatio / 1000000000, "%");
        console.log("  Deuda total:", totalDebt / 1e6, "USDC");
        console.log("  Es liquidable:", canLiquidate ? "SI" : "NO");
        console.log("");
        
        console.log("========================================");
        console.log("POSICION EXTREMA CREADA EXITOSAMENTE");
        console.log("========================================");
        console.log("Con 10,000% interest rate, el interes se acumula RAPIDAMENTE:");
        console.log("  - Por minuto: ~19% del principal");
        console.log("  - Por hora: ~1,140% del principal");
        console.log("  - Por dia: ~27,397% del principal");
        console.log("");
        console.log("ESPERA unos minutos y luego intenta liquidar!");
        console.log("Usa: cast call", GENERIC_LOAN_MANAGER);
        console.log("Function: canLiquidate(uint256)");
        console.log("Arg:", positionId);
        console.log("RPC: --rpc-url https://sepolia.base.org");
        console.log("Position ID para liquidar:", positionId);
        
        vm.stopBroadcast();
    }
} 
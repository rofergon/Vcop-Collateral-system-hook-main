// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";

/**
 * @title ForceLiquidationAttempt
 * @notice Intenta forzar liquidacion sin verificar canLiquidate
 */
contract ForceLiquidationAttempt is Script {
    
    address constant GENERIC_LOAN_MANAGER = 0xe2AA5803F1baD51f092650De840Ea79547F26b7d;
    address constant MOCK_ETH = 0x388F7D72FD879725E40d893Fc1b5455036C7fd19;
    address constant MOCK_USDC = 0x009A513d97e55C77060C303f74eE66a991Bd3f08;
    
    uint256 constant POSITION_ID = 2; // La posicion con 599,000% ratio
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address liquidator = vm.addr(privateKey);
        
        console.log("========================================");
        console.log("INTENTO DE LIQUIDACION FORZADA");
        console.log("========================================");
        console.log("Position ID:", POSITION_ID);
        console.log("Liquidador:", liquidator);
        console.log("");
        
        GenericLoanManager loanManager = GenericLoanManager(GENERIC_LOAN_MANAGER);
        
        // Verificar estado antes
        ILoanManager.LoanPosition memory position = loanManager.getPosition(POSITION_ID);
        uint256 currentRatio = loanManager.getCollateralizationRatio(POSITION_ID);
        uint256 totalDebt = loanManager.getTotalDebt(POSITION_ID);
        bool canLiquidate = loanManager.canLiquidate(POSITION_ID);
        
        console.log("ESTADO ACTUAL:");
        console.log("  Activa:", position.isActive);
        console.log("  Borrower:", position.borrower);
        console.log("  Colateral:", position.collateralAmount / 1e18, "ETH");
        console.log("  Loan amount:", position.loanAmount / 1e6, "USDC");
        console.log("  Ratio actual:", currentRatio / 1000000000, "%");
        console.log("  Deuda total:", totalDebt / 1e6, "USDC");
        console.log("  canLiquidate():", canLiquidate ? "SI" : "NO");
        console.log("");
        
        // Verificar balances del liquidador
        uint256 ethBefore = IERC20(MOCK_ETH).balanceOf(liquidator);
        uint256 usdcBefore = IERC20(MOCK_USDC).balanceOf(liquidator);
        console.log("Balances del liquidador ANTES:");
        console.log("  ETH:", ethBefore / 1e18);
        console.log("  USDC:", usdcBefore / 1e6);
        console.log("");
        
        vm.startBroadcast(privateKey);
        
        // Aprobar USDC suficiente para pagar la deuda
        IERC20(MOCK_USDC).approve(GENERIC_LOAN_MANAGER, totalDebt);
        console.log("USDC aprobado:", totalDebt / 1e6);
        
        // INTENTAR LIQUIDACION FORZADA
        console.log("=== INTENTANDO LIQUIDACION FORZADA ===");
        console.log("IGNORANDO canLiquidate() = false");
        console.log("Intentando liquidatePosition() directamente...");
        console.log("");
        
        try loanManager.liquidatePosition(POSITION_ID) {
            console.log("LIQUIDACION FORZADA EXITOSA!!!");
            
            // Verificar balances después
            uint256 ethAfter = IERC20(MOCK_ETH).balanceOf(liquidator);
            uint256 usdcAfter = IERC20(MOCK_USDC).balanceOf(liquidator);
            
            console.log("Balances DESPUES de liquidacion:");
            console.log("  ETH:", ethAfter / 1e18);
            console.log("  USDC:", usdcAfter / 1e6);
            console.log("");
            
            console.log("RESULTADO DE LA LIQUIDACION:");
            console.log("  ETH ganado:", (ethAfter - ethBefore) / 1e18);
            console.log("  USDC gastado:", (usdcBefore - usdcAfter) / 1e6);
            
            // Verificar si la posición se cerró
            ILoanManager.LoanPosition memory positionAfter = loanManager.getPosition(POSITION_ID);
            console.log("  Posicion cerrada:", !positionAfter.isActive ? "SI" : "NO");
            
        } catch Error(string memory reason) {
            console.log("LIQUIDACION FALLO - Razon:", reason);
            console.log("");
            console.log("POSIBLES CAUSAS:");
            console.log("1. El contrato verifica canLiquidate() internamente");
            console.log("2. El ratio realmente no cumple las condiciones");
            console.log("3. Hay validaciones adicionales de seguridad");
            console.log("");
            console.log("DIAGNOSTICO:");
            console.log("  Ratio actual:", currentRatio / 1000000000, "%");
            console.log("  Liquidation threshold requerido: ~110%");
            console.log("  Gap:", (currentRatio / 1000000000) - 110, "% puntos");
            
        } catch (bytes memory lowLevelData) {
            console.log("LIQUIDACION FALLO - Datos raw:");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        console.log("========================================");
        console.log("INTENTO DE LIQUIDACION COMPLETADO");
        console.log("========================================");
    }
} 
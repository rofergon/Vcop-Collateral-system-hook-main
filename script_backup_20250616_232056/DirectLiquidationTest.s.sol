// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";

/**
 * @title DirectLiquidationTest
 * @notice Intenta liquidar directamente la posicion ID 1 con 83% ratio
 */
contract DirectLiquidationTest is Script {
    
    // Direcciones actualizadas
    address constant GENERIC_LOAN_MANAGER = 0xFcEFB29436323ABc3dE96B210E93Fe954080fB89;
    address constant MOCK_ETH = 0x80aC5Fb8E4b5D5448754377ef17E9699f789a3C7;
    address constant MOCK_USDC = 0xdfd075c5ECa0b01196d0440b3E67cA207924Fc4B;
    
    uint256 constant POSITION_ID = 1; // Posicion mas reciente en GenericLoanManager nuevo
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address liquidator = vm.addr(privateKey);
        
        console.log("========================================");
        console.log("LIQUIDACION DIRECTA - POSICION ID:", POSITION_ID);
        console.log("========================================");
        console.log("Liquidador:", liquidator);
        console.log("GenericLoanManager:", GENERIC_LOAN_MANAGER);
        console.log("");
        
        GenericLoanManager loanManager = GenericLoanManager(GENERIC_LOAN_MANAGER);
        
        // PASO 1: Verificar estado de la posicion
        console.log("=== PASO 1: VERIFICANDO ESTADO POSICION ===");
        _checkPositionStatus(loanManager, liquidator);
        
        vm.startBroadcast(privateKey);
        
        // PASO 2: Preparar liquidacion
        console.log("=== PASO 2: PREPARANDO LIQUIDACION ===");
        _prepareLiquidation(loanManager, liquidator);
        
        // PASO 3: Ejecutar liquidacion
        console.log("=== PASO 3: EJECUTANDO LIQUIDACION ===");
        _executeLiquidation(loanManager, liquidator);
        
        vm.stopBroadcast();
        
        console.log("========================================");
        console.log("LIQUIDACION COMPLETADA");
        console.log("========================================");
    }
    
    function _checkPositionStatus(GenericLoanManager loanManager, address liquidator) internal view {
        // Verificar que la posicion existe
        ILoanManager.LoanPosition memory position = loanManager.getPosition(POSITION_ID);
        
        console.log("Posicion activa:", position.isActive);
        console.log("Borrower:", position.borrower);
        console.log("Colateral asset:", position.collateralAsset);
        console.log("Loan asset:", position.loanAsset);
        console.log("Colateral amount:", position.collateralAmount / 1e18, "ETH");
        console.log("Loan amount:", position.loanAmount / 1e6, "USDC");
        console.log("Interest rate:", position.interestRate / 10000, "%");
        console.log("");
        
        // Verificar ratio actual
        uint256 currentRatio = loanManager.getCollateralizationRatio(POSITION_ID);
        console.log("Ratio actual:", currentRatio / 1000000000, "%");
        
        // Verificar deuda total
        uint256 totalDebt = loanManager.getTotalDebt(POSITION_ID);
        console.log("Deuda total:", totalDebt / 1e6, "USDC");
        
        // Verificar si es liquidable
        bool canLiquidate = loanManager.canLiquidate(POSITION_ID);
        console.log("Es liquidable:", canLiquidate ? "SI" : "NO");
        console.log("");
        
        // Verificar balances del liquidador
        uint256 ethBalance = IERC20(MOCK_ETH).balanceOf(liquidator);
        uint256 usdcBalance = IERC20(MOCK_USDC).balanceOf(liquidator);
        console.log("Balances del liquidador:");
        console.log("  ETH:", ethBalance / 1e18);
        console.log("  USDC:", usdcBalance / 1e6);
        console.log("");
    }
    
    function _prepareLiquidation(GenericLoanManager loanManager, address liquidator) internal {
        // Obtener deuda total que necesitamos pagar
        uint256 totalDebt = loanManager.getTotalDebt(POSITION_ID);
        console.log("Deuda a pagar:", totalDebt / 1e6, "USDC");
        
        // Verificar que tenemos suficiente USDC
        uint256 usdcBalance = IERC20(MOCK_USDC).balanceOf(liquidator);
        console.log("USDC disponible:", usdcBalance / 1e6);
        
        if (usdcBalance < totalDebt) {
            console.log("ERROR: No hay suficiente USDC para la liquidacion");
            console.log("Necesario:", totalDebt / 1e6, "USDC");
            console.log("Disponible:", usdcBalance / 1e6, "USDC");
            return;
        }
        
        // Aprovar USDC para el loan manager
        IERC20(MOCK_USDC).approve(GENERIC_LOAN_MANAGER, totalDebt);
        console.log("USDC aprobado para liquidacion:", totalDebt / 1e6);
        console.log("");
    }
    
    function _executeLiquidation(GenericLoanManager loanManager, address liquidator) internal {
        // Balances antes de liquidacion
        uint256 ethBefore = IERC20(MOCK_ETH).balanceOf(liquidator);
        uint256 usdcBefore = IERC20(MOCK_USDC).balanceOf(liquidator);
        
        console.log("Balances ANTES de liquidacion:");
        console.log("  ETH:", ethBefore / 1e18);
        console.log("  USDC:", usdcBefore / 1e6);
        console.log("");
        
        // Verificar una vez mas si es liquidable
        bool canLiquidate = loanManager.canLiquidate(POSITION_ID);
        if (!canLiquidate) {
            console.log("ERROR: Posicion NO es liquidable segun canLiquidate()");
            
            // Diagnosticar por que no es liquidable
            ILoanManager.LoanPosition memory position = loanManager.getPosition(POSITION_ID);
            uint256 currentRatio = loanManager.getCollateralizationRatio(POSITION_ID);
            
            console.log("Diagnostico:");
            console.log("  Ratio actual:", currentRatio / 1000000000, "%");
            console.log("  Necesita estar por debajo del liquidation threshold");
            
            // Forzar actualizacion de interes
            console.log("Intentando actualizar interes...");
            loanManager.updateInterest(POSITION_ID);
            
            // Verificar nuevamente
            bool canLiquidateAfterUpdate = loanManager.canLiquidate(POSITION_ID);
            uint256 newRatio = loanManager.getCollateralizationRatio(POSITION_ID);
            console.log("Despues de actualizar interes:");
            console.log("  Nuevo ratio:", newRatio / 1000000000, "%");
            console.log("  Es liquidable ahora:", canLiquidateAfterUpdate ? "SI" : "NO");
            
            if (!canLiquidateAfterUpdate) {
                console.log("RAZON: El ratio aun esta por encima del liquidation threshold");
                return;
            }
        }
        
        // Ejecutar liquidacion
        console.log("Ejecutando liquidacion...");
        try loanManager.liquidatePosition(POSITION_ID) {
            console.log("LIQUIDACION EXITOSA!");
            
            // Verificar balances despues
            uint256 ethAfter = IERC20(MOCK_ETH).balanceOf(liquidator);
            uint256 usdcAfter = IERC20(MOCK_USDC).balanceOf(liquidator);
            
            console.log("Balances DESPUES de liquidacion:");
            console.log("  ETH:", ethAfter / 1e18);
            console.log("  USDC:", usdcAfter / 1e6);
            console.log("");
            
            console.log("GANANCIA DE LA LIQUIDACION:");
            console.log("  ETH ganado:", (ethAfter - ethBefore) / 1e18);
            console.log("  USDC gastado:", (usdcBefore - usdcAfter) / 1e6);
            
            // Calcular profit en USD (estimado)
            uint256 ethGained = ethAfter - ethBefore;
            uint256 usdcSpent = usdcBefore - usdcAfter;
            console.log("");
            console.log("Estimacion de ganancia:");
            console.log("  ETH ganado en USD (~$2500/ETH):", (ethGained * 2500) / 1e18);
            console.log("  USDC gastado:", usdcSpent / 1e6);
            console.log("  Profit neto estimado: $", ((ethGained * 2500) / 1e18) - (usdcSpent / 1e6));
            
        } catch Error(string memory reason) {
            console.log("LIQUIDACION FALLO con razon:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("LIQUIDACION FALLO con datos:");
            console.logBytes(lowLevelData);
        }
    }
} 
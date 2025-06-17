// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";

/**
 * @title ForceUpdateInterest
 * @notice Fuerza actualizaciones de interes en la posicion para acelerar el testing
 */
contract ForceUpdateInterest is Script {
    
    address constant GENERIC_LOAN_MANAGER = 0xe2AA5803F1baD51f092650De840Ea79547F26b7d;
    uint256 constant POSITION_ID = 2;
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("========================================");
        console.log("FORZANDO ACTUALIZACION DE INTERES");
        console.log("========================================");
        console.log("Position ID:", POSITION_ID);
        console.log("GenericLoanManager:", GENERIC_LOAN_MANAGER);
        console.log("");
        
        GenericLoanManager loanManager = GenericLoanManager(GENERIC_LOAN_MANAGER);
        
        vm.startBroadcast(privateKey);
        
        // Verificar estado antes
        uint256 ratioBefore = loanManager.getCollateralizationRatio(POSITION_ID);
        uint256 debtBefore = loanManager.getTotalDebt(POSITION_ID);
        bool liquidableBefore = loanManager.canLiquidate(POSITION_ID);
        
        console.log("ESTADO ANTES:");
        console.log("  Ratio:", ratioBefore / 1000000000, "%");
        console.log("  Deuda total:", debtBefore / 1e6, "USDC");
        console.log("  Es liquidable:", liquidableBefore ? "SI" : "NO");
        console.log("");
        
        // Forzar actualizacion de interes
        console.log("Actualizando interes...");
        loanManager.updateInterest(POSITION_ID);
        
        // Verificar estado despues
        uint256 ratioAfter = loanManager.getCollateralizationRatio(POSITION_ID);
        uint256 debtAfter = loanManager.getTotalDebt(POSITION_ID);
        bool liquidableAfter = loanManager.canLiquidate(POSITION_ID);
        
        console.log("ESTADO DESPUES:");
        console.log("  Ratio:", ratioAfter / 1000000000, "%");
        console.log("  Deuda total:", debtAfter / 1e6, "USDC");
        console.log("  Es liquidable:", liquidableAfter ? "SI" : "NO");
        console.log("");
        
        console.log("CAMBIOS:");
        int256 ratioChange = int256(ratioAfter) - int256(ratioBefore);
        if (ratioChange < 0) {
            console.log("  Ratio BAJO:", uint256(-ratioChange) / 1000000000, "% points");
        } else {
            console.log("  Ratio SUBIO:", uint256(ratioChange) / 1000000000, "% points");
        }
        console.log("  Cambio en deuda:", (debtAfter - debtBefore) / 1e6, "USDC");
        console.log("");
        
        if (liquidableAfter) {
            console.log("POSICION AHORA ES LIQUIDABLE!");
            console.log("Puedes ejecutar: make test-liquidation-direct");
        } else {
            console.log("Posicion aun NO es liquidable.");
            console.log("El liquidation threshold es aproximadamente 110%");
            console.log("Ratio actual:", ratioAfter / 1000000000, "%");
            
            // Calcular tiempo estimado
            uint256 ratioNeed = 110000000000; // 110%
            if (ratioAfter > ratioNeed) {
                uint256 ratioGap = ratioAfter - ratioNeed;
                console.log("Necesita bajar", ratioGap / 1000000000, "puntos porcentuales mas");
                console.log("Con 10,000% interest rate, esto tomara varios minutos");
            }
        }
        
        vm.stopBroadcast();
        
        console.log("========================================");
        console.log("ACTUALIZACION COMPLETADA");
        console.log("========================================");
    }
} 
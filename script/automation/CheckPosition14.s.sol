// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title CheckPosition14
 * @notice Verifica el estado especifico de la posicion 14 despues de corregir precios
 */
contract CheckPosition14 is Script {
    
    function run() external {
        console.log("VERIFICANDO POSICION 14 POST-CORRECCION DE PRECIOS");
        console.log("==================================================");
        console.log("");
        
        // Cargar direcciones
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address loanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        FlexibleLoanManager loanMgr = FlexibleLoanManager(loanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        console.log("CONTRATOS:");
        console.log("  FlexibleLoanManager:", loanManager);
        console.log("  LoanAdapter:", loanAdapter);
        console.log("");
        
        // Verificar posicion 14
        console.log("VERIFICANDO POSICION 14:");
        console.log("========================");
        
        try loanMgr.getPosition(14) returns (ILoanManager.LoanPosition memory position) {
            console.log("Posicion 14 encontrada:");
            console.log("  Borrower:", position.borrower);
            console.log("  Collateral Asset:", position.collateralAsset);
            console.log("  Loan Asset:", position.loanAsset);
            console.log("  Collateral Amount:", position.collateralAmount);
            console.log("  Loan Amount:", position.loanAmount);
            console.log("  Is Active:", position.isActive ? "SI" : "NO");
            console.log("  Created At:", position.createdAt);
            console.log("");
            
            if (position.isActive) {
                // Verificar ratio con precios corregidos
                try loanMgr.getCollateralizationRatio(14) returns (uint256 ratio) {
                    console.log("CALCULOS CON PRECIOS CORREGIDOS:");
                    console.log("===============================");
                    console.log("Ratio actual:", _formatRatio(ratio));
                    
                    // Calcular LTV
                    uint256 ltv = (1000000 * 1000000) / ratio;
                    console.log("LTV actual:", _formatRatio(ltv));
                    
                    // Verificar si puede liquidarse
                    try loanMgr.canLiquidate(14) returns (bool canLiq) {
                        console.log("Puede liquidarse:", canLiq ? "SI" : "NO");
                        
                        if (canLiq) {
                            console.log("[ERROR] PROBLEMA: Posicion aun es liquidable");
                            console.log("Esto indica que hay otro problema:");
                            console.log("1. Calculo de LTV incorrecto");
                            console.log("2. Logica de canLiquidate incorrecta");
                            console.log("3. Handler incorrecto siendo usado");
                        } else {
                            console.log("[OK] CORRECTO: Posicion ya no es liquidable");
                            console.log("Los precios corregidos solucionaron el problema");
                        }
                    } catch {
                        console.log("[ERROR] No se pudo verificar liquidabilidad");
                    }
                    
                    // Verificar debt total
                    try loanMgr.getTotalDebt(14) returns (uint256 debt) {
                        console.log("Total debt:", debt);
                    } catch {
                        console.log("No se pudo obtener debt total");
                    }
                    
                } catch {
                    console.log("[ERROR] No se pudo obtener ratio");
                }
                
                // Verificar si esta en automation tracking
                console.log("");
                console.log("VERIFICANDO AUTOMATION TRACKING:");
                console.log("================================");
                
                try adapter.isPositionAtRisk(14) returns (bool isAtRisk, uint256 riskLevel) {
                    console.log("At Risk segun adapter:", isAtRisk ? "SI" : "NO");
                    console.log("Risk Level:", riskLevel);
                    
                    if (isAtRisk) {
                        console.log("[WARN] Automation aun considera la posicion riesgosa");
                    } else {
                        console.log("[OK] Automation ya no considera la posicion riesgosa");
                    }
                } catch {
                    console.log("[ERROR] No se pudo verificar risk en adapter");
                }
                
            } else {
                console.log("[INFO] Posicion 14 esta INACTIVA");
                console.log("Esto explicaria por que FlexibleLoanManager no la detecta");
            }
            
        } catch {
            console.log("[ERROR] Posicion 14 no existe o no se pudo acceder");
        }
        
        // Verificar todas las posiciones activas
        console.log("");
        console.log("ESCANEANDO TODAS LAS POSICIONES:");
        console.log("================================");
        
        uint256 foundActive = 0;
        for (uint256 i = 1; i <= 20; i++) {
            try loanMgr.getPosition(i) returns (ILoanManager.LoanPosition memory pos) {
                if (pos.isActive) {
                    foundActive++;
                    console.log(string.concat("Posicion activa encontrada: ID ", vm.toString(i)));
                    
                    try loanMgr.getCollateralizationRatio(i) returns (uint256 ratio) {
                        uint256 ltv = (1000000 * 1000000) / ratio;
                        console.log(string.concat("  LTV: ", _formatRatio(ltv)));
                        
                        try loanMgr.canLiquidate(i) returns (bool canLiq) {
                            console.log(string.concat("  Liquidable: ", canLiq ? "SI" : "NO"));
                        } catch {}
                    } catch {}
                }
            } catch {
                // Posicion no existe
            }
        }
        
        console.log("");
        console.log("RESUMEN:");
        console.log("========");
        console.log("Total posiciones activas encontradas:", foundActive);
        
        if (foundActive == 0) {
            console.log("[INFO] No hay posiciones activas");
            console.log("Esto es normal si todas fueron liquidadas o cerradas");
        } else {
            console.log("[INFO] Hay posiciones activas que el diagnostico no detecta");
            console.log("Posible problema en el script de diagnostico");
        }
    }
    
    function _formatRatio(uint256 ratio) internal pure returns (string memory) {
        if (ratio == type(uint256).max) {
            return "INF";
        }
        uint256 percentage = ratio / 10000;
        uint256 decimal = (ratio % 10000) / 100;
        return string.concat(vm.toString(percentage), ".", vm.toString(decimal), "%");
    }
} 
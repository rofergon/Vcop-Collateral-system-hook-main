// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title CheckPosition15
 * @notice Verifica en detalle la posicion 15 y confirma el funcionamiento correcto
 */
contract CheckPosition15 is Script {
    
    function run() external {
        console.log("VERIFICACION DETALLADA - POSICION 15");
        console.log("====================================");
        console.log("");
        
        // Cargar direcciones
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address loanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        address mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        FlexibleLoanManager loanMgr = FlexibleLoanManager(loanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        MockVCOPOracle oracle = MockVCOPOracle(mockOracle);
        
        console.log("CONTRATOS:");
        console.log("  FlexibleLoanManager:", loanManager);
        console.log("  LoanAdapter:", loanAdapter);
        console.log("  MockOracle:", mockOracle);
        console.log("");
        
        // Verificar precios actuales del oracle
        console.log("PRECIOS ACTUALES DEL ORACLE:");
        console.log("============================");
        uint256 ethPrice = oracle.getPrice(mockETH, mockUSDC);
        uint256 usdcPrice = oracle.getPrice(mockUSDC, mockUSDC);
        
        console.log("ETH precio:", ethPrice, "($2500 esperado: 2500000000)");
        console.log("USDC precio:", usdcPrice, "($1 esperado: 1000000)");
        
        if (ethPrice == 2500000000) {
            console.log("[OK] ETH precio correcto");
        } else {
            console.log("[ERROR] ETH precio incorrecto");
        }
        
        if (usdcPrice == 1000000) {
            console.log("[OK] USDC precio correcto");
        } else {
            console.log("[ERROR] USDC precio incorrecto");
        }
        console.log("");
        
        // Verificar posicion 15 en detalle
        console.log("ANALISIS DETALLADO - POSICION 15:");
        console.log("=================================");
        
        try loanMgr.getPosition(15) returns (ILoanManager.LoanPosition memory position) {
            console.log("DATOS BASICOS:");
            console.log("  Borrower:", position.borrower);
            console.log("  Collateral Asset:", position.collateralAsset);
            console.log("  Loan Asset:", position.loanAsset);
            console.log("  Collateral Amount:", position.collateralAmount, "wei");
            console.log("  Collateral Amount (ETH):", position.collateralAmount / 1e18);
            console.log("  Loan Amount:", position.loanAmount, "wei");
            console.log("  Loan Amount (USDC):", position.loanAmount / 1e6);
            console.log("  Is Active:", position.isActive ? "SI" : "NO");
            console.log("  Interest Rate:", position.interestRate);
            console.log("");
            
            if (position.isActive) {
                // Calculos financieros detallados
                console.log("CALCULOS FINANCIEROS:");
                console.log("====================");
                
                // Valores en USD
                uint256 collateralValueUSD = (position.collateralAmount * ethPrice) / 1e18;
                uint256 loanValueUSD = (position.loanAmount * usdcPrice) / 1e6;
                
                console.log("Collateral Value USD:", collateralValueUSD / 1e6, "USD");
                console.log("Loan Value USD:", loanValueUSD / 1e6, "USD");
                
                // LTV manual
                uint256 ltvManual = (loanValueUSD * 1000000) / collateralValueUSD;
                console.log("LTV Manual:", _formatRatio(ltvManual));
                
                // Ratio de contrato
                try loanMgr.getCollateralizationRatio(15) returns (uint256 ratio) {
                    console.log("Ratio del Contrato:", _formatRatio(ratio));
                    
                    uint256 ltvContract = (1000000 * 1000000) / ratio;
                    console.log("LTV del Contrato:", _formatRatio(ltvContract));
                    
                    // Verificar consistencia
                    if (_abs(ltvManual, ltvContract) < 10000) { // Diferencia < 1%
                        console.log("[OK] Calculos consistentes");
                    } else {
                        console.log("[WARN] Diferencia en calculos detectada");
                    }
                } catch {
                    console.log("[ERROR] No se pudo obtener ratio del contrato");
                }
                
                console.log("");
                console.log("VERIFICACION DE LIQUIDACION:");
                console.log("============================");
                
                // Verificar si puede liquidarse
                try loanMgr.canLiquidate(15) returns (bool canLiq) {
                    console.log("Puede liquidarse:", canLiq ? "SI" : "NO");
                    
                    if (canLiq && ltvManual <= 950000) {
                        console.log("[ERROR] PROBLEMA: Se puede liquidar con LTV <= 95%");
                    } else if (!canLiq && ltvManual > 960000) {
                        console.log("[ERROR] PROBLEMA: NO se puede liquidar con LTV > 96%");
                    } else if (!canLiq && ltvManual <= 950000) {
                        console.log("[OK] CORRECTO: NO se liquida con LTV <= 95%");
                    } else {
                        console.log("[INFO] Comportamiento esperado para este LTV");
                    }
                } catch {
                    console.log("[ERROR] No se pudo verificar liquidabilidad");
                }
                
                // Verificar debt total
                try loanMgr.getTotalDebt(15) returns (uint256 debt) {
                    console.log("Total Debt:", debt);
                    console.log("Principal:", position.loanAmount);
                    console.log("Interest Accrued:", debt - position.loanAmount);
                } catch {
                    console.log("No se pudo obtener debt total");
                }
                
                console.log("");
                console.log("AUTOMATION ANALYSIS:");
                console.log("====================");
                
                // Verificar automation adapter
                try adapter.isPositionAtRisk(15) returns (bool isAtRisk, uint256 riskLevel) {
                    console.log("At Risk (Automation):", isAtRisk ? "SI" : "NO");
                    console.log("Risk Level:", riskLevel);
                    
                    if (isAtRisk && ltvManual <= 950000) {
                        console.log("[WARN] Automation considera riesgosa una posicion segura");
                    } else if (!isAtRisk && ltvManual <= 950000) {
                        console.log("[OK] Automation correctamente considera la posicion segura");
                    }
                } catch {
                    console.log("[ERROR] No se pudo verificar risk en automation");
                }
                
            } else {
                console.log("[ERROR] Posicion 15 esta INACTIVA");
                console.log("Esto significa que fue liquidada o cerrada");
            }
            
        } catch {
            console.log("[ERROR] Posicion 15 no existe");
        }
        
        console.log("");
        console.log("RESUMEN DEL ESTADO:");
        console.log("===================");
        console.log("Si la posicion 15 esta activa con LTV ~90% y NO es liquidable:");
        console.log("-> El sistema funciona CORRECTAMENTE");
        console.log("-> Las correcciones aplicadas fueron efectivas");
        console.log("-> El buffer de seguridad esta funcionando");
        console.log("");
        console.log("Si la posicion esta inactiva o es liquidable:");
        console.log("-> Hay un problema que requiere mas investigacion");
    }
    
    function _formatRatio(uint256 ratio) internal pure returns (string memory) {
        if (ratio == type(uint256).max) {
            return "INF";
        }
        uint256 percentage = ratio / 10000;
        uint256 decimal = (ratio % 10000) / 100;
        return string.concat(vm.toString(percentage), ".", vm.toString(decimal), "%");
    }
    
    function _abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }
} 
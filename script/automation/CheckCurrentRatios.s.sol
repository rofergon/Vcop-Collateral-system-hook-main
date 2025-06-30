// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title CheckCurrentRatios
 * @notice Diagnostico de ratios actuales en Avalanche Fuji
 */
contract CheckCurrentRatios is Script {
    
    function run() external {
        console.log("DIAGNOSTICO DE RATIOS ACTUALES - AVALANCHE FUJI");
        console.log("===============================================");
        console.log("");
        
        // Cargar direcciones
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address vaultHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address flexHandler = vm.parseJsonAddress(json, ".coreLending.flexibleAssetHandler");
        address loanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        console.log("CONTRATOS:");
        console.log("  VaultBasedHandler:", vaultHandler);
        console.log("  FlexibleAssetHandler:", flexHandler);
        console.log("  FlexibleLoanManager:", loanManager);
        console.log("  LoanAdapter:", loanAdapter);
        console.log("");
        
        console.log("TOKENS:");
        console.log("  MockETH:", mockETH);
        console.log("  MockUSDC:", mockUSDC);
        console.log("  MockWBTC:", mockWBTC);
        console.log("");
        
        // Verificar VaultBasedHandler
        console.log("VAULT BASED HANDLER - RATIOS:");
        console.log("==============================");
        _checkVaultRatios(vaultHandler, mockETH, "MockETH");
        _checkVaultRatios(vaultHandler, mockUSDC, "MockUSDC");
        _checkVaultRatios(vaultHandler, mockWBTC, "MockWBTC");
        
        // Verificar FlexibleAssetHandler
        console.log("FLEXIBLE ASSET HANDLER - RATIOS:");
        console.log("=================================");
        _checkFlexibleRatios(flexHandler, mockETH, "MockETH");
        _checkFlexibleRatios(flexHandler, mockUSDC, "MockUSDC");
        _checkFlexibleRatios(flexHandler, mockWBTC, "MockWBTC");
        
        // Verificar posiciones activas
        console.log("POSICIONES ACTIVAS:");
        console.log("===================");
        _checkActivePositions(loanManager);
        
        // Verificar automation
        console.log("AUTOMATION STATUS:");
        console.log("==================");
        _checkAutomationStatus(loanAdapter);
        
        // Identificar problemas
        console.log("ANALISIS DE PROBLEMAS:");
        console.log("======================");
        _identifyIssues(loanManager, mockETH, mockUSDC, mockWBTC);
    }
    
    function _checkVaultRatios(address handler, address token, string memory name) internal view {
        VaultBasedHandler vault = VaultBasedHandler(handler);
        
        console.log(string.concat("  ", name, ":"));
        try vault.getAssetConfig(token) returns (IAssetHandler.AssetConfig memory config) {
            if (config.isActive) {
                console.log("    [OK] ACTIVO");
                console.log("    Collateral:", _formatRatio(config.collateralRatio));
                console.log("    Liquidation:", _formatRatio(config.liquidationRatio));
                
                // Calcular LTV de liquidacion
                uint256 liqLTV = (1000000 * 1000000) / config.liquidationRatio;
                console.log("    LTV Liquidacion:", _formatRatio(liqLTV));
                
                if (liqLTV > 950000) {
                    console.log("    [ERROR] PROBLEMA: Liquida con LTV >95%");
                } else {
                    console.log("    [OK] Solo liquida con LTV >95%");
                }
            } else {
                console.log("    [ERROR] INACTIVO");
            }
        } catch {
            console.log("    [ERROR] al obtener config");
        }
        console.log("");
    }
    
    function _checkFlexibleRatios(address handler, address token, string memory name) internal view {
        FlexibleAssetHandler flex = FlexibleAssetHandler(handler);
        
        console.log(string.concat("  ", name, ":"));
        try flex.isAssetSupported(token) returns (bool supported) {
            if (supported) {
                try flex.getAssetConfig(token) returns (IAssetHandler.AssetConfig memory config) {
                    console.log("    [OK] SOPORTADO");
                    console.log("    Collateral:", _formatRatio(config.collateralRatio));
                    console.log("    Liquidation:", _formatRatio(config.liquidationRatio));
                    console.log("    Type:", uint256(config.assetType));
                } catch {
                    console.log("    [ERROR] al obtener config");
                }
            } else {
                console.log("    [ERROR] NO SOPORTADO");
            }
        } catch {
            console.log("    [ERROR] al verificar soporte");
        }
        console.log("");
    }
    
    function _checkActivePositions(address manager) internal view {
        FlexibleLoanManager loan = FlexibleLoanManager(manager);
        
        uint256 found = 0;
        for (uint256 i = 1; i <= 20; i++) {
            try loan.getPosition(i) returns (ILoanManager.LoanPosition memory pos) {
                if (pos.isActive) {
                    found++;
                    console.log(string.concat("  Posicion ", vm.toString(i), ":"));
                    console.log("    Borrower:", pos.borrower);
                    console.log("    Collateral Amount:", pos.collateralAmount);
                    console.log("    Loan Amount:", pos.loanAmount);
                    
                    try loan.getCollateralizationRatio(i) returns (uint256 ratio) {
                        console.log("    Ratio Actual:", _formatRatio(ratio));
                        
                        uint256 ltv = (1000000 * 1000000) / ratio;
                        console.log("    LTV Actual:", _formatRatio(ltv));
                        
                        try loan.canLiquidate(i) returns (bool canLiq) {
                            console.log("    Liquidable:", canLiq ? "SI" : "NO");
                            
                            // Verificar logica
                            if (canLiq && ltv <= 950000) {
                                console.log("    [ERROR] PROBLEMA: Se liquida con LTV <=95%");
                            } else if (!canLiq && ltv > 950000) {
                                console.log("    [ERROR] PROBLEMA: NO se liquida con LTV >95%");
                            } else {
                                console.log("    [OK] Comportamiento correcto");
                            }
                        } catch {
                            console.log("    [ERROR] en canLiquidate");
                        }
                    } catch {
                        console.log("    [ERROR] al obtener ratio");
                    }
                    console.log("");
                }
            } catch {
                // Posicion no existe
            }
        }
        
        console.log("  Total posiciones encontradas:", found);
        console.log("");
    }
    
    function _checkAutomationStatus(address adapter) internal view {
        LoanManagerAutomationAdapter automation = LoanManagerAutomationAdapter(adapter);
        
        try automation.isAutomationEnabled() returns (bool enabled) {
            console.log("  Automation Enabled:", enabled ? "SI" : "NO");
        } catch {
            console.log("  [ERROR] No se pudo verificar automation");
        }
        
        try automation.getTotalActivePositions() returns (uint256 total) {
            console.log("  Posiciones Tracked:", total);
        } catch {
            console.log("  [ERROR] No se pudo obtener posiciones tracked");
        }
        console.log("");
    }
    
    function _identifyIssues(address manager, address eth, address usdc, address wbtc) internal view {
        FlexibleLoanManager loan = FlexibleLoanManager(manager);
        
        console.log("IDENTIFICANDO HANDLER USADO POR FLEXIBLELOANMANAGER:");
        console.log("====================================================");
        
        // Verificar que handler se usa para cada token
        address[] memory tokens = new address[](3);
        tokens[0] = eth;
        tokens[1] = usdc;
        tokens[2] = wbtc;
        
        string[] memory names = new string[](3);
        names[0] = "MockETH";
        names[1] = "MockUSDC";
        names[2] = "MockWBTC";
        
        for (uint256 i = 0; i < tokens.length; i++) {
            console.log(string.concat("  ", names[i], ":"));
            
            // Intentar determinar que handler usa internamente
            // (esto requeriria acceso a _getAssetHandler, que es internal)
            console.log("    Handler usado: (funcion internal, no accesible)");
            console.log("");
        }
        
        console.log("POSIBLES PROBLEMAS IDENTIFICADOS:");
        console.log("=================================");
        console.log("1. Multiple handlers configurados para el mismo token");
        console.log("2. FlexibleLoanManager usando handler con ratios incorrectos");
        console.log("3. Inconsistencia entre ratios en diferentes handlers");
        console.log("4. Automation detectando con threshold incorrecto");
        console.log("");
        
        console.log("SOLUCIONES RECOMENDADAS:");
        console.log("========================");
        console.log("1. Unificar ratios en TODOS los handlers a 105.26%");
        console.log("2. Verificar orden de handlers en FlexibleLoanManager");
        console.log("3. Configurar automation threshold a 95");
        console.log("4. Probar liquidacion manual para confirmar");
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
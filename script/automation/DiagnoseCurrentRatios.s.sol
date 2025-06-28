// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";
import {MintableBurnableHandler} from "../../src/core/MintableBurnableHandler.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title DiagnoseCurrentRatios
 * @notice 🔍 DIAGNÓSTICO COMPLETO: Ratios actuales en Avalanche Fuji
 * @dev Rastrea todos los ratios configurados para identificar inconsistencias
 */
contract DiagnoseCurrentRatios is Script {
    
    // Direcciones de contratos
    address public vaultBasedHandler;
    address public flexibleAssetHandler;
    address public mintableBurnableHandler;
    address public flexibleLoanManager;
    address public loanAdapter;
    address public automationKeeper;
    
    // Tokens
    address public mockETH;
    address public mockUSDC;
    address public mockWBTC;
    
    function run() external {
        console.log("🔍 DIAGNÓSTICO COMPLETO DE RATIOS EN AVALANCHE FUJI");
        console.log("==================================================");
        console.log("");
        
        _loadAddresses();
        _printContractAddresses();
        
        console.log("📊 ANÁLISIS DE RATIOS ACTUALES:");
        console.log("===============================");
        _analyzeVaultBasedHandler();
        _analyzeFlexibleAssetHandler();
        _analyzeMintableBurnableHandler();
        
        console.log("");
        console.log("🎯 ANÁLISIS DE POSICIONES ACTIVAS:");
        console.log("==================================");
        _analyzeActivePositions();
        
        console.log("");
        console.log("🤖 ANÁLISIS DE CONFIGURACIÓN AUTOMATION:");
        console.log("=========================================");
        _analyzeAutomationConfig();
        
        console.log("");
        console.log("🚨 DIAGNÓSTICO DE PROBLEMAS:");
        console.log("============================");
        _identifyProblems();
    }
    
    function _loadAddresses() internal {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        flexibleAssetHandler = vm.parseJsonAddress(json, ".coreLending.flexibleAssetHandler");
        mintableBurnableHandler = vm.parseJsonAddress(json, ".coreLending.mintableBurnableHandler");
        flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        
        mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
    }
    
    function _printContractAddresses() internal view {
        console.log("📋 DIRECCIONES DE CONTRATOS:");
        console.log("  VaultBasedHandler:", vaultBasedHandler);
        console.log("  FlexibleAssetHandler:", flexibleAssetHandler);
        console.log("  MintableBurnableHandler:", mintableBurnableHandler);
        console.log("  FlexibleLoanManager:", flexibleLoanManager);
        console.log("  LoanAdapter:", loanAdapter);
        console.log("  AutomationKeeper:", automationKeeper);
        console.log("");
        console.log("🪙 TOKENS:");
        console.log("  MockETH:", mockETH);
        console.log("  MockUSDC:", mockUSDC);
        console.log("  MockWBTC:", mockWBTC);
        console.log("");
    }
    
    function _analyzeVaultBasedHandler() internal view {
        console.log("🏦 VAULT BASED HANDLER - Ratios Actuales:");
        console.log("-----------------------------------------");
        
        VaultBasedHandler vaultHandler = VaultBasedHandler(vaultBasedHandler);
        
        address[] memory tokens = new address[](3);
        tokens[0] = mockETH;
        tokens[1] = mockUSDC;
        tokens[2] = mockWBTC;
        
        string[] memory tokenNames = new string[](3);
        tokenNames[0] = "MockETH";
        tokenNames[1] = "MockUSDC";
        tokenNames[2] = "MockWBTC";
        
        for (uint256 i = 0; i < tokens.length; i++) {
            console.log(string.concat("  ", tokenNames[i], ":"));
            
            try vaultHandler.getAssetConfig(tokens[i]) returns (IAssetHandler.AssetConfig memory config) {
                if (config.isActive) {
                    console.log("    ✅ ACTIVO");
                    console.log("    📊 Collateral Ratio:", _formatRatio(config.collateralRatio));
                    console.log("    ⚠️  Liquidation Ratio:", _formatRatio(config.liquidationRatio));
                    console.log("    💰 Max Loan:", config.maxLoanAmount);
                    console.log("    📈 Interest Rate:", _formatBasisPoints(config.interestRate));
                    
                    // Calcular LTV equivalente
                    uint256 maxLTV = (1000000 * 1000000) / config.collateralRatio;
                    uint256 liquidationLTV = (1000000 * 1000000) / config.liquidationRatio;
                    console.log("    🎯 Max LTV permitido:", _formatRatio(maxLTV));
                    console.log("    🚨 LTV de liquidación:", _formatRatio(liquidationLTV));
                    
                    // Verificar si está dentro del objetivo (LTV ≤ 95%)
                    if (liquidationLTV <= 950000) {
                        console.log("    ✅ CORRECTO: Solo liquida si LTV > 95%");
                    } else {
                        console.log("    ❌ PROBLEMA: Liquida antes del 95% LTV objetivo");
                    }
                } else {
                    console.log("    ❌ INACTIVO");
                }
            } catch {
                console.log("    ❓ ERROR: No se pudo obtener configuración");
            }
            console.log("");
        }
    }
    
    function _analyzeFlexibleAssetHandler() internal view {
        console.log("🔧 FLEXIBLE ASSET HANDLER - Ratios Actuales:");
        console.log("--------------------------------------------");
        
        FlexibleAssetHandler flexHandler = FlexibleAssetHandler(flexibleAssetHandler);
        
        address[] memory tokens = new address[](3);
        tokens[0] = mockETH;
        tokens[1] = mockUSDC;
        tokens[2] = mockWBTC;
        
        string[] memory tokenNames = new string[](3);
        tokenNames[0] = "MockETH";
        tokenNames[1] = "MockUSDC";
        tokenNames[2] = "MockWBTC";
        
        for (uint256 i = 0; i < tokens.length; i++) {
            console.log(string.concat("  ", tokenNames[i], ":"));
            
            try flexHandler.getAssetConfig(tokens[i]) returns (IAssetHandler.AssetConfig memory config) {
                if (config.isActive) {
                    console.log("    ✅ ACTIVO");
                    console.log("    📊 Collateral Ratio:", _formatRatio(config.collateralRatio));
                    console.log("    ⚠️  Liquidation Ratio:", _formatRatio(config.liquidationRatio));
                    console.log("    🔧 Tipo:", _formatAssetType(config.assetType));
                } else {
                    console.log("    ❌ INACTIVO");
                }
            } catch {
                console.log("    ❓ ERROR: No se pudo obtener configuración");
            }
            console.log("");
        }
    }
    
    function _analyzeMintableBurnableHandler() internal view {
        console.log("🪙 MINTABLE BURNABLE HANDLER - Ratios Actuales:");
        console.log("-----------------------------------------------");
        
        MintableBurnableHandler mintHandler = MintableBurnableHandler(mintableBurnableHandler);
        
        address[] memory tokens = new address[](3);
        tokens[0] = mockETH;
        tokens[1] = mockUSDC;
        tokens[2] = mockWBTC;
        
        string[] memory tokenNames = new string[](3);
        tokenNames[0] = "MockETH";
        tokenNames[1] = "MockUSDC";
        tokenNames[2] = "MockWBTC";
        
        for (uint256 i = 0; i < tokens.length; i++) {
            console.log(string.concat("  ", tokenNames[i], ":"));
            
            try mintHandler.isAssetSupported(tokens[i]) returns (bool isSupported) {
                if (isSupported) {
                    try mintHandler.getAssetConfig(tokens[i]) returns (IAssetHandler.AssetConfig memory config) {
                        console.log("    ✅ SOPORTADO");
                        console.log("    📊 Collateral Ratio:", _formatRatio(config.collateralRatio));
                        console.log("    ⚠️  Liquidation Ratio:", _formatRatio(config.liquidationRatio));
                    } catch {
                        console.log("    ❓ ERROR: No se pudo obtener configuración");
                    }
                } else {
                    console.log("    ❌ NO SOPORTADO");
                }
            } catch {
                console.log("    ❓ ERROR: No se pudo verificar soporte");
            }
            console.log("");
        }
    }
    
    function _analyzeActivePositions() internal view {
        console.log("🎯 POSICIONES ACTIVAS EN FLEXIBLELOANMANAGER:");
        console.log("---------------------------------------------");
        
        FlexibleLoanManager loanMgr = FlexibleLoanManager(flexibleLoanManager);
        
        // Verificar posiciones 1-20 (rango común)
        uint256 foundPositions = 0;
        for (uint256 i = 1; i <= 20; i++) {
            try loanMgr.getPosition(i) returns (ILoanManager.LoanPosition memory position) {
                if (position.isActive) {
                    foundPositions++;
                    console.log(string.concat("  Posición ", vm.toString(i), ":"));
                    console.log("    👤 Borrower:", position.borrower);
                    console.log("    💎 Collateral:", _getTokenName(position.collateralAsset));
                    console.log("    💵 Loan Asset:", _getTokenName(position.loanAsset));
                    console.log("    📊 Collateral Amount:", position.collateralAmount);
                    console.log("    💰 Loan Amount:", position.loanAmount);
                    
                    // Obtener ratio actual
                    try loanMgr.getCollateralizationRatio(i) returns (uint256 ratio) {
                        console.log("    📈 Ratio Actual:", _formatRatio(ratio));
                        
                        // Calcular LTV actual
                        uint256 currentLTV = (1000000 * 1000000) / ratio;
                        console.log("    🎯 LTV Actual:", _formatRatio(currentLTV));
                        
                        // Verificar si puede liquidarse
                        try loanMgr.canLiquidate(i) returns (bool canLiq) {
                            console.log("    🚨 Puede Liquidarse:", canLiq ? "SI" : "NO");
                            
                            if (canLiq && currentLTV <= 950000) {
                                console.log("    ❌ PROBLEMA: Se liquida con LTV ≤ 95%");
                            } else if (!canLiq && currentLTV > 950000) {
                                console.log("    ❌ PROBLEMA: NO se liquida con LTV > 95%");
                            } else {
                                console.log("    ✅ CORRECTO: Comportamiento esperado");
                            }
                        } catch {
                            console.log("    ❓ ERROR: No se pudo verificar liquidabilidad");
                        }
                    } catch {
                        console.log("    ❓ ERROR: No se pudo obtener ratio");
                    }
                    console.log("");
                }
            } catch {
                // Posición no existe, continuar
            }
        }
        
        if (foundPositions == 0) {
            console.log("  ❌ No se encontraron posiciones activas");
        } else {
            console.log("  ✅ Total posiciones encontradas:", foundPositions);
        }
        console.log("");
    }
    
    function _analyzeAutomationConfig() internal view {
        console.log("🤖 CONFIGURACIÓN DE AUTOMATION:");
        console.log("-------------------------------");
        
        // Analizar LoanManagerAutomationAdapter
        try LoanManagerAutomationAdapter(loanAdapter).isAutomationEnabled() returns (bool enabled) {
            console.log("  📡 Automation Enabled:", enabled ? "SI" : "NO");
            
            try LoanManagerAutomationAdapter(loanAdapter).getTotalActivePositions() returns (uint256 total) {
                console.log("  📊 Posiciones Tracked:", total);
            } catch {
                console.log("  ❓ No se pudo obtener total de posiciones");
            }
        } catch {
            console.log("  ❓ ERROR: No se pudo verificar adapter");
        }
        
        // Analizar LoanAutomationKeeperOptimized
        try LoanAutomationKeeperOptimized(automationKeeper).minRiskThreshold() returns (uint256 threshold) {
            console.log("  🎯 Min Risk Threshold:", threshold);
            
            if (threshold < 90) {
                console.log("    ❌ PROBLEMA: Threshold muy bajo, detecta posiciones seguras");
            } else if (threshold > 95) {
                console.log("    ⚠️  ADVERTENCIA: Threshold alto, puede perder liquidaciones críticas");
            } else {
                console.log("    ✅ CORRECTO: Threshold en rango apropiado");
            }
        } catch {
            console.log("  ❓ ERROR: No se pudo obtener threshold");
        }
        
        try LoanAutomationKeeperOptimized(automationKeeper).liquidationCooldown() returns (uint256 cooldown) {
            console.log("  ⏰ Liquidation Cooldown:", cooldown, "segundos");
        } catch {
            console.log("  ❓ ERROR: No se pudo obtener cooldown");
        }
    }
    
    function _identifyProblems() internal view {
        console.log("🚨 RESUMEN DE PROBLEMAS IDENTIFICADOS:");
        console.log("=====================================");
        
        console.log("1. 🔍 VERIFICAR ASSET HANDLER LOOKUP:");
        console.log("   - FlexibleLoanManager._getAssetHandler() podría estar");
        console.log("     retornando el handler incorrecto para MockETH");
        console.log("");
        
        console.log("2. 🎯 INCONSISTENCIAS EN RATIOS:");
        console.log("   - Diferentes handlers podrían tener ratios distintos");
        console.log("     para el mismo token");
        console.log("");
        
        console.log("3. 🤖 CONFIGURACIÓN DE AUTOMATION:");
        console.log("   - Risk threshold podría estar detectando posiciones");
        console.log("     seguras como liquidables");
        console.log("");
        
        console.log("4. 📊 PROBLEMA EN canLiquidate():");
        console.log("   - La lógica de liquidación podría no estar usando");
        console.log("     los ratios actualizados correctamente");
        console.log("");
        
        console.log("🔧 PRÓXIMOS PASOS RECOMENDADOS:");
        console.log("===============================");
        console.log("1. Ejecutar script de unificación de ratios");
        console.log("2. Verificar qué handler usa FlexibleLoanManager para MockETH");
        console.log("3. Ajustar automation risk threshold a 95");
        console.log("4. Probar liquidación manual de posición problemática");
    }
    
    // Funciones de utilidad
    function _formatRatio(uint256 ratio) internal pure returns (string memory) {
        if (ratio == type(uint256).max) {
            return "INFINITO";
        }
        uint256 percentage = ratio / 10000; // Convert from 6 decimals to 2 decimals
        uint256 decimal = (ratio % 10000) / 100;
        return string.concat(vm.toString(percentage), ".", vm.toString(decimal), "%");
    }
    
    function _formatBasisPoints(uint256 bps) internal pure returns (string memory) {
        uint256 percentage = bps / 10000;
        uint256 decimal = (bps % 10000) / 100;
        return string.concat(vm.toString(percentage), ".", vm.toString(decimal), "%");
    }
    
    function _formatAssetType(IAssetHandler.AssetType assetType) internal pure returns (string memory) {
        if (assetType == IAssetHandler.AssetType.MINTABLE_BURNABLE) {
            return "MINTABLE_BURNABLE";
        } else if (assetType == IAssetHandler.AssetType.VAULT_BASED) {
            return "VAULT_BASED";
        } else if (assetType == IAssetHandler.AssetType.EXTERNAL) {
            return "EXTERNAL";
        } else {
            return "UNKNOWN";
        }
    }
    
    function _getTokenName(address token) internal view returns (string memory) {
        if (token == mockETH) return "MockETH";
        if (token == mockUSDC) return "MockUSDC";
        if (token == mockWBTC) return "MockWBTC";
        return string.concat("Unknown(", vm.toString(token), ")");
    }
} 
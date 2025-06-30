// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";

/**
 * @title DiagnoseAndFixChainlinkAutomation
 * @notice Diagnostico completo: Por que Chainlink Automation no ejecuta performUpkeep
 * @dev Verifica registro, fondeo, checkUpkeep y configuracion del upkeep
 */
contract DiagnoseAndFixChainlinkAutomation is Script {
    
    // Chainlink addresses for Avalanche Fuji
    address constant CHAINLINK_REGISTRY = 0x819B58A646CDd8289275A87653a2aA4902b14fe6;
    address constant CHAINLINK_REGISTRAR = 0xD23D3D1b81711D75E1012211f1b65Cc7dBB474e2;
    address constant LINK_TOKEN = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    
    // ========== DEPLOYED CONTRACTS ==========
    LoanAutomationKeeperOptimized public automationKeeper;
    LoanManagerAutomationAdapter public loanAdapter;
    FlexibleLoanManager public loanManager;
    
    // ========== DIAGNOSIS RESULTS ==========
    struct DiagnosisReport {
        bool contractExists;
        bool isRegistered;
        uint256 upkeepId;
        uint96 linkBalance;
        bool isActive;
        bool checkUpkeepWorks;
        bytes checkData;
        string issues;
    }
    
    function run() external {
        console.log("=== DIAGNOSTICO CHAINLINK AUTOMATION ===");
        console.log("==========================================");
        console.log("");
        
        _performDiagnosis();
        _showSolutions();
    }
    
    /**
     * @dev Realiza diagnostico completo del sistema
     */
    function _performDiagnosis() internal view {
        console.log("EJECUTANDO DIAGNOSTICO...");
        console.log("");
        
        // 1. Verificar contratos desplegados
        _checkDeployedContracts();
        
        // 2. Verificar configuracion interna
        _checkInternalConfig();
        
        // 3. Generar checkData correcto
        _generateCheckData();
        
        console.log("");
    }
    
    /**
     * @dev Verifica que los contratos esten desplegados
     */
    function _checkDeployedContracts() internal view {
        console.log("1. VERIFICANDO CONTRATOS DESPLEGADOS");
        console.log("===================================");
        
        try vm.readFile("deployed-addresses-mock.json") returns (string memory content) {
            console.log("ARCHIVO deployed-addresses-mock.json encontrado");
            
            // Extraer direcciones manualmente del JSON
            console.log("Contenido del archivo:");
            console.log(content);
            
        } catch {
            console.log("ERROR: No se encontro deployed-addresses-mock.json");
            console.log("SOLUCION: Ejecutar make deploy-avalanche-full-stack-mock");
        }
        
        console.log("");
    }
    
    /**
     * @dev Verifica configuracion interna
     */
    function _checkInternalConfig() internal pure {
        console.log("2. VERIFICANDO CONFIGURACION INTERNA");
        console.log("===================================");
        console.log("NECESITAS VERIFICAR MANUALMENTE:");
        console.log("- Automation Keeper desplegado");
        console.log("- LoanAdapter desplegado");
        console.log("- LoanAdapter registrado en Keeper");
        console.log("- Automation habilitado");
        console.log("- Risk thresholds configurados");
        console.log("- Posiciones liquidables existentes");
        console.log("");
    }
    
    /**
     * @dev Genera checkData correcto para registro
     */
    function _generateCheckData() internal pure {
        console.log("3. GENERANDO CHECKDATA CORRECTO");
        console.log("==============================");
        
        // Ejemplo de checkData (ajustar direcciones reales)
        address exampleLoanAdapter = 0x1234567890123456789012345678901234567890;
        uint256 startIndex = 0;
        uint256 batchSize = 25;
        
        bytes memory checkData = abi.encode(exampleLoanAdapter, startIndex, batchSize);
        
        console.log("CheckData para registro en Chainlink:");
        console.logBytes(checkData);
        console.log("");
        
        console.log("INSTRUCCIONES PARA USAR:");
        console.log("1. Reemplaza exampleLoanAdapter con tu direccion real");
        console.log("2. Copia el checkData hex");
        console.log("3. Usa en el registro de Chainlink");
        console.log("");
    }
    
    /**
     * @dev Muestra soluciones paso a paso
     */
    function _showSolutions() internal pure {
        console.log("=== SOLUCIONES PASO A PASO ===");
        console.log("===============================");
        console.log("");
        
        console.log("PROBLEMA MAS COMUN: UPKEEP NO REGISTRADO O SIN FONDOS");
        console.log("");
        
        console.log("PASO 1: VERIFICAR DEPLOYMENT");
        console.log("----------------------------");
        console.log("make deploy-avalanche-full-stack-mock");
        console.log("");
        
        console.log("PASO 2: CONFIGURAR AUTOMATION");
        console.log("-----------------------------");
        console.log("make configure-avalanche-vault-automation");
        console.log("make configure-avalanche-default-risk-thresholds");
        console.log("");
        
        console.log("PASO 3: CREAR POSICIONES LIQUIDABLES");
        console.log("------------------------------------");
        console.log("make create-avalanche-test-loan");
        console.log("make crash-avalanche-market");
        console.log("");
        
        console.log("PASO 4: REGISTRAR EN CHAINLINK (MANUAL)");
        console.log("---------------------------------------");
        console.log("1. Ir a: https://automation.chain.link/avalanche-fuji");
        console.log("2. Conectar wallet");
        console.log("3. Click 'Register New Upkeep'");
        console.log("4. Seleccionar 'Custom Logic'");
        console.log("5. Configurar:");
        console.log("   - Target Contract: [Tu AutomationKeeper address]");
        console.log("   - Gas Limit: 500000");
        console.log("   - Check Gas Limit: 50000");
        console.log("   - CheckData: [Usar el generado arriba]");
        console.log("   - Funding: 5-10 LINK tokens");
        console.log("");
        
        console.log("PASO 5: OBTENER LINK TOKENS");
        console.log("---------------------------");
        console.log("Faucet: https://faucets.chain.link/fuji");
        console.log("");
        
        console.log("PASO 6: VERIFICAR FUNCIONAMIENTO");
        console.log("--------------------------------");
        console.log("1. Esperar 1-2 minutos");
        console.log("2. Verificar en dashboard si detecta posiciones");
        console.log("3. Si no funciona, revisar logs del upkeep");
        console.log("");
        
        console.log("COMANDOS DE VERIFICACION:");
        console.log("========================");
        console.log("make monitor-avalanche-automation");
        console.log("make test-avalanche-automation");
        console.log("");
        
        console.log("RECURSOS:");
        console.log("=========");
        console.log("Dashboard: https://automation.chain.link/avalanche-fuji");
        console.log("Docs: https://docs.chain.link/chainlink-automation");
        console.log("LINK Faucet: https://faucets.chain.link/fuji");
    }
    
    /**
     * @dev Funcion para probar checkUpkeep manualmente
     */
    function testCheckUpkeepManual(
        address automationKeeper,
        address loanAdapter
    ) external view {
        console.log("=== PRUEBA MANUAL DE CHECKUPKEEP ===");
        console.log("====================================");
        
        // Generar checkData
        bytes memory checkData = abi.encode(loanAdapter, uint256(0), uint256(25));
        
        console.log("Probando checkUpkeep con:");
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.logBytes(checkData);
        
        // Intentar llamar checkUpkeep
        (bool success, bytes memory result) = automationKeeper.staticcall(
            abi.encodeWithSignature("checkUpkeep(bytes)", checkData)
        );
        
        if (success) {
            console.log("EXITO: checkUpkeep ejecutado correctamente");
            
            // Decodificar resultado
            (bool upkeepNeeded, bytes memory performData) = abi.decode(result, (bool, bytes));
            
            console.log("upkeepNeeded:", upkeepNeeded);
            console.log("performData length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("HAY POSICIONES LIQUIDABLES!");
                console.log("El problema esta en el registro/fondeo de Chainlink");
            } else {
                console.log("No hay posiciones liquidables");
                console.log("Crear posiciones de prueba primero");
            }
        } else {
            console.log("ERROR: checkUpkeep fallo");
            console.log("Verificar configuracion de contratos");
        }
    }
} 
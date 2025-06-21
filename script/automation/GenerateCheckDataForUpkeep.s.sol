// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title GenerateCheckDataForUpkeep
 * @notice Genera el checkData correcto para tu upkeep registrado y verifica el estado
 */
contract GenerateCheckDataForUpkeep is Script {
    
    // Direcciones desde tus logs de deployment
    address constant AUTOMATION_KEEPER = 0x15C7298Dd649DcDc17D281cB0dAE84E945573c93;
    address constant LOAN_ADAPTER = 0x6A444D8e037672535879AEF7C668D6d5D15B84d7;
    address constant FLEXIBLE_LOAN_MANAGER = 0xc8Bf18B4D6B459b17b9298D5Ed6B2feC1f0D9b3D;
    
    // Tu upkeep ID registrado
    uint256 constant UPKEEP_ID = 35283090123137439879057452590905787868464269668261475719855807879502576065354;
    
    function run() external {
        console.log("=== GENERANDO CHECKDATA PARA UPKEEP REGISTRADO ===");
        console.log("Upkeep ID:", UPKEEP_ID);
        console.log("AutomationKeeper:", AUTOMATION_KEEPER);
        console.log("LoanManager:", FLEXIBLE_LOAN_MANAGER);
        console.log("");
        
        // Instanciar contratos
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(AUTOMATION_KEEPER);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(LOAN_ADAPTER);
        ILoanManager loanManager = ILoanManager(FLEXIBLE_LOAN_MANAGER);
        
        // 1. Verificar configuracion del sistema
        console.log("PASO 1: Verificando configuracion del sistema...");
        _verifySystemConfiguration(keeper, adapter, loanManager);
        
        // 2. Generar checkData optimizado
        console.log("PASO 2: Generando checkData...");
        bytes memory checkData = _generateOptimalCheckData(keeper);
        
        // 3. Probar checkUpkeep localmente
        console.log("PASO 3: Probando checkUpkeep localmente...");
        _testCheckUpkeep(keeper, checkData);
        
        // 4. Mostrar informacion final
        console.log("PASO 4: Informacion final para actualizar upkeep...");
        _displayFinalInfo(checkData);
    }
    
    function _verifySystemConfiguration(
        LoanAutomationKeeperOptimized keeper,
        LoanManagerAutomationAdapter adapter,
        ILoanManager loanManager
    ) internal view {
        
        // Verificar si loan manager esta registrado en keeper
        (address[] memory managers, uint256[] memory priorities) = keeper.getRegisteredManagers();
        bool isRegistered = false;
        for (uint256 i = 0; i < managers.length; i++) {
            if (managers[i] == FLEXIBLE_LOAN_MANAGER) {
                isRegistered = true;
                console.log("OK: LoanManager registrado en keeper con prioridad:", priorities[i]);
                break;
            }
        }
        
        if (!isRegistered) {
            console.log("ERROR: LoanManager NO registrado en keeper");
            return;
        }
        
        // Verificar configuracion del adapter
        console.log("Automation habilitada en adapter:", adapter.isAutomationEnabled());
        console.log("Contrato de automation autorizado:", adapter.authorizedAutomationContract());
        
        // Verificar posiciones activas
        uint256 totalPositions = adapter.getTotalActivePositions();
        console.log("Total posiciones activas:", totalPositions);
        
        // Verificar estado del keeper
        console.log("Emergency pause:", keeper.emergencyPause());
        console.log("Min risk threshold:", keeper.minRiskThreshold());
        console.log("Max positions per batch:", keeper.maxPositionsPerBatch());
        
        // Estadisticas
        (
            uint256 totalLiquidations,
            uint256 totalUpkeeps,
            uint256 lastExecution,
            uint256 avgGas,
            uint256 registeredCount
        ) = keeper.getStats();
        
        console.log("Estadisticas del keeper:");
        console.log("  - Total liquidaciones:", totalLiquidations);
        console.log("  - Total upkeeps:", totalUpkeeps);
        console.log("  - Ultima ejecucion:", lastExecution);
        console.log("  - Gas promedio:", avgGas);
        console.log("  - Managers registrados:", registeredCount);
        console.log("");
    }
    
    function _generateOptimalCheckData(LoanAutomationKeeperOptimized keeper) 
        internal view returns (bytes memory checkData) {
        
        // Generar checkData optimizado
        // Parametros: (loanManager, startPositionId, batchSize)
        // startPositionId = 0 (se convertira a 1 automaticamente)
        // batchSize = 0 (usara valor por defecto de 25)
        
        checkData = keeper.generateOptimizedCheckData(
            FLEXIBLE_LOAN_MANAGER,  // loanManager
            0,                      // startPositionId (auto-start desde 1)
            0                       // batchSize (usa default 25)
        );
        
        console.log("CheckData generado:");
        console.logBytes(checkData);
        
        // Convertir a hex string para la interfaz web
        string memory hexCheckData = _bytesToHexString(checkData);
        console.log("CheckData en hex para la interfaz web:");
        console.log(hexCheckData);
        console.log("");
        
        return checkData;
    }
    
    function _testCheckUpkeep(LoanAutomationKeeperOptimized keeper, bytes memory checkData) 
        internal view {
        
        console.log("Probando checkUpkeep con el checkData generado...");
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("SUCCESS: checkUpkeep ejecutado exitosamente");
            console.log("Upkeep needed:", upkeepNeeded);
            console.log("PerformData length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("UPKEEP NEEDED! El sistema detecto posiciones que necesitan liquidacion");
            } else {
                console.log("INFO: No upkeep needed - no hay posiciones en riesgo actualmente");
            }
            
        } catch Error(string memory reason) {
            console.log("ERROR: checkUpkeep fallo:");
            console.log("Razon:", reason);
            
        } catch (bytes memory) {
            console.log("ERROR: checkUpkeep fallo con error desconocido");
        }
        
        console.log("");
    }
    
    function _displayFinalInfo(bytes memory checkData) internal view {
        string memory hexCheckData = _bytesToHexString(checkData);
        
        console.log("=== INFORMACION PARA ACTUALIZAR TU UPKEEP ===");
        console.log("");
        console.log("URL de Chainlink Automation:");
        console.log("https://automation.chain.link/base-sepolia");
        console.log("");
        console.log("Tu Upkeep ID:");
        console.log(vm.toString(UPKEEP_ID));
        console.log("");
        console.log("CheckData para pegar en la interfaz web:");
        console.log(hexCheckData);
        console.log("");
        console.log("Instrucciones:");
        console.log("1. Ve a https://automation.chain.link/base-sepolia");
        console.log("2. Busca tu upkeep ID:", vm.toString(UPKEEP_ID));
        console.log("3. Haz click en 'Edit' en tu upkeep");
        console.log("4. En el campo 'Check data', pega:");
        console.log("   ", hexCheckData);
        console.log("5. Guarda los cambios");
        console.log("");
        console.log("Que hace este checkData:");
        console.log("- Monitorea el FlexibleLoanManager en:", FLEXIBLE_LOAN_MANAGER);
        console.log("- Comienza desde la posicion ID 1");
        console.log("- Revisa hasta 25 posiciones por batch");
        console.log("- Ejecuta liquidaciones cuando detecta riesgo >= 85%");
        console.log("");
        console.log("Frecuencia de monitoreo:");
        console.log("- Chainlink revisara cada ~1 minuto");
        console.log("- Solo ejecutara si hay posiciones liquidables");
        console.log("- Consumira LINK solo cuando ejecute liquidaciones");
        console.log("");
        console.log("Monitoreo de LINK:");
        console.log("- El saldo se reduce solo cuando performUpkeep se ejecuta");
        console.log("- Puedes ver las ejecuciones en el dashboard");
        console.log("- Cada ejecucion aparecera en el historial");
    }
    
    function _bytesToHexString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
} 
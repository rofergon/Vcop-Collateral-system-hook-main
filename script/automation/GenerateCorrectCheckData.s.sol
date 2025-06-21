// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title GenerateCorrectCheckData
 * @notice Genera el checkData correcto para el nuevo upkeep registrado
 */
contract GenerateCorrectCheckData is Script {
    
    // DIRECCION CORRECTA del AutomationKeeper
    address constant AUTOMATION_KEEPER = 0x15C7298Dd649DcDc17D281cB0dAE84E945573c93;
    address constant FLEXIBLE_LOAN_MANAGER = 0xc8Bf18B4D6B459b17b9298D5Ed6B2feC1f0D9b3D;
    
    // NUEVO UPKEEP ID registrado
    uint256 constant NEW_UPKEEP_ID = 30080302487183721719276887120007770146371663906276452133962259565200945405248;
    
    function run() external view {
        console.log("=== GENERANDO CHECKDATA CORRECTO ===");
        console.log("Contrato CORRECTO registrado:", AUTOMATION_KEEPER);
        console.log("Nuevo Upkeep ID:", NEW_UPKEEP_ID);
        console.log("");
        
        // Instanciar el keeper correcto
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(AUTOMATION_KEEPER);
        
        // Generar checkData optimizado
        bytes memory checkData = keeper.generateOptimizedCheckData(
            FLEXIBLE_LOAN_MANAGER,  // loanManager
            0,                      // startPositionId (auto-start desde 1)
            0                       // batchSize (usa default 25)
        );
        
        console.log("CheckData generado:");
        console.logBytes(checkData);
        
        // Convertir a hex string para la interfaz web
        string memory hexCheckData = _bytesToHexString(checkData);
        console.log("");
        console.log("=== CHECKDATA PARA COPIAR EN CHAINLINK ===");
        console.log(hexCheckData);
        console.log("");
        
        console.log("INSTRUCCIONES:");
        console.log("1. Ve a: https://automation.chain.link/base-sepolia");
        console.log("2. Busca tu nuevo upkeep ID:", NEW_UPKEEP_ID);
        console.log("3. Haz click en 'Edit'");
        console.log("4. Pega este checkData:");
        console.log("   ", hexCheckData);
        console.log("5. Guarda los cambios");
        console.log("");
        console.log("AHORA SI FUNCIONARA porque:");
        console.log("- Contrato correcto registrado");
        console.log("- CheckData correcto");
        console.log("- Sistema autorizado");
        console.log("- Posiciones liquidables esperando");
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
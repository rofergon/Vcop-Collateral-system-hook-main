// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title GenerateCorrectAvalancheCheckData
 * @notice Genera el checkData CORRECTO para Avalanche Fuji
 * @dev Apunta al FlexibleLoanManager, no al LoanAdapter
 */
contract GenerateCorrectAvalancheCheckData is Script {
    
    function run() external view {
        console.log("=== CORRECTED AVALANCHE FUJI CHECKDATA ===");
        console.log("");
        
        // Load deployed addresses from JSON
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        
        console.log("DEPLOYED ADDRESSES:");
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("");
        
        console.log("PROBLEMA DETECTADO:");
        console.log("El checkData anterior apuntaba al LoanAdapter");
        console.log("Pero el Keeper solo tiene registrado el FlexibleLoanManager");
        console.log("");
        
        // FIXED: Generate checkData pointing to FlexibleLoanManager
        bytes memory correctCheckData = abi.encode(
            flexibleLoanManager,  // CORRECTO: FlexibleLoanManager
            uint256(0),           // startIndex (0 = auto-start from position 1)
            uint256(25)           // batchSize
        );
        
        console.log("CHECKDATA CORRECTO:");
        console.log("======================");
        console.log("");
        console.log("Target Contract (debe ser el Keeper):");
        console.log("   ", automationKeeper);
        console.log("");
        
        console.log("CheckData (apunta a FlexibleLoanManager):");
        console.logBytes(correctCheckData);
        console.log("");
        
        // Convert to clean hex string
        string memory hexString = _bytesToHex(correctCheckData);
        console.log("CheckData (HEX para Chainlink):");
        console.log("   ", hexString);
        console.log("");
        
        console.log("PASOS PARA CORREGIR:");
        console.log("====================");
        console.log("1. Ve a tu upkeep en: https://automation.chain.link/avalanche-fuji");
        console.log("2. Haz clic en 'Edit' o 'Update Upkeep'");
        console.log("3. Cambia el Check Data por el HEX de arriba");
        console.log("4. Guarda los cambios");
        console.log("");
        
        console.log("VERIFICACION:");
        console.log("=============");
        console.log("El nuevo checkData debe decodificar a:");
        console.log("  loanManager:", flexibleLoanManager);
        console.log("  startIndex: 0");
        console.log("  batchSize: 25");
        console.log("");
        
        console.log("Una vez corregido, el performUpkeep deberia ejecutarse!");
    }
    
    function _bytesToHex(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[2 + i * 2 + 1] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";

/**
 * @title CheckVaultContract
 * @notice Verifica si el contrato VaultBasedHandler existe y funciona
 */
contract CheckVaultContract is Script {
    
    function run() external view {
        console.log("=== CHECKING VAULT CONTRACT ===");
        console.log("");
        
        // Cargar direcciones desde el archivo JSON
        (address vaultHandler, address automationKeeper) = loadAddresses();
        
        console.log("VaultBasedHandler:", vaultHandler);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("");
        
        // Check if contract exists
        uint256 codeSize;
        address contractAddr = vaultHandler;
        assembly {
            codeSize := extcodesize(contractAddr)
        }
        
        console.log("Contract code size:", codeSize);
        
        if (codeSize == 0) {
            console.log("ERROR: VaultBasedHandler contract not found!");
            console.log("The address may be incorrect or contract not deployed");
            return;
        }
        
        console.log("Contract exists! Testing functions...");
        console.log("");
        
        // Test owner function
        (bool success1, bytes memory data1) = vaultHandler.staticcall(
            abi.encodeWithSignature("owner()")
        );
        
        if (success1 && data1.length >= 32) {
            address owner = abi.decode(data1, (address));
            console.log("Contract owner:", owner);
        } else {
            console.log("Could not get contract owner");
        }
        
        // Test authorization mapping with try-catch approach
        console.log("Testing authorization mapping...");
        
        // Try different function signatures
        _testAuthorization("authorizedAutomationContracts(address)", vaultHandler, automationKeeper);
        _testAuthorization("authorizedAutomationContract()", vaultHandler, automationKeeper);
        _testAuthorization("isAuthorized(address)", vaultHandler, automationKeeper);
        
        console.log("");
        console.log("DIAGNOSIS:");
        console.log("- Contract exists at the given address");
        console.log("- Need to find correct authorization function");
        console.log("- May need to authorize keeper with different method");
    }
    
    /**
     * @notice Carga las direcciones dinámicamente desde el archivo JSON
     */
    function loadAddresses() internal view returns (address vaultHandler, address automationKeeper) {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        // Cargar VaultBasedHandler
        vaultHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        
        // Para AutomationKeeper, intentamos desde el archivo JSON, si no existe usamos la dirección por defecto
        try vm.parseJsonAddress(json, ".automation.automationKeeper") returns (address keeper) {
            automationKeeper = keeper;
        } catch {
            // Si no está en el JSON, usar la dirección conocida (temporal)
            automationKeeper = 0x15C7298Dd649DcDc17D281cB0dAE84E945573c93;
        }
        
        // Validar que las direcciones no sean cero
        require(vaultHandler != address(0), "VaultBasedHandler address is zero");
        require(automationKeeper != address(0), "AutomationKeeper address is zero");
    }
    
    function _testAuthorization(string memory signature, address vaultHandler, address automationKeeper) internal view {
        console.log("Testing:", signature);
        
        if (keccak256(bytes(signature)) == keccak256("authorizedAutomationContracts(address)")) {
            (bool success, bytes memory data) = vaultHandler.staticcall(
                abi.encodeWithSignature(signature, automationKeeper)
            );
            
            if (success && data.length >= 32) {
                bool isAuthorized = abi.decode(data, (bool));
                console.log("SUCCESS - Authorized:", isAuthorized);
            } else {
                console.log("FAILED - Function not found or error");
            }
        } else {
            (bool success, ) = vaultHandler.staticcall(
                abi.encodeWithSignature(signature)
            );
            
            if (success) {
                console.log("SUCCESS - Function exists");
            } else {
                console.log("FAILED - Function not found");
            }
        }
    }
} 
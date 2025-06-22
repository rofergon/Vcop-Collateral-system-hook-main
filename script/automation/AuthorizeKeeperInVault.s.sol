// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";

/**
 * @title AuthorizeKeeperInVault
 * @notice Autoriza el AutomationKeeper en el VaultBasedHandler
 */
contract AuthorizeKeeperInVault is Script {
    
    // Direcciones que serán cargadas dinámicamente
    address public vaultHandler;
    address public automationKeeper;
    
    function run() external {
        console.log("=== AUTHORIZING AUTOMATION KEEPER IN VAULT ===");
        console.log("");
        
        // Cargar direcciones desde el archivo JSON
        loadAddresses();
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        VaultBasedHandler vault = VaultBasedHandler(vaultHandler);
        
        console.log("VaultBasedHandler:", vaultHandler);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("");
        
        // Check current authorization
        bool wasAuthorized = vault.authorizedAutomationContracts(automationKeeper);
        console.log("Current authorization status:", wasAuthorized);
        
        if (wasAuthorized) {
            console.log("AutomationKeeper already authorized!");
        } else {
            console.log("Authorizing AutomationKeeper...");
            
            // Authorize the automation keeper
            vault.authorizeAutomationContract(automationKeeper);
            
            console.log("SUCCESS: AutomationKeeper authorized!");
        }
        
        // Verify authorization
        bool isNowAuthorized = vault.authorizedAutomationContracts(automationKeeper);
        console.log("New authorization status:", isNowAuthorized);
        
        if (isNowAuthorized) {
            console.log("");
            console.log("AUTHORIZATION COMPLETE!");
            console.log("AutomationKeeper can now use vault funds for liquidations");
            console.log("");
            console.log("NEXT STEPS:");
            console.log("1. Test Chainlink Automation again");
            console.log("2. Check if liquidations now work");
            console.log("3. Monitor upkeep performance");
        } else {
            console.log("ERROR: Authorization failed!");
        }
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Carga las direcciones dinámicamente desde el archivo JSON
     */
    function loadAddresses() internal {
        console.log("Loading addresses from deployed-addresses-mock.json...");
        
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        // Cargar VaultBasedHandler
        vaultHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        console.log("Loaded VaultBasedHandler:", vaultHandler);
        
        // Para AutomationKeeper, intentamos desde el archivo JSON, si no existe usamos la dirección por defecto
        try vm.parseJsonAddress(json, ".automation.automationKeeper") returns (address keeper) {
            automationKeeper = keeper;
            console.log("Loaded AutomationKeeper from JSON:", automationKeeper);
        } catch {
            // Si no está en el JSON, usar la dirección conocida (temporal)
            automationKeeper = 0x15C7298Dd649DcDc17D281cB0dAE84E945573c93;
            console.log("Using fallback AutomationKeeper:", automationKeeper);
        }
        
        // Validar que las direcciones no sean cero
        require(vaultHandler != address(0), "VaultBasedHandler address is zero");
        require(automationKeeper != address(0), "AutomationKeeper address is zero");
        
        console.log("Address loading completed successfully!");
        console.log("");
    }
} 
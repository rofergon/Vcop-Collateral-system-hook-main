// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title ConfigureVaultAutomation
 * @notice Configures vault-funded liquidation system automatically after deployment
 */
contract ConfigureVaultAutomation is Script {
    
    // Addresses loaded from deployed-addresses-mock.json
    address public flexibleLoanManager;
    address public vaultBasedHandler;
    address public automationKeeper;
    
    function run() external {
        console.log("=== CONFIGURING VAULT-FUNDED LIQUIDATION SYSTEM ===");
        
        loadAddresses();
        configureVaultAutomation();
        
        console.log("=== VAULT-FUNDED LIQUIDATION CONFIGURATION COMPLETED ===");
    }
    
    function loadAddresses() internal {
        console.log("\nStep 1: Loading deployed addresses...");
        
        // Read addresses from deployed-addresses-mock.json
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("AutomationKeeper:", automationKeeper);
        
        // Validate addresses
        require(flexibleLoanManager != address(0), "FlexibleLoanManager address is zero");
        require(vaultBasedHandler != address(0), "VaultBasedHandler address is zero");
        require(automationKeeper != address(0), "AutomationKeeper address is zero");
    }
    
    function configureVaultAutomation() internal {
        console.log("\nStep 2: Configuring vault-funded liquidation...");
        
        vm.startBroadcast();
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        // 1. Authorize FlexibleLoanManager to use vault liquidity 
        console.log("Authorizing FlexibleLoanManager in vault...");
        vault.authorizeAutomationContract(flexibleLoanManager);
        
        // 2. Authorize deployer in FlexibleLoanManager for testing
        console.log("Authorizing deployer in FlexibleLoanManager...");
        (bool success,) = flexibleLoanManager.call(
            abi.encodeWithSignature("setAutomationContract(address)", msg.sender)
        );
        require(success, "Failed to set automation contract");
        
        // 3. Enable automation
        console.log("Enabling automation...");
        (success,) = flexibleLoanManager.call(
            abi.encodeWithSignature("setAutomationEnabled(bool)", true)
        );
        require(success, "Failed to enable automation");
        
        vm.stopBroadcast();
        
        console.log("Configuration completed successfully!");
        console.log("- FlexibleLoanManager authorized in VaultBasedHandler");
        console.log("- Deployer authorized in FlexibleLoanManager for testing");
        console.log("- Automation enabled");
    }
} 
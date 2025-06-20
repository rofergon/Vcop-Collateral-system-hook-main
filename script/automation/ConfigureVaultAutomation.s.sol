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
        
        // Using the latest deployed addresses from deployment
        flexibleLoanManager = 0x3AA0D317F4b7d0b36344A7B6C72d09e1d61d6601;
        vaultBasedHandler = 0xbC36d8283EEBcEe76Fc7f83c4FCee5084fceaf40;
        automationKeeper = 0xfB20bf1c7566883E2baA98B3160B4db8633d339D;
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("AutomationKeeper:", automationKeeper);
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
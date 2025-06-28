// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";

/**
 * @title CheckVaultAuthorizations
 * @notice Verifica si el automation keeper está autorizado en VaultBasedHandler
 */
contract CheckVaultAuthorizations is Script {
    
    function run() external view {
        console.log("=== CHECKING VAULT AUTHORIZATION STATUS ===");
        console.log("");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        console.log("Contract Addresses:");
        console.log("  VaultBasedHandler:", vaultBasedHandler);
        console.log("  AutomationKeeper:", automationKeeper);
        console.log("  LoanAdapter:", loanAdapter);
        console.log("");
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        // Check authorization status
        console.log("AUTHORIZATION STATUS:");
        console.log("====================");
        
        bool keeperAuthorized = vault.authorizedAutomationContracts(automationKeeper);
        bool adapterAuthorized = vault.authorizedAutomationContracts(loanAdapter);
        
        console.log("AutomationKeeper authorized:", keeperAuthorized);
        console.log("LoanAdapter authorized:", adapterAuthorized);
        console.log("");
        
        if (!keeperAuthorized && !adapterAuthorized) {
            console.log("[ERROR] PROBLEM IDENTIFIED:");
            console.log("   Neither AutomationKeeper nor LoanAdapter is authorized!");
            console.log("   This prevents vault-based liquidations from working.");
            console.log("");
            console.log("SOLUTION:");
            console.log("   Run: make authorize-automation-vault");
            console.log("   Or manually authorize the contracts:");
            console.log("   1. vault.authorizeAutomationContract(automationKeeper)");
            console.log("   2. vault.authorizeAutomationContract(loanAdapter)");
        } else {
            console.log("[SUCCESS] STATUS:");
            if (keeperAuthorized) {
                console.log("   AutomationKeeper is properly authorized");
            }
            if (adapterAuthorized) {
                console.log("   LoanAdapter is properly authorized");
            }
        }
        
        console.log("");
        
        // Check automation liquidity status for ETH
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        console.log("ETH AUTOMATION LIQUIDITY STATUS:");
        console.log("===============================");
        
        try vault.getAutomationLiquidityStatus(mockETH) returns (
            uint256 availableForAutomation,
            uint256 totalAutomationLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("Available for automation:", availableForAutomation / 1e18, "ETH");
            console.log("Total automation liquidations:", totalAutomationLiquidations);
            console.log("Total recovered:", totalRecovered / 1e18, "ETH");
            console.log("Can liquidate:", canLiquidate);
            
            if (!canLiquidate) {
                console.log("[ERROR] Cannot liquidate - insufficient vault liquidity or asset inactive");
            } else if (availableForAutomation == 0) {
                console.log("[WARNING] No liquidity available for automation liquidations");
            } else {
                console.log("[SUCCESS] Vault has liquidity for automation liquidations");
            }
        } catch {
            console.log("[ERROR] Error getting automation liquidity status");
        }
        
        console.log("");
        console.log("=== VAULT AUTHORIZATION CHECK COMPLETED ===");
    }
} 
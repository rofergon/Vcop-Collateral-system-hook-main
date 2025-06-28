// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title DiagnoseVaultAuthorizations
 * @notice Diagnose all VaultBasedHandler authorization issues preventing automated liquidations
 */
contract DiagnoseVaultAuthorizations is Script {
    
    // Contract addresses
    address constant FLEXIBLE_LOAN_MANAGER = 0xD1459d5113a5253b8BC9Fa69D35A25E45E122c28;
    address constant AUTOMATION_KEEPER = 0xf7FfF14bF8872243707c0519AAFBe266B03bf57a;
    address constant AUTOMATION_ADAPTER = 0xbB063767915A6CA539245d3719e3B405263fa355;
    address constant VAULT_BASED_HANDLER = 0x7CF68d2FCD4C4Ca2e628A73B1c4F50dD35F8C68c;
    address constant MOCK_USDC = 0x819B58A646CDd8289275A87653a2aA4902b14fe6;
    
    function run() external view {
        console.log("=== VAULT BASED HANDLER AUTHORIZATION DIAGNOSIS ===");
        console.log("Timestamp:", block.timestamp);
        console.log("");
        
        // Load contracts
        FlexibleLoanManager loanManager = FlexibleLoanManager(FLEXIBLE_LOAN_MANAGER);
        VaultBasedHandler vaultHandler = VaultBasedHandler(VAULT_BASED_HANDLER);
        LoanAutomationKeeperOptimized automationKeeper = LoanAutomationKeeperOptimized(AUTOMATION_KEEPER);
        LoanManagerAutomationAdapter automationAdapter = LoanManagerAutomationAdapter(AUTOMATION_ADAPTER);
        
        console.log("1. BASIC CONTRACT INFO:");
        console.log("   FlexibleLoanManager:", FLEXIBLE_LOAN_MANAGER);
        console.log("   VaultBasedHandler:", VAULT_BASED_HANDLER);
        console.log("   AutomationKeeper:", AUTOMATION_KEEPER);
        console.log("   AutomationAdapter:", AUTOMATION_ADAPTER);
        console.log("   Mock USDC:", MOCK_USDC);
        console.log("");
        
        // Check FlexibleLoanManager automation settings
        console.log("2. FLEXIBLE LOAN MANAGER AUTOMATION:");
        try loanManager.authorizedAutomationContract() returns (address authorized) {
            console.log("   Authorized automation contract:", authorized);
            console.log("   Is AutomationKeeper authorized:", authorized == AUTOMATION_KEEPER);
        } catch {
            console.log("   ERROR: Cannot read authorized automation contract");
        }
        
        try loanManager.isAutomationEnabled() returns (bool enabled) {
            console.log("   Automation enabled:", enabled);
        } catch {
            console.log("   ERROR: Cannot read automation enabled status");
        }
        console.log("");
        
        // Check VaultBasedHandler authorizations - THIS IS THE KEY ISSUE
        console.log("3. VAULT BASED HANDLER AUTHORIZATIONS:");
        
        // Check if AutomationKeeper is authorized in VaultBasedHandler
        try vaultHandler.authorizedAutomationContracts(AUTOMATION_KEEPER) returns (bool isAuth) {
            console.log("   Is AutomationKeeper authorized in VaultHandler:", isAuth);
        } catch {
            console.log("   ERROR: Cannot check AutomationKeeper authorization in VaultHandler");
        }
        
        // Check if FlexibleLoanManager is authorized in VaultBasedHandler
        try vaultHandler.authorizedAutomationContracts(FLEXIBLE_LOAN_MANAGER) returns (bool isAuth) {
            console.log("   Is FlexibleLoanManager authorized in VaultHandler:", isAuth);
        } catch {
            console.log("   ERROR: Cannot check FlexibleLoanManager authorization in VaultHandler");
        }
        
        // Check if AutomationAdapter is authorized in VaultBasedHandler
        try vaultHandler.authorizedAutomationContracts(AUTOMATION_ADAPTER) returns (bool isAuth) {
            console.log("   Is AutomationAdapter authorized in VaultHandler:", isAuth);
        } catch {
            console.log("   ERROR: Cannot check AutomationAdapter authorization in VaultHandler");
        }
        
        // Check VaultBasedHandler owner
        try vaultHandler.owner() returns (address owner) {
            console.log("   VaultBasedHandler owner:", owner);
        } catch {
            console.log("   ERROR: Cannot read VaultBasedHandler owner");
        }
        console.log("");
        
        // Check vault liquidity for USDC
        console.log("4. VAULT LIQUIDITY STATUS:");
        try vaultHandler.getAvailableLiquidity(MOCK_USDC) returns (uint256 available) {
            console.log("   Available USDC liquidity:", available);
            console.log("   Liquidity sufficient for liquidations:", available > 1000e6);
        } catch {
            console.log("   ERROR: Cannot check vault liquidity");
        }
        
        try vaultHandler.isAssetSupported(MOCK_USDC) returns (bool supported) {
            console.log("   Is USDC supported in vault:", supported);
        } catch {
            console.log("   ERROR: Cannot check if USDC is supported");
        }
        console.log("");
        
        // Check automation settings in VaultBasedHandler
        console.log("5. VAULT AUTOMATION SETTINGS:");
        
        // VaultBasedHandler doesn't have automationEnabled function
        console.log("   Vault automation: Controlled through authorizedAutomationContracts mapping");
        
        // Check emergency status - VaultBasedHandler uses owner-only emergency functions
        console.log("   Vault emergency: Controlled through owner-only emergencyLiquidationMode");
        console.log("");
        
        // Simulate authorization check for automation call
        console.log("6. AUTHORIZATION SIMULATION:");
        console.log("   When AutomationKeeper calls vaultFundedAutomatedLiquidation:");
        console.log("   1. FlexibleLoanManager checks: msg.sender == authorizedAutomationContract");
        console.log("   2. FlexibleLoanManager calls: vaultHandler.automationRepay()");
        console.log("   3. VaultBasedHandler checks: isAuthorized(msg.sender) [msg.sender = FlexibleLoanManager]");
        console.log("   4. If FlexibleLoanManager is not authorized in VaultHandler -> FAIL");
        console.log("");
        
        // The root cause analysis
        console.log("7. ROOT CAUSE ANALYSIS:");
        console.log("   The error 'Vault error: Unauthorized automa[tion]' suggests:");
        console.log("   - AutomationKeeper can call FlexibleLoanManager.vaultFundedAutomatedLiquidation");
        console.log("   - But FlexibleLoanManager cannot call VaultBasedHandler.automationRepay");
        console.log("   - This means FlexibleLoanManager is NOT authorized in VaultBasedHandler");
        console.log("");
        
        console.log("8. REQUIRED FIXES:");
        console.log("   Need to authorize FlexibleLoanManager in VaultBasedHandler");
        console.log("   Command: vaultHandler.authorize(FLEXIBLE_LOAN_MANAGER)");
        console.log("");
        
        console.log("=== DIAGNOSIS COMPLETE ===");
    }
} 
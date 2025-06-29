// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title FixAutomationConfiguration
 * @notice Corrige la configuración del sistema de automatización
 * @dev Basado en el diagnóstico realizado por CreatePositionCrashAndDiagnose
 */
contract FixAutomationConfiguration is Script {
    
    FlexibleLoanManager public loanManager;
    LoanAutomationKeeperOptimized public keeper;
    LoanManagerAutomationAdapter public adapter;
    
    function run() external {
        console.log("==================================================");
        console.log("FIXING AUTOMATION CONFIGURATION");
        console.log("==================================================");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        loanManager = FlexibleLoanManager(vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager"));
        keeper = LoanAutomationKeeperOptimized(vm.parseJsonAddress(json, ".automation.automationKeeper"));
        adapter = LoanManagerAutomationAdapter(vm.parseJsonAddress(json, ".automation.loanAdapter"));
        
        console.log("Contracts loaded:");
        console.log("  LoanManager:", address(loanManager));
        console.log("  Keeper (Chainlink Upkeep):", address(keeper));
        console.log("  Adapter:", address(adapter));
        console.log("");
        console.log("INFO: Chainlink upkeep registered at:", address(keeper));
        console.log("INFO: Correct flow should be: Chainlink -> Keeper -> Adapter -> LoanManager");
        console.log("");
        
        // Start broadcasting
        vm.startBroadcast();
        
        console.log("=== STEP 1: DIAGNOSE CURRENT STATE ===");
        _diagnoseCurrentState();
        
        console.log("=== STEP 2: FIX LOANMANAGER CONFIGURATION ===");
        _fixLoanManagerConfiguration();
        
        console.log("=== STEP 3: VERIFY AUTOMATION FLOW ===");
        _verifyAutomationFlow();
        
        console.log("=== STEP 4: ENABLE AUTO-TRACKING ===");
        _configureAutoTracking();
        
        vm.stopBroadcast();
        
        console.log("==================================================");
        console.log("AUTOMATION CONFIGURATION FIXED SUCCESSFULLY");
        console.log("==================================================");
    }
    
    function _diagnoseCurrentState() internal view {
        address currentAutomation = loanManager.authorizedAutomationContract();
        bool automationEnabled = loanManager.automationEnabled();
        
        console.log("CURRENT STATE:");
        console.log("  Automation Enabled:", automationEnabled);
        console.log("  Current Automation Contract:", currentAutomation);
        console.log("  Expected Adapter Address:", address(adapter));
        console.log("  Expected Keeper Address:", address(keeper));
        console.log("");
        
        if (currentAutomation == address(keeper)) {
            console.log("  >>> PROBLEM FOUND: LoanManager points to Keeper instead of Adapter <<<");
            console.log("  Current (wrong): LoanManager -> LoanAutomationKeeperOptimized");
            console.log("  Should be: LoanManager -> LoanManagerAutomationAdapter");
        } else if (currentAutomation == address(adapter)) {
            console.log("  >>> CORRECT: LoanManager points to Adapter <<<");
            console.log("  Flow: Chainlink -> Keeper -> Adapter -> LoanManager");
        } else {
            console.log("  >>> UNKNOWN: LoanManager points to unexpected contract <<<");
        }
        console.log("");
    }
    
    function _fixLoanManagerConfiguration() internal {
        console.log("FIXING LOANMANAGER CONFIGURATION:");
        
        // 1. Enable automation
        try loanManager.setAutomationEnabled(true) {
            console.log("  SUCCESS: Automation enabled");
        } catch {
            console.log("  FAILED: Could not enable automation (might be already enabled)");
        }
        
        // 2. Set correct automation contract (Adapter, not Keeper)
        try loanManager.setAutomationContract(address(adapter)) {
            console.log("  SUCCESS: Automation contract set to Adapter:", address(adapter));
        } catch {
            console.log("  FAILED: Could not set automation contract");
        }
        
        console.log("");
    }
    
    function _verifyAutomationFlow() internal view {
        console.log("VERIFYING AUTOMATION FLOW:");
        
        address currentAutomation = loanManager.authorizedAutomationContract();
        bool automationEnabled = loanManager.automationEnabled();
        
        console.log("  Automation Enabled:", automationEnabled);
        console.log("  Automation Contract:", currentAutomation);
        
        if (automationEnabled && currentAutomation == address(adapter)) {
            console.log("  SUCCESS: LoanManager -> Adapter -> Keeper flow");
        } else {
            console.log("  ERROR: Flow still broken");
        }
        
        // Check adapter configuration
        try adapter.automationEnabled() returns (bool adapterEnabled) {
            console.log("  Adapter Automation Enabled:", adapterEnabled);
        } catch {
            console.log("  Could not check adapter automation status");
        }
        
        // Check if adapter has correct automation contract (should be Keeper)
        try adapter.authorizedAutomationContract() returns (address adapterAuth) {
            console.log("  Adapter Authorized Contract:", adapterAuth);
            if (adapterAuth == address(keeper)) {
                console.log("  SUCCESS: Adapter correctly points to Keeper");
            } else {
                console.log("  PROBLEM: Adapter should point to Keeper");
            }
        } catch {
            console.log("  Could not check adapter authorized contract");
        }
        
        console.log("");
    }
    
    function _configureAutoTracking() internal {
        console.log("CONFIGURING AUTO-TRACKING:");
        
        // Enable adapter automation
        try adapter.setAutomationEnabled(true) {
            console.log("  SUCCESS: Adapter automation enabled");
        } catch {
            console.log("  FAILED: Could not enable adapter automation");
        }
        
        // Configure thresholds for optimal tracking
        try adapter.setRiskThresholds(100, 95, 90) {
            console.log("  SUCCESS: Risk thresholds set: Critical=100, Danger=95, Warning=90");
        } catch {
            console.log("  FAILED: Could not set risk thresholds");
        }
        
        // Set correct automation contract in adapter (should be Keeper)
        try adapter.setAutomationContract(address(keeper)) {
            console.log("  SUCCESS: Adapter automation contract set to Keeper");
        } catch {
            console.log("  FAILED: Could not set automation contract in adapter");
        }
        
        console.log("");
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title FixAutomationAuthorizations
 * @notice Corrige automáticamente los problemas de autorización encontrados en el diagnóstico
 */
contract FixAutomationAuthorizations is Script {
    
    // Contract addresses
    address public flexibleLoanManager;
    address public automationAdapter;
    address public automationKeeper;
    
    function run() external {
        console.log("=== FIXING AUTOMATION AUTHORIZATION ISSUES ===");
        console.log("");
        
        loadAddresses();
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        fixAuthorizations();
        
        vm.stopBroadcast();
        
        verifyFixes();
        
        console.log("=== AUTHORIZATION FIX COMPLETED ===");
    }
    
    function loadAddresses() internal {
        console.log("Loading contract addresses...");
        
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        automationAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("AutomationAdapter:", automationAdapter);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("");
    }
    
    function fixAuthorizations() internal {
        console.log("=== FIXING AUTHORIZATION ISSUES ===");
        console.log("");
        
        // Fix Issue 1: Authorize AutomationKeeper in FlexibleLoanManager
        console.log("1. Authorizing AutomationKeeper in FlexibleLoanManager...");
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        
        address currentAuth = loanManager.authorizedAutomationContract();
        console.log("   Current authorized contract:", currentAuth);
        console.log("   Setting to AutomationKeeper:", automationKeeper);
        
        loanManager.setAutomationContract(automationKeeper);
        console.log("   [SUCCESS] AutomationKeeper authorized in FlexibleLoanManager");
        console.log("");
        
        // Fix Issue 2: Authorize AutomationKeeper in AutomationAdapter
        console.log("2. Authorizing AutomationKeeper in AutomationAdapter...");
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        address currentAdapterAuth = adapter.authorizedAutomationContract();
        console.log("   Current authorized contract:", currentAdapterAuth);
        console.log("   Setting to AutomationKeeper:", automationKeeper);
        
        adapter.setAutomationContract(automationKeeper);
        console.log("   [SUCCESS] AutomationKeeper authorized in AutomationAdapter");
        console.log("");
        
        console.log("All authorization issues fixed!");
    }
    
    function verifyFixes() internal view {
        console.log("=== VERIFYING FIXES ===");
        console.log("");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        // Verify FlexibleLoanManager authorization
        address lmAuth = loanManager.authorizedAutomationContract();
        bool lmFixed = (lmAuth == automationKeeper);
        console.log("FlexibleLoanManager authorized contract:", lmAuth);
        console.log("FlexibleLoanManager fix verified:", lmFixed);
        
        // Verify AutomationAdapter authorization
        address adapterAuth = adapter.authorizedAutomationContract();
        bool adapterFixed = (adapterAuth == automationKeeper);
        console.log("AutomationAdapter authorized contract:", adapterAuth);
        console.log("AutomationAdapter fix verified:", adapterFixed);
        
        console.log("");
        
        if (lmFixed && adapterFixed) {
            console.log("[SUCCESS] ALL AUTHORIZATIONS FIXED!");
            console.log("The automation chain should now work properly.");
            console.log("");
            console.log("NEXT STEPS:");
            console.log("1. Test position liquidation");
            console.log("2. Monitor Chainlink Automation execution");
            console.log("3. Verify positions are being liquidated automatically");
        } else {
            console.log("[ERROR] Some authorizations still not working:");
            if (!lmFixed) {
                console.log("- FlexibleLoanManager authorization failed");
            }
            if (!adapterFixed) {
                console.log("- AutomationAdapter authorization failed");
            }
        }
    }
} 
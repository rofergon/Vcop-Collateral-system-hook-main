// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title FixVaultAuthorizations
 * @notice Fixes all authorization issues preventing automated liquidations
 * @dev Solves the "Vault error: Unauthorized automation" problem
 */
contract FixVaultAuthorizations is Script {
    
    // Contract addresses
    address constant FLEXIBLE_LOAN_MANAGER = 0xD1459d5113a5253b8BC9Fa69D35A25E45E122c28;
    address constant AUTOMATION_KEEPER = 0xf7FfF14bF8872243707c0519AAFBe266B03bf57a;
    address constant AUTOMATION_ADAPTER = 0xbB063767915A6CA539245d3719e3B405263fa355;
    address constant VAULT_BASED_HANDLER = 0x7CF68d2FCD4C4Ca2e628A73B1c4F50dD35F8C68c;
    
    function run() external {
        console.log("=== FIXING VAULT AUTHORIZATION ISSUES ===");
        console.log("Timestamp:", block.timestamp);
        console.log("");
        
        vm.startBroadcast();
        
        // Load contracts
        FlexibleLoanManager loanManager = FlexibleLoanManager(FLEXIBLE_LOAN_MANAGER);
        VaultBasedHandler vaultHandler = VaultBasedHandler(VAULT_BASED_HANDLER);
        
        console.log("1. CURRENT STATUS:");
        console.log("   FlexibleLoanManager:", FLEXIBLE_LOAN_MANAGER);
        console.log("   VaultBasedHandler:", VAULT_BASED_HANDLER);
        console.log("   AutomationKeeper:", AUTOMATION_KEEPER);
        console.log("   AutomationAdapter:", AUTOMATION_ADAPTER);
        console.log("");
        
        // Check current authorizations
        address currentAuthorizedContract = loanManager.authorizedAutomationContract();
        console.log("2. CURRENT AUTHORIZATIONS:");
        console.log("   FlexibleLoanManager authorized contract:", currentAuthorizedContract);
        console.log("   Should be AutomationKeeper:", currentAuthorizedContract == AUTOMATION_KEEPER);
        console.log("");
        
        // FIX 1: Authorize AutomationKeeper in FlexibleLoanManager
        console.log("3. FIX 1: Authorizing AutomationKeeper in FlexibleLoanManager...");
        try loanManager.setAutomationContract(AUTOMATION_KEEPER) {
                         console.log("   SUCCESS: AutomationKeeper authorized in FlexibleLoanManager");
                 } catch {
             console.log("   FAILED: Could not authorize AutomationKeeper in FlexibleLoanManager");
         }
         console.log("");
         
         // FIX 2: Authorize FlexibleLoanManager in VaultBasedHandler
         console.log("4. FIX 2: Authorizing FlexibleLoanManager in VaultBasedHandler...");
         try vaultHandler.authorizeAutomationContract(FLEXIBLE_LOAN_MANAGER) {
             console.log("   SUCCESS: FlexibleLoanManager authorized in VaultBasedHandler");
         } catch {
             console.log("   FAILED: Could not authorize FlexibleLoanManager in VaultBasedHandler");
         }
         console.log("");
         
         // FIX 3: Also authorize AutomationKeeper in VaultBasedHandler (backup)
         console.log("5. FIX 3: Authorizing AutomationKeeper in VaultBasedHandler (backup)...");
         try vaultHandler.authorizeAutomationContract(AUTOMATION_KEEPER) {
             console.log("   SUCCESS: AutomationKeeper authorized in VaultBasedHandler");
         } catch {
             console.log("   FAILED: Could not authorize AutomationKeeper in VaultBasedHandler");
        }
        console.log("");
        
        // VERIFICATION: Check final state
        console.log("6. VERIFICATION - FINAL STATE:");
        
        // Check FlexibleLoanManager authorization
        address finalAuthorizedContract = loanManager.authorizedAutomationContract();
        console.log("   FlexibleLoanManager authorized contract:", finalAuthorizedContract);
        console.log("   Is AutomationKeeper authorized:", finalAuthorizedContract == AUTOMATION_KEEPER);
        
        // Check VaultBasedHandler authorizations
        try vaultHandler.authorizedAutomationContracts(FLEXIBLE_LOAN_MANAGER) returns (bool isFlexibleAuth) {
            console.log("   FlexibleLoanManager authorized in VaultHandler:", isFlexibleAuth);
        } catch {
            console.log("   Could not check FlexibleLoanManager authorization in VaultHandler");
        }
        
        try vaultHandler.authorizedAutomationContracts(AUTOMATION_KEEPER) returns (bool isKeeperAuth) {
            console.log("   AutomationKeeper authorized in VaultHandler:", isKeeperAuth);
        } catch {
            console.log("   Could not check AutomationKeeper authorization in VaultHandler");
        }
        console.log("");
        
        vm.stopBroadcast();
        
        console.log("7. SUMMARY:");
        console.log("   The automated liquidation flow should now work:");
        console.log("   1. Chainlink calls: AutomationKeeper.performUpkeep()");
        console.log("   2. AutomationKeeper calls: FlexibleLoanManager.vaultFundedAutomatedLiquidation()");
        console.log("   3. FlexibleLoanManager calls: VaultBasedHandler.automationRepay()");
                 console.log("   4. All authorization checks should now pass");
        console.log("");
                 console.log("NEXT STEPS:");
        console.log("   1. Test with: make crash-avalanche-market");
        console.log("   2. Check Chainlink dashboard for automation execution");
        console.log("   3. Verify positions are liquidated automatically");
        console.log("");
        console.log("=== FIX AUTHORIZATION ISSUES COMPLETED ===");
    }
} 
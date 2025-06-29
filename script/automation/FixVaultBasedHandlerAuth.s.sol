// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";

/**
 * @title FixVaultBasedHandlerAuth
 * @notice Specifically fixes FlexibleLoanManager authorization in VaultBasedHandler
 * @dev Solves the "Vault error: Unauthorized automation" issue preventing liquidations
 */
contract FixVaultBasedHandlerAuth is Script {
    
    // Contract addresses
    address constant FLEXIBLE_LOAN_MANAGER = 0xD1bC54509E938d5271025412DF04Ad6e9DBAfbd1;
    address constant VAULT_BASED_HANDLER = 0x710c94fe37BA06a78478Ddd6231425152ce65b99;
    address constant AUTOMATION_KEEPER = 0xf7FfF14bF8872243707c0519AAFBe266B03bf57a;
    
    function run() external {
        console.log("=== FIXING VAULTBASEDHANDLER AUTHORIZATION ===");
        console.log("Target: Authorize FlexibleLoanManager in VaultBasedHandler");
        console.log("");
        
        vm.startBroadcast();
        
        VaultBasedHandler vaultHandler = VaultBasedHandler(VAULT_BASED_HANDLER);
        
        console.log("1. CONTRACT ADDRESSES:");
        console.log("   VaultBasedHandler:", VAULT_BASED_HANDLER);
        console.log("   FlexibleLoanManager:", FLEXIBLE_LOAN_MANAGER);
        console.log("   AutomationKeeper:", AUTOMATION_KEEPER);
        console.log("");
        
        // Check current owner
        address currentOwner = vaultHandler.owner();
        console.log("2. OWNERSHIP CHECK:");
        console.log("   VaultBasedHandler owner:", currentOwner);
        console.log("   Caller (msg.sender):", msg.sender);
        console.log("   Is caller owner:", currentOwner == msg.sender);
        console.log("");
        
        // Check current authorization status
        bool isFlexibleAuth = vaultHandler.authorizedAutomationContracts(FLEXIBLE_LOAN_MANAGER);
        bool isKeeperAuth = vaultHandler.authorizedAutomationContracts(AUTOMATION_KEEPER);
        
        console.log("3. CURRENT AUTHORIZATION STATUS:");
        console.log("   FlexibleLoanManager authorized:", isFlexibleAuth);
        console.log("   AutomationKeeper authorized:", isKeeperAuth);
        console.log("");
        
        // Authorize FlexibleLoanManager
        console.log("4. AUTHORIZING FLEXIBLELOANMANAGER...");
        if (!isFlexibleAuth) {
            try vaultHandler.authorizeAutomationContract(FLEXIBLE_LOAN_MANAGER) {
                console.log("   SUCCESS: FlexibleLoanManager authorized in VaultBasedHandler");
            } catch Error(string memory reason) {
                console.log("   FAILED: FlexibleLoanManager authorization failed");
                console.log("   Reason:", reason);
            } catch {
                console.log("   FAILED: FlexibleLoanManager authorization failed (unknown reason)");
            }
        } else {
            console.log("   SKIPPED: FlexibleLoanManager already authorized");
        }
        console.log("");
        
        // Also authorize AutomationKeeper as backup
        console.log("5. AUTHORIZING AUTOMATIONKEEPER (BACKUP)...");
        if (!isKeeperAuth) {
            try vaultHandler.authorizeAutomationContract(AUTOMATION_KEEPER) {
                console.log("   SUCCESS: AutomationKeeper authorized in VaultBasedHandler");
            } catch Error(string memory reason) {
                console.log("   FAILED: AutomationKeeper authorization failed");
                console.log("   Reason:", reason);
            } catch {
                console.log("   FAILED: AutomationKeeper authorization failed (unknown reason)");
            }
        } else {
            console.log("   SKIPPED: AutomationKeeper already authorized");
        }
        console.log("");
        
        // Verify final state
        bool finalFlexibleAuth = vaultHandler.authorizedAutomationContracts(FLEXIBLE_LOAN_MANAGER);
        bool finalKeeperAuth = vaultHandler.authorizedAutomationContracts(AUTOMATION_KEEPER);
        
        console.log("6. FINAL VERIFICATION:");
        console.log("   FlexibleLoanManager authorized:", finalFlexibleAuth);
        console.log("   AutomationKeeper authorized:", finalKeeperAuth);
        console.log("");
        
        vm.stopBroadcast();
        
        console.log("7. EXPECTED RESULT:");
        if (finalFlexibleAuth) {
            console.log("   SUCCESS: The automation flow should now work!");
            console.log("   FlexibleLoanManager can call VaultBasedHandler.automationRepay()");
        } else {
            console.log("   FAILURE: FlexibleLoanManager still not authorized");
            console.log("   Check ownership and try again");
        }
        console.log("");
        
        console.log("8. AUTOMATION FLOW:");
        console.log("   1. Chainlink calls: AutomationKeeper.performUpkeep()");
        console.log("   2. AutomationKeeper calls: FlexibleLoanManager.vaultFundedAutomatedLiquidation()");
        console.log("   3. FlexibleLoanManager calls: VaultBasedHandler.automationRepay()");
        console.log("   4. Step 3 should now succeed (no more 'Unauthorized automation' errors)");
        console.log("");
        console.log("=== VAULTBASEDHANDLER AUTHORIZATION FIX COMPLETED ===");
    }
} 
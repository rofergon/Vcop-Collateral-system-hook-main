// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";

/**
 * @title TestETHLiquidation
 * @notice Tests manual liquidation of ETH collateral positions to identify automation issues
 */
contract TestETHLiquidation is Script {
    
    // Contract addresses
    address constant FLEXIBLE_LOAN_MANAGER = 0xD1bC54509E938d5271025412DF04Ad6e9DBAfbd1;
    address constant VAULT_BASED_HANDLER = 0x710c94fe37BA06a78478Ddd6231425152ce65b99;
    address constant MOCK_USDC = 0x273860ddf28A478136B935E458b272876AB22Ab5;
    address constant MOCK_ETH = 0x55D917171766710BB0B94ed56aAb39EfA1692a34;
    
    function run() external {
        console.log("=== TESTING ETH COLLATERAL LIQUIDATION ===");
        console.log("Testing manual liquidation of ETH positions to identify automation issues");
        console.log("");
        
        vm.startBroadcast();
        
        // Load contracts
        FlexibleLoanManager loanManager = FlexibleLoanManager(FLEXIBLE_LOAN_MANAGER);
        VaultBasedHandler vaultHandler = VaultBasedHandler(VAULT_BASED_HANDLER);
        
        console.log("1. TESTING POSITION 4 (ETH COLLATERAL):");
        testPosition(loanManager, vaultHandler, 4);
        console.log("");
        
        console.log("2. TESTING POSITION 5 (ETH COLLATERAL):");
        testPosition(loanManager, vaultHandler, 5);
        console.log("");
        
        vm.stopBroadcast();
        
        console.log("3. ANALYSIS:");
        console.log("   If manual liquidation fails, this reveals the exact issue");
        console.log("   If manual liquidation works, the problem is in automation configuration");
        console.log("");
        
        console.log("=== ETH LIQUIDATION TEST COMPLETED ===");
    }
    
    function testPosition(
        FlexibleLoanManager loanManager,
        VaultBasedHandler vaultHandler,
        uint256 positionId
    ) internal {
        console.log("   Testing position", positionId, "...");
        
        // Check if position can be liquidated
        try loanManager.canLiquidate(positionId) returns (bool canLiq) {
            console.log("   Can liquidate:", canLiq);
            
            if (!canLiq) {
                console.log("   Position not liquidable - skipping");
                return;
            }
        } catch {
            console.log("   ERROR: Could not check liquidation status");
            return;
        }
        
        // Try manual liquidation
        console.log("   Attempting manual liquidation...");
        
        try loanManager.liquidatePosition(positionId) {
            console.log("   SUCCESS: Manual liquidation worked!");
            console.log("   This means the issue is in automation configuration, not the liquidation logic");
        } catch Error(string memory reason) {
            console.log("   FAILED: Manual liquidation failed");
            console.log("   Reason:", reason);
            console.log("   This reveals the exact issue preventing automated liquidations");
        } catch {
            console.log("   FAILED: Manual liquidation failed (unknown reason)");
        }
        
        // Try vault-funded liquidation (automation method)
        console.log("   Attempting vault-funded liquidation (automation method)...");
        
        try loanManager.vaultFundedAutomatedLiquidation(positionId) {
            console.log("   SUCCESS: Vault-funded liquidation worked!");
            console.log("   The automation system should be working but may have other issues");
        } catch Error(string memory reason) {
            console.log("   FAILED: Vault-funded liquidation failed");
            console.log("   Reason:", reason);
            console.log("   This is the method used by automation - this is the exact problem!");
        } catch {
            console.log("   FAILED: Vault-funded liquidation failed (unknown reason)");
        }
    }
} 
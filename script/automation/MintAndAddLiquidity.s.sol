// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";

/**
 * @title MintAndAddLiquidity
 * @notice Mints USDC and adds liquidity to VaultBasedHandler for automated liquidations
 */
contract MintAndAddLiquidity is Script {
    
    // Contract addresses  
    address constant VAULT_BASED_HANDLER = 0x710c94fe37BA06a78478Ddd6231425152ce65b99;
    address constant MOCK_USDC = 0x273860ddf28A478136B935E458b272876AB22Ab5;
    
    // Amount to provide (20,000 USDC should be more than enough)
    uint256 constant LIQUIDITY_AMOUNT = 20000 * 1e6; // 20,000 USDC
    
    function run() external {
        console.log("=== MINTING USDC AND ADDING VAULT LIQUIDITY ===");
        console.log("");
        
        vm.startBroadcast();
        
        console.log("1. CONTRACT INFORMATION:");
        console.log("   VaultBasedHandler:", VAULT_BASED_HANDLER);
        console.log("   Mock USDC:", MOCK_USDC);
        console.log("   Liquidity Provider:", msg.sender);
        console.log("   Amount to provide:", LIQUIDITY_AMOUNT / 1e6, "USDC");
        console.log("");
        
        // Load contracts
        VaultBasedHandler vaultHandler = VaultBasedHandler(VAULT_BASED_HANDLER);
        
        // Step 1: Mint USDC
        console.log("2. MINTING USDC:");
        console.log("   Minting", LIQUIDITY_AMOUNT / 1e6, "USDC...");
        
        (bool mintSuccess, ) = MOCK_USDC.call(
            abi.encodeWithSignature("mint(address,uint256)", msg.sender, LIQUIDITY_AMOUNT)
        );
        
        if (mintSuccess) {
            console.log("   SUCCESS: USDC minted");
        } else {
            console.log("   WARNING: USDC minting failed (may already have enough)");
        }
        console.log("");
        
        // Step 2: Approve USDC
        console.log("3. APPROVING USDC:");
        console.log("   Approving", LIQUIDITY_AMOUNT / 1e6, "USDC for VaultBasedHandler...");
        
        (bool approveSuccess, ) = MOCK_USDC.call(
            abi.encodeWithSignature("approve(address,uint256)", VAULT_BASED_HANDLER, LIQUIDITY_AMOUNT)
        );
        
        if (approveSuccess) {
            console.log("   SUCCESS: USDC approved");
        } else {
            console.log("   ERROR: USDC approval failed");
            vm.stopBroadcast();
            return;
        }
        console.log("");
        
        // Step 3: Add liquidity to vault
        console.log("4. ADDING LIQUIDITY TO VAULT:");
        console.log("   Providing", LIQUIDITY_AMOUNT / 1e6, "USDC liquidity...");
        
        try vaultHandler.provideLiquidity(MOCK_USDC, LIQUIDITY_AMOUNT, msg.sender) {
            console.log("   SUCCESS: Liquidity provided to vault!");
        } catch Error(string memory reason) {
            console.log("   ERROR: Liquidity provision failed");
            console.log("   Reason:", reason);
            vm.stopBroadcast();
            return;
        } catch {
            console.log("   ERROR: Liquidity provision failed (unknown reason)");
            vm.stopBroadcast();
            return;
        }
        console.log("");
        
        // Step 4: Verify vault status
        console.log("5. VERIFYING VAULT STATUS:");
        
        try vaultHandler.getAvailableLiquidity(MOCK_USDC) returns (uint256 available) {
            console.log("   Available USDC liquidity:", available);
            console.log("   Available USDC (readable):", available / 1e6);
        } catch {
            console.log("   Could not check available liquidity");
        }
        
        try vaultHandler.getAutomationLiquidityStatus(MOCK_USDC) returns (
            uint256 availableForAutomation,
            uint256 totalAutomationLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("   Available for automation:", availableForAutomation / 1e6);
            console.log("   Can liquidate:", canLiquidate);
            console.log("   Total automation liquidations:", totalAutomationLiquidations);
        } catch {
            console.log("   Could not check automation status");
        }
        console.log("");
        
        vm.stopBroadcast();
        
        console.log("6. FINAL RESULT:");
        console.log("   If successful, the vault now has sufficient liquidity for liquidations!");
        console.log("   Automated liquidations should work in the next Chainlink execution.");
        console.log("");
        
        console.log("7. NEXT STEPS:");
        console.log("   1. Wait for next Chainlink Automation execution (happens automatically)");
        console.log("   2. Monitor positions 2, 4, 5, 6, 7 for automatic liquidation");
        console.log("   3. Check automation dashboard: https://automation.chain.link/avalanche-fuji");
        console.log("   4. Verify no more 'insufficient liquidity' errors in logs");
        console.log("");
        
        console.log("=== MINT AND ADD LIQUIDITY COMPLETED ===");
    }
} 
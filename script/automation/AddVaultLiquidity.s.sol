// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title AddVaultLiquidity
 * @notice Adds USDC liquidity to VaultBasedHandler to enable automated liquidations
 */
contract AddVaultLiquidity is Script {
    
    // Contract addresses
    address constant VAULT_BASED_HANDLER = 0x710c94fe37BA06a78478Ddd6231425152ce65b99;
    address constant MOCK_USDC = 0x819B58A646CDd8289275A87653a2aA4902b14fe6;
    
    // Amount to provide (20,000 USDC should be more than enough)
    uint256 constant LIQUIDITY_AMOUNT = 20000 * 1e6; // 20,000 USDC
    
    function run() external {
        console.log("=== ADDING VAULT LIQUIDITY FOR AUTOMATED LIQUIDATIONS ===");
        console.log("");
        
        vm.startBroadcast();
        
        // Load contracts
        VaultBasedHandler vaultHandler = VaultBasedHandler(VAULT_BASED_HANDLER);
        IERC20 usdc = IERC20(MOCK_USDC);
        
        console.log("1. CONTRACT INFORMATION:");
        console.log("   VaultBasedHandler:", VAULT_BASED_HANDLER);
        console.log("   Mock USDC:", MOCK_USDC);
        console.log("   Liquidity Provider:", msg.sender);
        console.log("");
        
        // Check current balances
        uint256 userBalance = usdc.balanceOf(msg.sender);
        uint256 currentVaultLiquidity = vaultHandler.getAvailableLiquidity(MOCK_USDC);
        
        console.log("2. CURRENT STATUS:");
        console.log("   User USDC balance:", userBalance);
        console.log("   User USDC balance (readable):", userBalance / 1e6);
        console.log("   Current vault USDC liquidity:", currentVaultLiquidity);
        console.log("   Current vault USDC (readable):", currentVaultLiquidity / 1e6);
        console.log("");
        
        // Check if user has enough USDC
        require(userBalance >= LIQUIDITY_AMOUNT, "Insufficient USDC balance");
        
        console.log("3. ADDING LIQUIDITY:");
        console.log("   Amount to provide:", LIQUIDITY_AMOUNT);
        console.log("   Amount to provide (readable):", LIQUIDITY_AMOUNT / 1e6, "USDC");
        
        // Approve USDC for vault
        console.log("   Approving USDC...");
        usdc.approve(VAULT_BASED_HANDLER, LIQUIDITY_AMOUNT);
        
        // Provide liquidity to vault
        console.log("   Providing liquidity to vault...");
        vaultHandler.provideLiquidity(MOCK_USDC, LIQUIDITY_AMOUNT, msg.sender);
        
        console.log("   SUCCESS: Liquidity provided!");
        console.log("");
        
        // Verify final state
        uint256 finalUserBalance = usdc.balanceOf(msg.sender);
        uint256 finalVaultLiquidity = vaultHandler.getAvailableLiquidity(MOCK_USDC);
        
        console.log("4. FINAL STATUS:");
        console.log("   User USDC balance:", finalUserBalance);
        console.log("   User USDC balance (readable):", finalUserBalance / 1e6);
        console.log("   Final vault USDC liquidity:", finalVaultLiquidity);
        console.log("   Final vault USDC (readable):", finalVaultLiquidity / 1e6);
        console.log("");
        
        // Check automation status
        (
            uint256 availableForAutomation,
            uint256 totalAutomationLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) = vaultHandler.getAutomationLiquidityStatus(MOCK_USDC);
        
        console.log("5. AUTOMATION STATUS:");
        console.log("   Available for automation:", availableForAutomation);
        console.log("   Available for automation (readable):", availableForAutomation / 1e6);
        console.log("   Can liquidate:", canLiquidate);
        console.log("   Total automation liquidations:", totalAutomationLiquidations);
        console.log("   Total recovered:", totalRecovered);
        console.log("");
        
        vm.stopBroadcast();
        
        console.log("6. RESULT:");
        if (canLiquidate && finalVaultLiquidity >= 8000 * 1e6) {
            console.log("   SUCCESS: Vault now has sufficient liquidity for automated liquidations!");
            console.log("   The automation system should now be able to liquidate positions.");
        } else {
            console.log("   WARNING: May need more liquidity or check other issues.");
        }
        console.log("");
        
        console.log("7. NEXT STEPS:");
        console.log("   1. Wait for next Chainlink Automation execution");
        console.log("   2. Monitor positions 2, 4, 5, 6, 7 for automatic liquidation");
        console.log("   3. Check that no more 'insufficient liquidity' errors occur");
        console.log("   4. Verify liquidated positions are closed automatically");
        console.log("");
        
        console.log("=== VAULT LIQUIDITY ADDITION COMPLETED ===");
    }
} 
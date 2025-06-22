// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title TransferFundsToNewVault
 * @notice Transfiere fondos del vault anterior al nuevo vault con automation
 */
contract TransferFundsToNewVault is Script {
    
    // Direcciones del sistema
    address constant OLD_VAULT_HANDLER = 0xDE9d27ed1945A64F79c497134CEf511d6C20d9Ee;
    address constant NEW_VAULT_HANDLER = 0xD83E555AC6186d5f84863e79F26AF3222E5EC680;
    address constant MOCK_ETH = 0xff40519308154839EF5772CccE6012ccDEf5b32a;
    address constant MOCK_USDC = 0xabA8AFd2C637c27d09A893fe048A74f94D74108B;
    
    function run() external {
        console.log("=== TRANSFERRING FUNDS TO NEW VAULT ===");
        console.log("");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer:", deployer);
        console.log("Old Vault:", OLD_VAULT_HANDLER);
        console.log("New Vault:", NEW_VAULT_HANDLER);
        console.log("");
        
        // Check balances before
        uint256 oldEthBalance = IERC20(MOCK_ETH).balanceOf(OLD_VAULT_HANDLER);
        uint256 oldUsdcBalance = IERC20(MOCK_USDC).balanceOf(OLD_VAULT_HANDLER);
        uint256 deployerEthBalance = IERC20(MOCK_ETH).balanceOf(deployer);
        uint256 deployerUsdcBalance = IERC20(MOCK_USDC).balanceOf(deployer);
        
        console.log("BEFORE TRANSFER:");
        console.log("===============");
        console.log("Old vault ETH:", oldEthBalance / 1e18);
        console.log("Old vault USDC:", oldUsdcBalance / 1e6);
        console.log("Deployer ETH:", deployerEthBalance / 1e18);
        console.log("Deployer USDC:", deployerUsdcBalance / 1e6);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        VaultBasedHandler oldVault = VaultBasedHandler(OLD_VAULT_HANDLER);
        VaultBasedHandler newVault = VaultBasedHandler(NEW_VAULT_HANDLER);
        
        // STEP 1: Withdraw from old vault (if we provided the liquidity)
        console.log("STEP 1: Attempting to withdraw from old vault...");
        
        try oldVault.withdrawLiquidity(MOCK_USDC, oldUsdcBalance, deployer) {
            console.log("Successfully withdrew", oldUsdcBalance / 1e6, "USDC from old vault");
        } catch Error(string memory reason) {
            console.log("Failed to withdraw USDC:", reason);
            console.log("Will use deployer's existing USDC instead");
        }
        
        try oldVault.withdrawLiquidity(MOCK_ETH, oldEthBalance, deployer) {
            console.log("Successfully withdrew", oldEthBalance / 1e18, "ETH from old vault");
        } catch Error(string memory reason) {
            console.log("Failed to withdraw ETH:", reason);
            console.log("Will use deployer's existing ETH instead");
        }
        
        // STEP 2: Add liquidity to new vault
        console.log("");
        console.log("STEP 2: Adding liquidity to new vault...");
        
        uint256 currentDeployerUsdc = IERC20(MOCK_USDC).balanceOf(deployer);
        uint256 currentDeployerEth = IERC20(MOCK_ETH).balanceOf(deployer);
        
        console.log("Current deployer USDC:", currentDeployerUsdc / 1e6);
        console.log("Current deployer ETH:", currentDeployerEth / 1e18);
        
        // Add USDC liquidity
        if (currentDeployerUsdc >= 100000 * 1e6) { // At least 100k USDC
            uint256 usdcToAdd = 100000 * 1e6; // Add 100k USDC
            
            IERC20(MOCK_USDC).approve(NEW_VAULT_HANDLER, usdcToAdd);
            newVault.provideLiquidity(MOCK_USDC, usdcToAdd, deployer);
            console.log("Added", usdcToAdd / 1e6, "USDC liquidity to new vault");
        } else {
            console.log("Insufficient USDC balance for liquidity provision");
        }
        
        // Add ETH liquidity  
        if (currentDeployerEth >= 10 * 1e18) { // At least 10 ETH
            uint256 ethToAdd = 10 * 1e18; // Add 10 ETH
            
            IERC20(MOCK_ETH).approve(NEW_VAULT_HANDLER, ethToAdd);
            newVault.provideLiquidity(MOCK_ETH, ethToAdd, deployer);
            console.log("Added", ethToAdd / 1e18, "ETH liquidity to new vault");
        } else {
            console.log("Insufficient ETH balance for liquidity provision");
        }
        
        vm.stopBroadcast();
        
        // STEP 3: Verify new vault status
        console.log("");
        console.log("STEP 3: Verifying new vault status...");
        
        uint256 newVaultEth = IERC20(MOCK_ETH).balanceOf(NEW_VAULT_HANDLER);
        uint256 newVaultUsdc = IERC20(MOCK_USDC).balanceOf(NEW_VAULT_HANDLER);
        
        console.log("AFTER TRANSFER:");
        console.log("==============");
        console.log("New vault ETH:", newVaultEth / 1e18);
        console.log("New vault USDC:", newVaultUsdc / 1e6);
        
        // Check automation status
        (uint256 available, , , bool canLiquidate) = newVault.getAutomationLiquidityStatus(MOCK_USDC);
        console.log("");
        console.log("AUTOMATION STATUS:");
        console.log("=================");
        console.log("Available for automation:", available / 1e6, "USDC");
        console.log("Can liquidate:", canLiquidate);
        
        bool isAuthorized = newVault.authorizedAutomationContracts(0x15C7298Dd649DcDc17D281cB0dAE84E945573c93);
        console.log("Automation keeper authorized:", isAuthorized);
        
        if (canLiquidate && isAuthorized && available > 0) {
            console.log("");
            console.log("SUCCESS: New vault ready for automation!");
            console.log("Chainlink Automation should now work properly");
        } else {
            console.log("");
            console.log("ISSUE: New vault not fully ready");
            console.log("- Has liquidity:", available > 0);
            console.log("- Authorized:", isAuthorized);
            console.log("- Can liquidate:", canLiquidate);
        }
        
        console.log("");
        console.log("FINAL STEPS:");
        console.log("1. Test Chainlink automation with new vault");
        console.log("2. Verify liquidations work properly");
        console.log("3. Monitor automation performance");
    }
} 
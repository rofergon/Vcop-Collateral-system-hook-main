// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Core contracts
import {VaultBasedHandler} from "../src/core/VaultBasedHandler.sol";

// Auto-generated addresses
import {MOCK_ETH, MOCK_USDC, VAULT_BASED_HANDLER} from "./generated/TestSimpleLoansAddresses.sol";

/**
 * @title ProvideLiquidity
 * @notice Script to provide initial liquidity to VaultBasedHandler
 */
contract ProvideLiquidity is Script {
    
    address constant MOCK_ETH_ADDRESS = MOCK_ETH;
    address constant MOCK_USDC_ADDRESS = MOCK_USDC;
    address constant VAULT_BASED_HANDLER_ADDRESS = VAULT_BASED_HANDLER;
    
    // Liquidity amounts
    uint256 constant ETH_LIQUIDITY = 100 * 1e18;    // 100 ETH
    uint256 constant USDC_LIQUIDITY = 250000 * 1e6; // 250,000 USDC
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        
        console.log("=== PROVIDING LIQUIDITY TO VAULT BASED HANDLER ===");
        console.log("Deployer address:", deployer);
        console.log("VaultBasedHandler:", VAULT_BASED_HANDLER_ADDRESS);
        console.log("");
        
        vm.startBroadcast(privateKey);
        
        IERC20 ethToken = IERC20(MOCK_ETH_ADDRESS);
        IERC20 usdcToken = IERC20(MOCK_USDC_ADDRESS);
        VaultBasedHandler vaultHandler = VaultBasedHandler(VAULT_BASED_HANDLER_ADDRESS);
        
        // Check initial balances
        console.log("Initial balances:");
        console.log("ETH balance:", ethToken.balanceOf(deployer) / 1e18);
        console.log("USDC balance:", usdcToken.balanceOf(deployer) / 1e6);
        console.log("");
        
        // Provide ETH liquidity
        console.log("Providing ETH liquidity...");
        ethToken.approve(VAULT_BASED_HANDLER_ADDRESS, ETH_LIQUIDITY);
        vaultHandler.provideLiquidity(MOCK_ETH_ADDRESS, ETH_LIQUIDITY, deployer);
        console.log("Provided", ETH_LIQUIDITY / 1e18, "ETH to vault");
        
        // Provide USDC liquidity
        console.log("Providing USDC liquidity...");
        usdcToken.approve(VAULT_BASED_HANDLER_ADDRESS, USDC_LIQUIDITY);
        vaultHandler.provideLiquidity(MOCK_USDC_ADDRESS, USDC_LIQUIDITY, deployer);
        console.log("Provided", USDC_LIQUIDITY / 1e6, "USDC to vault");
        
        vm.stopBroadcast();
        
        // Check final liquidity
        console.log("");
        console.log("Final vault liquidity:");
        console.log("ETH available:", vaultHandler.getAvailableLiquidity(MOCK_ETH_ADDRESS) / 1e18);
        console.log("USDC available:", vaultHandler.getAvailableLiquidity(MOCK_USDC_ADDRESS) / 1e6);
        
        console.log("");
        console.log("=== LIQUIDITY PROVIDED SUCCESSFULLY ===");
    }
} 
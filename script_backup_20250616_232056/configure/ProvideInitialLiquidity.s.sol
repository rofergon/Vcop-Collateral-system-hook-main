// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Mock tokens
import {MockETH} from "../../src/mocks/MockETH.sol";
import {MockWBTC} from "../../src/mocks/MockWBTC.sol";
import {MockUSDC} from "../../src/mocks/MockUSDC.sol";

// Handlers
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";

/**
 * @title ProvideInitialLiquidity
 * @notice Provides initial liquidity to vault handlers for testing
 */
contract ProvideInitialLiquidity is Script {
    
    // Asset addresses (loaded from environment)
    address public mockETH;
    address public mockWBTC;
    address public mockUSDC;
    
    // Handler address
    address public vaultBasedHandler;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== PROVIDING INITIAL LIQUIDITY ===");
        console.log("Deployer address:", deployer);
        
        _loadAddresses();
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Mint tokens for liquidity provision
        _mintTokens(deployer);
        
        // Provide liquidity for each asset
        _provideETHLiquidity(deployer);
        _provideWBTCLiquidity(deployer);
        _provideUSDCLiquidity(deployer);
        
        vm.stopBroadcast();
        
        _printLiquiditySummary();
    }
    
    function _loadAddresses() internal {
        mockETH = vm.envAddress("MOCK_ETH_ADDRESS");
        mockWBTC = vm.envAddress("MOCK_WBTC_ADDRESS");
        mockUSDC = vm.envAddress("MOCK_USDC_ADDRESS");
        vaultBasedHandler = vm.envAddress("VAULT_BASED_HANDLER_ADDRESS");
        
        console.log("Loaded addresses from environment");
        console.log("VaultBasedHandler:", vaultBasedHandler);
    }
    
    function _mintTokens(address recipient) internal {
        console.log("\n--- Minting tokens for liquidity provision ---");
        
        // Mint generous amounts for testing
        MockETH(mockETH).mint(recipient, 200 * 1e18);     // 200 ETH
        MockWBTC(mockWBTC).mint(recipient, 10 * 1e8);     // 10 WBTC
        MockUSDC(mockUSDC).mint(recipient, 500000 * 1e6); // 500K USDC
        
        console.log("Minted 200 ETH to deployer");
        console.log("Minted 10 WBTC to deployer");
        console.log("Minted 500K USDC to deployer");
    }
    
    function _provideETHLiquidity(address provider) internal {
        console.log("\n--- Providing ETH liquidity ---");
        
        uint256 amount = 100 * 1e18; // 100 ETH
        
        MockETH(mockETH).approve(vaultBasedHandler, amount);
        VaultBasedHandler(vaultBasedHandler).provideLiquidity(
            mockETH,
            amount,
            provider
        );
        
        console.log("Provided 100 ETH liquidity");
    }
    
    function _provideWBTCLiquidity(address provider) internal {
        console.log("\n--- Providing WBTC liquidity ---");
        
        uint256 amount = 5 * 1e8; // 5 WBTC
        
        MockWBTC(mockWBTC).approve(vaultBasedHandler, amount);
        VaultBasedHandler(vaultBasedHandler).provideLiquidity(
            mockWBTC,
            amount,
            provider
        );
        
        console.log("Provided 5 WBTC liquidity");
    }
    
    function _provideUSDCLiquidity(address provider) internal {
        console.log("\n--- Providing USDC liquidity ---");
        
        uint256 amount = 200000 * 1e6; // 200K USDC
        
        MockUSDC(mockUSDC).approve(vaultBasedHandler, amount);
        VaultBasedHandler(vaultBasedHandler).provideLiquidity(
            mockUSDC,
            amount,
            provider
        );
        
        console.log("Provided 200K USDC liquidity");
    }
    
    function _printLiquiditySummary() internal view {
        console.log("\n=== LIQUIDITY PROVISION SUMMARY ===");
        console.log("");
        console.log("ASSETS WITH LIQUIDITY:");
        console.log("ETH:   100 tokens available for loans");
        console.log("WBTC:  5 tokens available for loans");
        console.log("USDC:  200,000 tokens available for loans");
        console.log("");
        console.log("VAULT HANDLER:");
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("");
        console.log("NEXT STEPS:");
        console.log("1. Test loans: make test-multi-token-loans");
        console.log("2. Check liquidity: make check-liquidity");
        console.log("3. Monitor system: make check-system-status");
        console.log("");
        console.log("NOTE: Additional liquidity can be provided by calling:");
        console.log("handler.provideLiquidity(asset, amount, provider)");
    }
}

// Required environment variables:
// PRIVATE_KEY=your_private_key
// MOCK_ETH_ADDRESS=deployed_mock_eth_address
// MOCK_WBTC_ADDRESS=deployed_mock_wbtc_address
// MOCK_USDC_ADDRESS=deployed_mock_usdc_address
// VAULT_BASED_HANDLER_ADDRESS=deployed_vault_handler_address 
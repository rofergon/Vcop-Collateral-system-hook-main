// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../../src/core/FlexibleLoanManager.sol";
import "../../src/core/FlexibleAssetHandler.sol";
import "../../src/core/VaultBasedHandler.sol";
import "../../src/mocks/MockERC20.sol";
import "../../src/interfaces/IAssetHandler.sol";

/**
 * @title ConfigureAvalancheAssets
 * @dev Configure asset handlers and liquidity for Avalanche Fuji deployment
 * This script is specifically designed for Avalanche deployment flow
 */
contract ConfigureAvalancheAssets is Script {
    
    function run() external {
        vm.startBroadcast();
        
        // Load deployed addresses from JSON
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(
            vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager")
        );
        FlexibleAssetHandler flexibleAssetHandler = FlexibleAssetHandler(
            vm.parseJsonAddress(json, ".coreLending.flexibleAssetHandler")
        );
        VaultBasedHandler vaultBasedHandler = VaultBasedHandler(
            vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler")
        );
        
        // Get token addresses
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        address vcopToken = vm.parseJsonAddress(json, ".tokens.vcopToken");
        
        console.log("CONFIGURING AVALANCHE ASSETS");
        console.log("============================");
        console.log("FlexibleLoanManager:", address(loanManager));
        console.log("FlexibleAssetHandler:", address(flexibleAssetHandler));
        console.log("VaultBasedHandler:", address(vaultBasedHandler));
        console.log("");
        
        // Step 1: Set asset handlers in FlexibleLoanManager
        console.log("Step 1: Setting asset handlers in FlexibleLoanManager...");
        loanManager.setAssetHandler(IAssetHandler.AssetType.MINTABLE_BURNABLE, address(flexibleAssetHandler));
        console.log("SUCCESS: MINTABLE_BURNABLE handler set");
        
        loanManager.setAssetHandler(IAssetHandler.AssetType.VAULT_BASED, address(vaultBasedHandler));
        console.log("SUCCESS: VAULT_BASED handler set");
        
        // Step 2: Configure external assets in VaultBasedHandler (ETH, BTC)
        console.log("Step 2: Configuring external assets in VaultBasedHandler...");
        
        vaultBasedHandler.configureAsset(mockETH, 
            1300000,  // 130% collateral ratio
            1100000,  // 110% liquidation ratio
            1000 * 1e18, // 1000 ETH max
            80000     // 8% interest rate
        );
        console.log("SUCCESS: ETH configured in vault");
        
        vaultBasedHandler.configureAsset(mockWBTC,
            1400000,  // 140% collateral ratio
            1150000,  // 115% liquidation ratio
            50 * 1e8, // 50 BTC max
            90000     // 9% interest rate
        );
        console.log("SUCCESS: WBTC configured in vault");
        
        // Step 3: Configure USDC in VaultBasedHandler (not FlexibleAssetHandler!)
        console.log("Step 3: Configuring USDC in VaultBasedHandler...");
        
        vaultBasedHandler.configureAsset(mockUSDC,
            1100000,  // 110% collateral ratio
            1050000,  // 105% liquidation ratio
            1000000 * 1e6, // 1M USDC max
            40000     // 4% interest rate
        );
        console.log("SUCCESS: USDC configured in vault");
        
        // Step 4: Configure VCOP in FlexibleAssetHandler
        console.log("Step 4: Configuring VCOP in FlexibleAssetHandler...");
        
        flexibleAssetHandler.configureAsset(vcopToken, 
            IAssetHandler.AssetType.MINTABLE_BURNABLE,
            1200000,  // 120% collateral ratio
            1080000,  // 108% liquidation ratio
            500000 * 1e18, // 500k VCOP max
            50000     // 5% interest rate
        );
        console.log("SUCCESS: VCOP configured in flexible handler");
        
        // Step 5: Mint tokens for liquidity
        console.log("Step 5: Minting tokens for liquidity...");
        MockERC20(mockUSDC).mint(msg.sender, 500000 * 1e6);  // 500k USDC
        MockERC20(mockETH).mint(msg.sender, 50 * 1e18);      // 50 ETH
        MockERC20(mockWBTC).mint(msg.sender, 2 * 1e8);       // 2 WBTC
        console.log("SUCCESS: Test tokens minted");
        
        // Step 6: Provide liquidity to VaultBasedHandler
        console.log("Step 6: Providing liquidity to VaultBasedHandler...");
        
        // USDC liquidity (300k USDC)
        MockERC20(mockUSDC).approve(address(vaultBasedHandler), 300000 * 1e6);
        vaultBasedHandler.provideLiquidity(mockUSDC, 300000 * 1e6, msg.sender);
        console.log("SUCCESS: 300k USDC liquidity provided");
        
        // ETH liquidity (10 ETH)
        MockERC20(mockETH).approve(address(vaultBasedHandler), 10 * 1e18);
        vaultBasedHandler.provideLiquidity(mockETH, 10 * 1e18, msg.sender);
        console.log("SUCCESS: 10 ETH liquidity provided");
        
        // WBTC liquidity (1 WBTC)
        MockERC20(mockWBTC).approve(address(vaultBasedHandler), 1 * 1e8);
        vaultBasedHandler.provideLiquidity(mockWBTC, 1 * 1e8, msg.sender);
        console.log("SUCCESS: 1 WBTC liquidity provided");
        
        vm.stopBroadcast();
        
        console.log("SUCCESS: AVALANCHE ASSETS CONFIGURATION COMPLETED!");
        console.log("");
        console.log("CONFIGURATION SUMMARY:");
        console.log("- VaultBasedHandler configured for: ETH, WBTC, USDC");
        console.log("- FlexibleAssetHandler configured for: VCOP");
        console.log("- Vault liquidity: 300k USDC, 10 ETH, 1 WBTC");
        console.log("- All collateral ratios and interest rates set");
        console.log("- Test tokens minted for operations");
        console.log("");
        console.log("AVALANCHE DEPLOYMENT READY FOR AUTOMATION!");
    }
    
    function checkConfiguration() external view {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        console.log("AVALANCHE CONFIGURATION CHECK");
        console.log("=============================");
        console.log("VaultBasedHandler USDC balance:", MockERC20(mockUSDC).balanceOf(vaultBasedHandler));
        console.log("Configuration check completed");
    }
} 
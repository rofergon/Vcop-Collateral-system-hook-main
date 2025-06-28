// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";
import {IERC20Metadata} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title FixTokenDecimals
 * @notice Arregla el problema de decimales incorrectos que causa el loop infinito de liquidación
 */
contract FixTokenDecimals is Script {
    
    function run() external {
        console.log("=== FIXING TOKEN DECIMALS CONFIGURATION ===");
        console.log("This will fix the incorrect decimals causing liquidation loop");
        console.log("");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address flexibleAssetHandler = vm.parseJsonAddress(json, ".coreLending.flexibleAssetHandler");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        console.log("Loaded Addresses:");
        console.log("  VaultBasedHandler:", vaultBasedHandler);
        console.log("  FlexibleAssetHandler:", flexibleAssetHandler);
        console.log("  MockETH:", mockETH);
        console.log("  MockUSDC:", mockUSDC);
        console.log("  MockWBTC:", mockWBTC);
        console.log("");
        
        // Check current decimals vs contract decimals
        _verifyTokenDecimals(mockETH, mockUSDC, mockWBTC);
        
        vm.startBroadcast();
        
        console.log("STEP 1: Fixing VaultBasedHandler configurations...");
        _fixVaultBasedHandler(vaultBasedHandler, mockETH, mockUSDC, mockWBTC);
        
        console.log("STEP 2: Fixing FlexibleAssetHandler configurations...");
        _fixFlexibleAssetHandler(flexibleAssetHandler, mockETH, mockUSDC, mockWBTC);
        
        console.log("STEP 3: Verifying fixed configurations...");
        _verifyFixedConfigurations(vaultBasedHandler, flexibleAssetHandler, mockETH, mockUSDC, mockWBTC);
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== TOKEN DECIMALS FIX COMPLETED ===");
        console.log("The liquidation loop should now be resolved!");
        console.log("Next steps:");
        console.log("1. Wait for the next Chainlink execution");
        console.log("2. Verify that liquidation completes successfully");
        console.log("3. Check that the position is actually liquidated");
    }
    
    function _verifyTokenDecimals(address eth, address usdc, address wbtc) internal view {
        console.log("CURRENT TOKEN DECIMALS:");
        console.log("======================");
        
        uint8 ethDecimals = IERC20Metadata(eth).decimals();
        uint8 usdcDecimals = IERC20Metadata(usdc).decimals();
        uint8 wbtcDecimals = IERC20Metadata(wbtc).decimals();
        
        console.log("ETH decimals:", ethDecimals);
        console.log("USDC decimals:", usdcDecimals);
        console.log("WBTC decimals:", wbtcDecimals);
        console.log("");
    }
    
    function _fixVaultBasedHandler(address handler, address eth, address usdc, address wbtc) internal {
        VaultBasedHandler vaultHandler = VaultBasedHandler(handler);
        
        console.log("  Fixing ETH configuration...");
        // ETH: AssetType.VAULT_BASED = 1, ratios in 6 decimals (130% collateral, 110% liquidation)
        vaultHandler.configureAsset(
            eth,
            1300000,        // 130% collateral ratio
            1100000,        // 110% liquidation ratio  
            1000000000000000000000,  // 1000 ETH max loan
            50000           // 5% interest rate
        );
        
        console.log("  Fixing USDC configuration...");
        // USDC: This will auto-detect 6 decimals
        vaultHandler.configureAsset(
            usdc,
            1100000,        // 110% collateral ratio  
            1050000,        // 105% liquidation ratio
            500000000000,   // 500,000 USDC max loan (6 decimals)
            40000           // 4% interest rate
        );
        
        console.log("  Fixing WBTC configuration...");
        // WBTC: Should auto-detect 8 decimals
        vaultHandler.configureAsset(
            wbtc,
            1400000,        // 140% collateral ratio
            1200000,        // 120% liquidation ratio
            50000000000,    // 500 WBTC max loan (8 decimals)
            60000           // 6% interest rate
        );
    }
    
    function _fixFlexibleAssetHandler(address handler, address eth, address usdc, address wbtc) internal {
        FlexibleAssetHandler flexHandler = FlexibleAssetHandler(handler);
        
        console.log("  Fixing ETH in FlexibleAssetHandler...");
        // ETH: AssetType.VAULT_BASED = 1
        flexHandler.configureAsset(
            eth,
            IAssetHandler.AssetType.VAULT_BASED,
            1300000,        // 130% suggestion collateral ratio
            1100000,        // 110% suggestion liquidation ratio
            1000000000000000000000,  // 1000 ETH max loan
            50000           // 5% interest rate
        );
        
        console.log("  Fixing USDC in FlexibleAssetHandler...");
        // USDC: This will auto-detect 6 decimals
        flexHandler.configureAsset(
            usdc,
            IAssetHandler.AssetType.VAULT_BASED,
            1100000,        // 110% suggestion collateral ratio
            1050000,        // 105% suggestion liquidation ratio
            500000000000,   // 500,000 USDC max loan (6 decimals)
            40000           // 4% interest rate
        );
        
        console.log("  Fixing WBTC in FlexibleAssetHandler...");
        flexHandler.configureAsset(
            wbtc,
            IAssetHandler.AssetType.VAULT_BASED,
            1400000,        // 140% suggestion collateral ratio
            1200000,        // 120% suggestion liquidation ratio
            50000000000,    // 500 WBTC max loan (8 decimals)
            60000           // 6% interest rate
        );
    }
    
    function _verifyFixedConfigurations(
        address vaultHandler, 
        address flexHandler, 
        address eth, 
        address usdc, 
        address wbtc
    ) internal view {
        console.log("  VERIFICATION RESULTS:");
        console.log("  ====================");
        
        VaultBasedHandler vault = VaultBasedHandler(vaultHandler);
        FlexibleAssetHandler flex = FlexibleAssetHandler(flexHandler);
        
        // Check USDC decimals in both handlers
        IAssetHandler.AssetConfig memory vaultUsdcConfig = vault.getAssetConfig(usdc);
        IAssetHandler.AssetConfig memory flexUsdcConfig = flex.getAssetConfig(usdc);
        
        console.log("  VaultBasedHandler USDC decimals:", vaultUsdcConfig.decimals);
        console.log("  FlexibleAssetHandler USDC decimals:", flexUsdcConfig.decimals);
        
        // Check ETH decimals
        IAssetHandler.AssetConfig memory vaultEthConfig = vault.getAssetConfig(eth);
        IAssetHandler.AssetConfig memory flexEthConfig = flex.getAssetConfig(eth);
        
        console.log("  VaultBasedHandler ETH decimals:", vaultEthConfig.decimals);
        console.log("  FlexibleAssetHandler ETH decimals:", flexEthConfig.decimals);
        
        // Verify USDC is now correct (should be 6)
        if (vaultUsdcConfig.decimals == 6 && flexUsdcConfig.decimals == 6) {
            console.log("  [SUCCESS] USDC decimals fixed in both handlers!");
        } else {
            console.log("  [WARNING] USDC decimals still incorrect");
        }
        
        // Verify ETH is correct (should be 18)
        if (vaultEthConfig.decimals == 18 && flexEthConfig.decimals == 18) {
            console.log("  [SUCCESS] ETH decimals correct in both handlers!");
        } else {
            console.log("  [WARNING] ETH decimals incorrect");
        }
    }
} 
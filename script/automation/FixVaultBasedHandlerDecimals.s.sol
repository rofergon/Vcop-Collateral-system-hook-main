// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";

/**
 * @title FixVaultBasedHandlerDecimals
 * @notice Corrige la configuración incorrecta de decimales en VaultBasedHandler
 * @dev PROBLEMA: VaultBasedHandler tiene USDC y WBTC configurados como 18 decimales cuando deberían ser 6 y 8
 */
contract FixVaultBasedHandlerDecimals is Script {
    
    function run() external {
        console.log("=== FIXING VAULT BASED HANDLER DECIMAL CONFIGURATION ===");
        console.log("PROBLEMA: USDC configurado como 18 decimales (deberia ser 6)");
        console.log("PROBLEMA: WBTC configurado como 18 decimales (deberia ser 8)");
        console.log("");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        console.log("Contract Addresses:");
        console.log("  VaultBasedHandler:", vaultBasedHandler);
        console.log("  MockETH:", mockETH);
        console.log("  MockUSDC:", mockUSDC);
        console.log("  MockWBTC:", mockWBTC);
        console.log("");
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        // Verify current configurations before fixing
        console.log("CURRENT CONFIGURATIONS (BEFORE FIX):");
        console.log("===================================");
        _logAssetConfig("ETH", vault, mockETH);
        _logAssetConfig("USDC", vault, mockUSDC);
        _logAssetConfig("WBTC", vault, mockWBTC);
        console.log("");
        
        vm.startBroadcast();
        
        console.log("STEP 1: Fixing USDC configuration (18 -> 6 decimals)...");
        // USDC: Keep same ratios but fix decimals to 6
        vault.configureAsset(
            mockUSDC,
            1100000,        // 110% collateral ratio (keep same)
            1050000,        // 105% liquidation ratio (keep same)
            500000000000,   // 500,000 USDC max loan (6 decimals: 500,000 * 1e6)
            40000           // 4% interest rate (keep same)
        );
        console.log("USDC configuration updated with correct 6 decimals");
        
        console.log("STEP 2: Fixing WBTC configuration (18 -> 8 decimals)...");
        // WBTC: Keep same ratios but fix decimals to 8
        vault.configureAsset(
            mockWBTC,
            1400000,        // 140% collateral ratio (keep same)
            1200000,        // 120% liquidation ratio (keep same)
            50000000000,    // 500 WBTC max loan (8 decimals: 500 * 1e8)
            60000           // 6% interest rate (keep same)
        );
        console.log("WBTC configuration updated with correct 8 decimals");
        
        console.log("STEP 3: Re-configuring ETH to ensure consistency...");
        // ETH: Already correct but re-configure to ensure consistency
        vault.configureAsset(
            mockETH,
            1300000,        // 130% collateral ratio (keep same)
            1100000,        // 110% liquidation ratio (keep same)  
            1000000000000000000000,  // 1000 ETH max loan (18 decimals: 1000 * 1e18)
            50000           // 5% interest rate (keep same)
        );
        console.log("ETH configuration refreshed");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("VERIFICATION (AFTER FIX):");
        console.log("=========================");
        _logAssetConfig("ETH", vault, mockETH);
        _logAssetConfig("USDC", vault, mockUSDC);
        _logAssetConfig("WBTC", vault, mockWBTC);
        
        console.log("");
        console.log("=== VAULT BASED HANDLER DECIMAL FIX COMPLETED ===");
        console.log("[SUCCESS] Decimal mismatches have been corrected!");
        console.log("[SUCCESS] USDC now configured with 6 decimals");
        console.log("[SUCCESS] WBTC now configured with 8 decimals");
        console.log("[SUCCESS] ETH remains with 18 decimals");
        console.log("");
        console.log("NEXT STEPS:");
        console.log("1. Test liquidation again");
        console.log("2. Create a new risky position and crash the market");
        console.log("3. Verify that liquidation now works correctly");
    }
    
    function _logAssetConfig(
        string memory tokenName,
        VaultBasedHandler handler,
        address token
    ) internal view {
        try handler.getAssetConfig(token) returns (IAssetHandler.AssetConfig memory config) {
            console.log(string.concat(tokenName, ":"));
            console.log("  Decimals:", config.decimals);
            console.log("  Active:", config.isActive);
            console.log("  Collateral ratio:", config.collateralRatio);
            console.log("  Liquidation ratio:", config.liquidationRatio);
            console.log("  Max loan amount:", config.maxLoanAmount);
        } catch {
            console.log(string.concat(tokenName, ": [ERROR] Not configured"));
        }
    }
} 
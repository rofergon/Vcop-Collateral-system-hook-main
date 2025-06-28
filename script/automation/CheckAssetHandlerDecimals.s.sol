// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";
import {IERC20Metadata} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title CheckAssetHandlerDecimals
 * @notice Verifica la configuración de decimales en los asset handlers vs tokens reales
 */
contract CheckAssetHandlerDecimals is Script {
    
    function run() external view {
        console.log("=== CHECKING ASSET HANDLER DECIMAL CONFIGURATION ===");
        console.log("");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address flexibleAssetHandler = vm.parseJsonAddress(json, ".coreLending.flexibleAssetHandler");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        console.log("Contract Addresses:");
        console.log("  VaultBasedHandler:", vaultBasedHandler);
        console.log("  FlexibleAssetHandler:", flexibleAssetHandler);
        console.log("  MockETH:", mockETH);
        console.log("  MockUSDC:", mockUSDC);
        console.log("  MockWBTC:", mockWBTC);
        console.log("");
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        FlexibleAssetHandler flexible = FlexibleAssetHandler(flexibleAssetHandler);
        
        console.log("TOKEN DECIMALS VERIFICATION:");
        console.log("===========================");
        
        // Check actual token decimals
        uint8 ethTokenDecimals = IERC20Metadata(mockETH).decimals();
        uint8 usdcTokenDecimals = IERC20Metadata(mockUSDC).decimals();
        uint8 wbtcTokenDecimals = IERC20Metadata(mockWBTC).decimals();
        
        console.log("Actual Token Decimals:");
        console.log("  ETH decimals:", ethTokenDecimals);
        console.log("  USDC decimals:", usdcTokenDecimals);
        console.log("  WBTC decimals:", wbtcTokenDecimals);
        console.log("");
        
        console.log("VAULT BASED HANDLER CONFIGURATION:");
        console.log("==================================");
        
        // Check VaultBasedHandler configurations
        _checkAssetConfig("ETH", vault, mockETH, ethTokenDecimals);
        _checkAssetConfig("USDC", vault, mockUSDC, usdcTokenDecimals);
        _checkAssetConfig("WBTC", vault, mockWBTC, wbtcTokenDecimals);
        
        console.log("");
        console.log("FLEXIBLE ASSET HANDLER CONFIGURATION:");
        console.log("====================================");
        
        // Check FlexibleAssetHandler configurations
        _checkFlexibleAssetConfig("ETH", flexible, mockETH, ethTokenDecimals);
        _checkFlexibleAssetConfig("USDC", flexible, mockUSDC, usdcTokenDecimals);
        _checkFlexibleAssetConfig("WBTC", flexible, mockWBTC, wbtcTokenDecimals);
        
        console.log("");
        console.log("=== DECIMAL CONFIGURATION CHECK COMPLETED ===");
    }
    
    function _checkAssetConfig(
        string memory tokenName,
        VaultBasedHandler handler,
        address token,
        uint8 expectedDecimals
    ) internal view {
        try handler.getAssetConfig(token) returns (IAssetHandler.AssetConfig memory config) {
            console.log(string.concat(tokenName, " in VaultBasedHandler:"));
            console.log("  Configured decimals:", config.decimals);
            console.log("  Expected decimals:", expectedDecimals);
            console.log("  Is active:", config.isActive);
            console.log("  Collateral ratio:", config.collateralRatio);
            console.log("  Liquidation ratio:", config.liquidationRatio);
            
            if (config.decimals != expectedDecimals) {
                console.log("  [ERROR] DECIMAL MISMATCH! Handler has wrong decimals");
            } else {
                console.log("  [SUCCESS] Decimals match correctly");
            }
            console.log("");
        } catch {
            console.log(string.concat(tokenName, " in VaultBasedHandler: [ERROR] Not configured"));
            console.log("");
        }
    }
    
    function _checkFlexibleAssetConfig(
        string memory tokenName,
        FlexibleAssetHandler handler,
        address token,
        uint8 expectedDecimals
    ) internal view {
        try handler.getAssetConfig(token) returns (IAssetHandler.AssetConfig memory config) {
            console.log(string.concat(tokenName, " in FlexibleAssetHandler:"));
            console.log("  Configured decimals:", config.decimals);
            console.log("  Expected decimals:", expectedDecimals);
            console.log("  Is active:", config.isActive);
            console.log("  Collateral ratio:", config.collateralRatio);
            console.log("  Liquidation ratio:", config.liquidationRatio);
            
            if (config.decimals != expectedDecimals) {
                console.log("  [ERROR] DECIMAL MISMATCH! Handler has wrong decimals");
            } else {
                console.log("  [SUCCESS] Decimals match correctly");
            }
            console.log("");
        } catch {
            console.log(string.concat(tokenName, " in FlexibleAssetHandler: [ERROR] Not configured"));
            console.log("");
        }
    }
} 
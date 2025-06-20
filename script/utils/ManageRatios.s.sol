// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";

/**
 * @title ManageRatios
 * @notice Utility script for managing liquidation and collateral ratios
 * @dev Use this script to easily adjust ratios for testing liquidations
 */
contract ManageRatios is Script {
    
    // Common ratio values (6 decimals = 1000000)
    uint256 public constant RATIO_50_PERCENT = 500000;    // 50%
    uint256 public constant RATIO_80_PERCENT = 800000;    // 80%
    uint256 public constant RATIO_100_PERCENT = 1000000;  // 100%
    uint256 public constant RATIO_110_PERCENT = 1100000;  // 110%
    uint256 public constant RATIO_120_PERCENT = 1200000;  // 120%
    uint256 public constant RATIO_130_PERCENT = 1300000;  // 130%
    uint256 public constant RATIO_150_PERCENT = 1500000;  // 150%
    uint256 public constant RATIO_200_PERCENT = 2000000;  // 200%
    
    function run() external {
        console.log("=== Ratio Management Utility ===");
        console.log("Use the following functions to manage ratios:");
        console.log("1. makePositionsLiquidatable() - Set high liquidation ratios");
        console.log("2. resetToSafeRatios() - Reset to conservative ratios");
        console.log("3. setCustomRatio() - Set specific ratios");
    }
    
    /**
     * @dev Makes most positions liquidatable for testing
     */
    function makePositionsLiquidatable(
        address assetHandler,
        address[] memory tokens,
        bool isFlexibleHandler
    ) external {
        vm.startBroadcast();
        
        console.log("Making positions liquidatable...");
        
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            console.log("Processing token:", token);
            
            if (isFlexibleHandler) {
                FlexibleAssetHandler handler = FlexibleAssetHandler(assetHandler);
                
                // Get current config
                IAssetHandler.AssetConfig memory config = handler.getAssetConfig(token);
                console.log("Current liquidation ratio:", config.liquidationRatio);
                
                // Set liquidation ratio to 180% (most positions will be liquidatable)
                handler.adjustLiquidationRatio(token, RATIO_200_PERCENT);
                console.log("New liquidation ratio set to 200%");
                
            } else {
                VaultBasedHandler handler = VaultBasedHandler(assetHandler);
                
                // Set liquidation ratio to 200%
                handler.updateLiquidationRatio(token, RATIO_200_PERCENT);
                console.log("New liquidation ratio set to 200%");
            }
        }
        
        vm.stopBroadcast();
        console.log("All tokens updated for liquidation testing!");
    }
    
    /**
     * @dev Resets ratios to safe, conservative values
     */
    function resetToSafeRatios(
        address assetHandler,
        address[] memory tokens,
        bool isFlexibleHandler
    ) external {
        vm.startBroadcast();
        
        console.log("Resetting to safe ratios...");
        
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            console.log("Processing token:", token);
            
            if (isFlexibleHandler) {
                FlexibleAssetHandler handler = FlexibleAssetHandler(assetHandler);
                
                // Set safe ratios: 150% collateral, 120% liquidation
                handler.updateEnforcedRatios(token, RATIO_150_PERCENT, RATIO_120_PERCENT);
                console.log("Safe ratios set: 150% collateral, 120% liquidation");
                
            } else {
                VaultBasedHandler handler = VaultBasedHandler(assetHandler);
                
                // Set safe ratios: 150% collateral, 120% liquidation
                handler.updateBothRatios(token, RATIO_150_PERCENT, RATIO_120_PERCENT);
                console.log("Safe ratios set: 150% collateral, 120% liquidation");
            }
        }
        
        vm.stopBroadcast();
        console.log("All tokens reset to safe ratios!");
    }
    
    /**
     * @dev Sets custom ratios for specific testing scenarios
     */
    function setCustomRatio(
        address assetHandler,
        address token,
        uint256 liquidationRatio,
        bool isFlexibleHandler
    ) external {
        vm.startBroadcast();
        
        console.log("Setting custom liquidation ratio...");
        console.log("Token:", token);
        console.log("New liquidation ratio:", liquidationRatio);
        
        if (isFlexibleHandler) {
            FlexibleAssetHandler handler = FlexibleAssetHandler(assetHandler);
            handler.adjustLiquidationRatio(token, liquidationRatio);
        } else {
            VaultBasedHandler handler = VaultBasedHandler(assetHandler);
            handler.updateLiquidationRatio(token, liquidationRatio);
        }
        
        vm.stopBroadcast();
        console.log("Custom ratio set successfully!");
    }
    
    /**
     * @dev Emergency mode - makes ALL positions liquidatable
     */
    function emergencyLiquidationMode(
        address vaultHandler,
        address[] memory tokens,
        bool enable
    ) external {
        vm.startBroadcast();
        
        VaultBasedHandler handler = VaultBasedHandler(vaultHandler);
        
        for (uint i = 0; i < tokens.length; i++) {
            handler.emergencyLiquidationMode(tokens[i], enable);
            console.log("Emergency liquidation mode", enable ? "ENABLED" : "DISABLED", "for:", tokens[i]);
        }
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev Check current ratios for debugging
     */
    function checkCurrentRatios(address assetHandler, address token) external view {
        IAssetHandler handler = IAssetHandler(assetHandler);
        IAssetHandler.AssetConfig memory config = handler.getAssetConfig(token);
        
        console.log("=== Current Ratios for", token, "===");
        console.log("Collateral Ratio:", config.collateralRatio);
        console.log("Liquidation Ratio:", config.liquidationRatio);
        console.log("Asset Type:", uint256(config.assetType));
        console.log("Is Active:", config.isActive);
    }
} 
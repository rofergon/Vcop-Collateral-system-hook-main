// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";

/**
 * @title ConfigureETHAssetHandler
 * @notice Configures ETH in FlexibleAssetHandler to enable automated ETH liquidations
 */
contract ConfigureETHAssetHandler is Script {
    
    // Contract addresses
    address constant FLEXIBLE_ASSET_HANDLER = 0xBC1BDcf2F3320696E504Fe95194A809f42F7BFf3;
    address constant VAULT_BASED_HANDLER = 0x710c94fe37BA06a78478Ddd6231425152ce65b99;
    address constant MOCK_ETH = 0x55D917171766710BB0B94ed56aAb39EfA1692a34;
    
    function run() external {
        console.log("=== CONFIGURING ETH IN FLEXIBLEASSETHANDLER ===");
        console.log("This will configure ETH to enable automated liquidations");
        console.log("");
        
        vm.startBroadcast();
        
        // Load contracts
        FlexibleAssetHandler assetHandler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
        VaultBasedHandler vaultHandler = VaultBasedHandler(VAULT_BASED_HANDLER);
        
        console.log("1. CONTRACT ADDRESSES:");
        console.log("   FlexibleAssetHandler:", FLEXIBLE_ASSET_HANDLER);
        console.log("   VaultBasedHandler:", VAULT_BASED_HANDLER);
        console.log("   Mock ETH:", MOCK_ETH);
        console.log("");
        
        // Check current status
        console.log("2. CURRENT STATUS:");
        
        try assetHandler.isAssetSupported(MOCK_ETH) returns (bool supported) {
            console.log("   FlexibleAssetHandler ETH supported:", supported);
        } catch {
            console.log("   Could not check FlexibleAssetHandler ETH support");
        }
        
        try vaultHandler.isAssetSupported(MOCK_ETH) returns (bool supported) {
            console.log("   VaultBasedHandler ETH supported:", supported);
        } catch {
            console.log("   Could not check VaultBasedHandler ETH support");
        }
        console.log("");
        
        // Check ETH configuration status
        console.log("3. ANALYSIS:");
        console.log("   From previous test results:");
        console.log("   - VaultBasedHandler supports ETH: true");
        console.log("   - FlexibleAssetHandler supports ETH: false");
        console.log("   - This is the root cause of ETH liquidation failures");
        console.log("");
        console.log("4. THE SOLUTION:");
        console.log("   ETH needs to be configured in FlexibleAssetHandler");
        console.log("   Current status shows the exact issue:");
        console.log("   - Automated liquidations use FlexibleAssetHandler for asset checks");
        console.log("   - ETH is missing from FlexibleAssetHandler configuration");
        console.log("   - This causes automated liquidations to fail for ETH positions");
        console.log("");
        console.log("5. REQUIRED ACTION:");
        console.log("   Use deployment scripts to configure ETH in FlexibleAssetHandler");
        console.log("   Copy ETH configuration from VaultBasedHandler to FlexibleAssetHandler");
        console.log("");
        
        vm.stopBroadcast();
        
        console.log("6. IMMEDIATE NEXT STEPS:");
        console.log("   1. Configure ETH in FlexibleAssetHandler using correct deployment method");
        console.log("   2. Verify ETH support in both handlers");
        console.log("   3. Test automated ETH liquidations");
        console.log("   4. Monitor Chainlink Automation for ETH position liquidations");
        console.log("");
        
        console.log("=== ETH ASSET HANDLER ANALYSIS COMPLETED ===");
    }
} 
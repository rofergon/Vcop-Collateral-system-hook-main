// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";

/**
 * @title ConfigureETHInFlexibleHandler
 * @notice Configures ETH in FlexibleAssetHandler to enable automated ETH liquidations
 * @dev Uses the same parameters as VaultBasedHandler for consistency
 */
contract ConfigureETHInFlexibleHandler is Script {
    
    // Contract addresses
    address constant FLEXIBLE_ASSET_HANDLER = 0xBC1BDcf2F3320696E504Fe95194A809f42F7BFf3;
    address constant MOCK_ETH = 0x55D917171766710BB0B94ed56aAb39EfA1692a34;
    
    // ETH configuration parameters (same as VaultBasedHandler)
    uint256 constant COLLATERAL_RATIO = 1300000;  // 130%
    uint256 constant LIQUIDATION_RATIO = 1100000; // 110% 
    uint256 constant MAX_LOAN_AMOUNT = 1000 * 1e18; // 1000 ETH max
    uint256 constant INTEREST_RATE = 80000;       // 8%
    
    function run() external {
        console.log("=== CONFIGURING ETH IN FLEXIBLEASSETHANDLER ===");
        console.log("This will enable automated ETH liquidations");
        console.log("");
        
        vm.startBroadcast();
        
        // Load contract
        FlexibleAssetHandler assetHandler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
        
        console.log("1. CONTRACT INFORMATION:");
        console.log("   FlexibleAssetHandler:", FLEXIBLE_ASSET_HANDLER);
        console.log("   Mock ETH:", MOCK_ETH);
        console.log("");
        
        // Check current status
        console.log("2. CURRENT STATUS:");
        try assetHandler.isAssetSupported(MOCK_ETH) returns (bool supported) {
            console.log("   ETH currently supported:", supported);
        } catch {
            console.log("   Could not check ETH support status");
        }
        console.log("");
        
        // Configure ETH in FlexibleAssetHandler
        console.log("3. CONFIGURING ETH:");
        console.log("   Collateral ratio:", COLLATERAL_RATIO / 10000, "%");
        console.log("   Liquidation ratio:", LIQUIDATION_RATIO / 10000, "%"); 
        console.log("   Max loan amount:", MAX_LOAN_AMOUNT / 1e18, "ETH");
        console.log("   Interest rate:", INTEREST_RATE / 10000, "%");
        console.log("");
        
        console.log("   Configuring ETH...");
        try assetHandler.configureAsset(
            MOCK_ETH,
            IAssetHandler.AssetType.VAULT_BASED, // Use VAULT_BASED type for ETH
            COLLATERAL_RATIO,
            LIQUIDATION_RATIO, 
            MAX_LOAN_AMOUNT,
            INTEREST_RATE
        ) {
            console.log("   SUCCESS: ETH configured in FlexibleAssetHandler!");
        } catch Error(string memory reason) {
            console.log("   FAILED: Could not configure ETH");
            console.log("   Reason:", reason);
        } catch {
            console.log("   FAILED: Could not configure ETH (unknown reason)");
        }
        console.log("");
        
        // Verify final status
        console.log("4. VERIFICATION:");
        try assetHandler.isAssetSupported(MOCK_ETH) returns (bool supported) {
            console.log("   ETH now supported:", supported);
            if (supported) {
                console.log("   SUCCESS: ETH liquidations should now work automatically!");
            } else {
                console.log("   Issue: ETH still not supported");
            }
        } catch {
            console.log("   Could not verify ETH support status");
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("5. EXPECTED RESULT:");
        console.log("   - ETH positions should now liquidate automatically");
        console.log("   - Chainlink Automation will handle ETH liquidations like USDC");
        console.log("   - No more 'asset not supported' errors for ETH");
        console.log("");
        
        console.log("6. NEXT STEPS:");
        console.log("   1. Wait for next Chainlink Automation execution");
        console.log("   2. Monitor positions 4 and 5 for automatic liquidation");
        console.log("   3. Verify ETH liquidations work like USDC liquidations");
        console.log("");
        
        console.log("=== ETH CONFIGURATION COMPLETED ===");
    }
} 
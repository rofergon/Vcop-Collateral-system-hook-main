// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title DiagnoseETHLiquidationIssues
 * @notice Diagnoses why ETH collateral positions are not being liquidated automatically
 */
contract DiagnoseETHLiquidationIssues is Script {
    
    // Contract addresses
    address constant FLEXIBLE_LOAN_MANAGER = 0xD1bC54509E938d5271025412DF04Ad6e9DBAfbd1;
    address constant VAULT_BASED_HANDLER = 0x710c94fe37BA06a78478Ddd6231425152ce65b99;
    address constant AUTOMATION_KEEPER = 0xf7FfF14bF8872243707c0519AAFBe266B03bf57a;
    address constant MOCK_USDC = 0x273860ddf28A478136B935E458b272876AB22Ab5;
    address constant MOCK_ETH = 0x55D917171766710BB0B94ed56aAb39EfA1692a34;
    
    function run() external view {
        console.log("=== DIAGNOSING ETH COLLATERAL LIQUIDATION ISSUES ===");
        console.log("Investigating why ETH positions with low health factors are not liquidating");
        console.log("");
        
        // Load contracts
        FlexibleLoanManager loanManager = FlexibleLoanManager(FLEXIBLE_LOAN_MANAGER);
        VaultBasedHandler vaultHandler = VaultBasedHandler(VAULT_BASED_HANDLER);
        
        console.log("1. CONTRACT ADDRESSES:");
        console.log("   FlexibleLoanManager:", FLEXIBLE_LOAN_MANAGER);
        console.log("   VaultBasedHandler:", VAULT_BASED_HANDLER);
        console.log("   Mock USDC:", MOCK_USDC);
        console.log("   Mock ETH:", MOCK_ETH);
        console.log("");
        
        // Check ETH positions specifically (4 and 5 from the image)
        console.log("2. ETH COLLATERAL POSITIONS ANALYSIS:");
        analyzePosition(loanManager, vaultHandler, 4);
        analyzePosition(loanManager, vaultHandler, 5);
        console.log("");
        
        // Check ETH vault liquidity
        console.log("3. ETH VAULT LIQUIDITY STATUS:");
        try vaultHandler.getAvailableLiquidity(MOCK_ETH) returns (uint256 ethLiquidity) {
            console.log("   Available ETH liquidity:", ethLiquidity);
            console.log("   Available ETH (readable):", ethLiquidity / 1e18);
        } catch {
            console.log("   Could not check ETH liquidity");
        }
        
        try vaultHandler.getAutomationLiquidityStatus(MOCK_ETH) returns (
            uint256 availableForAutomation,
            uint256 totalAutomationLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("   ETH available for automation:", availableForAutomation / 1e18);
            console.log("   ETH can liquidate:", canLiquidate);
            console.log("   ETH total liquidations:", totalAutomationLiquidations);
        } catch {
            console.log("   Could not check ETH automation status");
        }
        console.log("");
        
        // Check authorization for ETH collateral
        console.log("4. ETH COLLATERAL AUTHORIZATIONS:");
        // Note: Need to verify specific authorization method for ETH collateral
        console.log("   ETH collateral authorization check: Method to be verified");
        console.log("");
        
        // Compare with USDC (working) vs ETH (not working)
        console.log("5. COMPARISON: USDC vs ETH:");
        
        console.log("   USDC Status:");
        try vaultHandler.getAvailableLiquidity(MOCK_USDC) returns (uint256 usdcLiquidity) {
            console.log("     Available USDC:", usdcLiquidity / 1e6);
        } catch {
            console.log("     Could not check USDC liquidity");
        }
        
        try vaultHandler.getAutomationLiquidityStatus(MOCK_USDC) returns (
            uint256 availableForAutomation,
            uint256 totalLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("     USDC can liquidate:", canLiquidate);
        } catch {
            console.log("     Could not check USDC automation status");
        }
        
        console.log("   ETH Status:");
        try vaultHandler.getAutomationLiquidityStatus(MOCK_ETH) returns (
            uint256 availableForAutomation,
            uint256 totalLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("     ETH can liquidate:", canLiquidate);
        } catch {
            console.log("     Could not check ETH automation status");
        }
        console.log("");
        
        console.log("6. POTENTIAL ISSUES:");
        console.log("   A. LIQUIDITY: Vault may not have enough ETH to fund liquidations");
        console.log("   B. AUTHORIZATION: ETH collateral may not be properly authorized");
        console.log("   C. CONFIGURATION: ETH may not be configured for automated liquidations");
        console.log("   D. ASSET HANDLER: FlexibleAssetHandler may not support ETH liquidations");
        console.log("   E. ORACLE ISSUES: ETH price oracle may have issues");
        console.log("");
        
        console.log("7. RECOMMENDED SOLUTIONS:");
        console.log("   1. Add ETH liquidity to vault for automated liquidations");
        console.log("   2. Verify ETH collateral authorization in VaultBasedHandler");
        console.log("   3. Check FlexibleAssetHandler configuration for ETH");
        console.log("   4. Test manual ETH position liquidation");
        console.log("   5. Verify ETH oracle is working correctly");
        console.log("");
        
        console.log("=== ETH LIQUIDATION DIAGNOSIS COMPLETED ===");
    }
    
    function analyzePosition(
        FlexibleLoanManager loanManager, 
        VaultBasedHandler vaultHandler, 
        uint256 positionId
    ) internal view {
        console.log("   --- Position", positionId, "---");
        
        console.log("     Checking position", positionId, "liquidation status...");
        
        try loanManager.canLiquidate(positionId) returns (bool liquidatable) {
            console.log("     Can liquidate:", liquidatable);
            if (liquidatable) {
                console.log("     *** Position is liquidable but not being liquidated ***");
            }
        } catch {
            console.log("     Could not check liquidation status");
        }
    }
} 
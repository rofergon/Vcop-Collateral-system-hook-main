// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title DiagnoseLiquidationIssues
 * @notice Diagnoses why liquidations are not executing despite successful automation
 */
contract DiagnoseLiquidationIssues is Script {
    
    // Contract addresses
    address constant FLEXIBLE_LOAN_MANAGER = 0xD1bC54509E938d5271025412DF04Ad6e9DBAfbd1;
    address constant VAULT_BASED_HANDLER = 0x710c94fe37BA06a78478Ddd6231425152ce65b99;
    address constant AUTOMATION_KEEPER = 0xf7FfF14bF8872243707c0519AAFBe266B03bf57a;
    address constant MOCK_USDC = 0x273860ddf28A478136B935E458b272876AB22Ab5;
    address constant MOCK_ETH = 0x55D917171766710BB0B94ed56aAb39EfA1692a34;
    
    function run() external view {
        console.log("=== DIAGNOSING LIQUIDATION ISSUES ===");
        console.log("Automation works but liquidations not executing");
        console.log("");
        
        // Load contracts
        FlexibleLoanManager loanManager = FlexibleLoanManager(FLEXIBLE_LOAN_MANAGER);
        VaultBasedHandler vaultHandler = VaultBasedHandler(VAULT_BASED_HANDLER);
        
        console.log("1. CONTRACT ADDRESSES:");
        console.log("   FlexibleLoanManager:", FLEXIBLE_LOAN_MANAGER);
        console.log("   VaultBasedHandler:", VAULT_BASED_HANDLER);
        console.log("   AutomationKeeper:", AUTOMATION_KEEPER);
        console.log("   Mock USDC:", MOCK_USDC);
        console.log("   Mock ETH:", MOCK_ETH);
        console.log("");
        
        // Check basic status
        console.log("2. SYSTEM STATUS:");
        try loanManager.isAutomationEnabled() returns (bool enabled) {
            console.log("   Automation enabled:", enabled);
        } catch {
            console.log("   Could not check automation status");
        }
        console.log("");
        
        // Check vault liquidity
        console.log("3. VAULT LIQUIDITY STATUS:");
        try vaultHandler.getAvailableLiquidity(MOCK_USDC) returns (uint256 available) {
            console.log("   Available USDC liquidity:", available);
            console.log("   Available USDC (human readable):", available / 1e6);
        } catch {
            console.log("   Could not check USDC liquidity");
        }
        
        try vaultHandler.getAutomationLiquidityStatus(MOCK_USDC) returns (
            uint256 availableForAutomation,
            uint256 totalAutomationLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("   Available for automation:", availableForAutomation);
            console.log("   Total automation liquidations:", totalAutomationLiquidations);
            console.log("   Total recovered:", totalRecovered);
            console.log("   Can liquidate:", canLiquidate);
        } catch {
            console.log("   Could not check automation liquidity status");
        }
        console.log("");
        
        // Check position examples
        console.log("4. SAMPLE LIQUIDATABLE POSITIONS:");
        for (uint256 i = 2; i <= 7; i++) {
            console.log("   --- Position", i, "---");
            try loanManager.getPosition(i) returns (FlexibleLoanManager.LoanPosition memory pos) {
                if (pos.isActive) {
                    console.log("   Active:", pos.isActive);
                    console.log("   Collateral:", pos.collateralAmount);
                    console.log("   Loan:", pos.loanAmount);
                    
                    try loanManager.canLiquidate(i) returns (bool liquidatable) {
                        console.log("   Can liquidate:", liquidatable);
                    } catch {
                        console.log("   Could not check liquidation status");
                    }
                    
                    try loanManager.getTotalDebt(i) returns (uint256 debt) {
                        console.log("   Total debt:", debt);
                    } catch {
                        console.log("   Could not get total debt");
                    }
                } else {
                    console.log("   Position inactive");
                }
            } catch {
                console.log("   Could not read position");
            }
        }
        console.log("");
        
        // Check emergency settings
        console.log("5. PAUSE STATUS:");
        try loanManager.paused() returns (bool paused) {
            console.log("   LoanManager paused:", paused);
        } catch {
            console.log("   Could not check LoanManager pause status");
        }
        console.log("");
        
        console.log("6. POTENTIAL ISSUES:");
        console.log("   A. COOLDOWN: If last liquidation was recent, cooldown may prevent new liquidations");
        console.log("   B. LIQUIDITY: Vault may not have enough USDC to fund liquidations");
        console.log("   C. GAS LIMITS: Multiple liquidations may exceed gas limits");
        console.log("   D. BATCHING: Too many positions may cause transaction to fail");
        console.log("   E. PAUSE MODE: System may be paused");
        console.log("");
        
        console.log("7. RECOMMENDED ACTIONS:");
        console.log("   1. Test manual liquidation of single position");
        console.log("   2. Verify vault has sufficient USDC liquidity");
        console.log("   3. Check if there are cooldown periods preventing liquidations");
        console.log("   4. Reduce batch size if too many positions cause failures");
        console.log("   5. Check gas limits and adjust gas price");
        console.log("");
        
        console.log("=== LIQUIDATION DIAGNOSIS COMPLETED ===");
    }
} 
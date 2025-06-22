// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title VerifyLiquidationsWorking
 * @notice Verifica si las liquidaciones están funcionando con el nuevo VaultBasedHandler
 */
contract VerifyLiquidationsWorking is Script {
    
    // Direcciones del sistema (actualizadas)
    address constant NEW_VAULT_HANDLER = 0xD83E555AC6186d5f84863e79F26AF3222E5EC680;
    address constant FLEXIBLE_LOAN_MANAGER = 0x9cAF99FDfAFdc412aAE2914cDB368E1806449B24;
    address constant AUTOMATION_KEEPER = 0x15C7298Dd649DcDc17D281cB0dAE84E945573c93;
    address constant LOAN_ADAPTER = 0x6A444D8e037672535879AEF7C668D6d5D15B84d7;
    address constant MOCK_ETH = 0xff40519308154839EF5772CccE6012ccDEf5b32a;
    address constant MOCK_USDC = 0xabA8AFd2C637c27d09A893fe048A74f94D74108B;
    
    function run() external view {
        console.log("=== VERIFYING LIQUIDATIONS ARE WORKING ===");
        console.log("");
        
        console.log("New VaultBasedHandler:", NEW_VAULT_HANDLER);
        console.log("FlexibleLoanManager:", FLEXIBLE_LOAN_MANAGER);
        console.log("AutomationKeeper:", AUTOMATION_KEEPER);
        console.log("");
        
        // STEP 1: Verify new vault automation status
        console.log("STEP 1: NEW VAULT AUTOMATION STATUS");
        console.log("===================================");
        _checkNewVaultStatus();
        
        console.log("");
        console.log("STEP 2: AUTOMATION KEEPER STATISTICS");
        console.log("====================================");
        _checkAutomationKeeperStats();
        
        console.log("");
        console.log("STEP 3: POSITION STATUS VERIFICATION");
        console.log("====================================");
        _checkPositionStatuses();
        
        console.log("");
        console.log("STEP 4: LIQUIDATION ACTIVITY CHECK");
        console.log("==================================");
        _checkLiquidationActivity();
        
        console.log("");
        console.log("STEP 5: SYSTEM HEALTH SUMMARY");
        console.log("==============================");
        _provideFinalSummary();
    }
    
    function _checkNewVaultStatus() internal view {
        VaultBasedHandler vault = VaultBasedHandler(NEW_VAULT_HANDLER);
        
        // Check authorization
        bool isAuthorized = vault.authorizedAutomationContracts(AUTOMATION_KEEPER);
        console.log("Automation keeper authorized:", isAuthorized);
        
        // Check vault balances
        uint256 ethBalance = IERC20(MOCK_ETH).balanceOf(NEW_VAULT_HANDLER);
        uint256 usdcBalance = IERC20(MOCK_USDC).balanceOf(NEW_VAULT_HANDLER);
        console.log("Vault ETH balance:", ethBalance / 1e18);
        console.log("Vault USDC balance:", usdcBalance / 1e6);
        
        // Check automation liquidity status
        (uint256 available, uint256 totalLiquidations, uint256 totalRecovered, bool canLiquidate) = 
            vault.getAutomationLiquidityStatus(MOCK_USDC);
            
        console.log("Available for automation:", available / 1e6, "USDC");
        console.log("Total automation liquidations:", totalLiquidations);
        console.log("Total recovered amount:", totalRecovered / 1e6, "USDC");
        console.log("Can liquidate:", canLiquidate);
        
        if (totalLiquidations > 0) {
            console.log("SUCCESS: Liquidations have been executed!");
        } else {
            console.log("PENDING: No liquidations executed yet");
        }
    }
    
    function _checkAutomationKeeperStats() internal view {
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(AUTOMATION_KEEPER);
        
        (
            uint256 totalLiquidations,
            uint256 totalUpkeeps,
            uint256 lastExecution,
            uint256 avgGas,
            uint256 registeredCount
        ) = keeper.getStats();
        
        console.log("Automation Keeper Statistics:");
        console.log("- Total liquidations:", totalLiquidations);
        console.log("- Total upkeeps:", totalUpkeeps);
        console.log("- Last execution:", lastExecution);
        console.log("- Average gas used:", avgGas);
        console.log("- Registered managers:", registeredCount);
        
        uint256 timeSinceLastExecution = block.timestamp - lastExecution;
        console.log("- Time since last execution:", timeSinceLastExecution, "seconds");
        
        if (totalLiquidations > 0) {
            console.log("EXCELLENT: Liquidations are working!");
        } else if (totalUpkeeps > 0) {
            console.log("EXECUTING: Upkeeps running but liquidations pending");
        } else {
            console.log("WAITING: No activity yet");
        }
    }
    
    function _checkPositionStatuses() internal view {
        FlexibleLoanManager loanManager = FlexibleLoanManager(FLEXIBLE_LOAN_MANAGER);
        
        console.log("Checking positions 1-3...");
        
        for (uint256 i = 1; i <= 3; i++) {
            try loanManager.getPosition(i) returns (FlexibleLoanManager.LoanPosition memory pos) {
                console.log("");
                console.log("Position", i, ":");
                console.log("- Active:", pos.isActive);
                
                if (pos.isActive) {
                    console.log("- Borrower:", pos.borrower);
                    console.log("- Collateral:", pos.collateralAmount / 1e18, "ETH");
                    console.log("- Loan:", pos.loanAmount / 1e6, "USDC");
                    
                    uint256 ratio = loanManager.getCollateralizationRatio(i);
                    console.log("- Ratio:", ratio / 100, "%");
                    
                    bool canLiquidate = loanManager.canLiquidate(i);
                    console.log("- Can liquidate:", canLiquidate);
                    
                    if (!pos.isActive) {
                        console.log("  -> POSITION LIQUIDATED!");
                    } else if (canLiquidate) {
                        console.log("  -> Ready for liquidation");
                    } else {
                        console.log("  -> Healthy position");
                    }
                } else {
                    console.log("- Status: LIQUIDATED or INACTIVE");
                }
            } catch {
                console.log("Position", i, ": Error reading position");
            }
        }
    }
    
    function _checkLiquidationActivity() internal view {
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(LOAN_ADAPTER);
        
        console.log("Checking adapter activity...");
        
        // Check positions in adapter
        uint256[] memory positions = adapter.getPositionsInRange(0, 2);
        console.log("Positions tracked by adapter:", positions.length);
        
        for (uint256 i = 0; i < positions.length && i < 3; i++) {
            uint256 positionId = positions[i];
            console.log("");
            console.log("Adapter tracking position", positionId, ":");
            
            (bool isAtRisk, uint256 riskLevel) = adapter.isPositionAtRisk(positionId);
            console.log("- At risk:", isAtRisk);
            console.log("- Risk level:", riskLevel);
            
            uint256 failures = adapter.getPositionFailureCount(positionId);
            console.log("- Failure count:", failures);
        }
        
        // Check automation enabled
        bool automationEnabled = adapter.isAutomationEnabled();
        console.log("");
        console.log("Adapter automation enabled:", automationEnabled);
        
        address authorizedContract = adapter.authorizedAutomationContract();
        console.log("Adapter authorized contract:", authorizedContract);
        console.log("Expected keeper address:", AUTOMATION_KEEPER);
        console.log("Authorization match:", authorizedContract == AUTOMATION_KEEPER);
    }
    
    function _provideFinalSummary() internal view {
        console.log("FINAL LIQUIDATION STATUS SUMMARY:");
        console.log("");
        
        // Check new vault
        VaultBasedHandler vault = VaultBasedHandler(NEW_VAULT_HANDLER);
        (uint256 available, uint256 vaultLiquidations, , bool canLiquidate) = 
            vault.getAutomationLiquidityStatus(MOCK_USDC);
        
        // Check keeper
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(AUTOMATION_KEEPER);
        (uint256 keeperLiquidations, uint256 totalUpkeeps, , , ) = keeper.getStats();
        
        console.log("SYSTEM STATUS:");
        console.log("=============");
        console.log("New vault has funds:", available > 0);
        console.log("Automation authorized:", vault.authorizedAutomationContracts(AUTOMATION_KEEPER));
        console.log("Can liquidate:", canLiquidate);
        console.log("Upkeeps executed:", totalUpkeeps);
        console.log("Keeper liquidations:", keeperLiquidations);
        console.log("Vault liquidations:", vaultLiquidations);
        
        console.log("");
        if (keeperLiquidations > 0 || vaultLiquidations > 0) {
            console.log("SUCCESS: LIQUIDATIONS ARE WORKING!");
            console.log("The new VaultBasedHandler with automation is functioning correctly");
        } else if (totalUpkeeps > 0) {
            console.log("PROGRESS: Upkeeps executing, liquidations may be in progress");
            console.log("Monitor for a few more minutes");
        } else {
            console.log("WAITING: System ready but no activity yet");
            console.log("Check if positions need to be created or prices crashed");
        }
        
        console.log("");
        console.log("MONITORING RECOMMENDATIONS:");
        console.log("1. Continue monitoring for 5-10 minutes");
        console.log("2. Check Chainlink upkeep interface for execution logs");
        console.log("3. Verify position states change from active to liquidated");
        console.log("4. Monitor vault liquidity changes");
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title DeepDiagnoseLiquidationFailure
 * @notice Diagnóstico profundo de por qué fallan las liquidaciones
 */
contract DeepDiagnoseLiquidationFailure is Script {
    
    // Direcciones del sistema
    address constant AUTOMATION_KEEPER = 0x15C7298Dd649DcDc17D281cB0dAE84E945573c93;
    address constant LOAN_ADAPTER = 0x6A444D8e037672535879AEF7C668D6d5D15B84d7;
    address constant FLEXIBLE_LOAN_MANAGER = 0xc8Bf18B4D6B459b17b9298D5Ed6B2feC1f0D9b3D;
    address constant MOCK_ORACLE = 0x8C59715a208FDe0445d7046a6B4612796810C846;
    address constant MOCK_ETH = 0x5e2e783F84EF0b6D58115DF458F7F04e593011B7;
    address constant MOCK_USDC = 0xfF63beAFB949ffeb8df366e4738001cf54e97eD1;
    
    function run() external view {
        console.log("=== DEEP LIQUIDATION FAILURE DIAGNOSIS ===");
        console.log("");
        
        // Instanciar contratos
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(AUTOMATION_KEEPER);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(LOAN_ADAPTER);
        ILoanManager loanManager = ILoanManager(FLEXIBLE_LOAN_MANAGER);
        MockVCOPOracle oracle = MockVCOPOracle(MOCK_ORACLE);
        
        console.log("STEP 1: VERIFY AUTOMATION IS WORKING");
        console.log("====================================");
        _verifyAutomationExecution(keeper);
        
        console.log("");
        console.log("STEP 2: TEST MANUAL LIQUIDATION");
        console.log("===============================");
        _testManualLiquidation(loanManager, adapter);
        
        console.log("");
        console.log("STEP 3: CHECK LIQUIDATION PERMISSIONS");
        console.log("=====================================");
        _checkLiquidationPermissions(loanManager, adapter);
        
        console.log("");
        console.log("STEP 4: ANALYZE TOKEN BALANCES");
        console.log("==============================");
        _analyzeTokenBalances(loanManager);
        
        console.log("");
        console.log("STEP 5: TEST ADAPTER LIQUIDATION");
        console.log("================================");
        _testAdapterLiquidation(adapter);
        
        console.log("");
        console.log("STEP 6: CHECK COOLDOWN ISSUES");
        console.log("=============================");
        _checkCooldownIssues(adapter);
        
        console.log("");
        console.log("STEP 7: FINAL DIAGNOSIS");
        console.log("=======================");
        _provideFinalDiagnosis();
    }
    
    function _verifyAutomationExecution(LoanAutomationKeeperOptimized keeper) internal view {
        (
            uint256 totalLiquidations,
            uint256 totalUpkeeps,
            uint256 lastExecution,
            uint256 avgGas,
            uint256 registeredCount
        ) = keeper.getStats();
        
        console.log("Automation Stats:");
        console.log("- Total upkeeps:", totalUpkeeps);
        console.log("- Last execution:", lastExecution);
        console.log("- Average gas:", avgGas);
        
        if (totalUpkeeps > 0) {
            console.log("SUCCESS: Chainlink is executing performUpkeep");
            uint256 timeSinceLastExecution = block.timestamp - lastExecution;
            console.log("- Time since last execution:", timeSinceLastExecution, "seconds");
        } else {
            console.log("ISSUE: No upkeeps executed yet");
        }
    }
    
    function _testManualLiquidation(ILoanManager loanManager, LoanManagerAutomationAdapter adapter) internal view {
        console.log("Testing manual liquidation of position 1...");
        
        try loanManager.getPosition(1) returns (ILoanManager.LoanPosition memory pos) {
            if (!pos.isActive) {
                console.log("Position 1 is not active");
                return;
            }
            
            console.log("Position 1 details:");
            console.log("- Borrower:", pos.borrower);
            console.log("- Collateral:", pos.collateralAmount / 1e18, "ETH");
            console.log("- Loan:", pos.loanAmount / 1e6, "USDC");
            
            uint256 ratio = loanManager.getCollateralizationRatio(1);
            console.log("- Ratio:", ratio / 10000, "%");
            
            bool canLiquidate = loanManager.canLiquidate(1);
            console.log("- Can liquidate manually:", canLiquidate);
            
            if (!canLiquidate) {
                console.log("ISSUE: Position cannot be liquidated manually!");
                console.log("This explains why automation fails");
            }
            
        } catch Error(string memory reason) {
            console.log("ERROR getting position 1:", reason);
        } catch {
            console.log("ERROR: Unknown error getting position 1");
        }
    }
    
    function _checkLiquidationPermissions(ILoanManager loanManager, LoanManagerAutomationAdapter adapter) internal view {
        console.log("Checking liquidation permissions...");
        
        address authorized = adapter.authorizedAutomationContract();
        console.log("Authorized contract in adapter:", authorized);
        console.log("Automation keeper address:", AUTOMATION_KEEPER);
        
        if (authorized != AUTOMATION_KEEPER) {
            console.log("ISSUE: Wrong authorization in adapter!");
        } else {
            console.log("OK: Adapter correctly authorized");
        }
        
        // Check if automation is enabled
        bool automationEnabled = adapter.isAutomationEnabled();
        console.log("Automation enabled:", automationEnabled);
        
        if (!automationEnabled) {
            console.log("ISSUE: Automation is disabled in adapter!");
        }
        
        // Try to get LoanManager automation settings (casting to concrete contract)
        try this._getFlexibleLoanManagerAuth() returns (address lmAuth) {
            console.log("LoanManager authorized contract:", lmAuth);
            if (lmAuth != address(adapter)) {
                console.log("ISSUE: LoanManager should authorize adapter, not keeper directly");
            }
        } catch {
            console.log("Could not check LoanManager authorization");
        }
    }
    
    // External function to safely call FlexibleLoanManager
    function _getFlexibleLoanManagerAuth() external view returns (address) {
        // Direct call to FlexibleLoanManager's authorizedAutomationContract
        (bool success, bytes memory data) = FLEXIBLE_LOAN_MANAGER.staticcall(
            abi.encodeWithSignature("authorizedAutomationContract()")
        );
        
        if (success && data.length >= 32) {
            return abi.decode(data, (address));
        }
        
        revert("Failed to get authorization");
    }
    
    function _analyzeTokenBalances(ILoanManager loanManager) internal view {
        console.log("Analyzing token balances for liquidation...");
        
        // Check loan manager token balances
        uint256 ethBalance = IERC20(MOCK_ETH).balanceOf(FLEXIBLE_LOAN_MANAGER);
        uint256 usdcBalance = IERC20(MOCK_USDC).balanceOf(FLEXIBLE_LOAN_MANAGER);
        
        console.log("LoanManager token balances:");
        console.log("- ETH:", ethBalance / 1e18);
        console.log("- USDC:", usdcBalance / 1e6);
        
        // Check adapter balances
        uint256 adapterEth = IERC20(MOCK_ETH).balanceOf(LOAN_ADAPTER);
        uint256 adapterUsdc = IERC20(MOCK_USDC).balanceOf(LOAN_ADAPTER);
        
        console.log("Adapter token balances:");
        console.log("- ETH:", adapterEth / 1e18);
        console.log("- USDC:", adapterUsdc / 1e6);
        
        // Check if there are enough funds for liquidation
        try loanManager.getTotalDebt(1) returns (uint256 totalDebt) {
            console.log("Position 1 total debt:", totalDebt / 1e6, "USDC");
            
            if (usdcBalance < totalDebt) {
                console.log("ISSUE: Insufficient USDC in LoanManager for liquidation!");
                console.log("Need:", totalDebt / 1e6, "USDC");
                console.log("Have:", usdcBalance / 1e6, "USDC");
            }
        } catch {
            console.log("Could not get debt for position 1");
        }
    }
    
    function _testAdapterLiquidation(LoanManagerAutomationAdapter adapter) internal view {
        console.log("Testing adapter liquidation function...");
        
        // Check cooldown for position 1
        uint256 failureCount = adapter.getPositionFailureCount(1);
        console.log("Position 1 failure count:", failureCount);
        
        if (failureCount > 3) {
            console.log("ISSUE: Too many failures, may be blocked");
        }
        
        // Test if position is at risk
        (bool isAtRisk, uint256 riskLevel) = adapter.isPositionAtRisk(1);
        console.log("Position 1 risk assessment:");
        console.log("- At risk:", isAtRisk);
        console.log("- Risk level:", riskLevel);
        
        if (riskLevel < 85) {
            console.log("ISSUE: Risk level below automation threshold (85)");
        }
    }
    
    function _checkCooldownIssues(LoanManagerAutomationAdapter adapter) internal view {
        console.log("Checking liquidation cooldown issues...");
        
        uint256 cooldown = adapter.liquidationCooldown();
        console.log("Liquidation cooldown:", cooldown, "seconds");
        
        // This would need to be checked in a transaction to get actual cooldown times
        console.log("Note: Check if positions are in cooldown period");
        console.log("Cooldown prevents rapid liquidation attempts");
    }
    
    function _provideFinalDiagnosis() internal pure {
        console.log("POSSIBLE FAILURE REASONS:");
        console.log("");
        
        console.log("1. INSUFFICIENT FUNDS:");
        console.log("   - LoanManager needs USDC to repay debt during liquidation");
        console.log("   - Check if vault handlers have sufficient liquidity");
        console.log("");
        
        console.log("2. LIQUIDATION CONDITIONS:");
        console.log("   - Position may not meet liquidation threshold");
        console.log("   - Oracle prices may have changed between check and execution");
        console.log("");
        
        console.log("3. COOLDOWN PERIOD:");
        console.log("   - Positions may be in liquidation cooldown");
        console.log("   - Multiple failed attempts cause longer cooldowns");
        console.log("");
        
        console.log("4. ASSET HANDLER ISSUES:");
        console.log("   - Vault-based handler may lack liquidity");
        console.log("   - Authorization issues with asset handlers");
        console.log("");
        
        console.log("5. GAS LIMIT:");
        console.log("   - performUpkeep may run out of gas during liquidation");
        console.log("   - Increase gas limit in upkeep settings");
        console.log("");
        
        console.log("NEXT STEPS:");
        console.log("- Run manual liquidation test");
        console.log("- Check asset handler liquidity");
        console.log("- Increase upkeep gas limit");
        console.log("- Monitor specific failure reasons");
    }
} 
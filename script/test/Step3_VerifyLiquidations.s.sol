// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title Step3_VerifyLiquidations
 * @notice Verifica que las liquidaciones automaticas se hayan ejecutado correctamente
 */
contract Step3_VerifyLiquidations is Script {
    
    // Direcciones del sistema desplegado
    address constant AUTOMATION_KEEPER = 0x15C7298Dd649DcDc17D281cB0dAE84E945573c93;
    address constant LOAN_ADAPTER = 0x6A444D8e037672535879AEF7C668D6d5D15B84d7;
    address constant FLEXIBLE_LOAN_MANAGER = 0xc8Bf18B4D6B459b17b9298D5Ed6B2feC1f0D9b3D;
    address constant MOCK_ORACLE = 0x8C59715a208FDe0445d7046a6B4612796810C846;
    address constant MOCK_ETH = 0x5e2e783F84EF0b6D58115DF458F7F04e593011B7;
    address constant MOCK_USDC = 0xfF63beAFB949ffeb8df366e4738001cf54e97eD1;
    
    // Tu upkeep ID registrado
    uint256 constant UPKEEP_ID = 35283090123137439879057452590905787868464269668261475719855807879502576065354;
    
    function run() external {
        console.log("=== STEP 3: VERIFYING AUTOMATION LIQUIDATIONS ===");
        console.log("Upkeep ID:", UPKEEP_ID);
        console.log("");
        
        // Instanciar contratos
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(AUTOMATION_KEEPER);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(LOAN_ADAPTER);
        ILoanManager loanManager = ILoanManager(FLEXIBLE_LOAN_MANAGER);
        MockVCOPOracle oracle = MockVCOPOracle(MOCK_ORACLE);
        
        // Verificar estado actual
        console.log("CURRENT SYSTEM STATE:");
        console.log("====================");
        
        uint256 ethPrice = oracle.getPrice(MOCK_ETH, MOCK_USDC);
        console.log("ETH Price:", ethPrice / 1e6, "USD");
        
        uint256 totalPositions = adapter.getTotalActivePositions();
        console.log("Total active positions:", totalPositions);
        
        // Verificar estadisticas del keeper
        _checkKeeperStats(keeper);
        
        // Verificar estadisticas del adapter
        _checkAdapterStats(adapter);
        
        // Probar checkUpkeep manualmente
        _testCheckUpkeep(keeper);
        
        // Analizar posiciones restantes
        _analyzeRemainingPositions(adapter, loanManager);
        
        console.log("");
        console.log("=== VERIFICATION COMPLETED ===");
        console.log("Check your Chainlink Automation dashboard:");
        console.log("https://automation.chain.link/base-sepolia");
        console.log("Look for your upkeep:", UPKEEP_ID);
        console.log("");
        console.log("What to look for:");
        console.log("- Reduced LINK balance (gas consumed)");
        console.log("- PerformUpkeep executions in history");
        console.log("- Successful liquidation transactions");
    }
    
    function _checkKeeperStats(LoanAutomationKeeperOptimized keeper) internal view {
        console.log("");
        console.log("AUTOMATION KEEPER STATS:");
        console.log("========================");
        
        (
            uint256 totalLiquidations,
            uint256 totalUpkeeps,
            uint256 lastExecution,
            uint256 avgGas,
            uint256 registeredCount
        ) = keeper.getStats();
        
        console.log("Total liquidations executed:", totalLiquidations);
        console.log("Total upkeeps performed:", totalUpkeeps);
        console.log("Last execution timestamp:", lastExecution);
        console.log("Average gas used:", avgGas);
        console.log("Registered managers:", registeredCount);
        
        if (totalLiquidations > 0) {
            console.log("SUCCESS: Automation has executed liquidations!");
        } else {
            console.log("INFO: No liquidations executed yet (may be pending)");
        }
    }
    
    function _checkAdapterStats(LoanManagerAutomationAdapter adapter) internal view {
        console.log("");
        console.log("LOAN ADAPTER STATS:");
        console.log("==================");
        
        (
            uint256 totalAttempts,
            uint256 totalSuccessful,
            uint256 successRate,
            uint256 lastSync
        ) = adapter.getLiquidationStats();
        
        console.log("Liquidation attempts:", totalAttempts);
        console.log("Successful liquidations:", totalSuccessful);
        console.log("Success rate:", successRate / 10000, "%");
        console.log("Last sync:", lastSync);
        
        // Get tracking stats
        (
            uint256 totalTracked,
            uint256 totalAtRisk,
            uint256 totalLiquidatable,
            uint256 totalCritical,
            uint256 performance
        ) = adapter.getTrackingStats();
        
        console.log("");
        console.log("Position tracking:");
        console.log("- Total tracked:", totalTracked);
        console.log("- At risk:", totalAtRisk);
        console.log("- Liquidatable:", totalLiquidatable);
        console.log("- Critical:", totalCritical);
        console.log("- Performance score:", performance / 10000, "%");
    }
    
    function _testCheckUpkeep(LoanAutomationKeeperOptimized keeper) internal view {
        console.log("");
        console.log("TESTING CHECKUPKEEP:");
        console.log("====================");
        
        // Generate checkData
        bytes memory checkData = keeper.generateOptimizedCheckData(
            FLEXIBLE_LOAN_MANAGER,
            0,  // start from position 1
            0   // default batch size
        );
        
        // Test checkUpkeep
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("CheckUpkeep result:");
            console.log("- Upkeep needed:", upkeepNeeded);
            console.log("- PerformData length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("ACTIVE: System detected liquidatable positions");
                console.log("Chainlink will execute performUpkeep soon");
            } else {
                console.log("IDLE: No positions need liquidation currently");
            }
            
        } catch Error(string memory reason) {
            console.log("CheckUpkeep failed:", reason);
        } catch {
            console.log("CheckUpkeep failed: unknown error");
        }
    }
    
    function _analyzeRemainingPositions(
        LoanManagerAutomationAdapter adapter,
        ILoanManager loanManager
    ) internal view {
        console.log("");
        console.log("REMAINING POSITIONS ANALYSIS:");
        console.log("=============================");
        
        uint256 totalPositions = adapter.getTotalActivePositions();
        
        if (totalPositions == 0) {
            console.log("No active positions remaining - all liquidated!");
            return;
        }
        
        // Get positions at risk
        try adapter.getPositionsAtRisk() returns (
            uint256[] memory riskPositions,
            uint256[] memory riskLevels
        ) {
            if (riskPositions.length == 0) {
                console.log("No positions at risk - system is healthy");
            } else {
                console.log("Positions still at risk:", riskPositions.length);
                
                for (uint256 i = 0; i < riskPositions.length && i < 5; i++) {
                    uint256 positionId = riskPositions[i];
                    uint256 riskLevel = riskLevels[i];
                    
                    try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
                        bool canLiquidate = loanManager.canLiquidate(positionId);
                        
                        console.log("Position", positionId, ":");
                        console.log("  Risk Level:", riskLevel);
                        console.log("  Ratio:", ratio / 10000, "%");
                        console.log("  Can Liquidate:", canLiquidate);
                        
                        if (canLiquidate) {
                            console.log("  STATUS: Ready for liquidation");
                        } else {
                            console.log("  STATUS: At risk but not liquidatable yet");
                        }
                    } catch {
                        console.log("Position", positionId, ": Error reading data");
                    }
                }
            }
        } catch {
            console.log("Error getting positions at risk");
        }
        
        console.log("");
        console.log("NEXT STEPS:");
        console.log("- Monitor Chainlink dashboard for upkeep executions");
        console.log("- Check transaction history for liquidation events");
        console.log("- LINK balance should decrease with each execution");
        console.log("- Positions above should be liquidated automatically");
    }
} 
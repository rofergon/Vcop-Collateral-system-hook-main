// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title DeepDiagnoseLiquidationFailure
 * @notice Diagnostica en profundidad por que fallan las liquidaciones
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
        
        console.log("PERFORMANCE se ejecuta pero liquidaciones fallan");
        console.log("performUpkeep executions: 6");
        console.log("Gas used: 227421 (se consume gas real)");
        console.log("Liquidations successful: 0");
        console.log("");
        
        console.log("STEP 1: VERIFICAR AUTORIZACION COMPLETA");
        console.log("======================================");
        _checkFullAuthorization(keeper, adapter, loanManager);
        
        console.log("");
        console.log("STEP 2: PROBAR LIQUIDACION MANUAL");
        console.log("=================================");
        _testManualLiquidationDirectly(adapter, loanManager);
        
        console.log("");
        console.log("STEP 3: VERIFICAR COOLDOWNS");
        console.log("===========================");
        _checkCooldowns(adapter, keeper);
        
        console.log("");
        console.log("STEP 4: SIMULAR PERFORMUPKEEP");
        console.log("=============================");
        _simulatePerformUpkeep(keeper);
        
        console.log("");
        console.log("STEP 5: VERIFICAR ASSET HANDLERS");
        console.log("================================");
        _checkAssetHandlers(loanManager);
    }
    
    function _checkFullAuthorization(
        LoanAutomationKeeperOptimized keeper,
        LoanManagerAutomationAdapter adapter,
        ILoanManager loanManager
    ) internal view {
        
        address adapterAuth = adapter.authorizedAutomationContract();
        console.log("Adapter authorized contract:", adapterAuth);
        console.log("Keeper address:", address(keeper));
        console.log("Authorization match:", adapterAuth == address(keeper));
        
        // Check FlexibleLoanManager automation settings
        address loanManagerAuth = loanManager.authorizedAutomationContract();
        bool loanManagerEnabled = loanManager.isAutomationEnabled();
        console.log("LoanManager authorized contract:", loanManagerAuth);
        console.log("LoanManager automation enabled:", loanManagerEnabled);
        
        if (loanManagerAuth != address(adapter)) {
            console.log("ISSUE: LoanManager should authorize the ADAPTER, not keeper!");
            console.log("Expected:", address(adapter));
            console.log("Actual:", loanManagerAuth);
        } else {
            console.log("OK: LoanManager properly authorizes adapter");
        }
    }
    
    function _testManualLiquidationDirectly(
        LoanManagerAutomationAdapter adapter,
        ILoanManager loanManager
    ) internal view {
        
        console.log("Testing direct liquidation through adapter...");
        
        // Get first position
        uint256[] memory positions = adapter.getPositionsInRange(0, 0);
        if (positions.length == 0) {
            console.log("No positions found in adapter");
            return;
        }
        
        uint256 positionId = positions[0];
        console.log("Testing position:", positionId);
        
        // Check if position can be liquidated
        bool canLiquidate = loanManager.canLiquidate(positionId);
        console.log("LoanManager.canLiquidate:", canLiquidate);
        
        (bool isAtRisk, uint256 riskLevel) = adapter.isPositionAtRisk(positionId);
        console.log("Adapter.isPositionAtRisk:", isAtRisk);
        console.log("Risk level:", riskLevel);
        
        // Check cooldown
        uint256 cooldown = adapter.liquidationCooldown();
        console.log("Liquidation cooldown:", cooldown, "seconds");
        
        // Try to get position details
        try loanManager.getPosition(positionId) returns (ILoanManager.LoanPosition memory pos) {
            console.log("Position borrower:", pos.borrower);
            console.log("Position active:", pos.isActive);
            console.log("Collateral asset:", pos.collateralAsset);
            console.log("Loan asset:", pos.loanAsset);
        } catch {
            console.log("Failed to get position details");
        }
    }
    
    function _checkCooldowns(
        LoanManagerAutomationAdapter adapter,
        LoanAutomationKeeperOptimized keeper
    ) internal view {
        
        console.log("Checking cooldown settings...");
        
        uint256 adapterCooldown = adapter.liquidationCooldown();
        uint256 keeperCooldown = keeper.liquidationCooldown();
        
        console.log("Adapter cooldown:", adapterCooldown, "seconds");
        console.log("Keeper cooldown:", keeperCooldown, "seconds");
        
        if (adapterCooldown > 300) {
            console.log("WARNING: Adapter cooldown is high (>5min)");
        }
        
        if (keeperCooldown > 300) {
            console.log("WARNING: Keeper cooldown is high (>5min)");
        }
        
        // Check if positions are in cooldown
        uint256[] memory positions = adapter.getPositionsInRange(0, 2);
        for (uint256 i = 0; i < positions.length; i++) {
            console.log("Position", positions[i], "failure count:", 
                       adapter.getPositionFailureCount(positions[i]));
        }
    }
    
    function _simulatePerformUpkeep(LoanAutomationKeeperOptimized keeper) internal view {
        
        console.log("Simulating performUpkeep execution...");
        
        // Generate the same checkData that would be used
        bytes memory checkData = keeper.generateOptimizedCheckData(
            FLEXIBLE_LOAN_MANAGER,
            0,
            0
        );
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("CheckUpkeep returns upkeepNeeded:", upkeepNeeded);
            
            if (upkeepNeeded && performData.length > 0) {
                console.log("PerformData valid, would execute performUpkeep");
                console.log("PerformData length:", performData.length);
                
                // Try to decode performData
                try this.decodePerformData(performData) returns (
                    address manager,
                    uint256[] memory positionIds,
                    uint256[] memory riskLevels,
                    uint256 timestamp
                ) {
                    console.log("Decoded performData:");
                    console.log("- Manager:", manager);
                    console.log("- Positions count:", positionIds.length);
                    console.log("- Timestamp:", timestamp);
                    console.log("- Time diff:", block.timestamp - timestamp, "seconds");
                    
                    if (block.timestamp - timestamp > 300) {
                        console.log("WARNING: Data is old (>5min), might be rejected");
                    }
                    
                } catch {
                    console.log("Failed to decode performData");
                }
            }
        } catch {
            console.log("CheckUpkeep failed");
        }
    }
    
    function _checkAssetHandlers(ILoanManager loanManager) internal view {
        
        console.log("Checking asset handler configuration...");
        
        // Try to liquidate position 1 directly to see detailed error
        try loanManager.getPosition(1) returns (ILoanManager.LoanPosition memory pos) {
            console.log("Position 1 details:");
            console.log("- Borrower:", pos.borrower);
            console.log("- Collateral asset:", pos.collateralAsset);
            console.log("- Loan asset:", pos.loanAsset);
            console.log("- Collateral amount:", pos.collateralAmount);
            console.log("- Loan amount:", pos.loanAmount);
            console.log("- Active:", pos.isActive);
            
            if (pos.isActive) {
                try loanManager.getTotalDebt(1) returns (uint256 debt) {
                    console.log("- Total debt:", debt);
                } catch {
                    console.log("- Failed to get total debt");
                }
                
                try loanManager.getCollateralizationRatio(1) returns (uint256 ratio) {
                    console.log("- Collateral ratio:", ratio / 10000, "%");
                } catch {
                    console.log("- Failed to get collateral ratio");
                }
            }
        } catch {
            console.log("Failed to get position 1");
        }
    }
    
    // External function for decoding performData
    function decodePerformData(bytes calldata performData) external pure returns (
        address loanManager,
        uint256[] memory positions,
        uint256[] memory riskLevels,
        uint256 timestamp
    ) {
        return abi.decode(performData, (address, uint256[], uint256[], uint256));
    }
} 
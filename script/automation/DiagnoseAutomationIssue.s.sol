// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title DiagnoseAutomationIssue
 * @notice Diagnostica por que no se estan ejecutando las liquidaciones automaticas
 */
contract DiagnoseAutomationIssue is Script {
    
    // Direcciones del sistema
    address constant AUTOMATION_KEEPER = 0x15C7298Dd649DcDc17D281cB0dAE84E945573c93;
    address constant LOAN_ADAPTER = 0x6A444D8e037672535879AEF7C668D6d5D15B84d7;
    address constant FLEXIBLE_LOAN_MANAGER = 0xc8Bf18B4D6B459b17b9298D5Ed6B2feC1f0D9b3D;
    address constant MOCK_ORACLE = 0x8C59715a208FDe0445d7046a6B4612796810C846;
    address constant MOCK_ETH = 0x5e2e783F84EF0b6D58115DF458F7F04e593011B7;
    address constant MOCK_USDC = 0xfF63beAFB949ffeb8df366e4738001cf54e97eD1;
    
    function run() external view {
        console.log("=== CHAINLINK AUTOMATION DIAGNOSTIC ===");
        console.log("");
        
        // Instanciar contratos
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(AUTOMATION_KEEPER);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(LOAN_ADAPTER);
        ILoanManager loanManager = ILoanManager(FLEXIBLE_LOAN_MANAGER);
        MockVCOPOracle oracle = MockVCOPOracle(MOCK_ORACLE);
        
        console.log("STEP 1: CHECKING BASIC CONFIGURATION");
        console.log("====================================");
        _checkBasicConfig(keeper, adapter, loanManager, oracle);
        
        console.log("");
        console.log("STEP 2: CHECKING AUTHORIZATION");
        console.log("==============================");
        _checkAuthorization(keeper, adapter);
        
        console.log("");
        console.log("STEP 3: TESTING CHECKUPKEEP MANUALLY");
        console.log("====================================");
        _testCheckUpkeep(keeper);
        
        console.log("");
        console.log("STEP 4: CHECKING POSITIONS STATE");
        console.log("================================");
        _checkPositionsState(adapter, loanManager);
        
        console.log("");
        console.log("STEP 5: TESTING MANUAL LIQUIDATION");
        console.log("==================================");
        _testManualLiquidation(loanManager);
        
        console.log("");
        console.log("STEP 6: POSSIBLE SOLUTIONS");
        console.log("==========================");
        _provideSolutions();
    }
    
    function _checkBasicConfig(
        LoanAutomationKeeperOptimized keeper,
        LoanManagerAutomationAdapter adapter,
        ILoanManager loanManager,
        MockVCOPOracle oracle
    ) internal view {
        
        console.log("Emergency pause:", keeper.emergencyPause());
        console.log("Min risk threshold:", keeper.minRiskThreshold());
        console.log("Automation enabled in adapter:", adapter.isAutomationEnabled());
        console.log("ETH Price:", oracle.getPrice(MOCK_ETH, MOCK_USDC) / 1e6, "USD");
        console.log("Total active positions:", adapter.getTotalActivePositions());
        
        // Check if manager is registered
        (address[] memory managers, uint256[] memory priorities) = keeper.getRegisteredManagers();
        bool isRegistered = false;
        for (uint256 i = 0; i < managers.length; i++) {
            if (managers[i] == FLEXIBLE_LOAN_MANAGER) {
                isRegistered = true;
                console.log("LoanManager registered with priority:", priorities[i]);
                break;
            }
        }
        
        if (!isRegistered) {
            console.log("ERROR: LoanManager NOT registered in keeper!");
        }
    }
    
    function _checkAuthorization(
        LoanAutomationKeeperOptimized keeper,
        LoanManagerAutomationAdapter adapter
    ) internal view {
        
        address authorizedContract = adapter.authorizedAutomationContract();
        console.log("Authorized automation contract:", authorizedContract);
        
        if (authorizedContract == address(0)) {
            console.log("ISSUE: No automation contract authorized in adapter!");
        } else if (authorizedContract != AUTOMATION_KEEPER) {
            console.log("ISSUE: Wrong automation contract authorized!");
            console.log("Expected:", AUTOMATION_KEEPER);
            console.log("Actual:", authorizedContract);
        } else {
            console.log("OK: Automation contract properly authorized");
        }
    }
    
    function _testCheckUpkeep(LoanAutomationKeeperOptimized keeper) internal view {
        
        // Generate checkData
        bytes memory checkData = keeper.generateOptimizedCheckData(
            FLEXIBLE_LOAN_MANAGER,
            0,  // start from position 1
            0   // default batch size
        );
        
        console.log("Testing checkUpkeep...");
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("CheckUpkeep result:");
            console.log("- Upkeep needed:", upkeepNeeded);
            console.log("- PerformData length:", performData.length);
            
            if (upkeepNeeded && performData.length > 0) {
                console.log("OK: CheckUpkeep returns valid data");
                
                // Decode performData to see what would be liquidated
                try this.decodePerformData(performData) returns (
                    address loanManager,
                    uint256[] memory positions,
                    uint256[] memory riskLevels,
                    uint256 timestamp
                ) {
                    console.log("PerformData contains:");
                    console.log("- LoanManager:", loanManager);
                    console.log("- Positions to liquidate:", positions.length);
                    console.log("- Timestamp:", timestamp);
                    
                    for (uint256 i = 0; i < positions.length && i < 3; i++) {
                        console.log("- Position", positions[i], "risk:", riskLevels[i]);
                    }
                } catch {
                    console.log("Could not decode performData");
                }
                
            } else {
                console.log("ISSUE: CheckUpkeep not returning valid execution data");
            }
            
        } catch Error(string memory reason) {
            console.log("ERROR: CheckUpkeep failed:", reason);
        } catch {
            console.log("ERROR: CheckUpkeep failed with unknown error");
        }
    }
    
    function _checkPositionsState(
        LoanManagerAutomationAdapter adapter,
        ILoanManager loanManager
    ) internal view {
        
        uint256 totalPositions = adapter.getTotalActivePositions();
        console.log("Total positions in adapter:", totalPositions);
        
        if (totalPositions == 0) {
            console.log("ISSUE: No positions tracked in adapter!");
            return;
        }
        
        // Check each position
        uint256[] memory positions = adapter.getPositionsInRange(0, totalPositions - 1);
        console.log("Checking", positions.length, "positions:");
        
        for (uint256 i = 0; i < positions.length; i++) {
            uint256 positionId = positions[i];
            
            try loanManager.getPosition(positionId) returns (ILoanManager.LoanPosition memory pos) {
                if (!pos.isActive) {
                    console.log("Position", positionId, ": INACTIVE");
                    continue;
                }
                
                uint256 ratio = loanManager.getCollateralizationRatio(positionId);
                bool canLiquidate = loanManager.canLiquidate(positionId);
                (bool isAtRisk, uint256 riskLevel) = adapter.isPositionAtRisk(positionId);
                
                console.log("Position", positionId, ":");
                console.log("  - Borrower:", pos.borrower);
                console.log("  - Ratio:", ratio / 10000, "%");
                console.log("  - Can liquidate:", canLiquidate);
                console.log("  - At risk:", isAtRisk);
                console.log("  - Risk level:", riskLevel);
                
            } catch {
                console.log("Position", positionId, ": ERROR reading data");
            }
        }
    }
    
    function _testManualLiquidation(ILoanManager loanManager) internal view {
        
        console.log("Testing if manual liquidation would work...");
        
        // Try to get first position
        try loanManager.getPosition(1) returns (ILoanManager.LoanPosition memory pos) {
            if (pos.isActive) {
                bool canLiquidate = loanManager.canLiquidate(1);
                console.log("Position 1 can be liquidated manually:", canLiquidate);
                
                if (canLiquidate) {
                    console.log("Manual liquidation is possible - automation should work");
                } else {
                    console.log("Manual liquidation not possible - check liquidation conditions");
                }
            } else {
                console.log("Position 1 is not active");
            }
        } catch {
            console.log("Could not check position 1");
        }
    }
    
    function _provideSolutions() internal pure {
        
        console.log("POSSIBLE ISSUES AND SOLUTIONS:");
        console.log("");
        
        console.log("1. AUTHORIZATION ISSUE:");
        console.log("   Problem: Adapter not authorized for keeper");
        console.log("   Solution: Run authorization script");
        console.log("");
        
        console.log("2. TIMING ISSUE:");
        console.log("   Problem: Chainlink needs more time to detect");
        console.log("   Solution: Wait 5-10 more minutes");
        console.log("");
        
        console.log("3. GAS LIMIT ISSUE:");
        console.log("   Problem: Gas limit too low for execution");
        console.log("   Solution: Increase gas limit in upkeep");
        console.log("");
        
        console.log("4. LINK BALANCE ISSUE:");
        console.log("   Problem: Not enough LINK for execution");
        console.log("   Solution: Add more LINK to upkeep");
        console.log("");
        
        console.log("5. NETWORK CONGESTION:");
        console.log("   Problem: Base Sepolia network issues");
        console.log("   Solution: Wait for network to stabilize");
        console.log("");
        
        console.log("TO FIX AUTHORIZATION:");
        console.log("Run: script/automation/FixAuthorization.s.sol");
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
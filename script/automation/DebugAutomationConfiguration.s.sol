// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title DebugAutomationConfiguration
 * @notice Debug automation configuration to find why checkUpkeep returns false
 */
contract DebugAutomationConfiguration is Script {
    
    function run() external view {
        console.log("=== DEBUG AUTOMATION CONFIGURATION ===");
        console.log("======================================");
        console.log("");
        
        // Load addresses from JSON
        string memory content = vm.readFile("deployed-addresses-mock.json");
        
        // Extract addresses using proper JSON parsing
        address automationKeeper = vm.parseJsonAddress(content, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(content, ".automation.loanAdapter");
        address flexibleLoanManager = vm.parseJsonAddress(content, ".coreLending.flexibleLoanManager");
        
        console.log("DEPLOYED ADDRESSES:");
        console.log("==================");
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("");
        
        _debugAutomationKeeper(automationKeeper, loanAdapter);
        _debugLoanAdapter(loanAdapter, flexibleLoanManager);
        _debugSpecificPosition(loanAdapter, 30); // Position ID 30 que acabamos de crear
        _debugCheckUpkeepFlow(automationKeeper, loanAdapter);
    }
    
    /**
     * @dev Debug AutomationKeeper configuration
     */
    function _debugAutomationKeeper(address automationKeeper, address loanAdapter) internal view {
        console.log("1. DEBUGGING AUTOMATION KEEPER");
        console.log("=============================");
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        // Check if emergency paused
        try keeper.emergencyPause() returns (bool paused) {
            console.log("Emergency Pause:", paused ? "PAUSED" : "ACTIVE");
        } catch {
            console.log("Emergency Pause: ERROR - cannot read");
        }
        
        // Check if LoanAdapter is registered
        try keeper.registeredManagers(loanAdapter) returns (bool registered) {
            console.log("LoanAdapter Registered:", registered ? "YES" : "NO");
            if (!registered) {
                console.log("*** ISSUE: LoanAdapter NOT REGISTERED ***");
            }
        } catch {
            console.log("LoanAdapter Registration: ERROR - cannot read");
        }
        
        // Check min risk threshold
        try keeper.minRiskThreshold() returns (uint256 threshold) {
            console.log("Min Risk Threshold:", threshold);
        } catch {
            console.log("Min Risk Threshold: ERROR - cannot read");
        }
        
        // Check max positions per batch
        try keeper.maxPositionsPerBatch() returns (uint256 maxBatch) {
            console.log("Max Positions Per Batch:", maxBatch);
        } catch {
            console.log("Max Positions Per Batch: ERROR - cannot read");
        }
        
        console.log("");
    }
    
    /**
     * @dev Debug LoanAdapter configuration
     */
    function _debugLoanAdapter(address loanAdapter, address flexibleLoanManager) internal view {
        console.log("2. DEBUGGING LOAN ADAPTER");
        console.log("=========================");
        
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        // Check if automation is enabled
        try adapter.automationEnabled() returns (bool enabled) {
            console.log("Automation Enabled:", enabled ? "YES" : "NO");
            if (!enabled) {
                console.log("*** ISSUE: AUTOMATION DISABLED ***");
            }
        } catch {
            console.log("Automation Enabled: ERROR - cannot read");
        }
        
        // Check total active positions
        try adapter.getTotalActivePositions() returns (uint256 total) {
            console.log("Total Active Positions:", total);
            if (total == 0) {
                console.log("*** ISSUE: NO ACTIVE POSITIONS TRACKED ***");
            }
        } catch {
            console.log("Total Active Positions: ERROR - cannot read");
        }
        
        // Check if position 30 is tracked
        try adapter.isPositionTracked(30) returns (bool tracked) {
            console.log("Position 30 Tracked:", tracked ? "YES" : "NO");
            if (!tracked) {
                console.log("*** ISSUE: POSITION 30 NOT TRACKED ***");
            }
        } catch {
            console.log("Position 30 Tracked: ERROR - cannot read");
        }
        
        // Check loan manager address
        try adapter.loanManager() returns (ILoanManager loanMgr) {
            console.log("Configured LoanManager:", address(loanMgr));
            console.log("Expected LoanManager:", flexibleLoanManager);
            if (address(loanMgr) != flexibleLoanManager) {
                console.log("*** ISSUE: LOAN MANAGER MISMATCH ***");
            }
        } catch {
            console.log("Configured LoanManager: ERROR - cannot read");
        }
        
        console.log("");
    }
    
    /**
     * @dev Debug specific position 30
     */
    function _debugSpecificPosition(address loanAdapter, uint256 positionId) internal view {
        console.log("3. DEBUGGING POSITION", positionId);
        console.log("========================");
        
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        // Check if position is at risk
        try adapter.isPositionAtRisk(positionId) returns (bool isAtRisk, uint256 riskLevel) {
            console.log("Position At Risk:", isAtRisk ? "YES" : "NO");
            console.log("Risk Level:", riskLevel);
            
            if (!isAtRisk) {
                console.log("*** ISSUE: POSITION NOT DETECTED AS AT RISK ***");
            }
        } catch Error(string memory reason) {
            console.log("Position Risk Check: ERROR -", reason);
        } catch {
            console.log("Position Risk Check: ERROR - unknown");
        }
        
        // Get position health data
        try adapter.getPositionHealthData(positionId) returns (
            address borrower,
            uint256 collateralValue,
            uint256 debtValue,
            uint256 healthFactor
        ) {
            console.log("Position Health:");
            console.log("  Borrower:", borrower);
            console.log("  Collateral Value:", collateralValue);
            console.log("  Debt Value:", debtValue);
            console.log("  Health Factor:", healthFactor);
        } catch Error(string memory reason) {
            console.log("Position Health: ERROR -", reason);
        } catch {
            console.log("Position Health: ERROR - unknown");
        }
        
        console.log("");
    }
    
    /**
     * @dev Debug complete checkUpkeep flow
     */
    function _debugCheckUpkeepFlow(address automationKeeper, address loanAdapter) internal view {
        console.log("4. DEBUGGING CHECKUPKEEP FLOW");
        console.log("=============================");
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        // Generate checkData
        bytes memory checkData = abi.encode(loanAdapter, uint256(0), uint256(25));
        console.log("CheckData:");
        console.logBytes(checkData);
        
        // Try checkUpkeep
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("CheckUpkeep Result:");
            console.log("  UpkeepNeeded:", upkeepNeeded);
            console.log("  PerformData Length:", performData.length);
            
            if (!upkeepNeeded) {
                console.log("*** ISSUE: CHECKUPKEEP RETURNS FALSE ***");
                console.log("This means either:");
                console.log("1. LoanAdapter not registered in AutomationKeeper");
                console.log("2. LoanAdapter automation disabled");
                console.log("3. No positions tracked by LoanAdapter");
                console.log("4. Position not detected as at risk");
                console.log("5. Risk level below threshold");
            }
            
            if (performData.length > 0) {
                // Try to decode performData
                try this.decodePerformData(performData) returns (
                    address loanManager,
                    uint256[] memory positions,
                    uint256[] memory riskLevels,
                    uint256 timestamp
                ) {
                    console.log("PerformData decoded:");
                    console.log("  LoanManager:", loanManager);
                    console.log("  Positions Count:", positions.length);
                    for (uint256 i = 0; i < positions.length && i < 5; i++) {
                        console.log("  Position ID:", positions[i]);
                        console.log("  Risk Level:", riskLevels[i]);
                    }
                } catch {
                    console.log("Could not decode performData");
                }
            }
            
        } catch Error(string memory reason) {
            console.log("CheckUpkeep ERROR:", reason);
        } catch {
            console.log("CheckUpkeep ERROR: unknown");
        }
        
        console.log("");
    }
    
    /**
     * @dev Helper to decode performData
     */
    function decodePerformData(bytes memory performData) external pure returns (
        address loanManager,
        uint256[] memory positions,
        uint256[] memory riskLevels,
        uint256 timestamp
    ) {
        return abi.decode(performData, (address, uint256[], uint256[], uint256));
    }
    
    /**
     * @dev Show recommendations based on findings
     */
    function showRecommendations() external pure {
        console.log("=== RECOMMENDATIONS ===");
        console.log("======================");
        console.log("");
        console.log("Based on common issues:");
        console.log("");
        console.log("IF LoanAdapter NOT REGISTERED:");
        console.log("  make configure-avalanche-vault-automation");
        console.log("");
        console.log("IF Position NOT TRACKED:");
        console.log("  make configure-avalanche-default-risk-thresholds");
        console.log("");
        console.log("IF Automation DISABLED:");
        console.log("  Check LoanAdapter.automationEnabled()");
        console.log("");
        console.log("IF Risk thresholds WRONG:");
        console.log("  Verify minRiskThreshold and position risk level");
    }
} 
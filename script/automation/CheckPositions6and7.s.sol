// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title CheckPositions6and7
 * @notice Verifica específicamente las posiciones 6 y 7 y el estado del oracle
 */
contract CheckPositions6and7 is Script {
    
    address public flexibleLoanManager;
    address public automationAdapter;
    address public automationKeeper;
    address public mockOracle;
    
    function run() external {
        console.log("=== CHECKING POSITIONS 6 AND 7 ===");
        console.log("");
        
        loadAddresses();
        checkOraclePrices();
        checkSpecificPositions();
        testCheckUpkeepWithCorrectRange();
    }
    
    function loadAddresses() internal {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        automationAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("AutomationAdapter:", automationAdapter);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("MockOracle:", mockOracle);
        console.log("");
    }
    
    function checkOraclePrices() internal view {
        console.log("=== ORACLE PRICE CHECK ===");
        
        MockVCOPOracle oracle = MockVCOPOracle(mockOracle);
        
        try oracle.getCurrentMarketPrices() returns (
            uint256 ethPrice,
            uint256 btcPrice,
            uint256 vcopPrice,
            uint256 usdCopRate
        ) {
            console.log("Current Oracle Prices:");
            console.log("ETH: $", ethPrice / 1e6);
            console.log("BTC: $", btcPrice / 1e6);
            console.log("VCOP: $", vcopPrice / 1e6);
            console.log("USD/COP Rate:", usdCopRate / 1e6);
        } catch {
            console.log("Error getting oracle prices");
        }
        
        console.log("");
    }
    
    function checkSpecificPositions() internal view {
        console.log("=== CHECKING POSITIONS 6 AND 7 ===");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        uint256 nextPositionId = loanManager.nextPositionId();
        console.log("Next position ID:", nextPositionId);
        console.log("");
        
        // Check positions 6 and 7 specifically
        for (uint256 positionId = 6; positionId <= 7; positionId++) {
            console.log("POSITION", positionId, ":");
            
            try loanManager.getPosition(positionId) returns (FlexibleLoanManager.LoanPosition memory position) {
                if (position.borrower == address(0)) {
                    console.log("  Does not exist");
                } else {
                    console.log("  Borrower:", position.borrower);
                    console.log("  Active:", position.isActive);
                    
                    if (position.isActive) {
                        console.log("  Collateral:", position.collateralAmount / 1e18, "ETH");
                        console.log("  Loan:", position.loanAmount / 1e6, "USDC");
                        
                        // Check tracking
                        bool isTracked = adapter.isPositionTracked(positionId);
                        console.log("  Tracked in adapter:", isTracked);
                        
                        // Check collateralization ratio
                        try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
                            console.log("  Current ratio:", ratio / 10000, "%");
                            if (ratio < 1050000) { // Less than 105%
                                console.log("  [LIQUIDATABLE] Ratio < 105%");
                            } else {
                                console.log("  [SAFE] Ratio >= 105%");
                            }
                        } catch {
                            console.log("  Error getting ratio");
                        }
                        
                        // Check if liquidatable
                        try loanManager.canLiquidate(positionId) returns (bool canLiq) {
                            console.log("  Can liquidate:", canLiq);
                        } catch {
                            console.log("  Error checking liquidation");
                        }
                        
                        // Check via adapter
                        try adapter.isPositionAtRisk(positionId) returns (bool atRisk, uint256 riskLevel) {
                            console.log("  At risk (adapter):", atRisk);
                            console.log("  Risk level:", riskLevel);
                        } catch {
                            console.log("  Error checking adapter risk");
                        }
                    } else {
                        console.log("  [LIQUIDATED] Position is inactive");
                    }
                }
            } catch {
                console.log("  Error getting position");
            }
            
            console.log("");
        }
    }
    
    function testCheckUpkeepWithCorrectRange() internal view {
        console.log("=== TESTING CHECKUPKEEP WITH CORRECT RANGE ===");
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        // Test with range 1-10 (where positions 6,7 actually are)
        bytes memory checkData = abi.encode(automationAdapter, uint256(1), uint256(10));
        
        console.log("Testing checkUpkeep with range 1-10...");
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("CheckUpkeep result:", upkeepNeeded);
            console.log("PerformData length:", performData.length);
            
            if (upkeepNeeded && performData.length > 0) {
                console.log("SUCCESS: Found liquidatable positions!");
                
                // Decode performData
                (address loanManager, uint256[] memory positions, uint256[] memory riskLevels, uint256 timestamp) = 
                    abi.decode(performData, (address, uint256[], uint256[], uint256));
                    
                console.log("Loan Manager:", loanManager);
                console.log("Positions to liquidate:", positions.length);
                
                for (uint256 i = 0; i < positions.length && i < 5; i++) {
                    console.log("  Position", positions[i], "- Risk Level:", riskLevels[i]);
                }
                console.log("Timestamp:", timestamp);
            } else {
                console.log("No liquidatable positions found in range 1-10");
            }
        } catch Error(string memory reason) {
            console.log("CheckUpkeep failed:", reason);
        }
        
        console.log("");
        
        // Also test the original checkData (range 0-25, converted to 1-26)
        bytes memory originalCheckData = hex"0000000000000000000000009357b40e857bb2868646921aaa1a71fd9c364ea200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000019";
        
        console.log("Testing with original checkData (should work now)...");
        
        try keeper.checkUpkeep(originalCheckData) returns (bool upkeepNeeded2, bytes memory performData2) {
            console.log("Original CheckUpkeep result:", upkeepNeeded2);
            console.log("Original PerformData length:", performData2.length);
            
            if (upkeepNeeded2 && performData2.length > 0) {
                console.log("SUCCESS: Original checkData now works!");
            } else {
                console.log("Original checkData still returns no results");
            }
        } catch Error(string memory reason) {
            console.log("Original checkUpkeep failed:", reason);
        }
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title CheckRecentPositions
 * @notice Check recent positions (31-35) and their tracking status
 */
contract CheckRecentPositions is Script {
    
    function run() external view {
        console.log("=== CHECKING RECENT POSITIONS ===");
        console.log("=================================");
        
        // Load addresses
        string memory content = vm.readFile("deployed-addresses-mock.json");
        address flexibleLoanManager = vm.parseJsonAddress(content, ".coreLending.flexibleLoanManager");
        address loanAdapter = vm.parseJsonAddress(content, ".automation.loanAdapter");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        // Check positions 31-35
        for (uint256 i = 31; i <= 35; i++) {
            _checkPosition(loanManager, adapter, i);
        }
        
        // Check adapter tracking stats
        console.log("=== ADAPTER TRACKING STATS ===");
        console.log("==============================");
        (uint256 totalTracked, uint256 totalAtRisk, uint256 totalLiquidatable, uint256 totalCritical,) = adapter.getTrackingStats();
        console.log("Total Tracked:", totalTracked);
        console.log("Total At Risk:", totalAtRisk);
        console.log("Total Liquidatable:", totalLiquidatable);
        console.log("Total Critical:", totalCritical);
    }
    
    function _checkPosition(
        FlexibleLoanManager loanManager, 
        LoanManagerAutomationAdapter adapter, 
        uint256 positionId
    ) internal view {
        console.log("--- Position", positionId, "---");
        
        ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        
        if (position.borrower == address(0)) {
            console.log("Position does not exist");
            console.log("");
            return;
        }
        
        console.log("Borrower:", position.borrower);
        console.log("Collateral Amount:", position.collateralAmount);
        console.log("Loan Amount:", position.loanAmount);
        console.log("Is Active:", position.isActive);
        
        if (position.isActive) {
            // Check if tracked by adapter
            bool isTracked = adapter.isPositionTracked(positionId);
            console.log("Is Tracked by Adapter:", isTracked);
            
            // Check if liquidable
            bool canLiquidate = loanManager.canLiquidate(positionId);
            console.log("Can Liquidate:", canLiquidate);
            
            // Get risk level from adapter
            try adapter.isPositionAtRisk(positionId) returns (bool isAtRisk, uint256 riskLevel) {
                console.log("Is At Risk:", isAtRisk);
                console.log("Risk Level:", riskLevel);
            } catch {
                console.log("Could not get risk level");
            }
            
            // Get collateralization ratio
            try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
                console.log("Collateral Ratio:", ratio);
            } catch {
                console.log("Could not get ratio");
            }
            
            if (!isTracked && position.isActive) {
                console.log("*** ISSUE: ACTIVE POSITION NOT TRACKED ***");
            }
        }
        
        console.log("");
    }
} 
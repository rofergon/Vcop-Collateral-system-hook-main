// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title DebugPosition12
 * @notice Revisa específicamente qué está pasando con la posición 12
 */
contract DebugPosition12 is Script {
    
    function run() external view {
        console.log("=== DEBUGGING POSICION 12 ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        uint256 positionId = 12;
        
        console.log("CONTRACTS:");
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("LoanAdapter:", loanAdapter);
        console.log("Position ID:", positionId);
        console.log("");
        
        // 1. Check if position exists
        console.log("=== 1. POSICION DETAILS ===");
        ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        console.log("Position exists:", position.borrower != address(0));
        console.log("Position active:", position.isActive);
        console.log("Borrower:", position.borrower);
        console.log("Collateral Asset:", position.collateralAsset);
        console.log("Loan Asset:", position.loanAsset);
        console.log("Collateral Amount:", position.collateralAmount);
        console.log("Loan Amount:", position.loanAmount);
        console.log("");
        
        // 2. Check ratios directly from LoanManager
        console.log("=== 2. LOAN MANAGER DIRECT CHECKS ===");
        try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
            console.log("Collateralization Ratio:", ratio);
            console.log("Ratio Percentage:", ratio / 10000);
            
            // Calculate LTV
            if (ratio > 0 && ratio != type(uint256).max) {
                uint256 ltv = (100000000 / ratio) * 100; // LTV in basis points
                console.log("LTV (basis points):", ltv);
                console.log("LTV Percentage:", ltv / 10000);
            }
        } catch {
            console.log("ERROR: Could not get collateralization ratio");
        }
        
        try loanManager.canLiquidate(positionId) returns (bool canLiq) {
            console.log("Can Liquidate (LoanManager):", canLiq);
        } catch {
            console.log("ERROR: Could not check canLiquidate");
        }
        
        try loanManager.getTotalDebt(positionId) returns (uint256 debt) {
            console.log("Total Debt:", debt);
        } catch {
            console.log("ERROR: Could not get total debt");
        }
        
        console.log("");
        
        // 3. Check adapter response
        console.log("=== 3. AUTOMATION ADAPTER CHECKS ===");
        try adapter.isPositionAtRisk(positionId) returns (bool isAtRisk, uint256 riskLevel) {
            console.log("Adapter - At Risk:", isAtRisk);
            console.log("Adapter - Risk Level:", riskLevel);
        } catch {
            console.log("ERROR: Could not check adapter risk");
        }
        
        // 4. Check tracking
        console.log("");
        console.log("=== 4. TRACKING STATUS ===");
        (uint256 totalTracked, uint256 totalAtRisk, uint256 totalLiquidatable, uint256 totalCritical,) = adapter.getTrackingStats();
        console.log("Total Tracked:", totalTracked);
        console.log("Total At Risk:", totalAtRisk);
        console.log("Total Liquidatable:", totalLiquidatable);
        console.log("Total Critical:", totalCritical);
        
        console.log("");
        console.log("=== DIAGNOSTICO COMPLETO ===");
        console.log("Si la posicion tiene ratio < 105.26% pero no es liquidable,");
        console.log("el problema está en canLiquidate() del FlexibleLoanManager");
    }
} 
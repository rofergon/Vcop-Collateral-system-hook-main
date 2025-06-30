// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title CheckPositionStatus
 * @notice Check if position 30 still exists and is liquidable
 */
contract CheckPositionStatus is Script {
    
    function run() external view {
        console.log("=== CHECKING POSITION 30 STATUS ===");
        console.log("===================================");
        
        // Load addresses
        string memory content = vm.readFile("deployed-addresses-mock.json");
        address flexibleLoanManager = vm.parseJsonAddress(content, ".coreLending.flexibleLoanManager");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("Position ID: 30");
        console.log("");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        
        // Get position details
        ILoanManager.LoanPosition memory position = loanManager.getPosition(30);
        
        console.log("POSITION DETAILS:");
        console.log("================");
        console.log("Borrower:", position.borrower);
        console.log("Collateral Asset:", position.collateralAsset);
        console.log("Loan Asset:", position.loanAsset);
        console.log("Collateral Amount:", position.collateralAmount);
        console.log("Loan Amount:", position.loanAmount);
        console.log("Interest Rate:", position.interestRate);
        console.log("Is Active:", position.isActive);
        console.log("");
        
        if (position.isActive) {
            // Check if liquidable
            bool canLiquidate = loanManager.canLiquidate(30);
            console.log("Can Liquidate:", canLiquidate);
            
            // Get collateralization ratio
            try loanManager.getCollateralizationRatio(30) returns (uint256 ratio) {
                console.log("Collateralization Ratio:", ratio);
                console.log("Ratio Percentage:", ratio / 10000, "%");
            } catch {
                console.log("Could not get collateralization ratio");
            }
            
            // Get total debt
            try loanManager.getTotalDebt(30) returns (uint256 debt) {
                console.log("Total Debt:", debt);
            } catch {
                console.log("Could not get total debt");
            }
            
            console.log("");
            if (canLiquidate) {
                console.log("STATUS: POSITION IS LIQUIDABLE");
                console.log("Ready for Chainlink Automation to execute liquidation!");
            } else {
                console.log("STATUS: POSITION IS SAFE");
                console.log("No liquidation needed");
            }
        } else {
            console.log("STATUS: POSITION IS CLOSED/LIQUIDATED");
            console.log("Position no longer exists");
        }
    }
} 
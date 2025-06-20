// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title DebugRatio
 * @notice Debug ratio calculation step by step
 */
contract DebugRatio is Script {
    
    function run() external {
        console.log("DEBUGGING RATIO CALCULATION");
        console.log("===========================");
        
        // Read addresses from JSON
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address mockVcopOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        console.log("Contracts:");
        console.log("  FlexibleLoanManager:", flexibleLoanManager);
        console.log("  MockVCOPOracle:", mockVcopOracle);
        console.log("  Mock ETH:", mockETH);
        console.log("  Mock USDC:", mockUSDC);
        console.log("");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        MockVCOPOracle oracle = MockVCOPOracle(mockVcopOracle);
        
        // Check if position 1 exists
        console.log("=== STEP 1: CHECKING POSITION 1 ===");
        
        try loanManager.getPosition(1) returns (ILoanManager.LoanPosition memory position) {
            console.log("Position 1 found:");
            console.log("  Borrower:", position.borrower);
            console.log("  Collateral Asset:", position.collateralAsset);
            console.log("  Loan Asset:", position.loanAsset);
            console.log("  Collateral Amount:", position.collateralAmount);
            console.log("  Loan Amount:", position.loanAmount);
            console.log("  Interest Rate:", position.interestRate);
            console.log("  Is Active:", position.isActive);
            console.log("  Last Interest Update:", position.lastInterestUpdate);
            console.log("");
            
            // Step 2: Check total debt
            console.log("=== STEP 2: CHECKING TOTAL DEBT ===");
            
            try loanManager.getTotalDebt(1) returns (uint256 totalDebt) {
                console.log("  Total Debt:", totalDebt);
            } catch Error(string memory reason) {
                console.log("  Failed to get total debt:", reason);
            }
            
            try loanManager.getAccruedInterest(1) returns (uint256 interest) {
                console.log("  Accrued Interest:", interest);
            } catch Error(string memory reason) {
                console.log("  Failed to get accrued interest:", reason);
            }
            
            console.log("");
            
            // Step 3: Check asset values
            console.log("=== STEP 3: CHECKING ASSET VALUES ===");
            
            // Check collateral value
            console.log("  Checking collateral value...");
            console.log("  Collateral Asset:", position.collateralAsset);
            console.log("  Collateral Amount:", position.collateralAmount);
            
            try oracle.getPrice(position.collateralAsset, address(0)) returns (uint256 collateralPrice) {
                console.log("  Collateral Price from Oracle:", collateralPrice);
                uint256 calculatedCollateralValue = (position.collateralAmount * collateralPrice) / 1e18;
                console.log("  Calculated Collateral Value:", calculatedCollateralValue);
            } catch Error(string memory reason) {
                console.log("  Failed to get collateral price:", reason);
            }
            
            // Check loan value  
            console.log("  Checking loan value...");
            console.log("  Loan Asset:", position.loanAsset);
            console.log("  Loan Amount:", position.loanAmount);
            
            try oracle.getPrice(position.loanAsset, address(0)) returns (uint256 loanPrice) {
                console.log("  Loan Price from Oracle:", loanPrice);
                uint256 calculatedLoanValue = (position.loanAmount * loanPrice) / 1e6; // USDC has 6 decimals
                console.log("  Calculated Loan Value:", calculatedLoanValue);
            } catch Error(string memory reason) {
                console.log("  Failed to get loan price:", reason);
            }
            
            console.log("");
            
            // Step 4: Manual ratio calculation
            console.log("=== STEP 4: MANUAL RATIO CALCULATION ===");
            
            // Get prices again
            uint256 ethPrice = oracle.getPrice(position.collateralAsset, address(0));
            uint256 usdcPrice = oracle.getPrice(position.loanAsset, address(0));
            uint256 totalDebt = loanManager.getTotalDebt(1);
            
            console.log("  ETH Price:", ethPrice);
            console.log("  USDC Price:", usdcPrice);
            console.log("  Total Debt:", totalDebt);
            console.log("  Collateral Amount:", position.collateralAmount);
            console.log("");
            
            // Manual calculation
            uint256 collateralValueManual = (position.collateralAmount * ethPrice) / 1e18;
            uint256 debtValueManual = (totalDebt * usdcPrice) / 1e6;
            
            console.log("  Manual Collateral Value:", collateralValueManual);
            console.log("  Manual Debt Value:", debtValueManual);
            
            if (debtValueManual == 0) {
                console.log("  ERROR: Debt value is zero! This causes division by zero");
            } else {
                uint256 manualRatio = (collateralValueManual * 1000000) / debtValueManual;
                console.log("  Manual Ratio:", manualRatio);
                console.log("  Manual Ratio (percentage):", manualRatio / 10000);
            }
            
        } catch Error(string memory reason) {
            console.log("Failed to get position 1:", reason);
        }
        
        console.log("");
        console.log("=== DEBUGGING COMPLETED ===");
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

contract CreateTestPosition is Script {
    
    function run() external {
        console.log("CREATING TEST LOAN POSITION");
        console.log("===========================");
        console.log("");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("MockETH:", mockETH);
        console.log("MockUSDC:", mockUSDC);
        console.log("Borrower:", msg.sender);
        console.log("");
        
        vm.startBroadcast();
        
        // Step 1: Mint tokens for testing
        console.log("Step 1: Minting tokens for testing...");
        
        // Get token balances
        uint256 ethBalance = IERC20(mockETH).balanceOf(msg.sender);
        uint256 usdcBalance = IERC20(mockUSDC).balanceOf(msg.sender);
        
        console.log("Current ETH balance:", ethBalance);
        console.log("Current USDC balance:", usdcBalance);
        
        // If no tokens, notify user (tokens should have been minted during deployment)
        if (ethBalance < 5 ether) {
            console.log("WARNING: Insufficient ETH balance for testing");
            console.log("Mock tokens should have liquidity from deployment");
        }
        
        if (usdcBalance < 5000 * 1e6) {
            console.log("WARNING: Insufficient USDC balance for testing");
            console.log("Mock tokens should have liquidity from deployment");
        }
        
        // Refresh balances
        ethBalance = IERC20(mockETH).balanceOf(msg.sender);
        usdcBalance = IERC20(mockUSDC).balanceOf(msg.sender);
        
        console.log("Final ETH balance:", ethBalance);
        console.log("Final USDC balance:", usdcBalance);
        console.log("");
        
        // Step 2: Approve collateral
        console.log("Step 2: Approving collateral...");
        uint256 collateralAmount = 2 ether; // 2 ETH as collateral
        
        IERC20(mockETH).approve(flexibleLoanManager, collateralAmount);
        console.log("Approved", collateralAmount, "ETH for collateral");
        console.log("");
        
        // Step 3: Create loan position
        console.log("Step 3: Creating loan position...");
        
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: mockETH,
            loanAsset: mockUSDC,
            collateralAmount: collateralAmount,        // 2 ETH
            loanAmount: 2000 * 1e6,                   // 2,000 USDC
            maxLoanToValue: 800000,                   // 80% LTV (6 decimals)
            interestRate: 80000,                      // 8% APR (6 decimals)
            duration: 0                               // 0 = perpetual loan
        });
        
        console.log("Loan Terms:");
        console.log("  Collateral: 2 ETH (", collateralAmount, ")");
        console.log("  Loan: 2,000 USDC (", terms.loanAmount, ")");
        console.log("  Max LTV: 80%");
        console.log("  Interest Rate: 8% APR");
        console.log("");
        
        ILoanManager loanManager = ILoanManager(flexibleLoanManager);
        
        try loanManager.createLoan(terms) returns (uint256 positionId) {
            console.log("SUCCESS: Loan position created!");
            console.log("Position ID:", positionId);
            console.log("");
            
            // Step 4: Verify position
            console.log("Step 4: Verifying position...");
            
            try loanManager.getPosition(positionId) returns (ILoanManager.LoanPosition memory position) {
                console.log("Position verified:");
                console.log("  Borrower:", position.borrower);
                console.log("  Collateral Asset:", position.collateralAsset);
                console.log("  Loan Asset:", position.loanAsset);
                console.log("  Collateral Amount:", position.collateralAmount);
                console.log("  Loan Amount:", position.loanAmount);
                console.log("  Is Active:", position.isActive);
                console.log("");
                
                // Get collateralization ratio
                try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
                    console.log("Collateralization Ratio:", ratio);
                    console.log("Collateralization %:", ratio / 10000); // Convert to percentage
                    console.log("");
                    
                    // Check if can liquidate
                    try loanManager.canLiquidate(positionId) returns (bool canLiquidate) {
                        console.log("Can Liquidate:", canLiquidate);
                        console.log("");
                        
                        if (ratio >= 1200000) { // >= 120%
                            console.log("POSITION IS HEALTHY (Ratio >= 120%)");
                        } else if (ratio >= 1100000) { // >= 110%
                            console.log("WARNING: POSITION IS AT RISK (Ratio < 120%)");
                        } else {
                            console.log("CRITICAL: POSITION IS LIQUIDATABLE (Ratio < 110%)");
                        }
                        
                    } catch Error(string memory reason) {
                        console.log("Failed to check liquidation:", reason);
                    }
                    
                } catch Error(string memory reason) {
                    console.log("Failed to get collateralization ratio:", reason);
                }
                
            } catch Error(string memory reason) {
                console.log("Failed to get position details:", reason);
            }
            
        } catch Error(string memory reason) {
            console.log("FAILED to create loan position:", reason);
            console.log("");
            console.log("This might be due to:");
            console.log("1. Insufficient collateral ratio");
            console.log("2. Asset handler not configured");
            console.log("3. Oracle price issues");
            console.log("4. Insufficient liquidity");
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("TEST POSITION CREATION COMPLETED");
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title TestDirectLiquidation
 * @notice Test liquidation directly without automation
 */
contract TestDirectLiquidation is Script {
    
    function run() external {
        console.log("");
        console.log("TESTING DIRECT LIQUIDATION WITHOUT AUTOMATION");
        console.log("==============================================");
        console.log("This test creates a position and tests liquidation manually");
        console.log("");
        
        // Read addresses from JSON
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address mockVcopOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address testUser = vm.addr(privateKey);
        
        console.log("Contract addresses:");
        console.log("  FlexibleLoanManager:", flexibleLoanManager);
        console.log("  MockVCOPOracle:", mockVcopOracle);
        console.log("  Mock ETH:", mockETH);
        console.log("  Mock USDC:", mockUSDC);
        console.log("  Test User:", testUser);
        console.log("");
        
        vm.startBroadcast(privateKey);
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        MockVCOPOracle oracle = MockVCOPOracle(mockVcopOracle);
        
        // Step 1: Create loan position
        console.log("=== STEP 1: CREATING LOAN POSITION ===");
        
        uint256 collateralAmount = 2 ether; // 2 ETH
        uint256 loanAmount = 2000 * 1e6; // 2000 USDC
        
        console.log("Creating position:");
        console.log("  Collateral: 2 ETH");
        console.log("  Loan: 2000 USDC");
        
        // Check balances
        uint256 ethBalance = IERC20(mockETH).balanceOf(testUser);
        uint256 usdcBalance = IERC20(mockUSDC).balanceOf(testUser);
        console.log("  User ETH balance:", ethBalance / 1e18);
        console.log("  User USDC balance:", usdcBalance / 1e6);
        
        // Approve and create loan
        IERC20(mockETH).approve(flexibleLoanManager, collateralAmount);
        
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: mockETH,
            loanAsset: mockUSDC,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: 80 * 1e6, // 80%
            interestRate: 5 * 1e4, // 5%
            duration: 365 days
        });
        
        try loanManager.createLoan(terms) returns (uint256 positionId) {
            console.log("  Position created successfully! ID:", positionId);
            
            // Step 2: Check initial state
            console.log("");
            console.log("=== STEP 2: CHECKING INITIAL STATE ===");
            
            try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
                console.log("  Initial collateralization ratio:", ratio);
            } catch Error(string memory reason) {
                console.log("  Failed to get initial ratio:", reason);
            }
            
            try loanManager.canLiquidate(positionId) returns (bool canLiquidate) {
                console.log("  Can liquidate initially:", canLiquidate);
            } catch Error(string memory reason) {
                console.log("  Failed to check liquidation:", reason);
            }
            
            // Step 3: Crash ETH price
            console.log("");
            console.log("=== STEP 3: CRASHING ETH PRICE ===");
            
            uint256 originalPrice = oracle.getPrice(mockETH, address(0));
            console.log("  Original ETH price:", originalPrice / 1e6, "USD");
            
            uint256 newPrice = 1000 * 1e6; // $1000
            oracle.setEthPrice(newPrice);
            console.log("  New ETH price:", newPrice / 1e6, "USD");
            console.log("  Price drop:", (originalPrice - newPrice) * 100 / originalPrice, "%");
            
            // Step 4: Check liquidation status
            console.log("");
            console.log("=== STEP 4: CHECKING LIQUIDATION STATUS ===");
            
            try loanManager.getCollateralizationRatio(positionId) returns (uint256 newRatio) {
                console.log("  New collateralization ratio:", newRatio);
                
                // Check if ratio looks reasonable
                if (newRatio > 1000 * 1e6) { // More than 1000%
                    console.log("  WARNING: Ratio seems too high, possible calculation error");
                } else {
                    console.log("  Ratio looks reasonable");
                }
            } catch Error(string memory reason) {
                console.log("  Failed to get new ratio:", reason);
            }
            
            try loanManager.canLiquidate(positionId) returns (bool canLiquidate) {
                console.log("  Can liquidate after crash:", canLiquidate);
                
                if (canLiquidate) {
                    // Step 5: Execute liquidation
                    console.log("");
                    console.log("=== STEP 5: EXECUTING LIQUIDATION ===");
                    
                    try loanManager.liquidatePosition(positionId) {
                        console.log("  Liquidation executed successfully!");
                    } catch Error(string memory reason) {
                        console.log("  Liquidation failed:", reason);
                    }
                } else {
                    console.log("  Position is not liquidatable yet");
                    console.log("  Try reducing ETH price further");
                }
            } catch Error(string memory reason) {
                console.log("  Failed to check liquidation after crash:", reason);
            }
            
        } catch Error(string memory reason) {
            console.log("  Failed to create loan:", reason);
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== DIRECT LIQUIDATION TEST COMPLETED ===");
    }
} 
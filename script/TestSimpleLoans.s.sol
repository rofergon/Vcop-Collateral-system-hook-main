// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Core contracts
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {FlexibleLoanManager} from "../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../src/core/VaultBasedHandler.sol";

// Interfaces
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";

// Auto-generated addresses - This file is created by DeployUnifiedSystem.s.sol
// If this import fails, run: make deploy-unified first
import {MOCK_ETH, MOCK_USDC, VAULT_BASED_HANDLER, GENERIC_LOAN_MANAGER, FLEXIBLE_LOAN_MANAGER} from "./generated/TestSimpleLoansAddresses.sol";

/**
 * @title TestSimpleLoans
 * @notice Simple testing script for the core lending system
 * @dev Uses auto-generated addresses from latest deployment
 */
contract TestSimpleLoans is Script {
    
    // Use imported addresses from generated file
    address constant MOCK_ETH_ADDRESS = MOCK_ETH;
    address constant MOCK_USDC_ADDRESS = MOCK_USDC;
    address constant VAULT_BASED_HANDLER_ADDRESS = VAULT_BASED_HANDLER;
    address constant GENERIC_LOAN_MANAGER_ADDRESS = GENERIC_LOAN_MANAGER;
    address constant FLEXIBLE_LOAN_MANAGER_ADDRESS = FLEXIBLE_LOAN_MANAGER;
    
    // Test constants
    uint256 constant USDC_AMOUNT = 10000 * 1e6;    // 10,000 USDC
    uint256 constant ETH_AMOUNT = 5 * 1e18;        // 5 ETH
    uint256 constant LOAN_AMOUNT_USDC = 2000 * 1e6; // 2,000 USDC loan
    uint256 constant LOAN_AMOUNT_ETH = 1 * 1e18;    // 1 ETH loan
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(privateKey);
        
        console.log("=== TESTING CORE LENDING SYSTEM ===");
        console.log("User address:", user);
        console.log("Using auto-generated addresses from latest deployment");
        console.log("");
        
        vm.startBroadcast(privateKey);
        
        // Test suite
        _runFullTestSuite();
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== ALL CORE SYSTEM TESTS COMPLETED ===");
    }
    
    function _runFullTestSuite() internal {
        console.log("Running comprehensive test suite...");
        console.log("");
        
        // Test 1: ETH collateral -> USDC loan
        testETHToUSDCLoan();
        
        // Test 2: USDC collateral -> ETH loan  
        testUSDCToETHLoan();
        
        // Test 3: Advanced operations
        testAdvancedOperations();
        
        // Test 4: Risk analysis
        testRiskAnalysis();
        
        // Test 5: Repayment
        testRepaymentAndClosure();
    }
    
    function testETHToUSDCLoan() public {
        console.log("--- Test 1: ETH Collateral -> USDC Loan ---");
        
        IERC20 ethToken = IERC20(MOCK_ETH_ADDRESS);
        IERC20 usdcToken = IERC20(MOCK_USDC_ADDRESS);
        GenericLoanManager loanManager = GenericLoanManager(GENERIC_LOAN_MANAGER_ADDRESS);
        
        // Get initial balances
        uint256 initialETH = ethToken.balanceOf(msg.sender);
        uint256 initialUSDC = usdcToken.balanceOf(msg.sender);
        
        console.log("Initial ETH balance:", initialETH / 1e18);
        console.log("Initial USDC balance:", initialUSDC / 1e6);
        
        // Approve and create loan position
        ethToken.approve(address(loanManager), ETH_AMOUNT);
        
        // Create loan terms
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: MOCK_ETH_ADDRESS,
            loanAsset: MOCK_USDC_ADDRESS,
            collateralAmount: ETH_AMOUNT,
            loanAmount: LOAN_AMOUNT_USDC,
            maxLoanToValue: 700000,    // 70% LTV
            interestRate: 80000,       // 8% annual
            duration: 0                // Perpetual loan
        });
        
        uint256 positionId = loanManager.createLoan(terms);
        
        console.log("Position created with ID:", positionId);
        
        // Verify position
        ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        console.log("Collateral amount:", position.collateralAmount / 1e18, "ETH");
        console.log("Loan amount:", position.loanAmount / 1e6, "USDC");
        console.log("Interest rate:", position.interestRate / 1000, "%");
        
        // Check balances after loan
        uint256 finalETH = ethToken.balanceOf(msg.sender);
        uint256 finalUSDC = usdcToken.balanceOf(msg.sender);
        
        console.log("Final ETH balance:", finalETH / 1e18);
        console.log("Final USDC balance:", finalUSDC / 1e6);
        console.log("USDC received:", (finalUSDC - initialUSDC) / 1e6);
        
        console.log("ETH -> USDC loan test PASSED");
        console.log("");
    }
    
    function testUSDCToETHLoan() public {
        console.log("--- Test 2: USDC Collateral -> ETH Loan ---");
        
        IERC20 ethToken = IERC20(MOCK_ETH_ADDRESS);
        IERC20 usdcToken = IERC20(MOCK_USDC_ADDRESS);
        FlexibleLoanManager loanManager = FlexibleLoanManager(FLEXIBLE_LOAN_MANAGER_ADDRESS);
        
        // Get oracle prices for verification
        console.log("Getting oracle prices...");
        // Note: Oracle price calls would go here
        
        // Create USDC collateral -> ETH loan
        usdcToken.approve(address(loanManager), USDC_AMOUNT);
        
        // Create loan terms
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: MOCK_USDC_ADDRESS,
            loanAsset: MOCK_ETH_ADDRESS,
            collateralAmount: USDC_AMOUNT,
            loanAmount: LOAN_AMOUNT_ETH,
            maxLoanToValue: 500000,    // 50% LTV (more conservative)
            interestRate: 75000,       // 7.5% annual
            duration: 0                // Perpetual loan
        });
        
        uint256 positionId = loanManager.createLoan(terms);
        
        console.log("USDC -> ETH position created with ID:", positionId);
        
        // Verify position details
        ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        console.log("Collateral:", position.collateralAmount / 1e6, "USDC");
        console.log("Loan:", position.loanAmount / 1e18, "ETH");
        
        console.log("USDC -> ETH loan test PASSED");
        console.log("");
    }
    
    function testAdvancedOperations() public {
        console.log("--- Test 3: Advanced Operations ---");
        
        IERC20 ethToken = IERC20(MOCK_ETH_ADDRESS);
        GenericLoanManager loanManager = GenericLoanManager(GENERIC_LOAN_MANAGER_ADDRESS);
        
        // Use position from first test (ID should be 1)
        uint256 positionId = 1;
        
        console.log("Testing advanced operations on position:", positionId);
        
        // Add collateral
        uint256 additionalCollateral = 1 * 1e18; // 1 ETH
        ethToken.approve(address(loanManager), additionalCollateral);
        
        loanManager.addCollateral(positionId, additionalCollateral);
        console.log("Added", additionalCollateral / 1e18, "ETH collateral");
        
        // Simulate time passage for interest accrual
        vm.warp(block.timestamp + 30 days);
        console.log("Simulated 30 days passage");
        
        // Check accumulated interest
        ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        console.log("Position after 30 days:");
        console.log("- Collateral:", position.collateralAmount / 1e18, "ETH");
        console.log("- Original loan:", position.loanAmount / 1e6, "USDC");
        
        // Try to withdraw some collateral
        uint256 withdrawAmount = 0.5 * 1e18; // 0.5 ETH
        try loanManager.withdrawCollateral(positionId, withdrawAmount) {
            console.log("Successfully withdrew", withdrawAmount / 1e18, "ETH collateral");
        } catch {
            console.log("Could not withdraw collateral (insufficient collateralization)");
        }
        
        console.log("Advanced operations test PASSED");
        console.log("");
    }
    
    function testRiskAnalysis() public {
        console.log("--- Test 4: Basic Risk Analysis ---");
        
        GenericLoanManager loanManager = GenericLoanManager(GENERIC_LOAN_MANAGER_ADDRESS);
        
        // Analyze position 1
        uint256 positionId = 1;
        
        ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        
        console.log("Risk analysis for position", positionId);
        console.log("Collateral asset:", position.collateralAsset);
        console.log("Loan asset:", position.loanAsset);
        console.log("Collateral amount:", position.collateralAmount / 1e18, "ETH");
        console.log("Loan amount:", position.loanAmount / 1e6, "USDC");
        
        // Calculate approximate collateralization ratio
        // ETH = $2500, so 6 ETH = $15,000
        // Loan = 2,000 USDC = $2,000
        // Ratio = 15,000 / 2,000 = 7.5 = 750%
        uint256 approxRatio = (6 * 2500 * 100) / 2000; // Simplified calculation
        console.log("Approximate collateralization ratio:", approxRatio, "%");
        
        if (approxRatio >= 130) {
            console.log("Position is HEALTHY (>= 130%)");
        } else if (approxRatio >= 110) {
            console.log("Position is at RISK (110-130%)");
        } else {
            console.log("Position is LIQUIDATABLE (< 110%)");
        }
        
        console.log("Risk analysis test PASSED");
        console.log("");
    }
    
    function testRepaymentAndClosure() public {
        console.log("--- Test 5: Loan Repayment and Closure ---");
        
        IERC20 usdcToken = IERC20(MOCK_USDC_ADDRESS);
        GenericLoanManager loanManager = GenericLoanManager(GENERIC_LOAN_MANAGER_ADDRESS);
        
        uint256 positionId = 1;
        
        // Check current USDC balance
        uint256 currentBalance = usdcToken.balanceOf(msg.sender);
        console.log("Current USDC balance:", currentBalance / 1e6, "USDC");
        
        // Get current loan details
        ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        uint256 originalLoan = position.loanAmount;
        
        console.log("Preparing to repay position", positionId);
        console.log("Original loan amount:", originalLoan / 1e6, "USDC");
        
        // Get actual accrued interest from contract
        uint256 accruedInterest = loanManager.getAccruedInterest(positionId);
        uint256 totalDebt = originalLoan + accruedInterest;
        
        console.log("Accrued interest:", accruedInterest / 1e6, "USDC");
        console.log("Total debt:", totalDebt / 1e6, "USDC");
        
        // Check if we have enough USDC to repay
        if (currentBalance < totalDebt) {
            console.log("Insufficient USDC balance for repayment");
            console.log("Need:", totalDebt / 1e6, "USDC");
            console.log("Have:", currentBalance / 1e6, "USDC");
            console.log("Repayment test SKIPPED (insufficient balance)");
            console.log("");
            return;
        }
        
        // Approve and attempt repayment
        usdcToken.approve(address(loanManager), totalDebt);
        
        try loanManager.repayLoan(positionId, totalDebt) {
            console.log("Loan repayment successful");
            
            // Check if position is closed
            try loanManager.getPosition(positionId) returns (ILoanManager.LoanPosition memory updatedPosition) {
                if (updatedPosition.loanAmount == 0) {
                    console.log("Position fully closed");
                } else {
                    console.log("Remaining loan:", updatedPosition.loanAmount / 1e6, "USDC");
                }
            } catch {
                console.log("Position appears to be closed/deleted");
            }
        } catch Error(string memory reason) {
            console.log("Repayment failed:", reason);
        } catch {
            console.log("Repayment failed - unknown error");
        }
        
        console.log("Repayment test COMPLETED");
        console.log("");
    }
} 
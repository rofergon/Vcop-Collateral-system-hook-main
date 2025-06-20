// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title CreateRealPosition
 * @notice Creates a real loan position on blockchain for automation testing
 */
contract CreateRealPosition is Script {
    
    function run() external {
        console.log("");
        console.log("CREATING REAL LOAN POSITION FOR AUTOMATION TESTING");
        console.log("==================================================");
        console.log("This script creates a real position that can be tested");
        console.log("1. Load deployed contracts");
        console.log("2. Ensure user has tokens");
        console.log("3. Create loan position");
        console.log("4. Verify position created");
        console.log("");
        
        // Load contracts
        string memory json = vm.readFile("deployed-addresses-mock.json");
        FlexibleLoanManager loanManager = FlexibleLoanManager(
            vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager")
        );
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        console.log("Contract addresses:");
        console.log("  FlexibleLoanManager:", address(loanManager));
        console.log("  Mock ETH:", mockETH);
        console.log("  Mock USDC:", mockUSDC);
        console.log("");
        
        vm.startBroadcast();
        
        address user = msg.sender;
        console.log("Creating position for user:", user);
        
        // Check current balances
        uint256 ethBalance = IERC20(mockETH).balanceOf(user);
        uint256 usdcBalance = IERC20(mockUSDC).balanceOf(user);
        
        console.log("Current balances:");
        console.log("  ETH balance:", ethBalance / 1e18, "ETH");
        console.log("  USDC balance:", usdcBalance / 1e6, "USDC");
        console.log("");
        
        // Ensure user has enough tokens
        uint256 collateralAmount = 2 ether; // 2 ETH
        uint256 loanAmount = 2000 * 1e6;    // 2000 USDC
        
        if (ethBalance < collateralAmount) {
            console.log("Minting ETH for user...");
            address(mockETH).call(
                abi.encodeWithSignature("mint(address,uint256)", user, collateralAmount)
            );
            console.log("  Minted", collateralAmount / 1e18, "ETH");
        }
        
        // Approve tokens
        console.log("Approving ETH for loan manager...");
        IERC20(mockETH).approve(address(loanManager), collateralAmount);
        
        // Create loan position
        console.log("Creating loan position...");
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: mockETH,
            loanAsset: mockUSDC,
            collateralAmount: collateralAmount,  // 2 ETH
            loanAmount: loanAmount,              // 2000 USDC
            maxLoanToValue: 8000000,             // 800% max LTV
            interestRate: 50000,                 // 5%
            duration: 365 days                   // 1 year
        });
        
        uint256 positionId = loanManager.createLoan(terms);
        
        console.log("");
        console.log("POSITION CREATED SUCCESSFULLY!");
        console.log("===============================");
        console.log("Position ID:", positionId);
        console.log("Collateral: 2 ETH");
        console.log("Loan: 2000 USDC");
        console.log("User:", user);
        console.log("");
        
        // Verify position
        console.log("Verifying position...");
        ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        
        console.log("Position details:");
        console.log("  Borrower:", position.borrower);
        console.log("  Collateral Asset:", position.collateralAsset);
        console.log("  Loan Asset:", position.loanAsset);
        console.log("  Collateral Amount:", position.collateralAmount / 1e18, "ETH");
        console.log("  Loan Amount:", position.loanAmount / 1e6, "USDC");
        console.log("  Is Active:", position.isActive ? "YES" : "NO");
        
        // Check current ratio
        uint256 ratio = loanManager.getCollateralizationRatio(positionId);
        bool canLiquidate = loanManager.canLiquidate(positionId);
        
        console.log("");
        console.log("Position status:");
        if (ratio == type(uint256).max) {
            console.log("  Ratio: OVERFLOW (calculation error)");
        } else {
            console.log("  Ratio:", ratio / 1e4, "%");
        }
        console.log("  Can liquidate:", canLiquidate ? "YES" : "NO");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("NEXT STEPS:");
        console.log("1. Use MockVCOPOracle to crash ETH price");
        console.log("2. Test automation with: make test-automation-flow-complete");
        console.log("3. Or manually check: cast call <loanManager> \"canLiquidate(uint256)\" <positionId>");
        console.log("");
    }
} 
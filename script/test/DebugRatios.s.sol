// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title DebugRatios
 * @notice Debug collateralization ratio calculations
 */
contract DebugRatios is Script {
    
    function run() external {
        console.log("DEBUGGING COLLATERALIZATION RATIO CALCULATIONS");
        console.log("==============================================");
        
        // Load contracts
        string memory json = vm.readFile("deployed-addresses-mock.json");
        FlexibleLoanManager loanManager = FlexibleLoanManager(
            vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager")
        );
        MockVCOPOracle oracle = MockVCOPOracle(
            vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle")
        );
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        console.log("Contract addresses:");
        console.log("  LoanManager:", address(loanManager));
        console.log("  Oracle:", address(oracle));
        console.log("  ETH:", mockETH);
        console.log("  USDC:", mockUSDC);
        console.log("");
        
        // Get position details
        console.log("Position 1 details:");
        try loanManager.getPosition(1) returns (FlexibleLoanManager.LoanPosition memory position) {
            console.log("  Borrower:", position.borrower);
            console.log("  Collateral Asset:", position.collateralAsset);
            console.log("  Loan Asset:", position.loanAsset);
            console.log("  Collateral Amount:", position.collateralAmount);
            console.log("  Loan Amount:", position.loanAmount);
            console.log("  Is Active:", position.isActive);
            console.log("");
            
            // Get prices
            console.log("Getting prices...");
            uint256 ethPrice = oracle.getPrice(mockETH, address(0));
            uint256 usdcPrice = oracle.getPrice(mockUSDC, address(0));
            
            console.log("  ETH Price:", ethPrice);
            console.log("  USDC Price:", usdcPrice);
            console.log("");
            
            // Manual ratio calculation
            console.log("Manual ratio calculation:");
            uint256 collateralValue = (position.collateralAmount * ethPrice) / 1e18; // ETH has 18 decimals
            uint256 loanValue = (position.loanAmount * usdcPrice) / 1e6; // USDC has 6 decimals
            
            console.log("  Collateral Value (in base units):", collateralValue);
            console.log("  Loan Value (in base units):", loanValue);
            
            if (loanValue > 0) {
                uint256 manualRatio = (collateralValue * 1e6) / loanValue; // 6 decimals precision
                console.log("  Manual Ratio (6 decimals):", manualRatio);
                console.log("  Manual Ratio (%):", manualRatio / 1e4);
            }
            console.log("");
            
            // Contract ratio calculation
            console.log("Contract ratio calculation:");
            uint256 contractRatio = loanManager.getCollateralizationRatio(1);
            console.log("  Contract Ratio (raw):", contractRatio);
            
            // Accrued interest
            uint256 accruedInterest = loanManager.getAccruedInterest(1);
            console.log("  Accrued Interest:", accruedInterest);
            
        } catch Error(string memory reason) {
            console.log("Error getting position:", reason);
        }
        
        console.log("");
        console.log("DEBUGGING COMPLETED");
    }
} 
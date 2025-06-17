// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// Import loan managers
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {FlexibleLoanManager} from "../src/core/FlexibleLoanManager.sol";
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";

/**
 * @title LiquidationHelper
 * @notice Helper contract to handle liquidations properly in the core system
 * @dev This contract acts as a liquidator and handles the complete liquidation flow
 */
contract LiquidationHelper {
    using SafeERC20 for IERC20;
    
    // Events
    event LiquidationExecuted(address indexed loanManager, uint256 indexed positionId, uint256 collateralReceived);
    event PositionCreated(address indexed loanManager, uint256 indexed positionId, address borrower);
    
    /**
     * @dev Creates a risky loan position for testing liquidation
     * @param loanManager Address of the loan manager
     * @param collateralAsset Address of collateral token
     * @param loanAsset Address of loan token
     * @param collateralAmount Amount of collateral to deposit
     * @param loanAmount Amount to borrow (should be risky)
     * @param borrower Address that will own the position
     * @return positionId The ID of the created position
     */
    function createRiskyPosition(
        address loanManager,
        address collateralAsset,
        address loanAsset,
        uint256 collateralAmount,
        uint256 loanAmount,
        address borrower
    ) external returns (uint256 positionId) {
        // Transfer collateral from borrower to this contract
        IERC20(collateralAsset).safeTransferFrom(borrower, address(this), collateralAmount);
        
        // Approve loan manager to spend collateral
        IERC20(collateralAsset).approve(loanManager, collateralAmount);
        
        // Create loan terms with high LTV (risky)
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: collateralAsset,
            loanAsset: loanAsset,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: 950000,  // 95% LTV - Very risky
            interestRate: 200000,    // 20% annual interest
            duration: 0              // Perpetual loan
        });
        
        // Create the loan position
        positionId = ILoanManager(loanManager).createLoan(terms);
        
        // Transfer the borrowed tokens to the borrower
        IERC20(loanAsset).safeTransfer(borrower, loanAmount);
        
        emit PositionCreated(loanManager, positionId, borrower);
        return positionId;
    }
    
    /**
     * @dev Executes a liquidation of an underwater position
     * @param loanManager Address of the loan manager
     * @param positionId ID of the position to liquidate
     * @param liquidator Address that will receive the liquidation rewards
     */
    function executeLiquidation(
        address loanManager,
        uint256 positionId,
        address liquidator
    ) external {
        // Get position details before liquidation
        ILoanManager.LoanPosition memory position = ILoanManager(loanManager).getPosition(positionId);
        require(position.isActive, "Position not active");
        
        // Check if position can be liquidated
        require(ILoanManager(loanManager).canLiquidate(positionId), "Position not liquidatable");
        
        // Get total debt to repay
        uint256 totalDebt = ILoanManager(loanManager).getTotalDebt(positionId);
        
        // Transfer debt tokens from liquidator to this contract
        IERC20(position.loanAsset).safeTransferFrom(liquidator, address(this), totalDebt);
        
        // Approve loan manager to spend debt tokens for repayment
        IERC20(position.loanAsset).approve(loanManager, totalDebt);
        
        // Get collateral balance before liquidation
        uint256 collateralBefore = IERC20(position.collateralAsset).balanceOf(address(this));
        
        // Execute liquidation - this will repay debt and transfer collateral to msg.sender (this contract)
        ILoanManager(loanManager).liquidatePosition(positionId);
        
        // Get collateral balance after liquidation
        uint256 collateralAfter = IERC20(position.collateralAsset).balanceOf(address(this));
        uint256 collateralReceived = collateralAfter - collateralBefore;
        
        // Transfer all received collateral to the liquidator
        if (collateralReceived > 0) {
            IERC20(position.collateralAsset).safeTransfer(liquidator, collateralReceived);
        }
        
        emit LiquidationExecuted(loanManager, positionId, collateralReceived);
    }
    
    /**
     * @dev Checks if a position can be liquidated
     * @param loanManager Address of the loan manager
     * @param positionId ID of the position to check
     * @return canLiquidate Whether the position can be liquidated
     * @return collateralizationRatio Current collateralization ratio
     * @return totalDebt Total debt amount
     */
    function checkLiquidationStatus(
        address loanManager,
        uint256 positionId
    ) external view returns (
        bool canLiquidate,
        uint256 collateralizationRatio,
        uint256 totalDebt
    ) {
        canLiquidate = ILoanManager(loanManager).canLiquidate(positionId);
        collateralizationRatio = ILoanManager(loanManager).getCollateralizationRatio(positionId);
        totalDebt = ILoanManager(loanManager).getTotalDebt(positionId);
    }
    
    /**
     * @dev Simulates time passing to accrue interest
     * @param loanManager Address of the loan manager
     * @param positionId ID of the position
     */
    function accrueInterest(address loanManager, uint256 positionId) external {
        ILoanManager(loanManager).updateInterest(positionId);
    }
    
    /**
     * @dev Emergency function to recover stuck tokens
     * @param token Token address
     * @param amount Amount to recover
     * @param to Recipient address
     */
    function emergencyRecover(address token, uint256 amount, address to) external {
        IERC20(token).safeTransfer(to, amount);
    }
    
    /**
     * @dev Gets position information
     * @param loanManager Address of the loan manager
     * @param positionId ID of the position
     * @return position Position details
     */
    function getPosition(
        address loanManager,
        uint256 positionId
    ) external view returns (ILoanManager.LoanPosition memory position) {
        return ILoanManager(loanManager).getPosition(positionId);
    }
} 
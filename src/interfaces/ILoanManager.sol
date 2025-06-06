// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ILoanManager
 * @notice Interface for managing loans with any collateral and loan asset combination
 */
interface ILoanManager {
    struct LoanPosition {
        address borrower;
        address collateralAsset;
        address loanAsset;
        uint256 collateralAmount;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 createdAt;
        uint256 lastInterestUpdate;
        bool isActive;
    }
    
    struct LoanTerms {
        address collateralAsset;
        address loanAsset;
        uint256 collateralAmount;
        uint256 loanAmount;
        uint256 maxLoanToValue;  // Maximum loan-to-value ratio
        uint256 interestRate;    // Annual interest rate
        uint256 duration;        // Loan duration in seconds (0 = perpetual)
    }
    
    /**
     * @dev Creates a new loan position
     * @param terms Loan terms
     * @return positionId The ID of the created position
     */
    function createLoan(LoanTerms calldata terms) external returns (uint256 positionId);
    
    /**
     * @dev Adds collateral to an existing position
     * @param positionId Position ID
     * @param amount Amount of collateral to add
     */
    function addCollateral(uint256 positionId, uint256 amount) external;
    
    /**
     * @dev Withdraws collateral from a position (if ratio allows)
     * @param positionId Position ID
     * @param amount Amount of collateral to withdraw
     */
    function withdrawCollateral(uint256 positionId, uint256 amount) external;
    
    /**
     * @dev Repays part or all of the loan
     * @param positionId Position ID
     * @param amount Amount to repay
     */
    function repayLoan(uint256 positionId, uint256 amount) external;
    
    /**
     * @dev Liquidates an undercollateralized position
     * @param positionId Position ID
     */
    function liquidatePosition(uint256 positionId) external;
    
    /**
     * @dev Updates interest for a position
     * @param positionId Position ID
     */
    function updateInterest(uint256 positionId) external;
    
    /**
     * @dev Gets position details
     * @param positionId Position ID
     * @return position Loan position details
     */
    function getPosition(uint256 positionId) external view returns (LoanPosition memory position);
    
    /**
     * @dev Gets current collateralization ratio
     * @param positionId Position ID
     * @return ratio Current ratio (6 decimals)
     */
    function getCollateralizationRatio(uint256 positionId) external view returns (uint256 ratio);
    
    /**
     * @dev Checks if position can be liquidated
     * @param positionId Position ID
     * @return canLiquidate True if position can be liquidated
     */
    function canLiquidate(uint256 positionId) external view returns (bool canLiquidate);
    
    /**
     * @dev Gets maximum borrowable amount for given collateral
     * @param collateralAsset Collateral asset address
     * @param loanAsset Loan asset address
     * @param collateralAmount Amount of collateral
     * @return maxBorrow Maximum borrowable amount
     */
    function getMaxBorrowAmount(
        address collateralAsset,
        address loanAsset,
        uint256 collateralAmount
    ) external view returns (uint256 maxBorrow);
    
    /**
     * @dev Gets accrued interest for a position
     * @param positionId Position ID
     * @return interest Accrued interest amount
     */
    function getAccruedInterest(uint256 positionId) external view returns (uint256 interest);
    
    /**
     * @dev Gets total debt (principal + interest) for a position
     * @param positionId Position ID
     * @return totalDebt Total debt amount
     */
    function getTotalDebt(uint256 positionId) external view returns (uint256 totalDebt);
    
    /**
     * @dev Gets all position IDs for a user
     * @param user User address
     * @return positionIds Array of position IDs owned by the user
     */
    function getUserPositions(address user) external view returns (uint256[] memory positionIds);
    
    // Events
    event LoanCreated(
        uint256 indexed positionId,
        address indexed borrower,
        address collateralAsset,
        address loanAsset,
        uint256 collateralAmount,
        uint256 loanAmount
    );
    event CollateralAdded(uint256 indexed positionId, uint256 amount);
    event CollateralWithdrawn(uint256 indexed positionId, uint256 amount);
    event LoanRepaid(uint256 indexed positionId, uint256 amount);
    event PositionLiquidated(uint256 indexed positionId, address indexed liquidator);
    event InterestUpdated(uint256 indexed positionId, uint256 newInterest);
} 
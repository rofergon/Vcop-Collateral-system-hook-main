// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ILoanAutomation
 * @notice Interface for loan manager contracts to interact with automation system
 */
interface ILoanAutomation {
    /**
     * @dev Gets the total number of active positions for automation scanning
     */
    function getTotalActivePositions() external view returns (uint256);
    
    /**
     * @dev Gets positions in a specific range for batch processing
     * @param startIndex Starting index (inclusive)
     * @param endIndex Ending index (inclusive)
     * @return positionIds Array of position IDs in the range
     */
    function getPositionsInRange(uint256 startIndex, uint256 endIndex) 
        external view returns (uint256[] memory positionIds);
    
    /**
     * @dev Checks if a position is at risk of liquidation
     * @param positionId The position ID to check
     * @return isAtRisk True if position should be liquidated
     * @return riskLevel Risk level (0-100, where 100+ means immediate liquidation needed)
     */
    function isPositionAtRisk(uint256 positionId) 
        external view returns (bool isAtRisk, uint256 riskLevel);
    
    /**
     * @dev Performs automated liquidation of a position
     * @param positionId Position to liquidate
     * @return success True if liquidation was successful
     * @return liquidatedAmount Amount liquidated
     */
    function automatedLiquidation(uint256 positionId) 
        external returns (bool success, uint256 liquidatedAmount);
    
    /**
     * @dev Gets position details for automation purposes
     * @param positionId Position ID
     * @return borrower Address of the borrower
     * @return collateralValue Current collateral value
     * @return debtValue Current debt value
     * @return healthFactor Health factor (lower means riskier)
     */
    function getPositionHealthData(uint256 positionId) 
        external view returns (
            address borrower,
            uint256 collateralValue,
            uint256 debtValue,
            uint256 healthFactor
        );
    
    /**
     * @dev Checks if automation is enabled for this contract
     */
    function isAutomationEnabled() external view returns (bool);
    
    /**
     * @dev Sets the authorized automation contract
     * @param automationContract Address of the automation contract
     */
    function setAutomationContract(address automationContract) external;
} 
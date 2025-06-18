// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ILoanAutomation} from "../interfaces/ILoanAutomation.sol";
import {ILoanManager} from "../../interfaces/ILoanManager.sol";
import {IAssetHandler} from "../../interfaces/IAssetHandler.sol";
import {RiskCalculator} from "../../core/RiskCalculator.sol";

/**
 * @title LoanManagerAutomationAdapter
 * @notice Adapter contract that adds automation capabilities to existing loan managers
 * @dev Implements ILoanAutomation interface and delegates to the actual loan manager
 */
contract LoanManagerAutomationAdapter is ILoanAutomation, Ownable {
    
    // The loan manager this adapter is for
    ILoanManager public immutable loanManager;
    
    // Risk calculator for position evaluation
    RiskCalculator public immutable riskCalculator;
    
    // Automation settings
    bool public automationEnabled = true;
    address public authorizedAutomationContract;
    uint256 public liquidationCooldown = 300; // 5 minutes cooldown between liquidations
    
    // Liquidation tracking
    mapping(uint256 => uint256) public lastLiquidationAttempt;
    
    // Position tracking for efficient iteration
    uint256[] public allPositionIds;
    mapping(uint256 => uint256) public positionIndexMap; // positionId => index in allPositionIds
    mapping(uint256 => bool) public isPositionTracked;
    
    // Events
    event AutomationToggled(bool enabled);
    event AutomationContractSet(address indexed automationContract);
    event PositionAdded(uint256 indexed positionId);
    event PositionRemoved(uint256 indexed positionId);
    
    constructor(
        address _loanManager,
        address _riskCalculator
    ) Ownable(msg.sender) {
        require(_loanManager != address(0), "Invalid loan manager");
        require(_riskCalculator != address(0), "Invalid risk calculator");
        
        loanManager = ILoanManager(_loanManager);
        riskCalculator = RiskCalculator(_riskCalculator);
    }
    
    /**
     * @dev Gets the total number of active positions for automation scanning
     */
    function getTotalActivePositions() external view override returns (uint256) {
        return allPositionIds.length;
    }
    
    /**
     * @dev Gets positions in a specific range for batch processing
     */
    function getPositionsInRange(uint256 startIndex, uint256 endIndex) 
        external view override returns (uint256[] memory positionIds) {
        
        require(startIndex <= endIndex, "Invalid range");
        
        uint256 totalPositions = allPositionIds.length;
        if (startIndex >= totalPositions) {
            return new uint256[](0);
        }
        
        uint256 actualEndIndex = endIndex >= totalPositions ? totalPositions - 1 : endIndex;
        uint256 rangeSize = actualEndIndex - startIndex + 1;
        
        positionIds = new uint256[](rangeSize);
        for (uint256 i = 0; i < rangeSize; i++) {
            positionIds[i] = allPositionIds[startIndex + i];
        }
        
        return positionIds;
    }
    
    /**
     * @dev Checks if a position is at risk of liquidation
     */
    function isPositionAtRisk(uint256 positionId) 
        external view override returns (bool isAtRisk, uint256 riskLevel) {
        
        // Get position details from loan manager
        ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        
        if (!position.isActive) {
            return (false, 0);
        }
        
        // Use your existing risk calculator to determine risk
        RiskCalculator.RiskMetrics memory metrics = riskCalculator.calculateRiskMetrics(positionId);
        
        riskLevel = metrics.healthFactor < 1000000 ? 100 : // Health factor < 1.0 = immediate liquidation
                   metrics.healthFactor < 1100000 ? 90 :  // Health factor < 1.1 = critical
                   metrics.healthFactor < 1200000 ? 75 :  // Health factor < 1.2 = danger  
                   metrics.healthFactor < 1500000 ? 50 :  // Health factor < 1.5 = warning
                   0;                                     // Healthy
        
        isAtRisk = metrics.isLiquidatable;
    }
    
    /**
     * @dev Performs automated liquidation of a position
     */
    function automatedLiquidation(uint256 positionId) 
        external override returns (bool success, uint256 liquidatedAmount) {
        
        // Security: only authorized automation contract can call this
        require(msg.sender == authorizedAutomationContract, "Unauthorized");
        require(automationEnabled, "Automation disabled");
        
        // Check cooldown period
        require(
            block.timestamp >= lastLiquidationAttempt[positionId] + liquidationCooldown,
            "Liquidation cooldown active"
        );
        
        // Double-check position is still at risk
        (bool isAtRisk,) = this.isPositionAtRisk(positionId);
        require(isAtRisk, "Position not at risk");
        
        // Record liquidation attempt
        lastLiquidationAttempt[positionId] = block.timestamp;
        
        // Get position details for liquidation amount calculation
        uint256 totalDebt = loanManager.getTotalDebt(positionId);
        
        // Attempt liquidation through loan manager
        try loanManager.liquidatePosition(positionId) {
            // Liquidation successful
            success = true;
            liquidatedAmount = totalDebt;
            
            // Remove from tracking since position is now closed
            _removePositionFromTracking(positionId);
            
        } catch Error(string memory) {
            // Liquidation failed
            success = false;
            liquidatedAmount = 0;
            
            // Log the failure reason (in a real system, you might want to emit an event)
            // For now, we just return false
        } catch {
            // Liquidation failed with unknown error
            success = false;
            liquidatedAmount = 0;
        }
        
        return (success, liquidatedAmount);
    }
    
    /**
     * @dev Gets position details for automation purposes
     */
    function getPositionHealthData(uint256 positionId) 
        external view override returns (
            address borrower,
            uint256 collateralValue,
            uint256 debtValue,
            uint256 healthFactor
        ) {
        
        ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        
        if (!position.isActive) {
            return (address(0), 0, 0, 0);
        }
        
        borrower = position.borrower;
        
        // Get total debt
        uint256 totalDebt = loanManager.getTotalDebt(positionId);
        
        // Use your existing risk calculator
        RiskCalculator.RiskMetrics memory metrics = riskCalculator.calculateRiskMetrics(positionId);
        
        collateralValue = metrics.liquidationThreshold; // Using existing calculation
        debtValue = totalDebt;
        healthFactor = metrics.healthFactor;
        
        return (borrower, collateralValue, debtValue, healthFactor);
    }
    
    /**
     * @dev Checks if automation is enabled for this contract
     */
    function isAutomationEnabled() external view override returns (bool) {
        return automationEnabled;
    }
    
    /**
     * @dev Sets the authorized automation contract
     */
    function setAutomationContract(address automationContract) external override onlyOwner {
        require(automationContract != address(0), "Invalid automation contract");
        authorizedAutomationContract = automationContract;
        emit AutomationContractSet(automationContract);
    }
    
    /**
     * @dev Toggles automation on/off
     */
    function setAutomationEnabled(bool enabled) external onlyOwner {
        automationEnabled = enabled;
        emit AutomationToggled(enabled);
    }
    
    /**
     * @dev Sets liquidation cooldown period
     */
    function setLiquidationCooldown(uint256 cooldownSeconds) external onlyOwner {
        require(cooldownSeconds <= 3600, "Cooldown too long"); // Max 1 hour
        liquidationCooldown = cooldownSeconds;
    }
    
    /**
     * @dev Adds a position to tracking (called when new positions are created)
     */
    function addPositionToTracking(uint256 positionId) external {
        require(
            msg.sender == address(loanManager) || msg.sender == owner(),
            "Unauthorized"
        );
        
        if (!isPositionTracked[positionId]) {
            allPositionIds.push(positionId);
            positionIndexMap[positionId] = allPositionIds.length - 1;
            isPositionTracked[positionId] = true;
            
            emit PositionAdded(positionId);
        }
    }
    
    /**
     * @dev Removes a position from tracking (called when positions are closed/liquidated)
     */
    function removePositionFromTracking(uint256 positionId) external {
        require(
            msg.sender == address(loanManager) || msg.sender == owner(),
            "Unauthorized"
        );
        
        _removePositionFromTracking(positionId);
    }
    
    /**
     * @dev Internal function to remove position from tracking
     */
    function _removePositionFromTracking(uint256 positionId) internal {
        if (isPositionTracked[positionId]) {
            uint256 index = positionIndexMap[positionId];
            uint256 lastIndex = allPositionIds.length - 1;
            
            // Move last element to the index of the element to remove
            if (index != lastIndex) {
                uint256 lastPositionId = allPositionIds[lastIndex];
                allPositionIds[index] = lastPositionId;
                positionIndexMap[lastPositionId] = index;
            }
            
            // Remove last element
            allPositionIds.pop();
            delete positionIndexMap[positionId];
            delete isPositionTracked[positionId];
            
            emit PositionRemoved(positionId);
        }
    }
    
    /**
     * @dev Bulk initialization of positions (for existing loan managers)
     */
    function initializePositionTracking(uint256[] calldata positionIds) external onlyOwner {
        for (uint256 i = 0; i < positionIds.length; i++) {
            uint256 positionId = positionIds[i];
            
            // Verify position exists and is active
            ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
            if (position.isActive && !isPositionTracked[positionId]) {
                allPositionIds.push(positionId);
                positionIndexMap[positionId] = allPositionIds.length - 1;
                isPositionTracked[positionId] = true;
                
                emit PositionAdded(positionId);
            }
        }
    }
    
    /**
     * @dev Sync position tracking with loan manager (cleanup closed positions)
     */
    function syncPositionTracking() external {
        require(
            msg.sender == authorizedAutomationContract || msg.sender == owner(),
            "Unauthorized"
        );
        
        // Check all tracked positions and remove closed ones
        uint256 i = 0;
        while (i < allPositionIds.length) {
            uint256 positionId = allPositionIds[i];
            ILoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
            
            if (!position.isActive) {
                _removePositionFromTracking(positionId);
                // Don't increment i since we removed an element
            } else {
                i++;
            }
        }
    }
    
    /**
     * @dev Gets tracking statistics
     */
    function getTrackingStats() external view returns (
        uint256 totalTracked,
        uint256 totalAtRisk,
        uint256 totalLiquidatable
    ) {
        totalTracked = allPositionIds.length;
        
        for (uint256 i = 0; i < allPositionIds.length; i++) {
            (bool isAtRisk, uint256 riskLevel) = this.isPositionAtRisk(allPositionIds[i]);
            
            if (riskLevel > 60) { // Danger zone or higher
                totalAtRisk++;
            }
            
            if (isAtRisk) {
                totalLiquidatable++;
            }
        }
        
        return (totalTracked, totalAtRisk, totalLiquidatable);
    }
    
    /**
     * @dev Gets asset handler for a given asset (helper function)
     */
    function _getAssetHandler(address) internal pure returns (IAssetHandler) {
        // This is a simplified version - in reality, you'd query the loan manager
        // or have a registry of asset handlers
        
        // For now, we'll try different handler types
        // This should be improved to match your actual asset handler architecture
        revert("Asset handler lookup not implemented - needs integration with your asset handler system");
    }
} 
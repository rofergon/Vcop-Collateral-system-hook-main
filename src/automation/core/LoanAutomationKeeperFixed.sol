// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// ✅ CORRECTO: Import AutomationCompatible (no solo la interfaz)
import {AutomationCompatible} from "lib/chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ILoanAutomation} from "../interfaces/ILoanAutomation.sol";
import {IAutomationRegistry} from "../interfaces/IAutomationRegistry.sol";

/**
 * @title LoanAutomationKeeperFixed 
 * @notice FIXED: Properly implements AutomationCompatible for Chainlink UI detection
 * @dev Extends AutomationCompatible (not just interface) for full compatibility
 */
contract LoanAutomationKeeperFixed is AutomationCompatible, Ownable {
    
    IAutomationRegistry public automationRegistry;
    uint256 public minRiskThreshold = 75;
    bool public emergencyPause = false;
    
    // Performance tracking
    uint256 public totalLiquidations;
    uint256 public totalUpkeeps;
    uint256 public lastExecutionTimestamp;
    
    event UpkeepPerformed(uint256 liquidationsExecuted, uint256 timestamp);
    
    constructor(address _automationRegistry) Ownable(msg.sender) {
        require(_automationRegistry != address(0), "Invalid registry address");
        automationRegistry = IAutomationRegistry(_automationRegistry);
    }
    
    /**
     * @dev ✅ CHAINLINK COMPATIBLE: checkUpkeep function
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        
        if (emergencyPause) {
            return (false, bytes(""));
        }
        
        // For basic detection, return simple response
        if (checkData.length == 0) {
            return (false, bytes(""));
        }
        
        try this.decodeCheckData(checkData) returns (
            address loanManager,
            uint256 startIndex,
            uint256 batchSize
        ) {
            if (!automationRegistry.isManagerActive(loanManager)) {
                return (false, bytes(""));
            }
            
            ILoanAutomation loanAutomation = ILoanAutomation(loanManager);
            
            if (!loanAutomation.isAutomationEnabled()) {
                return (false, bytes(""));
            }
            
            uint256 totalPositions = loanAutomation.getTotalActivePositions();
            if (totalPositions == 0) {
                return (false, bytes(""));
            }
            
            // Check if any positions need liquidation
            uint256[] memory positions = loanAutomation.getPositionsInRange(startIndex, startIndex + batchSize - 1);
            
            for (uint256 i = 0; i < positions.length; i++) {
                (bool isAtRisk, uint256 riskLevel) = loanAutomation.isPositionAtRisk(positions[i]);
                if (isAtRisk && riskLevel >= minRiskThreshold) {
                    performData = abi.encode(loanManager, positions[i], block.timestamp);
                    return (true, performData);
                }
            }
            
            return (false, bytes(""));
            
        } catch {
            return (false, bytes(""));
        }
    }
    
    /**
     * @dev ✅ CHAINLINK COMPATIBLE: performUpkeep function
     */
    function performUpkeep(bytes calldata performData) external override {
        require(!emergencyPause, "Emergency paused");
        
        if (performData.length == 0) {
            return;
        }
        
        (address loanManager, uint256 positionId, uint256 timestamp) = 
            abi.decode(performData, (address, uint256, uint256));
        
        require(automationRegistry.isManagerActive(loanManager), "Manager not active");
        require(block.timestamp - timestamp <= 300, "Data too old");
        
        ILoanAutomation loanAutomation = ILoanAutomation(loanManager);
        
        try loanAutomation.automatedLiquidation(positionId) returns (bool success, uint256) {
            if (success) {
                totalLiquidations++;
            }
        } catch {
            // Liquidation failed, continue
        }
        
        totalUpkeeps++;
        lastExecutionTimestamp = block.timestamp;
        
        emit UpkeepPerformed(totalLiquidations, block.timestamp);
    }
    
    /**
     * @dev Helper function to decode checkData
     */
    function decodeCheckData(bytes calldata checkData) external pure returns (
        address loanManager,
        uint256 startIndex,
        uint256 batchSize
    ) {
        return abi.decode(checkData, (address, uint256, uint256));
    }
    
    /**
     * @dev Generate checkData for registration
     */
    function generateCheckData(
        address loanManager,
        uint256 startIndex,
        uint256 batchSize
    ) external pure returns (bytes memory) {
        return abi.encode(loanManager, startIndex, batchSize);
    }
    
    /**
     * @dev Set emergency pause
     */
    function setEmergencyPause(bool _paused) external onlyOwner {
        emergencyPause = _paused;
    }
    
    /**
     * @dev Set minimum risk threshold
     */
    function setMinRiskThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold >= 50 && _threshold <= 95, "Invalid threshold");
        minRiskThreshold = _threshold;
    }
    
    /**
     * @dev Get automation statistics
     */
    function getStats() external view returns (uint256, uint256, uint256) {
        return (totalLiquidations, totalUpkeeps, lastExecutionTimestamp);
    }
} 
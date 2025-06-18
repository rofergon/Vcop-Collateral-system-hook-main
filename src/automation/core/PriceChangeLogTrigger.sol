// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ILoanAutomation} from "../interfaces/ILoanAutomation.sol";
import {RiskCalculator} from "../../core/RiskCalculator.sol";

// Chainlink Log Automation Interface (local definition)
interface ILogAutomation {
    struct Log {
        uint256 index;
        uint256 timestamp;
        bytes32 txHash;
        uint256 blockNumber;
        bytes32 blockHash;
        address source;
        bytes32[] topics;
        bytes data;
    }

    function checkLog(
        Log calldata log,
        bytes calldata checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

/**
 * @title PriceChangeLogTrigger
 * @notice Log trigger automation for immediate liquidations on significant price changes
 * @dev Listens for price update events and triggers immediate position checks
 */
contract PriceChangeLogTrigger is ILogAutomation, Ownable {
    
    // Risk calculator for position evaluation
    RiskCalculator public immutable riskCalculator;
    
    // Configuration
    uint256 public priceChangeThreshold = 100000; // 10% change (6 decimals: 10% = 100000)
    uint256 public maxPositionsPerTrigger = 20;    // Limit positions checked per trigger
    bool public emergencyPause = false;
    
    // Registered loan managers for monitoring
    mapping(address => bool) public registeredLoanManagers;
    address[] public loanManagersList;
    
    // Price monitoring
    mapping(address => uint256) public lastKnownPrices;
    mapping(address => uint256) public lastPriceUpdate;
    
    // Statistics
    uint256 public totalTriggersProcessed;
    uint256 public totalLiquidationsExecuted;
    
    // Events
    event PriceChangeDetected(address indexed asset, uint256 oldPrice, uint256 newPrice, uint256 changePercent);
    event EmergencyLiquidationTriggered(address indexed loanManager, uint256 positionsChecked, uint256 liquidated);
    event LoanManagerRegistered(address indexed loanManager);
    event LoanManagerUnregistered(address indexed loanManager);
    
    constructor(address _riskCalculator) Ownable(msg.sender) {
        require(_riskCalculator != address(0), "Invalid risk calculator");
        riskCalculator = RiskCalculator(_riskCalculator);
    }
    
    /**
     * @dev Chainlink Log Automation checkLog function
     * @param log The log event that triggered this check
     */
    function checkLog(
        Log calldata log,
        bytes calldata /* checkData */
    ) external override returns (bool upkeepNeeded, bytes memory performData) {
        
        // Emergency pause check
        if (emergencyPause) {
            return (false, bytes(""));
        }
        
        // Check if this is a price update event we care about
        // Example: Looking for PriceUpdated(address asset, uint256 price) events
        if (log.topics.length < 2) {
            return (false, bytes(""));
        }
        
        // Extract asset address from log topics
        address asset = address(uint160(uint256(log.topics[1])));
        
        // Decode new price from log data
        uint256 newPrice = abi.decode(log.data, (uint256));
        
        // Check if price change is significant
        uint256 lastPrice = lastKnownPrices[asset];
        if (lastPrice == 0) {
            // First time seeing this asset, just store the price
            return (false, bytes(""));
        }
        
        // Calculate percentage change
        uint256 changePercent;
        if (newPrice > lastPrice) {
            changePercent = ((newPrice - lastPrice) * 1000000) / lastPrice;
        } else {
            changePercent = ((lastPrice - newPrice) * 1000000) / lastPrice;
        }
        
        // Check if change exceeds threshold
        if (changePercent >= priceChangeThreshold) {
            upkeepNeeded = true;
            
            // Prepare data for performUpkeep
            performData = abi.encode(
                asset,
                lastPrice,
                newPrice,
                changePercent,
                block.timestamp
            );
            
            emit PriceChangeDetected(asset, lastPrice, newPrice, changePercent);
        }
        
        return (upkeepNeeded, performData);
    }
    
    /**
     * @dev Chainlink Log Automation performUpkeep function
     * @param performData Data from checkLog containing price change info
     */
    function performUpkeep(bytes calldata performData) external override {
        require(!emergencyPause, "Emergency paused");
        
        // Decode price change data
        (
            address asset,
            ,
            uint256 newPrice,
            ,
            uint256 timestamp
        ) = abi.decode(performData, (address, uint256, uint256, uint256, uint256));
        
        // Update stored price
        lastKnownPrices[asset] = newPrice;
        lastPriceUpdate[asset] = timestamp;
        
        // Trigger emergency checks on all registered loan managers
        uint256 totalLiquidated = 0;
        
        for (uint256 i = 0; i < loanManagersList.length; i++) {
            address loanManager = loanManagersList[i];
            
            if (registeredLoanManagers[loanManager]) {
                uint256 liquidated = _performEmergencyCheck(loanManager, asset);
                totalLiquidated += liquidated;
            }
        }
        
        // Update statistics
        totalTriggersProcessed++;
        totalLiquidationsExecuted += totalLiquidated;
        
        emit EmergencyLiquidationTriggered(address(0), loanManagersList.length, totalLiquidated);
    }
    
    /**
     * @dev Performs emergency check on a specific loan manager
     * @param loanManager Address of the loan manager to check
     * @param changedAsset Asset that had significant price change
     * @return liquidatedCount Number of positions liquidated
     */
    function _performEmergencyCheck(
        address loanManager,
        address changedAsset
    ) internal returns (uint256 liquidatedCount) {
        
        try ILoanAutomation(loanManager).getTotalActivePositions() returns (uint256 totalPositions) {
            
            uint256 positionsToCheck = totalPositions > maxPositionsPerTrigger 
                ? maxPositionsPerTrigger 
                : totalPositions;
            
            // Get positions to check (prioritize those with the changed asset)
            uint256[] memory positionsInRange = ILoanAutomation(loanManager).getPositionsInRange(
                0, 
                positionsToCheck - 1
            );
            
            // Check each position for immediate liquidation need
            for (uint256 i = 0; i < positionsInRange.length; i++) {
                uint256 positionId = positionsInRange[i];
                
                // Check if position involves the asset that changed price
                if (_positionInvolvesAsset(loanManager, positionId, changedAsset)) {
                    
                    // Check if position needs immediate liquidation
                    (bool isAtRisk, uint256 riskLevel) = ILoanAutomation(loanManager).isPositionAtRisk(positionId);
                    
                    if (isAtRisk && riskLevel >= 95) { // Critical risk level
                        try ILoanAutomation(loanManager).automatedLiquidation(positionId) returns (bool success, uint256) {
                            if (success) {
                                liquidatedCount++;
                            }
                        } catch {
                            // Continue with next position if liquidation fails
                            continue;
                        }
                    }
                }
            }
            
        } catch {
            // Skip this loan manager if we can't access it
            return 0;
        }
        
        return liquidatedCount;
    }
    
    /**
     * @dev Checks if a position involves a specific asset (simplified version)
     * @param loanManager Address of the loan manager
     * @param positionId Position ID to check
     * @return involved True if position involves the asset
     */
    function _positionInvolvesAsset(
        address loanManager,
        uint256 positionId,
        address /* asset */
    ) internal view returns (bool involved) {
        
        try ILoanAutomation(loanManager).getPositionHealthData(positionId) returns (
            address,
            uint256,
            uint256,
            uint256
        ) {
            // In a real implementation, you would check if the position's
            // collateral or loan asset matches the changed asset
            // For now, we'll assume all positions might be affected
            return true;
        } catch {
            return false;
        }
    }
    
    /**
     * @dev Registers a loan manager for monitoring
     * @param loanManager Address of the loan manager
     */
    function registerLoanManager(address loanManager) external onlyOwner {
        require(loanManager != address(0), "Invalid loan manager");
        require(!registeredLoanManagers[loanManager], "Already registered");
        
        registeredLoanManagers[loanManager] = true;
        loanManagersList.push(loanManager);
        
        emit LoanManagerRegistered(loanManager);
    }
    
    /**
     * @dev Unregisters a loan manager from monitoring
     * @param loanManager Address of the loan manager
     */
    function unregisterLoanManager(address loanManager) external onlyOwner {
        require(registeredLoanManagers[loanManager], "Not registered");
        
        registeredLoanManagers[loanManager] = false;
        
        // Remove from array
        for (uint256 i = 0; i < loanManagersList.length; i++) {
            if (loanManagersList[i] == loanManager) {
                loanManagersList[i] = loanManagersList[loanManagersList.length - 1];
                loanManagersList.pop();
                break;
            }
        }
        
        emit LoanManagerUnregistered(loanManager);
    }
    
    /**
     * @dev Sets the price change threshold for triggering emergency checks
     * @param thresholdPercent Percentage change threshold (6 decimals: 10% = 100000)
     */
    function setPriceChangeThreshold(uint256 thresholdPercent) external onlyOwner {
        require(thresholdPercent > 0 && thresholdPercent <= 500000, "Invalid threshold"); // Max 50%
        priceChangeThreshold = thresholdPercent;
    }
    
    /**
     * @dev Sets maximum positions to check per trigger
     * @param maxPositions Maximum number of positions
     */
    function setMaxPositionsPerTrigger(uint256 maxPositions) external onlyOwner {
        require(maxPositions > 0 && maxPositions <= 100, "Invalid max positions");
        maxPositionsPerTrigger = maxPositions;
    }
    
    /**
     * @dev Emergency pause mechanism
     * @param paused Whether to pause the system
     */
    function setEmergencyPause(bool paused) external onlyOwner {
        emergencyPause = paused;
    }
    
    /**
     * @dev Manually updates a known price (for initialization)
     * @param asset Asset address
     * @param price Current price
     */
    function updateKnownPrice(address asset, uint256 price) external onlyOwner {
        lastKnownPrices[asset] = price;
        lastPriceUpdate[asset] = block.timestamp;
    }
    
    /**
     * @dev Gets monitoring statistics
     * @return triggersProcessed Total triggers processed
     * @return liquidationsExecuted Total liquidations executed
     * @return managersRegistered Number of registered loan managers
     */
    function getStatistics() external view returns (
        uint256 triggersProcessed,
        uint256 liquidationsExecuted,
        uint256 managersRegistered
    ) {
        return (totalTriggersProcessed, totalLiquidationsExecuted, loanManagersList.length);
    }
    
    /**
     * @dev Gets last known price for an asset
     * @param asset Asset address
     * @return price Last known price
     * @return lastUpdate Timestamp of last update
     */
    function getLastKnownPrice(address asset) external view returns (uint256 price, uint256 lastUpdate) {
        return (lastKnownPrices[asset], lastPriceUpdate[asset]);
    }
    
    /**
     * @dev Gets all registered loan managers
     * @return managers Array of registered loan manager addresses
     */
    function getRegisteredLoanManagers() external view returns (address[] memory managers) {
        return loanManagersList;
    }
} 
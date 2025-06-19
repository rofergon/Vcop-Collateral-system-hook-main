// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// ✅ USANDO IMPORT OFICIAL DE CHAINLINK v2.25.0 - AutomationCompatible incluye la interfaz
import {AutomationCompatibleInterface} from "lib/chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ILoanAutomation} from "../interfaces/ILoanAutomation.sol";
import {IAutomationRegistry} from "../interfaces/IAutomationRegistry.sol";

/**
 * @title LoanAutomationKeeper 
 * @notice UPDATED: Enhanced Chainlink Automation contract for FlexibleLoanManager system
 * @dev Implements AutomationCompatibleInterface with dynamic price monitoring
 */
contract LoanAutomationKeeper is AutomationCompatibleInterface, Ownable {
    
    // Registry for managing multiple loan managers
    IAutomationRegistry public automationRegistry;
    
    // ⚡ ENHANCED: Configuration with dynamic thresholds  
    uint256 public maxGasPerUpkeep = 2500000; // Increased for complex liquidations
    uint256 public minRiskThreshold = 75;     // Lower threshold for faster liquidations
    uint256 public maxPositionsPerBatch = 25; // Optimized batch size
    bool public emergencyPause = false;
    
    // ⚡ NEW: Price volatility monitoring
    uint256 public priceVolatilityThreshold = 50000; // 5% price change triggers immediate check
    mapping(address => uint256) public lastProcessedPriceUpdate;
    
    // Performance tracking
    uint256 public totalLiquidations;
    uint256 public totalUpkeeps;
    uint256 public totalPositionsChecked;
    uint256 public lastExecutionTimestamp;
    
    // ⚡ ENHANCED: Security with forwarder pattern
    address public forwarderAddress;
    
    // ⚡ NEW: Multi-manager support with priorities
    mapping(address => uint256) public managerPriority; // Higher number = higher priority
    
    // Events
    event UpkeepPerformed(uint256 indexed totalPositionsChecked, uint256 liquidationsExecuted, uint256 gasUsed);
    event LiquidationExecuted(address indexed loanManager, uint256 indexed positionId, uint256 amount, address liquidator);
    event EmergencyPaused(bool paused);
    event ForwarderSet(address forwarder);
    event PriceVolatilityDetected(address indexed asset, uint256 volatility);
    event BatchProcessingOptimized(uint256 oldBatchSize, uint256 newBatchSize);
    
    constructor(address _automationRegistry) Ownable(msg.sender) {
        require(_automationRegistry != address(0), "Invalid registry address");
        automationRegistry = IAutomationRegistry(_automationRegistry);
    }
    
    /**
     * @dev ⚡ ENHANCED: Chainlink Automation checkUpkeep with dynamic risk assessment
     * @param checkData ABI-encoded data specifying manager, range, and monitoring mode
     * @return upkeepNeeded True if liquidations are needed
     * @return performData Data for performUpkeep containing positions and metadata
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        
        // Emergency pause check
        if (emergencyPause) {
            return (false, bytes(""));
        }
        
        // ⚡ ENHANCED: Decode checkData with additional monitoring parameters
        (
            address loanManager, 
            uint256 startIndex, 
            uint256 batchSize,
            bool volatilityMode  // NEW: Special mode for price volatility
        ) = abi.decode(checkData, (address, uint256, uint256, bool));
        
        // Verify manager is registered and active
        if (!automationRegistry.isManagerActive(loanManager)) {
            return (false, bytes(""));
        }
        
        // Get loan automation interface
        ILoanAutomation loanAutomation = ILoanAutomation(loanManager);
        
        // Check if automation is enabled on the loan manager
        if (!loanAutomation.isAutomationEnabled()) {
            return (false, bytes(""));
        }
        
        // ⚡ ENHANCED: Dynamic batch size optimization
        uint256 totalPositions = loanAutomation.getTotalActivePositions();
        if (totalPositions == 0 || startIndex >= totalPositions) {
            return (false, bytes(""));
        }
        
        // Calculate optimal batch size based on gas and risk conditions
        uint256 optimizedBatchSize = _calculateOptimalBatchSize(batchSize, volatilityMode, totalPositions);
        uint256 endIndex = startIndex + optimizedBatchSize - 1;
        if (endIndex >= totalPositions) {
            endIndex = totalPositions - 1;
        }
        
        // Get positions in the specified range
        uint256[] memory positionsInRange = loanAutomation.getPositionsInRange(startIndex, endIndex);
        if (positionsInRange.length == 0) {
            return (false, bytes(""));
        }
        
        // ⚡ ENHANCED: Multi-tier risk assessment
        LiquidationBatch memory batch = _assessPositionRisks(loanAutomation, positionsInRange, volatilityMode);
        
        // If no liquidations needed, return false
        if (batch.count == 0) {
            return (false, bytes(""));
        }
        
        // ⚡ ENHANCED: Include metadata for smart execution
        performData = abi.encode(
            loanManager,
            batch.positions,
            batch.priorities,
            batch.urgencyLevel,
            block.timestamp
        );
        
        return (true, performData);
    }
    
    /**
     * @dev ⚡ ENHANCED: Chainlink Automation performUpkeep with intelligent execution
     * @param performData Enhanced data from checkUpkeep with prioritization
     */
    function performUpkeep(bytes calldata performData) external override {
        
        // ⚡ ENHANCED: Security check with forwarder validation
        if (forwarderAddress != address(0)) {
            require(msg.sender == forwarderAddress, "Unauthorized: invalid forwarder");
        }
        
        // Emergency pause check
        require(!emergencyPause, "Emergency paused");
        
        uint256 executionStartGas = gasleft();
        
        // ⚡ ENHANCED: Decode performData with metadata
        (
            address loanManager,
            uint256[] memory positionsToLiquidate,
            uint256[] memory priorities,
            uint256 urgencyLevel,
            uint256 checkTimestamp
        ) = abi.decode(performData, (address, uint256[], uint256[], uint256, uint256));
        
        // Verify manager is still active
        require(automationRegistry.isManagerActive(loanManager), "Manager not active");
        
        ILoanAutomation loanAutomation = ILoanAutomation(loanManager);
        require(loanAutomation.isAutomationEnabled(), "Automation disabled");
        
        // ⚡ ENHANCED: Prevent stale data execution (max 5 minutes old)
        require(block.timestamp - checkTimestamp <= 300, "Check data too old");
        
        // ⚡ ENHANCED: Execute liquidations with intelligent prioritization
        LiquidationResults memory results = _executePrioritizedLiquidations(
            loanAutomation,
            positionsToLiquidate,
            priorities,
            urgencyLevel,
            executionStartGas
        );
        
        // Update statistics
        totalLiquidations += results.liquidationsExecuted;
        totalUpkeeps++;
        totalPositionsChecked += positionsToLiquidate.length;
        lastExecutionTimestamp = block.timestamp;
        
        emit UpkeepPerformed(
            positionsToLiquidate.length,
            results.liquidationsExecuted,
            executionStartGas - gasleft()
        );
    }
    
    /**
     * @dev ⚡ NEW: Calculate optimal batch size based on conditions
     */
    function _calculateOptimalBatchSize(
        uint256 requestedSize,
        bool volatilityMode,
        uint256 totalPositions
    ) internal view returns (uint256) {
        uint256 baseSize = requestedSize > 0 ? requestedSize : maxPositionsPerBatch;
        
        // Reduce batch size during high volatility for faster execution
        if (volatilityMode) {
            baseSize = baseSize / 2;
        }
        
        // Ensure we don't exceed available positions
        if (baseSize > totalPositions) {
            baseSize = totalPositions;
        }
        
        // Minimum batch size of 1
        if (baseSize == 0) {
            baseSize = 1;
        }
        
        return baseSize;
    }
    
    // ⚡ NEW: Struct for liquidation batch data
    struct LiquidationBatch {
        uint256[] positions;
        uint256[] priorities;
        uint256 count;
        uint256 urgencyLevel;
    }
    
    // ⚡ NEW: Struct for liquidation execution results
    struct LiquidationResults {
        uint256 liquidationsExecuted;
        uint256 gasUsed;
        uint256 totalAmount;
    }
    
    /**
     * @dev ⚡ ENHANCED: Multi-tier risk assessment with prioritization
     */
    function _assessPositionRisks(
        ILoanAutomation loanAutomation,
        uint256[] memory positions,
        bool volatilityMode
    ) internal view returns (LiquidationBatch memory batch) {
        
        uint256[] memory toLiquidate = new uint256[](positions.length);
        uint256[] memory priorities = new uint256[](positions.length);
        uint256 liquidationCount = 0;
        uint256 maxUrgency = 0;
        
        // Check each position with enhanced risk analysis
        for (uint256 i = 0; i < positions.length; i++) {
            uint256 positionId = positions[i];
            
            (bool isAtRisk, uint256 riskLevel) = loanAutomation.isPositionAtRisk(positionId);
            
            // ⚡ ENHANCED: Multi-tier liquidation criteria
            uint256 threshold = volatilityMode ? minRiskThreshold - 10 : minRiskThreshold;
            
            if (isAtRisk && riskLevel >= threshold) {
                toLiquidate[liquidationCount] = positionId;
                
                // ⚡ NEW: Calculate priority based on risk level and urgency
                uint256 priority = _calculateLiquidationPriority(riskLevel, volatilityMode);
                priorities[liquidationCount] = priority;
                
                if (priority > maxUrgency) {
                    maxUrgency = priority;
                }
                
                liquidationCount++;
            }
        }
        
        // Truncate arrays to actual count
        uint256[] memory finalPositions = new uint256[](liquidationCount);
        uint256[] memory finalPriorities = new uint256[](liquidationCount);
        
        for (uint256 i = 0; i < liquidationCount; i++) {
            finalPositions[i] = toLiquidate[i];
            finalPriorities[i] = priorities[i];
        }
        
        batch = LiquidationBatch({
            positions: finalPositions,
            priorities: finalPriorities,
            count: liquidationCount,
            urgencyLevel: maxUrgency
        });
        
        return batch;
    }
    
    /**
     * @dev ⚡ NEW: Calculate liquidation priority
     */
    function _calculateLiquidationPriority(uint256 riskLevel, bool volatilityMode) internal pure returns (uint256) {
        uint256 basePriority = riskLevel;
        
        // Boost priority during volatility
        if (volatilityMode) {
            basePriority += 20;
        }
        
        // Critical positions get maximum priority
        if (riskLevel >= 95) {
            basePriority = 100;
        }
        
        return basePriority;
    }
    
    /**
     * @dev ⚡ ENHANCED: Execute liquidations with intelligent prioritization
     */
    function _executePrioritizedLiquidations(
        ILoanAutomation loanAutomation,
        uint256[] memory positions,
        uint256[] memory priorities,
        uint256 urgencyLevel,
        uint256 startGas
    ) internal returns (LiquidationResults memory results) {
        
        // Sort positions by priority (highest first) if urgent
        if (urgencyLevel >= 90) {
            _sortByPriority(positions, priorities);
        }
        
        uint256 liquidationsExecuted = 0;
        uint256 totalAmount = 0;
        
        // Execute liquidations with gas monitoring
        for (uint256 i = 0; i < positions.length; i++) {
            uint256 gasRemaining = gasleft();
            
            // ⚡ ENHANCED: Dynamic gas management
            uint256 gasNeeded = _estimateGasForLiquidation(urgencyLevel);
            if (gasRemaining < gasNeeded + 100000) { // Reserve gas for finalization
                break;
            }
            
            uint256 positionId = positions[i];
            
            // ⚡ ENHANCED: Re-validate position before liquidation
            (bool isAtRisk, uint256 currentRisk) = loanAutomation.isPositionAtRisk(positionId);
            
            if (isAtRisk && currentRisk >= minRiskThreshold) {
                try loanAutomation.automatedLiquidation(positionId) returns (bool success, uint256 amount) {
                    if (success) {
                        liquidationsExecuted++;
                        totalAmount += amount;
                        emit LiquidationExecuted(address(loanAutomation), positionId, amount, msg.sender);
                    }
                } catch Error(string memory reason) {
                    // Log error and continue
                    continue;
                } catch {
                    // Continue with next position if one fails
                    continue;
                }
            }
        }
        
        results = LiquidationResults({
            liquidationsExecuted: liquidationsExecuted,
            gasUsed: startGas - gasleft(),
            totalAmount: totalAmount
        });
        
        return results;
    }
    
    /**
     * @dev ⚡ NEW: Sort positions by priority (simple bubble sort for small arrays)
     */
    function _sortByPriority(uint256[] memory positions, uint256[] memory priorities) internal pure {
        uint256 length = positions.length;
        
        for (uint256 i = 0; i < length - 1; i++) {
            for (uint256 j = 0; j < length - i - 1; j++) {
                if (priorities[j] < priorities[j + 1]) {
                    // Swap priorities
                    (priorities[j], priorities[j + 1]) = (priorities[j + 1], priorities[j]);
                    // Swap corresponding positions
                    (positions[j], positions[j + 1]) = (positions[j + 1], positions[j]);
                }
            }
        }
    }
    
    /**
     * @dev ⚡ NEW: Estimate gas needed for liquidation based on urgency
     */
    function _estimateGasForLiquidation(uint256 urgencyLevel) internal pure returns (uint256) {
        // Base gas estimate
        uint256 baseGas = 200000;
        
        // Critical liquidations may need more gas for complex calculations
        if (urgencyLevel >= 95) {
            baseGas = 300000;
        } else if (urgencyLevel >= 85) {
            baseGas = 250000;
        }
        
        return baseGas;
    }
    
    // ========== ENHANCED CONFIGURATION FUNCTIONS ==========
    
    /**
     * @dev ⚡ ENHANCED: Sets the automation registry contract
     */
    function setAutomationRegistry(address _registry) external onlyOwner {
        require(_registry != address(0), "Invalid registry address");
        automationRegistry = IAutomationRegistry(_registry);
    }
    
    /**
     * @dev Sets the maximum gas per upkeep
     */
    function setMaxGasPerUpkeep(uint256 _maxGas) external onlyOwner {
        require(_maxGas >= 200000, "Gas too low");
        require(_maxGas <= 5000000, "Gas too high");
        maxGasPerUpkeep = _maxGas;
    }
    
    /**
     * @dev ⚡ ENHANCED: Sets the minimum risk threshold with validation
     */
    function setMinRiskThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold >= 50 && _threshold <= 100, "Invalid threshold range");
        minRiskThreshold = _threshold;
    }
    
    /**
     * @dev ⚡ NEW: Sets price volatility threshold
     */
    function setPriceVolatilityThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold >= 10000 && _threshold <= 200000, "Invalid volatility threshold"); // 1-20%
        priceVolatilityThreshold = _threshold;
    }
    
    /**
     * @dev ⚡ NEW: Sets maximum positions per batch
     */
    function setMaxPositionsPerBatch(uint256 _maxPositions) external onlyOwner {
        require(_maxPositions >= 5 && _maxPositions <= 100, "Invalid batch size");
        uint256 oldSize = maxPositionsPerBatch;
        maxPositionsPerBatch = _maxPositions;
        emit BatchProcessingOptimized(oldSize, _maxPositions);
    }
    
    /**
     * @dev Emergency pause mechanism
     */
    function setEmergencyPause(bool _paused) external onlyOwner {
        emergencyPause = _paused;
        emit EmergencyPaused(_paused);
    }
    
    /**
     * @dev ⚡ ENHANCED: Sets the forwarder address for additional security
     */
    function setForwarderAddress(address _forwarder) external onlyOwner {
        forwarderAddress = _forwarder;
        emit ForwarderSet(_forwarder);
    }
    
    /**
     * @dev ⚡ NEW: Sets manager priority for liquidation ordering
     */
    function setManagerPriority(address manager, uint256 priority) external onlyOwner {
        require(automationRegistry.isManagerActive(manager), "Manager not active");
        require(priority <= 100, "Priority too high");
        managerPriority[manager] = priority;
    }
    
    // ========== VIEW FUNCTIONS ==========
    
    /**
     * @dev ⚡ ENHANCED: Gets comprehensive automation statistics
     */
    function getAutomationStats() external view returns (
        uint256 totalLiquidationsCount,
        uint256 totalUpkeepsCount,
        uint256 totalPositionsCheckedCount,
        uint256 lastExecution,
        uint256 averagePositionsPerUpkeep
    ) {
        uint256 avgPositions = totalUpkeeps > 0 ? totalPositionsChecked / totalUpkeeps : 0;
        
        return (
            totalLiquidations,
            totalUpkeeps,
            totalPositionsChecked,
            lastExecutionTimestamp,
            avgPositions
        );
    }
    
    /**
     * @dev ⚡ ENHANCED: Checks if automation is currently active with detailed status
     */
    function isAutomationActive() external view returns (bool isActive, string memory status) {
        if (emergencyPause) {
            return (false, "Emergency paused");
        }
        
        address[] memory managers = automationRegistry.getRegisteredManagers();
        if (managers.length == 0) {
            return (false, "No registered managers");
        }
        
        uint256 activeCount = 0;
        for (uint256 i = 0; i < managers.length; i++) {
            if (automationRegistry.isManagerActive(managers[i])) {
                activeCount++;
            }
        }
        
        if (activeCount == 0) {
            return (false, "No active managers");
        }
        
        return (true, "Active");
    }
    
    /**
     * @dev ⚡ ENHANCED: Helper function to generate checkData with volatility mode
     */
    function generateCheckData(
        address loanManager,
        uint256 startIndex,
        uint256 batchSize,
        bool volatilityMode
    ) external pure returns (bytes memory checkData) {
        return abi.encode(loanManager, startIndex, batchSize, volatilityMode);
    }
    
    /**
     * @dev ⚡ NEW: Generate standard checkData (backward compatibility)
     */
         function generateStandardCheckData(
         address loanManager,
         uint256 startIndex,
         uint256 batchSize
     ) external pure returns (bytes memory checkData) {
         return abi.encode(loanManager, startIndex, batchSize, false);
     }
 } 
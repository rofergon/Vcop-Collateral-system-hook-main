// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// CORRECT: Import complete AutomationCompatible (not just the interface)
import {AutomationCompatible} from "lib/chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ILoanAutomation} from "../interfaces/ILoanAutomation.sol";
import {IAutomationRegistry} from "../interfaces/IAutomationRegistry.sol";

/**
 * @title LoanAutomationKeeperOptimized 
 * @notice OPTIMIZED: Chainlink Custom Logic Automation for loan liquidation
 * @dev Correct implementation according to official Chainlink documentation
 * 
 * KEY OPTIMIZATIONS:
 * - Extends AutomationCompatible (not just interface) for UI detection
 * - Simplified but effective logic 
 * - Focus on critical liquidations
 * - Flexible configuration
 * - Performance metrics
 */
contract LoanAutomationKeeperOptimized is AutomationCompatible, Ownable {
    
    // Registry for multiple loan managers
    IAutomationRegistry public automationRegistry;
    
    // OPTIMIZED CONFIGURATION
    uint256 public minRiskThreshold = 85;        // Risk threshold for liquidation
    uint256 public maxPositionsPerBatch = 20;    // Optimized batch for gas
    uint256 public maxGasPerUpkeep = 2000000;    // Maximum gas per upkeep
    bool public emergencyPause = false;
    
    // PRIORITIZATION: Managers with different priorities
    mapping(address => uint256) public managerPriority; // Higher number = higher priority
    mapping(address => bool) public registeredManagers;
    address[] public managersList;
    
    // PERFORMANCE METRICS
    uint256 public totalLiquidations;
    uint256 public totalUpkeeps;
    uint256 public lastExecutionTimestamp;
    uint256 public totalGasUsed;
    
    // OPTIMIZATION: Cooldown to avoid spam
    mapping(uint256 => uint256) public lastLiquidationAttempt;
    uint256 public liquidationCooldown = 300; // 5 minutes
    
    // SECURITY: Chainlink Forwarder
    address public chainlinkForwarder;
    bool public forwarderRestricted = false;
    
    // Simplified but informative events
    event UpkeepPerformed(
        address indexed loanManager,
        uint256 positionsChecked, 
        uint256 liquidationsExecuted, 
        uint256 gasUsed
    );
    event LiquidationExecuted(
        address indexed loanManager, 
        uint256 indexed positionId, 
        uint256 amount
    );
    event ManagerRegistered(address indexed manager, uint256 priority);
    event EmergencyPaused(bool paused);
    event ForwarderSet(address indexed forwarder);
    event ForwarderRestrictionToggled(bool restricted);
    
    constructor(address _automationRegistry) Ownable(msg.sender) {
        require(_automationRegistry != address(0), "Invalid registry address");
        automationRegistry = IAutomationRegistry(_automationRegistry);
    }
    
    /**
     * @dev CHAINLINK AUTOMATION: checkUpkeep function
     * @param checkData ABI-encoded: (loanManager, startIndex, batchSize)
     * @return upkeepNeeded True if liquidations need to be executed
     * @return performData Data for performUpkeep
     * 
     * 🔧 IMPORTANT FIX: This function fixes an index mapping issue where:
     * - Position IDs in FlexibleLoanManager start at 1, not 0
     * - startIndex=0 in checkData is automatically converted to startPositionId=1
     * - This prevents getPositionsInRange(0,0) from returning an empty array when position ID 1 exists
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        
        // Emergency pause check
        if (emergencyPause) {
            return (false, bytes(""));
        }
        
        // Decode checkData
        if (checkData.length == 0) {
            return (false, bytes(""));
        }
        
        try this.decodeCheckData(checkData) returns (
            address loanManager,
            uint256 startIndex,
            uint256 batchSize
        ) {
            // Validate manager is active (if registry supports it)
            try automationRegistry.isManagerActive(loanManager) returns (bool isActive) {
                if (!isActive) {
                    return (false, bytes(""));
                }
            } catch {
                // Registry doesn't support isManagerActive (official Chainlink registry), continue
            }
            
            if (!registeredManagers[loanManager]) {
                return (false, bytes(""));
            }
            
            ILoanAutomation loanAutomation = ILoanAutomation(loanManager);
            
            // Verify automation is enabled
            if (!loanAutomation.isAutomationEnabled()) {
                return (false, bytes(""));
            }
            
            // Get positions
            uint256 totalPositions = loanAutomation.getTotalActivePositions();
            if (totalPositions == 0) {
                return (false, bytes(""));
            }
            
            // ✅ FIXED: Correct index logic for position IDs that start at 1
            // startIndex in checkData should be interpreted as startPositionId
            uint256 startPositionId = startIndex == 0 ? 1 : startIndex; // IDs start at 1
            
            // OPTIMIZATION: Calculate dynamic batch size
            uint256 optimalBatchSize = _calculateOptimalBatchSize(batchSize, totalPositions);
            uint256 endPositionId = startPositionId + optimalBatchSize - 1;
            
            // ✅ FIXED: Don't limit by totalPositions, but by reasonable maximum range
            // The loan manager handles filtering inactive positions
            if (endPositionId > startPositionId + 100) { // Maximum 100 positions per batch
                endPositionId = startPositionId + 100;
            }
            
            // Get positions in range (now with correct IDs)
            uint256[] memory positions = loanAutomation.getPositionsInRange(startPositionId, endPositionId);
            
            // If no positions in this range, try with broader range
            if (positions.length == 0 && startPositionId == 1) {
                // Fallback: search in broader range from ID 1
                positions = loanAutomation.getPositionsInRange(1, 50);
            }
            
            // SEARCH FOR LIQUIDATABLE POSITIONS
            uint256[] memory liquidatablePositions = new uint256[](positions.length);
            uint256[] memory riskLevels = new uint256[](positions.length);
            uint256 liquidatableCount = 0;
            
            for (uint256 i = 0; i < positions.length; i++) {
                uint256 positionId = positions[i];
                
                // Check cooldown
                if (block.timestamp < lastLiquidationAttempt[positionId] + liquidationCooldown) {
                    continue;
                }
                
                (bool isAtRisk, uint256 riskLevel) = loanAutomation.isPositionAtRisk(positionId);
                
                if (isAtRisk && riskLevel >= minRiskThreshold) {
                    liquidatablePositions[liquidatableCount] = positionId;
                    riskLevels[liquidatableCount] = riskLevel;
                    liquidatableCount++;
                }
            }
            
            if (liquidatableCount == 0) {
                return (false, bytes(""));
            }
            
            // Prepare performData
            uint256[] memory finalPositions = new uint256[](liquidatableCount);
            uint256[] memory finalRiskLevels = new uint256[](liquidatableCount);
            
            for (uint256 i = 0; i < liquidatableCount; i++) {
                finalPositions[i] = liquidatablePositions[i];
                finalRiskLevels[i] = riskLevels[i];
            }
            
            performData = abi.encode(
                loanManager,
                finalPositions,
                finalRiskLevels,
                block.timestamp
            );
            
            return (true, performData);
            
        } catch {
            return (false, bytes(""));
        }
    }
    
    /**
     * @dev CHAINLINK AUTOMATION: performUpkeep function
     * @param performData Data from checkUpkeep
     */
    function performUpkeep(bytes calldata performData) external override {
        
        require(!emergencyPause, "Emergency paused");
        
        // SECURITY: Only allow calls from Chainlink Forwarder
        if (forwarderRestricted) {
            require(msg.sender == chainlinkForwarder, "Only Chainlink Forwarder allowed");
        }
        
        uint256 gasStart = gasleft();
        
        // Decode performData
        (
            address loanManager,
            uint256[] memory positions,
            uint256[] memory riskLevels,
            uint256 timestamp
        ) = abi.decode(performData, (address, uint256[], uint256[], uint256));
        
        // Security validations (if registry supports it)
        try automationRegistry.isManagerActive(loanManager) returns (bool isActive) {
            require(isActive, "Manager not active");
        } catch {
            // Registry doesn't support isManagerActive (official Chainlink registry), continue
        }
        require(registeredManagers[loanManager], "Manager not registered");
        require(block.timestamp - timestamp <= 300, "Data too old"); // Max 5 min
        
        ILoanAutomation loanAutomation = ILoanAutomation(loanManager);
        require(loanAutomation.isAutomationEnabled(), "Automation disabled");
        
        // OPTIMIZATION: Sort by risk level (highest first)
        _sortByRiskLevel(positions, riskLevels);
        
        // EXECUTE LIQUIDATIONS
        uint256 liquidationsExecuted = 0;
        uint256 positionsChecked = positions.length;
        
        for (uint256 i = 0; i < positions.length; i++) {
            uint256 positionId = positions[i];
            
            // Gas check to avoid out-of-gas
            if (gasleft() < 200000) { // Reserve gas for finalization
                break;
            }
            
            // Re-verify that position is still liquidatable
            (bool isAtRisk, uint256 currentRisk) = loanAutomation.isPositionAtRisk(positionId);
            
            if (isAtRisk && currentRisk >= minRiskThreshold) {
                // 🤖 VAULT-FUNDED LIQUIDATION: Uses vault liquidity instead of requiring keeper to have tokens
                try loanAutomation.vaultFundedAutomatedLiquidation(positionId) returns (bool success, uint256 amount) {
                    if (success) {
                        liquidationsExecuted++;
                        lastLiquidationAttempt[positionId] = block.timestamp;
                        emit LiquidationExecuted(loanManager, positionId, amount);
                    }
                } catch {
                    // Continue with next position if one fails
                    continue;
                }
            }
        }
        
        // Update statistics
        totalLiquidations += liquidationsExecuted;
        totalUpkeeps++;
        lastExecutionTimestamp = block.timestamp;
        uint256 gasUsed = gasStart - gasleft();
        totalGasUsed += gasUsed;
        
        emit UpkeepPerformed(loanManager, positionsChecked, liquidationsExecuted, gasUsed);
    }
    
    // ========== INTERNAL OPTIMIZATIONS ==========
    
    /**
     * @dev Detects if we're using a custom registry vs official Chainlink
     */
    function _isCustomRegistry() internal view returns (bool) {
        // Official Chainlink addresses on Base Sepolia
        // If it's the official registry, we DON'T do isManagerActive validation
        return address(automationRegistry) != 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3;
    }
    
    /**
     * @dev Calculates optimal batch size based on conditions
     * 🔧 FIXED: Don't limit by totalPositions since this is the count of active positions,
     * not the maximum range of IDs we can search
     */
    function _calculateOptimalBatchSize(
        uint256 requestedSize, 
        uint256 totalPositions
    ) internal view returns (uint256) {
        
        uint256 optimalSize = requestedSize > 0 ? requestedSize : maxPositionsPerBatch;
        
        // ✅ REMOVED: Don't limit by totalPositions since IDs can be sparse
        // Position IDs can be much higher than the number of active positions
        // The getPositionsInRange function handles filtering active positions
        
        // Minimum of 1, reasonable maximum to avoid excessive gas
        if (optimalSize == 0) {
            optimalSize = 1;
        }
        if (optimalSize > 100) { // Reasonable maximum limit
            optimalSize = 100;
        }
        
        return optimalSize;
    }
    
    /**
     * @dev Sorts positions by risk level (highest first)
     */
    function _sortByRiskLevel(uint256[] memory positions, uint256[] memory riskLevels) internal pure {
        uint256 length = positions.length;
        
        // Simple bubble sort for small arrays
        for (uint256 i = 0; i < length - 1; i++) {
            for (uint256 j = 0; j < length - i - 1; j++) {
                if (riskLevels[j] < riskLevels[j + 1]) {
                    // Swap risk levels
                    (riskLevels[j], riskLevels[j + 1]) = (riskLevels[j + 1], riskLevels[j]);
                    // Swap corresponding positions
                    (positions[j], positions[j + 1]) = (positions[j + 1], positions[j]);
                }
            }
        }
    }
    
    // ========== CONFIGURATION ==========
    
    /**
     * @dev Registers a loan manager for automation
     */
    function registerLoanManager(address loanManager, uint256 priority) external onlyOwner {
        require(loanManager != address(0), "Invalid manager");
        require(!registeredManagers[loanManager], "Already registered");
        require(priority <= 100, "Priority too high");
        
        registeredManagers[loanManager] = true;
        managerPriority[loanManager] = priority;
        managersList.push(loanManager);
        
        emit ManagerRegistered(loanManager, priority);
    }
    
    /**
     * @dev Unregisters a loan manager
     */
    function unregisterLoanManager(address loanManager) external onlyOwner {
        require(registeredManagers[loanManager], "Not registered");
        
        registeredManagers[loanManager] = false;
        delete managerPriority[loanManager];
        
        // Remove from array
        for (uint256 i = 0; i < managersList.length; i++) {
            if (managersList[i] == loanManager) {
                managersList[i] = managersList[managersList.length - 1];
                managersList.pop();
                break;
            }
        }
    }
    
    /**
     * @dev Parameter configuration
     */
    function setMinRiskThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold >= 50 && _threshold <= 100, "Invalid threshold");
        minRiskThreshold = _threshold;
    }
    
    function setMaxPositionsPerBatch(uint256 _maxPositions) external onlyOwner {
        require(_maxPositions >= 5 && _maxPositions <= 50, "Invalid batch size");
        maxPositionsPerBatch = _maxPositions;
    }
    
    function setLiquidationCooldown(uint256 _cooldown) external onlyOwner {
        require(_cooldown >= 60 && _cooldown <= 1800, "Invalid cooldown"); // 1min - 30min
        liquidationCooldown = _cooldown;
    }
    
    function setEmergencyPause(bool _paused) external onlyOwner {
        emergencyPause = _paused;
        emit EmergencyPaused(_paused);
    }
    
    /**
     * @dev Sets the Chainlink Forwarder address (obtained after registration)
     */
    function setChainlinkForwarder(address _forwarder) external onlyOwner {
        require(_forwarder != address(0), "Invalid forwarder address");
        chainlinkForwarder = _forwarder;
        emit ForwarderSet(_forwarder);
    }
    
    /**
     * @dev Enables/disables Forwarder restriction for security
     */
    function setForwarderRestriction(bool _restricted) external onlyOwner {
        forwarderRestricted = _restricted;
        emit ForwarderRestrictionToggled(_restricted);
    }
    
    // ========== UTILITIES ==========
    
    /**
     * @dev Helper to decode checkData
     */
    function decodeCheckData(bytes calldata checkData) external pure returns (
        address loanManager,
        uint256 startIndex,
        uint256 batchSize
    ) {
        return abi.decode(checkData, (address, uint256, uint256));
    }
    
    /**
     * @dev Generates checkData for registration
     */
    function generateCheckData(
        address loanManager,
        uint256 startIndex,
        uint256 batchSize
    ) external pure returns (bytes memory) {
        return abi.encode(loanManager, startIndex, batchSize);
    }
    
    /**
     * @dev ✅ NEW: Generates optimized checkData for automation
     * @param loanManager Address of the loan manager
     * @param startPositionId Initial position ID (use 0 for auto-start from 1)
     * @param batchSize Batch size (use 0 for automatic batch)
     */
    function generateOptimizedCheckData(
        address loanManager,
        uint256 startPositionId,
        uint256 batchSize
    ) external pure returns (bytes memory) {
        // If no startPositionId specified, use 0 (will be converted to 1 in checkUpkeep)
        uint256 effectiveStartId = startPositionId == 0 ? 0 : startPositionId;
        
        // If no batchSize specified, use default value
        uint256 effectiveBatchSize = batchSize == 0 ? 25 : batchSize;
        
        return abi.encode(loanManager, effectiveStartId, effectiveBatchSize);
    }
    
    /**
     * @dev Gets complete statistics
     */
    function getStats() external view returns (
        uint256 totalLiquidationsCount,
        uint256 totalUpkeepsCount,
        uint256 lastExecution,
        uint256 averageGasUsed,
        uint256 registeredManagersCount
    ) {
        uint256 avgGas = totalUpkeeps > 0 ? totalGasUsed / totalUpkeeps : 0;
        
        return (
            totalLiquidations,
            totalUpkeeps,
            lastExecutionTimestamp,
            avgGas,
            managersList.length
        );
    }
    
    /**
     * @dev 📋 Gets registered managers
     */
    function getRegisteredManagers() external view returns (
        address[] memory managers,
        uint256[] memory priorities
    ) {
        managers = new address[](managersList.length);
        priorities = new uint256[](managersList.length);
        
        for (uint256 i = 0; i < managersList.length; i++) {
            managers[i] = managersList[i];
            priorities[i] = managerPriority[managersList[i]];
        }
        
        return (managers, priorities);
    }
} 
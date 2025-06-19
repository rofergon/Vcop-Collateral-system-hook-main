// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ILoanAutomation} from "../interfaces/ILoanAutomation.sol";
import {IPriceRegistry} from "../../interfaces/IPriceRegistry.sol";

// ✅ USANDO IMPORT OFICIAL DE CHAINLINK v2.25.0
import {ILogAutomation, Log} from "lib/chainlink/contracts/src/v0.8/automation/interfaces/ILogAutomation.sol";

/**
 * @title PriceChangeLogTrigger
 * @notice UPDATED: Enhanced log trigger automation with DynamicPriceRegistry integration
 * @dev Listens for price update events and triggers immediate position checks using dynamic pricing
 */
contract PriceChangeLogTrigger is ILogAutomation, Ownable {
    
    // ⚡ ENHANCED: Dynamic price registry integration
    IPriceRegistry public immutable priceRegistry;
    
    // ⚡ ENHANCED: Configuration with dynamic thresholds
    uint256 public priceChangeThreshold = 50000; // 5% change (6 decimals: 5% = 50000)
    uint256 public maxPositionsPerTrigger = 30;  // Increased for better coverage
    uint256 public volatilityBoostThreshold = 100000; // 10% change triggers volatility mode
    bool public emergencyPause = false;
    
    // ⚡ NEW: Multi-tier response thresholds
    uint256 public criticalThreshold = 150000;   // 15% change = critical
    uint256 public immediateThreshold = 100000;  // 10% change = immediate
    uint256 public urgentThreshold = 75000;      // 7.5% change = urgent
    
    // Registered loan managers for monitoring
    mapping(address => bool) public registeredLoanManagers;
    mapping(address => uint256) public managerPriority; // Higher = more priority
    address[] public loanManagersList;
    
    // ⚡ ENHANCED: Price monitoring with detailed tracking
    mapping(address => uint256) public lastKnownPrices;
    mapping(address => uint256) public lastPriceUpdate;
    mapping(address => uint256) public priceChangeCount; // Track frequency of changes
    mapping(address => uint256) public maxPriceDeviation; // Track maximum deviation
    
    // ⚡ NEW: Volatility detection
    mapping(address => bool) public assetInVolatilityMode;
    mapping(address => uint256) public volatilityModeEntered;
    uint256 public volatilityModeDuration = 3600; // 1 hour
    
    // Statistics
    uint256 public totalTriggersProcessed;
    uint256 public totalLiquidationsExecuted;
    uint256 public totalVolatilityEvents;
    uint256 public lastTriggerTimestamp;
    
    // ⚡ NEW: Enhanced events
    event PriceChangeDetected(
        address indexed asset, 
        uint256 oldPrice, 
        uint256 newPrice, 
        uint256 changePercent,
        string urgencyLevel
    );
    event EmergencyLiquidationTriggered(
        address indexed loanManager, 
        uint256 positionsChecked, 
        uint256 liquidated,
        string triggerReason
    );
    event VolatilityModeActivated(address indexed asset, uint256 changePercent);
    event VolatilityModeDeactivated(address indexed asset);
    event LoanManagerRegistered(address indexed loanManager, uint256 priority);
    event LoanManagerUnregistered(address indexed loanManager);
    event ThresholdUpdated(string thresholdType, uint256 oldValue, uint256 newValue);
    
    constructor(address _priceRegistry) Ownable(msg.sender) {
        require(_priceRegistry != address(0), "Invalid price registry");
        priceRegistry = IPriceRegistry(_priceRegistry);
    }
    
    /**
     * @dev ⚡ ENHANCED: Chainlink Log Automation checkLog with dynamic price analysis
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
        
        // ⚡ ENHANCED: More flexible log validation
        // Check if this is a price update event we care about
        if (log.topics.length < 2) {
            return (false, bytes(""));
        }
        
        // Extract asset address from log topics
        address asset = address(uint160(uint256(log.topics[1])));
        
        // ⚡ ENHANCED: Support multiple price update formats
        uint256 newPrice;
        bool validPriceUpdate = false;
        
        // Try different price update formats
        try this.decodePriceUpdate(log.data) returns (uint256 price) {
            newPrice = price;
            validPriceUpdate = true;
        } catch {
            // Try alternative format for DynamicPriceRegistry events
            try this.decodeDynamicPriceUpdate(log.data) returns (uint256 price, uint8) {
                newPrice = price;
                validPriceUpdate = true;
            } catch {
                // Not a price update we can process
                return (false, bytes(""));
            }
        }
        
        if (!validPriceUpdate || newPrice == 0) {
            return (false, bytes(""));
        }
        
        // ⚡ ENHANCED: Comprehensive price change analysis
        PriceAnalysis memory analysis = _analyzePriceChange(asset, newPrice);
        
        if (!analysis.significantChange) {
            return (false, bytes(""));
        }
        
        // ⚡ NEW: Handle volatility mode activation
        if (analysis.changePercent >= volatilityBoostThreshold && !assetInVolatilityMode[asset]) {
            assetInVolatilityMode[asset] = true;
            volatilityModeEntered[asset] = block.timestamp;
            totalVolatilityEvents++;
            emit VolatilityModeActivated(asset, analysis.changePercent);
        }
        
        upkeepNeeded = true;
        
        // ⚡ ENHANCED: Rich metadata for smart execution
        performData = abi.encode(
            asset,
            analysis.oldPrice,
            newPrice,
            analysis.changePercent,
            analysis.urgencyLevel,
            assetInVolatilityMode[asset],
            block.timestamp
        );
        
        emit PriceChangeDetected(
            asset, 
            analysis.oldPrice, 
            newPrice, 
            analysis.changePercent,
            _getUrgencyLevelString(analysis.urgencyLevel)
        );
        
        return (upkeepNeeded, performData);
    }
    
    /**
     * @dev ⚡ ENHANCED: Chainlink Log Automation performUpkeep with intelligent response
     * @param performData Enhanced data from checkLog with urgency levels
     */
    function performUpkeep(bytes calldata performData) external override {
        require(!emergencyPause, "Emergency paused");
        
        // ⚡ ENHANCED: Decode rich performData
        (
            address asset,
            uint256 oldPrice,
            uint256 newPrice,
            uint256 changePercent,
            uint256 urgencyLevel,
            bool volatilityMode,
            uint256 timestamp
        ) = abi.decode(performData, (address, uint256, uint256, uint256, uint256, bool, uint256));
        
        // Update stored price and tracking
        lastKnownPrices[asset] = newPrice;
        lastPriceUpdate[asset] = timestamp;
        priceChangeCount[asset]++;
        
        // Track maximum deviation
        if (changePercent > maxPriceDeviation[asset]) {
            maxPriceDeviation[asset] = changePercent;
        }
        
        // ⚡ ENHANCED: Intelligent liquidation strategy based on urgency
        LiquidationStrategy memory strategy = _determineLiquidationStrategy(
            urgencyLevel,
            volatilityMode,
            changePercent
        );
        
        // Execute liquidations across registered managers
        uint256 totalLiquidated = 0;
        string memory triggerReason = _getUrgencyLevelString(urgencyLevel);
        
        for (uint256 i = 0; i < loanManagersList.length; i++) {
            address loanManager = loanManagersList[i];
            
            if (registeredLoanManagers[loanManager]) {
                uint256 liquidated = _performEmergencyCheck(
                    loanManager,
                    asset,
                    strategy
                );
                totalLiquidated += liquidated;
            }
        }
        
        // ⚡ NEW: Check if volatility mode should be deactivated
        _checkVolatilityModeExpiry(asset);
        
        // Update statistics
        totalTriggersProcessed++;
        totalLiquidationsExecuted += totalLiquidated;
        lastTriggerTimestamp = block.timestamp;
        
        emit EmergencyLiquidationTriggered(
            address(0), 
            strategy.positionsToCheck, 
            totalLiquidated,
            triggerReason
        );
    }
    
    // ⚡ NEW: Structs for enhanced data management
    struct PriceAnalysis {
        uint256 oldPrice;
        uint256 changePercent;
        uint256 urgencyLevel;
        bool significantChange;
    }
    
    struct LiquidationStrategy {
        uint256 positionsToCheck;
        uint256 riskThresholdOverride;
        bool prioritizeByRisk;
        bool useEnhancedGas;
    }
    
    /**
     * @dev ⚡ NEW: Analyze price change and determine significance
     */
    function _analyzePriceChange(address asset, uint256 newPrice) 
        internal view returns (PriceAnalysis memory analysis) {
        
        uint256 lastPrice = lastKnownPrices[asset];
        
        if (lastPrice == 0) {
            // First time seeing this asset, just store the price
            return PriceAnalysis({
                oldPrice: 0,
                changePercent: 0,
                urgencyLevel: 0,
                significantChange: false
            });
        }
        
        // Calculate percentage change
        uint256 changePercent;
        if (newPrice > lastPrice) {
            changePercent = ((newPrice - lastPrice) * 1000000) / lastPrice;
        } else {
            changePercent = ((lastPrice - newPrice) * 1000000) / lastPrice;
        }
        
        // Determine urgency level
        uint256 urgencyLevel = 0;
        if (changePercent >= criticalThreshold) {
            urgencyLevel = 4; // Critical
        } else if (changePercent >= immediateThreshold) {
            urgencyLevel = 3; // Immediate
        } else if (changePercent >= urgentThreshold) {
            urgencyLevel = 2; // Urgent
        } else if (changePercent >= priceChangeThreshold) {
            urgencyLevel = 1; // Normal
        }
        
        analysis = PriceAnalysis({
            oldPrice: lastPrice,
            changePercent: changePercent,
            urgencyLevel: urgencyLevel,
            significantChange: changePercent >= priceChangeThreshold
        });
        
        return analysis;
    }
    
    /**
     * @dev ⚡ NEW: Determine liquidation strategy based on urgency
     */
    function _determineLiquidationStrategy(
        uint256 urgencyLevel,
        bool volatilityMode,
        uint256 changePercent
    ) internal view returns (LiquidationStrategy memory strategy) {
        
        uint256 basePositions = maxPositionsPerTrigger;
        uint256 riskOverride = 0;
        bool prioritize = false;
        bool enhancedGas = false;
        
        if (urgencyLevel >= 4) { // Critical
            basePositions = basePositions * 2; // Check more positions
            riskOverride = 70; // Lower risk threshold
            prioritize = true;
            enhancedGas = true;
        } else if (urgencyLevel >= 3) { // Immediate
            basePositions = (basePositions * 3) / 2;
            riskOverride = 75;
            prioritize = true;
            enhancedGas = true;
        } else if (urgencyLevel >= 2) { // Urgent
            basePositions = (basePositions * 4) / 3;
            riskOverride = 80;
            prioritize = true;
        }
        
        // Volatility mode adjustments
        if (volatilityMode) {
            basePositions = (basePositions * 3) / 2;
            if (riskOverride > 0) {
                riskOverride -= 5; // Even lower threshold
            }
        }
        
        strategy = LiquidationStrategy({
            positionsToCheck: basePositions,
            riskThresholdOverride: riskOverride,
            prioritizeByRisk: prioritize,
            useEnhancedGas: enhancedGas
        });
        
        return strategy;
    }
    
    /**
     * @dev ⚡ ENHANCED: Performs emergency check with intelligent strategy
     */
    function _performEmergencyCheck(
        address loanManager,
        address changedAsset,
        LiquidationStrategy memory strategy
    ) internal returns (uint256 liquidatedCount) {
        
        try ILoanAutomation(loanManager).getTotalActivePositions() returns (uint256 totalPositions) {
            
            if (totalPositions == 0) return 0;
            
            uint256 positionsToCheck = strategy.positionsToCheck > totalPositions 
                ? totalPositions 
                : strategy.positionsToCheck;
            
            // Get positions to check
            uint256[] memory positionsInRange = ILoanAutomation(loanManager).getPositionsInRange(
                0, 
                positionsToCheck - 1
            );
            
            // ⚡ ENHANCED: Smart liquidation with prioritization
            if (strategy.prioritizeByRisk) {
                liquidatedCount = _executePrioritizedLiquidations(
                    loanManager,
                    positionsInRange,
                    strategy.riskThresholdOverride
                );
            } else {
                liquidatedCount = _executeStandardLiquidations(
                    loanManager,
                    positionsInRange,
                    changedAsset
                );
            }
            
        } catch {
            // Skip this loan manager if we can't access it
            return 0;
        }
        
        return liquidatedCount;
    }
    
    /**
     * @dev ⚡ NEW: Execute prioritized liquidations for urgent situations
     */
    function _executePrioritizedLiquidations(
        address loanManager,
        uint256[] memory positions,
        uint256 riskThresholdOverride
    ) internal returns (uint256 liquidatedCount) {
        
        // First pass: Get all positions with risk levels
        PositionRisk[] memory positionRisks = new PositionRisk[](positions.length);
        uint256 riskPositionsCount = 0;
        
        for (uint256 i = 0; i < positions.length; i++) {
            uint256 positionId = positions[i];
            
            (bool isAtRisk, uint256 riskLevel) = ILoanAutomation(loanManager).isPositionAtRisk(positionId);
            
            uint256 threshold = riskThresholdOverride > 0 ? riskThresholdOverride : 95;
            
            if (isAtRisk || riskLevel >= threshold) {
                positionRisks[riskPositionsCount] = PositionRisk({
                    positionId: positionId,
                    riskLevel: riskLevel
                });
                riskPositionsCount++;
            }
        }
        
        // Sort by risk level (highest first) - simple bubble sort for small arrays
        for (uint256 i = 0; i < riskPositionsCount - 1; i++) {
            for (uint256 j = 0; j < riskPositionsCount - i - 1; j++) {
                if (positionRisks[j].riskLevel < positionRisks[j + 1].riskLevel) {
                    PositionRisk memory temp = positionRisks[j];
                    positionRisks[j] = positionRisks[j + 1];
                    positionRisks[j + 1] = temp;
                }
            }
        }
        
        // Execute liquidations in priority order
        for (uint256 i = 0; i < riskPositionsCount; i++) {
            try ILoanAutomation(loanManager).automatedLiquidation(positionRisks[i].positionId) returns (bool success, uint256) {
                if (success) {
                    liquidatedCount++;
                }
            } catch {
                continue;
            }
        }
        
        return liquidatedCount;
    }
    
    /**
     * @dev ⚡ ENHANCED: Execute standard liquidations with asset filtering
     */
    function _executeStandardLiquidations(
        address loanManager,
        uint256[] memory positions,
        address changedAsset
    ) internal returns (uint256 liquidatedCount) {
        
        for (uint256 i = 0; i < positions.length; i++) {
            uint256 positionId = positions[i];
            
            // Check if position involves the asset that changed price
            if (_positionInvolvesAsset(loanManager, positionId, changedAsset)) {
                
                (bool isAtRisk, uint256 riskLevel) = ILoanAutomation(loanManager).isPositionAtRisk(positionId);
                
                if (isAtRisk && riskLevel >= 85) { // Standard risk threshold
                    try ILoanAutomation(loanManager).automatedLiquidation(positionId) returns (bool success, uint256) {
                        if (success) {
                            liquidatedCount++;
                        }
                    } catch {
                        continue;
                    }
                }
            }
        }
        
        return liquidatedCount;
    }
    
    struct PositionRisk {
        uint256 positionId;
        uint256 riskLevel;
    }
    
    /**
     * @dev ⚡ ENHANCED: Checks if a position involves a specific asset
     */
    function _positionInvolvesAsset(
        address loanManager,
        uint256 positionId,
        address asset
    ) internal view returns (bool involved) {
        
        try ILoanAutomation(loanManager).getPositionHealthData(positionId) returns (
            address,
            uint256,
            uint256,
            uint256
        ) {
            // For now, we'll assume all positions might be affected by major price changes
            // In a more sophisticated implementation, you would check if the position's
            // collateral or loan asset matches the changed asset
            return true;
        } catch {
            return false;
        }
    }
    
    /**
     * @dev ⚡ NEW: Check and deactivate volatility mode if expired
     */
    function _checkVolatilityModeExpiry(address asset) internal {
        if (assetInVolatilityMode[asset]) {
            if (block.timestamp >= volatilityModeEntered[asset] + volatilityModeDuration) {
                assetInVolatilityMode[asset] = false;
                emit VolatilityModeDeactivated(asset);
            }
        }
    }
    
    /**
     * @dev ⚡ NEW: Get urgency level as string for events
     */
    function _getUrgencyLevelString(uint256 urgencyLevel) internal pure returns (string memory) {
        if (urgencyLevel >= 4) return "CRITICAL";
        if (urgencyLevel >= 3) return "IMMEDIATE";
        if (urgencyLevel >= 2) return "URGENT";
        if (urgencyLevel >= 1) return "NORMAL";
        return "LOW";
    }
    
    // ========== EXTERNAL FUNCTIONS FOR PRICE DECODING ==========
    
    /**
     * @dev ⚡ NEW: Decode standard price update
     */
    function decodePriceUpdate(bytes calldata data) external pure returns (uint256 price) {
        return abi.decode(data, (uint256));
    }
    
    /**
     * @dev ⚡ NEW: Decode dynamic price registry update
     */
    function decodeDynamicPriceUpdate(bytes calldata data) external pure returns (uint256 price, uint8 decimals) {
        return abi.decode(data, (uint256, uint8));
    }
    
    // ========== CONFIGURATION FUNCTIONS ==========
    
    /**
     * @dev ⚡ ENHANCED: Registers a loan manager with priority
     */
    function registerLoanManager(address loanManager, uint256 priority) external onlyOwner {
        require(loanManager != address(0), "Invalid loan manager");
        require(!registeredLoanManagers[loanManager], "Already registered");
        require(priority <= 100, "Priority too high");
        
        registeredLoanManagers[loanManager] = true;
        managerPriority[loanManager] = priority;
        loanManagersList.push(loanManager);
        
        emit LoanManagerRegistered(loanManager, priority);
    }
    
    /**
     * @dev Unregisters a loan manager from monitoring
     */
    function unregisterLoanManager(address loanManager) external onlyOwner {
        require(registeredLoanManagers[loanManager], "Not registered");
        
        registeredLoanManagers[loanManager] = false;
        delete managerPriority[loanManager];
        
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
     * @dev ⚡ NEW: Sets price change thresholds
     */
    function setPriceChangeThresholds(
        uint256 _basic,
        uint256 _urgent,
        uint256 _immediate,
        uint256 _critical
    ) external onlyOwner {
        require(_basic <= _urgent && _urgent <= _immediate && _immediate <= _critical, "Invalid threshold order");
        require(_critical <= 500000, "Critical threshold too high"); // Max 50%
        
        emit ThresholdUpdated("basic", priceChangeThreshold, _basic);
        emit ThresholdUpdated("urgent", urgentThreshold, _urgent);
        emit ThresholdUpdated("immediate", immediateThreshold, _immediate);
        emit ThresholdUpdated("critical", criticalThreshold, _critical);
        
        priceChangeThreshold = _basic;
        urgentThreshold = _urgent;
        immediateThreshold = _immediate;
        criticalThreshold = _critical;
    }
    
    /**
     * @dev ⚡ NEW: Sets volatility parameters
     */
    function setVolatilityParameters(
        uint256 _boostThreshold,
        uint256 _modeDuration
    ) external onlyOwner {
        require(_boostThreshold >= urgentThreshold, "Boost threshold too low");
        require(_modeDuration >= 300 && _modeDuration <= 7200, "Invalid duration"); // 5min - 2hours
        
        volatilityBoostThreshold = _boostThreshold;
        volatilityModeDuration = _modeDuration;
    }
    
    /**
     * @dev Sets maximum positions per trigger
     */
    function setMaxPositionsPerTrigger(uint256 _maxPositions) external onlyOwner {
        require(_maxPositions >= 10 && _maxPositions <= 100, "Invalid max positions");
        maxPositionsPerTrigger = _maxPositions;
    }
    
    /**
     * @dev Emergency pause mechanism
     */
    function setEmergencyPause(bool _paused) external onlyOwner {
        emergencyPause = _paused;
    }
    
    // ========== VIEW FUNCTIONS ==========
    
    /**
     * @dev ⚡ ENHANCED: Gets comprehensive statistics
     */
    function getStatistics() external view returns (
        uint256 totalTriggers,
        uint256 totalLiquidations,
        uint256 totalVolatility,
        uint256 lastTrigger,
        uint256 activeVolatilityAssets
    ) {
        // Count assets currently in volatility mode
        uint256 volatileCount = 0;
        address[] memory supportedTokens = priceRegistry.getSupportedTokens();
        
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            if (assetInVolatilityMode[supportedTokens[i]]) {
                volatileCount++;
            }
        }
        
        return (
            totalTriggersProcessed,
            totalLiquidationsExecuted,
            totalVolatilityEvents,
            lastTriggerTimestamp,
            volatileCount
        );
    }
    
    /**
     * @dev ⚡ NEW: Gets price tracking data for an asset
     */
    function getAssetPriceData(address asset) external view returns (
        uint256 lastPrice,
        uint256 lastUpdate,
        uint256 changeCount,
        uint256 maxDeviation,
        bool inVolatilityMode,
        uint256 volatilityEntered
    ) {
        return (
            lastKnownPrices[asset],
            lastPriceUpdate[asset],
            priceChangeCount[asset],
            maxPriceDeviation[asset],
            assetInVolatilityMode[asset],
            volatilityModeEntered[asset]
        );
    }
    
    /**
     * @dev Gets registered loan managers with priorities
     */
    function getRegisteredManagers() external view returns (
        address[] memory managers,
        uint256[] memory priorities
    ) {
        managers = new address[](loanManagersList.length);
        priorities = new uint256[](loanManagersList.length);
        
        for (uint256 i = 0; i < loanManagersList.length; i++) {
            managers[i] = loanManagersList[i];
            priorities[i] = managerPriority[loanManagersList[i]];
        }
        
        return (managers, priorities);
    }
    
    /**
     * @dev ⚡ NEW: Gets current threshold configuration
     */
    function getThresholdConfiguration() external view returns (
        uint256 basic,
        uint256 urgent,
        uint256 immediate,
        uint256 critical,
        uint256 volatilityBoost,
        uint256 volatilityDuration
    ) {
        return (
            priceChangeThreshold,
            urgentThreshold,
            immediateThreshold,
            criticalThreshold,
            volatilityBoostThreshold,
            volatilityModeDuration
        );
    }
} 
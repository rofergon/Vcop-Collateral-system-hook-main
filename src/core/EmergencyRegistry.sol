// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IEmergencyRegistry} from "../interfaces/IEmergencyRegistry.sol";

/**
 * @title EmergencyRegistry
 * @notice 🚨 CENTRALIZED EMERGENCY COORDINATION SYSTEM 🚨
 * @dev Manages emergency states across all asset handlers and loan managers
 */
contract EmergencyRegistry is IEmergencyRegistry, Ownable {
    
    // ⚡ CORE STATE: Emergency levels per asset
    mapping(address => EmergencyState) public assetEmergencyStates;
    EmergencyLevel public globalEmergencyLevel = EmergencyLevel.NONE;
    
    // ⚡ REGISTRY: Registered contracts
    mapping(address => bool) public registeredAssetHandlers;
    mapping(address => bool) public registeredLoanManagers;
    mapping(address => string) public handlerTypes;
    mapping(address => string) public managerTypes;
    
    // ⚡ ACCESS CONTROL: Authorized emergency responders
    mapping(address => bool) public emergencyResponders;
    
    // ⚡ TRACKING: Lists for iteration
    address[] public allAssetHandlers;
    address[] public allLoanManagers;
    address[] public assetsInEmergency;
    
    // ⚡ GLOBAL SETTINGS
    uint256 public constant EMERGENCY_LIQUIDATION_RATIO = 2000000; // 200% - makes most positions liquidatable
    uint256 public constant CRITICAL_LIQUIDATION_RATIO = 1100000;  // 110% - enhanced liquidation
    uint256 public constant WARNING_LIQUIDATION_RATIO = 1150000;   // 115% - elevated monitoring
    
    // ⚡ STATISTICS
    uint256 public totalEmergenciesActivated;
    uint256 public totalEmergenciesResolved;
    uint256 public lastEmergencyTimestamp;
    
    constructor() Ownable(msg.sender) {
        // Owner is automatically an emergency responder
        emergencyResponders[msg.sender] = true;
    }
    
    // ========================================
    // ⚡ EMERGENCY LEVEL MANAGEMENT
    // ========================================
    
    /**
     * @dev 🚨 Sets emergency level for a specific asset
     */
    function setAssetEmergencyLevel(
        address asset,
        EmergencyLevel level,
        uint256 emergencyRatio,
        string calldata reason
    ) external override {
        require(emergencyResponders[msg.sender] || msg.sender == owner(), "Unauthorized emergency responder");
        require(asset != address(0), "Invalid asset address");
        
        // Update emergency state
        assetEmergencyStates[asset] = EmergencyState({
            level: level,
            activatedAt: block.timestamp,
            emergencyRatio: level == EmergencyLevel.EMERGENCY ? emergencyRatio : 0,
            activatedBy: msg.sender,
            reason: reason,
            isActive: level != EmergencyLevel.NONE
        });
        
        // Track active emergencies
        if (level != EmergencyLevel.NONE) {
            _addAssetToEmergencyList(asset);
            totalEmergenciesActivated++;
            lastEmergencyTimestamp = block.timestamp;
        } else {
            _removeAssetFromEmergencyList(asset);
            totalEmergenciesResolved++;
            emit EmergencyResolved(asset, msg.sender);
        }
        
        emit AssetEmergencyLevelSet(asset, level, emergencyRatio, reason);
    }
    
    /**
     * @dev 🚨 Sets global emergency level (affects ALL assets)
     */
    function setGlobalEmergencyLevel(
        EmergencyLevel level,
        string calldata reason
    ) external override {
        require(emergencyResponders[msg.sender] || msg.sender == owner(), "Unauthorized emergency responder");
        
        globalEmergencyLevel = level;
        lastEmergencyTimestamp = block.timestamp;
        
        if (level != EmergencyLevel.NONE) {
            totalEmergenciesActivated++;
        } else {
            totalEmergenciesResolved++;
        }
        
        emit GlobalEmergencyLevelSet(level, reason);
    }
    
    // ========================================
    // ⚡ EMERGENCY STATE QUERIES
    // ========================================
    
    /**
     * @dev Gets emergency state for an asset
     */
    function getAssetEmergencyState(address asset) external view override returns (EmergencyState memory state) {
        return assetEmergencyStates[asset];
    }
    
    /**
     * @dev Gets global emergency level
     */
    function getGlobalEmergencyLevel() external view override returns (EmergencyLevel level) {
        return globalEmergencyLevel;
    }
    
    /**
     * @dev ⚡ CRITICAL: Checks if an asset is in emergency mode
     * This is the KEY function that loan managers will call!
     */
    function isAssetInEmergency(address asset) external view override returns (bool isEmergency, uint256 effectiveRatio) {
        // Check global emergency first
        if (globalEmergencyLevel != EmergencyLevel.NONE) {
            isEmergency = true;
            effectiveRatio = _getLevelRatio(globalEmergencyLevel, 0);
            return (isEmergency, effectiveRatio);
        }
        
        // Check asset-specific emergency
        EmergencyState memory state = assetEmergencyStates[asset];
        if (state.isActive && state.level != EmergencyLevel.NONE) {
            isEmergency = true;
            effectiveRatio = _getLevelRatio(state.level, state.emergencyRatio);
            return (isEmergency, effectiveRatio);
        }
        
        return (false, 0);
    }
    
    /**
     * @dev ⚡ ENHANCED: Gets the effective liquidation ratio (considering emergency states)
     * This replaces the need for hardcoded ratios!
     */
    function getEffectiveLiquidationRatio(address asset, uint256 defaultRatio) external view override returns (uint256 effectiveRatio) {
        (bool isEmergency, uint256 emergencyRatio) = this.isAssetInEmergency(asset);
        
        if (isEmergency) {
            // Use emergency ratio if in emergency mode
            return emergencyRatio;
        }
        
        // Use default ratio if no emergency
        return defaultRatio;
    }
    
    // ========================================
    // ⚡ CONTRACT REGISTRATION
    // ========================================
    
    /**
     * @dev Registers an asset handler for emergency coordination
     */
    function registerAssetHandler(address handler, string calldata handlerType) external override onlyOwner {
        require(handler != address(0), "Invalid handler address");
        require(!registeredAssetHandlers[handler], "Handler already registered");
        
        registeredAssetHandlers[handler] = true;
        handlerTypes[handler] = handlerType;
        allAssetHandlers.push(handler);
        
        emit AssetHandlerRegistered(handler, handlerType);
    }
    
    /**
     * @dev Registers a loan manager for emergency coordination
     */
    function registerLoanManager(address loanManager, string calldata managerType) external override onlyOwner {
        require(loanManager != address(0), "Invalid loan manager address");
        require(!registeredLoanManagers[loanManager], "Manager already registered");
        
        registeredLoanManagers[loanManager] = true;
        managerTypes[loanManager] = managerType;
        allLoanManagers.push(loanManager);
        
        emit LoanManagerRegistered(loanManager, managerType);
    }
    
    // ========================================
    // ⚡ ACCESS CONTROL
    // ========================================
    
    /**
     * @dev Adds an emergency responder
     */
    function addEmergencyResponder(address responder) external onlyOwner {
        require(responder != address(0), "Invalid responder address");
        emergencyResponders[responder] = true;
    }
    
    /**
     * @dev Removes an emergency responder
     */
    function removeEmergencyResponder(address responder) external onlyOwner {
        emergencyResponders[responder] = false;
    }
    
    // ========================================
    // ⚡ CONVENIENCE FUNCTIONS
    // ========================================
    
    /**
     * @dev 🚨 QUICK EMERGENCY: Activate emergency mode for multiple assets
     */
    function quickEmergencyActivation(address[] calldata assets, string calldata reason) external {
        require(emergencyResponders[msg.sender] || msg.sender == owner(), "Unauthorized");
        
        for (uint256 i = 0; i < assets.length; i++) {
            this.setAssetEmergencyLevel(
                assets[i], 
                EmergencyLevel.EMERGENCY, 
                EMERGENCY_LIQUIDATION_RATIO, 
                reason
            );
        }
    }
    
    /**
     * @dev 🔧 QUICK RESOLVE: Resolve emergency mode for multiple assets
     */
    function quickEmergencyResolution(address[] calldata assets, string calldata reason) external {
        require(emergencyResponders[msg.sender] || msg.sender == owner(), "Unauthorized");
        
        for (uint256 i = 0; i < assets.length; i++) {
            this.setAssetEmergencyLevel(
                assets[i], 
                EmergencyLevel.NONE, 
                0, 
                reason
            );
        }
    }
    
    // ========================================
    // ⚡ VIEW FUNCTIONS
    // ========================================
    
    /**
     * @dev Gets all assets currently in emergency
     */
    function getAssetsInEmergency() external view returns (address[] memory) {
        return assetsInEmergency;
    }
    
    /**
     * @dev Gets all registered asset handlers
     */
    function getRegisteredAssetHandlers() external view returns (address[] memory) {
        return allAssetHandlers;
    }
    
    /**
     * @dev Gets all registered loan managers
     */
    function getRegisteredLoanManagers() external view returns (address[] memory) {
        return allLoanManagers;
    }
    
    /**
     * @dev Gets emergency statistics
     */
    function getEmergencyStats() external view returns (
        uint256 totalActivated,
        uint256 totalResolved,
        uint256 currentlyActive,
        uint256 lastEmergency,
        EmergencyLevel globalLevel
    ) {
        return (
            totalEmergenciesActivated,
            totalEmergenciesResolved,
            assetsInEmergency.length,
            lastEmergencyTimestamp,
            globalEmergencyLevel
        );
    }
    
    // ========================================
    // ⚡ INTERNAL HELPERS
    // ========================================
    
    /**
     * @dev Gets the liquidation ratio for an emergency level
     */
    function _getLevelRatio(EmergencyLevel level, uint256 customRatio) internal pure returns (uint256) {
        if (level == EmergencyLevel.EMERGENCY) {
            return customRatio > 0 ? customRatio : EMERGENCY_LIQUIDATION_RATIO;
        } else if (level == EmergencyLevel.CRITICAL) {
            return CRITICAL_LIQUIDATION_RATIO;
        } else if (level == EmergencyLevel.WARNING) {
            return WARNING_LIQUIDATION_RATIO;
        }
        return 0;
    }
    
    /**
     * @dev Adds asset to emergency tracking list
     */
    function _addAssetToEmergencyList(address asset) internal {
        // Check if already in list
        for (uint256 i = 0; i < assetsInEmergency.length; i++) {
            if (assetsInEmergency[i] == asset) {
                return; // Already in list
            }
        }
        assetsInEmergency.push(asset);
    }
    
    /**
     * @dev Removes asset from emergency tracking list
     */
    function _removeAssetFromEmergencyList(address asset) internal {
        for (uint256 i = 0; i < assetsInEmergency.length; i++) {
            if (assetsInEmergency[i] == asset) {
                // Move last element to this position
                assetsInEmergency[i] = assetsInEmergency[assetsInEmergency.length - 1];
                assetsInEmergency.pop();
                return;
            }
        }
    }
} 
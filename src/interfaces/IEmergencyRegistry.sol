// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IEmergencyRegistry
 * @notice Centralized registry for emergency liquidation states across the system
 * @dev Coordinates emergency modes between asset handlers and loan managers
 */
interface IEmergencyRegistry {
    
    // Emergency state levels
    enum EmergencyLevel {
        NONE,           // 0 - Normal operation
        WARNING,        // 1 - Elevated monitoring
        CRITICAL,       // 2 - Enhanced liquidation
        EMERGENCY       // 3 - All positions liquidatable
    }
    
    // Emergency state data
    struct EmergencyState {
        EmergencyLevel level;
        uint256 activatedAt;
        uint256 emergencyRatio;     // Custom liquidation ratio during emergency
        address activatedBy;
        string reason;
        bool isActive;
    }
    
    /**
     * @dev Sets emergency level for a specific asset
     * @param asset The asset address
     * @param level Emergency level to set
     * @param emergencyRatio Custom liquidation ratio (only used in EMERGENCY level)
     * @param reason Reason for emergency activation
     */
    function setAssetEmergencyLevel(
        address asset,
        EmergencyLevel level,
        uint256 emergencyRatio,
        string calldata reason
    ) external;
    
    /**
     * @dev Sets global emergency level (affects all assets)
     * @param level Emergency level to set
     * @param reason Reason for emergency activation
     */
    function setGlobalEmergencyLevel(
        EmergencyLevel level,
        string calldata reason
    ) external;
    
    /**
     * @dev Gets emergency state for an asset
     * @param asset The asset address
     * @return state The current emergency state
     */
    function getAssetEmergencyState(address asset) external view returns (EmergencyState memory state);
    
    /**
     * @dev Gets global emergency level
     * @return level Current global emergency level
     */
    function getGlobalEmergencyLevel() external view returns (EmergencyLevel level);
    
    /**
     * @dev Checks if an asset is in emergency mode
     * @param asset The asset address
     * @return isEmergency True if asset is in any emergency level > NONE
     * @return effectiveRatio The effective liquidation ratio to use
     */
    function isAssetInEmergency(address asset) external view returns (bool isEmergency, uint256 effectiveRatio);
    
    /**
     * @dev Registers an asset handler for emergency coordination
     * @param handler Address of the asset handler
     * @param handlerType Type identifier for the handler
     */
    function registerAssetHandler(address handler, string calldata handlerType) external;
    
    /**
     * @dev Registers a loan manager for emergency coordination
     * @param loanManager Address of the loan manager
     * @param managerType Type identifier for the manager
     */
    function registerLoanManager(address loanManager, string calldata managerType) external;
    
    /**
     * @dev Gets the effective liquidation ratio for an asset (considering emergency states)
     * @param asset The asset address
     * @param defaultRatio The normal liquidation ratio
     * @return effectiveRatio The ratio to actually use
     */
    function getEffectiveLiquidationRatio(address asset, uint256 defaultRatio) external view returns (uint256 effectiveRatio);
    
    // Events
    event AssetEmergencyLevelSet(address indexed asset, EmergencyLevel level, uint256 emergencyRatio, string reason);
    event GlobalEmergencyLevelSet(EmergencyLevel level, string reason);
    event AssetHandlerRegistered(address indexed handler, string handlerType);
    event LoanManagerRegistered(address indexed loanManager, string managerType);
    event EmergencyResolved(address indexed asset, address resolvedBy);
} 
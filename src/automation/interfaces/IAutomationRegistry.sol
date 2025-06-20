// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IAutomationRegistry
 * @notice Interface for registering and managing loan managers in automation system
 */
interface IAutomationRegistry {
    
    struct LoanManagerInfo {
        address managerAddress;
        string name;
        bool isActive;
        uint256 batchSize;          // How many positions to check per batch
        uint256 lastCheckedIndex;   // For rotative scanning
        uint256 totalPositions;     // Cache of total positions
        uint256 riskThreshold;      // Risk threshold for this manager
    }
    
    /**
     * @dev Registers a loan manager for automation
     * @param manager Address of the loan manager
     * @param name Human readable name
     * @param batchSize Number of positions to check per automation round
     * @param riskThreshold Risk threshold (0-100)
     */
    function registerLoanManager(
        address manager,
        string calldata name,
        uint256 batchSize,
        uint256 riskThreshold
    ) external;
    
    /**
     * @dev Unregisters a loan manager from automation
     * @param manager Address of the loan manager to remove
     */
    function unregisterLoanManager(address manager) external;
    
    /**
     * @dev Updates loan manager settings
     * @param manager Address of the loan manager
     * @param batchSize New batch size
     * @param riskThreshold New risk threshold
     */
    function updateLoanManagerSettings(
        address manager,
        uint256 batchSize,
        uint256 riskThreshold
    ) external;
    
    /**
     * @dev Sets active status for a loan manager
     * @param manager Address of the loan manager
     * @param isActive Whether automation should be active
     */
    function setLoanManagerStatus(address manager, bool isActive) external;
    
    /**
     * @dev Gets registered loan managers
     * @return managers Array of registered loan manager addresses
     */
    function getRegisteredManagers() external view returns (address[] memory managers);
    
    /**
     * @dev Gets loan manager info
     * @param manager Address of the loan manager
     * @return info Loan manager information struct
     */
    function getLoanManagerInfo(address manager) external view returns (LoanManagerInfo memory info);
    
    /**
     * @dev Checks if a manager is registered and active
     * @param manager Address to check
     * @return isRegistered True if registered and active
     */
    function isManagerActive(address manager) external view returns (bool isRegistered);
    
    /**
     * @dev Updates the cached total positions for a manager
     * @param manager Address of the loan manager
     */
    function updatePositionCount(address manager) external;
    
    // Events
    event LoanManagerRegistered(address indexed manager, string name, uint256 batchSize);
    event LoanManagerUnregistered(address indexed manager);
    event LoanManagerUpdated(address indexed manager, uint256 batchSize, uint256 riskThreshold);
    event LoanManagerStatusChanged(address indexed manager, bool isActive);
} 
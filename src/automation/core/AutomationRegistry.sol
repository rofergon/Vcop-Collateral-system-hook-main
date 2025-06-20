// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// WARNING: DEPRECATED CONTRACT - NO LONGER USED
// ==========================================
// This contract has been deprecated in favor of using the official Chainlink Automation Registry.
// Both production and mock deployments now use the official Chainlink infrastructure:
// Registry Address (Base Sepolia): 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3
//
// This file is kept for reference but should not be deployed in new systems.
// Use DeployAutomationProduction.s.sol or DeployAutomationMock.s.sol instead.
// ==========================================

import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IAutomationRegistry} from "../interfaces/IAutomationRegistry.sol";
import {ILoanAutomation} from "../interfaces/ILoanAutomation.sol";

/**
 * @title AutomationRegistry - DEPRECATED
 * @notice This contract is no longer used - replaced by official Chainlink Registry
 * @dev DEPRECATED: Use official Chainlink Automation Registry instead
 */
contract AutomationRegistry is IAutomationRegistry, Ownable {
    
    // Mapping of manager address to manager info
    mapping(address => LoanManagerInfo) public managerInfo;
    
    // Array of registered manager addresses
    address[] public registeredManagers;
    
    // Mapping to track if an address is registered (for O(1) lookup)
    mapping(address => bool) public isRegistered;
    
    // Authorized automation contracts
    mapping(address => bool) public authorizedAutomationContracts;
    
    // Global settings
    uint256 public defaultBatchSize = 50;
    uint256 public defaultRiskThreshold = 80;
    uint256 public maxBatchSize = 200;
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Registers a loan manager for automation
     */
    function registerLoanManager(
        address manager,
        string calldata name,
        uint256 batchSize,
        uint256 riskThreshold
    ) external override onlyOwner {
        require(manager != address(0), "Invalid manager address");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(batchSize > 0 && batchSize <= maxBatchSize, "Invalid batch size");
        require(riskThreshold <= 100, "Risk threshold must be <= 100");
        require(!isRegistered[manager], "Manager already registered");
        
        // Verify the manager implements ILoanAutomation
        try ILoanAutomation(manager).isAutomationEnabled() returns (bool) {
            // Interface check passed
        } catch {
            revert("Manager does not implement ILoanAutomation");
        }
        
        // Add to registered managers array
        registeredManagers.push(manager);
        isRegistered[manager] = true;
        
        // Store manager info
        managerInfo[manager] = LoanManagerInfo({
            managerAddress: manager,
            name: name,
            isActive: true,
            batchSize: batchSize,
            lastCheckedIndex: 0,
            totalPositions: 0,
            riskThreshold: riskThreshold
        });
        
        // Update position count
        _updatePositionCount(manager);
        
        emit LoanManagerRegistered(manager, name, batchSize);
    }
    
    /**
     * @dev Unregisters a loan manager from automation
     */
    function unregisterLoanManager(address manager) external override onlyOwner {
        require(isRegistered[manager], "Manager not registered");
        
        // Remove from registered managers array
        for (uint256 i = 0; i < registeredManagers.length; i++) {
            if (registeredManagers[i] == manager) {
                registeredManagers[i] = registeredManagers[registeredManagers.length - 1];
                registeredManagers.pop();
                break;
            }
        }
        
        // Clean up mappings
        delete managerInfo[manager];
        delete isRegistered[manager];
        
        emit LoanManagerUnregistered(manager);
    }
    
    /**
     * @dev Updates loan manager settings
     */
    function updateLoanManagerSettings(
        address manager,
        uint256 batchSize,
        uint256 riskThreshold
    ) external override onlyOwner {
        require(isRegistered[manager], "Manager not registered");
        require(batchSize > 0 && batchSize <= maxBatchSize, "Invalid batch size");
        require(riskThreshold <= 100, "Risk threshold must be <= 100");
        
        LoanManagerInfo storage info = managerInfo[manager];
        info.batchSize = batchSize;
        info.riskThreshold = riskThreshold;
        
        emit LoanManagerUpdated(manager, batchSize, riskThreshold);
    }
    
    /**
     * @dev Sets active status for a loan manager
     */
    function setLoanManagerStatus(address manager, bool isActive) external override onlyOwner {
        require(isRegistered[manager], "Manager not registered");
        
        managerInfo[manager].isActive = isActive;
        
        emit LoanManagerStatusChanged(manager, isActive);
    }
    
    /**
     * @dev Gets registered loan managers
     */
    function getRegisteredManagers() external view override returns (address[] memory managers) {
        return registeredManagers;
    }
    
    /**
     * @dev Gets loan manager info
     */
    function getLoanManagerInfo(address manager) external view override returns (LoanManagerInfo memory info) {
        require(isRegistered[manager], "Manager not registered");
        return managerInfo[manager];
    }
    
    /**
     * @dev Checks if a manager is registered and active
     */
    function isManagerActive(address manager) external view override returns (bool) {
        return isRegistered[manager] && managerInfo[manager].isActive;
    }
    
    /**
     * @dev Updates the cached total positions for a manager
     */
    function updatePositionCount(address manager) external override {
        require(
            isRegistered[manager] || authorizedAutomationContracts[msg.sender],
            "Unauthorized"
        );
        _updatePositionCount(manager);
    }
    
    /**
     * @dev Internal function to update position count
     */
    function _updatePositionCount(address manager) internal {
        if (!isRegistered[manager]) return;
        
        try ILoanAutomation(manager).getTotalActivePositions() returns (uint256 totalPositions) {
            managerInfo[manager].totalPositions = totalPositions;
        } catch {
            // If call fails, keep the old count
        }
    }
    
    /**
     * @dev Updates the last checked index for a manager (for rotative scanning)
     */
    function updateLastCheckedIndex(address manager, uint256 newIndex) external {
        require(authorizedAutomationContracts[msg.sender], "Unauthorized");
        require(isRegistered[manager], "Manager not registered");
        
        managerInfo[manager].lastCheckedIndex = newIndex;
    }
    
    /**
     * @dev Authorizes an automation contract to interact with the registry
     */
    function setAutomationContractAuthorization(address automationContract, bool authorized) external onlyOwner {
        require(automationContract != address(0), "Invalid contract address");
        authorizedAutomationContracts[automationContract] = authorized;
    }
    
    /**
     * @dev Sets global default settings
     */
    function setGlobalDefaults(
        uint256 _defaultBatchSize,
        uint256 _defaultRiskThreshold,
        uint256 _maxBatchSize
    ) external onlyOwner {
        require(_defaultBatchSize > 0 && _defaultBatchSize <= _maxBatchSize, "Invalid default batch size");
        require(_defaultRiskThreshold <= 100, "Invalid default risk threshold");
        require(_maxBatchSize > 0, "Invalid max batch size");
        
        defaultBatchSize = _defaultBatchSize;
        defaultRiskThreshold = _defaultRiskThreshold;
        maxBatchSize = _maxBatchSize;
    }
    
    /**
     * @dev Gets active managers with their next batch info (for automation scheduling)
     */
    function getActiveManagersWithBatchInfo() external view returns (
        address[] memory activeManagers,
        uint256[] memory nextStartIndices,
        uint256[] memory batchSizes,
        uint256[] memory totalPositions
    ) {
        // Count active managers
        uint256 activeCount = 0;
        for (uint256 i = 0; i < registeredManagers.length; i++) {
            if (managerInfo[registeredManagers[i]].isActive) {
                activeCount++;
            }
        }
        
        // Populate arrays
        activeManagers = new address[](activeCount);
        nextStartIndices = new uint256[](activeCount);
        batchSizes = new uint256[](activeCount);
        totalPositions = new uint256[](activeCount);
        
        uint256 index = 0;
        for (uint256 i = 0; i < registeredManagers.length; i++) {
            address manager = registeredManagers[i];
            LoanManagerInfo memory info = managerInfo[manager];
            
            if (info.isActive) {
                activeManagers[index] = manager;
                nextStartIndices[index] = info.lastCheckedIndex;
                batchSizes[index] = info.batchSize;
                totalPositions[index] = info.totalPositions;
                index++;
            }
        }
    }
    
    /**
     * @dev Gets statistics for all registered managers
     */
    function getRegistryStats() external view returns (
        uint256 totalRegistered,
        uint256 totalActive,
        uint256 totalPositionsAcrossAll
    ) {
        totalRegistered = registeredManagers.length;
        
        for (uint256 i = 0; i < registeredManagers.length; i++) {
            address manager = registeredManagers[i];
            LoanManagerInfo memory info = managerInfo[manager];
            
            if (info.isActive) {
                totalActive++;
            }
            totalPositionsAcrossAll += info.totalPositions;
        }
    }
    
    /**
     * @dev Bulk update position counts for all registered managers
     */
    function bulkUpdatePositionCounts() external {
        require(
            msg.sender == owner() || authorizedAutomationContracts[msg.sender],
            "Unauthorized"
        );
        
        for (uint256 i = 0; i < registeredManagers.length; i++) {
            _updatePositionCount(registeredManagers[i]);
        }
    }
} 
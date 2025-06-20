// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAutomationRegistry} from "../interfaces/IAutomationRegistry.sol";

/**
 * @title MockAutomationRegistry
 * @notice Simple mock for testing automation functionality
 */
contract MockAutomationRegistry is IAutomationRegistry {
    
    mapping(address => bool) public activeManagers;
    address[] public managers;
    
    // All managers are active by default for testing
    function isManagerActive(address manager) external view override returns (bool) {
        return activeManagers[manager] || managers.length == 0; // Default to true if no managers registered
    }
    
    function registerLoanManager(
        address manager,
        string calldata, // name
        uint256, // batchSize
        uint256  // riskThreshold
    ) external override {
        if (!activeManagers[manager]) {
            activeManagers[manager] = true;
            managers.push(manager);
        }
    }
    
    function unregisterLoanManager(address manager) external override {
        activeManagers[manager] = false;
        // Remove from array
        for (uint256 i = 0; i < managers.length; i++) {
            if (managers[i] == manager) {
                managers[i] = managers[managers.length - 1];
                managers.pop();
                break;
            }
        }
    }
    
    function updateLoanManagerSettings(
        address, // manager
        uint256, // batchSize
        uint256  // riskThreshold
    ) external override {
        // Mock - do nothing
    }
    
    function setLoanManagerStatus(address manager, bool isActive) external override {
        activeManagers[manager] = isActive;
    }
    
    function getRegisteredManagers() external view override returns (address[] memory) {
        return managers;
    }
    
    function getLoanManagerInfo(address manager) external view override returns (LoanManagerInfo memory) {
        return LoanManagerInfo({
            managerAddress: manager,
            name: "Mock Manager",
            isActive: activeManagers[manager],
            batchSize: 10,
            lastCheckedIndex: 0,
            totalPositions: 1,
            riskThreshold: 75
        });
    }
    
    function updatePositionCount(address) external override {
        // Mock - do nothing
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Local interface definition (based on Chainlink's AutomationCompatibleInterface)
interface AutomationCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does not actually need to be executable in
     * the contract.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easily be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able to call it, and the input should be validated, typically by checking
     * the source of the data (not just the caller).
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}
import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ILoanAutomation} from "../interfaces/ILoanAutomation.sol";
import {IAutomationRegistry} from "../interfaces/IAutomationRegistry.sol";

/**
 * @title LoanAutomationKeeper
 * @notice Main Chainlink Automation contract for monitoring loan positions and triggering liquidations
 * @dev Implements AutomationCompatibleInterface for Chainlink Keepers
 */
contract LoanAutomationKeeper is AutomationCompatibleInterface, Ownable {
    
    // Registry for managing multiple loan managers
    IAutomationRegistry public automationRegistry;
    
    // Configuration
    uint256 public maxGasPerUpkeep = 2000000; // Maximum gas per upkeep execution
    uint256 public minRiskThreshold = 80;     // Minimum risk level to trigger liquidation
    bool public emergencyPause = false;      // Emergency pause mechanism
    
    // Performance tracking
    uint256 public totalLiquidations;
    uint256 public totalUpkeeps;
    uint256 public lastExecutionTimestamp;
    
    // Forwarder security (optional - for production use)
    address public forwarderAddress;
    
    // Events
    event UpkeepPerformed(uint256 indexed totalPositionsChecked, uint256 liquidationsExecuted);
    event LiquidationExecuted(address indexed loanManager, uint256 indexed positionId, uint256 amount);
    event EmergencyPaused(bool paused);
    event ForwarderSet(address forwarder);
    
    constructor(address _automationRegistry) Ownable(msg.sender) {
        automationRegistry = IAutomationRegistry(_automationRegistry);
    }
    
    /**
     * @dev Chainlink Automation checkUpkeep function - executed off-chain
     * @param checkData ABI-encoded data specifying which manager and range to check
     * @return upkeepNeeded True if liquidations are needed
     * @return performData Data for performUpkeep containing positions to liquidate
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        
        // Emergency pause check
        if (emergencyPause) {
            return (false, bytes(""));
        }
        
        // Decode checkData to get manager address and range
        (address loanManager, uint256 startIndex, uint256 batchSize) = 
            abi.decode(checkData, (address, uint256, uint256));
        
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
        
        // Calculate end index for this batch
        uint256 totalPositions = loanAutomation.getTotalActivePositions();
        if (startIndex >= totalPositions) {
            return (false, bytes(""));
        }
        
        uint256 endIndex = startIndex + batchSize - 1;
        if (endIndex >= totalPositions) {
            endIndex = totalPositions - 1;
        }
        
        // Get positions in the specified range
        uint256[] memory positionsInRange = loanAutomation.getPositionsInRange(startIndex, endIndex);
        
        // Arrays to collect positions that need liquidation
        uint256[] memory toLiquidate = new uint256[](positionsInRange.length);
        uint256 liquidationCount = 0;
        
        // Check each position for risk
        for (uint256 i = 0; i < positionsInRange.length; i++) {
            uint256 positionId = positionsInRange[i];
            
            (bool isAtRisk, uint256 riskLevel) = loanAutomation.isPositionAtRisk(positionId);
            
            // Add to liquidation list if risk level exceeds threshold
            if (isAtRisk && riskLevel >= minRiskThreshold) {
                toLiquidate[liquidationCount] = positionId;
                liquidationCount++;
                upkeepNeeded = true;
            }
        }
        
        // If no liquidations needed, return false
        if (!upkeepNeeded) {
            return (false, bytes(""));
        }
        
        // Truncate array to actual liquidation count and encode performData
        uint256[] memory finalLiquidations = new uint256[](liquidationCount);
        for (uint256 i = 0; i < liquidationCount; i++) {
            finalLiquidations[i] = toLiquidate[i];
        }
        
        // Encode performData with loan manager address and positions to liquidate
        performData = abi.encode(loanManager, finalLiquidations);
        
        return (true, performData);
    }
    
    /**
     * @dev Chainlink Automation performUpkeep function - executed on-chain
     * @param performData Data from checkUpkeep containing positions to liquidate
     */
    function performUpkeep(bytes calldata performData) external override {
        
        // Security check: verify forwarder if set
        if (forwarderAddress != address(0)) {
            require(msg.sender == forwarderAddress, "Unauthorized: invalid forwarder");
        }
        
        // Emergency pause check
        require(!emergencyPause, "Emergency paused");
        
        // Decode performData
        (address loanManager, uint256[] memory positionsToLiquidate) = 
            abi.decode(performData, (address, uint256[]));
        
        // Verify manager is still active
        require(automationRegistry.isManagerActive(loanManager), "Manager not active");
        
        ILoanAutomation loanAutomation = ILoanAutomation(loanManager);
        require(loanAutomation.isAutomationEnabled(), "Automation disabled");
        
        // Track execution
        uint256 liquidationsExecuted = 0;
        uint256 gasUsed = gasleft();
        
        // Execute liquidations
        for (uint256 i = 0; i < positionsToLiquidate.length; i++) {
            uint256 gasStart = gasleft();
            
            // Safety check: ensure we don't exceed gas limit
            if (gasUsed - gasStart > maxGasPerUpkeep) {
                break; // Stop if approaching gas limit
            }
            
            uint256 positionId = positionsToLiquidate[i];
            
            // Double-check position is still at risk before liquidating
            (bool isAtRisk, uint256 riskLevel) = loanAutomation.isPositionAtRisk(positionId);
            
            if (isAtRisk && riskLevel >= minRiskThreshold) {
                try loanAutomation.automatedLiquidation(positionId) returns (bool success, uint256 amount) {
                    if (success) {
                        liquidationsExecuted++;
                        emit LiquidationExecuted(loanManager, positionId, amount);
                    }
                } catch {
                    // Continue with next position if one fails
                    continue;
                }
            }
            
            gasUsed = gasStart;
        }
        
        // Update statistics
        totalLiquidations += liquidationsExecuted;
        totalUpkeeps++;
        lastExecutionTimestamp = block.timestamp;
        
        emit UpkeepPerformed(positionsToLiquidate.length, liquidationsExecuted);
    }
    
    /**
     * @dev Sets the automation registry contract
     * @param _registry Address of the new registry
     */
    function setAutomationRegistry(address _registry) external onlyOwner {
        require(_registry != address(0), "Invalid registry address");
        automationRegistry = IAutomationRegistry(_registry);
    }
    
    /**
     * @dev Sets the maximum gas per upkeep
     * @param _maxGas New maximum gas amount
     */
    function setMaxGasPerUpkeep(uint256 _maxGas) external onlyOwner {
        require(_maxGas > 0, "Gas must be positive");
        maxGasPerUpkeep = _maxGas;
    }
    
    /**
     * @dev Sets the minimum risk threshold for liquidations
     * @param _threshold New minimum threshold (0-100)
     */
    function setMinRiskThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold <= 100, "Threshold must be <= 100");
        minRiskThreshold = _threshold;
    }
    
    /**
     * @dev Emergency pause mechanism
     * @param _paused Whether to pause automation
     */
    function setEmergencyPause(bool _paused) external onlyOwner {
        emergencyPause = _paused;
        emit EmergencyPaused(_paused);
    }
    
    /**
     * @dev Sets the forwarder address for additional security
     * @param _forwarder Address of the Chainlink forwarder
     */
    function setForwarderAddress(address _forwarder) external onlyOwner {
        forwarderAddress = _forwarder;
        emit ForwarderSet(_forwarder);
    }
    
    /**
     * @dev Gets automation statistics
     * @return totalLiquidationsCount Total liquidations executed
     * @return totalUpkeepsCount Total upkeeps performed
     * @return lastExecution Timestamp of last execution
     */
    function getAutomationStats() external view returns (
        uint256 totalLiquidationsCount,
        uint256 totalUpkeepsCount,
        uint256 lastExecution
    ) {
        return (totalLiquidations, totalUpkeeps, lastExecutionTimestamp);
    }
    
    /**
     * @dev Checks if automation is currently active
     * @return isActive True if not paused and has active managers
     */
    function isAutomationActive() external view returns (bool isActive) {
        if (emergencyPause) return false;
        
        address[] memory managers = automationRegistry.getRegisteredManagers();
        for (uint256 i = 0; i < managers.length; i++) {
            if (automationRegistry.isManagerActive(managers[i])) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev Helper function to generate checkData for specific manager and range
     * @param loanManager Address of the loan manager
     * @param startIndex Starting position index
     * @param batchSize Number of positions to check
     * @return checkData Encoded data for checkUpkeep
     */
    function generateCheckData(
        address loanManager,
        uint256 startIndex,
        uint256 batchSize
    ) external pure returns (bytes memory checkData) {
        return abi.encode(loanManager, startIndex, batchSize);
    }
} 
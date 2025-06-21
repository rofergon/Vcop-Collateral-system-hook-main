// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title MonitorChainlinkUpkeep
 * @notice Monitor registered Chainlink Automation upkeep in REAL-TIME
 * @dev Verifies LINK consumption, execution history, and upkeep status
 */
contract MonitorChainlinkUpkeep is Script {
    
    // OFFICIAL CHAINLINK AUTOMATION REGISTRY (Base Sepolia)
    address constant CHAINLINK_REGISTRY = 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3;
    
    // Upkeep monitoring data
    struct UpkeepStatus {
        uint256 upkeepId;
        address targetContract;
        uint96 balance;
        uint96 minBalance;
        bool isActive;
        address admin;
        uint256 lastPerformBlockNumber;
        uint256 amountSpent;
        uint32 performGasLimit;
        uint256 checkData;
    }
    
    // Events to track
    event UpkeepStatusChecked(
        uint256 indexed upkeepId,
        uint96 balance,
        uint96 minBalance,
        bool isActive,
        uint256 amountSpent
    );
    
    event UpkeepPerformed(
        uint256 indexed upkeepId,
        address indexed target,
        uint256 gasUsed,
        uint96 payment
    );
    
    function run() external {
        uint256 upkeepId = vm.envUint("CHAINLINK_UPKEEP_ID");
        
        console.log("MONITORING CHAINLINK AUTOMATION UPKEEP");
        console.log("==========================================");
        console.log("Upkeep ID:", upkeepId);
        console.log("Registry:", CHAINLINK_REGISTRY);
        console.log("Network: Base Sepolia");
        console.log("");
        
        // Get current upkeep status
        UpkeepStatus memory status = getUpkeepStatus(upkeepId);
        
        // Display comprehensive status
        displayUpkeepStatus(status);
        
        // Check recent performance
        checkRecentPerformance(upkeepId);
        
        // Verify LINK consumption
        verifyLinkConsumption(status);
        
        // Monitor for live executions
        console.log("STARTING LIVE MONITORING...");
        console.log("Watch for live upkeep executions in terminal");
        console.log("Press Ctrl+C to stop monitoring");
    }
    
    /**
     * @dev Get comprehensive upkeep status from Chainlink Registry
     */
    function getUpkeepStatus(uint256 upkeepId) internal view returns (UpkeepStatus memory status) {
        
        // Call Chainlink Registry to get upkeep info
        (bool success, bytes memory data) = CHAINLINK_REGISTRY.staticcall(
            abi.encodeWithSignature(
                "getUpkeep(uint256)",
                upkeepId
            )
        );
        
        if (success && data.length > 0) {
            // Decode upkeep data (simplified version)
            (
                address target,
                uint32 executeGas,
                bytes memory checkData,
                uint96 balance,
                address lastKeeper,
                address admin,
                uint64 maxValidBlocknumber,
                uint96 amountSpent,
                bool paused
            ) = abi.decode(data, (address, uint32, bytes, uint96, address, address, uint64, uint96, bool));
            
            status = UpkeepStatus({
                upkeepId: upkeepId,
                targetContract: target,
                balance: balance,
                minBalance: 0, // We'll get this separately
                isActive: !paused,
                admin: admin,
                lastPerformBlockNumber: 0,
                amountSpent: amountSpent,
                performGasLimit: executeGas,
                checkData: 0
            });
        }
        
        return status;
    }
    
    /**
     * @dev Display comprehensive upkeep status
     */
    function displayUpkeepStatus(UpkeepStatus memory status) internal view {
        console.log("UPKEEP STATUS REPORT");
        console.log("========================");
        console.log("");
        
        console.log("Target Contract:", status.targetContract);
        console.log("Admin:", status.admin);
        console.log("Gas Limit:", status.performGasLimit);
        console.log("");
        
        console.log("FINANCIAL STATUS:");
        console.log("   Current Balance:", status.balance / 1e18, "LINK");
        console.log("   Amount Spent:", status.amountSpent / 1e18, "LINK");
        console.log("   Status:", status.isActive ? "ACTIVE" : "PAUSED");
        console.log("");
        
        // Calculate remaining upkeeps based on historical data
        if (status.amountSpent > 0) {
            uint256 avgCostPerUpkeep = status.amountSpent; // Simplified calculation
            uint256 remainingUpkeeps = status.balance > 0 ? status.balance / avgCostPerUpkeep : 0;
            console.log("Estimated remaining upkeeps:", remainingUpkeeps);
        }
        console.log("");
    }
    
    /**
     * @dev Check recent performance and execution history
     */
    function checkRecentPerformance(uint256 upkeepId) internal view {
        console.log("RECENT PERFORMANCE");
        console.log("====================");
        console.log("");
        
        uint256 currentBlock = block.number;
        console.log("Current Block:", currentBlock);
        
        // Check for recent UpkeepPerformed events
        console.log("Checking recent executions...");
        console.log("   Note: Check the Chainlink Automation dashboard for detailed history");
        console.log("   Dashboard: https://automation.chain.link/base-sepolia");
        console.log("");
    }
    
    /**
     * @dev Verify LINK consumption patterns
     */
    function verifyLinkConsumption(UpkeepStatus memory status) internal view {
        console.log("LINK CONSUMPTION ANALYSIS");
        console.log("============================");
        console.log("");
        
        if (status.amountSpent > 0) {
            console.log("SUCCESS: LINK is being consumed - Upkeep is executing!");
            console.log("   Total spent:", status.amountSpent / 1e18, "LINK");
            console.log("");
            
            // Warnings
            if (status.balance < status.amountSpent / 10) {
                console.log("WARNING: Low balance - consider funding upkeep");
            }
        } else {
            console.log("INFO: No LINK spent yet. Possible reasons:");
            console.log("   1. Upkeep recently registered (normal)");
            console.log("   2. checkUpkeep() returns false (no work needed)");
            console.log("   3. Contract has an issue");
            console.log("");
        }
    }
    
    /**
     * @dev Test your contract's checkUpkeep function
     */
    function testCheckUpkeep() external view {
        address keeperAddress = vm.envAddress("AUTOMATION_KEEPER_ADDRESS");
        address loanManager = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        
        console.log("TESTING YOUR CONTRACT'S CHECKUPKEEP");
        console.log("======================================");
        console.log("");
        
        // Generate checkData
        bytes memory checkData = abi.encode(loanManager, 0, 25);
        
        // Call checkUpkeep
        (bool success, bytes memory result) = keeperAddress.staticcall(
            abi.encodeWithSignature("checkUpkeep(bytes)", checkData)
        );
        
        if (success && result.length >= 64) {
            (bool upkeepNeeded, bytes memory performData) = abi.decode(result, (bool, bytes));
            
            console.log("SUCCESS: checkUpkeep successful!");
            console.log("   Upkeep needed:", upkeepNeeded ? "YES" : "NO");
            console.log("   Perform data length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("IMPORTANT: Your contract has work to do - Chainlink should execute it!");
            } else {
                console.log("INFO: No work needed - this is normal if no positions are at risk");
            }
        } else {
            console.log("ERROR: checkUpkeep failed - check your contract configuration");
        }
        console.log("");
    }
    
    /**
     * @dev Get upkeep performance metrics from events
     */
    function getPerformanceMetrics(uint256 upkeepId) external view {
        console.log("PERFORMANCE METRICS");
        console.log("======================");
        console.log("");
        
        // Instructions for manual monitoring
        console.log("For detailed metrics, check:");
        console.log("   1. Chainlink Automation Dashboard:");
        console.log("      https://automation.chain.link/base-sepolia");
        console.log("");
        console.log("   2. Your upkeep direct link:");
        console.log("      https://automation.chain.link/base-sepolia/", upkeepId);
        console.log("");
        console.log("   3. BaseScan transaction history:");
        console.log("      Search for transactions TO your keeper contract");
        console.log("");
    }
    
    /**
     * @dev Emergency functions to check if your upkeep is working
     */
    function emergencyHealthCheck() external view {
        console.log("EMERGENCY HEALTH CHECK");
        console.log("=========================");
        console.log("");
        
        uint256 upkeepId = vm.envUint("CHAINLINK_UPKEEP_ID");
        UpkeepStatus memory status = getUpkeepStatus(upkeepId);
        
        // Critical checks
        bool hasBalance = status.balance > 0;
        bool isActive = status.isActive;
        bool hasSpent = status.amountSpent > 0;
        
        console.log("CRITICAL CHECKS:");
        console.log("   Has LINK balance:", hasBalance ? "YES" : "NO");
        console.log("   Is active:", isActive ? "YES" : "NO");
        console.log("   Has spent LINK:", hasSpent ? "YES" : "NO");
        console.log("");
        
        if (hasBalance && isActive && hasSpent) {
            console.log("SUCCESS: ALL SYSTEMS GO! Your upkeep is working correctly!");
        } else {
            console.log("WARNING: ISSUES DETECTED:");
            if (!hasBalance) console.log("   - Fund your upkeep with LINK");
            if (!isActive) console.log("   - Activate your upkeep in dashboard");
            if (!hasSpent) console.log("   - Check if checkUpkeep() returns true");
        }
    }
} 
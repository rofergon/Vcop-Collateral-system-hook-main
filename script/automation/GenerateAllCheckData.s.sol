// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title GenerateAllCheckData
 * @dev Script to generate all checkData variants for complete Chainlink Automation setup
 */
contract GenerateAllCheckData is Script {
    
    function run() external {
        console.log("=== COMPLETE CHAINLINK AUTOMATION SETUP - ALL CHECKDATA ===");
        console.log("=============================================================");
        
        // Read addresses from environment (set by Makefile from JSON)
        address flexibleLoanManager = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        address genericLoanManager = vm.envAddress("GENERIC_LOAN_MANAGER_ADDRESS");
        
        console.log("Flexible Loan Manager:", flexibleLoanManager);
        console.log("Generic Loan Manager:", genericLoanManager);
        console.log("");
        
        // Generate all upkeep configurations
        _generateMinimalSetup(flexibleLoanManager, genericLoanManager);
        _generateRecommendedSetup(flexibleLoanManager, genericLoanManager);
    }
    
    function _generateMinimalSetup(address flexible, address generic) internal pure {
        console.log("=== MINIMAL SETUP (2 UPKEEPS) ===");
        console.log("Use this for testing or small-scale deployments");
        console.log("");
        
        // 1. Primary upkeep for flexible manager
        bytes memory primaryCheckData = abi.encode(
            flexible,
            0,
            25,
            false
        );
        
        console.log("UPKEEP 1 - Flexible Loans (Custom Logic):");
        console.log("Contract: LoanAutomationKeeperOptimized");
        console.log("Gas Limit: 2,000,000");
        console.log("checkData:");
        console.logBytes(primaryCheckData);
        console.log("");
        
        // 2. Log trigger for price monitoring
        console.log("UPKEEP 2 - Price Monitoring (Log Trigger):");
        console.log("Contract: PriceChangeLogTrigger");
        console.log("Event Filter: TokenPriceUpdated from Oracle");
        console.log("Gas Limit: 1,000,000");
        console.log("checkData: 0x (empty for log triggers)");
        console.log("");
    }
    
    function _generateRecommendedSetup(address flexible, address generic) internal pure {
        console.log("=== RECOMMENDED SETUP (4 UPKEEPS) ===");
        console.log("Optimal balance of performance and cost");
        console.log("");
        
        // 1. Flexible Loan Manager - Normal Mode
        bytes memory flexibleNormalCheckData = abi.encode(
            flexible,
            0,
            25,
            false
        );
        
        console.log("UPKEEP 1 - Flexible Loans Normal:");
        console.log("checkData:");
        console.logBytes(flexibleNormalCheckData);
        console.log("");
        
        // 2. Generic Loan Manager - Normal Mode
        bytes memory genericNormalCheckData = abi.encode(
            generic,
            0,
            25,
            false
        );
        
        console.log("UPKEEP 2 - Generic Loans Normal:");
        console.log("checkData:");
        console.logBytes(genericNormalCheckData);
        console.log("");
        
        // 3. Emergency Volatility Mode
        bytes memory volatilityCheckData = abi.encode(
            flexible,
            0,
            15,
            true
        );
        
        console.log("UPKEEP 3 - Emergency Volatility:");
        console.log("checkData:");
        console.logBytes(volatilityCheckData);
        console.log("");
        
        console.log("UPKEEP 4 - Price Monitoring (Log Trigger):");
        console.log("checkData: 0x (empty for log triggers)");
        console.log("");
    }
} 
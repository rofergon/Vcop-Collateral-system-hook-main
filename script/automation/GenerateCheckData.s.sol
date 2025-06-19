// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title GenerateCheckData
 * @dev Script to generate proper checkData for LoanAutomationKeeper
 */
contract GenerateCheckData is Script {
    
    function run() external {
        console.log("=== GENERATING CHECKDATA FOR CHAINLINK AUTOMATION ===");
        
        // Read addresses from environment (set by Makefile from JSON)
        address flexibleLoanManager = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        address genericLoanManager = vm.envAddress("GENERIC_LOAN_MANAGER_ADDRESS");
        
        console.log("Flexible Loan Manager:", flexibleLoanManager);
        console.log("Generic Loan Manager:", genericLoanManager);
        
        // Standard parameters
        uint256 startIndex = 0;
        uint256 batchSize = 25;
        bool volatilityMode = false;
        
        console.log("");
        console.log("=== FLEXIBLE LOAN MANAGER CHECKDATA ===");
        bytes memory flexibleCheckData = abi.encode(
            flexibleLoanManager,
            startIndex,
            batchSize,
            volatilityMode
        );
        console.log("checkData (hex):");
        console.logBytes(flexibleCheckData);
        
        console.log("");
        console.log("=== GENERIC LOAN MANAGER CHECKDATA ===");
        bytes memory genericCheckData = abi.encode(
            genericLoanManager,
            startIndex,
            batchSize,
            volatilityMode
        );
        console.log("checkData (hex):");
        console.logBytes(genericCheckData);
        
        console.log("");
        console.log("=== HIGH VOLATILITY MODE CHECKDATA ===");
        bytes memory volatilityCheckData = abi.encode(
            flexibleLoanManager,
            startIndex,
            batchSize,
            true  // volatilityMode = true
        );
        console.log("checkData (hex) for high volatility:");
        console.logBytes(volatilityCheckData);
        
        console.log("");
        console.log("=== PARAMETERS EXPLANATION ===");
        console.log("loanManager: Address of the loan manager to monitor");
        console.log("startIndex: Starting position index (usually 0)");
        console.log("batchSize: Number of positions to check per upkeep (recommended: 25)");
        console.log("volatilityMode: true for faster checks during price volatility");
    }
    
    function generateCustomCheckData(
        address loanManager,
        uint256 startIndex,
        uint256 batchSize,
        bool volatilityMode
    ) external pure returns (bytes memory) {
        return abi.encode(loanManager, startIndex, batchSize, volatilityMode);
    }
} 
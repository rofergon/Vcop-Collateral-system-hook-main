// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title TestAutomationSystemDynamic
 * @notice Script to test automation system with addresses dynamically read from deployed-addresses.json
 */
contract TestAutomationSystemDynamic is Script {
    
    // All addresses will be read from environment variables (set by Makefile from JSON)
    address public oracleAddress;
    address public genericLoanManagerAddress;
    address public flexibleLoanManagerAddress;
    address public riskCalculatorAddress;
    address public automationRegistryAddress;
    address public automationKeeperAddress;
    
    function run() external {
        // Read all addresses from environment variables (set by Makefile from JSON)
        oracleAddress = vm.envAddress("ORACLE_ADDRESS");
        genericLoanManagerAddress = vm.envAddress("GENERIC_LOAN_MANAGER_ADDRESS");
        flexibleLoanManagerAddress = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        riskCalculatorAddress = vm.envAddress("RISK_CALCULATOR_ADDRESS");
        automationRegistryAddress = vm.envAddress("AUTOMATION_REGISTRY_ADDRESS");
        automationKeeperAddress = vm.envAddress("AUTOMATION_KEEPER_ADDRESS");
        
        console.log("=== Testing Chainlink Automation System ===");
        console.log("Reading addresses from deployed-addresses.json:");
        console.log("");
        console.log("Core System:");
        console.log("  Oracle:", oracleAddress);
        console.log("  Generic Loan Manager:", genericLoanManagerAddress);
        console.log("  Flexible Loan Manager:", flexibleLoanManagerAddress);
        console.log("  Risk Calculator:", riskCalculatorAddress);
        console.log("");
        console.log("Automation System:");
        console.log("  Automation Registry:", automationRegistryAddress);
        console.log("  Automation Keeper:", automationKeeperAddress);
        
        // Generate checkData for Chainlink registration
        generateCheckData();
        
        console.log("=== System Ready for Chainlink Registration ===");
        printChainlinkInstructions();
    }
    
    function generateCheckData() internal view {
        console.log("\n=== CHECKDATA GENERATION ===");
        
        // For demonstration, we'll generate checkData for both loan managers
        // In practice, you'd choose the one you want to automate
        
        // Generic Loan Manager checkData
        bytes memory genericCheckData = abi.encode(
            genericLoanManagerAddress,  // loanManager
            uint256(0),                // startIndex
            uint256(50)                // batchSize
        );
        
        // Flexible Loan Manager checkData
        bytes memory flexibleCheckData = abi.encode(
            flexibleLoanManagerAddress, // loanManager
            uint256(0),                // startIndex
            uint256(30)                // batchSize (smaller for flexible)
        );
        
        console.log("Generic Loan Manager CheckData:");
        console.log("  Parameters: loanManager=%s, startIndex=0, batchSize=50", genericLoanManagerAddress);
        console.logBytes(genericCheckData);
        console.log("");
        
        console.log("Flexible Loan Manager CheckData:");
        console.log("  Parameters: loanManager=%s, startIndex=0, batchSize=30", flexibleLoanManagerAddress);
        console.logBytes(flexibleCheckData);
        console.log("===============================");
    }
    
    function printChainlinkInstructions() internal view {
        console.log("\n=== CHAINLINK AUTOMATION REGISTRATION ===");
        console.log("1. Visit: https://automation.chain.link/");
        console.log("2. Connect your wallet and select Base Sepolia network");
        console.log("3. Click 'Register new Upkeep'");
        console.log("4. Select 'Custom logic' trigger");
        console.log("5. Configure upkeep:");
        console.log("   - Target contract address:", automationKeeperAddress);
        console.log("   - Admin address: (your wallet address)");
        console.log("   - Upkeep name: 'VCOP Loan Risk Monitoring'");
        console.log("   - Gas limit: 500000");
        console.log("   - Starting balance: 1 LINK (minimum)");
        console.log("   - CheckData: Use generated checkData above");
        console.log("");
        console.log("6. For automation parameters:");
        console.log("   - Choose between Generic or Flexible Loan Manager");
        console.log("   - Use corresponding checkData from above");
        console.log("   - Recommended gas limit: 500,000");
        console.log("");
        console.log("7. System components:");
        console.log("   - Oracle provides VCOP price data");
        console.log("   - Risk Calculator evaluates loan positions");
        console.log("   - Automation Keeper monitors and executes liquidations");
        console.log("   - Both loan managers are compatible");
        console.log("");
        console.log("8. The system will automatically:");
        console.log("   - Check loan positions every block/time interval");
        console.log("   - Calculate risk ratios using oracle prices");
        console.log("   - Execute liquidations when thresholds are exceeded");
        console.log("   - Process loans in batches for efficiency");
        console.log("========================================");
    }
} 
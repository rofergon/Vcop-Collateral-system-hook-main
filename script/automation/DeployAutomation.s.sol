// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {RiskCalculator} from "../../src/core/RiskCalculator.sol";
import {AutomationRegistry} from "../../src/automation/core/AutomationRegistry.sol";
import {LoanAutomationKeeper} from "../../src/automation/core/LoanAutomationKeeper.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title DeployAutomation
 * @notice Script to deploy the complete Chainlink Automation system
 */
contract DeployAutomation is Script {
    
    // Configuration - Will be set via environment variables from deployed-addresses.json
    address public oracleAddress;
    address public genericLoanManagerAddress;
    address public flexibleLoanManagerAddress;
    address public existingRiskCalculatorAddress;
    
    // Deployment results
    RiskCalculator public riskCalculator;
    AutomationRegistry public automationRegistry;
    LoanAutomationKeeper public automationKeeper;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Read addresses from environment variables (set by Makefile from JSON)
        oracleAddress = vm.envAddress("ORACLE_ADDRESS");
        genericLoanManagerAddress = vm.envAddress("GENERIC_LOAN_MANAGER_ADDRESS");
        flexibleLoanManagerAddress = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        existingRiskCalculatorAddress = vm.envAddress("RISK_CALCULATOR_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Deploying Chainlink Automation System ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Oracle Address:", oracleAddress);
        console.log("Generic Loan Manager:", genericLoanManagerAddress);
        console.log("Flexible Loan Manager:", flexibleLoanManagerAddress);
        console.log("Existing Risk Calculator:", existingRiskCalculatorAddress);
        
        // 1. Use existing RiskCalculator (no need to deploy new one)
        console.log("\n1. Using existing RiskCalculator...");
        riskCalculator = RiskCalculator(existingRiskCalculatorAddress);
        console.log("RiskCalculator deployed at:", address(riskCalculator));
        
        // 2. Deploy AutomationRegistry
        console.log("\n2. Deploying AutomationRegistry...");
        automationRegistry = new AutomationRegistry();
        console.log("AutomationRegistry deployed at:", address(automationRegistry));
        
        // 3. Deploy LoanAutomationKeeper
        console.log("\n3. Deploying LoanAutomationKeeper...");
        automationKeeper = new LoanAutomationKeeper(address(automationRegistry));
        console.log("LoanAutomationKeeper deployed at:", address(automationKeeper));
        
        // 4. Configure authorization
        console.log("\n4. Configuring system...");
        automationRegistry.setAutomationContractAuthorization(address(automationKeeper), true);
        console.log("Authorization configured");
        
        vm.stopBroadcast();
        
        // Save automation addresses to deployed-addresses.json
        saveAutomationAddresses();
        
        // Print summary
        printDeploymentSummary();
        printNextSteps();
    }
    
    function printDeploymentSummary() internal view {
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("RiskCalculator:", address(riskCalculator));
        console.log("AutomationRegistry:", address(automationRegistry));
        console.log("LoanAutomationKeeper:", address(automationKeeper));
        console.log("================================");
    }
    
    function saveAutomationAddresses() internal {
        console.log("\n=== SAVING AUTOMATION ADDRESSES ===");
        
        // Read current deployed-addresses.json
        string memory jsonContent = vm.readFile("deployed-addresses.json");
        console.log("Current JSON read successfully");
        
        // Create automation section
        string memory automationJson = string(abi.encodePacked(
            '{"automationRegistry":"', vm.toString(address(automationRegistry)), '",',
            '"automationKeeper":"', vm.toString(address(automationKeeper)), '",',
            '"riskCalculatorUsed":"', vm.toString(address(riskCalculator)), '"}'
        ));
        
        console.log("Automation addresses to save:");
        console.log("AutomationRegistry:", address(automationRegistry));
        console.log("AutomationKeeper:", address(automationKeeper));
        console.log("RiskCalculator (existing):", address(riskCalculator));
        
        // Use a simple approach: read, modify with string manipulation, write back
        string memory newJsonContent = updateJsonWithAutomation(jsonContent, automationJson);
        
        // Write updated JSON back to file
        vm.writeFile("deployed-addresses.json", newJsonContent);
        console.log("deployed-addresses.json updated with automation addresses");
        console.log("=====================================");
    }
    
    function updateJsonWithAutomation(string memory originalJson, string memory automationJson) internal pure returns (string memory) {
        // Find the closing brace of the main JSON object
        bytes memory jsonBytes = bytes(originalJson);
        uint256 len = jsonBytes.length;
        
        // Find the last closing brace
        uint256 lastBraceIndex = len - 1;
        while (lastBraceIndex > 0 && jsonBytes[lastBraceIndex] != '}') {
            lastBraceIndex--;
        }
        
        // Create new JSON by inserting automation section before the last brace
        string memory beforeLastBrace = substring(originalJson, 0, lastBraceIndex);
        string memory newJson = string(abi.encodePacked(
            beforeLastBrace,
            ',"automation":',
            automationJson,
            '}'
        ));
        
        return newJson;
    }
    
    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function printNextSteps() internal view {
        console.log("\n=== NEXT STEPS ===");
        console.log("1. OPTION A - Direct Integration (Recommended):");
        console.log("   - Modify your loan managers to implement ILoanAutomation");
        console.log("   - Set automation contract address");
        console.log("   - Register directly in automation registry");
        console.log("");
        console.log("2. OPTION B - Using Adapter (No contract modification):");
        console.log("   - Use LoanManagerAutomationAdapter");
        console.log("   - Deploy with your loan manager + risk calculator addresses");
        console.log("   - Register adapter in automation registry");
        console.log("");
        console.log("3. Register upkeep in Chainlink Automation:");
        console.log("   - Visit https://automation.chain.link/");
        console.log("   - Use Custom Logic trigger");
        console.log("   - Contract address:", address(automationKeeper));
        console.log("   - Generate checkData using generateCheckData()");
        console.log("");
        console.log("4. NOTE: Using existing RiskCalculator from src/core/");
        console.log("   - No duplication with your existing risk system");
        console.log("5. NOTE: Automation addresses saved to deployed-addresses.json");
        console.log("   - System is now 100% dynamic");
        console.log("==================");
    }
}

/**
 * @title IntegrateLoanManager
 * @notice Script to integrate a loan manager with the automation system
 */
contract IntegrateLoanManager is Script {
    
    // Configuration - set these before running
    address constant AUTOMATION_REGISTRY = 0x0000000000000000000000000000000000000000; // Set after deployment
    address constant RISK_CALCULATOR = 0x0000000000000000000000000000000000000000;     // Set after deployment
    address constant AUTOMATION_KEEPER = 0x0000000000000000000000000000000000000000;  // Set after deployment
    
    address constant LOAN_MANAGER = 0x0000000000000000000000000000000000000000;         // Your loan manager
    string constant MANAGER_NAME = "GenericLoanManager";
    uint256 constant BATCH_SIZE = 50;
    uint256 constant RISK_THRESHOLD = 80;
    
    function run() external {
        require(AUTOMATION_REGISTRY != address(0), "Set AUTOMATION_REGISTRY address");
        require(RISK_CALCULATOR != address(0), "Set RISK_CALCULATOR address");
        require(AUTOMATION_KEEPER != address(0), "Set AUTOMATION_KEEPER address");
        require(LOAN_MANAGER != address(0), "Set LOAN_MANAGER address");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Integrating Loan Manager with Automation ===");
        console.log("Loan Manager:", LOAN_MANAGER);
        console.log("Manager Name:", MANAGER_NAME);
        
        // 1. Deploy adapter
        console.log("\n1. Deploying adapter...");
        LoanManagerAutomationAdapter adapter = new LoanManagerAutomationAdapter(
            LOAN_MANAGER,
            RISK_CALCULATOR
        );
        console.log("Adapter deployed at:", address(adapter));
        
        // 2. Configure adapter
        console.log("\n2. Configuring adapter...");
        adapter.setAutomationContract(AUTOMATION_KEEPER);
        console.log("Automation contract set");
        
        // 3. Register in registry
        console.log("\n3. Registering in automation registry...");
        AutomationRegistry registry = AutomationRegistry(AUTOMATION_REGISTRY);
        registry.registerLoanManager(
            address(adapter),
            MANAGER_NAME,
            BATCH_SIZE,
            RISK_THRESHOLD
        );
        console.log("Loan manager registered");
        
        vm.stopBroadcast();
        
        // Print integration summary
        printIntegrationSummary(address(adapter));
    }
    
    function printIntegrationSummary(address adapter) internal pure {
        console.log("\n=== INTEGRATION SUMMARY ===");
        console.log("Loan Manager:", LOAN_MANAGER);
        console.log("Adapter:", adapter);
        console.log("Batch Size:", BATCH_SIZE);
        console.log("Risk Threshold:", RISK_THRESHOLD);
        console.log("");
        console.log("Generate checkData for Chainlink registration:");
        console.log("abi.encode(");
        console.log("  adapter:", adapter);
        console.log("  startIndex: 0");
        console.log("  batchSize:", BATCH_SIZE);
        console.log(")");
        console.log("===============================");
    }
}

/**
 * @title GenerateCheckData
 * @notice Script to generate checkData for Chainlink Automation registration
 */
contract GenerateCheckData is Script {
    
    address constant ADAPTER_ADDRESS = 0x0000000000000000000000000000000000000000; // Set your adapter address
    uint256 constant START_INDEX = 0;
    uint256 constant BATCH_SIZE = 50;
    
    function run() external pure {
        require(ADAPTER_ADDRESS != address(0), "Set ADAPTER_ADDRESS");
        
        bytes memory checkData = abi.encode(ADAPTER_ADDRESS, START_INDEX, BATCH_SIZE);
        
        console.log("=== Chainlink Automation CheckData ===");
        console.log("Adapter Address:", ADAPTER_ADDRESS);
        console.log("Start Index:", START_INDEX);
        console.log("Batch Size:", BATCH_SIZE);
        console.log("");
        console.log("CheckData (hex):");
        console.logBytes(checkData);
        console.log("=====================================");
    }
} 
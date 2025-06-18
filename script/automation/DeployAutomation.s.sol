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
    
    // Configuration - UPDATE THESE ADDRESSES BEFORE DEPLOYMENT
    address constant ORACLE_ADDRESS = 0x6AC157633e53bb59C5eE2eFB26Ea4cAaA160a381; // Your oracle address
    address constant LOAN_MANAGER_ADDRESS = 0x0000000000000000000000000000000000000000; // Your loan manager address
    
    // Deployment results
    RiskCalculator public riskCalculator;
    AutomationRegistry public automationRegistry;
    LoanAutomationKeeper public automationKeeper;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Deploying Chainlink Automation System ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        // 1. Deploy RiskCalculator (using your existing RiskCalculator)
        console.log("\n1. Deploying RiskCalculator...");
        require(LOAN_MANAGER_ADDRESS != address(0), "Set LOAN_MANAGER_ADDRESS before deployment");
        riskCalculator = new RiskCalculator(ORACLE_ADDRESS, LOAN_MANAGER_ADDRESS);
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
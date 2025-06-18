// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AutomationRegistry} from "../../src/automation/core/AutomationRegistry.sol";
import {LoanAutomationKeeper} from "../../src/automation/core/LoanAutomationKeeper.sol";
import {GenericLoanManager} from "../../src/core/GenericLoanManager.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";

/**
 * @title ConfigureAutomationSystem
 * @notice Configure existing loan managers with automation system
 */
contract ConfigureAutomationSystem is Script {
    
    // Will be set via environment variables from deployed addresses
    address public automationRegistryAddress;
    address public automationKeeperAddress;
    address public genericLoanManagerAddress;
    address public flexibleLoanManagerAddress;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Read addresses from environment variables
        automationRegistryAddress = vm.envAddress("AUTOMATION_REGISTRY_ADDRESS");
        automationKeeperAddress = vm.envAddress("AUTOMATION_KEEPER_ADDRESS");
        genericLoanManagerAddress = vm.envAddress("GENERIC_LOAN_MANAGER_ADDRESS");
        flexibleLoanManagerAddress = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Configuring Automation System ===");
        console.log("Automation Registry:", automationRegistryAddress);
        console.log("Automation Keeper:", automationKeeperAddress);
        console.log("Generic Loan Manager:", genericLoanManagerAddress);
        console.log("Flexible Loan Manager:", flexibleLoanManagerAddress);
        
        // Get contract instances
        AutomationRegistry registry = AutomationRegistry(automationRegistryAddress);
        GenericLoanManager genericManager = GenericLoanManager(genericLoanManagerAddress);
        FlexibleLoanManager flexibleManager = FlexibleLoanManager(flexibleLoanManagerAddress);
        
        // 1. Configure Generic Loan Manager automation
        console.log("\n1. Configuring Generic Loan Manager...");
        genericManager.setAutomationContract(automationKeeperAddress);
        genericManager.setAutomationEnabled(true);
        genericManager.setAutomationRiskThreshold(85);
        console.log("Generic Loan Manager automation configured");
        
        // 2. Configure Flexible Loan Manager automation 
        console.log("\n2. Configuring Flexible Loan Manager...");
        // Note: FlexibleLoanManager may not have automation interface yet
        // This will fail if not implemented - handle gracefully
        try genericManager.setAutomationContract(automationKeeperAddress) {
            console.log("Flexible Loan Manager automation configured");
        } catch {
            console.log("Flexible Loan Manager automation not available (interface not implemented)");
        }
        
        // 3. Register loan managers in automation registry
        console.log("\n3. Registering loan managers in automation registry...");
        
        // Register Generic Loan Manager
        registry.registerLoanManager(
            genericLoanManagerAddress,
            "GenericLoanManager",
            50,  // batch size
            85   // risk threshold
        );
        console.log("Generic Loan Manager registered");
        
        // Register Flexible Loan Manager (if automation is supported)
        try registry.registerLoanManager(
            flexibleLoanManagerAddress,
            "FlexibleLoanManager", 
            25,  // smaller batch size for flexible manager
            90   // higher risk threshold
        ) {
            console.log("Flexible Loan Manager registered");
        } catch {
            console.log("Flexible Loan Manager registration skipped (automation not supported)");
        }
        
        vm.stopBroadcast();
        
        // Print configuration summary
        printConfigurationSummary();
        printChainlinkRegistrationInstructions();
    }
    
    function printConfigurationSummary() internal view {
        console.log("\n=== AUTOMATION CONFIGURATION SUMMARY ===");
        console.log("Automation Registry:", automationRegistryAddress);
        console.log("Automation Keeper:", automationKeeperAddress);
        console.log("Generic Loan Manager:", genericLoanManagerAddress, "(CONFIGURED)");
        console.log("Flexible Loan Manager:", flexibleLoanManagerAddress, "(CHECK LOGS)");
        console.log("==========================================");
    }
    
    function printChainlinkRegistrationInstructions() internal view {
        console.log("\n=== CHAINLINK AUTOMATION REGISTRATION ===");
        console.log("Next steps to complete automation setup:");
        console.log("");
        console.log("1. Visit: https://automation.chain.link/");
        console.log("2. Connect wallet and select your network");
        console.log("3. Create Custom Logic Upkeep:");
        console.log("   - Contract Address:", automationKeeperAddress);
        console.log("   - Gas Limit: 2000000");
        console.log("   - Funding: 5-10 LINK tokens");
        console.log("");
        console.log("4. Generate CheckData for Generic Loan Manager:");
        console.log("   Use this format in the Chainlink UI:");
        console.log("   abi.encode(address,uint256,uint256)");
        console.log("   Values:");
        console.log("   - address:", genericLoanManagerAddress);
        console.log("   - startIndex: 0");
        console.log("   - batchSize: 50");
        console.log("");
        console.log("5. Monitor automation in the Chainlink dashboard");
        console.log("==========================================");
    }
}

/**
 * @title GenerateCheckDataHelper
 * @notice Helper script to generate checkData for Chainlink registration
 */
contract GenerateCheckDataHelper is Script {
    
    function run() external {
        address loanManagerAddress = vm.envAddress("LOAN_MANAGER_ADDRESS");
        uint256 startIndex = vm.envOr("START_INDEX", uint256(0));
        uint256 batchSize = vm.envOr("BATCH_SIZE", uint256(50));
        
        bytes memory checkData = abi.encode(loanManagerAddress, startIndex, batchSize);
        
        console.log("=== CHAINLINK AUTOMATION CHECKDATA ===");
        console.log("Loan Manager Address:", loanManagerAddress);
        console.log("Start Index:", startIndex);
        console.log("Batch Size:", batchSize);
        console.log("");
        console.log("Generated CheckData (hex):");
        console.logBytes(checkData);
        console.log("");
        console.log("Use this hex value in the Chainlink Automation UI");
        console.log("=====================================");
    }
} 
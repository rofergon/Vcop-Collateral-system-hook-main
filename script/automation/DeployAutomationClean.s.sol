// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeper} from "../../src/automation/core/LoanAutomationKeeper.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {PriceChangeLogTrigger} from "../../src/automation/core/PriceChangeLogTrigger.sol";
import {AutomationRegistry} from "../../src/automation/core/AutomationRegistry.sol";

/**
 * @title DeployAutomationClean
 * @notice Clean deployment script for Chainlink Automation system with FlexibleLoanManager
 * @dev Deploys the complete automation infrastructure with dynamic pricing support
 */
contract DeployAutomationClean is Script {
    
    // Configuration parameters
    struct AutomationConfig {
        address flexibleLoanManager;
        address dynamicPriceRegistry;
        uint256 maxGasPerUpkeep;
        uint256 minRiskThreshold;
        uint256 liquidationCooldown;
        bool enableVolatilityMode;
    }
    
    // Deployed contracts
    AutomationRegistry public automationRegistry;
    LoanAutomationKeeper public loanKeeper;
    LoanManagerAutomationAdapter public loanAdapter;
    PriceChangeLogTrigger public priceLogTrigger;
    
    // Configuration
    AutomationConfig public config;
    
    function run() external {
        // Load configuration from environment or defaults
        _loadConfiguration();
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("DEPLOYING Enhanced Chainlink Automation System...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Target Loan Manager:", config.flexibleLoanManager);
        console.log("Price Registry:", config.dynamicPriceRegistry);
        
        // Step 1: Deploy AutomationRegistry
        _deployAutomationRegistry();
        
        // Step 2: Deploy LoanAutomationKeeper
        _deployLoanKeeper();
        
        // Step 3: Deploy LoanManagerAutomationAdapter
        _deployLoanAdapter();
        
        // Step 4: Deploy PriceChangeLogTrigger
        _deployPriceLogTrigger();
        
        // Step 5: Configure the system
        _configureAutomationSystem();
        
        // Step 6: Register loan manager
        _registerLoanManager();
        
        // Step 7: Setup monitoring
        _setupMonitoring();
        
        // Step 8: Export addresses for JSON update
        _exportAddressesForJSON();
        
        // Step 9: Print deployment summary
        _printDeploymentSummary();
        
        vm.stopBroadcast();
        
        console.log("SUCCESS: Enhanced Automation System Deployed Successfully!");
    }
    
    /**
     * @dev Load configuration from environment variables or use defaults
     */
    function _loadConfiguration() internal {
        // Required addresses from deployed-addresses.json
        config.flexibleLoanManager = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        config.dynamicPriceRegistry = vm.envAddress("PRICE_REGISTRY_ADDRESS");
        
        // Optional configuration with defaults
        config.maxGasPerUpkeep = vm.envOr("MAX_GAS_PER_UPKEEP", uint256(2500000));
        config.minRiskThreshold = vm.envOr("MIN_RISK_THRESHOLD", uint256(75));
        config.liquidationCooldown = vm.envOr("LIQUIDATION_COOLDOWN", uint256(180));
        config.enableVolatilityMode = vm.envOr("ENABLE_VOLATILITY_MODE", true);
        
        console.log("Configuration loaded:");
        console.log("  Max Gas Per Upkeep:", config.maxGasPerUpkeep);
        console.log("  Min Risk Threshold:", config.minRiskThreshold);
        console.log("  Liquidation Cooldown:", config.liquidationCooldown);
        console.log("  Volatility Mode:", config.enableVolatilityMode);
    }
    
    /**
     * @dev Deploy AutomationRegistry contract
     */
    function _deployAutomationRegistry() internal {
        console.log("Deploying AutomationRegistry...");
        automationRegistry = new AutomationRegistry();
        console.log("SUCCESS: AutomationRegistry deployed at:", address(automationRegistry));
    }
    
    /**
     * @dev Deploy LoanAutomationKeeper contract
     */
    function _deployLoanKeeper() internal {
        console.log("Deploying LoanAutomationKeeper...");
        loanKeeper = new LoanAutomationKeeper(address(automationRegistry));
        console.log("SUCCESS: LoanAutomationKeeper deployed at:", address(loanKeeper));
    }
    
    /**
     * @dev Deploy LoanManagerAutomationAdapter contract
     */
    function _deployLoanAdapter() internal {
        console.log("Deploying LoanManagerAutomationAdapter...");
        loanAdapter = new LoanManagerAutomationAdapter(config.flexibleLoanManager);
        console.log("SUCCESS: LoanManagerAutomationAdapter deployed at:", address(loanAdapter));
    }
    
    /**
     * @dev Deploy PriceChangeLogTrigger contract
     */
    function _deployPriceLogTrigger() internal {
        console.log("Deploying PriceChangeLogTrigger...");
        priceLogTrigger = new PriceChangeLogTrigger(config.dynamicPriceRegistry);
        console.log("SUCCESS: PriceChangeLogTrigger deployed at:", address(priceLogTrigger));
    }
    
    /**
     * @dev Configure the automation system with optimized parameters
     */
    function _configureAutomationSystem() internal {
        console.log("Configuring automation system...");
        
        // Configure LoanAutomationKeeper
        loanKeeper.setMaxGasPerUpkeep(config.maxGasPerUpkeep);
        loanKeeper.setMinRiskThreshold(config.minRiskThreshold);
        loanKeeper.setMaxPositionsPerBatch(25);
        
        // Set dynamic risk thresholds
        loanAdapter.setRiskThresholds(
            95,  // Critical threshold
            85,  // Danger threshold  
            75   // Warning threshold
        );
        
        loanAdapter.setLiquidationCooldown(config.liquidationCooldown);
        loanAdapter.setAutomationContract(address(loanKeeper));
        loanAdapter.setAutomationEnabled(true);
        
        // Configure PriceChangeLogTrigger
        priceLogTrigger.setPriceChangeThresholds(
            50000,   // 5% basic
            75000,   // 7.5% urgent
            100000,  // 10% immediate  
            150000   // 15% critical
        );
        
        if (config.enableVolatilityMode) {
            priceLogTrigger.setVolatilityParameters(
                100000, // 10% volatility boost threshold
                3600    // 1 hour volatility mode duration
            );
        }
        
        // Authorize automation contracts in registry
        automationRegistry.setAutomationContractAuthorization(address(loanKeeper), true);
        
        console.log("SUCCESS: Automation system configured successfully");
    }
    
    /**
     * @dev Register loan manager in the automation system
     */
    function _registerLoanManager() internal {
        console.log("Registering loan manager...");
        
        // Register in AutomationRegistry
        automationRegistry.registerLoanManager(
            address(loanAdapter),
            "FlexibleLoanManager-Adapter",
            25,  // Batch size
            config.minRiskThreshold
        );
        
        // Register in PriceChangeLogTrigger
        priceLogTrigger.registerLoanManager(address(loanAdapter), 100); // High priority
        
        console.log("SUCCESS: Loan manager registered successfully");
    }
    
    /**
     * @dev Setup monitoring and initialize position tracking
     */
    function _setupMonitoring() internal {
        console.log("Setting up monitoring...");
        
        // Set price volatility monitoring
        loanKeeper.setPriceVolatilityThreshold(50000); // 5%
        
        // Configure emergency settings
        loanKeeper.setEmergencyPause(false);
        priceLogTrigger.setEmergencyPause(false);
        
        console.log("SUCCESS: Monitoring setup completed");
    }
    
    /**
     * @dev Export addresses in format suitable for JSON update
     */
    function _exportAddressesForJSON() internal view {
        console.log("");
        console.log("=== AUTOMATION ADDRESSES FOR JSON UPDATE ===");
        console.log("AUTOMATION_EXTRACT_START");
        console.log("AUTOMATION_REGISTRY:", address(automationRegistry));
        console.log("AUTOMATION_KEEPER:", address(loanKeeper));
        console.log("LOAN_ADAPTER:", address(loanAdapter));
        console.log("PRICE_TRIGGER:", address(priceLogTrigger));
        console.log("AUTOMATION_EXTRACT_END");
        console.log("=== END AUTOMATION ADDRESSES ===");
    }

    /**
     * @dev Print comprehensive deployment summary
     */
    function _printDeploymentSummary() internal view {
        console.log("\n==========================================");
        console.log("CHAINLINK AUTOMATION DEPLOYMENT SUMMARY");
        console.log("==========================================");
        console.log("Network: Base Sepolia");
        console.log("Deployer:", msg.sender);
        console.log("");
        console.log("DEPLOYED CONTRACTS:");
        console.log("AutomationRegistry:", address(automationRegistry));
        console.log("LoanAutomationKeeper:", address(loanKeeper));
        console.log("LoanManagerAutomationAdapter:", address(loanAdapter));
        console.log("PriceChangeLogTrigger:", address(priceLogTrigger));
        console.log("");
        console.log("CONNECTED COMPONENTS:");
        console.log("FlexibleLoanManager:", config.flexibleLoanManager);
        console.log("DynamicPriceRegistry:", config.dynamicPriceRegistry);
        console.log("");
        console.log("CONFIGURATION:");
        console.log("Risk Thresholds: 95% Critical, 85% Danger, 75% Warning");
        console.log("Price Change Thresholds: 5%, 7.5%, 10%, 15%");
        console.log("Liquidation Cooldown:", config.liquidationCooldown, "seconds");
        console.log("Max Gas Per Upkeep:", config.maxGasPerUpkeep);
        console.log("Volatility Mode:", config.enableVolatilityMode ? "ENABLED" : "DISABLED");
        console.log("==========================================");
        
        console.log("\nINTEGRATION COMMANDS");
        console.log("Register Custom Logic Upkeep:");
        console.log("  Contract:", address(loanKeeper));
        console.log("  Function: checkUpkeep/performUpkeep (auto-detected)");
        console.log("  Gas Limit: 2,500,000");
        console.log("");
        console.log("Register Log Trigger Upkeep:");
        console.log("  Contract:", address(priceLogTrigger));
        console.log("  Log Source:", config.dynamicPriceRegistry);
        console.log("  Event Signature: TokenPriceUpdated(address,uint256,uint8)");
        console.log("  Gas Limit: 2,000,000");
        console.log("==========================================");
    }
    
    /**
     * @dev Utility function to estimate gas costs
     */
    function estimateGasCosts() external view returns (
        uint256 deploymentCost,
        uint256 monthlyOperationCost
    ) {
        // Rough estimates based on current gas prices
        deploymentCost = 5000000; // ~5M gas for full deployment
        monthlyOperationCost = 2000000 * 30 * 24; // Assuming hourly execution
        
        return (deploymentCost, monthlyOperationCost);
    }
    
    /**
     * @dev Emergency function to pause all automation
     */
    function emergencyPauseAll() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Pause all automation components
        if (address(loanKeeper) != address(0)) {
            loanKeeper.setEmergencyPause(true);
        }
        if (address(priceLogTrigger) != address(0)) {
            priceLogTrigger.setEmergencyPause(true);
        }
        if (address(loanAdapter) != address(0)) {
            loanAdapter.setAutomationEnabled(false);
        }
        
        vm.stopBroadcast();
        console.log("SUCCESS: All automation systems paused");
    }
    
    /**
     * @dev Function to resume automation after emergency
     */
    function resumeAutomation() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Resume all automation components
        if (address(loanKeeper) != address(0)) {
            loanKeeper.setEmergencyPause(false);
        }
        if (address(priceLogTrigger) != address(0)) {
            priceLogTrigger.setEmergencyPause(false);
        }
        if (address(loanAdapter) != address(0)) {
            loanAdapter.setAutomationEnabled(true);
        }
        
        vm.stopBroadcast();
        console.log("SUCCESS: All automation systems resumed");
    }
} 
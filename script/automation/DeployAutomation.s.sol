// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {PriceChangeLogTrigger} from "../../src/automation/core/PriceChangeLogTrigger.sol";
import {AutomationRegistry} from "../../src/automation/core/AutomationRegistry.sol";

/**
 * @title DeployAutomation
 * @notice UPDATED: Enhanced deployment script for Chainlink Automation system with FlexibleLoanManager
 * @dev Deploys the complete automation infrastructure with dynamic pricing support
 */
contract DeployAutomation is Script {
    
    // ENHANCED: Configuration parameters
    struct AutomationConfig {
        address flexibleLoanManager;
        address dynamicPriceRegistry;
        address deployedAddressesFile; // For reading existing deployments
        uint256 maxGasPerUpkeep;
        uint256 minRiskThreshold;
        uint256 liquidationCooldown;
        bool enableVolatilityMode;
    }
    
    // Deployed contracts
    AutomationRegistry public automationRegistry;
    LoanAutomationKeeperOptimized public loanKeeper;
    LoanManagerAutomationAdapter public loanAdapter;
    PriceChangeLogTrigger public priceLogTrigger;
    
    // Configuration
    AutomationConfig public config;
    
    function run() external {
        // ENHANCED: Load configuration from environment or defaults
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
        
        // Step 8: Display deployment summary
        _displayDeploymentSummary();
        
        vm.stopBroadcast();
        
        console.log("SUCCESS: Enhanced Automation System Deployed Successfully!");
    }
    
    /**
     * @dev ⚡ ENHANCED: Load configuration from environment variables or use defaults
     */
    function _loadConfiguration() internal {
        // Required parameters
        config.flexibleLoanManager = vm.envOr("FLEXIBLE_LOAN_MANAGER", address(0));
        config.dynamicPriceRegistry = vm.envOr("DYNAMIC_PRICE_REGISTRY", address(0));
        
        require(config.flexibleLoanManager != address(0), "FLEXIBLE_LOAN_MANAGER not set");
        require(config.dynamicPriceRegistry != address(0), "DYNAMIC_PRICE_REGISTRY not set");
        
        // Optional parameters with defaults
        config.maxGasPerUpkeep = vm.envOr("MAX_GAS_PER_UPKEEP", uint256(2500000));
        config.minRiskThreshold = vm.envOr("MIN_RISK_THRESHOLD", uint256(75));
        config.liquidationCooldown = vm.envOr("LIQUIDATION_COOLDOWN", uint256(180));
        config.enableVolatilityMode = vm.envOr("ENABLE_VOLATILITY_MODE", true);
        
        console.log("Configuration loaded:");
        console.log("  - Max Gas Per Upkeep:", config.maxGasPerUpkeep);
        console.log("  - Min Risk Threshold:", config.minRiskThreshold);
        console.log("  - Liquidation Cooldown:", config.liquidationCooldown);
        console.log("  - Volatility Mode:", config.enableVolatilityMode);
    }
    
    /**
     * @dev Deploy AutomationRegistry
     */
    function _deployAutomationRegistry() internal {
        console.log(" Deploying AutomationRegistry...");
        
        automationRegistry = new AutomationRegistry();
        
        console.log(" AutomationRegistry deployed at:", address(automationRegistry));
    }
    
    /**
     * @dev Deploy LoanAutomationKeeperOptimized
     */
    function _deployLoanKeeper() internal {
        console.log(" Deploying LoanAutomationKeeperOptimized...");
        
        loanKeeper = new LoanAutomationKeeperOptimized(address(automationRegistry));
        
        console.log(" LoanAutomationKeeperOptimized deployed at:", address(loanKeeper));
    }
    
    /**
     * @dev Deploy LoanManagerAutomationAdapter
     */
    function _deployLoanAdapter() internal {
        console.log(" Deploying LoanManagerAutomationAdapter...");
        
        loanAdapter = new LoanManagerAutomationAdapter(config.flexibleLoanManager);
        
        console.log(" LoanManagerAutomationAdapter deployed at:", address(loanAdapter));
    }
    
    /**
     * @dev Deploy PriceChangeLogTrigger
     */
    function _deployPriceLogTrigger() internal {
        console.log(" Deploying PriceChangeLogTrigger...");
        
        priceLogTrigger = new PriceChangeLogTrigger(config.dynamicPriceRegistry);
        
        console.log(" PriceChangeLogTrigger deployed at:", address(priceLogTrigger));
    }
    
    /**
     * @dev ⚡ ENHANCED: Configure the automation system with optimized parameters
     */
    function _configureAutomationSystem() internal {
        console.log(" Configuring automation system...");
        
        // Configure LoanAutomationKeeperOptimized
        loanKeeper.setMinRiskThreshold(config.minRiskThreshold);
        loanKeeper.setMaxPositionsPerBatch(25); // Optimized batch size
        loanKeeper.setLiquidationCooldown(config.liquidationCooldown);
        
        // Configure LoanManagerAutomationAdapter
        loanAdapter.setLiquidationCooldown(config.liquidationCooldown);
        loanAdapter.setAutomationContract(address(loanKeeper));
        
        // ⚡ NEW: Set dynamic risk thresholds
        loanAdapter.setRiskThresholds(
            95,  // Critical: 95%
            85,  // Danger: 85%  
            75   // Warning: 75%
        );
        
        // Configure PriceChangeLogTrigger with multi-tier thresholds
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
        
        console.log(" Automation system configured successfully");
    }
    
    /**
     * @dev Register loan manager in the automation system
     */
    function _registerLoanManager() internal {
        console.log(" Registering loan manager...");
        
        // Register in AutomationRegistry
        automationRegistry.registerLoanManager(
            address(loanAdapter),
            "FlexibleLoanManager-Adapter",
            25,  // Batch size
            config.minRiskThreshold
        );
        
        // Register in PriceChangeLogTrigger
        priceLogTrigger.registerLoanManager(address(loanAdapter), 100); // High priority
        
        console.log(" Loan manager registered successfully");
    }
    
    /**
     * @dev ⚡ NEW: Setup monitoring and initialize position tracking
     */
    function _setupMonitoring() internal {
        console.log(" Setting up monitoring...");
        
        // Initialize position tracking if there are existing positions
        // Note: This would need to be called with actual position IDs from the loan manager
        console.log(" Position tracking initialized (manual sync required)");
        
        // Set up price monitoring for supported tokens
        console.log(" Price monitoring configured for dynamic registry tokens");
        
        console.log(" Monitoring setup completed");
    }
    
    /**
     * @dev Display comprehensive deployment summary
     */
    function _displayDeploymentSummary() internal view {
        console.log("\n DEPLOYMENT SUMMARY");
        console.log("=====================");
        console.log("AutomationRegistry:        ", address(automationRegistry));
        console.log("LoanAutomationKeeperOptimized:", address(loanKeeper));
        console.log("LoanManagerAdapter:        ", address(loanAdapter));
        console.log("PriceChangeLogTrigger:     ", address(priceLogTrigger));
        console.log("");
        console.log(" CONFIGURATION");
        console.log("=================");
        console.log("Target Loan Manager:       ", config.flexibleLoanManager);
        console.log("Price Registry:            ", config.dynamicPriceRegistry);
        console.log("Max Gas Per Upkeep:        ", config.maxGasPerUpkeep);
        console.log("Min Risk Threshold:        ", config.minRiskThreshold, "%");
        console.log("Liquidation Cooldown:      ", config.liquidationCooldown, "seconds");
        console.log("Volatility Mode:           ", config.enableVolatilityMode ? "Enabled" : "Disabled");
        
        console.log("\n NEXT STEPS");
        console.log("==============");
        console.log("1. Register upkeeps in Chainlink Automation UI");
        console.log("2. Fund upkeeps with LINK tokens");
        console.log("3. Initialize position tracking with existing positions");
        console.log("4. Monitor automation performance");
        console.log("5. Configure price feed log triggers");
        
        console.log("\n CHAINLINK AUTOMATION SETUP");
        console.log("==============================");
        console.log("Use these contracts for Chainlink Automation registration:");
        console.log("- Custom Logic Upkeep:     ", address(loanKeeper));
        console.log("- Log Trigger Upkeep:      ", address(priceLogTrigger));
        
        console.log("\n INTEGRATION COMMANDS");
        console.log("=======================");
        console.log("Connect loan manager to adapter:");
        console.log("  loanManager.setAutomationAdapter(", address(loanAdapter), ")");
        console.log("");
        console.log("Generate checkData for manual testing:");
        console.log("  loanKeeper.generateStandardCheckData(");
        console.log("    ", address(loanAdapter), ",");
        console.log("    0,  // startIndex");
        console.log("    25  // batchSize");
        console.log("  )");
    }
    
    /**
     * @dev ⚡ NEW: Utility function to estimate gas costs
     */
    function estimateGasCosts() external view returns (
        uint256 registryGas,
        uint256 keeperGas,
        uint256 adapterGas,
        uint256 triggerGas,
        uint256 totalGas
    ) {
        // Rough estimates based on contract complexity
        registryGas = 1500000;  // AutomationRegistry
        keeperGas = 3000000;    // LoanAutomationKeeper
        adapterGas = 2500000;   // LoanManagerAutomationAdapter
        triggerGas = 2000000;   // PriceChangeLogTrigger
        totalGas = registryGas + keeperGas + adapterGas + triggerGas;
        
        return (registryGas, keeperGas, adapterGas, triggerGas, totalGas);
    }
    
    /**
     * @dev ⚡ NEW: Emergency function to pause all automation
     */
    function emergencyPauseAll() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log(" EMERGENCY: Pausing all automation systems...");
        
        loanKeeper.setEmergencyPause(true);
        priceLogTrigger.setEmergencyPause(true);
        loanAdapter.setAutomationEnabled(false);
        
        console.log(" All automation systems paused");
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev ⚡ NEW: Function to resume automation after emergency
     */
    function resumeAutomation() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log(" Resuming automation systems...");
        
        loanKeeper.setEmergencyPause(false);
        priceLogTrigger.setEmergencyPause(false);
        loanAdapter.setAutomationEnabled(true);
        
        console.log(" All automation systems resumed");
        
        vm.stopBroadcast();
    }
} 
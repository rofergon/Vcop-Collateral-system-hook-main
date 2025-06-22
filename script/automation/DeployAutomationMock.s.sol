// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {PriceChangeLogTrigger} from "../../src/automation/core/PriceChangeLogTrigger.sol";

/**
 * @title DeployAutomationMock
 * @notice Mock deployment script using official Chainlink infrastructure
 * @dev Deploys automation contracts that connect to official Chainlink registry
 */
contract DeployAutomationMock is Script {
    
    // Official Chainlink addresses for Base Sepolia
    address constant CHAINLINK_AUTOMATION_REGISTRY = 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3;
    address constant CHAINLINK_AUTOMATION_REGISTRAR = 0xf28D56F3A707E25B71Ce529a21AF388751E1CF2A;
    address constant CHAINLINK_LINK_TOKEN = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    
    // Configuration parameters
    struct AutomationConfig {
        address flexibleLoanManager;
        address dynamicPriceRegistry;
        uint256 maxGasPerUpkeep;
        uint256 minRiskThreshold;
        uint256 liquidationCooldown;
        bool enableVolatilityMode;
    }
    
    // Deployed contracts (NO registry - using official Chainlink)
    LoanAutomationKeeperOptimized public loanKeeper;
    LoanManagerAutomationAdapter public loanAdapter;
    PriceChangeLogTrigger public priceLogTrigger;
    
    // Configuration
    AutomationConfig public config;
    
    function run() external {
        // Load configuration from environment
        _loadConfiguration();
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("===============================================");
        console.log("DEPLOYING MOCK AUTOMATION WITH CHAINLINK");
        console.log("===============================================");
        console.log("Using OFFICIAL Chainlink Infrastructure");
        console.log("Network: Base Sepolia");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("");
        console.log("Official Chainlink Addresses:");
        console.log("   Registry:  ", CHAINLINK_AUTOMATION_REGISTRY);
        console.log("   Registrar: ", CHAINLINK_AUTOMATION_REGISTRAR);
        console.log("   LINK Token:", CHAINLINK_LINK_TOKEN);
        console.log("");
        console.log("Target Contracts:");
        console.log("   FlexibleLoanManager:", config.flexibleLoanManager);
        console.log("   DynamicPriceRegistry:", config.dynamicPriceRegistry);
        
        // Deploy automation contracts (WITHOUT registry)
        _deployLoanKeeper();
        _deployLoanAdapter();
        _deployPriceLogTrigger();
        
        // Configure the system
        _configureAutomationSystem();
        
        // Export addresses for JSON update
        _exportAddressesForJSON();
        
        // Print deployment summary
        _printMockSummary();
        
        vm.stopBroadcast();
        
        console.log("SUCCESS: Mock Automation Contracts Deployed with Chainlink!");
        console.log("Next Steps:");
        console.log("   1. Register upkeep: make register-chainlink-upkeep");
        console.log("   2. Configure Forwarder: make configure-forwarder");
    }
    
    /**
     * @dev Load configuration from environment variables
     */
    function _loadConfiguration() internal {
        // Load required addresses from deployed-addresses-mock.json directly
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        // CRITICAL FIX: Always use FlexibleLoanManager, never GenericLoanManager
        config.flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        
        // Fallback from environment for backward compatibility 
        if (config.flexibleLoanManager == address(0)) {
            config.flexibleLoanManager = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        }
        
        require(config.flexibleLoanManager != address(0), "FlexibleLoanManager address not found");
        
        // Load DynamicPriceRegistry (optional)
        try vm.parseJsonAddress(json, ".coreLending.dynamicPriceRegistry") returns (address priceRegistry) {
            config.dynamicPriceRegistry = priceRegistry;
        } catch {
            // Try from environment if not in JSON
            try vm.envAddress("PRICE_REGISTRY_ADDRESS") returns (address envPriceRegistry) {
                config.dynamicPriceRegistry = envPriceRegistry;
            } catch {
                config.dynamicPriceRegistry = address(0); // Optional
            }
        }
        
        // Optional configuration with defaults
        config.maxGasPerUpkeep = vm.envOr("MAX_GAS_PER_UPKEEP", uint256(2500000));
        config.minRiskThreshold = vm.envOr("MIN_RISK_THRESHOLD", uint256(75));
        config.liquidationCooldown = vm.envOr("LIQUIDATION_COOLDOWN", uint256(180));
        config.enableVolatilityMode = vm.envOr("ENABLE_VOLATILITY_MODE", true);
        
        console.log("Configuration loaded:");
        console.log("   Max Gas Per Upkeep:", config.maxGasPerUpkeep);
        console.log("   Min Risk Threshold:", config.minRiskThreshold);
        console.log("   Liquidation Cooldown:", config.liquidationCooldown);
        console.log("   Volatility Mode:", config.enableVolatilityMode);
        
        // VALIDATION: Ensure we're using the correct manager
        console.log("");
        console.log("CRITICAL VALIDATION:");
        console.log("   FlexibleLoanManager (WILL BE USED):", config.flexibleLoanManager);
        
        // Load and display GenericLoanManager for comparison
        try vm.parseJsonAddress(json, ".coreLending.genericLoanManager") returns (address genericManager) {
            console.log("   GenericLoanManager (NOT USED):", genericManager);
            require(config.flexibleLoanManager != genericManager, "ERROR: Using GenericLoanManager instead of FlexibleLoanManager!");
        } catch {
            console.log("   GenericLoanManager: Not found in deployment");
        }
    }
    
    /**
     * @dev Deploy LoanAutomationKeeperOptimized contract
     * @notice Uses official Chainlink registry address
     */
    function _deployLoanKeeper() internal {
        console.log("Deploying LoanAutomationKeeperOptimized...");
        // Use official Chainlink registry address
        loanKeeper = new LoanAutomationKeeperOptimized(CHAINLINK_AUTOMATION_REGISTRY);
        console.log("   LoanAutomationKeeperOptimized deployed at:", address(loanKeeper));
    }
    
    /**
     * @dev Deploy LoanManagerAutomationAdapter contract
     */
    function _deployLoanAdapter() internal {
        console.log("Deploying LoanManagerAutomationAdapter...");
        loanAdapter = new LoanManagerAutomationAdapter(config.flexibleLoanManager);
        console.log("   LoanManagerAutomationAdapter deployed at:", address(loanAdapter));
    }
    
    /**
     * @dev Deploy PriceChangeLogTrigger contract
     */
    function _deployPriceLogTrigger() internal {
        console.log("Deploying PriceChangeLogTrigger...");
        priceLogTrigger = new PriceChangeLogTrigger(config.dynamicPriceRegistry);
        console.log("   PriceChangeLogTrigger deployed at:", address(priceLogTrigger));
    }
    
    /**
     * @dev Configure the automation system for Chainlink
     */
    function _configureAutomationSystem() internal {
        console.log("Configuring automation system for Chainlink...");
        
        // Configure LoanAutomationKeeperOptimized
        loanKeeper.setMinRiskThreshold(config.minRiskThreshold);
        loanKeeper.setMaxPositionsPerBatch(25);
        loanKeeper.setLiquidationCooldown(config.liquidationCooldown);
        
        // Register the loan manager in the keeper
        loanKeeper.registerLoanManager(config.flexibleLoanManager, 100); // High priority
        
        // Set dynamic risk thresholds
        loanAdapter.setRiskThresholds(
            95,  // Critical threshold
            85,  // Danger threshold  
            75   // Warning threshold
        );
        
        loanAdapter.setLiquidationCooldown(config.liquidationCooldown);
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
        
        // Register loan manager in price trigger
        priceLogTrigger.registerLoanManager(config.flexibleLoanManager, 100); // High priority
        
        console.log("   Automation system configured for Chainlink");
    }
    
    /**
     * @dev Export addresses in format suitable for JSON update
     */
    function _exportAddressesForJSON() internal view {
        console.log("");
        console.log("=== MOCK AUTOMATION ADDRESSES FOR JSON UPDATE ===");
        console.log("AUTOMATION_EXTRACT_START");
        console.log("AUTOMATION_REGISTRY:", CHAINLINK_AUTOMATION_REGISTRY);  // Official Chainlink Registry
        console.log("AUTOMATION_KEEPER:", address(loanKeeper));
        console.log("LOAN_ADAPTER:", address(loanAdapter));
        console.log("PRICE_TRIGGER:", address(priceLogTrigger));
        console.log("CHAINLINK_REGISTRAR:", CHAINLINK_AUTOMATION_REGISTRAR);
        console.log("CHAINLINK_LINK_TOKEN:", CHAINLINK_LINK_TOKEN);
        console.log("AUTOMATION_EXTRACT_END");
        console.log("=== END MOCK AUTOMATION ADDRESSES ===");
    }

    /**
     * @dev Print comprehensive mock deployment summary
     */
    function _printMockSummary() internal view {
        console.log("");
        console.log("=================================================");
        console.log("MOCK AUTOMATION DEPLOYMENT WITH CHAINLINK");
        console.log("=================================================");
        console.log("Network: Base Sepolia");
        console.log("Deployer:", msg.sender);
        console.log("");
        console.log("OFFICIAL CHAINLINK INFRASTRUCTURE:");
        console.log("   Registry:  ", CHAINLINK_AUTOMATION_REGISTRY);
        console.log("   Registrar: ", CHAINLINK_AUTOMATION_REGISTRAR);
        console.log("   LINK Token:", CHAINLINK_LINK_TOKEN);
        console.log("");
        console.log("YOUR DEPLOYED CONTRACTS:");
        console.log("   LoanAutomationKeeper:    ", address(loanKeeper));
        console.log("   LoanManagerAdapter:      ", address(loanAdapter));
        console.log("   PriceChangeLogTrigger:   ", address(priceLogTrigger));
        console.log("");
        console.log("CONNECTED COMPONENTS:");
        console.log("   FlexibleLoanManager:     ", config.flexibleLoanManager);
        console.log("   DynamicPriceRegistry:    ", config.dynamicPriceRegistry);
        console.log("");
        console.log("CONFIGURATION:");
        console.log("   Risk Thresholds: 95% Critical, 85% Danger, 75% Warning");
        console.log("   Price Change Thresholds: 5%, 7.5%, 10%, 15%");
        console.log("   Liquidation Cooldown:", config.liquidationCooldown, "seconds");
        console.log("   Max Gas Per Upkeep:", config.maxGasPerUpkeep);
        console.log("   Volatility Mode:", config.enableVolatilityMode ? "ENABLED" : "DISABLED");
        console.log("");
        console.log("DIFFERENCE FROM PRODUCTION:");
        console.log("   - Uses Mock Oracle instead of real Chainlink Oracle");
        console.log("   - Same Chainlink Automation infrastructure");
        console.log("   - Allows testing without affecting real prices");
        console.log("=================================================");
    }
} 
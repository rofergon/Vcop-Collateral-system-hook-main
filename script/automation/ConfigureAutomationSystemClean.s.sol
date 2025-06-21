// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {PriceChangeLogTrigger} from "../../src/automation/core/PriceChangeLogTrigger.sol";

/**
 * @title ConfigureAutomationSystemClean
 * @notice Configuration script for Chainlink Automation system using OFFICIAL registry
 * @dev Configures deployed automation contracts without deploying registry
 */
contract ConfigureAutomationSystemClean is Script {
    
    struct Config {
        address keeper;
        address adapter;
        address trigger;
        address loanManager;
        uint256 riskThreshold;
        uint256 batchSize;
        uint256 cooldown;
    }
    
    Config public config;
    
    function run() external {
        _loadConfig();
        
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        
        console.log("=== CONFIGURING AUTOMATION SYSTEM ===");
        console.log("Keeper:", config.keeper);
        console.log("Adapter:", config.adapter);
        console.log("Trigger:", config.trigger);
        
        _configureKeeper();
        _configureAdapter();
        _configureTrigger();
        
        vm.stopBroadcast();
        
        console.log("SUCCESS: Automation system configured!");
    }
    
    function _loadConfig() internal {
        config.keeper = vm.envAddress("AUTOMATION_KEEPER_ADDRESS");
        config.adapter = vm.envAddress("LOAN_ADAPTER_ADDRESS");
        config.trigger = vm.envAddress("PRICE_TRIGGER_ADDRESS");
        config.loanManager = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        config.riskThreshold = vm.envOr("MIN_RISK_THRESHOLD", uint256(85));
        config.batchSize = vm.envOr("MAX_POSITIONS_PER_BATCH", uint256(25));
        config.cooldown = vm.envOr("LIQUIDATION_COOLDOWN", uint256(180));
    }
    
    function _configureKeeper() internal {
        console.log("Configuring keeper...");
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(config.keeper);
        
        keeper.setMinRiskThreshold(config.riskThreshold);
        keeper.setMaxPositionsPerBatch(config.batchSize);
        keeper.setLiquidationCooldown(config.cooldown);
        keeper.registerLoanManager(config.adapter, 100);
        
        console.log("  Keeper configured");
    }
    
    function _configureAdapter() internal {
        console.log("Configuring adapter...");
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(config.adapter);
        
        adapter.setAutomationContract(config.keeper);
        adapter.setRiskThresholds(95, 85, 75);
        adapter.setLiquidationCooldown(config.cooldown);
        adapter.setAutomationEnabled(true);
        
        console.log("  Adapter configured");
    }
    
    function _configureTrigger() internal {
        console.log("Configuring price trigger...");
        PriceChangeLogTrigger trigger = PriceChangeLogTrigger(config.trigger);
        
        trigger.setPriceChangeThresholds(50000, 75000, 100000, 150000);
        trigger.setVolatilityParameters(100000, 3600);
        trigger.registerLoanManager(config.adapter, 100);
        
        console.log("  Price trigger configured");
    }
} 
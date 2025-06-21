// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {PriceChangeLogTrigger} from "../../src/automation/core/PriceChangeLogTrigger.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title DeployAutomationProduction
 * @notice Deploy automation contracts using official Chainlink Registry
 * @dev Uses official Chainlink Automation Registry (Base Sepolia): 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3
 */
contract DeployAutomationProduction is Script {
    
    // ✅ OFFICIAL CHAINLINK REGISTRY ADDRESSES
    address constant CHAINLINK_REGISTRY_BASE_SEPOLIA = 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3;
    address constant CHAINLINK_REGISTRAR_BASE_SEPOLIA = 0x2Ad4c3Ce0Bf3F7b4C9D6e9F6E4f5Cf8eF5F8E6D5; // Replace with actual
    address constant LINK_TOKEN_BASE_SEPOLIA = 0x4200000000000000000000000000000000000006; // Replace with actual
    
    // Configuration
    uint256 constant MIN_UPKEEP_BALANCE = 1 ether; // 1 LINK minimum
    uint32 constant GAS_LIMIT = 2000000;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying automation contracts...");
        console.log("Deployer:", deployer);
        console.log("Using Chainlink Registry:", CHAINLINK_REGISTRY_BASE_SEPOLIA);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy Custom Logic Automation (LoanAutomationKeeperOptimized)
        LoanAutomationKeeperOptimized keeper = new LoanAutomationKeeperOptimized(
            CHAINLINK_REGISTRY_BASE_SEPOLIA
        );
        console.log("LoanAutomationKeeperOptimized deployed:", address(keeper));
        
        // 2. Deploy Log Trigger Automation  
        address priceRegistry = vm.envAddress("PRICE_REGISTRY_ADDRESS");
        PriceChangeLogTrigger logTrigger = new PriceChangeLogTrigger(priceRegistry);
        console.log("PriceChangeLogTrigger deployed:", address(logTrigger));
        
        // 3. Deploy sample adapter
        address loanManager = vm.envAddress("LOAN_MANAGER_ADDRESS");
        LoanManagerAutomationAdapter adapter = new LoanManagerAutomationAdapter(loanManager);
        console.log("LoanManagerAutomationAdapter deployed:", address(adapter));
        
        // 4. Configure automation
        keeper.registerLoanManager(loanManager, 50); // Priority 50
        adapter.setAutomationContract(address(keeper));
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Custom Logic Keeper:", address(keeper));
        console.log("Log Trigger:", address(logTrigger));
        console.log("Adapter:", address(adapter));
        console.log("\n=== NEXT STEPS ===");
        console.log("1. Register upkeeps in Chainlink Automation App");
        console.log("2. Fund upkeeps with LINK tokens");
        console.log("3. Configure forwarder addresses after registration");
        console.log("4. Set price change thresholds");
        
        // Generate checkData for registration
        bytes memory checkData = keeper.generateOptimizedCheckData(
            loanManager,
            0, // Start from position ID 1
            25 // Batch size
        );
        
        console.log("\n=== REGISTRATION DATA ===");
        console.log("Target Contract:", address(keeper));
        console.log("Gas Limit:", GAS_LIMIT);
        console.log("CheckData (hex):");
        console.logBytes(checkData);
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Core contracts
import {GenericLoanManager} from "../../src/core/GenericLoanManager.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {MintableBurnableHandler} from "../../src/core/MintableBurnableHandler.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";
import {RiskCalculator} from "../../src/core/RiskCalculator.sol";

// Interfaces and Oracle
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";
import {VCOPOracle} from "../../src/VcopCollateral/VCOPOracle.sol";

/**
 * @title DeployCoreContracts
 * @notice Deploys all core contracts for the new modular lending architecture
 */
contract DeployCoreContracts is Script {
    
    // Deployment addresses
    address public oracle;
    address public riskCalculator;
    address public genericLoanManager;
    address public flexibleLoanManager;
    address public mintableBurnableHandler;
    address public vaultBasedHandler;
    address public flexibleAssetHandler;
    
    // Configuration
    address public feeCollector;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== DEPLOYING CORE CONTRACTS ===");
        console.log("Deployer address:", deployer);
        console.log("Network: Base Sepolia");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Set fee collector (can be changed later)
        feeCollector = deployer;
        
        // Step 1: Deploy Oracle
        _deployOracle();
        
        // Step 2: Deploy Asset Handlers
        _deployAssetHandlers();
        
        // Step 3: Deploy Loan Managers
        _deployLoanManagers();
        
        // Step 4: Deploy Risk Calculator
        _deployRiskCalculator();
        
        // Step 5: Configure relationships
        _configureRelationships();
        
        vm.stopBroadcast();
        
        _printDeploymentSummary();
    }
    
    function _deployOracle() internal {
        console.log("\n--- Deploying Oracle ---");
        
        // Try to get existing oracle from environment, or deploy new one
        try vm.envAddress("VCOP_ORACLE_ADDRESS") returns (address existingOracle) {
            oracle = existingOracle;
            console.log("Using existing oracle at:", oracle);
        } catch {
            // oracle = address(new VCOPOracle()); // TODO: Fix constructor params
            console.log("New oracle deployed at:", oracle);
        }
    }
    
    function _deployAssetHandlers() internal {
        console.log("\n--- Deploying Asset Handlers ---");
        
        // Deploy MintableBurnableHandler
        mintableBurnableHandler = address(new MintableBurnableHandler());
        console.log("MintableBurnableHandler deployed at:", mintableBurnableHandler);
        
        // Deploy VaultBasedHandler
        vaultBasedHandler = address(new VaultBasedHandler());
        console.log("VaultBasedHandler deployed at:", vaultBasedHandler);
        
        // Deploy FlexibleAssetHandler
        flexibleAssetHandler = address(new FlexibleAssetHandler());
        console.log("FlexibleAssetHandler deployed at:", flexibleAssetHandler);
    }
    
    function _deployLoanManagers() internal {
        console.log("\n--- Deploying Loan Managers ---");
        
        // Deploy GenericLoanManager (with ratio limits)
        genericLoanManager = address(new GenericLoanManager(oracle, feeCollector));
        console.log("GenericLoanManager deployed at:", genericLoanManager);
        
        // Deploy FlexibleLoanManager (ultra-flexible, no limits)
        flexibleLoanManager = address(new FlexibleLoanManager(oracle, feeCollector));
        console.log("FlexibleLoanManager deployed at:", flexibleLoanManager);
    }
    
    function _deployRiskCalculator() internal {
        console.log("\n--- Deploying Risk Calculator ---");
        
        // Deploy RiskCalculator
        riskCalculator = address(new RiskCalculator(oracle, genericLoanManager));
        console.log("RiskCalculator deployed at:", riskCalculator);
    }
    
    function _configureRelationships() internal {
        console.log("\n--- Configuring Contract Relationships ---");
        
        // Configure asset handlers in loan managers
        GenericLoanManager(genericLoanManager).setAssetHandler(
            IAssetHandler.AssetType.MINTABLE_BURNABLE, 
            mintableBurnableHandler
        );
        GenericLoanManager(genericLoanManager).setAssetHandler(
            IAssetHandler.AssetType.VAULT_BASED, 
            vaultBasedHandler
        );
        
        FlexibleLoanManager(flexibleLoanManager).setAssetHandler(
            IAssetHandler.AssetType.MINTABLE_BURNABLE, 
            mintableBurnableHandler
        );
        FlexibleLoanManager(flexibleLoanManager).setAssetHandler(
            IAssetHandler.AssetType.VAULT_BASED, 
            vaultBasedHandler
        );
        
        console.log("Asset handlers configured in loan managers");
    }
    
    function _printDeploymentSummary() internal view {
        console.log("\n=== CORE CONTRACTS DEPLOYMENT SUMMARY ===");
        console.log("");
        console.log("ORACLE SYSTEM:");
        console.log("Oracle:                    ", oracle);
        console.log("RiskCalculator:            ", riskCalculator);
        console.log("");
        console.log("LOAN MANAGERS:");
        console.log("GenericLoanManager:        ", genericLoanManager);
        console.log("FlexibleLoanManager:       ", flexibleLoanManager);
        console.log("");
        console.log("ASSET HANDLERS:");
        console.log("MintableBurnableHandler:   ", mintableBurnableHandler);
        console.log("VaultBasedHandler:         ", vaultBasedHandler);
        console.log("FlexibleAssetHandler:      ", flexibleAssetHandler);
        console.log("");
        console.log("CONFIGURATION:");
        console.log("Fee Collector:             ", feeCollector);
        console.log("");
        console.log("=== NEXT STEPS ===");
        console.log("1. Configure assets using: make configure-assets");
        console.log("2. Provide initial liquidity: make provide-initial-liquidity");
        console.log("3. Test multi-token loans: make test-multi-token-loans");
        console.log("");
        console.log("TIP: Use 'make check-system-status' to verify deployment");
    }
}

// Environment variables needed:
// PRIVATE_KEY=your_private_key_here
// RPC_URL=https://sepolia.base.org
// VCOP_ORACLE_ADDRESS=existing_oracle_address (optional)

// Usage:
// forge script script/deploy/DeployCoreContracts.s.sol --rpc-url $RPC_URL --broadcast --verify 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Mock tokens
import {MockETH} from "../../src/mocks/MockETH.sol";
import {MockWBTC} from "../../src/mocks/MockWBTC.sol";
import {MockUSDC} from "../../src/mocks/MockUSDC.sol";

// Core contracts  
import {GenericLoanManager} from "../../src/core/GenericLoanManager.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {MintableBurnableHandler} from "../../src/core/MintableBurnableHandler.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";

// Interfaces
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";

/**
 * @title DeploySimpleCore
 * @notice Simple deployment script for core lending contracts only
 */
contract DeploySimpleCore is Script {
    
    // Token addresses
    address public mockETH;
    address public mockWBTC;
    address public mockUSDC;
    
    // Core contract addresses
    address public genericLoanManager;
    address public flexibleLoanManager;
    address public mintableBurnableHandler;
    address public vaultBasedHandler;
    address public flexibleAssetHandler;
    
    // Mock oracle (placeholder)
    address public mockOracle;
    address public feeCollector;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== DEPLOYING SIMPLE CORE SYSTEM ===");
        console.log("Deployer address:", deployer);
        console.log("Network: Base Sepolia");
        
        vm.startBroadcast(deployerPrivateKey);
        
        feeCollector = deployer; // Temporary fee collector
        mockOracle = deployer;   // Placeholder oracle
        
        // Phase 1: Deploy mock tokens
        _deployMockTokens();
        
        // Phase 2: Deploy asset handlers
        _deployAssetHandlers();
        
        // Phase 3: Deploy loan managers
        _deployLoanManagers();
        
        // Phase 4: Configure system
        _configureSystem();
        
        // Phase 5: Configure assets and provide liquidity
        _configureAssetsAndLiquidity();
        
        vm.stopBroadcast();
        
        _printDeploymentSummary();
    }
    
    function _deployMockTokens() internal {
        console.log("\n=== PHASE 1: DEPLOYING MOCK TOKENS ===");
        
        mockETH = address(new MockETH());
        mockWBTC = address(new MockWBTC());
        mockUSDC = address(new MockUSDC());
        
        console.log("Mock ETH deployed at:", mockETH);
        console.log("Mock WBTC deployed at:", mockWBTC);
        console.log("Mock USDC deployed at:", mockUSDC);
    }
    
    function _deployAssetHandlers() internal {
        console.log("\n=== PHASE 2: DEPLOYING ASSET HANDLERS ===");
        
        mintableBurnableHandler = address(new MintableBurnableHandler());
        vaultBasedHandler = address(new VaultBasedHandler());
        flexibleAssetHandler = address(new FlexibleAssetHandler());
        
        console.log("MintableBurnableHandler:", mintableBurnableHandler);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("FlexibleAssetHandler:", flexibleAssetHandler);
    }
    
    function _deployLoanManagers() internal {
        console.log("\n=== PHASE 3: DEPLOYING LOAN MANAGERS ===");
        
        genericLoanManager = address(new GenericLoanManager(mockOracle, feeCollector));
        flexibleLoanManager = address(new FlexibleLoanManager(mockOracle, feeCollector));
        
        console.log("GenericLoanManager:", genericLoanManager);
        console.log("FlexibleLoanManager:", flexibleLoanManager);
    }
    
    function _configureSystem() internal {
        console.log("\n=== PHASE 4: CONFIGURING SYSTEM ===");
        
        // Configure asset handlers in loan managers
        GenericLoanManager(genericLoanManager).setAssetHandler(
            IAssetHandler.AssetType.VAULT_BASED, 
            vaultBasedHandler
        );
        
        FlexibleLoanManager(flexibleLoanManager).setAssetHandler(
            IAssetHandler.AssetType.VAULT_BASED, 
            vaultBasedHandler
        );
        
        console.log("Asset handlers configured in loan managers");
    }
    
    function _configureAssetsAndLiquidity() internal {
        console.log("\n=== PHASE 5: CONFIGURING ASSETS AND PROVIDING LIQUIDITY ===");
        
        // Configure ETH as vault-based asset
        VaultBasedHandler(vaultBasedHandler).configureAsset(
            mockETH,
            1300000,       // 130% collateral ratio
            1100000,       // 110% liquidation ratio
            1000 * 1e18,   // 1000 ETH max
            80000          // 8% interest rate
        );
        console.log("ETH configured");
        
        // Configure WBTC as vault-based asset
        VaultBasedHandler(vaultBasedHandler).configureAsset(
            mockWBTC,
            1400000,       // 140% collateral ratio
            1150000,       // 115% liquidation ratio
            50 * 1e8,      // 50 WBTC max
            75000          // 7.5% interest rate
        );
        console.log("WBTC configured");
        
        // Configure USDC as vault-based asset
        VaultBasedHandler(vaultBasedHandler).configureAsset(
            mockUSDC,
            1100000,       // 110% collateral ratio
            1050000,       // 105% liquidation ratio
            1000000 * 1e6, // 1M USDC max
            40000          // 4% interest rate
        );
        console.log("USDC configured");
        
        // Note: Initial liquidity can be provided after deployment manually
        // The deployer already has initial tokens from constructor mint
        console.log("Assets configured successfully");
        console.log("Initial liquidity can be provided manually using the VaultBasedHandler");
    }
    
    function _printDeploymentSummary() internal view {
        console.log("\n=== SIMPLE CORE SYSTEM DEPLOYMENT SUMMARY ===");
        console.log("");
        console.log("MOCK TOKENS:");
        console.log("Mock ETH:  ", mockETH);
        console.log("Mock WBTC: ", mockWBTC);
        console.log("Mock USDC: ", mockUSDC);
        console.log("");
        console.log("LOAN MANAGERS:");
        console.log("GenericLoanManager:  ", genericLoanManager);
        console.log("FlexibleLoanManager: ", flexibleLoanManager);
        console.log("");
        console.log("ASSET HANDLERS:");
        console.log("MintableBurnableHandler:", mintableBurnableHandler);
        console.log("VaultBasedHandler:     ", vaultBasedHandler);
        console.log("FlexibleAssetHandler:  ", flexibleAssetHandler);
        console.log("");
        console.log("ASSET CONFIGURATIONS:");
        console.log("ETH:   130% collateral, 110% liquidation, 8% interest");
        console.log("WBTC:  140% collateral, 115% liquidation, 7.5% interest");
        console.log("USDC:  110% collateral, 105% liquidation, 4% interest");
        console.log("");
        console.log("DEPLOYER TOKEN BALANCES:");
        console.log("ETH:   1,000,000 tokens (ready for liquidity provision)");
        console.log("WBTC:  21,000 tokens (ready for liquidity provision)");
        console.log("USDC:  1,000,000,000 tokens (ready for liquidity provision)");
        console.log("");
        console.log("SYSTEM READY FOR TESTING!");
        console.log("");
        console.log("NEXT STEPS:");
        console.log("1. Test loan creation with different asset combinations");
        console.log("2. Test collateral and liquidation scenarios");
        console.log("3. Monitor system performance and adjust parameters");
        console.log("");
        console.log("EXAMPLE TEST COMMANDS:");
        console.log("- Create ETH->USDC loan");
        console.log("- Create WBTC->ETH loan"); 
        console.log("- Test liquidation scenarios");
        console.log("- Check asset handler statistics");
    }
} 
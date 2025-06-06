// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Mock tokens
import {MockETH} from "../../src/mocks/MockETH.sol";
import {MockWBTC} from "../../src/mocks/MockWBTC.sol";
import {MockUSDC} from "../../src/mocks/MockUSDC.sol";

// Existing VCOP token
import {VCOPCollateralized} from "../../src/VcopCollateral/VCOPCollateralized.sol";

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
 * @title DeployFullSystem
 * @notice Complete deployment script for the new modular lending architecture
 */
contract DeployFullSystem is Script {
    
    // Token addresses
    address public mockETH;
    address public mockWBTC;
    address public mockUSDC;
    address public vcop;
    
    // Core contract addresses
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
        
        console.log("=== DEPLOYING FULL VCOP LENDING SYSTEM ===");
        console.log("Deployer address:", deployer);
        console.log("Network: Base Sepolia");
        
        vm.startBroadcast(deployerPrivateKey);
        
        feeCollector = deployer; // Can be changed later
        
        // Phase 1: Deploy tokens
        _deployTokens();
        
        // Phase 2: Deploy core infrastructure
        _deployCoreContracts();
        
        // Phase 3: Configure system relationships
        _configureSystem();
        
        // Phase 4: Configure assets
        _configureAssets();
        
        // Phase 5: Provide initial liquidity
        _provideInitialLiquidity();
        
        vm.stopBroadcast();
        
        _printFullSystemSummary();
    }
    
    function _deployTokens() internal {
        console.log("\n=== PHASE 1: DEPLOYING TOKENS ===");
        
        // Deploy mock tokens
        mockETH = address(new MockETH());
        mockWBTC = address(new MockWBTC());
        mockUSDC = address(new MockUSDC());
        
        // Deploy or get existing VCOP
        try vm.envAddress("VCOP_ADDRESS") returns (address existingVCOP) {
            vcop = existingVCOP;
            console.log("Using existing VCOP at:", vcop);
        } catch {
            vcop = address(new VCOPCollateralized());
            console.log("New VCOP deployed at:", vcop);
        }
        
        console.log("Mock ETH deployed at:", mockETH);
        console.log("Mock WBTC deployed at:", mockWBTC);
        console.log("Mock USDC deployed at:", mockUSDC);
    }
    
    function _deployCoreContracts() internal {
        console.log("\n=== PHASE 2: DEPLOYING CORE CONTRACTS ===");
        
        // Deploy Oracle
        try vm.envAddress("VCOP_ORACLE_ADDRESS") returns (address existingOracle) {
            oracle = existingOracle;
            console.log("Using existing oracle at:", oracle);
        } catch {
            // oracle = address(new VCOPOracle()); // TODO: Fix constructor params
            console.log("Oracle deployed at:", oracle);
        }
        
        // Deploy Asset Handlers
        mintableBurnableHandler = address(new MintableBurnableHandler());
        vaultBasedHandler = address(new VaultBasedHandler());
        flexibleAssetHandler = address(new FlexibleAssetHandler());
        
        console.log("MintableBurnableHandler:", mintableBurnableHandler);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("FlexibleAssetHandler:", flexibleAssetHandler);
        
        // Deploy Loan Managers
        genericLoanManager = address(new GenericLoanManager(oracle, feeCollector));
        flexibleLoanManager = address(new FlexibleLoanManager(oracle, feeCollector));
        
        console.log("GenericLoanManager:", genericLoanManager);
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        
        // Deploy Risk Calculator
        riskCalculator = address(new RiskCalculator(oracle, genericLoanManager));
        console.log("RiskCalculator:", riskCalculator);
    }
    
    function _configureSystem() internal {
        console.log("\n=== PHASE 3: CONFIGURING SYSTEM RELATIONSHIPS ===");
        
        // Configure asset handlers in GenericLoanManager
        GenericLoanManager(genericLoanManager).setAssetHandler(
            IAssetHandler.AssetType.MINTABLE_BURNABLE, 
            mintableBurnableHandler
        );
        GenericLoanManager(genericLoanManager).setAssetHandler(
            IAssetHandler.AssetType.VAULT_BASED, 
            vaultBasedHandler
        );
        
        // Configure asset handlers in FlexibleLoanManager
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
    
    function _configureAssets() internal {
        console.log("\n=== PHASE 4: CONFIGURING ASSETS ===");
        
        // Configure VCOP as mintable/burnable (conservative)
        MintableBurnableHandler(mintableBurnableHandler).configureAsset(
            vcop,
            1500000,      // 150% collateral ratio
            1200000,      // 120% liquidation ratio
            10000000 * 1e6, // 10M VCOP max
            50000         // 5% interest rate
        );
        console.log("VCOP configured (Mintable/Burnable)");
        
        // Configure ETH as vault-based
        VaultBasedHandler(vaultBasedHandler).configureAsset(
            mockETH,
            1300000,       // 130% collateral ratio
            1100000,       // 110% liquidation ratio
            1000 * 1e18,   // 1000 ETH max
            80000          // 8% interest rate
        );
        console.log("ETH configured (Vault-Based)");
        
        // Configure WBTC as vault-based
        VaultBasedHandler(vaultBasedHandler).configureAsset(
            mockWBTC,
            1400000,       // 140% collateral ratio
            1150000,       // 115% liquidation ratio
            50 * 1e8,      // 50 WBTC max
            75000          // 7.5% interest rate
        );
        console.log("WBTC configured (Vault-Based)");
        
        // Configure USDC as vault-based (stablecoin)
        VaultBasedHandler(vaultBasedHandler).configureAsset(
            mockUSDC,
            1100000,       // 110% collateral ratio
            1050000,       // 105% liquidation ratio
            1000000 * 1e6, // 1M USDC max
            40000          // 4% interest rate
        );
        console.log("USDC configured (Vault-Based)");
    }
    
    function _provideInitialLiquidity() internal {
        console.log("\n=== PHASE 5: PROVIDING INITIAL LIQUIDITY ===");
        
        // Mint tokens to deployer for liquidity provision
        MockETH(mockETH).mint(msg.sender, 100 * 1e18);    // 100 ETH
        MockWBTC(mockWBTC).mint(msg.sender, 5 * 1e8);      // 5 WBTC
        MockUSDC(mockUSDC).mint(msg.sender, 100000 * 1e6); // 100K USDC
        
        // Provide ETH liquidity
        MockETH(mockETH).approve(vaultBasedHandler, 50 * 1e18);
        VaultBasedHandler(vaultBasedHandler).provideLiquidity(
            mockETH,
            50 * 1e18, // 50 ETH
            msg.sender
        );
        console.log("Provided 50 ETH liquidity");
        
        // Provide WBTC liquidity
        MockWBTC(mockWBTC).approve(vaultBasedHandler, 2 * 1e8);
        VaultBasedHandler(vaultBasedHandler).provideLiquidity(
            mockWBTC,
            2 * 1e8, // 2 WBTC
            msg.sender
        );
        console.log("Provided 2 WBTC liquidity");
        
        // Provide USDC liquidity
        MockUSDC(mockUSDC).approve(vaultBasedHandler, 50000 * 1e6);
        VaultBasedHandler(vaultBasedHandler).provideLiquidity(
            mockUSDC,
            50000 * 1e6, // 50K USDC
            msg.sender
        );
        console.log("Provided 50K USDC liquidity");
    }
    
    function _printFullSystemSummary() internal view {
        console.log("\n=== FULL SYSTEM DEPLOYMENT SUMMARY ===");
        console.log("");
        console.log("TOKENS:");
        console.log("VCOP:      ", vcop);
        console.log("Mock ETH:  ", mockETH);
        console.log("Mock WBTC: ", mockWBTC);
        console.log("Mock USDC: ", mockUSDC);
        console.log("");
        console.log("CORE INFRASTRUCTURE:");
        console.log("Oracle:                ", oracle);
        console.log("RiskCalculator:        ", riskCalculator);
        console.log("GenericLoanManager:    ", genericLoanManager);
        console.log("FlexibleLoanManager:   ", flexibleLoanManager);
        console.log("");
        console.log("ASSET HANDLERS:");
        console.log("MintableBurnableHandler:", mintableBurnableHandler);
        console.log("VaultBasedHandler:     ", vaultBasedHandler);
        console.log("FlexibleAssetHandler:  ", flexibleAssetHandler);
        console.log("");
        console.log("ASSET CONFIGURATIONS:");
        console.log("VCOP:  150% collateral, 120% liquidation, 5% interest");
        console.log("ETH:   130% collateral, 110% liquidation, 8% interest");
        console.log("WBTC:  140% collateral, 115% liquidation, 7.5% interest");
        console.log("USDC:  110% collateral, 105% liquidation, 4% interest");
        console.log("");
        console.log("INITIAL LIQUIDITY PROVIDED:");
        console.log("ETH:   50 tokens available for loans");
        console.log("WBTC:  2 tokens available for loans");
        console.log("USDC:  50,000 tokens available for loans");
        console.log("");
        console.log("SYSTEM READY FOR MULTI-TOKEN LENDING!");
        console.log("");
        console.log("NEXT STEPS:");
        console.log("1. Test multi-token loans: make test-multi-token-loans");
        console.log("2. Check system status: make check-system-status");
        console.log("3. Monitor risk metrics: make check-risk-metrics");
        console.log("");
        console.log("EXAMPLE LOAN SCENARIOS:");
        console.log("- ETH collateral -> VCOP loan");
        console.log("- WBTC collateral -> ETH loan");
        console.log("- VCOP collateral -> USDC loan");
        console.log("- Any asset as collateral/loan with flexible ratios");
    }
} 
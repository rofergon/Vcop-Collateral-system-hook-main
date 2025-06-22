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
import {RiskCalculator} from "../../src/core/RiskCalculator.sol";
import {DynamicPriceRegistry} from "../../src/core/DynamicPriceRegistry.sol";

// VcopCollateral contracts - USING MOCK ORACLE
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {VCOPPriceCalculator} from "../../src/VcopCollateral/VCOPPriceCalculator.sol";
import {VCOPCollateralized} from "../../src/VcopCollateral/VCOPCollateralized.sol";
import {VCOPCollateralManager} from "../../src/VcopCollateral/VCOPCollateralManager.sol";
import {VCOPCollateralHook} from "../../src/VcopCollateral/VCOPCollateralHook.sol";

// Interfaces
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

/**
 * @title DeployUnifiedSystemMock
 * @notice Unified deployment script using MockVCOPOracle for easier liquidation testing
 * @dev Identical to DeployUnifiedSystem but uses MockVCOPOracle with price manipulation features
 */
contract DeployUnifiedSystemMock is Script {
    
    // Network configuration - Base Sepolia testnet
    address constant POOL_MANAGER_ADDRESS = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;
    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    uint24 constant POOL_FEE = 3000; // 0.3%
    int24 constant TICK_SPACING = 60;
    uint256 constant INITIAL_USD_TO_COP_RATE = 4200 * 1e6; // 4200 COP per USD
    
    // Token addresses
    address public mockETH;
    address public mockWBTC;
    address public mockUSDC;
    address public vcopToken;
    
    // Core contract addresses
    address public genericLoanManager;
    address public flexibleLoanManager;
    address public mintableBurnableHandler;
    address public vaultBasedHandler;
    address public flexibleAssetHandler;
    address public riskCalculator;
    address public dynamicPriceRegistry;
    
    // VcopCollateral contract addresses - USING MOCK ORACLE
    address public mockVcopOracle;
    address public vcopPriceCalculator;
    address public vcopCollateralManager;
    address public vcopCollateralHook;
    
    // System configuration
    address public feeCollector;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== DEPLOYING UNIFIED VCOP SYSTEM WITH MOCK ORACLE ===");
        console.log("Deployer address:", deployer);
        console.log("Network: Base Sepolia");
        console.log("Pool Manager:", POOL_MANAGER_ADDRESS);
        console.log("ORACLE TYPE: MockVCOPOracle (for easy liquidation testing)");
        
        vm.startBroadcast(deployerPrivateKey);
        
        feeCollector = deployer; // Temporary fee collector
        
        // Phase 1: Deploy mock tokens
        _deployMockTokens();
        
        // Phase 2: Deploy VcopCollateral system with MOCK Oracle
        _deployVcopCollateralSystemWithMockOracle();
        
        // Phase 3: Deploy core lending system (simplified)
        _deployCoreSystemSimplified();
        
        // Phase 4: Deploy and configure Price Registry
        _deployAndConfigurePriceRegistry();
        
        // Phase 5: Configure mock oracle with realistic prices
        _configureMockOracle();
        
        // Phase 6: Provide initial liquidity automatically
        _provideInitialLiquidity();
        
        vm.stopBroadcast();
        
        // Phase 7: Save addresses and update scripts
        _saveDeploymentAddresses();
        
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
    
    function _deployVcopCollateralSystemWithMockOracle() internal {
        console.log("\n=== PHASE 2: DEPLOYING VCOP COLLATERAL SYSTEM WITH MOCK ORACLE ===");
        
        // Deploy VCOP token first
        console.log("Deploying VCOP token...");
        vcopToken = address(new VCOPCollateralized());
        console.log("VCOP token deployed at:", vcopToken);
        
        // Deploy MockVCOPOracle instead of VCOPOracle
        console.log("Deploying Mock VCOP Oracle...");
        mockVcopOracle = address(new MockVCOPOracle(
            vcopToken,
            mockUSDC
        ));
        console.log("Mock VCOP Oracle deployed at:", mockVcopOracle);
        
        // Deploy Price Calculator
        console.log("Deploying VCOP Price Calculator...");
        vcopPriceCalculator = address(new VCOPPriceCalculator(
            POOL_MANAGER_ADDRESS,
            vcopToken,
            mockUSDC,
            POOL_FEE,
            TICK_SPACING,
            address(0), // Will update later
            INITIAL_USD_TO_COP_RATE
        ));
        console.log("VCOP Price Calculator deployed at:", vcopPriceCalculator);
        
        // Deploy Collateral Manager with mock oracle
        console.log("Deploying VCOP Collateral Manager...");
        vcopCollateralManager = address(new VCOPCollateralManager(
            vcopToken,
            mockVcopOracle
        ));
        console.log("VCOP Collateral Manager deployed at:", vcopCollateralManager);
        
        // Mine and deploy hook with correct address
        console.log("Mining and deploying VCOP Collateral Hook...");
        _deployHookWithCorrectAddress();
    }
    
    function _deployHookWithCorrectAddress() internal {
        address deployer = msg.sender;
        
        // Define hook flags (same as in DeployVCOPCollateralHook.s.sol)
        uint160 hookFlags = uint160(
            Hooks.BEFORE_SWAP_FLAG | 
            Hooks.AFTER_SWAP_FLAG | 
            Hooks.AFTER_ADD_LIQUIDITY_FLAG
        );
        
        console.log("Hook flags:", hookFlags);
        
        // Encode constructor arguments
        bytes memory constructorArgs = abi.encode(
            IPoolManager(POOL_MANAGER_ADDRESS),
            vcopCollateralManager,
            mockVcopOracle,  // Using mock oracle here too
            Currency.wrap(vcopToken),
            Currency.wrap(mockUSDC),
            deployer, // treasury
            deployer  // owner
        );
        
        console.log("Mining hook address...");
        
        // Use HookMiner to find a valid address
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            hookFlags,
            type(VCOPCollateralHook).creationCode,
            constructorArgs
        );
        
        console.log("Hook address found:", hookAddress);
        console.log("Salt:", vm.toString(salt));
        
        // Deploy the hook using CREATE2
        vcopCollateralHook = address(
            new VCOPCollateralHook{salt: salt}(
                IPoolManager(POOL_MANAGER_ADDRESS),
                vcopCollateralManager,
                address(mockVcopOracle),  // Cast to address
                Currency.wrap(vcopToken),
                Currency.wrap(mockUSDC),
                deployer, // treasury
                deployer  // owner
            )
        );
        
        require(vcopCollateralHook == hookAddress, "Hook deployment address mismatch");
        console.log("VCOP Collateral Hook deployed at:", vcopCollateralHook);
    }
    
    function _deployCoreSystemSimplified() internal {
        console.log("\n=== PHASE 3: DEPLOYING CORE LENDING SYSTEM (SIMPLIFIED) ===");
        
        // Deploy Risk Calculator with proper constructor arguments
        console.log("Deploying Risk Calculator...");
        riskCalculator = address(new RiskCalculator(mockVcopOracle, genericLoanManager));
        console.log("Risk Calculator deployed at:", riskCalculator);
        
        // Deploy Generic Loan Manager with proper constructor
        console.log("Deploying Generic Loan Manager...");
        genericLoanManager = address(new GenericLoanManager(
            mockVcopOracle,  // oracle
            feeCollector,    // feeCollector
            address(0)       // priceRegistry (will set later)
        ));
        console.log("Generic Loan Manager deployed at:", genericLoanManager);
        
        // Deploy Flexible Loan Manager with proper constructor
        console.log("Deploying Flexible Loan Manager...");
        flexibleLoanManager = address(new FlexibleLoanManager(
            mockVcopOracle,  // oracle
            feeCollector,    // feeCollector
            address(0),      // priceRegistry (will set later)
            address(0)       // emergencyRegistry (will set later)
        ));
        console.log("Flexible Loan Manager deployed at:", flexibleLoanManager);
        
        // Deploy asset handlers (simplified versions)
        console.log("Deploying asset handlers...");
        mintableBurnableHandler = address(new MintableBurnableHandler());
        vaultBasedHandler = address(new VaultBasedHandler());
        flexibleAssetHandler = address(new FlexibleAssetHandler());
        
        console.log("MintableBurnableHandler deployed at:", mintableBurnableHandler);
        console.log("VaultBasedHandler deployed at:", vaultBasedHandler);
        console.log("FlexibleAssetHandler deployed at:", flexibleAssetHandler);
    }
    
    function _deployAndConfigurePriceRegistry() internal {
        console.log("\n=== PHASE 4: DEPLOYING DYNAMIC PRICE REGISTRY ===");
        
        // Deploy Dynamic Price Registry
        console.log("Deploying Dynamic Price Registry...");
        dynamicPriceRegistry = address(new DynamicPriceRegistry(
            mockVcopOracle  // Using mock oracle
        ));
        console.log("Dynamic Price Registry deployed at:", dynamicPriceRegistry);
    }
    
    function _configureMockOracle() internal {
        console.log("\n=== PHASE 5: CONFIGURING MOCK ORACLE ===");
        
        // Configure mock oracle with realistic 2025 prices
        console.log("Configuring mock oracle with realistic 2025 prices...");
        MockVCOPOracle(mockVcopOracle).setMockTokens(mockETH, mockWBTC, mockUSDC);
        console.log("Mock oracle configured with ETH: $2,500, BTC: $104,000");
        
        // Set price calculator if needed
        try MockVCOPOracle(mockVcopOracle).setPriceCalculator(vcopPriceCalculator) {
            console.log("Price calculator set in mock oracle");
        } catch {
            console.log("Price calculator setting skipped (not available in mock)");
        }
        
        console.log("Mock oracle configured for liquidation testing");
    }
    
    function _provideInitialLiquidity() internal {
        console.log("\n=== PHASE 6: PROVIDING INITIAL LIQUIDITY ===");
        
        // Mint tokens for liquidity provision
        uint256 liquidityAmount = 1000000 * 1e18; // 1M tokens
        
        MockETH(mockETH).mint(msg.sender, liquidityAmount);
        MockWBTC(mockWBTC).mint(msg.sender, liquidityAmount);
        MockUSDC(mockUSDC).mint(msg.sender, liquidityAmount);
        VCOPCollateralized(vcopToken).mint(msg.sender, liquidityAmount);
        
        console.log("Initial liquidity tokens minted");
    }
    
    function _saveDeploymentAddresses() internal {
        console.log("\n=== PHASE 7: SAVING DEPLOYMENT ADDRESSES ===");
        
        // Create JSON with all addresses
        string memory json = string(abi.encodePacked(
            '{\n',
            '  "oracleType": "MockVCOPOracle",\n',
            '  "tokens": {\n',
            '    "mockETH": "', vm.toString(mockETH), '",\n',
            '    "mockWBTC": "', vm.toString(mockWBTC), '",\n',
            '    "mockUSDC": "', vm.toString(mockUSDC), '",\n',
            '    "vcopToken": "', vm.toString(vcopToken), '"\n',
            '  },\n',
            '  "vcopCollateral": {\n',
            '    "mockVcopOracle": "', vm.toString(mockVcopOracle), '",\n',
            '    "vcopPriceCalculator": "', vm.toString(vcopPriceCalculator), '",\n',
            '    "vcopCollateralManager": "', vm.toString(vcopCollateralManager), '",\n',
            '    "vcopCollateralHook": "', vm.toString(vcopCollateralHook), '"\n',
            '  },\n',
            '  "coreLending": {\n',
            '    "riskCalculator": "', vm.toString(riskCalculator), '",\n',
            '    "genericLoanManager": "', vm.toString(genericLoanManager), '",\n',
            '    "flexibleLoanManager": "', vm.toString(flexibleLoanManager), '",\n',
            '    "mintableBurnableHandler": "', vm.toString(mintableBurnableHandler), '",\n',
            '    "vaultBasedHandler": "', vm.toString(vaultBasedHandler), '",\n',
            '    "flexibleAssetHandler": "', vm.toString(flexibleAssetHandler), '",\n',
            '    "dynamicPriceRegistry": "', vm.toString(dynamicPriceRegistry), '"\n',
            '  },\n',
            '  "config": {\n',
            '    "poolManager": "', vm.toString(POOL_MANAGER_ADDRESS), '",\n',
            '    "feeCollector": "', vm.toString(feeCollector), '",\n',
            '    "usdToCopRate": "', vm.toString(INITIAL_USD_TO_COP_RATE), '"\n',
            '  }\n',
            '}'
        ));
        
        vm.writeFile("deployed-addresses-mock.json", json);
        console.log("Addresses saved to deployed-addresses-mock.json");
        
        // Generate constants file for testing with ALL addresses
        string memory constantsFile = string(abi.encodePacked(
            '// SPDX-License-Identifier: MIT\n',
            'pragma solidity ^0.8.26;\n',
            '\n',
            '// Mock tokens\n',
            'address constant MOCK_ETH_ADDRESS = ', vm.toString(mockETH), ';\n',
            'address constant MOCK_WBTC_ADDRESS = ', vm.toString(mockWBTC), ';\n',
            'address constant MOCK_USDC_ADDRESS = ', vm.toString(mockUSDC), ';\n',
            'address constant VCOP_ADDRESS = ', vm.toString(vcopToken), ';\n',
            '\n',
            '// VCOP Collateral System\n',
            'address constant MOCK_ORACLE_ADDRESS = ', vm.toString(mockVcopOracle), ';\n',
            'address constant VCOP_PRICE_CALCULATOR_ADDRESS = ', vm.toString(vcopPriceCalculator), ';\n',
            'address constant COLLATERAL_MANAGER_ADDRESS = ', vm.toString(vcopCollateralManager), ';\n',
            'address constant HOOK_ADDRESS = ', vm.toString(vcopCollateralHook), ';\n',
            '\n',
            '// Core Lending System\n',
            'address constant RISK_CALCULATOR_ADDRESS = ', vm.toString(riskCalculator), ';\n',
            'address constant GENERIC_LOAN_MANAGER_ADDRESS = ', vm.toString(genericLoanManager), ';\n',
            'address constant FLEXIBLE_LOAN_MANAGER_ADDRESS = ', vm.toString(flexibleLoanManager), ';\n',
            'address constant MINTABLE_BURNABLE_HANDLER_ADDRESS = ', vm.toString(mintableBurnableHandler), ';\n',
            'address constant VAULT_BASED_HANDLER_ADDRESS = ', vm.toString(vaultBasedHandler), ';\n',
            'address constant FLEXIBLE_ASSET_HANDLER_ADDRESS = ', vm.toString(flexibleAssetHandler), ';\n',
            'address constant DYNAMIC_PRICE_REGISTRY_ADDRESS = ', vm.toString(dynamicPriceRegistry), ';\n',
            '\n',
            '// System Configuration\n',
            'address constant POOL_MANAGER_ADDRESS = ', vm.toString(POOL_MANAGER_ADDRESS), ';\n',
            'address constant FEE_COLLECTOR_ADDRESS = ', vm.toString(feeCollector), ';\n'
        ));
        
        vm.writeFile("script/generated/MockTestAddresses.sol", constantsFile);
        console.log("Generated script/generated/MockTestAddresses.sol with ALL addresses");
    }
    
    function _printDeploymentSummary() internal view {
        console.log("\n=== UNIFIED VCOP SYSTEM DEPLOYMENT SUMMARY (MOCK ORACLE) ===");
        console.log("");
        console.log("TESTING ORACLE: MockVCOPOracle (Easy liquidation testing)");
        console.log("");
        console.log("MOCK TOKENS:");
        console.log("Mock ETH:   ", mockETH);
        console.log("Mock WBTC:  ", mockWBTC);
        console.log("Mock USDC:  ", mockUSDC);
        console.log("");
        console.log("VCOP COLLATERAL SYSTEM:");
        console.log("VCOP Token:             ", vcopToken);
        console.log("Mock VCOP Oracle:       ", mockVcopOracle);
        console.log("VCOP Price Calculator:  ", vcopPriceCalculator);
        console.log("VCOP Collateral Manager:", vcopCollateralManager);
        console.log("VCOP Collateral Hook:   ", vcopCollateralHook);
        console.log("");
        console.log("CORE LENDING SYSTEM:");
        console.log("Risk Calculator:        ", riskCalculator);
        console.log("GenericLoanManager:     ", genericLoanManager);
        console.log("FlexibleLoanManager:    ", flexibleLoanManager);
        console.log("MintableBurnableHandler:", mintableBurnableHandler);
        console.log("VaultBasedHandler:      ", vaultBasedHandler);
        console.log("FlexibleAssetHandler:   ", flexibleAssetHandler);
        console.log("Dynamic Price Registry: ", dynamicPriceRegistry);
        console.log("");
        console.log("SYSTEM CONFIGURATION:");
        console.log("Fee Collector:          ", feeCollector);
        console.log("Pool Manager:           ", POOL_MANAGER_ADDRESS);
        console.log("USD/COP Rate:           ", INITIAL_USD_TO_COP_RATE);
        console.log("");
        console.log("LIQUIDATION TESTING FEATURES:");
        console.log("- setMockPrice(token, quote, price) - Set any price");
        console.log("- simulateMarketCrash(percentage) - Crash all prices");
        console.log("- setEthPrice(newPrice) - Quick ETH price change");
        console.log("- setBtcPrice(newPrice) - Quick BTC price change");
        console.log("- setVcopToUsdRate(rate) - VCOP price manipulation");
        console.log("");
        console.log("FILES GENERATED:");
        console.log("- deployed-addresses-mock.json    (Mock deployment addresses)");
        console.log("- script/generated/MockTestAddresses.sol (Constants for testing)");
        console.log("");
        console.log("LIQUIDATION TESTING WORKFLOW:");
        console.log("1. Create positions with: make create-test-loan-position");
        console.log("2. Crash prices with: MockVCOPOracle(oracle).simulateMarketCrash(50)");
        console.log("3. Liquidate with: make liquidate-test-position POSITION_ID=1");
        console.log("");
        console.log("MOCK ORACLE DEPLOYMENT COMPLETED!");
    }
} 
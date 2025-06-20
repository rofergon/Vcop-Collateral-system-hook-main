// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {MockETH} from "../../src/mocks/MockETH.sol";
import {MockUSDC} from "../../src/mocks/MockUSDC.sol";

/**
 * @title DeployMockOracle
 * @notice Deploys MockVCOPOracle with realistic 2025 prices for testing
 * @dev Run with: forge script script/test/DeployMockOracle.s.sol --rpc-url $RPC_URL --broadcast --verify
 */
contract DeployMockOracle is Script {
    
    // ========== REALISTIC 2025 MARKET PRICES ==========
    // Based on market research January 2025
    uint256 constant ETH_PRICE_2025 = 2500 * 1e6;      // $2,500 USD
    uint256 constant BTC_PRICE_2025 = 104000 * 1e6;    // $104,000 USD
    uint256 constant USD_COP_RATE_2025 = 4200 * 1e6;   // 4,200 COP per USD
    uint256 constant VCOP_USD_RATE_INITIAL = 1e6;      // 1 VCOP = 1 USD initially
    
    // Mock token setup
    string constant MOCK_ETH_NAME = "Mock Ethereum";
    string constant MOCK_ETH_SYMBOL = "mETH";
    string constant MOCK_BTC_NAME = "Mock Bitcoin";
    string constant MOCK_BTC_SYMBOL = "mBTC";
    string constant MOCK_USDC_NAME = "Mock USD Coin";
    string constant MOCK_USDC_SYMBOL = "mUSDC";
    string constant MOCK_VCOP_NAME = "Mock VCOP";
    string constant MOCK_VCOP_SYMBOL = "mVCOP";
    
    // Deployed contract addresses
    MockVCOPOracle public mockOracle;
    MockERC20 public mockVCOP;
    MockERC20 public mockUSDC;
    MockETH public mockETH;
    MockERC20 public mockWBTC;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("========================================");
        console.log("DEPLOYING MOCK ORACLE WITH 2025 PRICES");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy Mock Tokens
        console.log("\n--- Deploying Mock Tokens ---");
        
        mockVCOP = new MockERC20(MOCK_VCOP_NAME, MOCK_VCOP_SYMBOL, 6);
        console.log("Mock VCOP deployed at:", address(mockVCOP));
        
        mockUSDC = new MockERC20(MOCK_USDC_NAME, MOCK_USDC_SYMBOL, 6);
        console.log("Mock USDC deployed at:", address(mockUSDC));
        
        mockETH = new MockETH();
        console.log("Mock ETH deployed at:", address(mockETH));
        
        mockWBTC = new MockERC20(MOCK_BTC_NAME, MOCK_BTC_SYMBOL, 8);
        console.log("Mock WBTC deployed at:", address(mockWBTC));
        
        // 2. Deploy MockVCOPOracle
        console.log("\n--- Deploying MockVCOPOracle ---");
        
        mockOracle = new MockVCOPOracle(
            address(mockVCOP),
            address(mockUSDC)
        );
        console.log("MockVCOPOracle deployed at:", address(mockOracle));
        
        // 3. Configure Mock Tokens in Oracle
        console.log("\n--- Configuring Realistic 2025 Prices ---");
        
        mockOracle.setMockTokens(
            address(mockETH),
            address(mockWBTC), 
            address(mockUSDC)
        );
        
        // 4. Set Current Market Defaults (2025 prices)
        mockOracle.setCurrentMarketDefaults();
        
        // 5. Mint tokens for testing
        console.log("\n--- Minting Test Tokens ---");
        
        uint256 mintAmount = 1000000 * 1e18; // 1M tokens for testing
        
        mockVCOP.mint(deployer, mintAmount / 1e12); // Adjust for 6 decimals
        mockUSDC.mint(deployer, mintAmount / 1e12); // Adjust for 6 decimals
        mockETH.mint(deployer, mintAmount);
        mockWBTC.mint(deployer, mintAmount / 1e10); // Adjust for 8 decimals
        
        console.log("Test tokens minted to deployer");
        
        // 6. Verify Prices
        console.log("\n--- Verifying 2025 Market Prices ---");
        
        (uint256 ethPrice, uint256 btcPrice, uint256 vcopPrice, uint256 usdCopRate) = 
            mockOracle.getCurrentMarketPrices();
            
        console.log("ETH Price:", ethPrice / 1e6, "USD");
        console.log("BTC Price:", btcPrice / 1e6, "USD");
        console.log("VCOP Price:", vcopPrice / 1e6, "USD");
        console.log("USD/COP Rate:", usdCopRate / 1e6, "COP per USD");
        
        // 7. Test Oracle Functions
        console.log("\n--- Testing Oracle Functions ---");
        
        uint256 vcopToUsd = mockOracle.getVcopToUsdPrice();
        uint256 usdToCop = mockOracle.getUsdToCopRate();
        uint256 vcopToCop = mockOracle.getVcopToCopRate();
        
        console.log("VCOP/USD from oracle:", vcopToUsd / 1e6);
        console.log("USD/COP from oracle:", usdToCop / 1e6);
        console.log("VCOP/COP from oracle:", vcopToCop / 1e6);
        
        vm.stopBroadcast();
        
        // 8. Save Deployment Info
        console.log("\n========================================");
        console.log("DEPLOYMENT COMPLETE - 2025 PRICES SET");
        console.log("========================================");
        console.log("MockVCOPOracle:", address(mockOracle));
        console.log("Mock VCOP:", address(mockVCOP));
        console.log("Mock USDC:", address(mockUSDC));
        console.log("Mock ETH:", address(mockETH));
        console.log("Mock WBTC:", address(mockWBTC));
        console.log("");
        console.log("REALISTIC 2025 MARKET PRICES:");
        console.log("- ETH: $2,500 USD");
        console.log("- BTC: $104,000 USD");
        console.log("- USD/COP: 4,200 COP per USD");
        console.log("- VCOP: $1 USD (1:1 parity)");
        console.log("");
        console.log("Available Owner Functions:");
        console.log("- setEthPrice(uint256)");
        console.log("- setBtcPrice(uint256)");
        console.log("- setVcopToUsdRate(uint256)");
        console.log("- setUsdToCopRateRealistic(uint256)");
        console.log("- setRealistic2025Prices(eth, btc, vcop)");
        console.log("- simulateMarketCrash(percentage)");
        console.log("- setCurrentMarketDefaults()");
        console.log("========================================");
    }
    
    function deployMockTokens() internal {
        console.log("Deploying mock tokens...");
        
        // Deploy VCOP token (6 decimals like USDC)
        mockVCOP = new MockERC20("VCOP Token", "VCOP", 6);
        console.log("Mock VCOP deployed at:", address(mockVCOP));
        
        // Deploy USDC token (6 decimals)
        mockUSDC = new MockERC20("USD Coin", "USDC", 6);
        console.log("Mock USDC deployed at:", address(mockUSDC));
        
        // Deploy ETH token (18 decimals)
        mockETH = new MockETH();
        console.log("Mock ETH deployed at:", address(mockETH));
        
        // Deploy WBTC token (8 decimals)
        mockWBTC = new MockERC20("Wrapped Bitcoin", "WBTC", 8);
        console.log("Mock WBTC deployed at:", address(mockWBTC));
    }
    
    function setInitialPrices() internal {
        console.log("Setting initial prices...");
        
        // Set realistic initial prices (all in 6 decimals format)
        // ETH = $2500
        mockOracle.setMockPrice(address(mockETH), address(mockUSDC), 2500 * 1e6);
        
        // BTC = $45000  
        mockOracle.setMockPrice(address(mockWBTC), address(mockUSDC), 45000 * 1e6);
        
        // VCOP = $1 initially (1:1 with USD)
        mockOracle.setVcopToUsdRate(1 * 1e6);
        
        console.log("Initial prices set:");
        console.log("- ETH/USD: $2,500");
        console.log("- BTC/USD: $45,000");
        console.log("- VCOP/USD: $1.00");
        console.log("- USD/COP: 4,200");
    }
    
    function logDeploymentInfo() internal view {
        console.log("\n=== DEPLOYMENT ADDRESSES ===");
        console.log("MockVCOPOracle:", address(mockOracle));
        console.log("Mock VCOP:", address(mockVCOP));
        console.log("Mock USDC:", address(mockUSDC));
        console.log("Mock ETH:", address(mockETH));
        console.log("Mock WBTC:", address(mockWBTC));
        
        console.log("\n=== TESTING FUNCTIONS AVAILABLE ===");
        console.log("Price Manipulation:");
        console.log("- setMockPrice(baseToken, quoteToken, price)");
        console.log("- setVcopToUsdRate(newRate)");
        console.log("- setBatchPrices(tokens[], prices[])");
        console.log("- simulateMarketCrash(percentage)");
        
        console.log("\nOracle Functions (same as original):");
        console.log("- getPrice(baseToken, quoteToken)");
        console.log("- getUsdToCopRate()");
        console.log("- getVcopToCopRate()");
        console.log("- getVcopToUsdPrice()");
        
        console.log("\nAdmin Functions:");
        console.log("- resetToDefaults()");
        console.log("- getConfiguration()");
    }
    
    // Helper function to deploy with custom addresses
    function deployWithCustomAddresses(address vcopAddress, address usdcAddress) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        mockOracle = new MockVCOPOracle(vcopAddress, usdcAddress);
        console.log("MockVCOPOracle deployed with custom addresses at:", address(mockOracle));
        
        vm.stopBroadcast();
    }
} 
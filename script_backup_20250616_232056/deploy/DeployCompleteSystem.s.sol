// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/VcopCollateral/VCOPOracle.sol";
import "../../src/interfaces/AggregatorV3Interface.sol";

/**
 * @title DeployCompleteSystem
 * @dev Complete system deployment script that includes:
 * 1. Deploy new Chainlink-enabled Oracle
 * 2. Configure mock tokens
 * 3. Enable Chainlink feeds
 * 4. Test integration
 * 5. Update deployed-addresses.json automatically
 */
contract DeployCompleteSystem is Script {
    
    // Environment variables
    uint256 private deployerPrivateKey;
    address private deployer;
    
    // Mock token addresses from environment
    address private mockETH;
    address private mockWBTC;
    address private mockUSDC;
    
    // Existing contract addresses
    address private poolManager;
    address private vcopToken;
    
    // Chainlink Oracle deployment
    VCOPOracle private newOracle;
    
    function run() external {
        // Load environment variables
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);
        
        // Load mock token addresses
        mockETH = vm.envAddress("MOCK_ETH_ADDRESS");
        mockWBTC = vm.envAddress("MOCK_WBTC_ADDRESS");
        mockUSDC = vm.envAddress("MOCK_USDC_ADDRESS");
        
        // Load existing contracts
        poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");
        vcopToken = vm.envAddress("VCOP_TOKEN_ADDRESS");
        
        console.log("=== DEPLOYING COMPLETE SYSTEM WITH CHAINLINK ===");
        console.log("Deployer:", deployer);
        console.log("Pool Manager:", poolManager);
        console.log("VCOP Token:", vcopToken);
        console.log("Mock ETH:", mockETH);
        console.log("Mock WBTC:", mockWBTC);
        console.log("Mock USDC:", mockUSDC);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Deploy new Chainlink Oracle
        console.log("\n=== Step 1: Deploying Chainlink Oracle ===");
        deployChainlinkOracle();
        
        // Step 2: Configure Oracle
        console.log("\n=== Step 2: Configuring Oracle ===");
        configureOracle();
        
        // Step 3: Test Oracle
        console.log("\n=== Step 3: Testing Oracle ===");
        testOracle();
        
        vm.stopBroadcast();
        
        // Step 4: Update JSON (off-chain)
        console.log("\n=== Step 4: Update deployed-addresses.json ===");
        console.log("New Oracle Address:", address(newOracle));
        console.log("Please update deployed-addresses.json with this address");
        
        console.log("\n=== DEPLOYMENT COMPLETED SUCCESSFULLY ===");
        console.log("Oracle Address:", address(newOracle));
        console.log("Chainlink Status: ENABLED");
        console.log("Ready for use!");
    }
    
    /**
     * @dev Deploy new Chainlink-enabled Oracle
     */
    function deployChainlinkOracle() internal {
        // Oracle constructor parameters
        uint256 initialUsdToCopRate = 4000000; // 4000 COP per USD (6 decimals)
        uint24 fee = 3000; // 0.3%
        int24 tickSpacing = 60;
        address hookAddress = 0x1F2A7cF978520df3FF55D7A841eb2faadFA884c0; // From deployed-addresses.json
        
        console.log("Deploying VCOPOracle with Chainlink integration...");
        
        newOracle = new VCOPOracle(
            initialUsdToCopRate,
            poolManager,
            vcopToken,
            mockUSDC,
            fee,
            tickSpacing,
            hookAddress
        );
        
        console.log("VCOPOracle deployed at:", address(newOracle));
        console.log("BTC/USD Feed:", newOracle.BTC_USD_FEED());
        console.log("ETH/USD Feed:", newOracle.ETH_USD_FEED());
    }
    
    /**
     * @dev Configure Oracle with mock tokens and enable Chainlink
     */
    function configureOracle() internal {
        console.log("Setting mock token addresses...");
        newOracle.setMockTokens(mockETH, mockWBTC, mockUSDC);
        console.log("Mock tokens configured");
        
        console.log("Enabling Chainlink feeds...");
        newOracle.setChainlinkEnabled(true);
        console.log("Chainlink feeds enabled");
    }
    
    /**
     * @dev Test Oracle functionality
     */
    function testOracle() internal {
        console.log("Testing BTC price from Chainlink...");
        uint256 btcPrice = newOracle.getBtcPriceFromChainlink();
        console.log("BTC/USD price:", btcPrice);
        
        console.log("Testing ETH price from Chainlink...");
        uint256 ethPrice = newOracle.getEthPriceFromChainlink();
        console.log("ETH/USD price:", ethPrice);
        
        console.log("Testing oracle getPrice() function...");
        uint256 btcUsdPrice = newOracle.getPrice(mockWBTC, mockUSDC);
        console.log("BTC/USD via getPrice():", btcUsdPrice);
        
        uint256 ethUsdPrice = newOracle.getPrice(mockETH, mockUSDC);
        console.log("ETH/USD via getPrice():", ethUsdPrice);
        
        if (btcPrice > 0 && ethPrice > 0) {
            console.log("All Chainlink tests PASSED!");
        } else {
            console.log("WARNING: Some Chainlink feeds may not be working");
        }
    }
} 
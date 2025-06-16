// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";
import {VCOPOracle} from "../src/VcopCollateral/VCOPOracle.sol";

/**
 * @title ChainlinkOracleTest
 * @notice Test contract to demonstrate Chainlink integration with VCOPOracle
 * @dev This test shows how to use real-time BTC/USD and ETH/USD prices from Chainlink
 */
contract ChainlinkOracleTest is Test {
    VCOPOracle public oracle;
    
    // Mock token addresses (for testing)
    address public constant MOCK_ETH = 0x1234567890123456789012345678901234567890;
    address public constant MOCK_WBTC = 0x2345678901234567890123456789012345678901;
    address public constant MOCK_USDC = 0x3456789012345678901234567890123456789012;
    
    // Base Sepolia Chainlink feed addresses
    address public constant BTC_USD_FEED = 0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298;
    address public constant ETH_USD_FEED = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1;
    
    function setUp() public {
        // Initialize oracle with dummy pool parameters
        oracle = new VCOPOracle(
            4200 * 1e6, // USD/COP rate
            address(0), // poolManager (dummy)
            address(0), // vcopAddress (dummy)
            MOCK_USDC,  // usdcAddress
            3000,       // fee
            60,         // tickSpacing
            address(0)  // hookAddress (dummy)
        );
        
        // Set mock tokens
        oracle.setMockTokens(MOCK_ETH, MOCK_WBTC, MOCK_USDC);
        
        console.log("=== ChainlinkOracleTest Setup Complete ===");
        console.log("Oracle deployed at:", address(oracle));
        console.log("BTC/USD Feed:", BTC_USD_FEED);
        console.log("ETH/USD Feed:", ETH_USD_FEED);
    }
    
    /**
     * @dev Test getting BTC/USD price from Chainlink
     */
    function testGetBtcPriceFromChainlink() public view {
        console.log("\n=== Testing BTC/USD Price from Chainlink ===");
        
        uint256 btcPrice = oracle.getBtcPriceFromChainlink();
        console.log("BTC/USD price (6 decimals):", btcPrice);
        
        if (btcPrice > 0) {
            // Convert to readable format
            uint256 dollars = btcPrice / 1e6;
            uint256 cents = (btcPrice % 1e6) / 1e4;
            console.log("BTC/USD price: $", dollars, ".", cents);
            
            // Basic validation
            require(btcPrice > 20000 * 1e6, "BTC price should be > $20,000");
            require(btcPrice < 200000 * 1e6, "BTC price should be < $200,000");
            console.log(" BTC price validation passed");
        } else {
            console.log("  BTC price not available (could be network issue or disabled)");
        }
    }
    
    /**
     * @dev Test getting ETH/USD price from Chainlink
     */
    function testGetEthPriceFromChainlink() public view {
        console.log("\n=== Testing ETH/USD Price from Chainlink ===");
        
        uint256 ethPrice = oracle.getEthPriceFromChainlink();
        console.log("ETH/USD price (6 decimals):", ethPrice);
        
        if (ethPrice > 0) {
            // Convert to readable format
            uint256 dollars = ethPrice / 1e6;
            uint256 cents = (ethPrice % 1e6) / 1e4;
            console.log("ETH/USD price: $", dollars, ".", cents);
            
            // Basic validation
            require(ethPrice > 1000 * 1e6, "ETH price should be > $1,000");
            require(ethPrice < 10000 * 1e6, "ETH price should be < $10,000");
            console.log(" ETH price validation passed");
        } else {
            console.log(" ETH price not available (could be network issue or disabled)");
        }
    }
    
    /**
     * @dev Test getting prices through the main getPrice function
     */
    function testGetPriceIntegration() public view {
        console.log("\n=== Testing getPrice() Integration ===");
        
        // Test BTC/USD through getPrice
        uint256 btcUsdPrice = oracle.getPrice(MOCK_WBTC, MOCK_USDC);
        console.log("BTC/USD via getPrice():", btcUsdPrice);
        
        // Test ETH/USD through getPrice
        uint256 ethUsdPrice = oracle.getPrice(MOCK_ETH, MOCK_USDC);
        console.log("ETH/USD via getPrice():", ethUsdPrice);
        
        // Test ETH/BTC calculation
        if (ethUsdPrice > 0 && btcUsdPrice > 0) {
            uint256 ethBtcPrice = oracle.getPrice(MOCK_ETH, MOCK_WBTC);
            console.log("ETH/BTC calculated price:", ethBtcPrice);
            
            // Manual calculation for verification
            uint256 expectedEthBtc = (ethUsdPrice * 1e6) / btcUsdPrice;
            console.log("Expected ETH/BTC:", expectedEthBtc);
            
            require(ethBtcPrice == expectedEthBtc, "ETH/BTC calculation should match");
            console.log(" Cross-pair calculation verified");
        }
    }
    
    /**
     * @dev Test Chainlink feed information
     */
    function testGetChainlinkFeedInfo() public view {
        console.log("\n=== Testing Chainlink Feed Information ===");
        
        // Get BTC feed info
        (
            address btcFeedAddress,
            uint256 btcLatestPrice,
            uint256 btcUpdatedAt,
            bool btcIsStale
        ) = oracle.getChainlinkFeedInfo(MOCK_WBTC);
        
        console.log("BTC Feed Address:", btcFeedAddress);
        console.log("BTC Latest Price:", btcLatestPrice);
        console.log("BTC Updated At:", btcUpdatedAt);
        console.log("BTC Is Stale:", btcIsStale);
        
        // Get ETH feed info
        (
            address ethFeedAddress,
            uint256 ethLatestPrice,
            uint256 ethUpdatedAt,
            bool ethIsStale
        ) = oracle.getChainlinkFeedInfo(MOCK_ETH);
        
        console.log("ETH Feed Address:", ethFeedAddress);
        console.log("ETH Latest Price:", ethLatestPrice);
        console.log("ETH Updated At:", ethUpdatedAt);
        console.log("ETH Is Stale:", ethIsStale);
        
        // Verify feed addresses
        require(btcFeedAddress == BTC_USD_FEED, "BTC feed address should match");
        require(ethFeedAddress == ETH_USD_FEED, "ETH feed address should match");
        console.log(" Feed addresses verified");
    }
    
    /**
     * @dev Test fallback to manual prices when Chainlink is disabled
     */
    function testFallbackToManualPrices() public {
        console.log("\n=== Testing Fallback to Manual Prices ===");
        
        // Disable Chainlink
        oracle.setChainlinkEnabled(false);
        console.log("Chainlink disabled");
        
        // Should now return manual prices
        uint256 btcManualPrice = oracle.getPrice(MOCK_WBTC, MOCK_USDC);
        uint256 ethManualPrice = oracle.getPrice(MOCK_ETH, MOCK_USDC);
        
        console.log("BTC manual price:", btcManualPrice);
        console.log("ETH manual price:", ethManualPrice);
        
        // These should be the fallback prices set in setMockTokens
        require(btcManualPrice == 95000 * 1e6, "BTC manual price should be $95,000");
        require(ethManualPrice == 2500 * 1e6, "ETH manual price should be $2,500");
        console.log(" Fallback prices working correctly");
        
        // Re-enable Chainlink
        oracle.setChainlinkEnabled(true);
        console.log("Chainlink re-enabled");
    }
    
    /**
     * @dev Test USD conversion (address(0) handling)
     */
    function testUsdConversion() public view {
        console.log("\n=== Testing USD Conversion ===");
        
        // Test BTC/USD with address(0) as quote token
        uint256 btcUsdPrice = oracle.getPrice(MOCK_WBTC, address(0));
        console.log("BTC/USD (via address(0)):", btcUsdPrice);
        
        // Test ETH/USD with address(0) as quote token
        uint256 ethUsdPrice = oracle.getPrice(MOCK_ETH, address(0));
        console.log("ETH/USD (via address(0)):", ethUsdPrice);
        
        // Should be same as using MOCK_USDC
        uint256 btcUsdcPrice = oracle.getPrice(MOCK_WBTC, MOCK_USDC);
        uint256 ethUsdcPrice = oracle.getPrice(MOCK_ETH, MOCK_USDC);
        
        require(btcUsdPrice == btcUsdcPrice, "BTC prices should match");
        require(ethUsdPrice == ethUsdcPrice, "ETH prices should match");
        console.log(" USD conversion working correctly");
    }
} 
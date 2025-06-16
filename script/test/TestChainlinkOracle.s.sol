// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {VCOPOracle} from "../../src/VcopCollateral/VCOPOracle.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title TestChainlinkOracle
 * @notice Tests the Chainlink integration in VCOPOracle using deployed contracts from .env
 */
contract TestChainlinkOracle is Script {
    
    function run() external view {
        // Load addresses from environment
        address vcopOracleAddress = vm.envAddress("VCOP_ORACLE_ADDRESS");
        address mockETH = vm.envAddress("MOCK_ETH_ADDRESS");
        address mockWBTC = vm.envAddress("MOCK_WBTC_ADDRESS");
        address mockUSDC = vm.envAddress("MOCK_USDC_ADDRESS");
        
        console.log("=== CHAINLINK ORACLE TESTING ===");
        console.log("Testing VCOPOracle at:", vcopOracleAddress);
        console.log("Mock ETH:", mockETH);
        console.log("Mock WBTC:", mockWBTC);
        console.log("Mock USDC:", mockUSDC);
        console.log("");
        
        // Connect to deployed oracle
        VCOPOracle oracle = VCOPOracle(vcopOracleAddress);
        
        // Test 1: Check if Chainlink is enabled
        console.log("=== TEST 1: CHAINLINK STATUS ===");
        bool chainlinkEnabled = oracle.chainlinkEnabled();
        console.log("Chainlink enabled:", chainlinkEnabled);
        
        if (!chainlinkEnabled) {
            console.log("WARNING: Chainlink is disabled. Enable it first with:");
            console.log("cast send", vcopOracleAddress, '"setChainlinkEnabled(bool)" true --rpc-url $RPC_URL --private-key $PRIVATE_KEY');
            return;
        }
        
        // Test 2: Get BTC price from Chainlink
        console.log("\n=== TEST 2: BTC PRICE FROM CHAINLINK ===");
        try oracle.getBtcPriceFromChainlink() returns (uint256 btcPrice) {
            if (btcPrice > 0) {
                console.log("BTC/USD price:", btcPrice);
                console.log("BTC price in formatted USD: $", btcPrice / 1e6);
                console.log("BTC Chainlink feed working!");
                
                // Validate reasonable price range
                if (btcPrice > 20000 * 1e6 && btcPrice < 200000 * 1e6) {
                    console.log("BTC price validation PASSED");
                } else {
                    console.log("WARNING: BTC price outside expected range");
                }
            } else {
                console.log("BTC price returned 0 - feed might be disabled or stale");
            }
        } catch {
            console.log("ERROR: Failed to get BTC price from Chainlink");
        }
        
        // Test 3: Get ETH price from Chainlink
        console.log("\n=== TEST 3: ETH PRICE FROM CHAINLINK ===");
        try oracle.getEthPriceFromChainlink() returns (uint256 ethPrice) {
            if (ethPrice > 0) {
                console.log("ETH/USD price:", ethPrice);
                console.log("ETH price in formatted USD: $", ethPrice / 1e6);
                console.log("ETH Chainlink feed working!");
                
                // Validate reasonable price range
                if (ethPrice > 1000 * 1e6 && ethPrice < 10000 * 1e6) {
                    console.log("ETH price validation PASSED");
                } else {
                    console.log("WARNING: ETH price outside expected range");
                }
            } else {
                console.log("ETH price returned 0 - feed might be disabled or stale");
            }
        } catch {
            console.log("ERROR: Failed to get ETH price from Chainlink");
        }
        
        // Test 4: Test oracle getPrice function with Chainlink
        console.log("\n=== TEST 4: ORACLE GETPRICE FUNCTION ===");
        
        // Test BTC/USD via oracle
        try oracle.getPrice(mockWBTC, address(0)) returns (uint256 btcUsdPrice) {
            console.log("BTC/USD via getPrice():", btcUsdPrice);
            console.log("BTC/USD formatted: $", btcUsdPrice / 1e6);
        } catch {
            console.log("Failed to get BTC/USD via getPrice()");
        }
        
        // Test ETH/USD via oracle
        try oracle.getPrice(mockETH, address(0)) returns (uint256 ethUsdPrice) {
            console.log("ETH/USD via getPrice():", ethUsdPrice);
            console.log("ETH/USD formatted: $", ethUsdPrice / 1e6);
        } catch {
            console.log("Failed to get ETH/USD via getPrice()");
        }
        
        // Test 5: Get feed information
        console.log("\n=== TEST 5: CHAINLINK FEED INFORMATION ===");
        
        try oracle.getChainlinkFeedInfo(mockWBTC) returns (
            address btcFeedAddress,
            uint256 btcLatestPrice,
            uint256 btcUpdatedAt,
            bool btcIsStale
        ) {
            console.log("BTC Feed Address:", btcFeedAddress);
            console.log("BTC Latest Price:", btcLatestPrice);
            console.log("BTC Updated At:", btcUpdatedAt);
            console.log("BTC Is Stale:", btcIsStale);
        } catch {
            console.log("Failed to get BTC feed info");
        }
        
        try oracle.getChainlinkFeedInfo(mockETH) returns (
            address ethFeedAddress,
            uint256 ethLatestPrice,
            uint256 ethUpdatedAt,
            bool ethIsStale
        ) {
            console.log("ETH Feed Address:", ethFeedAddress);
            console.log("ETH Latest Price:", ethLatestPrice);
            console.log("ETH Updated At:", ethUpdatedAt);
            console.log("ETH Is Stale:", ethIsStale);
        } catch {
            console.log("Failed to get ETH feed info");
        }
        
        // Test 6: Cross-pair calculation
        console.log("\n=== TEST 6: CROSS-PAIR CALCULATIONS ===");
        
        try oracle.getBtcPriceFromChainlink() returns (uint256 btcPrice) {
            if (btcPrice > 0) {
                try oracle.getEthPriceFromChainlink() returns (uint256 ethPrice) {
                    if (ethPrice > 0) {
                        // Calculate ETH/BTC ratio
                        uint256 ethBtcRatio = (ethPrice * 1e6) / btcPrice;
                        console.log("ETH/BTC ratio:", ethBtcRatio);
                        console.log("ETH/BTC formatted:", ethBtcRatio * 1e12 / 1e6); // Convert to readable format
                        console.log("Cross-pair calculation working!");
                    }
                } catch {}
            }
        } catch {}
        
        console.log("\n=== TESTING COMPLETED ===");
        console.log("Check results above for any issues");
        console.log("To enable Chainlink: make enable-chainlink-oracle");
        console.log("To disable Chainlink: make disable-chainlink-oracle");
    }
} 
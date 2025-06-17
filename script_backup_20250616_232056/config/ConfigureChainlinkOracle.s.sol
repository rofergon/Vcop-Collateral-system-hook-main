// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {VCOPOracle} from "../../src/VcopCollateral/VCOPOracle.sol";

/**
 * @title ConfigureChainlinkOracle
 * @notice Configures the VCOPOracle after deployment with all necessary settings
 */
contract ConfigureChainlinkOracle is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address vcopOracleAddress = vm.envAddress("VCOP_ORACLE_ADDRESS");
        
        // Load mock token addresses from .env
        address mockETH = vm.envAddress("MOCK_ETH_ADDRESS");
        address mockWBTC = vm.envAddress("MOCK_WBTC_ADDRESS");
        address mockUSDC = vm.envAddress("MOCK_USDC_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== CONFIGURING CHAINLINK ORACLE ===");
        console.log("Oracle address:", vcopOracleAddress);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Mock ETH:", mockETH);
        console.log("Mock WBTC:", mockWBTC);
        console.log("Mock USDC:", mockUSDC);
        console.log("");
        
        // Connect to deployed oracle
        VCOPOracle oracle = VCOPOracle(vcopOracleAddress);
        
        // Step 1: Configure mock token addresses
        console.log("Step 1: Setting mock token addresses...");
        oracle.setMockTokens(mockETH, mockWBTC, mockUSDC);
        console.log("Mock tokens configured with fallback prices");
        
        // Step 2: Enable Chainlink feeds
        console.log("\nStep 2: Enabling Chainlink feeds...");
        oracle.setChainlinkEnabled(true);
        console.log("Chainlink feeds enabled");
        
        // Step 3: Test Chainlink feeds
        console.log("\nStep 3: Testing Chainlink feeds...");
        
        // Test BTC feed
        try oracle.getBtcPriceFromChainlink() returns (uint256 btcPrice) {
            if (btcPrice > 0) {
                console.log("BTC/USD Chainlink feed working: $", btcPrice / 1e6);
            } else {
                console.log("BTC/USD Chainlink feed returned 0");
            }
        } catch {
            console.log("BTC/USD Chainlink feed failed");
        }
        
        // Test ETH feed
        try oracle.getEthPriceFromChainlink() returns (uint256 ethPrice) {
            if (ethPrice > 0) {
                console.log("ETH/USD Chainlink feed working: $", ethPrice / 1e6);
            } else {
                console.log("ETH/USD Chainlink feed returned 0");
            }
        } catch {
            console.log("ETH/USD Chainlink feed failed");
        }
        
        // Step 4: Test oracle getPrice function
        console.log("\nStep 4: Testing oracle getPrice() function...");
        
        // Test BTC/USD via oracle
        try oracle.getPrice(mockWBTC, address(0)) returns (uint256 btcUsdPrice) {
            console.log("BTC/USD via getPrice(): $", btcUsdPrice / 1e6);
        } catch {
            console.log("Failed BTC/USD via getPrice()");
        }
        
        // Test ETH/USD via oracle
        try oracle.getPrice(mockETH, address(0)) returns (uint256 ethUsdPrice) {
            console.log("ETH/USD via getPrice(): $", ethUsdPrice / 1e6);
        } catch {
            console.log("Failed ETH/USD via getPrice()");
        }
        
        // Test BTC/USDC (should use Chainlink -> USDC conversion)
        try oracle.getPrice(mockWBTC, mockUSDC) returns (uint256 btcUsdcPrice) {
            console.log("BTC/USDC via getPrice(): ", btcUsdcPrice / 1e6);
        } catch {
            console.log("Failed BTC/USDC via getPrice()");
        }
        
        // Test ETH/USDC (should use Chainlink -> USDC conversion)
        try oracle.getPrice(mockETH, mockUSDC) returns (uint256 ethUsdcPrice) {
            console.log("ETH/USDC via getPrice(): ", ethUsdcPrice / 1e6);
        } catch {
            console.log("Failed ETH/USDC via getPrice()");
        }
        
        vm.stopBroadcast();
        
        // Step 5: Final verification
        console.log("\n=== CONFIGURATION COMPLETED ===");
        console.log("Mock tokens configured");
        console.log("Chainlink feeds enabled");
        console.log("Oracle ready for use");
        console.log("");
        console.log("Next steps:");
        console.log("- Run 'make test-chainlink-oracle' for comprehensive testing");
        console.log("- Run 'make check-chainlink-prices' to monitor prices");
        console.log("- Use oracle.getPrice(tokenA, tokenB) in your contracts");
        console.log("");
        console.log("Supported price pairs:");
        console.log("- BTC/USD (Chainlink + fallback)");
        console.log("- ETH/USD (Chainlink + fallback)");
        console.log("- Any token/USDC conversions");
        console.log("- Cross-pair calculations (ETH/BTC, etc.)");
    }
} 
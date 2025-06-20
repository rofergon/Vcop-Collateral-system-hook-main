// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title ConfigureMockOracle
 * @notice Configures the MockVCOPOracle after deployment with all necessary settings
 */
contract ConfigureMockOracle is Script {
    function run() external {
        console.log("=== CONFIGURING MOCK VCOP ORACLE ===");
        
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get addresses from deployed-addresses-mock.json
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address mockOracleAddress = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        console.log("Deployer:", deployer);
        console.log("Mock Oracle address:", mockOracleAddress);
        console.log("Mock ETH:", mockETH);
        console.log("Mock WBTC:", mockWBTC);
        console.log("Mock USDC:", mockUSDC);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        MockVCOPOracle oracle = MockVCOPOracle(mockOracleAddress);
        
        console.log("Step 1: Configuring mock tokens with realistic 2025 prices...");
        oracle.setMockTokens(mockETH, mockWBTC, mockUSDC);
        console.log("Mock tokens configured");
        
        console.log("Step 2: Setting individual price configurations...");
        
        // Set realistic 2025 market prices
        oracle.setEthPrice(2500 * 1e6);  // ETH = $2,500
        oracle.setBtcPrice(104000 * 1e6); // BTC = $104,000
        
        console.log("ETH price set to: $2,500");
        console.log("BTC price set to: $104,000");
        
        console.log("Step 3: Configuring VCOP price...");
        oracle.setVcopToUsdRate(1 * 1e6); // 1 VCOP = $1 initially
        console.log("VCOP price set to: $1.00");
        
        console.log("Step 4: Verifying mock oracle configuration...");
        
        // Test price retrieval
        uint256 ethPrice = oracle.getPrice(mockETH, mockUSDC);
        uint256 btcPrice = oracle.getPrice(mockWBTC, mockUSDC);
        uint256 vcopPrice = oracle.getVcopToUsdPrice();
        uint256 usdCopRate = oracle.getUsdToCopRate();
        
        console.log("Verification Results:");
        console.log("ETH/USD price:", ethPrice);
        console.log("BTC/USD price:", btcPrice);
        console.log("VCOP/USD price:", vcopPrice);
        console.log("USD/COP rate:", usdCopRate);
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== MOCK ORACLE CONFIGURATION COMPLETED ===");
        console.log("Mock Oracle is ready for liquidation testing");
        console.log("");
        console.log("AVAILABLE TESTING FUNCTIONS:");
        console.log("1. setMockPrice(baseToken, quoteToken, price)");
        console.log("2. simulateMarketCrash(percentage)");
        console.log("3. setEthPrice(newPrice)");
        console.log("4. setBtcPrice(newPrice)");
        console.log("5. setVcopToUsdRate(newRate)");
        console.log("");
        console.log("EXAMPLE LIQUIDATION TEST:");
        console.log("1. Create loan position");
        console.log("2. oracle.simulateMarketCrash(50) // 50% crash");
        console.log("3. Check position for liquidation");
        console.log("4. Execute liquidation");
    }
} 
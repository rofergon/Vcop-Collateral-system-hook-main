// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

contract ConfigureMockVCOPPrice is Script {
    function run() external {
        console.log("=== CONFIGURING VCOP PRICE IN MOCK ORACLE ===");
        
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get addresses from deployed-addresses-mock.json
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address mockOracleAddress = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        address vcopTokenAddress = vm.parseJsonAddress(json, ".tokens.vcopToken");
        address mockUSDCAddress = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        console.log("Deployer:", deployer);
        console.log("Mock Oracle Address:", mockOracleAddress);
        console.log("VCOP Token:", vcopTokenAddress);
        console.log("Mock USDC:", mockUSDCAddress);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        MockVCOPOracle oracle = MockVCOPOracle(mockOracleAddress);
        
        console.log("Step 1: Setting initial VCOP price...");
        // Set VCOP price to $1 initially (can be easily changed for testing)
        uint256 vcopToUsdPrice = 1e6; // $1.00 with 6 decimals
        oracle.setVcopToUsdRate(vcopToUsdPrice);
        console.log("VCOP/USD price set to:", vcopToUsdPrice, "($1.00)");
        
        console.log("Step 2: Setting reverse price (USD to VCOP)...");
        uint256 usdToVcopPrice = 1e6; // 1 VCOP per USD initially
        oracle.setMockPrice(mockUSDCAddress, vcopTokenAddress, usdToVcopPrice);
        console.log("USD/VCOP price set to:", usdToVcopPrice, "(1 VCOP per USD)");
        
        console.log("Step 3: Testing VCOP price retrieval...");
        uint256 vcopPrice = oracle.getPrice(vcopTokenAddress, mockUSDCAddress);
        console.log("VCOP/USD price via getPrice():", vcopPrice);
        
        if (vcopPrice > 0) {
            // Display price with precision
            console.log("VCOP price (raw 6 decimals):", vcopPrice);
            console.log("VCOP price (USD):", vcopPrice / 1e6);
        }
        
        uint256 usdcPrice = oracle.getPrice(mockUSDCAddress, vcopTokenAddress);
        console.log("USD/VCOP price via getPrice():", usdcPrice);
        
        if (usdcPrice > 0) {
            uint256 vcopPerDollar = usdcPrice / 1e6; // Convert from 6 decimals
            console.log("VCOP per USD:", vcopPerDollar);
        }
        
        console.log("Step 4: Verifying VCOP price configuration...");
        
        // Verify final VCOP price
        uint256 finalVcopPrice = oracle.getVcopToUsdPrice();
        console.log("Final VCOP/USD price:", finalVcopPrice);
        
        if (finalVcopPrice == 1e6) {
            console.log("SUCCESS: VCOP price correctly set to $1.00");
        } else {
            console.log("WARNING: VCOP price may be incorrect. Expected 1000000, got:", finalVcopPrice);
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== MOCK VCOP PRICE CONFIGURATION COMPLETED ===");
        console.log("VCOP price is now available in the Mock Oracle");
        console.log("Use oracle.getPrice(VCOP, USDC) to get VCOP/USD price");
        console.log("");
        console.log("PRICE MANIPULATION FUNCTIONS AVAILABLE:");
        console.log("1. setVcopToUsdRate(newRate) - Direct VCOP price setting");
        console.log("2. simulateMarketCrash(percentage) - Crash all prices");
        console.log("3. setMockPrice(base, quote, price) - Set any pair price");
        console.log("4. setEthPrice(newPrice) - Quick ETH price changes");
        console.log("5. setBtcPrice(newPrice) - Quick BTC price changes");
        console.log("");
        console.log("LIQUIDATION TESTING READY:");
        console.log("- Create loan positions normally");
        console.log("- Use price manipulation to trigger liquidations");
        console.log("- Test liquidation system with predictable price changes");
    }
} 
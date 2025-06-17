// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/VcopCollateral/VCOPOracle.sol";

contract ConfigureVCOPPrice is Script {
    function run() external {
        console.log("=== CONFIGURING VCOP PRICE IN ORACLE ===");
        
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get addresses from environment
        address vcopOracleAddress = vm.envAddress("VCOP_ORACLE_ADDRESS");
        address vcopTokenAddress = vm.envAddress("VCOP_TOKEN_ADDRESS");
        address mockUSDCAddress = vm.envAddress("MOCK_USDC_ADDRESS");
        
        console.log("Deployer:", deployer);
        console.log("Oracle Address:", vcopOracleAddress);
        console.log("VCOP Token:", vcopTokenAddress);
        console.log("Mock USDC:", mockUSDCAddress);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        VCOPOracle oracle = VCOPOracle(vcopOracleAddress);
        
        console.log("Step 1: Checking current VCOP price from pool...");
        uint256 currentPoolPrice = oracle.getVcopToUsdPriceFromPool();
        console.log("Current pool price:", currentPoolPrice);
        
        if (currentPoolPrice == 0) {
            console.log("Pool has no liquidity - setting manual fallback price for VCOP");
            
            // Set VCOP price manually as fallback
            // 1 USD = 4100 VCOP, so 1 VCOP = 1/4100 USD = ~$0.000244
            uint256 vcopToUsdPrice = 244; // ~$0.000244 with 6 decimals (1/4100 * 1000000)
            uint256 usdToVcopPrice = 4100000000; // 4100 VCOP per USD with 6 decimals
            
            console.log("Setting VCOP/USD price to:", vcopToUsdPrice, "($0.000244)");
            oracle.updatePrice(vcopTokenAddress, mockUSDCAddress, vcopToUsdPrice);
            
            console.log("Setting USD/VCOP price to:", usdToVcopPrice, "(4100 VCOP per USD)");
            oracle.updatePrice(mockUSDCAddress, vcopTokenAddress, usdToVcopPrice);
            
        } else {
            console.log("Pool has liquidity, using pool price:", currentPoolPrice);
        }
        
        console.log("");
        console.log("Step 2: Testing VCOP price retrieval...");
        uint256 vcopPrice = oracle.getPrice(vcopTokenAddress, mockUSDCAddress);
        console.log("VCOP/USD price via getPrice():", vcopPrice);
        
                if (vcopPrice > 0) {
            // Display price with more precision for small values
            console.log("VCOP price (raw 6 decimals):", vcopPrice);
        }
        
        uint256 usdcPrice = oracle.getPrice(mockUSDCAddress, vcopTokenAddress);
        console.log("USD/VCOP price via getPrice():", usdcPrice);
        
        if (usdcPrice > 0) {
            uint256 vcopPerDollar = usdcPrice / 1000000; // Convert from 6 decimals
            console.log("VCOP per USD:", vcopPerDollar);
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== VCOP PRICE CONFIGURATION COMPLETED ===");
        console.log("VCOP price is now available in the Oracle");
        console.log("Use oracle.getPrice(VCOP, USDC) to get VCOP/USD price");
        console.log("Use oracle.getPrice(USDC, VCOP) to get USD/VCOP price");
        
        if (currentPoolPrice == 0) {
            console.log("");
            console.log("NOTE: Pool has no liquidity, using manual fallback price (4100 VCOP = 1 USD)");
            console.log("Add liquidity to Uniswap V4 pool for dynamic pricing");
        }
    }
} 
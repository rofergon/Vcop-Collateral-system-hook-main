// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title CrashMarketAggressively
 * @notice Hace un crash agresivo del mercado para hacer las posiciones liquidables
 */
contract CrashMarketAggressively is Script {
    
    address public mockOracle;
    
    function run() external {
        console.log("=== AGGRESSIVE MARKET CRASH ===");
        console.log("Crashing ETH from $2,375 to ~$1,100 (53% crash)");
        console.log("");
        
        loadAddresses();
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        crashMarket();
        
        vm.stopBroadcast();
        
        verifyNewPrices();
        
        console.log("=== CRASH COMPLETED ===");
        console.log("Positions should now be liquidatable!");
    }
    
    function loadAddresses() internal {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        
        console.log("Mock Oracle:", mockOracle);
        console.log("");
    }
    
    function crashMarket() internal {
        MockVCOPOracle oracle = MockVCOPOracle(mockOracle);
        
        console.log("Current prices before crash:");
        (uint256 ethPrice, uint256 btcPrice, uint256 vcopPrice, uint256 usdCopRate) = oracle.getCurrentMarketPrices();
        console.log("ETH: $", ethPrice / 1e6);
        console.log("BTC: $", btcPrice / 1e6);
        console.log("VCOP: $", vcopPrice / 1e6);
        console.log("");
        
        // Crash ETH to $1,100 (53% crash from $2,375)
        uint256 newEthPrice = 1100 * 1e6; // $1,100
        console.log("Setting ETH to $1,100...");
        oracle.setEthPrice(newEthPrice);
        
        // Also crash BTC proportionally
        uint256 newBtcPrice = 48000 * 1e6; // $48,000 (similar % crash)
        console.log("Setting BTC to $48,000...");
        oracle.setBtcPrice(newBtcPrice);
        
        console.log("Market crashed successfully!");
    }
    
    function verifyNewPrices() internal view {
        MockVCOPOracle oracle = MockVCOPOracle(mockOracle);
        
        console.log("");
        console.log("New prices after crash:");
        (uint256 ethPrice, uint256 btcPrice, uint256 vcopPrice, uint256 usdCopRate) = oracle.getCurrentMarketPrices();
        console.log("ETH: $", ethPrice / 1e6);
        console.log("BTC: $", btcPrice / 1e6);
        console.log("VCOP: $", vcopPrice / 1e6);
        console.log("");
        
        // Calculate expected ratios for the new positions
        console.log("Expected position ratios after crash:");
        
        // Position 6: 1 ETH collateral, 1500 USDC debt
        uint256 collateralValue6 = ethPrice / 1e6; // ETH price in USD
        uint256 debtValue6 = 1500; // USDC
        uint256 ratio6 = (collateralValue6 * 100) / debtValue6;
        console.log("Position 6 (1 ETH, 1500 USDC): ", ratio6, "% ratio");
        
        // Position 7: 2 ETH collateral, 3000 USDC debt  
        uint256 collateralValue7 = (ethPrice * 2) / 1e6; // 2 ETH in USD
        uint256 debtValue7 = 3000; // USDC
        uint256 ratio7 = (collateralValue7 * 100) / debtValue7;
        console.log("Position 7 (2 ETH, 3000 USDC): ", ratio7, "% ratio");
        
        console.log("");
        if (ratio6 < 105 || ratio7 < 105) {
            console.log("[SUCCESS] Positions are now liquidatable! (Ratio < 105%)");
        } else {
            console.log("[WARNING] Positions may still be safe. Need more crash.");
            console.log("Required: Ratio < 105% for liquidation");
        }
    }
} 
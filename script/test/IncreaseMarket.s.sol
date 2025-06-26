// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title IncreaseMarket
 * @notice Script to increase market prices in MockVCOPOracle
 */
contract IncreaseMarket is Script {
    function run() external {
        console.log("===================================");
        console.log("INCREASING MARKET PRICES");
        console.log("===================================");
        
        // Load oracle address from deployed-addresses-mock.json
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        
        console.log("MockVCOPOracle address:", mockOracle);
        
        vm.startBroadcast();
        
        // Get oracle instance
        MockVCOPOracle oracle = MockVCOPOracle(mockOracle);
        
        // Get current prices before increase
        (
            uint256 ethPriceBefore,
            uint256 btcPriceBefore,
            uint256 vcopPriceBefore,
            uint256 usdCopRateBefore
        ) = oracle.getCurrentMarketPrices();
        
        console.log("Current prices before increase:");
        console.log("ETH Price: $", ethPriceBefore / 1e6);
        console.log("BTC Price: $", btcPriceBefore / 1e6);
        console.log("VCOP Price: $", vcopPriceBefore / 1e6);
        
        // Calculate new prices (50% increase)
        uint256 newEthPrice = (ethPriceBefore * 150) / 100;
        uint256 newBtcPrice = (btcPriceBefore * 150) / 100;
        uint256 newVcopPrice = (vcopPriceBefore * 150) / 100;
        
        // Set new prices
        oracle.setRealistic2025Prices(
            newEthPrice,
            newBtcPrice,
            newVcopPrice
        );
        
        // Get and display current prices after increase
        (
            uint256 ethPriceAfter,
            uint256 btcPriceAfter,
            uint256 vcopPriceAfter,
            uint256 usdCopRateAfter
        ) = oracle.getCurrentMarketPrices();
        
        console.log("");
        console.log("New prices after 50% increase:");
        console.log("ETH Price: $", ethPriceAfter / 1e6);
        console.log("BTC Price: $", btcPriceAfter / 1e6);
        console.log("VCOP Price: $", vcopPriceAfter / 1e6);
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=========================================");
        console.log("MARKET PRICE INCREASE COMPLETED");
        console.log("=========================================");
    }
} 
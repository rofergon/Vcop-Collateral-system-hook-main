// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title CrashMarket
 * @notice Script to crash the market prices in MockVCOPOracle
 */
contract CrashMarket is Script {
    function run() external {
        console.log("===================================");
        console.log("CRASHING MARKET PRICES");
        console.log("===================================");
        
        // Load oracle address from deployed-addresses-mock.json
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        
        console.log("MockVCOPOracle address:", mockOracle);
        
        // Start broadcast with private key from .env
        vm.startBroadcast();
        
        // Get oracle instance
        MockVCOPOracle oracle = MockVCOPOracle(mockOracle);
        
        // First set current market defaults to ensure proper state
        try oracle.setCurrentMarketDefaults() {
            console.log("Market prices reset to defaults");
        } catch {
            console.log("Warning: Could not reset market prices");
        }
        
        // Crash market by 50%
        oracle.simulateMarketCrash(50); // 50% crash
        
        console.log("Market crashed by 5%");
        
        // Get and display current prices after crash
        try oracle.getCurrentMarketPrices() returns (
            uint256 ethPrice,
            uint256 btcPrice,
            uint256 vcopPrice,
            uint256 usdCopRate
        ) {
            console.log("Current prices after crash:");
            console.log("ETH Price: $", ethPrice / 1e6);
            console.log("BTC Price: $", btcPrice / 1e6);
            console.log("VCOP Price: $", vcopPrice / 1e6);
            console.log("USD/COP Rate:", usdCopRate / 1e6);
        } catch {
            console.log("Warning: Could not fetch current prices");
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=========================================");
        console.log("MARKET CRASH COMPLETED");
        console.log("=========================================");
    }
} 
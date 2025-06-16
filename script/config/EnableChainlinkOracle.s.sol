// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {VCOPOracle} from "../../src/VcopCollateral/VCOPOracle.sol";

/**
 * @title EnableChainlinkOracle
 * @notice Enables Chainlink feeds in the deployed VCOPOracle
 */
contract EnableChainlinkOracle is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address vcopOracleAddress = vm.envAddress("VCOP_ORACLE_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Enabling Chainlink in VCOPOracle...");
        console.log("Oracle address:", vcopOracleAddress);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        // Connect to deployed oracle
        VCOPOracle oracle = VCOPOracle(vcopOracleAddress);
        
        // Check current status
        bool currentStatus = oracle.chainlinkEnabled();
        console.log("Current Chainlink status:", currentStatus);
        
        if (!currentStatus) {
            // Enable Chainlink
            oracle.setChainlinkEnabled(true);
            console.log("Chainlink feeds ENABLED!");
            
            // Test immediately
            console.log("\nTesting feeds...");
            try oracle.getBtcPriceFromChainlink() returns (uint256 btcPrice) {
                if (btcPrice > 0) {
                    console.log("BTC/USD price:", btcPrice);
                    console.log("BTC feed working!");
                } else {
                    console.log("BTC feed returned 0");
                }
            } catch {
                console.log("BTC feed test failed");
            }
            
            try oracle.getEthPriceFromChainlink() returns (uint256 ethPrice) {
                if (ethPrice > 0) {
                    console.log("ETH/USD price:", ethPrice);
                    console.log("ETH feed working!");
                } else {
                    console.log("ETH feed returned 0");
                }
            } catch {
                console.log("ETH feed test failed");
            }
            
        } else {
            console.log("Chainlink is already enabled!");
        }
        
        vm.stopBroadcast();
        
        console.log("\nNext steps:");
        console.log("- Run 'make test-chainlink-oracle' to test functionality");
        console.log("- Run 'make check-chainlink-prices' to see current prices");
    }
} 
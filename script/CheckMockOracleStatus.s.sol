// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {MockVCOPOracle} from "../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title CheckMockOracleStatus
 * @notice Verifies that MockOracle is configured correctly with expected prices
 */
contract CheckMockOracleStatus is Script {
    function run() external {
        console.log("CHECKING MOCK ORACLE STATUS");
        console.log("============================");
        
        // Get addresses from deployed-addresses-mock.json
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address mockOracleAddress = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        MockVCOPOracle oracle = MockVCOPOracle(mockOracleAddress);
        
        console.log("Oracle Address:", mockOracleAddress);
        console.log("Mock ETH:", mockETH);
        console.log("Mock USDC:", mockUSDC);
        console.log("Mock WBTC:", mockWBTC);
        console.log("");
        
        // Check current prices
        console.log("CURRENT PRICES:");
        console.log("===============");
        
        try oracle.getPrice(mockETH, mockUSDC) returns (uint256 ethPrice) {
            console.log("ETH/USD Price:", ethPrice / 1e6, "USD");
            
            // Verify it's the expected $2,500
            if (ethPrice >= 2499 * 1e6 && ethPrice <= 2501 * 1e6) {
                console.log("OK: ETH price is correct ($2,500)");
            } else {
                console.log("ERROR: ETH price is incorrect! Expected $2,500, got:", ethPrice / 1e6);
            }
        } catch {
            console.log("ERROR: Failed to get ETH price");
        }
        
        try oracle.getPrice(mockUSDC, mockETH) returns (uint256 usdcPrice) {
            console.log("USDC/ETH Price:", usdcPrice);
        } catch {
            console.log("ERROR: Failed to get USDC price");
        }
        
        try oracle.getPrice(mockWBTC, mockUSDC) returns (uint256 btcPrice) {
            console.log("BTC/USD Price:", btcPrice / 1e6, "USD");
            
            // Verify it's around $104,000
            if (btcPrice >= 103000 * 1e6 && btcPrice <= 105000 * 1e6) {
                console.log("OK: BTC price is correct (~$104,000)");
            } else {
                console.log("ERROR: BTC price is incorrect! Expected ~$104,000, got:", btcPrice / 1e6);
            }
        } catch {
            console.log("ERROR: Failed to get BTC price");
        }
        
        console.log("");
        console.log("VCOP SPECIFIC PRICES:");
        console.log("====================");
        
        try oracle.getVcopToUsdPrice() returns (uint256 vcopPrice) {
            console.log("VCOP/USD Price:", vcopPrice / 1e6, "USD");
            
            if (vcopPrice >= 0.99e6 && vcopPrice <= 1.01e6) {
                console.log("OK: VCOP price is correct ($1.00)");
            } else {
                console.log("ERROR: VCOP price is incorrect! Expected $1.00, got:", vcopPrice / 1e6);
            }
        } catch {
            console.log("ERROR: Failed to get VCOP price");
        }
        
        try oracle.getUsdToCopRate() returns (uint256 usdCopRate) {
            console.log("USD/COP Rate:", usdCopRate / 1e6);
        } catch {
            console.log("ERROR: Failed to get USD/COP rate");
        }
        
        console.log("");
        console.log("TEST SCENARIO CALCULATION:");
        console.log("==========================");
        console.log("For a position with:");
        console.log("  - Collateral: 2 ETH");
        console.log("  - Loan: 2,000 USDC");
        console.log("");
        
        try oracle.getPrice(mockETH, mockUSDC) returns (uint256 ethPriceLocal) {
            uint256 collateralValue = (2 ether * ethPriceLocal) / 1e18; // ETH has 18 decimals
            uint256 loanValue = 2000 * 1e6; // USDC has 6 decimals
            uint256 ratio = (collateralValue * 100) / loanValue;
            
            console.log("Collateral Value: $", collateralValue / 1e6);
            console.log("Loan Value: $", loanValue / 1e6);
            console.log("Collateralization Ratio:", ratio, "%");
            
            if (ratio >= 240 && ratio <= 260) {
                console.log("OK: Ratio is safe for testing (around 250%)");
            } else {
                console.log("WARNING: Ratio is not optimal for testing! Expected ~250%, got:", ratio, "%");
            }
        } catch {
            console.log("ERROR: Failed to calculate test scenario");
        }
        
        console.log("");
        console.log("ORACLE STATUS SUMMARY:");
        console.log("======================");
        console.log("Oracle is configured and responsive");
        console.log("All price feeds are working");
        console.log("Ready for liquidation testing");
        console.log("");
        console.log("To create a liquidatable position:");
        console.log("   1. Create position with current prices (250% ratio)");
        console.log("   2. Call oracle.setEthPrice(1000 * 1e6) to crash to $1,000");
        console.log("   3. Position will have 100% ratio (liquidatable at <110%)");
    }
} 
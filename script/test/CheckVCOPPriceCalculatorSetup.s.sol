// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {VCOPOracle} from "../../src/VcopCollateral/VCOPOracle.sol";
import {VCOPPriceCalculator} from "../../src/VcopCollateral/VCOPPriceCalculator.sol";

/**
 * @title CheckVCOPPriceCalculatorSetup
 * @notice Script to check and configure VCOPPriceCalculator in VCOPOracle
 */
contract CheckVCOPPriceCalculatorSetup is Script {
    
    // Contract addresses from deployed-addresses.json
    address constant VCOP_ORACLE = 0xc1dce9c9c7344478dc98EDEA2E18019d51E06D69;
    address constant PRICE_CALCULATOR = 0xD911ba558A3Bf548Ee2B2385D7F342932B38acEe;
    
    function run() external {
        console.log("=== CHECKING VCOP PRICE CALCULATOR SETUP ===");
        console.log("==============================================");
        console.log("");
        
        console.log("Oracle Address:", VCOP_ORACLE);
        console.log("Calculator Address:", PRICE_CALCULATOR);
        console.log("");
        
        VCOPOracle oracle = VCOPOracle(VCOP_ORACLE);
        
        // Check current calculator configuration
        address currentCalculator = address(oracle.priceCalculator());
        console.log("Current Calculator in Oracle:", currentCalculator);
        
        if (currentCalculator == PRICE_CALCULATOR) {
            console.log("[SUCCESS] VCOPPriceCalculator is correctly configured!");
            console.log("");
            
            // Test the integration
            testCalculatorIntegration(oracle);
            
        } else if (currentCalculator == address(0)) {
            console.log("[WARNING] No price calculator is set in the oracle");
            console.log("This means the oracle will use its fallback implementation");
            console.log("");
            
            // Ask if user wants to configure it
            console.log("To configure the price calculator, run:");
            console.log("make configure-price-calculator");
            
        } else {
            console.log("[ERROR] Different price calculator is configured!");
            console.log("Expected:", PRICE_CALCULATOR);
            console.log("Found:", currentCalculator);
            console.log("");
            console.log("To fix this, run:");
            console.log("make configure-price-calculator");
        }
    }
    
    /**
     * @dev Configure the price calculator in the oracle (requires PRIVATE_KEY)
     */
    function configurePriceCalculator() external {
        console.log("=== CONFIGURING PRICE CALCULATOR ===");
        console.log("=====================================");
        
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        VCOPOracle oracle = VCOPOracle(VCOP_ORACLE);
        
        console.log("Setting price calculator in oracle...");
        oracle.setPriceCalculator(PRICE_CALCULATOR);
        
        vm.stopBroadcast();
        
        console.log("[SUCCESS] Price calculator configured!");
        console.log("Calculator Address:", PRICE_CALCULATOR);
        console.log("");
        
        // Verify the configuration
        address setCalculator = address(oracle.priceCalculator());
        if (setCalculator == PRICE_CALCULATOR) {
            console.log("[VERIFIED] Configuration successful!");
        } else {
            console.log("[ERROR] Configuration failed!");
        }
    }
    
    /**
     * @dev Test the calculator integration with the oracle
     */
    function testCalculatorIntegration(VCOPOracle oracle) internal view {
        console.log("=== TESTING CALCULATOR INTEGRATION ===");
        console.log("=======================================");
        
        VCOPPriceCalculator calculator = VCOPPriceCalculator(PRICE_CALCULATOR);
        
        // Test 1: Compare direct calculator vs oracle calls
        console.log("TEST 1: Price Comparison");
        console.log("------------------------");
        
        try calculator.getVcopToUsdPriceFromPool() returns (uint256 calcPrice, int24 calcTick) {
            try oracle.getVcopToUsdPriceFromPool() returns (uint256 oraclePrice) {
                                 console.log("Calculator VCOP/USD Price:", calcPrice);
                 console.log("Calculator Current Tick:", calcTick);
                console.log("Oracle VCOP/USD Price:    ", oraclePrice);
                
                if (calcPrice == oraclePrice) {
                    console.log("[SUCCESS] Prices match perfectly!");
                } else {
                    console.log("[WARNING] Prices differ - check implementation");
                }
            } catch {
                console.log("[ERROR] Oracle call failed");
            }
        } catch {
            console.log("[ERROR] Calculator call failed");
        }
        
        console.log("");
        
        // Test 2: Compare parity calculations
        console.log("TEST 2: Parity Comparison");
        console.log("-------------------------");
        
        try calculator.isVcopAtParity() returns (bool calcParity) {
            try oracle.isVcopAtParity() returns (bool oracleParity) {
                console.log("Calculator Parity:", calcParity);
                console.log("Oracle Parity:    ", oracleParity);
                
                if (calcParity == oracleParity) {
                    console.log("[SUCCESS] Parity calculations match!");
                } else {
                    console.log("[WARNING] Parity calculations differ");
                }
            } catch {
                console.log("[ERROR] Oracle parity call failed");
            }
        } catch {
            console.log("[ERROR] Calculator parity call failed");
        }
        
        console.log("");
        
        // Test 3: Test calculateAllPrices function
        console.log("TEST 3: Comprehensive Price Calculation");
        console.log("---------------------------------------");
        
        try calculator.calculateAllPrices() returns (
            uint256 vcopToUsdPrice,
            uint256 vcopToCopPrice,
            int24 currentTick,
            bool isAtParity
        ) {
            console.log("[SUCCESS] calculateAllPrices() works!");
            console.log("  VCOP/USD Price:", vcopToUsdPrice);
            console.log("  VCOP/COP Price:", vcopToCopPrice);
            console.log("  Current Tick:", currentTick);
            console.log("  At Parity:", isAtParity);
            
            // Check if prices make sense
            if (vcopToUsdPrice > 0) {
                console.log("  [ANALYSIS] Pool has liquidity and pricing data");
                uint256 vcopPerUsd = 1000000 * 1000000 / vcopToUsdPrice;
                console.log("  [ANALYSIS] VCOP per USD:", vcopPerUsd);
            } else {
                console.log("  [WARNING] No pool price available (price = 0)");
            }
            
        } catch Error(string memory reason) {
            console.log("[ERROR] calculateAllPrices() failed:", reason);
        }
        
        console.log("");
        console.log("[COMPLETE] Integration testing finished!");
    }
} 
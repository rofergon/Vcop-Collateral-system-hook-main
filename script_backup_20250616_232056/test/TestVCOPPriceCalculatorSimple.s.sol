// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {VCOPOracle} from "../../src/VcopCollateral/VCOPOracle.sol";
import {VCOPPriceCalculator} from "../../src/VcopCollateral/VCOPPriceCalculator.sol";

/**
 * @title TestVCOPPriceCalculatorSimple
 * @notice Comprehensive testing script for VCOPPriceCalculator and Oracle integration
 */
contract TestVCOPPriceCalculatorSimple is Script {
    
    // Contract addresses from deployed-addresses.json
    address constant VCOP_TOKEN = 0xE7cBF4527f193009Ed7C7201a60cA26e5b295E3c;
    address constant VCOP_ORACLE = 0xc1dce9c9c7344478dc98EDEA2E18019d51E06D69;
    address constant PRICE_CALCULATOR = 0xD911ba558A3Bf548Ee2B2385D7F342932B38acEe;
    address constant MOCK_USDC = 0xcbeC2cAa97A660434aA5420d667b3f1e60E2C17B;
    address constant MOCK_ETH = 0x87bb55de00f7D2791dbF3461A110D99bB47cF62F;
    address constant MOCK_WBTC = 0x4Cd911B122e27e5EF684e3553B8187525725a399;
    
    // Contract instances
    VCOPOracle oracle;
    VCOPPriceCalculator calculator;
    
    function run() external {
        console.log("=== TESTING VCOP PRICE CALCULATOR SYSTEM ===");
        console.log("==============================================");
        console.log("");
        
        // Initialize contract instances
        oracle = VCOPOracle(VCOP_ORACLE);
        calculator = VCOPPriceCalculator(PRICE_CALCULATOR);
        
        console.log("Contract Addresses:");
        console.log("  VCOP Token:", VCOP_TOKEN);
        console.log("  VCOP Oracle:", VCOP_ORACLE);
        console.log("  Price Calculator:", PRICE_CALCULATOR);
        console.log("  Mock USDC:", MOCK_USDC);
        console.log("");
        
        // Run all tests
        testBasicConfiguration();
        testPriceCalculatorFunctions();
        testOracleIntegration();
        testChainlinkIntegration();
        testPriceConsistency();
        testPoolStateAnalysis();
        
        console.log("");
        console.log("=== ALL TESTS COMPLETED ===");
        console.log("============================");
    }
    
    function testBasicConfiguration() internal view {
        console.log("TEST 1: BASIC CONFIGURATION CHECK");
        console.log("==================================");
        
        // Check calculator configuration
        console.log("Price Calculator Configuration:");
        console.log("  Pool Manager:", address(calculator.poolManager()));
        console.log("  VCOP Address:", calculator.vcopAddress());
        console.log("  USDC Address:", calculator.usdcAddress());
        console.log("  Fee:", calculator.fee());
        console.log("  Tick Spacing:", calculator.tickSpacing());
        console.log("  USD to COP Rate:", calculator.usdToCopRate());
        console.log("  VCOP is Token0:", calculator.isVCOPToken0());
        
        // Check oracle configuration
        console.log("");
        console.log("Oracle Configuration:");
        console.log("  Pool Manager:", address(oracle.poolManager()));
        console.log("  VCOP Address:", oracle.vcopAddress());
        console.log("  USDC Address:", oracle.usdcAddress());
        console.log("  Fee:", oracle.fee());
        console.log("  Tick Spacing:", oracle.tickSpacing());
        console.log("  VCOP is Token0:", oracle.isVCOPToken0());
        
        // Check if calculator is set in oracle
        address oracleCalculator = address(oracle.priceCalculator());
        console.log("  Price Calculator in Oracle:", oracleCalculator);
        
        if (oracleCalculator == PRICE_CALCULATOR) {
            console.log("  [SUCCESS] Price calculator correctly configured in oracle");
        } else if (oracleCalculator == address(0)) {
            console.log("  [WARNING] Price calculator not set in oracle");
        } else {
            console.log("  [ERROR] Price calculator mismatch!");
        }
        
        console.log("");
    }
    
    function testPriceCalculatorFunctions() internal view {
        console.log("TEST 2: PRICE CALCULATOR FUNCTIONS");
        console.log("===================================");
        
        try calculator.getVcopToUsdPriceFromPool() returns (uint256 price, int24 tick) {
            console.log("[SUCCESS] getVcopToUsdPriceFromPool() works");
            console.log("  VCOP/USD Price:", price);
            console.log("  Current Tick:", tick);
            
            if (price > 0) {
                // Calculate VCOP per USD
                uint256 vcopPerDollar = 1000000 * 1000000 / price;
                console.log("  VCOP per USD:", vcopPerDollar);
            } else {
                console.log("  [WARNING] Pool price is 0 - pool might be uninitialized");
            }
        } catch Error(string memory reason) {
            console.log("[ERROR] getVcopToUsdPriceFromPool() failed:", reason);
        }
        
        try calculator.getVcopToCopPrice() returns (uint256 copPrice, int24 tick) {
            console.log("[SUCCESS] getVcopToCopPrice() works");
            console.log("  VCOP/COP Price:", copPrice);
            console.log("  Current Tick:", tick);
            
            // Show as decimal
            uint256 integer = copPrice / 1e6;
            uint256 fraction = copPrice % 1e6;
            console.log("  VCOP/COP as decimal:", integer, ".", fraction);
        } catch Error(string memory reason) {
            console.log("[ERROR] getVcopToCopPrice() failed:", reason);
        }
        
        try calculator.isVcopAtParity() returns (bool atParity) {
            console.log("[SUCCESS] isVcopAtParity() works");
            console.log("  At 1:1 Parity:", atParity);
        } catch Error(string memory reason) {
            console.log("[ERROR] isVcopAtParity() failed:", reason);
        }
        
        try calculator.calculateAllPrices() returns (
            uint256 vcopToUsdPrice,
            uint256 vcopToCopPrice,
            int24 currentTick,
            bool isAtParity
        ) {
            console.log("[SUCCESS] calculateAllPrices() works");
            console.log("  VCOP/USD:", vcopToUsdPrice);
            console.log("  VCOP/COP:", vcopToCopPrice);
            console.log("  Tick:", currentTick);
            console.log("  At Parity:", isAtParity);
        } catch Error(string memory reason) {
            console.log("[ERROR] calculateAllPrices() failed:", reason);
        }
        
        console.log("");
    }
    
    function testOracleIntegration() internal {
        console.log("TEST 3: ORACLE INTEGRATION");
        console.log("===========================");
        
        // Check if oracle has calculator set
        address oracleCalculator = address(oracle.priceCalculator());
        console.log("Calculator in Oracle:", oracleCalculator);
        
        if (oracleCalculator != address(0)) {
            console.log("[SUCCESS] Oracle has price calculator configured");
            
            // Test oracle functions that use calculator
            try oracle.getVcopToUsdPriceFromPool() returns (uint256 price) {
                console.log("[SUCCESS] Oracle.getVcopToUsdPriceFromPool():", price);
            } catch Error(string memory reason) {
                console.log("[ERROR] Oracle.getVcopToUsdPriceFromPool() failed:", reason);
            }
            
            try oracle.isVcopAtParity() returns (bool atParity) {
                console.log("[SUCCESS] Oracle.isVcopAtParity():", atParity);
            } catch Error(string memory reason) {
                console.log("[ERROR] Oracle.isVcopAtParity() failed:", reason);
            }
            
        } else {
            console.log("[WARNING] Oracle doesn't have price calculator set");
            console.log("   Oracle will use fallback implementation");
        }
        
        // Test basic oracle functions
        console.log("");
        console.log("Basic Oracle Functions:");
        console.log("  USD/COP Rate (view):", oracle.getUsdToCopRateView());
        console.log("  VCOP/COP Rate (view):", oracle.getVcopToCopRateView());
        
        console.log("");
    }
    
    function testChainlinkIntegration() internal view {
        console.log("TEST 4: CHAINLINK INTEGRATION");
        console.log("==============================");
        
        // Check Chainlink status
        bool chainlinkEnabled = oracle.chainlinkEnabled();
        console.log("Chainlink Enabled:", chainlinkEnabled);
        
        if (chainlinkEnabled) {
            console.log("[SUCCESS] Chainlink is enabled");
            
            // Test BTC price
            try oracle.getBtcPriceFromChainlink() returns (uint256 btcPrice) {
                console.log("[SUCCESS] BTC/USD from Chainlink:", btcPrice);
                if (btcPrice > 0) {
                    console.log("  BTC Price: $", btcPrice / 1000000);
                } else {
                    console.log("  [WARNING] BTC price is 0 - feed might be stale");
                }
            } catch Error(string memory reason) {
                console.log("[ERROR] getBtcPriceFromChainlink() failed:", reason);
            }
            
            // Test ETH price
            try oracle.getEthPriceFromChainlink() returns (uint256 ethPrice) {
                console.log("[SUCCESS] ETH/USD from Chainlink:", ethPrice);
                if (ethPrice > 0) {
                    console.log("  ETH Price: $", ethPrice / 1000000);
                } else {
                    console.log("  [WARNING] ETH price is 0 - feed might be stale");
                }
            } catch Error(string memory reason) {
                console.log("[ERROR] getEthPriceFromChainlink() failed:", reason);
            }
            
            // Test generic price function with Chainlink tokens
            try oracle.getPrice(MOCK_WBTC, MOCK_USDC) returns (uint256 price) {
                console.log("[SUCCESS] WBTC/USDC price via getPrice():", price);
            } catch Error(string memory reason) {
                console.log("[ERROR] WBTC/USDC getPrice() failed:", reason);
            }
            
            try oracle.getPrice(MOCK_ETH, MOCK_USDC) returns (uint256 price) {
                console.log("[SUCCESS] ETH/USDC price via getPrice():", price);
            } catch Error(string memory reason) {
                console.log("[ERROR] ETH/USDC getPrice() failed:", reason);
            }
            
        } else {
            console.log("[WARNING] Chainlink is disabled - using manual prices");
        }
        
        console.log("");
    }
    
    function testPriceConsistency() internal view {
        console.log("TEST 5: PRICE CONSISTENCY CHECK");
        console.log("================================");
        
        // Compare calculator vs oracle prices
        try calculator.getVcopToUsdPriceFromPool() returns (uint256 calcPrice, int24) {
            try oracle.getVcopToUsdPriceFromPool() returns (uint256 oraclePrice) {
                console.log("Calculator VCOP/USD:", calcPrice);
                console.log("Oracle VCOP/USD:    ", oraclePrice);
                
                if (calcPrice == oraclePrice) {
                    console.log("[SUCCESS] Prices match perfectly");
                } else if (calcPrice > 0 && oraclePrice > 0) {
                    uint256 diff = calcPrice > oraclePrice ? 
                        calcPrice - oraclePrice : oraclePrice - calcPrice;
                    uint256 percentDiff = (diff * 100) / calcPrice;
                    console.log("[WARNING] Price difference:", diff);
                    console.log("[WARNING] Percentage difference:", percentDiff, "%");
                } else {
                    console.log("[ERROR] One or both prices are zero");
                }
            } catch {
                console.log("[ERROR] Could not get oracle price");
            }
        } catch {
            console.log("[ERROR] Could not get calculator price");
        }
        
        // Check parity consistency
        try calculator.isVcopAtParity() returns (bool calcParity) {
            try oracle.isVcopAtParity() returns (bool oracleParity) {
                console.log("Calculator Parity:", calcParity);
                console.log("Oracle Parity:    ", oracleParity);
                
                if (calcParity == oracleParity) {
                    console.log("[SUCCESS] Parity status matches");
                } else {
                    console.log("[WARNING] Parity status differs");
                }
            } catch {
                console.log("[ERROR] Could not get oracle parity");
            }
        } catch {
            console.log("[ERROR] Could not get calculator parity");
        }
        
        console.log("");
    }
    
    function testPoolStateAnalysis() internal view {
        console.log("TEST 6: POOL STATE ANALYSIS");
        console.log("============================");
        
        try calculator.getVcopToUsdPriceFromPool() returns (uint256 price, int24 tick) {
            console.log("");
            console.log("Detailed Pool Analysis:");
            console.log("  Current Price:", price, "(6 decimals)");
            console.log("  Current Tick:", tick);
            
            if (price > 0) {
                console.log("  [SUCCESS] Pool is initialized and has liquidity");
                
                // Calculate price ranges
                console.log("");
                console.log("Price Analysis:");
                if (price < 100) { // Less than $0.0001
                    console.log("  VCOP is very cheap (< $0.0001)");
                } else if (price < 1000) { // Less than $0.001
                    console.log("  VCOP is cheap (< $0.001)");
                } else if (price < 10000) { // Less than $0.01
                    console.log("  VCOP is moderately priced (< $0.01)");
                } else {
                    console.log("  VCOP is expensive (> $0.01)");
                }
                
                // Calculate inverse
                uint256 vcopPerUsd = 1000000 * 1000000 / price;
                console.log("  VCOP per USD:", vcopPerUsd);
                
            } else {
                console.log("  [WARNING] Pool price is 0");
                console.log("     This could mean:");
                console.log("     - Pool is not initialized");
                console.log("     - Pool has no liquidity");
                console.log("     - There's an error in price calculation");
            }
            
            // Tick analysis
            console.log("");
            console.log("Tick Analysis:");
            if (tick == 0) {
                console.log("  Tick is at zero (1:1 price)");
            } else if (tick > 0) {
                console.log("  Positive tick (VCOP > USDC in this tick range)");
            } else {
                console.log("  Negative tick (VCOP < USDC in this tick range)");
            }
            
        } catch Error(string memory reason) {
            console.log("[ERROR] Could not analyze pool state:", reason);
        }
        
        console.log("");
    }
} 
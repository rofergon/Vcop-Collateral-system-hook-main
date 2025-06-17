// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {VCOPOracle} from "../../src/VcopCollateral/VCOPOracle.sol";
import {VCOPCollateralized} from "../../src/VcopCollateral/VCOPCollateralized.sol";

/**
 * @title TestVCOPOraclePrice
 * @notice Script específico para verificar qué precios está devolviendo el Oracle para VCOP
 */
contract TestVCOPOraclePrice is Script {
    
    // Contract addresses from deployed-addresses.json
    address constant VCOP_TOKEN = 0xE7cBF4527f193009Ed7C7201a60cA26e5b295E3c;
    address constant VCOP_ORACLE = 0xc1dce9c9c7344478dc98EDEA2E18019d51E06D69;
    address constant MOCK_USDC = 0xcbeC2cAa97A660434aA5420d667b3f1e60E2C17B;
    
    function run() external {
        console.log("=== TESTING VCOP ORACLE PRICES ===");
        console.log("===================================");
        console.log("");
        
        VCOPOracle oracle = VCOPOracle(VCOP_ORACLE);
        
        console.log("Contract Addresses:");
        console.log("  VCOP Token:", VCOP_TOKEN);
        console.log("  Oracle:", VCOP_ORACLE);
        console.log("  Mock USDC:", MOCK_USDC);
        console.log("");
        
        // TEST 1: Verificar precios básicos del Oracle
        testBasicOraclePrices(oracle);
        
        // TEST 2: Probar función getPrice() con VCOP
        testGetPriceFunction(oracle);
        
        // TEST 3: Probar las funciones específicas de VCOP
        testVCOPSpecificFunctions(oracle);
        
        // TEST 4: Simular llamadas como las haría otro contrato
        testContractUsage(oracle);
        
        console.log("");
        console.log("=== VCOP PRICE TESTING COMPLETED ===");
        console.log("====================================");
    }
    
    function testBasicOraclePrices(VCOPOracle oracle) internal view {
        console.log("TEST 1: BASIC ORACLE PRICES");
        console.log("============================");
        
        // Verificar tasas básicas
        uint256 usdToCopRate = oracle.getUsdToCopRateView();
        uint256 vcopToCopRate = oracle.getVcopToCopRateView();
        
        console.log("USD/COP Rate (view):", usdToCopRate);
        console.log("VCOP/COP Rate (view):", vcopToCopRate);
        
        // Calcular precio implícito VCOP/USD
        if (usdToCopRate > 0 && vcopToCopRate > 0) {
            uint256 implicitVcopUsdPrice = (vcopToCopRate * 1000000) / usdToCopRate;
            console.log("Implicit VCOP/USD price:", implicitVcopUsdPrice);
            console.log("  (This means 1 VCOP =", implicitVcopUsdPrice, "USD in 6 decimals)");
        }
        
        console.log("");
    }
    
    function testGetPriceFunction(VCOPOracle oracle) internal view {
        console.log("TEST 2: GETPRICE() FUNCTION WITH VCOP");
        console.log("=====================================");
        
        // Test VCOP/USDC price
        try oracle.getPrice(VCOP_TOKEN, MOCK_USDC) returns (uint256 vcopUsdcPrice) {
            console.log("[SUCCESS] VCOP/USDC price via getPrice():", vcopUsdcPrice);
            
            if (vcopUsdcPrice > 0) {
                console.log("  Price interpretation: 1 VCOP =", vcopUsdcPrice, "USDC (6 decimals)");
                console.log("  In dollars: 1 VCOP = $", vcopUsdcPrice, "/ 1000000 = $", vcopUsdcPrice / 1000000);
                
                // Calculate inverse
                uint256 usdcPerVcop = 1000000 * 1000000 / vcopUsdcPrice;
                console.log("  Inverse: 1 USD =", usdcPerVcop, "VCOP");
            } else {
                console.log("  [WARNING] VCOP price is 0 via getPrice()");
            }
        } catch Error(string memory reason) {
            console.log("[ERROR] getPrice(VCOP, USDC) failed:", reason);
        }
        
        // Test USDC/VCOP price (inverse)
        try oracle.getPrice(MOCK_USDC, VCOP_TOKEN) returns (uint256 usdcVcopPrice) {
            console.log("[SUCCESS] USDC/VCOP price via getPrice():", usdcVcopPrice);
            
            if (usdcVcopPrice > 0) {
                console.log("  Price interpretation: 1 USDC =", usdcVcopPrice, "VCOP (6 decimals)");
                uint256 vcopPerDollar = usdcVcopPrice / 1000000;
                console.log("  In human terms: 1 USD =", vcopPerDollar, "VCOP");
            } else {
                console.log("  [WARNING] USDC/VCOP price is 0");
            }
        } catch Error(string memory reason) {
            console.log("[ERROR] getPrice(USDC, VCOP) failed:", reason);
        }
        
        // Test VCOP with address(0) (should default to USD)
        try oracle.getPrice(VCOP_TOKEN, address(0)) returns (uint256 vcopUsdPrice) {
            console.log("[SUCCESS] VCOP/USD price via getPrice(VCOP, address(0)):", vcopUsdPrice);
        } catch Error(string memory reason) {
            console.log("[ERROR] getPrice(VCOP, address(0)) failed:", reason);
        }
        
        console.log("");
    }
    
    function testVCOPSpecificFunctions(VCOPOracle oracle) internal {
        console.log("TEST 3: VCOP-SPECIFIC ORACLE FUNCTIONS");
        console.log("=======================================");
        
        // Test getVcopToUsdPrice()
        try oracle.getVcopToUsdPrice() returns (uint256 vcopUsdPrice) {
            console.log("[SUCCESS] getVcopToUsdPrice():", vcopUsdPrice);
        } catch Error(string memory reason) {
            console.log("[ERROR] getVcopToUsdPrice() failed:", reason);
        }
        
        // Test getVcopToCopRate()
        try oracle.getVcopToCopRate() returns (uint256 vcopCopRate) {
            console.log("[SUCCESS] getVcopToCopRate():", vcopCopRate);
        } catch Error(string memory reason) {
            console.log("[ERROR] getVcopToCopRate() failed:", reason);
        }
        
        // Test getUsdToCopRate()
        try oracle.getUsdToCopRate() returns (uint256 usdCopRate) {
            console.log("[SUCCESS] getUsdToCopRate():", usdCopRate);
        } catch Error(string memory reason) {
            console.log("[ERROR] getUsdToCopRate() failed:", reason);
        }
        
        // Test getPrice() - the main oracle function
        try oracle.getPrice() returns (uint256 price) {
            console.log("[SUCCESS] getPrice() (main oracle function):", price);
            console.log("  This is the price used by rebase mechanism");
        } catch Error(string memory reason) {
            console.log("[ERROR] getPrice() failed:", reason);
        }
        
        console.log("");
    }
    
    function testContractUsage(VCOPOracle oracle) internal view {
        console.log("TEST 4: SIMULATING CONTRACT USAGE");
        console.log("==================================");
        
        // Simular cómo otros contratos usarían el Oracle
        console.log("Scenario: Contract wants to know VCOP price for calculations");
        
        // Método 1: Usar getPrice(VCOP, USDC)
        try oracle.getPrice(VCOP_TOKEN, MOCK_USDC) returns (uint256 price1) {
            console.log("Method 1 - getPrice(VCOP, USDC):", price1);
        } catch {
            console.log("Method 1 - FAILED");
        }
        
        // Método 2: Usar getPriceData()
        try oracle.getPriceData(VCOP_TOKEN, MOCK_USDC) returns (
            VCOPOracle.PriceData memory priceData
        ) {
            console.log("Method 2 - getPriceData():");
            console.log("  Price:", priceData.price);
            console.log("  Timestamp:", priceData.timestamp);
            console.log("  Is Valid:", priceData.isValid);
        } catch Error(string memory reason) {
            console.log("Method 2 - getPriceData() failed:", reason);
        }
        
        // Método 3: Calcular usando las tasas básicas
        uint256 usdToCop = oracle.getUsdToCopRateView();
        uint256 vcopToCop = oracle.getVcopToCopRateView();
        
        if (usdToCop > 0 && vcopToCop > 0) {
            uint256 calculatedPrice = (vcopToCop * 1000000) / usdToCop;
            console.log("Method 3 - Calculated from rates:", calculatedPrice);
        }
        
        console.log("");
        console.log("SUMMARY: Which price should contracts use?");
        console.log("- For VCOP/USD: Use getPrice(VCOP_TOKEN, MOCK_USDC)");
        console.log("- For rebase: Use getPrice() (returns VCOP/COP rate)");
        console.log("- For validation: Use getPriceData() to check timestamp/validity");
    }
} 
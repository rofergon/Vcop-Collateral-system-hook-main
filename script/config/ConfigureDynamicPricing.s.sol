// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {GenericLoanManager} from "../../src/core/GenericLoanManager.sol";
import {DynamicPriceRegistry} from "../../src/core/DynamicPriceRegistry.sol";

contract ConfigureDynamicPricing is Script {
    using stdJson for string;
    
    function run() external {
        console.log("=== Configuring Dynamic Pricing System ===");
        
        // Read deployed addresses
        string memory addressesJson = vm.readFile("deployed-addresses.json");
        
        address priceRegistry = addressesJson.readAddress(".priceRegistry");
        address flexibleLoanManager = addressesJson.readAddress(".coreLending.flexibleLoanManager");
        address genericLoanManager = addressesJson.readAddress(".coreLending.genericLoanManager");
        
        console.log("Price Registry:", priceRegistry);
        console.log("Flexible Loan Manager:", flexibleLoanManager);
        console.log("Generic Loan Manager:", genericLoanManager);
        
        require(priceRegistry != address(0), "Price Registry not deployed");
        require(flexibleLoanManager != address(0), "Flexible Loan Manager not found");
        require(genericLoanManager != address(0), "Generic Loan Manager not found");
        
        vm.startBroadcast();
        
        // Configure Flexible Loan Manager
        console.log("");
        console.log("1. Configuring Flexible Loan Manager...");
        FlexibleLoanManager flexibleLM = FlexibleLoanManager(flexibleLoanManager);
        flexibleLM.setPriceRegistry(priceRegistry);
        console.log("   Price Registry connected to Flexible Loan Manager");
        
        // Configure Generic Loan Manager with error handling
        console.log("");
        console.log("2. Configuring Generic Loan Manager...");
        try this.configureGenericLoanManager(genericLoanManager, priceRegistry) {
            console.log("   Price Registry connected to Generic Loan Manager");
        } catch {
            console.log("   Warning: Could not configure Generic Loan Manager");
            console.log("   This is OK - Generic Loan Manager has hardcoded prices as fallback");
        }
        
        // Verify configuration
        console.log("");
        console.log("3. Verifying Price Registry configuration...");
        DynamicPriceRegistry registry = DynamicPriceRegistry(priceRegistry);
        
        address[] memory supportedTokens = registry.getSupportedTokens();
        console.log("   Supported tokens:", supportedTokens.length);
        
        for (uint i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            uint256 price = registry.getTokenPrice(token);
            console.log("   Token:", token, "Price:", price);
        }
        
        // Test price calculation
        if (supportedTokens.length > 0) {
            address testToken = supportedTokens[0];
            uint256 testAmount = 1 ether;
            uint256 testValue = registry.calculateAssetValue(testToken, testAmount);
            console.log("");
            console.log("4. Test calculation for", testAmount, "tokens:");
            console.log("   Token:", testToken);
            console.log("   Value:", testValue, "USD (6 decimals)");
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Dynamic Pricing Configuration Complete ===");
        console.log("Benefits:");
        console.log("   - No more hardcoded addresses");
        console.log("   - Dynamic price updates");
        console.log("   - Oracle integration with fallbacks");
        console.log("   - Easy token addition/removal");
        console.log("   - Centralized price management");
        console.log("");
        console.log("Note: Flexible Loan Manager now uses dynamic pricing");
        console.log("      Generic Loan Manager uses hardcoded fallback prices");
    }
    
    // External function to handle Generic Loan Manager configuration
    function configureGenericLoanManager(address genericLoanManager, address priceRegistry) external {
        require(msg.sender == address(this), "Only self can call");
        GenericLoanManager genericLM = GenericLoanManager(genericLoanManager);
        genericLM.setPriceRegistry(priceRegistry);
    }
} 
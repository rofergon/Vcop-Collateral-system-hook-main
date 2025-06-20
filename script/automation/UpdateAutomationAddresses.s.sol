// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title UpdateAutomationAddresses
 * @dev Script to update deployed-addresses.json with automation contract addresses
 * Reads the latest automation deployment and outputs addresses for JSON update
 */
contract UpdateAutomationAddresses is Script {
    
    function run() external {
        console.log("=== UPDATING AUTOMATION ADDRESSES IN JSON ===");
        
        // Get deployer info
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer:", deployer);
        
        // Read automation addresses from environment (set by deployment script)
        address automationRegistry = vm.envAddress("AUTOMATION_REGISTRY_ADDRESS");
        address automationKeeper = vm.envAddress("AUTOMATION_KEEPER_ADDRESS");
        address loanAdapter = vm.envAddress("LOAN_ADAPTER_ADDRESS");
        address priceTrigger = vm.envAddress("PRICE_TRIGGER_ADDRESS");
        
        console.log("");
        console.log("=== AUTOMATION SYSTEM ADDRESSES ===");
        console.log("Automation Registry:", automationRegistry);
        console.log("Automation Keeper:", automationKeeper);
        console.log("Loan Adapter:", loanAdapter);
        console.log("Price Trigger:", priceTrigger);
        
        console.log("");
        console.log("=== ADDRESSES READY FOR JSON UPDATE ===");
        console.log("These addresses will be added to deployed-addresses.json");
        
        // Log in a format that can be easily parsed by shell script
        console.log("AUTOMATION_EXTRACT_START");
        console.log("AUTOMATION_REGISTRY:", automationRegistry);
        console.log("AUTOMATION_KEEPER:", automationKeeper);
        console.log("LOAN_ADAPTER:", loanAdapter);
        console.log("PRICE_TRIGGER:", priceTrigger);
        console.log("AUTOMATION_EXTRACT_END");
        
        // Success message
        console.log("");
        console.log("SUCCESS: Automation addresses ready for JSON update!");
        console.log("Run the shell script to update deployed-addresses.json");
    }
    
    /**
     * @dev Alternative function to update addresses using a different approach
     */
    function updateFromBroadcast() external view {
        console.log("=== READING FROM BROADCAST FILES ===");
        console.log("This function would read the latest broadcast file");
        console.log("and extract automation addresses automatically");
    }
} 
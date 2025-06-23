// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title GenerateCheckDataSimple
 * @notice Generate checkData for Chainlink Automation without network connection
 */
contract GenerateCheckDataSimple is Script {
    
    function run() external pure {
        console.log("=== CHAINLINK AUTOMATION UPKEEP REGISTRATION ===");
        console.log("");
        
        // Deployed addresses from your system
        address automationKeeper = 0xD826ac602E4ea5cC8596B5D7CDad05644730bD7A;
        address loanAdapter = 0xAdc01a79f9120010a1dc7EAEdAAaEbfde128881F;
        address flexibleLoanManager = 0x6AF626a57D1482ed0c9e3d12e344d7E5A2fB0EEB;
        
        console.log("UPKEEP REGISTRATION INFO:");
        console.log("=========================");
        console.log("");
        
        console.log("1. CONTRACT TO REGISTER:");
        console.log("   Address:", automationKeeper);
        console.log("");
        
        console.log("2. NETWORK: Base Sepolia");
        console.log("   Chain ID: 84532");
        console.log("");
        
        console.log("3. TRIGGER TYPE: Custom Logic");
        console.log("");
        
        // Generate checkData
        bytes memory checkData = abi.encode(
            loanAdapter,      // LoanAdapter address being monitored
            uint256(0),       // startIndex (0 = auto-start from position 1)
            uint256(25)       // batchSize (check 25 positions at a time)
        );
        
        console.log("4. CHECK DATA (HEX):");
        console.log("   Copy this exactly:");
        console.logBytes(checkData);
        console.log("");
        
        console.log("5. RECOMMENDED SETTINGS:");
        console.log("   Gas Limit: 500,000");
        console.log("   Check Gas Limit: 50,000");
        console.log("   Admin Address: Your wallet address");
        console.log("   Starting Balance: 5-10 LINK tokens");
        console.log("");
        
        console.log("6. SYSTEM COMPONENTS:");
        console.log("   AutomationKeeper: %s", automationKeeper);
        console.log("   LoanAdapter: %s", loanAdapter);
        console.log("   FlexibleLoanManager: %s", flexibleLoanManager);
        console.log("");
        
        console.log("7. REGISTRATION URL:");
        console.log("   https://automation.chain.link/base-sepolia");
        console.log("");
        
        console.log("=== READY FOR CHAINLINK REGISTRATION! ===");
    }
} 
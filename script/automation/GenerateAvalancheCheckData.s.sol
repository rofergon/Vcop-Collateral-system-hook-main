// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title GenerateAvalancheCheckData
 * @notice Genera el checkData correcto para el upkeep de Avalanche Fuji
 */
contract GenerateAvalancheCheckData is Script {
    
    function run() external view {
        console.log("=== AVALANCHE FUJI - CHAINLINK AUTOMATION CHECKDATA ===");
        console.log("");
        
        // Load deployed addresses from JSON
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        console.log("DEPLOYED ADDRESSES:");
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        // Generate checkData
        bytes memory checkData = abi.encode(
            loanAdapter,     // LoanAdapter address
            uint256(0),      // startIndex (0 = auto-start from position 1)
            uint256(25)      // batchSize (check 25 positions at a time)
        );
        
        console.log("=== CHAINLINK AUTOMATION UPKEEP CONFIGURATION ===");
        console.log("");
        console.log("NETWORK: Avalanche Fuji");
        console.log("Chain ID: 43113");
        console.log("RPC URL: https://api.avax-test.network/ext/bc/C/rpc");
        console.log("");
        
        console.log("UPKEEP SETTINGS:");
        console.log("================");
        console.log("1. Target Contract Address:");
        console.log("   ", automationKeeper);
        console.log("");
        
        console.log("2. Trigger Type: Custom Logic");
        console.log("");
        
        console.log("3. Check Data (copy this hex):");
        console.logBytes(checkData);
        console.log("");
        
        // Convert to clean hex string
        string memory hexString = _bytesToHex(checkData);
        console.log("4. Check Data (formatted):");
        console.log("   ", hexString);
        console.log("");
        
        console.log("5. Recommended Gas Settings:");
        console.log("   Gas Limit: 500,000");
        console.log("   Check Gas Limit: 50,000");
        console.log("");
        
        console.log("6. Funding:");
        console.log("   Starting Balance: 5-10 LINK tokens");
        console.log("   Get LINK: https://faucets.chain.link/fuji");
        console.log("");
        
        console.log("=== REGISTRATION INSTRUCTIONS ===");
        console.log("1. Go to: https://automation.chain.link/");
        console.log("2. Connect your wallet to Avalanche Fuji network");
        console.log("3. Click 'Register New Upkeep'");
        console.log("4. Select 'Custom Logic' trigger");
        console.log("5. Paste the target contract address above");
        console.log("6. Paste the Check Data hex above");
        console.log("7. Set gas limits as recommended");
        console.log("8. Fund with LINK and complete registration");
        console.log("");
        
        console.log("=== VERIFICATION ===");
        console.log("After registration, your upkeep should:");
        console.log("- Monitor positions automatically");
        console.log("- Trigger liquidations when needed");
        console.log("- Execute every ~1 minute when positions are at risk");
        console.log("");
        
        console.log("SYSTEM READY FOR AUTOMATION!");
    }
    
    function _bytesToHex(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[2 + i * 2 + 1] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract FixCheckDataHex is Script {
    
    function run() external pure {
        console.log("=== FIXING CHECKDATA HEX FOR CHAINLINK ===");
        console.log("");
        
        // Your deployed addresses
        address loanAdapter = 0xAdc01a79f9120010a1dc7EAEdAAaEbfde128881F;
        
        console.log("Parameters:");
        console.log("- LoanAdapter:", loanAdapter);
        console.log("- StartIndex: 0");
        console.log("- BatchSize: 25");
        console.log("");
        
        // Generate checkData using abi.encode
        bytes memory checkData = abi.encode(
            loanAdapter,    // address
            uint256(0),     // startIndex
            uint256(25)     // batchSize
        );
        
        console.log("Generated CheckData:");
        console.logBytes(checkData);
        console.log("");
        
        // Verify length
        console.log("CheckData length in bytes:", checkData.length);
        console.log("Hex string length (without 0x):", checkData.length * 2);
        console.log("Is even length?", (checkData.length * 2) % 2 == 0);
        console.log("");
        
        // Manual hex conversion to ensure correctness
        bytes memory hexChars = "0123456789abcdef";
        string memory hexString = "0x";
        
        for (uint256 i = 0; i < checkData.length; i++) {
            uint8 b = uint8(checkData[i]);
            hexString = string.concat(
                hexString,
                string(abi.encodePacked(hexChars[b >> 4])),
                string(abi.encodePacked(hexChars[b & 0x0f]))
            );
        }
        
        console.log("CORRECTED CHECKDATA (copy this):");
        console.log(hexString);
        console.log("");
        
        // Alternative: Simple checkData with just the loan adapter
        bytes memory simpleCheckData = abi.encode(loanAdapter);
        console.log("SIMPLE ALTERNATIVE (just loan adapter):");
        console.logBytes(simpleCheckData);
    }
} 
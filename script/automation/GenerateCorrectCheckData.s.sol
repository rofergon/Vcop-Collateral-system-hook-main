// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title GenerateCorrectCheckData
 * @notice Genera el checkData CORRECTO para registro en Chainlink Automation
 */
contract GenerateCorrectCheckData is Script {
    
    function run() external view {
        console.log("=== GENERATING CORRECT CHECKDATA FOR CHAINLINK ===");
        console.log("");
        
        // Load addresses from deployed-addresses-mock.json
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        
        console.log("AVALANCHE FUJI ADDRESSES:");
        console.log("========================");
        console.log("LoanAdapter:", loanAdapter);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("");
        
        // Generate checkData: abi.encode(address loanManager, uint256 startIndex, uint256 batchSize)
        bytes memory checkData = abi.encode(
            loanAdapter,  // address: LoanAdapter (NOT FlexibleLoanManager)
            uint256(0),   // uint256: startIndex (will be converted to position ID 1)
            uint256(25)   // uint256: batchSize (optimal for gas)
        );
        
        console.log("CHAINLINK AUTOMATION REGISTRATION:");
        console.log("=================================");
        console.log("Registry Address (Avalanche Fuji):");
        console.log("0x819B58A646CDd8289275A87653a2aA4902b14fe6");
        console.log("");
        console.log("Target Contract (AutomationKeeper):");
        console.log(automationKeeper);
        console.log("");
        console.log("CheckData (CORRECT FORMAT):");
        console.logBytes(checkData);
        console.log("");
        
        // Verify hex length
        string memory hexString = vm.toString(checkData);
        console.log("CheckData as string (copy this to Chainlink UI):");
        console.log(hexString);
        console.log("");
        
        // Show length info
        console.log("LENGTH VERIFICATION:");
        console.log("===================");
        console.log("CheckData length (bytes):", checkData.length);
        console.log("Expected length: 96 bytes (32+32+32)");
        console.log("Hex string length:", bytes(hexString).length);
        console.log("Expected hex length: 194 chars (2 + 192)"); // "0x" + 192 hex chars
        
        // Manual verification
        _verifyEncoding(loanAdapter);
    }
    
    function _verifyEncoding(address loanAdapter) internal pure {
        console.log("");
        console.log("MANUAL VERIFICATION:");
        console.log("===================");
        
        // Manually encode to verify
        bytes32 encodedAddress = bytes32(uint256(uint160(loanAdapter)));
        bytes32 encodedStartIndex = bytes32(uint256(0));
        bytes32 encodedBatchSize = bytes32(uint256(25));
        
        console.log("Address encoded (32 bytes):");
        console.logBytes32(encodedAddress);
        console.log("StartIndex encoded (32 bytes):");
        console.logBytes32(encodedStartIndex);
        console.log("BatchSize encoded (32 bytes):");
        console.logBytes32(encodedBatchSize);
        
        // Concatenate manually
        bytes memory manualCheckData = abi.encodePacked(
            encodedAddress,
            encodedStartIndex,
            encodedBatchSize
        );
        
        console.log("Manual concatenation:");
        console.logBytes(manualCheckData);
        console.log("");
        
        // Generate using abi.encode again for final result
        bytes memory finalCheckData = abi.encode(loanAdapter, uint256(0), uint256(25));
        
        console.log("FINAL RESULT FOR CHAINLINK:");
        console.log("===========================");
        console.log("Use this exact value in Chainlink UI:");
        console.logBytes(finalCheckData);
        
        // Convert to hex without 0x prefix for debugging
        bytes memory dataOnly = new bytes(finalCheckData.length);
        for (uint i = 0; i < finalCheckData.length; i++) {
            dataOnly[i] = finalCheckData[i];
        }
        
        console.log("");
        console.log("REGISTRATION PARAMETERS:");
        console.log("========================");
        console.log("Upkeep Name: VCOP Avalanche Loan Liquidation");
        console.log("Gas Limit: 2000000");
        console.log("Starting Balance: 50 LINK");
        console.log("Trigger Type: Custom Logic");
        console.log("Target Contract: Use AutomationKeeper address above");
        console.log("CheckData: Use the hex value above");
    }
} 
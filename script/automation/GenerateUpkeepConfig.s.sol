// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../generated/MockTestAddresses.sol";

/**
 * @title GenerateUpkeepConfig
 * @notice Genera configuración exacta para registrar upkeep en Chainlink
 */
contract GenerateUpkeepConfig is Script {
    
    function run() external view {
        console.log("========================================");
        console.log("CHAINLINK AUTOMATION CONFIG GENERATOR");
        console.log("========================================");
        console.log("");
        
        // Use addresses from recent deployment
        address flexibleLoanManager = FLEXIBLE_LOAN_MANAGER_ADDRESS;
        // Updated AutomationKeeper address from latest deployment
        address automationKeeper = 0x85C77737887DcB94331cFAf24fc3fCD5eECE9292;
        
        console.log("UPKEEP REGISTRATION INFORMATION:");
        console.log("-----------------------------------");
        console.log("");
        
        console.log("CONTRACT TO REGISTER:");
        console.log("AutomationKeeper Address:", automationKeeper);
        console.log("");
        
        console.log("CHECK DATA (HEX):");
        
        // Generate checkData for FlexibleLoanManager
        bytes memory checkData = abi.encode(
            flexibleLoanManager,  // loanManager address
            uint256(0),          // startIndex  
            uint256(0),          // maxPositions (0 = check all)
            uint256(25)          // minRiskLevel (25% risk threshold)
        );
        console.log("CheckData Hex: %s", _bytesToHex(checkData));
        console.log("");
        
        console.log("RECOMMENDED SETTINGS:");
        console.log("Gas Limit: 500,000");
        console.log("Check Gas Limit: 30,000");
        console.log("Trigger Type: Custom Logic");
        console.log("Min/Max Funding: 0.5 - 10 LINK");
        console.log("");
        
        console.log("SYSTEM ADDRESSES (FROM LATEST DEPLOYMENT):");
        console.log("----------------------------------------------");
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("VaultBasedHandler:", VAULT_BASED_HANDLER_ADDRESS);
        console.log("Mock Oracle:", MOCK_ORACLE_ADDRESS);
        console.log("Mock ETH:", MOCK_ETH_ADDRESS);
        console.log("Mock USDC:", MOCK_USDC_ADDRESS);
        console.log("");
        
        console.log("REGISTRATION STEPS:");
        console.log("----------------------");
        console.log("1. Go to: https://automation.chain.link");
        console.log("2. Connect to Base Sepolia network");
        console.log("3. Click 'Register New Upkeep'");
        console.log("4. Choose 'Custom Logic'");
        console.log("5. Enter AutomationKeeper address:");
        console.log("  ", automationKeeper);
        console.log("6. Paste the CheckData hex above");
        console.log("7. Set gas limit to 500,000");
        console.log("8. Fund with at least 0.5 LINK");
        console.log("");
        
        console.log("TESTING WORKFLOW:");
        console.log("--------------------");
        console.log("1. Create test positions:");
        console.log("   forge script script/automation/Step1_CreateTestPositions.s.sol --broadcast");
        console.log("");
        console.log("2. Crash prices to trigger liquidations:");
        console.log("   forge script script/automation/Step2_CrashPrices.s.sol --broadcast");
        console.log("");
        console.log("3. Monitor automation execution on:");
        console.log("   https://automation.chain.link/base-sepolia");
        console.log("");
        
        console.log("AUTOMATION CONFIGURATION COMPLETE!");
        console.log("Your system is ready for Chainlink Automation");
    }
    
    function _bytesToHex(bytes memory data) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory result = new bytes(2 + data.length * 2);
        result[0] = "0";
        result[1] = "x";
        
        for (uint256 i = 0; i < data.length; i++) {
            result[2 + i * 2] = hexChars[uint8(data[i] >> 4)];
            result[2 + i * 2 + 1] = hexChars[uint8(data[i] & 0x0f)];
        }
        
        return string(result);
    }
} 
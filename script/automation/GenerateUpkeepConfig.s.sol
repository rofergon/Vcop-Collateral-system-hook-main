// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title GenerateUpkeepConfig
 * @notice Genera configuración exacta para registrar upkeep en Chainlink
 * @dev FIXED: Maneja el caso donde automatización aún no está desplegada
 */
contract GenerateUpkeepConfig is Script {
    
    function run() external view {
        console.log("========================================");
        console.log("CHAINLINK AUTOMATION CONFIG GENERATOR");
        console.log("========================================");
        console.log("");
        
        // CRITICAL FIX: Load addresses directly from deployed-addresses-mock.json
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        // ALWAYS use FlexibleLoanManager from JSON
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        
        // Try to get AutomationKeeper, but handle case where it doesn't exist yet
        address automationKeeper;
        bool automationDeployed = false;
        
        try vm.parseJsonAddress(json, ".automation.automationKeeper") returns (address keeper) {
            automationKeeper = keeper;
            automationDeployed = true;
        } catch {
            // Automation not deployed yet - this is OK during initial deployment
            automationKeeper = address(0);
            automationDeployed = false;
        }
        
        // Validation to prevent future mistakes
        require(flexibleLoanManager != address(0), "FlexibleLoanManager not found in deployed-addresses-mock.json");
        
        // Display validation info
        console.log("VALIDATION:");
        console.log("Reading from: deployed-addresses-mock.json");
        console.log("FlexibleLoanManager found:", flexibleLoanManager);
        
        if (automationDeployed) {
            console.log("AutomationKeeper found:", automationKeeper);
        } else {
            console.log("AutomationKeeper: NOT YET DEPLOYED");
            console.log("NOTE: This is normal during initial core deployment");
        }
        
        // Check for GenericLoanManager to warn if they're different
        try vm.parseJsonAddress(json, ".coreLending.genericLoanManager") returns (address genericManager) {
            if (genericManager != flexibleLoanManager) {
                console.log("NOTE: GenericLoanManager exists but NOT used:", genericManager);
                console.log("CORRECT: Using FlexibleLoanManager for automation");
            }
        } catch {
            console.log("GenericLoanManager not found - this is OK");
        }
        console.log("");
        
        console.log("UPKEEP REGISTRATION INFORMATION:");
        console.log("-----------------------------------");
        console.log("");
        
        if (automationDeployed) {
            console.log("CONTRACT TO REGISTER:");
            console.log("AutomationKeeper Address:", automationKeeper);
        } else {
            console.log("CONTRACT TO REGISTER:");
            console.log("AutomationKeeper Address: [WILL BE AVAILABLE AFTER AUTOMATION DEPLOYMENT]");
        }
        console.log("");
        
        console.log("CHECK DATA (HEX):");
        
        // Generate checkData for FlexibleLoanManager (NEVER GenericLoanManager)
        bytes memory checkData = abi.encode(
            flexibleLoanManager,  // ALWAYS FlexibleLoanManager from JSON
            uint256(0),          // startIndex (0 = auto-start from position ID 1)
            uint256(25)          // batchSize (25 positions per check)
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
        console.log("FlexibleLoanManager (USED):", flexibleLoanManager);
        
        // Load other addresses for reference
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("Mock Oracle:", mockOracle);
        console.log("Mock ETH:", mockETH);
        console.log("Mock USDC:", mockUSDC);
        console.log("");
        
        if (automationDeployed) {
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
        } else {
            console.log("NEXT STEPS:");
            console.log("----------------------");
            console.log("1. Complete automation deployment first");
            console.log("2. Run this script again to get full registration info");
            console.log("3. Or check the automation deployment output for complete details");
        }
        console.log("");
        
        console.log("TESTING WORKFLOW:");
        console.log("--------------------");
        console.log("1. Create test positions:");
        console.log("   forge script script/test/Step1_CreateTestPositions.s.sol --broadcast");
        console.log("");
        console.log("2. Crash prices to trigger liquidations:");
        console.log("   forge script script/test/Step2_CrashPrices.s.sol --broadcast");
        console.log("");
        console.log("3. Monitor automation execution on:");
        console.log("   https://automation.chain.link/base-sepolia");
        console.log("");
        
        if (automationDeployed) {
            console.log("AUTOMATION CONFIGURATION COMPLETE!");
            console.log("Your system is ready for Chainlink Automation");
        } else {
            console.log("CORE SYSTEM CONFIGURATION COMPLETE!");
            console.log("Automation will be configured in the next deployment phase");
        }
        console.log("");
        console.log("IMPORTANT: This upkeep will monitor positions in FlexibleLoanManager ONLY");
        console.log("This is correct because test positions are created in FlexibleLoanManager");
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
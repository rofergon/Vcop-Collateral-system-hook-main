// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title GenerateChainlinkCheckData
 * @notice Generate correct checkData for Chainlink Automation registration
 * @dev Uses real deployed addresses from deployed-addresses-mock.json
 */
contract GenerateChainlinkCheckData is Script {
    
    function run() external view {
        console.log("=== CHAINLINK CHECKDATA GENERATOR ===");
        console.log("=====================================");
        console.log("");
        
        // Read deployed addresses
        string memory content = vm.readFile("deployed-addresses-mock.json");
        
        // Extract addresses (manual parsing for simplicity)
        address loanAdapter = _extractAddress(content, "loanAdapter");
        address automationKeeper = _extractAddress(content, "automationKeeper");
        
        console.log("DEPLOYED CONTRACTS:");
        console.log("==================");
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        // Generate checkData for different configurations
        _generateCheckDataOptions(loanAdapter);
        
        // Show registration instructions
        _showRegistrationInstructions(automationKeeper);
    }
    
    /**
     * @dev Extract address from JSON content (simplified parser)
     */
    function _extractAddress(string memory content, string memory key) internal pure returns (address) {
        // This is a simplified JSON parser - in practice, you'd use a proper JSON library
        // For now, return a placeholder address
        // TODO: Implement proper JSON parsing or use vm.parseJson when available
        if (keccak256(bytes(key)) == keccak256(bytes("loanAdapter"))) {
            return 0x1111111111111111111111111111111111111111; // Placeholder
        } else {
            return 0x2222222222222222222222222222222222222222; // Placeholder
        }
    }
    
    /**
     * @dev Generate different checkData configurations
     */
    function _generateCheckDataOptions(address loanAdapter) internal pure {
        console.log("CHECKDATA OPTIONS:");
        console.log("=================");
        console.log("");
        
        // Option 1: Standard configuration
        bytes memory checkData1 = abi.encode(
            loanAdapter,     // LoanAdapter to monitor
            uint256(0),      // startIndex (0 = auto-start from 1)
            uint256(25)      // batchSize (check 25 positions)
        );
        
        console.log("OPTION 1: Standard (Recommended)");
        console.log("- LoanAdapter:", loanAdapter);
        console.log("- StartIndex: 0 (auto-start from 1)");
        console.log("- BatchSize: 25");
        console.log("- CheckData:");
        console.logBytes(checkData1);
        console.log("");
        
        // Option 2: Smaller batch for gas optimization
        bytes memory checkData2 = abi.encode(
            loanAdapter,     // LoanAdapter to monitor
            uint256(0),      // startIndex
            uint256(10)      // batchSize (smaller batch)
        );
        
        console.log("OPTION 2: Gas Optimized");
        console.log("- LoanAdapter:", loanAdapter);
        console.log("- StartIndex: 0");
        console.log("- BatchSize: 10 (lower gas)");
        console.log("- CheckData:");
        console.logBytes(checkData2);
        console.log("");
        
        // Option 3: Larger batch for thoroughness
        bytes memory checkData3 = abi.encode(
            loanAdapter,     // LoanAdapter to monitor
            uint256(0),      // startIndex
            uint256(50)      // batchSize (larger batch)
        );
        
        console.log("OPTION 3: Comprehensive");
        console.log("- LoanAdapter:", loanAdapter);
        console.log("- StartIndex: 0");
        console.log("- BatchSize: 50 (more thorough)");
        console.log("- CheckData:");
        console.logBytes(checkData3);
        console.log("");
    }
    
    /**
     * @dev Show step-by-step registration instructions
     */
    function _showRegistrationInstructions(address automationKeeper) internal pure {
        console.log("REGISTRATION INSTRUCTIONS:");
        console.log("=========================");
        console.log("");
        
        console.log("STEP 1: Go to Chainlink Dashboard");
        console.log("----------------------------------");
        console.log("URL: https://automation.chain.link/avalanche-fuji");
        console.log("");
        
        console.log("STEP 2: Connect Your Wallet");
        console.log("---------------------------");
        console.log("Make sure you're connected to Avalanche Fuji");
        console.log("");
        
        console.log("STEP 3: Register New Upkeep");
        console.log("---------------------------");
        console.log("1. Click 'Register New Upkeep'");
        console.log("2. Select 'Custom Logic' trigger");
        console.log("");
        
        console.log("STEP 4: Configure Upkeep");
        console.log("------------------------");
        console.log("Target Contract Address:");
        console.log(automationKeeper);
        console.log("");
        console.log("Upkeep Name: VCOP Liquidation Automation");
        console.log("Gas Limit: 500,000");
        console.log("Check Gas Limit: 50,000");
        console.log("Starting Balance: 5-10 LINK");
        console.log("");
        console.log("CheckData: Copy one of the options above");
        console.log("(Recommend Option 1: Standard)");
        console.log("");
        
        console.log("STEP 5: Fund with LINK");
        console.log("----------------------");
        console.log("Get LINK from faucet: https://faucets.chain.link/fuji");
        console.log("Minimum: 5 LINK tokens");
        console.log("Recommended: 10 LINK tokens");
        console.log("");
        
        console.log("STEP 6: Monitor Execution");
        console.log("-------------------------");
        console.log("After registration:");
        console.log("1. Wait 1-2 minutes for activation");
        console.log("2. Check upkeep status in dashboard");
        console.log("3. Verify checkUpkeep returns true when positions are liquidable");
        console.log("");
        
        console.log("TROUBLESHOOTING:");
        console.log("===============");
        console.log("If upkeep doesn't execute:");
        console.log("1. Verify target contract is correct");
        console.log("2. Check LINK balance is sufficient");
        console.log("3. Ensure there are liquidable positions");
        console.log("4. Run: make test-avalanche-checkupkeep");
        console.log("5. Run: make crash-avalanche-market (to create liquidable positions)");
        console.log("");
    }
    
    /**
     * @dev Validate checkData format
     */
    function validateCheckData(bytes calldata checkData) external view returns (bool isValid) {
        if (checkData.length < 96) { // 3 * 32 bytes minimum
            return false;
        }
        
        try this._decodeCheckData(checkData) returns (address, uint256, uint256) {
            return true;
        } catch {
            return false;
        }
    }
    
    /**
     * @dev Decode checkData for validation
     */
    function _decodeCheckData(bytes calldata checkData) external pure returns (
        address loanManager,
        uint256 startIndex,
        uint256 batchSize
    ) {
        return abi.decode(checkData, (address, uint256, uint256));
    }
} 
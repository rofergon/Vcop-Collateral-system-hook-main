// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title TestCheckUpkeep
 * @notice Tests checkUpkeep to see if it detects liquidatable positions
 */
contract TestCheckUpkeep is Script {
    
    function run() external view {
        console.log("=== TESTING CHAINLINK CHECKUPKEEP ===");
        console.log("");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        
        console.log("AutomationKeeper:", automationKeeper);
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("");
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        // Generate checkData
        console.log("STEP 1: Generating checkData...");
        bytes memory checkData = keeper.generateOptimizedCheckData(
            flexibleLoanManager,
            0,  // Start from position 1 (0 converts to 1)
            25  // Batch size
        );
        
        console.log("CheckData generated:");
        console.logBytes(checkData);
        console.log("");
        
        // Test checkUpkeep
        console.log("STEP 2: Testing checkUpkeep...");
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("CheckUpkeep result:");
            console.log("  upkeepNeeded:", upkeepNeeded);
            console.log("  performData length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("  [SUCCESS] Liquidatable positions detected!");
                
                // Decode performData to see what positions
                try this.decodePerformData(performData) returns (
                    address loanManager,
                    uint256[] memory positions,
                    uint256[] memory riskLevels,
                    uint256 timestamp
                ) {
                    console.log("  Liquidatable positions found:");
                    console.log("    LoanManager:", loanManager);
                    console.log("    Positions count:", positions.length);
                    console.log("    Timestamp:", timestamp);
                    
                    for (uint256 i = 0; i < positions.length && i < 5; i++) {
                        console.log(string.concat("    Position ", vm.toString(positions[i]), ": risk ", vm.toString(riskLevels[i]), "%"));
                    }
                } catch {
                    console.log("  [WARNING] Could not decode performData");
                    console.logBytes(performData);
                }
            } else {
                console.log("  [INFO] No liquidatable positions detected");
                console.log("  This could mean:");
                console.log("    - No positions are liquidatable yet");
                console.log("    - CheckData is incorrect");  
                console.log("    - Position range doesn't include liquidatable positions");
            }
        } catch Error(string memory reason) {
            console.log("  [ERROR] CheckUpkeep failed:");
            console.log("  Reason:", reason);
        } catch {
            console.log("  [ERROR] CheckUpkeep failed with unknown error");
        }
        
        console.log("");
        console.log("=== CHECKUPKEEP TEST COMPLETED ===");
    }
    
    /**
     * @dev Helper to decode performData
     */
    function decodePerformData(bytes memory performData) external pure returns (
        address loanManager,
        uint256[] memory positions,
        uint256[] memory riskLevels,
        uint256 timestamp
    ) {
        return abi.decode(performData, (address, uint256[], uint256[], uint256));
    }
} 
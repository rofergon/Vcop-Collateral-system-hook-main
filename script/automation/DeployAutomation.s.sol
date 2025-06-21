// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// ❌ DEPRECATED SCRIPT - DO NOT USE
// =====================================
// This script deployed a custom AutomationRegistry which is no longer needed.
// 
// ✅ USE INSTEAD: script/automation/DeployAutomationProduction.s.sol
// This new script uses the official Chainlink Registry: 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3
//
// To deploy automation:
// make deploy-automation-production
//
// ❌ DEPRECATED - This file kept for reference only
// =====================================

/*
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {PriceChangeLogTrigger} from "../../src/automation/core/PriceChangeLogTrigger.sol";

// ❌ REMOVED: AutomationRegistry import - now using official Chainlink Registry
// import {AutomationRegistry} from "../../src/automation/core/AutomationRegistry.sol";

contract DeployAutomation is Script {
    
    // ❌ DEPRECATED: This entire script is no longer used
    // ✅ USE: DeployAutomationProduction.s.sol instead
    
    function run() external {
        revert("❌ DEPRECATED: Use 'make deploy-automation-production' instead");
    }
}
*/

// Empty contract to avoid compilation errors
contract DeployAutomation {
    // ❌ DEPRECATED - Use DeployAutomationProduction.s.sol
} 
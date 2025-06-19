// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperFixed} from "../../src/automation/core/LoanAutomationKeeperFixed.sol";

/**
 * @title DeployFixedKeeper
 * @notice Deploy the fixed AutomationCompatible keeper
 */
contract DeployFixedKeeper is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Use existing AutomationRegistry from deployment
        address automationRegistry = 0xf6d8FE19A75e610Cea3c1Bce7B6520f9756f8bB2;
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying Fixed LoanAutomationKeeper...");
        console.log("Using AutomationRegistry:", automationRegistry);
        
        LoanAutomationKeeperFixed fixedKeeper = new LoanAutomationKeeperFixed(automationRegistry);
        
        console.log("SUCCESS: Fixed LoanAutomationKeeper deployed at:", address(fixedKeeper));
        
        // Generate sample checkData
        address loanAdapter = 0xb970589d6Bd918B8594cf167bD0F0ddc78F356D0;
        bytes memory checkData = fixedKeeper.generateCheckData(loanAdapter, 0, 25);
        
        console.log("Sample checkData for Chainlink registration:");
        console.logBytes(checkData);
        
        vm.stopBroadcast();
        
        console.log("\n===========================================");
        console.log("FIXED KEEPER DEPLOYMENT COMPLETE");
        console.log("===========================================");
        console.log("Contract Address:", address(fixedKeeper));
        console.log("AutomationRegistry:", automationRegistry);
        console.log("LoanAdapter:", loanAdapter);
        console.log("\nREGISTER THIS CONTRACT IN CHAINLINK:");
        console.log("1. Go to https://automation.chain.link/");
        console.log("2. Create Custom Logic Upkeep");
        console.log("3. Target contract:", address(fixedKeeper));
        console.log("4. Gas limit: 2,500,000");
        console.log("5. Use generated checkData above");
        console.log("===========================================");
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

contract DeployBasicAutomation is Script {
    
    function run() external {
        console.log("DEPLOYING BASIC AUTOMATION SYSTEM");
        console.log("=================================");
        console.log("");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("Deployer:", msg.sender);
        console.log("");
        
        vm.startBroadcast();
        
        // 1. Deploy LoanAdapter
        console.log("Step 1: Deploying LoanAdapter...");
        LoanManagerAutomationAdapter loanAdapter = new LoanManagerAutomationAdapter(
            flexibleLoanManager
        );
        console.log("LoanAdapter deployed at:", address(loanAdapter));
        
        // 2. Deploy AutomationKeeper (using official Chainlink Registry)
        console.log("Step 2: Deploying AutomationKeeper...");
        address chainlinkRegistry = 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3; // Official Base Sepolia Registry
        LoanAutomationKeeperOptimized automationKeeper = new LoanAutomationKeeperOptimized(chainlinkRegistry);
        console.log("AutomationKeeper deployed at:", address(automationKeeper));
        
        // 3. Configure connections
        console.log("Step 3: Configuring automation system...");
        
        // Register LoanAdapter in AutomationKeeper
        automationKeeper.registerLoanManager(address(loanAdapter), 100); // Priority 100
        console.log("LoanAdapter registered in AutomationKeeper");
        
        // Enable automation in LoanAdapter
        loanAdapter.setAutomationEnabled(true);
        console.log("Automation enabled in LoanAdapter");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("AUTOMATION DEPLOYMENT COMPLETED");
        console.log("===============================");
        console.log("LoanAdapter:", address(loanAdapter));
        console.log("AutomationKeeper:", address(automationKeeper));
        console.log("");
        
        // Update JSON file
        _updateAddressesFile(address(loanAdapter), address(automationKeeper));
    }
    
    function _updateAddressesFile(address loanAdapter, address automationKeeper) internal {
        console.log("Updating deployed-addresses-mock.json...");
        
        // Read current JSON
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        // Write the new JSON structure - we'll manually add the automation section
        string memory newJson = string(abi.encodePacked(
            '{\n',
            '  "oracleType": "MockVCOPOracle",\n',
            '  "tokens": {\n',
            '    "mockETH": "', _addressToString(vm.parseJsonAddress(json, ".tokens.mockETH")), '",\n',
            '    "mockWBTC": "', _addressToString(vm.parseJsonAddress(json, ".tokens.mockWBTC")), '",\n',
            '    "mockUSDC": "', _addressToString(vm.parseJsonAddress(json, ".tokens.mockUSDC")), '",\n',
            '    "vcopToken": "', _addressToString(vm.parseJsonAddress(json, ".tokens.vcopToken")), '"\n',
            '  },\n',
            '  "vcopCollateral": {\n',
            '    "mockVcopOracle": "', _addressToString(vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle")), '",\n',
            '    "vcopPriceCalculator": "', _addressToString(vm.parseJsonAddress(json, ".vcopCollateral.vcopPriceCalculator")), '",\n',
            '    "vcopCollateralManager": "', _addressToString(vm.parseJsonAddress(json, ".vcopCollateral.vcopCollateralManager")), '",\n',
            '    "vcopCollateralHook": "', _addressToString(vm.parseJsonAddress(json, ".vcopCollateral.vcopCollateralHook")), '"\n',
            '  },\n',
            '  "coreLending": {\n',
            '    "riskCalculator": "', _addressToString(vm.parseJsonAddress(json, ".coreLending.riskCalculator")), '",\n',
            '    "genericLoanManager": "', _addressToString(vm.parseJsonAddress(json, ".coreLending.genericLoanManager")), '",\n',
            '    "flexibleLoanManager": "', _addressToString(vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager")), '",\n',
            '    "mintableBurnableHandler": "', _addressToString(vm.parseJsonAddress(json, ".coreLending.mintableBurnableHandler")), '",\n',
            '    "vaultBasedHandler": "', _addressToString(vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler")), '",\n',
            '    "flexibleAssetHandler": "', _addressToString(vm.parseJsonAddress(json, ".coreLending.flexibleAssetHandler")), '",\n',
            '    "dynamicPriceRegistry": "', _addressToString(vm.parseJsonAddress(json, ".coreLending.dynamicPriceRegistry")), '"\n',
            '  },\n',
            '  "automation": {\n',
            '    "loanAdapter": "', _addressToString(loanAdapter), '",\n',
            '    "automationKeeper": "', _addressToString(automationKeeper), '"\n',
            '  },\n',
            '  "config": {\n',
            '    "poolManager": "', _addressToString(vm.parseJsonAddress(json, ".config.poolManager")), '",\n',
            '    "feeCollector": "', _addressToString(vm.parseJsonAddress(json, ".config.feeCollector")), '",\n',
            '    "usdToCopRate": "', vm.parseJsonString(json, ".config.usdToCopRate"), '"\n',
            '  }\n',
            '}'
        ));
        
        vm.writeFile("deployed-addresses-mock.json", newJson);
        console.log("deployed-addresses-mock.json updated");
    }
    
    function _addressToString(address addr) internal pure returns (string memory) {
        return vm.toString(addr);
    }
} 
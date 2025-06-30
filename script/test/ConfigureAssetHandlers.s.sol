// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

/**
 * @title ConfigureAssetHandlers
 * @notice Simplified version to debug deployment issues
 */
contract ConfigureAssetHandlers is Script {
    
    function run() external {
        console.log("DEBUGGING ASSET HANDLERS CONFIGURATION");
        console.log("=======================================");
        
        // Read addresses from JSON
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address flexibleAssetHandler = vm.parseJsonAddress(json, ".coreLending.flexibleAssetHandler");
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address mintableBurnableHandler = vm.parseJsonAddress(json, ".coreLending.mintableBurnableHandler");
        
        console.log("Contract addresses from JSON:");
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("FlexibleAssetHandler:", flexibleAssetHandler);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("MintableBurnableHandler:", mintableBurnableHandler);
        
        // Use deployer private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);
        
        // Check if contracts have code
        console.log("Checking contract deployments...");
        console.log("FlexibleLoanManager code size:", flexibleLoanManager.code.length);
        console.log("FlexibleAssetHandler code size:", flexibleAssetHandler.code.length);
        console.log("VaultBasedHandler code size:", vaultBasedHandler.code.length);
        console.log("MintableBurnableHandler code size:", mintableBurnableHandler.code.length);
        
        // Basic deployment validation
        if (flexibleLoanManager.code.length == 0) {
            console.log("ERROR: FlexibleLoanManager not deployed properly!");
            return;
        }
        
        if (vaultBasedHandler.code.length == 0) {
            console.log("ERROR: VaultBasedHandler not deployed properly!");
            return;
        }
        
        console.log("SUCCESS: All contracts have code, proceeding with basic configuration test...");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Try basic call without revert handling to see raw error
        console.log("Testing basic contract call...");
        
        // Simple check - try to call a view function first
        (bool success, bytes memory data) = flexibleLoanManager.staticcall(abi.encodeWithSignature("nextPositionId()"));
        if (success) {
            uint256 nextId = abi.decode(data, (uint256));
            console.log("FlexibleLoanManager nextPositionId:", nextId);
        } else {
            console.log("Failed to call nextPositionId()");
        }
        
        vm.stopBroadcast();
        
        console.log("Basic configuration test completed!");
    }
} 
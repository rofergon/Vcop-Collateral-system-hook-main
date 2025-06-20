// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {EmergencyRegistry} from "../../src/core/EmergencyRegistry.sol";

/**
 * @title DeployEmergencyRegistry
 * @notice Deploy Emergency Registry and automatically update deployed-addresses.json
 */
contract DeployEmergencyRegistry is Script {
    
    function run() external {
        vm.startBroadcast();
        
        console.log("DEPLOYING EMERGENCY REGISTRY SYSTEM");
        console.log("=====================================");
        
        // Deploy Emergency Registry
        console.log("Deploying EmergencyRegistry...");
        EmergencyRegistry emergencyRegistry = new EmergencyRegistry();
        
        console.log("Emergency Registry deployed at:", address(emergencyRegistry));
        console.log("Owner set to:", emergencyRegistry.owner());
        
        // Add deployer as emergency responder
        console.log("Adding deployer as emergency responder...");
        emergencyRegistry.addEmergencyResponder(msg.sender);
        
        console.log("Emergency Registry deployment completed!");
        
        // Automatically update deployed-addresses.json
        _updateDeployedAddresses(address(emergencyRegistry));
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev Updates deployed-addresses.json automatically (following DeployDynamicPriceRegistry pattern)
     */
    function _updateDeployedAddresses(address emergencyRegistry) internal {
        try vm.readFile("deployed-addresses.json") returns (string memory existingJson) {
            console.log("Updating deployed-addresses.json with Emergency Registry...");
            
            // Parse existing JSON and preserve all fields (following exact pattern from DeployDynamicPriceRegistry)
            string memory network = abi.decode(vm.parseJson(existingJson, ".network"), (string));
            uint256 chainId = abi.decode(vm.parseJson(existingJson, ".chainId"), (uint256));
            address deployer = abi.decode(vm.parseJson(existingJson, ".deployer"), (address));
            string memory deploymentDate = abi.decode(vm.parseJson(existingJson, ".deploymentDate"), (string));
            address poolManager = abi.decode(vm.parseJson(existingJson, ".poolManager"), (address));
            
            // Mock tokens
            address ethToken = abi.decode(vm.parseJson(existingJson, ".mockTokens.ETH"), (address));
            address wbtcToken = abi.decode(vm.parseJson(existingJson, ".mockTokens.WBTC"), (address));
            address usdcToken = abi.decode(vm.parseJson(existingJson, ".mockTokens.USDC"), (address));
            
            // VCOP Collateral
            address vcopToken = abi.decode(vm.parseJson(existingJson, ".vcopCollateral.vcopToken"), (address));
            address oracle = abi.decode(vm.parseJson(existingJson, ".vcopCollateral.oracle"), (address));
            address priceCalculator = abi.decode(vm.parseJson(existingJson, ".vcopCollateral.priceCalculator"), (address));
            address collateralManager = abi.decode(vm.parseJson(existingJson, ".vcopCollateral.collateralManager"), (address));
            address hook = abi.decode(vm.parseJson(existingJson, ".vcopCollateral.hook"), (address));
            
            // Core Lending
            address genericLoanManager = abi.decode(vm.parseJson(existingJson, ".coreLending.genericLoanManager"), (address));
            address flexibleLoanManager = abi.decode(vm.parseJson(existingJson, ".coreLending.flexibleLoanManager"), (address));
            address vaultBasedHandler = abi.decode(vm.parseJson(existingJson, ".coreLending.vaultBasedHandler"), (address));
            address mintableBurnableHandler = abi.decode(vm.parseJson(existingJson, ".coreLending.mintableBurnableHandler"), (address));
            address flexibleAssetHandler = abi.decode(vm.parseJson(existingJson, ".coreLending.flexibleAssetHandler"), (address));
            address riskCalculator = abi.decode(vm.parseJson(existingJson, ".coreLending.riskCalculator"), (address));
            
                        // Price Registry
            address priceRegistry = abi.decode(vm.parseJson(existingJson, ".priceRegistry"), (address));
            
            // Rebuild complete JSON structure (exact pattern from DeployDynamicPriceRegistry)
            string memory json = "{";
            json = string.concat(json, '"network":"', network, '",');
            json = string.concat(json, '"chainId":', vm.toString(chainId), ',');
            json = string.concat(json, '"deployer":"', vm.toString(deployer), '",');
            json = string.concat(json, '"deploymentDate":"', deploymentDate, '",');
            json = string.concat(json, '"poolManager":"', vm.toString(poolManager), '",');
            
            // Mock tokens
            json = string.concat(json, '"mockTokens":{');
            json = string.concat(json, '"ETH":"', vm.toString(ethToken), '",');
            json = string.concat(json, '"WBTC":"', vm.toString(wbtcToken), '",');
            json = string.concat(json, '"USDC":"', vm.toString(usdcToken), '"');
            json = string.concat(json, '},');
            
            // VCOP Collateral
            json = string.concat(json, '"vcopCollateral":{');
            json = string.concat(json, '"vcopToken":"', vm.toString(vcopToken), '",');
            json = string.concat(json, '"oracle":"', vm.toString(oracle), '",');
            json = string.concat(json, '"priceCalculator":"', vm.toString(priceCalculator), '",');
            json = string.concat(json, '"collateralManager":"', vm.toString(collateralManager), '",');
            json = string.concat(json, '"hook":"', vm.toString(hook), '"');
            json = string.concat(json, '},');
            
            // Core Lending
            json = string.concat(json, '"coreLending":{');
            json = string.concat(json, '"genericLoanManager":"', vm.toString(genericLoanManager), '",');
            json = string.concat(json, '"flexibleLoanManager":"', vm.toString(flexibleLoanManager), '",');
            json = string.concat(json, '"vaultBasedHandler":"', vm.toString(vaultBasedHandler), '",');
            json = string.concat(json, '"mintableBurnableHandler":"', vm.toString(mintableBurnableHandler), '",');
            json = string.concat(json, '"flexibleAssetHandler":"', vm.toString(flexibleAssetHandler), '",');
            json = string.concat(json, '"riskCalculator":"', vm.toString(riskCalculator), '"');
            json = string.concat(json, '},');
            
            // Price Registry
            json = string.concat(json, '"priceRegistry":"', vm.toString(priceRegistry), '",');
            
            // Emergency Registry (NEW)
            json = string.concat(json, '"emergencyRegistry":"', vm.toString(emergencyRegistry), '"');
            
            json = string.concat(json, '}');
            
            vm.writeFile("deployed-addresses.json", json);
            console.log("deployed-addresses.json updated with Emergency Registry:", vm.toString(emergencyRegistry));
            
        } catch {
            console.log("Warning: Could not update deployed-addresses.json - please update manually");
            console.log("Emergency Registry address:", vm.toString(emergencyRegistry));
        }
    }
} 
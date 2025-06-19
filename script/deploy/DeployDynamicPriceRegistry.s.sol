// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {DynamicPriceRegistry} from "../../src/core/DynamicPriceRegistry.sol";

contract DeployDynamicPriceRegistry is Script {
    using stdJson for string;
    
    function run() external {
        console.log("=== Deploying Dynamic Price Registry ===");
        
        // Read current addresses
        string memory addressesJson = vm.readFile("deployed-addresses.json");
        
        address oracle = addressesJson.readAddress(".vcopCollateral.oracle");
        console.log("Oracle address:", oracle);
        
        vm.startBroadcast();
        
        // Deploy Dynamic Price Registry
        DynamicPriceRegistry priceRegistry = new DynamicPriceRegistry(oracle);
        console.log("DynamicPriceRegistry deployed at:", address(priceRegistry));
        
        // Read token addresses from deployment
        address ethToken = addressesJson.readAddress(".mockTokens.ETH");
        address usdcToken = addressesJson.readAddress(".mockTokens.USDC");
        address wbtcToken = addressesJson.readAddress(".mockTokens.WBTC");
        
        console.log("Initializing tokens...");
        console.log("  ETH:", ethToken);
        console.log("  USDC:", usdcToken);
        console.log("  WBTC:", wbtcToken);
        
        // Initialize tokens with current deployment addresses
        priceRegistry.initializeFromDeployment(ethToken, usdcToken, wbtcToken);
        
        vm.stopBroadcast();
        
        // Update deployed-addresses.json
        _updateDeployedAddresses(address(priceRegistry));
        
        console.log("=== Dynamic Price Registry Deployment Complete ===");
        console.log("Price Registry Address:", address(priceRegistry));
        console.log("Oracle connected:", oracle != address(0) ? "Yes" : "No");
        console.log("Fallback enabled: Yes");
    }
    
    function _updateDeployedAddresses(address priceRegistry) internal {
        try vm.readFile("deployed-addresses.json") returns (string memory existingJson) {
            // ✅ FIXED: Just add priceRegistry to existing JSON instead of overwriting
            string memory updatedJson = vm.serializeAddress("update", "priceRegistry", priceRegistry);
            
            // Parse existing JSON and preserve all fields
            string memory network = existingJson.readString(".network");
            uint256 chainId = existingJson.readUint(".chainId");
            address deployer = existingJson.readAddress(".deployer");
            string memory deploymentDate = existingJson.readString(".deploymentDate");
            address poolManager = existingJson.readAddress(".poolManager");
            
            // Mock tokens
            address ethToken = existingJson.readAddress(".mockTokens.ETH");
            address wbtcToken = existingJson.readAddress(".mockTokens.WBTC");
            address usdcToken = existingJson.readAddress(".mockTokens.USDC");
            
            // VCOP Collateral
            address vcopToken = existingJson.readAddress(".vcopCollateral.vcopToken");
            address oracle = existingJson.readAddress(".vcopCollateral.oracle");
            address priceCalculator = existingJson.readAddress(".vcopCollateral.priceCalculator");
            address collateralManager = existingJson.readAddress(".vcopCollateral.collateralManager");
            address hook = existingJson.readAddress(".vcopCollateral.hook");
            
            // Core Lending
            address genericLoanManager = existingJson.readAddress(".coreLending.genericLoanManager");
            address flexibleLoanManager = existingJson.readAddress(".coreLending.flexibleLoanManager");
            address vaultBasedHandler = existingJson.readAddress(".coreLending.vaultBasedHandler");
            address mintableBurnableHandler = existingJson.readAddress(".coreLending.mintableBurnableHandler");
            address flexibleAssetHandler = existingJson.readAddress(".coreLending.flexibleAssetHandler");
            address riskCalculator = existingJson.readAddress(".coreLending.riskCalculator");
            
            // Rewards (OPTIONAL - may not exist yet)
            address rewardDistributor = address(0);
            try vm.parseJsonAddress(existingJson, ".rewards.rewardDistributor") returns (address addr) {
                rewardDistributor = addr;
            } catch {
                // RewardDistributor not deployed yet - this is OK
            }
            
            // Rebuild complete JSON structure
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
            
            // Price Registry (NEW)
            json = string.concat(json, '"priceRegistry":"', vm.toString(priceRegistry), '"');
            
            // Add rewards section only if rewardDistributor exists
            if (rewardDistributor != address(0)) {
                json = string.concat(json, ',');
                json = string.concat(json, '"rewards":{');
                json = string.concat(json, '"rewardDistributor":"', vm.toString(rewardDistributor), '"');
                json = string.concat(json, '}');
            }
            
            json = string.concat(json, '}');
            
            vm.writeFile("deployed-addresses.json", json);
            console.log("deployed-addresses.json updated with priceRegistry:", vm.toString(priceRegistry));
            
        } catch {
            console.log("Warning: Could not update deployed-addresses.json - please update manually");
            console.log("Price Registry address:", vm.toString(priceRegistry));
        }
    }
} 
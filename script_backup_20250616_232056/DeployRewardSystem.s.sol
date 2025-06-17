// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {RewardDistributor} from "../src/core/RewardDistributor.sol";
import {FlexibleLoanManager} from "../src/core/FlexibleLoanManager.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {VaultBasedHandler} from "../src/core/VaultBasedHandler.sol";
import {VCOPCollateralManager} from "../src/VcopCollateral/VCOPCollateralManager.sol";
import {VCOPCollateralized} from "../src/VcopCollateral/VCOPCollateralized.sol";

/**
 * @title DeployRewardSystem
 * @notice Script to deploy and configure the reward system
 */
contract DeployRewardSystem is Script {
    // Reward pool IDs
    bytes32 public constant FLEXIBLE_LOAN_POOL = keccak256("FLEXIBLE_LOAN_COLLATERAL");
    bytes32 public constant GENERIC_LOAN_POOL = keccak256("GENERIC_LOAN_COLLATERAL");
    bytes32 public constant VAULT_HANDLER_POOL = keccak256("VAULT_HANDLER_LIQUIDITY");
    bytes32 public constant VCOP_COLLATERAL_POOL = keccak256("VCOP_COLLATERAL_DEPOSITS");
    
    // Reward rates (rewards per second)
    uint256 public constant DEFAULT_REWARD_RATE = 1e15; // 0.001 VCOP per second
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying Reward System with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy RewardDistributor
        RewardDistributor rewardDistributor = new RewardDistributor();
        console.log("RewardDistributor deployed at:", address(rewardDistributor));
        
        // 2. Get existing contract addresses
        address vcopToken = vm.envAddress("VCOP_TOKEN_ADDRESS");
        address flexibleLoanManager = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        address genericLoanManager = vm.envAddress("GENERIC_LOAN_MANAGER_ADDRESS");
        address vaultHandler = vm.envAddress("VAULT_HANDLER_ADDRESS");
        address collateralManager = vm.envAddress("COLLATERAL_MANAGER_ADDRESS");
        
        console.log("Using VCOP token at:", vcopToken);
        console.log("Using FlexibleLoanManager at:", flexibleLoanManager);
        console.log("Using GenericLoanManager at:", genericLoanManager);
        console.log("Using VaultHandler at:", vaultHandler);
        console.log("Using CollateralManager at:", collateralManager);
        
        // 3. Configure VCOP token in RewardDistributor
        rewardDistributor.setVCOPToken(vcopToken);
        console.log("VCOP token set in RewardDistributor");
        
        // 4. Set RewardDistributor as minter in VCOP token
        VCOPCollateralized vcop = VCOPCollateralized(vcopToken);
        vcop.setMinter(address(rewardDistributor), true);
        console.log("RewardDistributor set as VCOP minter");
        
        // 5. Set protocol components in RewardDistributor
        rewardDistributor.setProtocolComponents(
            vaultHandler,
            flexibleLoanManager,
            genericLoanManager,
            collateralManager
        );
        console.log("Protocol components configured");
        
        // 6. Authorize contracts to update stakes
        rewardDistributor.setAuthorizedUpdater(flexibleLoanManager, true);
        rewardDistributor.setAuthorizedUpdater(genericLoanManager, true);
        rewardDistributor.setAuthorizedUpdater(vaultHandler, true);
        rewardDistributor.setAuthorizedUpdater(collateralManager, true);
        console.log("Authorized updaters configured");
        
        // 7. Create reward pools
        console.log("Creating reward pools...");
        
        // VCOP pools (use minting)
        rewardDistributor.createRewardPool(
            FLEXIBLE_LOAN_POOL,
            vcopToken,
            DEFAULT_REWARD_RATE
        );
        console.log("Flexible Loan Pool created with VCOP minting");
        
        rewardDistributor.createRewardPool(
            GENERIC_LOAN_POOL,
            vcopToken,
            DEFAULT_REWARD_RATE
        );
        console.log("Generic Loan Pool created with VCOP minting");
        
        rewardDistributor.createRewardPool(
            VAULT_HANDLER_POOL,
            vcopToken,
            DEFAULT_REWARD_RATE
        );
        console.log("Vault Handler Pool created with VCOP minting");
        
        rewardDistributor.createRewardPool(
            VCOP_COLLATERAL_POOL,
            vcopToken,
            DEFAULT_REWARD_RATE
        );
        console.log("VCOP Collateral Pool created with VCOP minting");
        
        // 8. Add virtual rewards to pools (for minting pools, this just tracks potential rewards)
        uint256 virtualRewards = 10000000 * 1e6; // 10M VCOP virtual rewards per pool
        rewardDistributor.addRewards(FLEXIBLE_LOAN_POOL, virtualRewards);
        rewardDistributor.addRewards(GENERIC_LOAN_POOL, virtualRewards);
        rewardDistributor.addRewards(VAULT_HANDLER_POOL, virtualRewards);
        rewardDistributor.addRewards(VCOP_COLLATERAL_POOL, virtualRewards);
        console.log("Virtual rewards added to all pools");
        
        vm.stopBroadcast();
        
        // 9. Update deployed-addresses.json automatically
        _updateDeployedAddresses(address(rewardDistributor));
        
        console.log("=================================");
        console.log("REWARD SYSTEM DEPLOYMENT COMPLETE");
        console.log("===============================");
        console.log("RewardDistributor:", address(rewardDistributor));
        console.log("VCOP Token:", vcopToken);
        console.log("FlexibleLoanManager authorized:", rewardDistributor.authorizedUpdaters(flexibleLoanManager));
        console.log("GenericLoanManager authorized:", rewardDistributor.authorizedUpdaters(genericLoanManager));
        console.log("VaultHandler authorized:", rewardDistributor.authorizedUpdaters(vaultHandler));
        console.log("CollateralManager authorized:", rewardDistributor.authorizedUpdaters(collateralManager));
        
        // Display pool information
        console.log("\nCreated Pools:");
        console.log("- Flexible Loan Pool:", vm.toString(FLEXIBLE_LOAN_POOL));
        console.log("- Generic Loan Pool:", vm.toString(GENERIC_LOAN_POOL));
        console.log("- Vault Handler Pool:", vm.toString(VAULT_HANDLER_POOL));
        console.log("- VCOP Collateral Pool:", vm.toString(VCOP_COLLATERAL_POOL));
        
        console.log("\n=== POST-DEPLOYMENT ACTIONS ===");
        console.log("RewardDistributor deployed at:", address(rewardDistributor));
        console.log("deployed-addresses.json updated automatically");
        console.log("To configure system integration, run: make configure-system-integration");
    }
    
    /**
     * @notice Update deployed-addresses.json with RewardDistributor address
     */
    function _updateDeployedAddresses(address rewardDistributor) internal {
        string memory currentJson = vm.readFile("deployed-addresses.json");
        
        // Parse current JSON to get existing values
        address deployer = abi.decode(vm.parseJson(currentJson, ".deployer"), (address));
        uint256 chainId = abi.decode(vm.parseJson(currentJson, ".chainId"), (uint256));
        string memory network = abi.decode(vm.parseJson(currentJson, ".network"), (string));
        address poolManager = abi.decode(vm.parseJson(currentJson, ".poolManager"), (address));
        uint256 deploymentDate = block.timestamp;
        
        // Get mock tokens
        address ethToken = abi.decode(vm.parseJson(currentJson, ".mockTokens.ETH"), (address));
        address wbtcToken = abi.decode(vm.parseJson(currentJson, ".mockTokens.WBTC"), (address));
        address usdcToken = abi.decode(vm.parseJson(currentJson, ".mockTokens.USDC"), (address));
        
        // Get vcopCollateral
        address vcopToken = abi.decode(vm.parseJson(currentJson, ".vcopCollateral.vcopToken"), (address));
        address oracle = abi.decode(vm.parseJson(currentJson, ".vcopCollateral.oracle"), (address));
        address priceCalculator = abi.decode(vm.parseJson(currentJson, ".vcopCollateral.priceCalculator"), (address));
        address collateralManager = abi.decode(vm.parseJson(currentJson, ".vcopCollateral.collateralManager"), (address));
        address hook = abi.decode(vm.parseJson(currentJson, ".vcopCollateral.hook"), (address));
        
        // Get coreLending
        address genericLoanManager = abi.decode(vm.parseJson(currentJson, ".coreLending.genericLoanManager"), (address));
        address flexibleLoanManager = abi.decode(vm.parseJson(currentJson, ".coreLending.flexibleLoanManager"), (address));
        address vaultBasedHandler = abi.decode(vm.parseJson(currentJson, ".coreLending.vaultBasedHandler"), (address));
        address mintableBurnableHandler = abi.decode(vm.parseJson(currentJson, ".coreLending.mintableBurnableHandler"), (address));
        address flexibleAssetHandler = abi.decode(vm.parseJson(currentJson, ".coreLending.flexibleAssetHandler"), (address));
        address riskCalculator = abi.decode(vm.parseJson(currentJson, ".coreLending.riskCalculator"), (address));
        
        // Create updated JSON with rewards section
        string memory updatedJson = string(abi.encodePacked(
            "{\n",
            '  "network": "', network, '",\n',
            '  "chainId": ', vm.toString(chainId), ',\n',
            '  "deployer": "', _addressToString(deployer), '",\n',
            '  "deploymentDate": "', vm.toString(deploymentDate), '",\n',
            '  "poolManager": "', _addressToString(poolManager), '",\n',
            '  "mockTokens": {\n',
            '    "ETH": "', _addressToString(ethToken), '",\n',
            '    "WBTC": "', _addressToString(wbtcToken), '",\n',
            '    "USDC": "', _addressToString(usdcToken), '"\n',
            '  },\n',
            '  "vcopCollateral": {\n',
            '    "vcopToken": "', _addressToString(vcopToken), '",\n',
            '    "oracle": "', _addressToString(oracle), '",\n',
            '    "priceCalculator": "', _addressToString(priceCalculator), '",\n',
            '    "collateralManager": "', _addressToString(collateralManager), '",\n',
            '    "hook": "', _addressToString(hook), '"\n',
            '  },\n',
            '  "coreLending": {\n',
            '    "genericLoanManager": "', _addressToString(genericLoanManager), '",\n',
            '    "flexibleLoanManager": "', _addressToString(flexibleLoanManager), '",\n',
            '    "vaultBasedHandler": "', _addressToString(vaultBasedHandler), '",\n',
            '    "mintableBurnableHandler": "', _addressToString(mintableBurnableHandler), '",\n',
            '    "flexibleAssetHandler": "', _addressToString(flexibleAssetHandler), '",\n',
            '    "riskCalculator": "', _addressToString(riskCalculator), '"\n',
            '  },\n',
            '  "rewards": {\n',
            '    "rewardDistributor": "', _addressToString(rewardDistributor), '"\n',
            '  }\n',
            '}'
        ));
        
        // Write updated JSON to file
        vm.writeFile("deployed-addresses.json", updatedJson);
        console.log("deployed-addresses.json updated with RewardDistributor:", _addressToString(rewardDistributor));
    }
    
    /**
     * @notice Convert address to string
     */
    function _addressToString(address addr) internal pure returns (string memory) {
        return vm.toString(addr);
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {RewardDistributor} from "../src/core/RewardDistributor.sol";
import {FlexibleLoanManager} from "../src/core/FlexibleLoanManager.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {VaultBasedHandler} from "../src/core/VaultBasedHandler.sol";
import {VCOPCollateralManager} from "../src/VcopCollateral/VCOPCollateralManager.sol";
import {VCOPCollateralized} from "../src/VcopCollateral/VCOPCollateralized.sol";

contract DeployRewardSystem is Script {
    
    // Pool IDs
    bytes32 constant FLEXIBLE_LOAN_POOL = keccak256("FLEXIBLE_LOAN_COLLATERAL");
    bytes32 constant GENERIC_LOAN_POOL = keccak256("GENERIC_LOAN_COLLATERAL");
    bytes32 constant VAULT_ETH_POOL = keccak256("VAULT_ETH_LIQUIDITY");
    bytes32 constant VAULT_WBTC_POOL = keccak256("VAULT_WBTC_LIQUIDITY");
    bytes32 constant VAULT_USDC_POOL = keccak256("VAULT_USDC_LIQUIDITY");
    bytes32 constant VCOP_COLLATERAL_POOL = keccak256("VCOP_COLLATERAL_DEPOSITS");
    
    // Reward rates (rewards per second, 18 decimals)
    uint256 constant FLEXIBLE_LOAN_RATE = 1e15; // 0.001 VCOP per second
    uint256 constant GENERIC_LOAN_RATE = 5e14;   // 0.0005 VCOP per second
    uint256 constant VAULT_ETH_RATE = 2e15;      // 0.002 VCOP per second
    uint256 constant VAULT_WBTC_RATE = 15e14;    // 0.0015 VCOP per second
    uint256 constant VAULT_USDC_RATE = 1e15;     // 0.001 VCOP per second
    uint256 constant VCOP_COLLATERAL_RATE = 5e14; // 0.0005 VCOP per second
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying Reward System with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy RewardDistributor
        RewardDistributor rewardDistributor = new RewardDistributor();
        console.log("RewardDistributor deployed at:", address(rewardDistributor));
        
        // 2. Get existing contract addresses (you'll need to update these)
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
        
        // 3. Set protocol components in RewardDistributor
        rewardDistributor.setProtocolComponents(
            vaultHandler,
            flexibleLoanManager,
            genericLoanManager,
            collateralManager
        );
        
        // 4. Authorize contracts to update stakes
        rewardDistributor.setAuthorizedUpdater(flexibleLoanManager, true);
        rewardDistributor.setAuthorizedUpdater(genericLoanManager, true);
        rewardDistributor.setAuthorizedUpdater(vaultHandler, true);
        rewardDistributor.setAuthorizedUpdater(collateralManager, true);
        
        // 5. Create reward pools
        console.log("Creating reward pools...");
        
        // Flexible Loan Collateral Pool
        rewardDistributor.createRewardPool(
            FLEXIBLE_LOAN_POOL,
            vcopToken,
            FLEXIBLE_LOAN_RATE
        );
        console.log("Created Flexible Loan Pool");
        
        // Generic Loan Collateral Pool
        rewardDistributor.createRewardPool(
            GENERIC_LOAN_POOL,
            vcopToken,
            GENERIC_LOAN_RATE
        );
        console.log("Created Generic Loan Pool");
        
        // Vault Liquidity Pools
        rewardDistributor.createRewardPool(
            VAULT_ETH_POOL,
            vcopToken,
            VAULT_ETH_RATE
        );
        console.log("Created Vault ETH Pool");
        
        rewardDistributor.createRewardPool(
            VAULT_WBTC_POOL,
            vcopToken,
            VAULT_WBTC_RATE
        );
        console.log("Created Vault WBTC Pool");
        
        rewardDistributor.createRewardPool(
            VAULT_USDC_POOL,
            vcopToken,
            VAULT_USDC_RATE
        );
        console.log("Created Vault USDC Pool");
        
        // VCOP Collateral Pool
        rewardDistributor.createRewardPool(
            VCOP_COLLATERAL_POOL,
            vcopToken,
            VCOP_COLLATERAL_RATE
        );
        console.log("Created VCOP Collateral Pool");
        
        // 6. Set RewardDistributor in existing contracts
        console.log("Setting RewardDistributor in existing contracts...");
        
        if (flexibleLoanManager != address(0)) {
            FlexibleLoanManager(flexibleLoanManager).setRewardDistributor(address(rewardDistributor));
            console.log("Set RewardDistributor in FlexibleLoanManager");
        }
        
        if (genericLoanManager != address(0)) {
            GenericLoanManager(genericLoanManager).setRewardDistributor(address(rewardDistributor));
            console.log("Set RewardDistributor in GenericLoanManager");
        }
        
        if (vaultHandler != address(0)) {
            VaultBasedHandler(vaultHandler).setRewardDistributor(address(rewardDistributor));
            console.log("Set RewardDistributor in VaultHandler");
        }
        
        if (collateralManager != address(0)) {
            VCOPCollateralManager(collateralManager).setRewardDistributor(address(rewardDistributor));
            console.log("Set RewardDistributor in CollateralManager");
        }
        
        // 7. Add initial rewards to pools (optional)
        uint256 initialRewardAmount = 1000000 * 1e6; // 1M VCOP tokens
        
        if (vcopToken != address(0)) {
            VCOPCollateralized vcop = VCOPCollateralized(vcopToken);
            
            // Mint rewards to deployer first
            vcop.mint(deployer, initialRewardAmount * 6); // 6 pools
            
            // Approve RewardDistributor to spend VCOP
            vcop.approve(address(rewardDistributor), initialRewardAmount * 6);
            
            // Add rewards to each pool
            rewardDistributor.addRewards(FLEXIBLE_LOAN_POOL, initialRewardAmount);
            rewardDistributor.addRewards(GENERIC_LOAN_POOL, initialRewardAmount);
            rewardDistributor.addRewards(VAULT_ETH_POOL, initialRewardAmount);
            rewardDistributor.addRewards(VAULT_WBTC_POOL, initialRewardAmount);
            rewardDistributor.addRewards(VAULT_USDC_POOL, initialRewardAmount);
            rewardDistributor.addRewards(VCOP_COLLATERAL_POOL, initialRewardAmount);
            
            console.log("Added initial rewards to all pools");
        }
        
        vm.stopBroadcast();
        
        // 8. Log deployment summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("RewardDistributor:", address(rewardDistributor));
        console.log("Total Pools Created: 6");
        console.log("Initial Rewards per Pool:", initialRewardAmount);
        console.log("Deployment completed successfully!");
        
        // 9. Save deployment info to file
        string memory deploymentInfo = string(abi.encodePacked(
            "REWARD_DISTRIBUTOR_ADDRESS=", vm.toString(address(rewardDistributor)), "\n",
            "FLEXIBLE_LOAN_POOL_ID=", vm.toString(FLEXIBLE_LOAN_POOL), "\n",
            "GENERIC_LOAN_POOL_ID=", vm.toString(GENERIC_LOAN_POOL), "\n",
            "VAULT_ETH_POOL_ID=", vm.toString(VAULT_ETH_POOL), "\n",
            "VAULT_WBTC_POOL_ID=", vm.toString(VAULT_WBTC_POOL), "\n",
            "VAULT_USDC_POOL_ID=", vm.toString(VAULT_USDC_POOL), "\n",
            "VCOP_COLLATERAL_POOL_ID=", vm.toString(VCOP_COLLATERAL_POOL), "\n"
        ));
        
        vm.writeFile("./deployments/reward-system.env", deploymentInfo);
        console.log("Deployment info saved to ./deployments/reward-system.env");
    }
} 
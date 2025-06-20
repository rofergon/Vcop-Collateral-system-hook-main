// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";

/**
 * @title ConfigureAssetHandlers
 * @notice Configures asset handlers in FlexibleLoanManager for mock tokens
 */
contract ConfigureAssetHandlers is Script {
    
    function run() external {
        console.log("CONFIGURING ASSET HANDLERS FOR MOCK TOKENS");
        console.log("==========================================");
        
        // Read addresses from JSON
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address flexibleAssetHandler = vm.parseJsonAddress(json, ".coreLending.flexibleAssetHandler");
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address mintableBurnableHandler = vm.parseJsonAddress(json, ".coreLending.mintableBurnableHandler");
        
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("FlexibleAssetHandler:", flexibleAssetHandler);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        
        vm.startBroadcast();
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        
        // Set asset handlers
        console.log("Setting asset handlers...");
        loanManager.setAssetHandler(IAssetHandler.AssetType.MINTABLE_BURNABLE, mintableBurnableHandler);
        loanManager.setAssetHandler(IAssetHandler.AssetType.VAULT_BASED, vaultBasedHandler);
        loanManager.setAssetHandler(IAssetHandler.AssetType.REBASING, flexibleAssetHandler);
        
        // Configure mock tokens in handlers
        console.log("Configuring mock tokens...");
        
        // Configure ETH as vault-based (external asset)
        VaultBasedHandler(vaultBasedHandler).configureAsset(
            mockETH,
            1300000, // 130% collateral ratio
            1100000, // 110% liquidation ratio  
            1000 * 1e18, // 1000 ETH max loan
            80000 // 8% interest rate
        );
        
        // Configure USDC as vault-based (for testing)
        VaultBasedHandler(vaultBasedHandler).configureAsset(
            mockUSDC,
            1100000, // 110% collateral ratio
            1050000, // 105% liquidation ratio
            1000000 * 1e6, // 1M USDC max loan
            40000 // 4% interest rate
        );
        
        // Configure WBTC as vault-based (external asset)
        VaultBasedHandler(vaultBasedHandler).configureAsset(
            mockWBTC,
            1400000, // 140% collateral ratio
            1150000, // 115% liquidation ratio
            50 * 1e8, // 50 BTC max loan
            75000 // 7.5% interest rate
        );
        
        // Provide initial liquidity to vault-based assets
        console.log("Providing initial liquidity...");
        
        // Mint tokens to provide liquidity
        (bool success, ) = mockETH.call(
            abi.encodeWithSignature("mint(address,uint256)", msg.sender, 100 * 1e18)
        );
        require(success, "Failed to mint ETH");
        
        (success, ) = mockWBTC.call(
            abi.encodeWithSignature("mint(address,uint256)", msg.sender, 10 * 1e8)
        );
        require(success, "Failed to mint WBTC");
        
        // Mint USDC for liquidity (THIS WAS MISSING!)
        (success, ) = mockUSDC.call(
            abi.encodeWithSignature("mint(address,uint256)", msg.sender, 1000000 * 1e6)
        );
        require(success, "Failed to mint USDC");
        
        // Approve and provide liquidity for all tokens
        (success, ) = mockETH.call(
            abi.encodeWithSignature("approve(address,uint256)", vaultBasedHandler, 50 * 1e18)
        );
        require(success, "Failed to approve ETH");
        
        VaultBasedHandler(vaultBasedHandler).provideLiquidity(mockETH, 50 * 1e18, msg.sender);
        
        (success, ) = mockWBTC.call(
            abi.encodeWithSignature("approve(address,uint256)", vaultBasedHandler, 5 * 1e8)
        );
        require(success, "Failed to approve WBTC");
        
        VaultBasedHandler(vaultBasedHandler).provideLiquidity(mockWBTC, 5 * 1e8, msg.sender);
        
        // Provide USDC liquidity (THIS WAS MISSING!)
        (success, ) = mockUSDC.call(
            abi.encodeWithSignature("approve(address,uint256)", vaultBasedHandler, 100000 * 1e6)
        );
        require(success, "Failed to approve USDC");
        
        VaultBasedHandler(vaultBasedHandler).provideLiquidity(mockUSDC, 100000 * 1e6, msg.sender);
        
        vm.stopBroadcast();
        
        console.log("Asset handlers configured successfully!");
        console.log("Mock tokens are now supported by FlexibleLoanManager");
    }
} 
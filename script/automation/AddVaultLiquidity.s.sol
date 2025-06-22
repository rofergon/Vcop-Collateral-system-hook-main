// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";

/**
 * @title AddVaultLiquidity
 * @notice Adds USDC liquidity to the vault for automated liquidations
 * @dev Simple script that doesn't depend on automation contracts being deployed
 */
contract AddVaultLiquidity is Script {
    
    // Addresses loaded from deployed-addresses-mock.json
    address public vaultBasedHandler;
    address public mockUSDC;
    
    // Liquidity configuration
    uint256 public constant REQUIRED_USDC_LIQUIDITY = 200000 * 1e6; // 200,000 USDC
    
    function run() external {
        console.log("=== ADDING VAULT LIQUIDITY FOR AUTOMATION ===");
        console.log("");
        
        loadAddresses();
        checkCurrentLiquidity();
        provideLiquidity();
        verifyLiquidity();
        
        console.log("=== VAULT LIQUIDITY ADDED SUCCESSFULLY ===");
    }
    
    function loadAddresses() internal {
        console.log("Step 1: Loading addresses from deployed-addresses-mock.json...");
        
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("MockUSDC:", mockUSDC);
        console.log("");
        
        require(vaultBasedHandler != address(0), "VaultBasedHandler not found!");
        require(mockUSDC != address(0), "MockUSDC not found!");
    }
    
    function checkCurrentLiquidity() internal view {
        console.log("Step 2: Checking current vault liquidity...");
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        // Check USDC balance in vault
        uint256 vaultBalance = IERC20(mockUSDC).balanceOf(vaultBasedHandler);
        console.log("Current vault USDC balance:", vaultBalance / 1e6, "USDC");
        
        // Check available liquidity for automation
        try vault.getAutomationLiquidityStatus(mockUSDC) returns (
            uint256 available, 
            uint256 liquidations, 
            uint256 recovered, 
            bool canLiquidate
        ) {
            console.log("Available for automation:", available / 1e6, "USDC");
            console.log("Total liquidations executed:", liquidations);
            console.log("Total recovered:", recovered / 1e6, "USDC");
            console.log("Can liquidate:", canLiquidate);
        } catch {
            console.log("Note: Automation functions not available yet (will be configured later)");
        }
        
        console.log("");
        
        if (vaultBalance < 50000 * 1e6) { // Less than 50k USDC
            console.log("WARNING: Insufficient liquidity for liquidations!");
        }
    }
    
    function provideLiquidity() internal {
        console.log("Step 3: Providing sufficient USDC liquidity...");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        IERC20 usdcToken = IERC20(mockUSDC);
        
        // Check deployer USDC balance
        uint256 deployerBalance = usdcToken.balanceOf(deployer);
        console.log("Deployer USDC balance:", deployerBalance / 1e6, "USDC");
        
        // Mint USDC if needed (works for mock tokens)
        if (deployerBalance < REQUIRED_USDC_LIQUIDITY) {
            uint256 toMint = REQUIRED_USDC_LIQUIDITY - deployerBalance + (100000 * 1e6); // Extra buffer
            console.log("Minting", toMint / 1e6, "USDC for liquidity...");
            
            (bool success, ) = mockUSDC.call(
                abi.encodeWithSignature("mint(address,uint256)", deployer, toMint)
            );
            require(success, "Failed to mint USDC");
            
            console.log("USDC minted successfully");
        }
        
        // Approve and provide liquidity
        console.log("Approving and providing", REQUIRED_USDC_LIQUIDITY / 1e6, "USDC liquidity...");
        
        usdcToken.approve(vaultBasedHandler, REQUIRED_USDC_LIQUIDITY);
        vault.provideLiquidity(mockUSDC, REQUIRED_USDC_LIQUIDITY, deployer);
        
        console.log("USDC liquidity provided successfully!");
        
        vm.stopBroadcast();
    }
    
    function verifyLiquidity() internal view {
        console.log("Step 4: Verifying liquidity provision...");
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        // Final vault balance
        uint256 finalBalance = IERC20(mockUSDC).balanceOf(vaultBasedHandler);
        console.log("Final vault USDC balance:", finalBalance / 1e6, "USDC");
        
        console.log("");
        
        if (finalBalance >= 50000 * 1e6) {
            console.log("SUCCESS: Vault has sufficient liquidity!");
            console.log("   - USDC balance:", finalBalance / 1e6, "USDC");
            console.log("   - Ready for automation configuration");
        } else {
            console.log("ISSUE: Vault still has insufficient liquidity");
            console.log("   - Current balance:", finalBalance / 1e6, "USDC");
            console.log("   - Minimum required: 50,000 USDC");
        }
        
        console.log("");
        console.log("NOTE: Automation authorization will be configured after automation deployment");
    }
} 
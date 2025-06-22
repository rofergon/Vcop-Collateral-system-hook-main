// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";

/**
 * @title ConfigureVaultLiquidity
 * @notice Ensures vault has sufficient USDC liquidity for automated liquidations
 * @dev This script fixes the "ERC20InsufficientAllowance" problem
 */
contract ConfigureVaultLiquidity is Script {
    
    // Addresses loaded from deployed-addresses-mock.json
    address public vaultBasedHandler;
    address public mockUSDC;
    address public automationKeeper;
    
    // Liquidity configuration
    uint256 public constant REQUIRED_USDC_LIQUIDITY = 200000 * 1e6; // 200,000 USDC
    
    function run() external {
        console.log("=== CONFIGURING VAULT LIQUIDITY FOR AUTOMATION ===");
        console.log("");
        
        loadAddresses();
        checkCurrentLiquidity();
        provideLiquidity();
        verifyConfiguration();
        
        console.log("=== VAULT LIQUIDITY CONFIGURATION COMPLETED ===");
    }
    
    function loadAddresses() internal {
        console.log("Step 1: Loading addresses from deployed-addresses-mock.json...");
        
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        // Try to load automation keeper address, but don't fail if it doesn't exist
        try vm.parseJsonAddress(json, ".automation.automationKeeper") returns (address keeper) {
            automationKeeper = keeper;
            console.log("AutomationKeeper found:", automationKeeper);
        } catch {
            console.log("AutomationKeeper not found in JSON - will skip authorization");
            automationKeeper = address(0);
        }
        
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
        (uint256 available, uint256 liquidations, uint256 recovered, bool canLiquidate) = 
            vault.getAutomationLiquidityStatus(mockUSDC);
            
        console.log("Available for automation:", available / 1e6, "USDC");
        console.log("Total liquidations executed:", liquidations);
        console.log("Total recovered:", recovered / 1e6, "USDC");
        console.log("Can liquidate:", canLiquidate);
        
        // Check authorization only if automationKeeper exists
        if (automationKeeper != address(0)) {
            bool isAuthorized = vault.authorizedAutomationContracts(automationKeeper);
            console.log("AutomationKeeper authorized:", isAuthorized);
            
            if (!isAuthorized) {
                console.log("WARNING: AutomationKeeper not authorized!");
            }
        } else {
            console.log("AutomationKeeper not available - skipping authorization check");
        }
        
        console.log("");
        
        if (available < 50000 * 1e6) { // Less than 50k USDC
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
        
        // Authorize AutomationKeeper if it exists and not already authorized
        if (automationKeeper != address(0)) {
            bool isAuthorized = vault.authorizedAutomationContracts(automationKeeper);
            if (!isAuthorized) {
                console.log("Authorizing AutomationKeeper...");
                vault.authorizeAutomationContract(automationKeeper);
                console.log("AutomationKeeper authorized!");
            } else {
                console.log("AutomationKeeper already authorized");
            }
        } else {
            console.log("AutomationKeeper not available - skipping authorization");
        }
        
        vm.stopBroadcast();
    }
    
    function verifyConfiguration() internal view {
        console.log("Step 4: Verifying final configuration...");
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        // Check final liquidity status
        (uint256 available, , , bool canLiquidate) = vault.getAutomationLiquidityStatus(mockUSDC);
        
        console.log("FINAL STATUS:");
        console.log("=============");
        console.log("Available USDC for automation:", available / 1e6, "USDC");
        console.log("Can liquidate:", canLiquidate);
        
        if (automationKeeper != address(0)) {
            console.log("AutomationKeeper authorized:", vault.authorizedAutomationContracts(automationKeeper));
        } else {
            console.log("AutomationKeeper: Not configured (will be set up later)");
        }
        
        // Final vault balance
        uint256 finalBalance = IERC20(mockUSDC).balanceOf(vaultBasedHandler);
        console.log("Final vault USDC balance:", finalBalance / 1e6, "USDC");
        
        console.log("");
        
        if (available >= 50000 * 1e6 && canLiquidate) {
            console.log("SUCCESS: Vault ready for automated liquidations!");
            console.log("   - Sufficient USDC liquidity (>50k)");
            if (automationKeeper != address(0)) {
                console.log("   - AutomationKeeper authorized");
            } else {
                console.log("   - AutomationKeeper will be authorized after deployment");
            }
            console.log("   - Liquidations enabled");
        } else {
            console.log("ISSUE: Vault not properly configured");
            if (available < 50000 * 1e6) {
                console.log("   - Insufficient liquidity");
            }
            if (!canLiquidate) {
                console.log("   - Liquidations disabled");
            }
        }
        
        console.log("");
        console.log("NEXT STEPS:");
        console.log("1. Deploy automation: make deploy-automation-complete-mock-no-test");
        console.log("2. Create test positions: make create-test-positions");
        console.log("3. Crash prices: make crash-prices");
        console.log("4. Register/Update Chainlink upkeep with correct CheckData");
        console.log("5. Monitor: https://automation.chain.link/base-sepolia");
    }
} 
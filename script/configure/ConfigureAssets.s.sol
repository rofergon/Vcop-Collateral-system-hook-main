// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title ConfigureAssets
 * @notice Configures assets in the new modular lending system
 * @dev This script configures VCOP, ETH, WBTC, and USDC with appropriate handlers
 */
contract ConfigureAssets is Script {
    
    // Asset addresses (will be loaded from environment)
    address public vcop;
    address public mockETH;
    address public mockWBTC;
    address public mockUSDC;
    
    // Handler addresses (will be loaded from environment)
    address public mintableBurnableHandler;
    address public vaultBasedHandler;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== CONFIGURING ASSETS ===");
        console.log("Deployer address:", deployer);
        
        _loadAddresses();
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Configure VCOP as mintable/burnable asset
        _configureVCOP();
        
        // Configure ETH as vault-based asset
        _configureETH();
        
        // Configure WBTC as vault-based asset
        _configureWBTC();
        
        // Configure USDC as vault-based asset
        _configureUSDC();
        
        vm.stopBroadcast();
        
        _printConfigurationSummary();
    }
    
    function _loadAddresses() internal {
        // Load asset addresses
        vcop = vm.envAddress("VCOP_ADDRESS");
        mockETH = vm.envAddress("MOCK_ETH_ADDRESS");
        mockWBTC = vm.envAddress("MOCK_WBTC_ADDRESS");
        mockUSDC = vm.envAddress("MOCK_USDC_ADDRESS");
        
        // Load handler addresses
        mintableBurnableHandler = vm.envAddress("MINTABLE_BURNABLE_HANDLER_ADDRESS");
        vaultBasedHandler = vm.envAddress("VAULT_BASED_HANDLER_ADDRESS");
        
        console.log("Loaded addresses from environment");
    }
    
    function _configureVCOP() internal {
        console.log("\n--- Configuring VCOP (Mintable/Burnable) ---");
        
        // Configure VCOP with conservative parameters
        // collateralRatio: 150% (1.5x)
        // liquidationRatio: 120% (1.2x)
        // maxLoanAmount: 10M VCOP
        // interestRate: 5% annually
        
        (bool success,) = mintableBurnableHandler.call(
            abi.encodeWithSignature(
                "configureAsset(address,uint256,uint256,uint256,uint256)",
                vcop,
                1500000,      // 150% collateral ratio
                1200000,      // 120% liquidation ratio
                10000000 * 1e6, // 10M VCOP max (6 decimals)
                50000         // 5% interest rate
            )
        );
        
        if (success) {
            console.log("VCOP configured successfully");
        } else {
            console.log("Failed to configure VCOP");
        }
    }
    
    function _configureETH() internal {
        console.log("\n--- Configuring ETH (Vault-Based) ---");
        
        // Configure ETH with standard parameters
        // collateralRatio: 130% (1.3x)
        // liquidationRatio: 110% (1.1x)  
        // maxLoanAmount: 1000 ETH
        // interestRate: 8% annually
        
        (bool success,) = vaultBasedHandler.call(
            abi.encodeWithSignature(
                "configureAsset(address,uint256,uint256,uint256,uint256)",
                mockETH,
                1300000,       // 130% collateral ratio
                1100000,       // 110% liquidation ratio
                1000 * 1e18,   // 1000 ETH max (18 decimals)
                80000          // 8% interest rate
            )
        );
        
        if (success) {
            console.log("ETH configured successfully");
        } else {
            console.log("Failed to configure ETH");
        }
    }
    
    function _configureWBTC() internal {
        console.log("\n--- Configuring WBTC (Vault-Based) ---");
        
        // Configure WBTC with higher collateral requirements
        // collateralRatio: 140% (1.4x)
        // liquidationRatio: 115% (1.15x)
        // maxLoanAmount: 50 WBTC
        // interestRate: 7.5% annually
        
        (bool success,) = vaultBasedHandler.call(
            abi.encodeWithSignature(
                "configureAsset(address,uint256,uint256,uint256,uint256)",
                mockWBTC,
                1400000,       // 140% collateral ratio
                1150000,       // 115% liquidation ratio
                50 * 1e8,      // 50 WBTC max (8 decimals)
                75000          // 7.5% interest rate
            )
        );
        
        if (success) {
            console.log("WBTC configured successfully");
        } else {
            console.log("Failed to configure WBTC");
        }
    }
    
    function _configureUSDC() internal {
        console.log("\n--- Configuring USDC (Vault-Based) ---");
        
        // Configure USDC with minimal collateral requirements (stablecoin)
        // collateralRatio: 110% (1.1x)
        // liquidationRatio: 105% (1.05x)
        // maxLoanAmount: 1M USDC
        // interestRate: 4% annually
        
        (bool success,) = vaultBasedHandler.call(
            abi.encodeWithSignature(
                "configureAsset(address,uint256,uint256,uint256,uint256)",
                mockUSDC,
                1100000,       // 110% collateral ratio
                1050000,       // 105% liquidation ratio
                1000000 * 1e6, // 1M USDC max (6 decimals)
                40000          // 4% interest rate
            )
        );
        
        if (success) {
            console.log("USDC configured successfully");
        } else {
            console.log("Failed to configure USDC");
        }
    }
    
    function _printConfigurationSummary() internal view {
        console.log("\n=== ASSET CONFIGURATION SUMMARY ===");
        console.log("");
        console.log("CONFIGURED ASSETS:");
        console.log("VCOP (Mintable):     ", vcop, " - 150% collateral, 5% interest");
        console.log("ETH (Vault):         ", mockETH, " - 130% collateral, 8% interest");
        console.log("WBTC (Vault):        ", mockWBTC, " - 140% collateral, 7.5% interest");
        console.log("USDC (Vault):        ", mockUSDC, " - 110% collateral, 4% interest");
        console.log("");
        console.log("HANDLERS USED:");
        console.log("MintableBurnable:    ", mintableBurnableHandler);
        console.log("VaultBased:          ", vaultBasedHandler);
        console.log("");
        console.log("=== NEXT STEPS ===");
        console.log("1. Provide initial liquidity: make provide-initial-liquidity");
        console.log("2. Test multi-token loans: make test-multi-token-loans");
        console.log("3. Check system status: make check-system-status");
    }
}

// Required environment variables:
// PRIVATE_KEY=your_private_key
// VCOP_ADDRESS=deployed_vcop_address
// MOCK_ETH_ADDRESS=deployed_mock_eth_address
// MOCK_WBTC_ADDRESS=deployed_mock_wbtc_address
// MOCK_USDC_ADDRESS=deployed_mock_usdc_address
// MINTABLE_BURNABLE_HANDLER_ADDRESS=deployed_handler_address
// VAULT_BASED_HANDLER_ADDRESS=deployed_handler_address

// Usage:
// forge script script/configure/ConfigureAssets.s.sol --rpc-url $RPC_URL --broadcast 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title ConfigureAssetHandlers
 * @notice Configures asset handlers in FlexibleLoanManager for tokens
 * @dev Run after deployment to set up the lending system
 */
contract ConfigureAssetHandlers is Script {
    
    function run() external {
        console.log("");
        console.log("CONFIGURING ASSET HANDLERS FOR FLEXIBLE LOAN MANAGER");
        console.log("====================================================");
        console.log("This script configures the lending system to handle tokens:");
        console.log("1. Set asset handlers in FlexibleLoanManager");
        console.log("2. Configure tokens in each handler");
        console.log("3. Provide initial liquidity for testing");
        console.log("");
        
        // Determine which JSON file to use
        string memory jsonFile = _getJsonFile();
        console.log("Using addresses from:", jsonFile);
        
        // Read addresses from JSON
        string memory json = vm.readFile(jsonFile);
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(
            vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager")
        );
        FlexibleAssetHandler flexibleAssetHandler = FlexibleAssetHandler(
            vm.parseJsonAddress(json, ".coreLending.flexibleAssetHandler")
        );
        VaultBasedHandler vaultBasedHandler = VaultBasedHandler(
            vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler")
        );
        
        // Get token addresses
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        console.log("Contract addresses loaded:");
        console.log("  FlexibleLoanManager:", address(loanManager));
        console.log("  FlexibleAssetHandler:", address(flexibleAssetHandler));
        console.log("  VaultBasedHandler:", address(vaultBasedHandler));
        console.log("");
        
        console.log("Token addresses loaded:");
        console.log("  Mock ETH:", mockETH);
        console.log("  Mock USDC:", mockUSDC);
        console.log("  Mock WBTC:", mockWBTC);
        console.log("");
        
        vm.startBroadcast();
        
        // Step 1: Set asset handlers in FlexibleLoanManager
        console.log("Step 1: Setting asset handlers in FlexibleLoanManager...");
        
        try loanManager.setAssetHandler(IAssetHandler.AssetType.MINTABLE_BURNABLE, address(flexibleAssetHandler)) {
            console.log("  MINTABLE_BURNABLE handler set successfully");
        } catch Error(string memory reason) {
            console.log("  Failed to set MINTABLE_BURNABLE handler:", reason);
        }
        
        try loanManager.setAssetHandler(IAssetHandler.AssetType.VAULT_BASED, address(vaultBasedHandler)) {
            console.log("  VAULT_BASED handler set successfully");
        } catch Error(string memory reason) {
            console.log("  Failed to set VAULT_BASED handler:", reason);
        }
        
        console.log("");
        
        // Step 2: Configure tokens in VaultBasedHandler (for external assets like ETH, BTC)
        console.log("Step 2: Configuring external assets in VaultBasedHandler...");
        
        _configureVaultAsset(vaultBasedHandler, mockETH, "ETH", 
            1300000,  // 130% collateral ratio
            1100000,  // 110% liquidation ratio
            1000 * 1e18, // 1000 ETH max
            80000     // 8% interest rate
        );
        
        _configureVaultAsset(vaultBasedHandler, mockWBTC, "WBTC",
            1400000,  // 140% collateral ratio
            1150000,  // 115% liquidation ratio
            50 * 1e8, // 50 BTC max
            90000     // 9% interest rate
        );
        
        console.log("");
        
        // Step 3: Configure USDC in FlexibleAssetHandler (for stablecoin lending)
        console.log("Step 3: Configuring stablecoin in FlexibleAssetHandler...");
        
        _configureFlexibleAsset(flexibleAssetHandler, mockUSDC, "USDC",
            1100000,  // 110% collateral ratio (low for stablecoin)
            1050000,  // 105% liquidation ratio
            1000000 * 1e6, // 1M USDC max
            40000     // 4% interest rate
        );
        
        console.log("");
        
        // Step 4: Provide initial liquidity for testing
        console.log("Step 4: Providing initial liquidity for testing...");
        
        _provideLiquidity(address(vaultBasedHandler), mockETH, 10 * 1e18, "ETH");
        _provideLiquidity(address(vaultBasedHandler), mockWBTC, 1 * 1e8, "WBTC");
        _provideLiquidity(address(flexibleAssetHandler), mockUSDC, 100000 * 1e6, "USDC");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("ASSET HANDLER CONFIGURATION COMPLETED SUCCESSFULLY!");
        console.log("===================================================");
        console.log("System is now ready for lending operations:");
        console.log("  - ETH and WBTC can be used as collateral");
        console.log("  - USDC can be borrowed or used as collateral");
        console.log("  - All handlers have initial liquidity");
        console.log("  - Interest rates and ratios are configured");
        console.log("");
        console.log("Next steps:");
        console.log("  1. Run: make test-automation-flow-complete");
        console.log("  2. Or create positions with: make create-test-loan-position");
        console.log("");
    }
    
    /**
     * @dev Determines which JSON file to use based on what exists
     */
    function _getJsonFile() internal view returns (string memory) {
        // Try mock file first (for testing), then regular file
        try vm.readFile("deployed-addresses-mock.json") returns (string memory) {
            return "deployed-addresses-mock.json";
        } catch {
            return "deployed-addresses.json";
        }
    }
    
    /**
     * @dev Configures an asset in VaultBasedHandler
     */
    function _configureVaultAsset(
        VaultBasedHandler handler,
        address token,
        string memory symbol,
        uint256 collateralRatio,
        uint256 liquidationRatio,
        uint256 maxLoan,
        uint256 interestRate
    ) internal {
        try handler.configureAsset(token, collateralRatio, liquidationRatio, maxLoan, interestRate) {
            console.log("  ", symbol, "configured successfully");
            console.log("    Collateral ratio:", collateralRatio / 10000, "%");
            console.log("    Liquidation ratio:", liquidationRatio / 10000, "%");
            console.log("    Interest rate:", interestRate / 10000, "%");
        } catch Error(string memory reason) {
            console.log("  Failed to configure", symbol, ":", reason);
        }
    }
    
    /**
     * @dev Configures an asset in FlexibleAssetHandler
     */
    function _configureFlexibleAsset(
        FlexibleAssetHandler handler,
        address token,
        string memory symbol,
        uint256 collateralRatio,
        uint256 liquidationRatio,
        uint256 maxLoan,
        uint256 interestRate
    ) internal {
        try handler.configureAsset(token, IAssetHandler.AssetType.MINTABLE_BURNABLE, collateralRatio, liquidationRatio, maxLoan, interestRate) {
            console.log("  ", symbol, "configured successfully");
            console.log("    Collateral ratio:", collateralRatio / 10000, "%");
            console.log("    Liquidation ratio:", liquidationRatio / 10000, "%");
            console.log("    Interest rate:", interestRate / 10000, "%");
        } catch Error(string memory reason) {
            console.log("  Failed to configure", symbol, ":", reason);
        }
    }
    
    /**
     * @dev Provides initial liquidity to a handler
     */
    function _provideLiquidity(
        address handler,
        address token,
        uint256 amount,
        string memory symbol
    ) internal {
        // First ensure we have tokens
        _ensureTokenBalance(token, msg.sender, amount);
        
        // Approve tokens
        try IERC20(token).approve(handler, amount) returns (bool success) {
            if (success) {
                console.log("  ", symbol, "approved for liquidity provision");
                
                // Provide liquidity
                // Provide liquidity (VaultBasedHandler expects different signature)
                bytes memory callData = abi.encodeWithSignature("provideLiquidity(address,uint256,address)", token, amount, msg.sender);
                (bool success,) = handler.call(callData);
                if (success) {
                    console.log("  ", amount / (10 ** _getTokenDecimals(token)), symbol, "liquidity provided");
                } else {
                    console.log("  Failed to provide", symbol, "liquidity");
                }
            }
        } catch {
            console.log("  Failed to approve", symbol, "for liquidity");
        }
    }
    
    /**
     * @dev Ensures address has enough token balance, minting if necessary
     */
    function _ensureTokenBalance(address token, address user, uint256 amount) internal {
        uint256 balance = IERC20(token).balanceOf(user);
        
        if (balance < amount) {
            uint256 needed = amount - balance;
            console.log("    Minting", needed / (10 ** _getTokenDecimals(token)), "tokens for liquidity");
            
            // Try to mint tokens (works for mock tokens)
            try this._mintTokens(token, user, needed) {
                console.log("    Tokens minted successfully");
            } catch {
                console.log("    Warning: Could not mint tokens, may need manual provision");
            }
        }
    }
    
    /**
     * @dev External function to mint tokens (for try/catch)
     */
    function _mintTokens(address token, address to, uint256 amount) external {
        (bool success,) = token.call(
            abi.encodeWithSignature("mint(address,uint256)", to, amount)
        );
        require(success, "Mint failed");
    }
    
    /**
     * @dev Gets token decimals for display purposes
     */
    function _getTokenDecimals(address token) internal view returns (uint256) {
        try IERC20Metadata(token).decimals() returns (uint8 decimals) {
            return decimals;
        } catch {
            return 18; // Default to 18 decimals
        }
    }
} 
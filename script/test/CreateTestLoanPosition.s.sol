// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {GenericLoanManager} from "../../src/core/GenericLoanManager.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Interface for mintable tokens
interface IMintable {
    function mint(address to, uint256 amount) external;
}

/**
 * @title CreateTestLoanPosition
 * @notice Creates a test loan position for liquidation testing
 * @dev Reads addresses dynamically from environment variables set by Makefile
 *      Automatically mints required tokens and provides liquidity
 */
contract CreateTestLoanPosition is Script {
    
    // These will be set via environment variables by the Makefile
    address public loanManager;
    address public collateralToken;  // ETH
    address public loanToken;       // USDC
    
    // Test amounts
    uint256 public constant COLLATERAL_AMOUNT = 1 ether;        // 1 ETH as collateral
    uint256 public constant LOAN_AMOUNT = 1500 * 1e6;          // 1500 USDC (6 decimals)
    uint256 public constant INTEREST_RATE = 50000;             // 5% annual interest
    uint256 public constant MAX_LTV = 800000;                  // 80% max LTV
    
    // Extra amounts for liquidity provision and testing
    uint256 public constant EXTRA_COLLATERAL_MINT = 10 ether;   // Extra ETH for testing
    uint256 public constant EXTRA_LOAN_MINT = 100000 * 1e6;    // Extra USDC for liquidity
    
    function run() external {
        // Read addresses from environment variables
        loanManager = vm.envAddress("LOAN_MANAGER_ADDRESS");
        collateralToken = vm.envAddress("COLLATERAL_TOKEN_ADDRESS");
        loanToken = vm.envAddress("LOAN_TOKEN_ADDRESS");
        
        console.log("=== Creating Test Loan Position ===");
        console.log("Loan Manager:", loanManager);
        console.log("Collateral Token (ETH):", collateralToken);
        console.log("Loan Token (USDC):", loanToken);
        console.log("Collateral Amount:", COLLATERAL_AMOUNT);
        console.log("Loan Amount:", LOAN_AMOUNT);
        
        vm.startBroadcast();
        
        // Step 1: Auto-mint required tokens
        console.log("\n=== Step 1: Minting Required Tokens ===");
        mintRequiredTokens();
        
        // Step 2: Provide liquidity for loan tokens if needed
        console.log("\n=== Step 2: Ensuring Liquidity Availability ===");
        ensureLoanTokenLiquidity();
        
        // Step 3: Create the loan position
        console.log("\n=== Step 3: Creating Loan Position ===");
        uint256 positionId = createLoanPosition();
        
        vm.stopBroadcast();
        
        console.log("\n=== Loan Position Created Successfully! ===");
        console.log("Position ID:", positionId);
        console.log("Borrower:", msg.sender);
        
        // Get position details for verification
        ILoanManager loanMgr = ILoanManager(loanManager);
        ILoanManager.LoanPosition memory position = loanMgr.getPosition(positionId);
        
        console.log("\n=== Position Details ===");
        console.log("Borrower:", position.borrower);
        console.log("Collateral Asset:", position.collateralAsset);
        console.log("Loan Asset:", position.loanAsset);
        console.log("Collateral Amount:", position.collateralAmount);
        console.log("Loan Amount:", position.loanAmount);
        console.log("Interest Rate:", position.interestRate);
        console.log("Is Active:", position.isActive);
        
        // Check if position can be liquidated (should be false initially)
        bool canLiquidate = loanMgr.canLiquidate(positionId);
        console.log("Can liquidate (should be false):", canLiquidate);
        
        // Get collateralization ratio
        uint256 ratio = loanMgr.getCollateralizationRatio(positionId);
        console.log("Collateralization Ratio:", ratio);
        
                 console.log("\n=== Next Steps ===");
         console.log("1. Run 'make liquidate-test-position POSITION_ID=", positionId, "' to configure ratios and liquidate");
         console.log("2. Position should be safe initially (ratio > 150%)");
         console.log("3. Liquidation test will set ratios to 200% to make it liquidatable");
    }
    
    /**
     * @dev Mints required tokens for testing
     */
    function mintRequiredTokens() internal {
        address deployer = msg.sender;
        
        // Check current balances
        IERC20 collateral = IERC20(collateralToken);
        IERC20 loan = IERC20(loanToken);
        
        uint256 currentCollateralBalance = collateral.balanceOf(deployer);
        uint256 currentLoanBalance = loan.balanceOf(deployer);
        
        console.log("Current ETH balance:", currentCollateralBalance);
        console.log("Current USDC balance:", currentLoanBalance);
        
        // Mint collateral tokens (ETH) if needed
        uint256 requiredCollateral = COLLATERAL_AMOUNT + EXTRA_COLLATERAL_MINT;
        if (currentCollateralBalance < requiredCollateral) {
            uint256 toMint = requiredCollateral - currentCollateralBalance;
            console.log("Minting", toMint, "ETH tokens...");
            
                         try IMintable(collateralToken).mint(deployer, toMint) {
                 console.log("Successfully minted", toMint, "ETH tokens");
             } catch Error(string memory reason) {
                 console.log("Failed to mint ETH tokens:", reason);
                 revert("Failed to mint collateral tokens");
             }
         } else {
             console.log("Sufficient ETH balance available");
         }
        
        // Mint loan tokens (USDC) for liquidity provision
        uint256 requiredLoan = LOAN_AMOUNT + EXTRA_LOAN_MINT;
        if (currentLoanBalance < requiredLoan) {
            uint256 toMint = requiredLoan - currentLoanBalance;
            console.log("Minting", toMint, "USDC tokens for liquidity...");
            
                         try IMintable(loanToken).mint(deployer, toMint) {
                 console.log("Successfully minted", toMint, "USDC tokens");
             } catch Error(string memory reason) {
                 console.log("Failed to mint USDC tokens:", reason);
                 revert("Failed to mint loan tokens");
             }
         } else {
             console.log("Sufficient USDC balance available");
         }
        
        // Verify final balances
        uint256 finalCollateralBalance = collateral.balanceOf(deployer);
        uint256 finalLoanBalance = loan.balanceOf(deployer);
        
        console.log("Final ETH balance:", finalCollateralBalance);
        console.log("Final USDC balance:", finalLoanBalance);
        
        require(finalCollateralBalance >= COLLATERAL_AMOUNT, "Insufficient collateral balance after minting");
        require(finalLoanBalance >= LOAN_AMOUNT, "Insufficient loan token balance after minting");
    }
    
    /**
     * @dev Ensures loan token liquidity is available in the asset handler
     */
    function ensureLoanTokenLiquidity() internal {
        // Get the asset handler for the loan token
        IAssetHandler loanHandler = _getAssetHandler(loanToken);
        
        console.log("Loan asset handler:", address(loanHandler));
        
        // Check available liquidity
        uint256 availableLiquidity = loanHandler.getAvailableLiquidity(loanToken);
        console.log("Current available liquidity:", availableLiquidity);
        
        if (availableLiquidity < LOAN_AMOUNT) {
            uint256 liquidityNeeded = LOAN_AMOUNT - availableLiquidity + (50000 * 1e6); // Extra 50k USDC buffer
            console.log("Need to provide", liquidityNeeded, "additional liquidity");
            
            // Check asset type to determine how to provide liquidity
            IAssetHandler.AssetType assetType = loanHandler.getAssetType(loanToken);
            
            if (assetType == IAssetHandler.AssetType.VAULT_BASED) {
                console.log("Providing liquidity to vault-based handler...");
                
                // Approve and provide liquidity
                IERC20(loanToken).approve(address(loanHandler), liquidityNeeded);
                loanHandler.provideLiquidity(loanToken, liquidityNeeded, msg.sender);
                
                                 console.log("Provided", liquidityNeeded, "liquidity to vault");
             } else if (assetType == IAssetHandler.AssetType.MINTABLE_BURNABLE) {
                 console.log("Mintable/burnable asset - liquidity handled automatically");
             } else {
                 console.log("Unknown asset type, checking if liquidity is sufficient...");
             }
         } else {
             console.log("Sufficient liquidity available");
         }
        
        // Verify liquidity after provision
        uint256 finalLiquidity = loanHandler.getAvailableLiquidity(loanToken);
        console.log("Final available liquidity:", finalLiquidity);
        
        require(finalLiquidity >= LOAN_AMOUNT, "Insufficient liquidity for loan");
    }
    
    /**
     * @dev Creates the loan position
     */
    function createLoanPosition() internal returns (uint256 positionId) {
        // Verify we have enough collateral tokens
        IERC20 collateral = IERC20(collateralToken);
        uint256 balance = collateral.balanceOf(msg.sender);
        
        console.log("Verifying collateral balance:", balance);
        require(balance >= COLLATERAL_AMOUNT, "Insufficient collateral balance");
        
        // Approve collateral transfer
        console.log("Approving collateral transfer...");
        collateral.approve(loanManager, COLLATERAL_AMOUNT);
        
        // Create loan terms
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: collateralToken,
            loanAsset: loanToken,
            collateralAmount: COLLATERAL_AMOUNT,
            loanAmount: LOAN_AMOUNT,
            maxLoanToValue: MAX_LTV,
            interestRate: INTEREST_RATE,
            duration: 0  // 0 = perpetual loan
        });
        
        // Create the loan
        console.log("Creating loan position...");
        ILoanManager loanMgr = ILoanManager(loanManager);
        positionId = loanMgr.createLoan(terms);
        
                 console.log("Loan position created with ID:", positionId);
        return positionId;
    }
    
    /**
     * @dev Gets asset handler for a given asset
     */
    function _getAssetHandler(address asset) internal view returns (IAssetHandler) {
        // Try to get from loan manager (both Generic and Flexible have this pattern)
        try this._getAssetHandlerFromLoanManager(asset) returns (IAssetHandler handler) {
            return handler;
        } catch {
            revert("No handler found for asset");
        }
    }
    
    /**
     * @dev External function to get asset handler (for try-catch)
     */
    function _getAssetHandlerFromLoanManager(address asset) external view returns (IAssetHandler) {
        // Try each asset type to find the correct handler
        
        // First, check if it's a GenericLoanManager
        try GenericLoanManager(loanManager).assetHandlers(IAssetHandler.AssetType.VAULT_BASED) returns (address handler1) {
            if (handler1 != address(0)) {
                IAssetHandler h1 = IAssetHandler(handler1);
                if (h1.isAssetSupported(asset)) {
                    return h1;
                }
            }
        } catch {}
        
        try GenericLoanManager(loanManager).assetHandlers(IAssetHandler.AssetType.MINTABLE_BURNABLE) returns (address handler2) {
            if (handler2 != address(0)) {
                IAssetHandler h2 = IAssetHandler(handler2);
                if (h2.isAssetSupported(asset)) {
                    return h2;
                }
            }
        } catch {}
        
        // If GenericLoanManager doesn't work, try FlexibleLoanManager
        try FlexibleLoanManager(loanManager).assetHandlers(IAssetHandler.AssetType.VAULT_BASED) returns (address handler3) {
            if (handler3 != address(0)) {
                IAssetHandler h3 = IAssetHandler(handler3);
                if (h3.isAssetSupported(asset)) {
                    return h3;
                }
            }
        } catch {}
        
        try FlexibleLoanManager(loanManager).assetHandlers(IAssetHandler.AssetType.MINTABLE_BURNABLE) returns (address handler4) {
            if (handler4 != address(0)) {
                IAssetHandler h4 = IAssetHandler(handler4);
                if (h4.isAssetSupported(asset)) {
                    return h4;
                }
            }
        } catch {}
        
        revert("No compatible asset handler found");
    }
    
    /**
     * @dev Helper function to check balances without transaction
     */
    function checkBalances() external view {
        address deployer = msg.sender;
        
        console.log("=== Current Token Balances ===");
        console.log("Deployer:", deployer);
        
        // Check ETH balance
        IERC20 eth = IERC20(collateralToken);
        uint256 ethBalance = eth.balanceOf(deployer);
        console.log("ETH balance:", ethBalance);
        console.log("ETH needed for loan:", COLLATERAL_AMOUNT);
        console.log("ETH sufficient:", ethBalance >= COLLATERAL_AMOUNT);
        
        // Check USDC balance
        IERC20 usdc = IERC20(loanToken);
        uint256 usdcBalance = usdc.balanceOf(deployer);
        console.log("USDC balance:", usdcBalance);
        
        console.log("=== Liquidity Check ===");
        // Get available liquidity (this requires the handler to be configured)
        try this._getAssetHandlerFromLoanManager(loanToken) returns (IAssetHandler handler) {
            uint256 availableLiquidity = handler.getAvailableLiquidity(loanToken);
            console.log("Available loan liquidity:", availableLiquidity);
            console.log("Loan amount needed:", LOAN_AMOUNT);
            console.log("Liquidity sufficient:", availableLiquidity >= LOAN_AMOUNT);
        } catch {
            console.log("Could not check liquidity - handler not configured yet");
        }
    }

    /**
     * @dev Creates a custom loan position with specified amounts for automation testing
     */
    function createCustomPosition() external {
        // Read addresses from environment variables
        loanManager = vm.envAddress("LOAN_MANAGER_ADDRESS");
        collateralToken = vm.envAddress("COLLATERAL_TOKEN_ADDRESS");
        loanToken = vm.envAddress("LOAN_TOKEN_ADDRESS");
        
        // Read custom amounts from environment variables
        uint256 customCollateralAmount = vm.envUint("TEST_COLLATERAL_AMOUNT");
        uint256 customLoanAmount = vm.envUint("TEST_LOAN_AMOUNT");
        
        console.log("=== Creating Custom Test Loan Position ===");
        console.log("Loan Manager:", loanManager);
        console.log("Collateral Token (ETH):", collateralToken);
        console.log("Loan Token (USDC):", loanToken);
        console.log("Custom Collateral Amount:", customCollateralAmount);
        console.log("Custom Loan Amount:", customLoanAmount);
        
        vm.startBroadcast();
        
        // Step 1: Auto-mint required tokens
        console.log("\n=== Step 1: Minting Required Tokens ===");
        mintCustomTokens(customCollateralAmount, customLoanAmount);
        
        // Step 2: Provide liquidity for loan tokens if needed
        console.log("\n=== Step 2: Ensuring Liquidity Availability ===");
        ensureCustomLoanTokenLiquidity(customLoanAmount);
        
        // Step 3: Create the loan position
        console.log("\n=== Step 3: Creating Custom Loan Position ===");
        uint256 positionId = createCustomLoanPosition(customCollateralAmount, customLoanAmount);
        
        vm.stopBroadcast();
        
        console.log("\n=== Custom Loan Position Created Successfully! ===");
        console.log("Position ID:", positionId);
        console.log("Borrower:", msg.sender);
        
        // Get position details for verification
        ILoanManager loanMgr = ILoanManager(loanManager);
        ILoanManager.LoanPosition memory position = loanMgr.getPosition(positionId);
        
        console.log("\n=== Position Details ===");
        console.log("Borrower:", position.borrower);
        console.log("Collateral Asset:", position.collateralAsset);
        console.log("Loan Asset:", position.loanAsset);
        console.log("Collateral Amount:", position.collateralAmount);
        console.log("Loan Amount:", position.loanAmount);
        console.log("Interest Rate:", position.interestRate);
        console.log("Is Active:", position.isActive);
        
        // Check if position can be liquidated (should be false initially)
        bool canLiquidate = loanMgr.canLiquidate(positionId);
        console.log("Can liquidate (should be false):", canLiquidate);
        
        // Get collateralization ratio
        uint256 ratio = loanMgr.getCollateralizationRatio(positionId);
        console.log("Collateralization Ratio:", ratio);
        
        console.log("\n=== Custom Position Ready for Automation Testing ===");
    }

    /**
     * @dev Mints custom amounts of tokens for testing
     */
    function mintCustomTokens(uint256 collateralAmount, uint256 loanAmount) internal {
        address deployer = msg.sender;
        
        // Check current balances
        IERC20 collateral = IERC20(collateralToken);
        IERC20 loan = IERC20(loanToken);
        
        uint256 currentCollateralBalance = collateral.balanceOf(deployer);
        uint256 currentLoanBalance = loan.balanceOf(deployer);
        
        console.log("Current ETH balance:", currentCollateralBalance);
        console.log("Current USDC balance:", currentLoanBalance);
        
        // Mint collateral tokens (ETH) if needed
        uint256 requiredCollateral = collateralAmount + EXTRA_COLLATERAL_MINT;
        if (currentCollateralBalance < requiredCollateral) {
            uint256 toMint = requiredCollateral - currentCollateralBalance;
            console.log("Minting", toMint, "ETH tokens...");
            
            try IMintable(collateralToken).mint(deployer, toMint) {
                console.log("Successfully minted", toMint, "ETH tokens");
            } catch Error(string memory reason) {
                console.log("Failed to mint ETH tokens:", reason);
                revert("Failed to mint collateral tokens");
            }
        } else {
            console.log("Sufficient ETH balance available");
        }
        
        // Mint loan tokens (USDC) for liquidity provision
        uint256 requiredLoan = loanAmount + EXTRA_LOAN_MINT;
        if (currentLoanBalance < requiredLoan) {
            uint256 toMint = requiredLoan - currentLoanBalance;
            console.log("Minting", toMint, "USDC tokens for liquidity...");
            
            try IMintable(loanToken).mint(deployer, toMint) {
                console.log("Successfully minted", toMint, "USDC tokens");
            } catch Error(string memory reason) {
                console.log("Failed to mint USDC tokens:", reason);
                revert("Failed to mint loan tokens");
            }
        } else {
            console.log("Sufficient USDC balance available");
        }
        
        // Verify final balances
        uint256 finalCollateralBalance = collateral.balanceOf(deployer);
        uint256 finalLoanBalance = loan.balanceOf(deployer);
        
        console.log("Final ETH balance:", finalCollateralBalance);
        console.log("Final USDC balance:", finalLoanBalance);
        
        require(finalCollateralBalance >= collateralAmount, "Insufficient collateral balance after minting");
        require(finalLoanBalance >= loanAmount, "Insufficient loan token balance after minting");
    }

    /**
     * @dev Ensures custom loan token liquidity is available
     */
    function ensureCustomLoanTokenLiquidity(uint256 loanAmount) internal {
        // Get the asset handler for the loan token
        IAssetHandler loanHandler = _getAssetHandler(loanToken);
        
        console.log("Loan asset handler:", address(loanHandler));
        
        // Check available liquidity
        uint256 availableLiquidity = loanHandler.getAvailableLiquidity(loanToken);
        console.log("Current available liquidity:", availableLiquidity);
        
        if (availableLiquidity < loanAmount) {
            uint256 liquidityNeeded = loanAmount - availableLiquidity + (50000 * 1e6); // Extra 50k USDC buffer
            console.log("Need to provide", liquidityNeeded, "additional liquidity");
            
            // Check asset type to determine how to provide liquidity
            IAssetHandler.AssetType assetType = loanHandler.getAssetType(loanToken);
            
            if (assetType == IAssetHandler.AssetType.VAULT_BASED) {
                console.log("Providing liquidity to vault-based handler...");
                
                // Approve and provide liquidity
                IERC20(loanToken).approve(address(loanHandler), liquidityNeeded);
                loanHandler.provideLiquidity(loanToken, liquidityNeeded, msg.sender);
                
                console.log("Provided", liquidityNeeded, "liquidity to vault");
            } else if (assetType == IAssetHandler.AssetType.MINTABLE_BURNABLE) {
                console.log("Mintable/burnable asset - liquidity handled automatically");
            } else {
                console.log("Unknown asset type, checking if liquidity is sufficient...");
            }
        } else {
            console.log("Sufficient liquidity available");
        }
        
        // Verify liquidity after provision
        uint256 finalLiquidity = loanHandler.getAvailableLiquidity(loanToken);
        console.log("Final available liquidity:", finalLiquidity);
        
        require(finalLiquidity >= loanAmount, "Insufficient liquidity for loan");
    }

    /**
     * @dev Creates a custom loan position with specified amounts
     */
    function createCustomLoanPosition(uint256 collateralAmount, uint256 loanAmount) internal returns (uint256) {
        IERC20 collateral = IERC20(collateralToken);
        
        // Approve collateral for the loan manager
        console.log("Approving", collateralAmount, "collateral tokens...");
        collateral.approve(loanManager, collateralAmount);
        
        // Create the loan position
        console.log("Creating loan position...");
        uint256 positionId;
        
        // Create loan terms struct
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: collateralToken,
            loanAsset: loanToken,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: MAX_LTV,
            interestRate: INTEREST_RATE,
            duration: 0  // Perpetual loan
        });

        // Use FlexibleLoanManager interface
        try FlexibleLoanManager(loanManager).createLoan(terms) returns (uint256 id) {
            positionId = id;
            console.log("Position created successfully with ID:", positionId);
        } catch Error(string memory reason) {
            console.log("Failed to create position:", reason);
            revert("Failed to create loan position");
        } catch {
            console.log("Failed to create position: unknown error");
            revert("Failed to create loan position");
        }
        
        return positionId;
    }
} 
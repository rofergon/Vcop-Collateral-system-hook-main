// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {GenericLoanManager} from "../../src/core/GenericLoanManager.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title LiquidateTestPosition
 * @notice Configures ratios and liquidate a test position
 * @dev Reads addresses dynamically and auto-detects the correct asset handler
 */
contract LiquidateTestPosition is Script {
    
    // These will be set via environment variables by the Makefile
    address public loanManager;
    address public flexibleAssetHandler;
    address public vaultBasedHandler;
    address public collateralToken;  // ETH
    address public loanToken;       // USDC
    
    // Auto-detected handler
    address public activeAssetHandler;
    
    // Position to liquidate (can be set via environment or parameter)
    uint256 public positionId;
    
    // Liquidation configuration
    uint256 public constant HIGH_LIQUIDATION_RATIO = 2000000;  // 200% - makes most positions liquidatable
    uint256 public constant HIGH_COLLATERAL_RATIO = 2500000;   // 250% - higher than liquidation for testing
    uint256 public constant NORMAL_LIQUIDATION_RATIO = 1200000; // 120% - normal ratio
    uint256 public constant NORMAL_COLLATERAL_RATIO = 1500000;  // 150% - normal ratio
    
    function run() external {
        // Read addresses from environment variables
        loanManager = vm.envAddress("LOAN_MANAGER_ADDRESS");
        flexibleAssetHandler = vm.envAddress("FLEXIBLE_ASSET_HANDLER_ADDRESS");
        vaultBasedHandler = vm.envAddress("VAULT_BASED_HANDLER_ADDRESS");
        collateralToken = vm.envAddress("COLLATERAL_TOKEN_ADDRESS");
        loanToken = vm.envAddress("LOAN_TOKEN_ADDRESS");
        
        // Try to read position ID from environment, default to 1
        try vm.envUint("POSITION_ID") returns (uint256 envPositionId) {
            positionId = envPositionId;
        } catch {
            positionId = 1; // Default to position 1
        }
        
        console.log("=== Liquidating Test Position ===");
        console.log("Loan Manager:", loanManager);
        console.log("Flexible Asset Handler:", flexibleAssetHandler);
        console.log("Vault Based Handler:", vaultBasedHandler);
        console.log("Collateral Token (ETH):", collateralToken);
        console.log("Loan Token (USDC):", loanToken);
        console.log("Position ID:", positionId);
        
        // Step 0: Auto-detect which asset handler manages our collateral
        detectAssetHandler();
        
        // Step 1: Check current position status
        checkPositionStatus();
        
        // Step 2: Configure ratios to make position liquidatable
        configureForLiquidation();
        
        // Step 3: Verify position is now liquidatable
        verifyLiquidatable();
        
        // Step 4: Execute liquidation
        executeLiquidation();
        
        // Step 5: Reset ratios to normal
        resetRatios();
        
        console.log("Liquidation test completed successfully!");
    }
    
    function detectAssetHandler() internal {
        console.log("\n=== Step 0: Auto-detecting Asset Handler ===");
        
        // Check FlexibleAssetHandler first
        try IAssetHandler(flexibleAssetHandler).isAssetSupported(collateralToken) returns (bool isSupported) {
            if (isSupported) {
                activeAssetHandler = flexibleAssetHandler;
                console.log("Detected: FlexibleAssetHandler manages this token");
                console.log("Active Handler:", activeAssetHandler);
                return;
            }
        } catch {
            console.log("FlexibleAssetHandler check failed");
        }
        
        // Check VaultBasedHandler
        try IAssetHandler(vaultBasedHandler).isAssetSupported(collateralToken) returns (bool isSupported) {
            if (isSupported) {
                activeAssetHandler = vaultBasedHandler;
                console.log("Detected: VaultBasedHandler manages this token");
                console.log("Active Handler:", activeAssetHandler);
                return;
            }
        } catch {
            console.log("VaultBasedHandler check failed");
        }
        
        revert("No asset handler found for collateral token");
    }
    
    function checkPositionStatus() internal view {
        console.log("\n=== Step 1: Checking Position Status ===");
        
        ILoanManager loanMgr = ILoanManager(loanManager);
        
        // Check if position exists and is active
        ILoanManager.LoanPosition memory position = loanMgr.getPosition(positionId);
        require(position.isActive, "Position is not active");
        
        console.log("Position Details:");
        console.log("  Borrower:", position.borrower);
        console.log("  Collateral Asset:", position.collateralAsset);
        console.log("  Loan Asset:", position.loanAsset);
        console.log("  Collateral Amount:", position.collateralAmount);
        console.log("  Loan Amount:", position.loanAmount);
        console.log("  Interest Rate:", position.interestRate);
        console.log("  Is Active:", position.isActive);
        
        // Check current liquidation status
        bool canLiquidate = loanMgr.canLiquidate(positionId);
        uint256 ratio = loanMgr.getCollateralizationRatio(positionId);
        uint256 totalDebt = loanMgr.getTotalDebt(positionId);
        
        console.log("Current Status:");
        console.log("  Can liquidate:", canLiquidate);
        console.log("  Collateralization ratio:", ratio);
        console.log("  Total debt:", totalDebt);
        
        // Check current asset handler configuration
        IAssetHandler.AssetConfig memory config = IAssetHandler(activeAssetHandler).getAssetConfig(position.collateralAsset);
        
        console.log("Current Asset Handler Config:");
        console.log("  Collateral Ratio:", config.collateralRatio);
        console.log("  Liquidation Ratio:", config.liquidationRatio);
        console.log("  Is Active:", config.isActive);
    }
    
    function configureForLiquidation() internal {
        console.log("\n=== Step 2: Configuring for Liquidation ===");
        
        vm.startBroadcast();
        
        console.log("Setting liquidation ratio to 200% to make position liquidatable...");
        
        // Set both ratios safely to enable liquidation
        if (activeAssetHandler == flexibleAssetHandler) {
            console.log("Using FlexibleAssetHandler...");
            FlexibleAssetHandler(activeAssetHandler).updateEnforcedRatios(
                collateralToken, 
                HIGH_COLLATERAL_RATIO,  // 250% collateral ratio (higher than liquidation)
                HIGH_LIQUIDATION_RATIO  // 200% liquidation ratio
            );
        } else if (activeAssetHandler == vaultBasedHandler) {
            console.log("Using VaultBasedHandler...");
            VaultBasedHandler(activeAssetHandler).updateBothRatios(
                collateralToken, 
                HIGH_COLLATERAL_RATIO,  // 250% collateral ratio (higher than liquidation)
                HIGH_LIQUIDATION_RATIO  // 200% liquidation ratio
            );
        } else {
            revert("Unknown asset handler type");
        }
        
        console.log("Liquidation ratio updated to 200%");
        
        vm.stopBroadcast();
    }
    
    function verifyLiquidatable() internal view {
        console.log("\n=== Step 3: Verifying Position is Liquidatable ===");
        
        ILoanManager loanMgr = ILoanManager(loanManager);
        
        // Check liquidation status after ratio change
        bool canLiquidate = loanMgr.canLiquidate(positionId);
        uint256 ratio = loanMgr.getCollateralizationRatio(positionId);
        
        console.log("After ratio adjustment:");
        console.log("  Can liquidate:", canLiquidate);
        console.log("  Collateralization ratio:", ratio);
        
        require(canLiquidate, "Position should be liquidatable after ratio adjustment");
        console.log("Position is now liquidatable!");
    }
    
    function executeLiquidation() internal {
        console.log("\n=== Step 4: Executing Liquidation ===");
        
        ILoanManager loanMgr = ILoanManager(loanManager);
        ILoanManager.LoanPosition memory position = loanMgr.getPosition(positionId);
        
        // Get debt amount for repayment
        uint256 totalDebt = loanMgr.getTotalDebt(positionId);
        console.log("Total debt to repay:", totalDebt);
        
        vm.startBroadcast();
        
        // Ensure liquidator has enough loan tokens to repay the debt
        IERC20 loanTokenContract = IERC20(position.loanAsset);
        uint256 liquidatorBalance = loanTokenContract.balanceOf(msg.sender);
        console.log("Liquidator balance:", liquidatorBalance);
        
        if (liquidatorBalance < totalDebt) {
            console.log("WARNING: Liquidator has insufficient balance");
            console.log("Required:", totalDebt);
            console.log("Available:", liquidatorBalance);
            // For testing, we might need to mint tokens or use a different approach
        }
        
        // CRITICAL FIX: Need to approve the asset handler, not the loan manager
        // The liquidation process calls handler.repay() which does transferFrom directly
        
        // First, get the correct asset handler for the loan token
        IAssetHandler loanAssetHandler;
        if (IAssetHandler(flexibleAssetHandler).isAssetSupported(position.loanAsset)) {
            loanAssetHandler = IAssetHandler(flexibleAssetHandler);
            console.log("Loan asset managed by FlexibleAssetHandler");
        } else if (IAssetHandler(vaultBasedHandler).isAssetSupported(position.loanAsset)) {
            loanAssetHandler = IAssetHandler(vaultBasedHandler);
            console.log("Loan asset managed by VaultBasedHandler");
        } else {
            revert("No asset handler found for loan asset");
        }
        
        // Approve token transfer to the correct asset handler with buffer for interest
        address handlerAddress = address(loanAssetHandler);
        uint256 approvalAmount = totalDebt + 1000; // Add small buffer for interest accrual
        loanTokenContract.approve(handlerAddress, approvalAmount);
        console.log("Approved token transfer to asset handler:", handlerAddress);
        console.log("Approved amount (with buffer):", approvalAmount);
        
        // Execute liquidation
        console.log("Executing liquidation...");
        loanMgr.liquidatePosition(positionId);
        
        console.log("Liquidation executed successfully!");
        
        vm.stopBroadcast();
        
        // Verify position is now closed
        ILoanManager.LoanPosition memory updatedPosition = loanMgr.getPosition(positionId);
        console.log("Position active after liquidation:", updatedPosition.isActive);
    }
    
    function resetRatios() internal {
        console.log("\n=== Step 5: Resetting Ratios to Normal ===");
        
        vm.startBroadcast();
        
        console.log("Resetting to safe ratios (150% collateral, 120% liquidation)...");
        
        // Reset to normal, safe ratios - using standardized function
        if (activeAssetHandler == flexibleAssetHandler) {
            console.log("Using FlexibleAssetHandler...");
            FlexibleAssetHandler handler = FlexibleAssetHandler(activeAssetHandler);
            handler.updateEnforcedRatios(
                collateralToken, 
                NORMAL_COLLATERAL_RATIO,  // 150% collateral ratio
                NORMAL_LIQUIDATION_RATIO  // 120% liquidation ratio
            );
        } else if (activeAssetHandler == vaultBasedHandler) {
            console.log("Using VaultBasedHandler...");
            VaultBasedHandler handler = VaultBasedHandler(activeAssetHandler);
            handler.updateEnforcedRatios(  // Now using standardized function
                collateralToken, 
                NORMAL_COLLATERAL_RATIO,  // 150% collateral ratio
                NORMAL_LIQUIDATION_RATIO  // 120% liquidation ratio
            );
        } else {
            revert("Unknown asset handler type");
        }
        
        console.log("Ratios reset to normal values");
        
        vm.stopBroadcast();
        
        // Verify the reset
        IAssetHandler.AssetConfig memory config = IAssetHandler(activeAssetHandler).getAssetConfig(collateralToken);
        console.log("New ratios:");
        console.log("  Collateral Ratio:", config.collateralRatio);
        console.log("  Liquidation Ratio:", config.liquidationRatio);
    }
    
    /**
     * @dev Helper function to liquidate a specific position ID
     */
    function liquidateSpecificPosition(uint256 _positionId) external {
        positionId = _positionId;
        
        // Read addresses from environment
        loanManager = vm.envAddress("LOAN_MANAGER_ADDRESS");
        flexibleAssetHandler = vm.envAddress("FLEXIBLE_ASSET_HANDLER_ADDRESS");
        vaultBasedHandler = vm.envAddress("VAULT_BASED_HANDLER_ADDRESS");
        collateralToken = vm.envAddress("COLLATERAL_TOKEN_ADDRESS");
        loanToken = vm.envAddress("LOAN_TOKEN_ADDRESS");
        
        console.log("Liquidating specific position:", _positionId);
        
        // Execute the full liquidation flow
        checkPositionStatus();
        configureForLiquidation();
        verifyLiquidatable();
        executeLiquidation();
        resetRatios();
    }
    
    /**
     * @dev Emergency function to just configure ratios without liquidating
     */
    function justConfigureRatios() external {
        loanManager = vm.envAddress("LOAN_MANAGER_ADDRESS");
        flexibleAssetHandler = vm.envAddress("FLEXIBLE_ASSET_HANDLER_ADDRESS");
        vaultBasedHandler = vm.envAddress("VAULT_BASED_HANDLER_ADDRESS");
        collateralToken = vm.envAddress("COLLATERAL_TOKEN_ADDRESS");
        
        console.log("Configuring ratios for liquidation testing...");
        
        vm.startBroadcast();
        
        console.log("Setting liquidation ratio to 200% to make position liquidatable...");
        
        // Set both ratios safely to enable liquidation
        if (activeAssetHandler == flexibleAssetHandler) {
            console.log("Using FlexibleAssetHandler...");
            FlexibleAssetHandler(activeAssetHandler).updateEnforcedRatios(
                collateralToken, 
                HIGH_COLLATERAL_RATIO,  // 250% collateral ratio
                HIGH_LIQUIDATION_RATIO  // 200% liquidation ratio
            );
        } else if (activeAssetHandler == vaultBasedHandler) {
            console.log("Using VaultBasedHandler...");
            VaultBasedHandler(activeAssetHandler).updateBothRatios(
                collateralToken, 
                HIGH_COLLATERAL_RATIO,  // 250% collateral ratio
                HIGH_LIQUIDATION_RATIO  // 200% liquidation ratio
            );
        } else {
            revert("Unknown asset handler type");
        }
        
        console.log("Liquidation ratio set to 200% - positions should now be liquidatable");
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev Emergency function to reset ratios only
     */
    function justResetRatios() external {
        flexibleAssetHandler = vm.envAddress("FLEXIBLE_ASSET_HANDLER_ADDRESS");
        vaultBasedHandler = vm.envAddress("VAULT_BASED_HANDLER_ADDRESS");
        collateralToken = vm.envAddress("COLLATERAL_TOKEN_ADDRESS");
        
        console.log("Resetting ratios to normal...");
        
        vm.startBroadcast();
        
        console.log("Resetting to safe ratios (150% collateral, 120% liquidation)...");
        
        // Reset to normal, safe ratios
        if (activeAssetHandler == flexibleAssetHandler) {
            console.log("Using FlexibleAssetHandler...");
            FlexibleAssetHandler handler = FlexibleAssetHandler(activeAssetHandler);
            handler.updateEnforcedRatios(
                collateralToken, 
                NORMAL_COLLATERAL_RATIO,  // 150% collateral ratio
                NORMAL_LIQUIDATION_RATIO  // 120% liquidation ratio
            );
        } else if (activeAssetHandler == vaultBasedHandler) {
            console.log("Using VaultBasedHandler...");
            VaultBasedHandler handler = VaultBasedHandler(activeAssetHandler);
            handler.updateBothRatios(
                collateralToken, 
                NORMAL_COLLATERAL_RATIO,  // 150% collateral ratio
                NORMAL_LIQUIDATION_RATIO  // 120% liquidation ratio
            );
        } else {
            revert("Unknown asset handler type");
        }
        
        console.log("Ratios reset to normal");
        
        vm.stopBroadcast();
    }
} 
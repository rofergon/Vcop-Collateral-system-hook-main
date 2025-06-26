// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";
import {GenericLoanManager} from "../../src/core/GenericLoanManager.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";

/**
 * @title TestLiquidationRatios
 * @notice Practical example of how to configure ratios for liquidation testing
 * @dev This script shows the complete workflow for testing liquidations
 */
contract TestLiquidationRatios is Script {
    
    // Example deployed addresses (replace with your actual addresses)
    address constant FLEXIBLE_ASSET_HANDLER = 0x1234567890123456789012345678901234567890;
    address constant LOAN_MANAGER = 0x2345678901234567890123456789012345678901;
    
    // Example token addresses (replace with your actual token addresses)
    address constant MOCK_ETH = 0xca09D6c5f9f5646A20b5EF71986EED5f8A86add0;
    address constant MOCK_USDC = 0xAdc9649EF0468d6C73B56Dc96fF6bb527B8251A0;
    address constant MOCK_WBTC = 0x6C2AAf9cFb130d516401Ee769074F02fae6ACb91;
    
    function run() external {
        console.log("=== Testing Liquidation Ratios ===");
        console.log("This script demonstrates the liquidation ratio management workflow");
    }
    
    /**
     * @dev Step 1: Check current ratios before making changes
     */
    function step1_checkCurrentRatios() external view {
        console.log("\n=== STEP 1: Current Ratios ===");
        
        FlexibleAssetHandler handler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
        
        address[] memory tokens = new address[](3);
        tokens[0] = MOCK_ETH;
        tokens[1] = MOCK_USDC; 
        tokens[2] = MOCK_WBTC;
        
        for (uint i = 0; i < tokens.length; i++) {
            IAssetHandler.AssetConfig memory config = handler.getAssetConfig(tokens[i]);
            console.log("Token:", tokens[i]);
            console.log("  Collateral Ratio:", config.collateralRatio);
            console.log("  Liquidation Ratio:", config.liquidationRatio);
            console.log("  Is Active:", config.isActive);
            console.log("");
        }
    }
    
    /**
     * @dev Step 2: Make positions liquidatable for testing
     */
    function step2_enableLiquidationTesting() external {
        console.log("\n=== STEP 2: Enabling Liquidation Testing ===");
        
        vm.startBroadcast();
        
        FlexibleAssetHandler handler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
        
        // Set high liquidation ratios to make existing positions liquidatable
        // Most collateralized positions are around 150-180%, so setting to 200% makes them liquidatable
        
        console.log("Setting liquidation ratio to 200% for all tokens...");
        
        handler.adjustLiquidationRatio(MOCK_ETH, 2000000);   // 200%
        handler.adjustLiquidationRatio(MOCK_USDC, 2000000);  // 200%
        handler.adjustLiquidationRatio(MOCK_WBTC, 2000000);  // 200%
        
        console.log("All tokens configured for liquidation testing!");
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev Step 3: Test liquidation on specific position
     */
    function step3_testLiquidation(uint256 positionId) external view {
        console.log("\n=== STEP 3: Testing Position", positionId, "===");
        
        GenericLoanManager loanManager = GenericLoanManager(LOAN_MANAGER);
        
        // Check if position can be liquidated
        bool canLiquidate = loanManager.canLiquidate(positionId);
        console.log("Can liquidate position:", canLiquidate);
        
        // Get position details
        GenericLoanManager.LoanPosition memory position = loanManager.getPosition(positionId);
        console.log("Borrower:", position.borrower);
        console.log("Collateral Asset:", position.collateralAsset);
        console.log("Loan Asset:", position.loanAsset);
        console.log("Collateral Amount:", position.collateralAmount);
        console.log("Loan Amount:", position.loanAmount);
        console.log("Is Active:", position.isActive);
        
        // Get collateralization ratio
        uint256 ratio = loanManager.getCollateralizationRatio(positionId);
        console.log("Current Collateralization Ratio:", ratio);
        
        // Get total debt
        uint256 totalDebt = loanManager.getTotalDebt(positionId);
        console.log("Total Debt (principal + interest):", totalDebt);
    }
    
    /**
     * @dev Step 4: Reset ratios to normal after testing
     */
    function step4_resetToNormalRatios() external {
        console.log("\n=== STEP 4: Resetting to Normal Ratios ===");
        
        vm.startBroadcast();
        
        FlexibleAssetHandler handler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
        
        console.log("Resetting to conservative ratios...");
        
        // Reset to safe ratios: 150% collateral, 120% liquidation
        handler.updateEnforcedRatios(MOCK_ETH, 1500000, 1200000);   // 150% / 120%
        handler.updateEnforcedRatios(MOCK_USDC, 1500000, 1200000);  // 150% / 120%
        handler.updateEnforcedRatios(MOCK_WBTC, 1500000, 1200000);  // 150% / 120%
        
        console.log("All ratios reset to normal values!");
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev Advanced: Set custom ratios for specific testing scenarios
     */
    function advancedSetCustomRatios(
        address token,
        uint256 collateralRatio,
        uint256 liquidationRatio
    ) external {
        console.log("\n=== ADVANCED: Setting Custom Ratios ===");
        console.log("Token:", token);
        console.log("Collateral Ratio:", collateralRatio);
        console.log("Liquidation Ratio:", liquidationRatio);
        
        vm.startBroadcast();
        
        FlexibleAssetHandler handler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
        handler.updateEnforcedRatios(token, collateralRatio, liquidationRatio);
        
        console.log("Custom ratios set successfully!");
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev Emergency function to make specific positions liquidatable instantly
     */
    function emergencyMakePositionLiquidatable(address collateralToken) external {
        console.log("\n=== EMERGENCY: Making Positions Liquidatable ===");
        console.log("Collateral Token:", collateralToken);
        
        vm.startBroadcast();
        
        FlexibleAssetHandler handler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
        
        // Set liquidation ratio to 300% - virtually all positions will be liquidatable
        handler.emergencySetLiquidationRatio(collateralToken, 3000000); // 300%
        
        console.log("EMERGENCY: Liquidation ratio set to 300% - all positions liquidatable!");
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev Helper function to get all user positions and their liquidation status
     */
    function checkUserPositions(address user) external view {
        console.log("\n=== Checking User Positions ===");
        console.log("User:", user);
        
        GenericLoanManager loanManager = GenericLoanManager(LOAN_MANAGER);
        uint256[] memory positions = loanManager.getUserPositions(user);
        
        console.log("Total positions:", positions.length);
        
        for (uint i = 0; i < positions.length; i++) {
            uint256 positionId = positions[i];
            bool canLiquidate = loanManager.canLiquidate(positionId);
            uint256 ratio = loanManager.getCollateralizationRatio(positionId);
            
            console.log("Position", positionId, ":");
            console.log("  Can liquidate:", canLiquidate);
            console.log("  Ratio:", ratio);
            console.log("");
        }
    }
}

/**
 * USAGE EXAMPLES:
 * 
 * 1. Check current ratios:
 *    forge script script/test/TestLiquidationRatios.s.sol:TestLiquidationRatios --sig "step1_checkCurrentRatios()" --rpc-url $RPC_URL
 * 
 * 2. Enable liquidation testing:
 *    forge script script/test/TestLiquidationRatios.s.sol:TestLiquidationRatios --sig "step2_enableLiquidationTesting()" --rpc-url $RPC_URL --broadcast
 * 
 * 3. Test specific position:
 *    forge script script/test/TestLiquidationRatios.s.sol:TestLiquidationRatios --sig "step3_testLiquidation(uint256)" 1 --rpc-url $RPC_URL
 * 
 * 4. Reset to normal ratios:
 *    forge script script/test/TestLiquidationRatios.s.sol:TestLiquidationRatios --sig "step4_resetToNormalRatios()" --rpc-url $RPC_URL --broadcast
 * 
 * 5. Emergency liquidation mode:
 *    forge script script/test/TestLiquidationRatios.s.sol:TestLiquidationRatios --sig "emergencyMakePositionLiquidatable(address)" <TOKEN_ADDRESS> --rpc-url $RPC_URL --broadcast
 */ 
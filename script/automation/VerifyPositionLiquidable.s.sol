// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title VerifyPositionLiquidable
 * @notice Verifica si la posición crasheada es liquidable y puede activar automation
 */
contract VerifyPositionLiquidable is Script {
    
    uint256 constant POSITION_ID = 3; // Position created by avalanche-quick-test
    
    function run() external view {
        console.log("=== VERIFICATION: POSITION LIQUIDABLE & AUTOMATION READY ===");
        console.log("");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        address mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        MockVCOPOracle oracle = MockVCOPOracle(mockOracle);
        
        console.log("DEPLOYED CONTRACTS:");
        console.log("===================");
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.log("MockOracle:", mockOracle);
        console.log("");
        
        // ========== 1. VERIFY POSITION EXISTS ==========
        console.log("1. VERIFYING POSITION EXISTS");
        console.log("============================");
        
        try loanManager.getPosition(POSITION_ID) returns (ILoanManager.LoanPosition memory position) {
            console.log("Position ID:", POSITION_ID);
            console.log("Borrower:", position.borrower);
            console.log("Collateral Asset:", position.collateralAsset);
            console.log("Loan Asset:", position.loanAsset);
            console.log("Collateral Amount:", position.collateralAmount / 1e18, "ETH");
            console.log("Loan Amount:", position.loanAmount / 1e6, "USDC");
            console.log("Is Active:", position.isActive ? "YES" : "NO");
            console.log("");
        } catch {
            console.log("ERROR: Position", POSITION_ID, "does not exist!");
            return;
        }
        
        // ========== 2. CHECK CURRENT MARKET PRICES ==========
        console.log("2. CURRENT MARKET PRICES");
        console.log("========================");
        
        uint256 ethPrice = oracle.getPrice(mockETH, mockUSDC);
        uint256 usdcPrice = oracle.getPrice(mockUSDC, mockUSDC);
        
        console.log("ETH Price: $", ethPrice / 1e6);
        console.log("USDC Price: $", usdcPrice / 1e6);
        console.log("");
        
        // ========== 3. CHECK COLLATERALIZATION RATIO ==========
        console.log("3. COLLATERALIZATION ANALYSIS");
        console.log("==============================");
        
        uint256 ratio = loanManager.getCollateralizationRatio(POSITION_ID);
        console.log("Current Ratio:", ratio / 1e4, "%");
        console.log("Liquidation Threshold: 150%");
        console.log("Is Under-collateralized:", (ratio < 1500000) ? "YES (LIQUIDABLE)" : "NO (SAFE)");
        console.log("");
        
        // ========== 4. CHECK DIRECT LIQUIDATION ==========
        console.log("4. DIRECT LIQUIDATION CHECK");
        console.log("============================");
        
        bool canLiquidate = loanManager.canLiquidate(POSITION_ID);
        console.log("Can Liquidate Directly:", canLiquidate ? "YES" : "NO");
        console.log("");
        
        // ========== 5. CHECK AUTOMATION ADAPTER ==========
        console.log("5. AUTOMATION ADAPTER STATUS");
        console.log("=============================");
        
        try adapter.isPositionAtRisk(POSITION_ID) returns (bool isAtRisk, uint256 riskLevel) {
            console.log("Position At Risk:", isAtRisk ? "YES" : "NO");
            console.log("Risk Level:", riskLevel);
        } catch {
            console.log("Could not check risk through adapter");
        }
        
        try adapter.isPositionTracked(POSITION_ID) returns (bool isTracked) {
            console.log("Position Tracked:", isTracked ? "YES" : "NO");
        } catch {
            console.log("Could not check if position is tracked");
        }
        
        console.log("");
        
        // ========== 6. TEST AUTOMATION KEEPER ==========
        console.log("6. AUTOMATION KEEPER TESTING");
        console.log("=============================");
        
        // Generate checkData
        bytes memory checkData = keeper.generateOptimizedCheckData(
            loanAdapter,  // Use adapter
            0,           // startIndex 
            25           // batchSize
        );
        
        console.log("Generated CheckData Length:", checkData.length);
        
        // Test checkUpkeep
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("Upkeep Needed:", upkeepNeeded ? "YES (AUTOMATION SHOULD TRIGGER)" : "NO");
            console.log("PerformData Length:", performData.length);
            
            if (upkeepNeeded && performData.length > 0) {
                console.log("");
                console.log("SUCCESS: AUTOMATION SHOULD TRIGGER!");
                console.log("Chainlink nodes should detect this position and execute performUpkeep");
                
                // Try to decode performData to see what would be liquidated
                try this.decodePerformData(performData) returns (
                    address targetLoanManager,
                    uint256[] memory positionIds,
                    uint256[] memory liquidationAmounts,
                    uint256 totalAmount
                ) {
                    console.log("");
                    console.log("PERFORMDATA DETAILS:");
                    console.log("Target Loan Manager:", targetLoanManager);
                    console.log("Positions to Liquidate:", positionIds.length);
                    
                    for (uint256 i = 0; i < positionIds.length && i < 5; i++) {
                        console.log("  Position", i + 1, "ID:", positionIds[i]);
                        console.log("  Liquidation Amount:", liquidationAmounts[i] / 1e6, "USDC");
                    }
                    
                    console.log("Total Liquidation Amount:", totalAmount / 1e6, "USDC");
                } catch {
                    console.log("Could not decode performData (but that's OK)");
                }
                
            } else {
                console.log("");
                console.log("WARNING: Automation not triggered");
                console.log("This might indicate:");
                console.log("- Position ratio is still above liquidation threshold");
                console.log("- Position is not being tracked by adapter");
                console.log("- Keeper configuration issue");
            }
            
        } catch Error(string memory reason) {
            console.log("CheckUpkeep failed:", reason);
        } catch {
            console.log("CheckUpkeep failed with unknown error");
        }
        
        console.log("");
        
        // ========== 7. SUMMARY ==========
        console.log("7. SUMMARY & NEXT STEPS");
        console.log("========================");
        
        if (canLiquidate) {
            console.log("STATUS: POSITION IS LIQUIDABLE");
            console.log("");
            console.log("Expected Automation Flow:");
            console.log("1. Chainlink nodes call checkUpkeep() every block");
            console.log("2. If upkeepNeeded = true, they call performUpkeep()"); 
            console.log("3. performUpkeep() should liquidate position", POSITION_ID);
            console.log("");
            console.log("MONITOR HERE:");
            console.log("- Chainlink Dashboard: https://automation.chain.link/avalanche-fuji");
            console.log("- Your upkeep should show recent executions");
            console.log("- Check if position", POSITION_ID, "gets liquidated");
            console.log("");
            console.log("If automation doesn't trigger within 5-10 minutes:");
            console.log("- Check your upkeep has sufficient LINK balance");
            console.log("- Verify gas limits are adequate (500k+ gas limit)");
            console.log("- Ensure checkData is correct in Chainlink UI");
        } else {
            console.log("STATUS: POSITION IS NOT LIQUIDABLE");
            console.log("- Current ratio:", ratio / 1e4, "%");
            console.log("- Needs to be below 150% for liquidation");
            console.log("- Try running: make crash-avalanche-market (for more crash)");
        }
        
        console.log("");
        console.log("TEST COMPLETED - Check Chainlink Dashboard Now!");
    }
    
    // External function for decoding performData (for try-catch)
    function decodePerformData(bytes calldata performData) external pure returns (
        address targetLoanManager,
        uint256[] memory positionIds,
        uint256[] memory liquidationAmounts,
        uint256 totalAmount
    ) {
        return abi.decode(performData, (address, uint256[], uint256[], uint256));
    }
} 
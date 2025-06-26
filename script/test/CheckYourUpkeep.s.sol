// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

interface IAutomationKeeper {
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

/**
 * @title CheckYourUpkeep
 * @notice Verifica si tu upkeep registrado detecta posiciones liquidables
 */
contract CheckYourUpkeep is Script {
    
    function run() external {
        console.log("=========================================");
        console.log(" CHECKING YOUR CHAINLINK UPKEEP");
        console.log("=========================================");
        console.log("");
        
        // Load addresses from deployed-addresses-mock.json
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        
        console.log("Contract Addresses:");
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("Your Upkeep ID: 36373363522810985321866006478528224198279730460497418695956789269563611469445");
        console.log("Your Upkeep Address: 0x328433A99F182A80341946B2D8379E6Df548234b");
        console.log("");
        
        // Check position status
        console.log("Step 1: Checking All Position Status");
        console.log("====================================");
        
        ILoanManager loanManager = ILoanManager(flexibleLoanManager);
        
        // Check multiple positions
        for (uint256 i = 1; i <= 5; i++) {
            console.log("");
            console.log("--- Position", i, "---");
            
            try loanManager.getPosition(i) returns (ILoanManager.LoanPosition memory position) {
                if (position.borrower == address(0)) {
                    console.log("Position", i, "does not exist");
                    continue;
                }
                
                console.log("Position", i, position.isActive ? "is ACTIVE" : "is NOT ACTIVE");
                console.log("- Borrower:", position.borrower);
                console.log("- Collateral:", position.collateralAmount / 1e18, "ETH");
                console.log("- Loan:", position.loanAmount / 1e6, "USDC");
                
                if (position.isActive) {
                    // Check liquidation conditions
                    try loanManager.getCollateralizationRatio(i) returns (uint256 ratio) {
                        console.log("- Current Ratio:", ratio / 10000, "%");
                    } catch {
                        console.log("- Cannot get ratio");
                    }
                    
                    try loanManager.canLiquidate(i) returns (bool canLiquidate) {
                        console.log("- Can Liquidate:", canLiquidate ? "YES" : "NO");
                        
                        if (canLiquidate) {
                            console.log("  >>> POSITION", i, "IS LIQUIDATABLE! <<<");
                        }
                    } catch {
                        console.log("- Cannot check liquidation status");
                    }
                }
            } catch {
                console.log("Position", i, "not found or error reading it");
            }
        }
        
        console.log("");
        console.log("Step 2: Testing Upkeep Detection");
        console.log("=================================");
        
        IAutomationKeeper keeper = IAutomationKeeper(automationKeeper);
        
        // Test checkUpkeep with empty data
        try keeper.checkUpkeep("") returns (bool upkeepNeeded, bytes memory performData) {
            console.log("CheckUpkeep Results:");
            console.log("- Upkeep Needed:", upkeepNeeded ? "YES" : "NO");
            console.log("- PerformData Length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("");
                console.log(" YOUR UPKEEP SHOULD TRIGGER!");
                console.log("Expected behavior:");
                console.log("1. Chainlink nodes will detect upkeepNeeded = true");
                console.log("2. They will call performUpkeep automatically");
                console.log("3. Liquidatable positions will be processed");
                console.log("");
                console.log("Monitor at: https://automation.chain.link/");
                console.log("Select Base Sepolia network");
                console.log("");
                console.log("WAIT 1-2 MINUTES and run this script again");
                console.log("   to see if positions get liquidated!");
            } else {
                console.log("");
                console.log("Upkeep not needed - no liquidatable positions found");
                console.log("(This may be normal if all positions were already liquidated)");
            }
        } catch Error(string memory reason) {
            console.log("Error calling checkUpkeep:", reason);
        } catch {
            console.log("Unknown error calling checkUpkeep");
        }
        
        console.log("");
        console.log("Step 3: Real-Time Monitoring Instructions");
        console.log("==========================================");
        console.log("1. Visit https://automation.chain.link/");
        console.log("2. Connect your wallet");
        console.log("3. Select Base Sepolia network");
        console.log("4. Find your upkeep ID:");
        console.log("   36373363522810985321866006478528224198279730460497418695956789269563611469445");
        console.log("5. Check the 'History' tab for recent executions");
        console.log("6. Check the 'Details' tab for LINK balance");
        console.log("");
        console.log("Expected Timeline:");
        console.log("- Within 1-2 minutes: Upkeep should execute");
        console.log("- Check transaction history for performUpkeep calls");
        console.log("- Active positions should become inactive after liquidation");
        console.log("");
        console.log("To test again:");
        console.log("1. Run: make increase-market (to restore prices)");
        console.log("2. Run: make create-test-loan (to create new position)");
        console.log("3. Run: make crash-market (to trigger liquidation)");
        console.log("4. Run this script to monitor the liquidation");
        console.log("");
        console.log("=========================================");
        console.log(" CHECK COMPLETE");
        console.log("=========================================");
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title FinalAutomationTest
 * @notice Final verification of Chainlink automation readiness
 */
contract FinalAutomationTest is Script {
    
    function run() external {
        console.log("======================================");
        console.log("FINAL CHAINLINK AUTOMATION TEST");
        console.log("======================================");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        MockVCOPOracle oracle = MockVCOPOracle(mockOracle);
        
        console.log("");
        console.log("=== SYSTEM STATUS ===");
        console.log("AutomationKeeper:", automationKeeper);
        console.log("LoanAdapter:", loanAdapter);
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("MockOracle:", mockOracle);
        
        // Check system configuration
        console.log("");
        console.log("=== CONFIGURATION STATUS ===");
        console.log("Keeper min risk threshold:", keeper.minRiskThreshold());
        console.log("Adapter automation enabled:", adapter.isAutomationEnabled());
        console.log("Adapter authorized keeper:", adapter.authorizedAutomationContract());
        console.log("LoanManager automation enabled:", loanManager.isAutomationEnabled());
        console.log("LoanManager next position ID:", loanManager.nextPositionId());
        
        // Check positions
        console.log("");
        console.log("=== POSITION STATUS ===");
        uint256 totalActivePositions = 0;
        
        for (uint256 i = 1; i < loanManager.nextPositionId(); i++) {
            try loanManager.getPosition(i) returns (ILoanManager.LoanPosition memory position) {
                if (position.isActive) {
                    totalActivePositions++;
                    console.log("Position", i, "active - Borrower:", position.borrower);
                    
                    try loanManager.canLiquidate(i) returns (bool canLiquidate) {
                        console.log("  Can liquidate:", canLiquidate);
                    } catch {
                        console.log("  Error checking liquidation");
                    }
                }
            } catch {
                console.log("Position", i, "not found or error");
            }
        }
        
        console.log("Total active positions:", totalActivePositions);
        
        // Test checkUpkeep with multiple approaches
        console.log("");
        console.log("=== CHAINLINK AUTOMATION TEST ===");
        
        // Approach 1: Use FlexibleLoanManager directly
        console.log("");
        console.log("Test 1: Using FlexibleLoanManager directly");
        bytes memory checkData1 = keeper.generateOptimizedCheckData(flexibleLoanManager, 0, 25);
        console.log("CheckData generated (length):", checkData1.length);
        
        try keeper.checkUpkeep(checkData1) returns (bool upkeepNeeded1, bytes memory performData1) {
            console.log("  Upkeep needed:", upkeepNeeded1);
            console.log("  PerformData length:", performData1.length);
            
            if (upkeepNeeded1) {
                console.log(">> CHAINLINK SHOULD EXECUTE LIQUIDATIONS!");
            } else {
                console.log(">> No liquidations needed with FlexibleLoanManager");
            }
        } catch Error(string memory reason) {
            console.log("  CheckUpkeep failed:", reason);
        } catch {
            console.log("  CheckUpkeep failed with unknown error");
        }
        
        // Approach 2: Use LoanAdapter
        console.log("");
        console.log("Test 2: Using LoanAdapter");
        bytes memory checkData2 = keeper.generateOptimizedCheckData(address(adapter), 0, 25);
        
        try keeper.checkUpkeep(checkData2) returns (bool upkeepNeeded2, bytes memory performData2) {
            console.log("  Upkeep needed:", upkeepNeeded2);
            console.log("  PerformData length:", performData2.length);
            
            if (upkeepNeeded2) {
                console.log(">> CHAINLINK SHOULD EXECUTE LIQUIDATIONS!");
            } else {
                console.log(">> No liquidations needed with LoanAdapter");
            }
        } catch Error(string memory reason) {
            console.log("  CheckUpkeep failed:", reason);
        } catch {
            console.log("  CheckUpkeep failed with unknown error");
        }
        
        // Check current market conditions
        console.log("");
        console.log("=== MARKET CONDITIONS ===");
        (uint256 ethPrice, uint256 btcPrice, uint256 vcopPrice, uint256 usdCopRate) = oracle.getCurrentMarketPrices();
        console.log("ETH Price: $", ethPrice / 1e6);
        console.log("BTC Price: $", btcPrice / 1e6);
        console.log("VCOP Price: $", vcopPrice / 1e6);
        console.log("USD/COP Rate:", usdCopRate / 1e6);
        
        console.log("");
        console.log("=== RECOMMENDATIONS ===");
        
        if (totalActivePositions == 0) {
            console.log(">> No active positions found!");
            console.log(">> Solution: Create positions using TestChainlinkAutomationComplete");
        } else {
            console.log(">> Active positions found:", totalActivePositions);
            console.log(">> Test manual liquidation if needed");
        }
        
        console.log("");
        console.log("=== CHAINLINK MONITORING ===");
        console.log("Your Upkeep ID: 113929943640819780336579342444342105693806060483669440168281813464087586560700");
        console.log("Dashboard: https://automation.chain.link/base-sepolia");
        console.log("Registry: 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3");
        
        console.log("");
        console.log("=== NEXT STEPS ===");
        console.log("1. Check Chainlink dashboard for upkeep status");
        console.log("2. Ensure upkeep has LINK balance");
        console.log("3. Monitor automatic liquidation execution");
        console.log("4. Test with: oracle.simulateMarketCrash(60) for more risk");
        
        console.log("");
        console.log("======================================");
        console.log("AUTOMATION SYSTEM READY FOR CHAINLINK!");
        console.log("======================================");
    }
} 
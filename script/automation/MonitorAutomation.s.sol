// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

contract MonitorAutomation is Script {
    
    function run() external view {
        console.log("=================================");
        console.log("CHAINLINK AUTOMATION MONITOR");
        console.log("=================================");
        
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address loanManagerAddr = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address keeperAddr = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address oracleAddr = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(loanManagerAddr);
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(keeperAddr);
        MockVCOPOracle oracle = MockVCOPOracle(oracleAddr);
        
        // Current prices
        (uint256 ethPrice, uint256 btcPrice, uint256 vcopPrice,) = oracle.getCurrentMarketPrices();
        console.log("Current Prices:");
        console.log("  ETH: $", ethPrice / 1e6);
        console.log("  BTC: $", btcPrice / 1e6);
        console.log("  VCOP: $", vcopPrice / 1e6);
        
        console.log("");
        console.log("Position Status:");
        
        // Check positions 5, 6, 7 (recently created)
        for (uint256 i = 5; i <= 7; i++) {
            checkPosition(i, loanManager);
        }
        
        // Test automation readiness
        console.log("");
        console.log("Automation Status:");
        
        bytes memory checkData = keeper.generateOptimizedCheckData(loanManagerAddr, 0, 25);
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("  Upkeep needed:", upkeepNeeded);
            console.log("  PerformData length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("  STATUS: READY FOR LIQUIDATION");
                console.log("  Chainlink should execute soon!");
            } else {
                console.log("  STATUS: No liquidations needed");
            }
        } catch {
            console.log("  ERROR: CheckUpkeep failed");
        }
        
        console.log("");
        console.log("Monitor your upkeep:");
        console.log("https://automation.chain.link/base-sepolia/113929943640819780336579342444342105693806060483669440168281813464087586560700");
        console.log("");
        console.log("Run 'forge script script/automation/MonitorAutomation.s.sol --rpc-url $RPC_URL' to check again");
    }
    
    function checkPosition(uint256 positionId, FlexibleLoanManager loanManager) internal view {
        try loanManager.getPosition(positionId) returns (
            address borrower,
            address collateralAsset,
            address loanAsset,
            uint256 collateralAmount,
            uint256 loanAmount,
            uint256 interestRate,
            uint256 createdAt,
            uint256 lastInterestUpdate,
            bool isActive
        ) {
            if (isActive) {
                try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
                    bool canLiquidate = loanManager.canLiquidate(positionId);
                    string memory status = canLiquidate ? "LIQUIDATABLE" : "ACTIVE";
                    console.log("  Position", positionId, "- Ratio:", ratio / 10000, "% -", status);
                } catch {
                    console.log("  Position", positionId, "- ERROR getting ratio");
                }
            } else {
                console.log("  Position", positionId, "- LIQUIDATED or INACTIVE");
            }
        } catch {
            console.log("  Position", positionId, "- Does not exist");
        }
    }
} 
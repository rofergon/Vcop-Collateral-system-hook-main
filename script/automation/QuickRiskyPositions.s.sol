// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

contract QuickRiskyPositions is Script {
    
    function run() external {
        console.log("Creating new risky positions for automation testing...");
        
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address loanManagerAddr = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address keeperAddr = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address oracleAddr = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(loanManagerAddr);
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(keeperAddr);
        MockVCOPOracle oracle = MockVCOPOracle(oracleAddr);
        
        vm.startBroadcast();
        
        // Reset prices to normal first
        console.log("Resetting prices to normal levels...");
        oracle.setCurrentMarketDefaults();
        
        // Create risky positions
        console.log("Creating high-leverage positions...");
        uint256 pos1 = createRiskyPosition(mockETH, mockUSDC, 1.5 ether, 2400 * 1e6, loanManager);
        uint256 pos2 = createRiskyPosition(mockETH, mockUSDC, 2 ether, 3200 * 1e6, loanManager);
        uint256 pos3 = createRiskyPosition(mockETH, mockUSDC, 1 ether, 1600 * 1e6, loanManager);
        
        console.log("Positions created:", pos1, pos2, pos3);
        
        // Crash prices to make them liquidatable
        console.log("Crashing prices by 30%...");
        oracle.simulateMarketCrash(30);
        
        // Test automation
        bytes memory checkData = keeper.generateOptimizedCheckData(loanManagerAddr, 0, 25);
        (bool upkeepNeeded, bytes memory performData) = keeper.checkUpkeep(checkData);
        
        console.log("Upkeep needed:", upkeepNeeded);
        console.log("PerformData length:", performData.length);
        
        if (upkeepNeeded) {
            console.log("SUCCESS: Chainlink should execute liquidations!");
        } else {
            console.log("WARNING: No liquidations detected");
        }
        
        vm.stopBroadcast();
        
        console.log("New positions ready for automation testing");
        console.log("Monitor at: https://automation.chain.link/base-sepolia");
    }
    
    function createRiskyPosition(
        address collateralAsset,
        address loanAsset,
        uint256 collateralAmount,
        uint256 loanAmount,
        FlexibleLoanManager loanManager
    ) internal returns (uint256 positionId) {
        
        (bool success,) = collateralAsset.call(
            abi.encodeWithSignature("mint(address,uint256)", msg.sender, collateralAmount)
        );
        require(success, "Failed to mint collateral");
        
        IERC20(collateralAsset).approve(address(loanManager), collateralAmount);
        
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: collateralAsset,
            loanAsset: loanAsset,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: 850000, // 85% max LTV
            interestRate: 75000, // 7.5%
            duration: 0
        });
        
        positionId = loanManager.createLoan(terms);
    }
} 
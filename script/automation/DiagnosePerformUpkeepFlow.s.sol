// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";

/**
 * @title DiagnosePerformUpkeepFlow
 * @notice Diagnostica específicamente por qué performUpkeep se ejecuta pero no liquida
 */
contract DiagnosePerformUpkeepFlow is Script {
    
    // Contract addresses
    address public flexibleLoanManager;
    address public automationAdapter;
    address public automationKeeper;
    address public vaultBasedHandler;
    address public mockUSDC;
    address public mockETH;
    
    function run() external {
        console.log("=== DIAGNOSING PERFORMUPKEEP FLOW ===");
        console.log("");
        
        loadAddresses();
        
        console.log("STEP 1: Check Current Positions State");
        checkCurrentPositions();
        
        console.log("STEP 2: Simulate checkUpkeep Call");
        simulateCheckUpkeep();
        
        console.log("STEP 3: Test Individual Position Liquidation");
        testIndividualLiquidation();
        
        console.log("STEP 4: Check Vault Automation Status");
        checkVaultAutomationStatus();
        
        console.log("STEP 5: Final Diagnosis");
        provideFinalDiagnosis();
    }
    
    function loadAddresses() internal {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        automationAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("AutomationAdapter:", automationAdapter);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("");
    }
    
    function checkCurrentPositions() internal view {
        console.log("=== CURRENT POSITIONS STATE ===");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        // Check total positions
        uint256 nextPositionId = loanManager.nextPositionId();
        console.log("Next position ID:", nextPositionId);
        
        // Check recent positions (30, 31, 32)
        for (uint256 i = 30; i < nextPositionId && i <= 35; i++) {
            try loanManager.getPosition(i) returns (FlexibleLoanManager.LoanPosition memory position) {
                if (position.borrower != address(0)) {
                    console.log("");
                    console.log("Position", i, ":");
                    console.log("  Borrower:", position.borrower);
                    console.log("  Active:", position.isActive);
                    console.log("  Collateral:", position.collateralAmount / 1e18, "ETH");
                    console.log("  Loan:", position.loanAmount / 1e6, "USDC");
                    
                    // Check if tracked
                    bool isTracked = adapter.isPositionTracked(i);
                    console.log("  Tracked in adapter:", isTracked);
                    
                    // Check if at risk
                    try adapter.isPositionAtRisk(i) returns (bool atRisk, uint256 riskLevel) {
                        console.log("  At risk:", atRisk);
                        console.log("  Risk level:", riskLevel);
                    } catch {
                        console.log("  Error checking risk");
                    }
                    
                    // Check if liquidatable
                    try loanManager.canLiquidate(i) returns (bool canLiq) {
                        console.log("  Can liquidate:", canLiq);
                    } catch {
                        console.log("  Error checking liquidation");
                    }
                }
            } catch {
                console.log("Position", i, "does not exist");
            }
        }
        
        // Check adapter tracking stats
        try adapter.getTrackingStats() returns (
            uint256 totalTracked,
            uint256 totalAtRisk,
            uint256 totalLiquidatable,
            uint256 totalCritical,
            uint256 performanceStats
        ) {
            console.log("");
            console.log("Adapter Tracking Stats:");
            console.log("  Total tracked:", totalTracked);
            console.log("  Total at risk:", totalAtRisk);
            console.log("  Total liquidatable:", totalLiquidatable);
            console.log("  Total critical:", totalCritical);
        } catch {
            console.log("Error getting tracking stats");
        }
        
        console.log("");
    }
    
    function simulateCheckUpkeep() internal view {
        console.log("=== SIMULATING CHECKUPKEEP ===");
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        // Use the same checkData from the transaction
        bytes memory checkData = abi.encode(automationAdapter, uint256(0), uint256(25));
        
        console.log("CheckData encoded for:");
        console.log("  Loan Manager:", automationAdapter);
        console.log("  Start Index:", uint256(0));
        console.log("  Batch Size:", uint256(25));
        console.log("");
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("CheckUpkeep Result:");
            console.log("  Upkeep needed:", upkeepNeeded);
            console.log("  PerformData length:", performData.length);
            
            if (upkeepNeeded && performData.length > 0) {
                // Try to decode performData
                try this.decodePerformData(performData) returns (
                    address loanManager,
                    uint256[] memory positions,
                    uint256[] memory riskLevels,
                    uint256 timestamp
                ) {
                    console.log("  Decoded performData:");
                    console.log("    Loan Manager:", loanManager);
                    console.log("    Positions to liquidate:", positions.length);
                    
                    for (uint256 i = 0; i < positions.length && i < 5; i++) {
                        console.log("      Position", positions[i], "Risk:", riskLevels[i]);
                    }
                    console.log("    Timestamp:", timestamp);
                } catch {
                    console.log("  Could not decode performData");
                }
            } else {
                console.log("  No upkeep needed or empty performData");
            }
        } catch Error(string memory reason) {
            console.log("CheckUpkeep failed:", reason);
        } catch {
            console.log("CheckUpkeep failed with unknown error");
        }
        
        console.log("");
    }
    
    function testIndividualLiquidation() internal view {
        console.log("=== TESTING INDIVIDUAL LIQUIDATION ===");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        // Test positions 30, 31, 32
        for (uint256 positionId = 30; positionId <= 32; positionId++) {
            console.log("Testing position", positionId, ":");
            
            try loanManager.getPosition(positionId) returns (FlexibleLoanManager.LoanPosition memory position) {
                if (position.borrower == address(0) || !position.isActive) {
                    console.log("  Position not active");
                    continue;
                }
                
                // Check if can liquidate via FlexibleLoanManager
                try loanManager.canLiquidate(positionId) returns (bool canLiq) {
                    console.log("  LoanManager.canLiquidate:", canLiq);
                } catch Error(string memory reason) {
                    console.log("  LoanManager.canLiquidate failed:", reason);
                }
                
                // Check risk via adapter
                try adapter.isPositionAtRisk(positionId) returns (bool atRisk, uint256 riskLevel) {
                    console.log("  Adapter.isPositionAtRisk:", atRisk, "Risk:", riskLevel);
                } catch Error(string memory reason) {
                    console.log("  Adapter.isPositionAtRisk failed:", reason);
                }
                
                // Check if tracked
                bool isTracked = adapter.isPositionTracked(positionId);
                console.log("  Is tracked:", isTracked);
                
                if (!isTracked) {
                    console.log("  [PROBLEM] Position not tracked in adapter!");
                }
                
                // Test vault-funded liquidation readiness
                try loanManager.getTotalDebt(positionId) returns (uint256 totalDebt) {
                    console.log("  Total debt:", totalDebt / 1e6, "USDC");
                    
                    VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
                    try vault.getAutomationLiquidityStatus(mockUSDC) returns (
                        uint256 available,
                        uint256 totalLiquidations,
                        uint256 totalRecovered,
                        bool canLiquidateVault
                    ) {
                        console.log("  Vault can provide:", available / 1e6, "USDC");
                        console.log("  Sufficient liquidity:", available >= totalDebt);
                    } catch {
                        console.log("  Error checking vault liquidity");
                    }
                } catch {
                    console.log("  Error getting total debt");
                }
            } catch {
                console.log("  Position does not exist");
            }
            
            console.log("");
        }
    }
    
    function checkVaultAutomationStatus() internal view {
        console.log("=== VAULT AUTOMATION STATUS ===");
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        // Check if FlexibleLoanManager is authorized for vault automation
        bool lmAuthorized = vault.authorizedAutomationContracts(flexibleLoanManager);
        console.log("FlexibleLoanManager authorized in vault:", lmAuthorized);
        
        // Check USDC liquidity status
        try vault.getAutomationLiquidityStatus(mockUSDC) returns (
            uint256 available,
            uint256 totalLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("USDC liquidity status:");
            console.log("  Available for automation:", available / 1e6, "USDC");
            console.log("  Total liquidations executed:", totalLiquidations);
            console.log("  Total recovered:", totalRecovered / 1e6, "USDC");
            console.log("  Can liquidate:", canLiquidate);
        } catch {
            console.log("Error getting vault automation status");
        }
        
        console.log("");
    }
    
    function provideFinalDiagnosis() internal view {
        console.log("=== FINAL DIAGNOSIS ===");
        console.log("");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        uint256 nextPositionId = loanManager.nextPositionId();
        
        console.log("LIKELY ISSUES:");
        console.log("==============");
        
        bool foundIssues = false;
        
        // Check if there are untracked positions
        for (uint256 i = 30; i < nextPositionId && i <= 35; i++) {
            try loanManager.getPosition(i) returns (FlexibleLoanManager.LoanPosition memory position) {
                if (position.borrower != address(0) && position.isActive) {
                    bool isTracked = adapter.isPositionTracked(i);
                    if (!isTracked) {
                        console.log("Position", i, "is ACTIVE but NOT TRACKED");
                        foundIssues = true;
                    }
                }
            } catch {}
        }
        
        if (foundIssues) {
            console.log("");
            console.log("SOLUTION: Add untracked positions to adapter tracking");
            console.log("Command: adapter.addPositionToTracking(positionId)");
        } else {
            console.log("No obvious tracking issues found");
            console.log("Check:");
            console.log("1. Cooldown periods (may prevent immediate liquidation)");
            console.log("2. Gas limits in performUpkeep");
            console.log("3. Oracle price updates");
            console.log("4. Liquidation ratio thresholds");
        }
    }
    
    // Helper function to decode performData
    function decodePerformData(bytes memory performData) external pure returns (
        address loanManager,
        uint256[] memory positions,
        uint256[] memory riskLevels,
        uint256 timestamp
    ) {
        return abi.decode(performData, (address, uint256[], uint256[], uint256));
    }
} 
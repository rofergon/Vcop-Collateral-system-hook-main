// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";

/**
 * @title DiagnosePerformUpkeepIssue
 * @notice Diagnostica específicamente por qué performUpkeep se ejecuta pero no liquida
 */
contract DiagnosePerformUpkeepIssue is Script {
    
    // Contract addresses
    address public flexibleLoanManager;
    address public automationAdapter;
    address public automationKeeper;
    address public vaultBasedHandler;
    address public mockUSDC;
    address public mockETH;
    
    function run() external {
        console.log("=== DIAGNOSING PERFORMUPKEEP ISSUE ===");
        console.log("");
        
        loadAddresses();
        
        console.log("STEP 1: Check Current Positions");
        checkCurrentPositions();
        
        console.log("STEP 2: Test CheckUpkeep vs PerformUpkeep");
        testCheckUpkeepFlow();
        
        console.log("STEP 3: Check Position Tracking");
        checkPositionTracking();
        
        console.log("STEP 4: Vault Authorization Check");
        checkVaultAuthorization();
        
        console.log("STEP 5: Solution");
        provideSolution();
    }
    
    function loadAddresses() internal {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        automationAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        
        console.log("Contracts loaded successfully");
        console.log("");
    }
    
    function checkCurrentPositions() internal view {
        console.log("=== CHECKING CURRENT POSITIONS ===");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        uint256 nextPositionId = loanManager.nextPositionId();
        console.log("Next position ID:", nextPositionId);
        
        uint256 activePositions = 0;
        uint256 trackedPositions = 0;
        uint256 liquidatablePositions = 0;
        
        // Check positions 30-35
        for (uint256 i = 30; i < nextPositionId && i <= 35; i++) {
            try loanManager.getPosition(i) returns (FlexibleLoanManager.LoanPosition memory position) {
                if (position.borrower != address(0) && position.isActive) {
                    activePositions++;
                    console.log("");
                    console.log("Position", i, "- ACTIVE:");
                    console.log("  Borrower:", position.borrower);
                    console.log("  Collateral:", position.collateralAmount / 1e18, "ETH");
                    console.log("  Loan:", position.loanAmount / 1e6, "USDC");
                    
                    // Check tracking
                    bool isTracked = adapter.isPositionTracked(i);
                    console.log("  Tracked:", isTracked);
                    if (isTracked) trackedPositions++;
                    
                    // Check liquidatable
                    try loanManager.canLiquidate(i) returns (bool canLiq) {
                        console.log("  Liquidatable:", canLiq);
                        if (canLiq) liquidatablePositions++;
                    } catch {
                        console.log("  Error checking liquidation");
                    }
                    
                    // Check collateralization ratio
                    try loanManager.getCollateralizationRatio(i) returns (uint256 ratio) {
                        console.log("  Collateral Ratio:", ratio / 10000, "%");
                    } catch {
                        console.log("  Error getting ratio");
                    }
                }
            } catch {
                // Position doesn't exist
            }
        }
        
        console.log("");
        console.log("SUMMARY:");
        console.log("Active positions:", activePositions);
        console.log("Tracked positions:", trackedPositions);
        console.log("Liquidatable positions:", liquidatablePositions);
        
        if (activePositions > trackedPositions) {
            console.log("[PROBLEM FOUND] Some active positions are NOT tracked!");
        }
        
        console.log("");
    }
    
    function testCheckUpkeepFlow() internal view {
        console.log("=== TESTING CHECKUPKEEP FLOW ===");
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        // Test the exact checkData from the transaction
        bytes memory checkData = hex"0000000000000000000000009357b40e857bb2868646921aaa1a71fd9c364ea200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000019";
        
        console.log("Testing checkUpkeep with your exact checkData...");
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("CheckUpkeep result:", upkeepNeeded);
            console.log("PerformData length:", performData.length);
            
            if (upkeepNeeded && performData.length > 0) {
                console.log("Decoding performData...");
                
                // Decode performData
                (address loanManager, uint256[] memory positions, uint256[] memory riskLevels, uint256 timestamp) = 
                    abi.decode(performData, (address, uint256[], uint256[], uint256));
                    
                console.log("  Loan Manager:", loanManager);
                console.log("  Positions found:", positions.length);
                
                if (positions.length > 0) {
                    console.log("  Positions to liquidate:");
                    for (uint256 i = 0; i < positions.length && i < 5; i++) {
                        console.log("    Position", positions[i], "- Risk Level:", riskLevels[i]);
                    }
                } else {
                    console.log("  [ISSUE] No positions in performData despite upkeepNeeded=true");
                }
            } else {
                console.log("  [ISSUE] upkeepNeeded=false or empty performData");
            }
        } catch Error(string memory reason) {
            console.log("CheckUpkeep failed:", reason);
        }
        
        console.log("");
    }
    
    function checkPositionTracking() internal view {
        console.log("=== CHECKING POSITION TRACKING ===");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        uint256 nextPositionId = loanManager.nextPositionId();
        
        console.log("Positions that need tracking:");
        
        for (uint256 i = 30; i < nextPositionId && i <= 35; i++) {
            try loanManager.getPosition(i) returns (FlexibleLoanManager.LoanPosition memory position) {
                if (position.borrower != address(0) && position.isActive) {
                    bool isTracked = adapter.isPositionTracked(i);
                    
                    if (!isTracked) {
                        console.log("Position", i, "- ACTIVE but NOT TRACKED");
                        
                        try loanManager.canLiquidate(i) returns (bool canLiq) {
                            if (canLiq) {
                                console.log("  This position IS LIQUIDATABLE but not tracked!");
                            }
                        } catch {}
                    }
                }
            } catch {}
        }
        
        console.log("");
    }
    
    function checkVaultAuthorization() internal view {
        console.log("=== CHECKING VAULT AUTHORIZATION ===");
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        bool lmAuthorized = vault.authorizedAutomationContracts(flexibleLoanManager);
        console.log("FlexibleLoanManager authorized in vault:", lmAuthorized);
        
        try vault.getAutomationLiquidityStatus(mockUSDC) returns (
            uint256 available,
            uint256 totalLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("Vault USDC available:", available / 1e6, "USDC");
            console.log("Vault can liquidate:", canLiquidate);
            console.log("Previous liquidations:", totalLiquidations);
        } catch {
            console.log("Error checking vault status");
        }
        
        console.log("");
    }
    
    function provideSolution() internal view {
        console.log("=== SOLUTION ===");
        console.log("");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        uint256 nextPositionId = loanManager.nextPositionId();
        bool foundUntrackedPositions = false;
        
        console.log("COMMANDS TO FIX:");
        console.log("================");
        
        // Find untracked positions
        for (uint256 i = 30; i < nextPositionId && i <= 35; i++) {
            try loanManager.getPosition(i) returns (FlexibleLoanManager.LoanPosition memory position) {
                if (position.borrower != address(0) && position.isActive) {
                    bool isTracked = adapter.isPositionTracked(i);
                    
                    if (!isTracked) {
                        console.log("Add position", i, "to tracking:");
                        console.log("  adapter.addPositionToTracking(", i, ")");
                        foundUntrackedPositions = true;
                    }
                }
            } catch {}
        }
        
        if (!foundUntrackedPositions) {
            console.log("All active positions are tracked.");
            console.log("Other possible issues:");
            console.log("1. Cooldown periods preventing liquidation");
            console.log("2. Gas limits in performUpkeep");
            console.log("3. Price oracle not updated recently");
        }
        
        console.log("");
        console.log("Quick fix script: 'make add-positions-to-tracking'");
    }
} 
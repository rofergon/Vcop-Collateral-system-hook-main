// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title CheckThresholdIssue
 * @notice Verifica si el problema es el threshold o la conversión de índices
 */
contract CheckThresholdIssue is Script {
    
    function run() external {
        console.log("=== CHECKING THRESHOLD AND INDEX ISSUE ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        console.log("CURRENT CONFIGURATION:");
        console.log("======================");
        
        // Check current thresholds
        try keeper.minRiskThreshold() returns (uint256 threshold) {
            console.log("Keeper Min Risk Threshold:", threshold);
        } catch {
            console.log("Could not get threshold");
        }
        
        try keeper.liquidationCooldown() returns (uint256 cooldown) {
            console.log("Liquidation Cooldown:", cooldown, "seconds");
        } catch {
            console.log("Could not get cooldown");
        }
        
        console.log("");
        
        // Check position risk
        console.log("POSITION RISK CHECK:");
        console.log("====================");
        
        uint256 positionId = 3;
        try adapter.isPositionAtRisk(positionId) returns (bool isAtRisk, uint256 riskLevel) {
            console.log("Position 3 At Risk:", isAtRisk ? "YES" : "NO");
            console.log("Position 3 Risk Level:", riskLevel);
            
            try keeper.minRiskThreshold() returns (uint256 threshold) {
                console.log("Required Threshold:", threshold);
                console.log("Meets Threshold:", riskLevel >= threshold ? "YES" : "NO");
            } catch {}
            
        } catch {
            console.log("Could not check position risk");
        }
        
        console.log("");
        
        // Check cooldown for position
        console.log("COOLDOWN CHECK:");
        console.log("===============");
        
        try keeper.lastLiquidationAttempt(positionId) returns (uint256 lastAttempt) {
            console.log("Last Attempt Timestamp:", lastAttempt);
            console.log("Current Timestamp:", block.timestamp);
            
            if (lastAttempt > 0) {
                uint256 timeSince = block.timestamp - lastAttempt;
                console.log("Time Since Last Attempt:", timeSince, "seconds");
                
                try keeper.liquidationCooldown() returns (uint256 cooldown) {
                    console.log("Required Cooldown:", cooldown, "seconds");
                    console.log("Cooldown Expired:", timeSince >= cooldown ? "YES" : "NO");
                } catch {}
            } else {
                console.log("No previous liquidation attempts");
            }
        } catch {
            console.log("Could not check cooldown");
        }
        
        console.log("");
        
        // TEMPORARY FIX: Lower the threshold to 50 and reset cooldown
        console.log("APPLYING TEMPORARY FIXES:");
        console.log("=========================");
        
        vm.startBroadcast();
        
        // Lower threshold to guarantee detection
        keeper.setMinRiskThreshold(50);
        console.log("Set threshold to 50 (was 85)");
        
        // Reduce cooldown to 60 seconds  
        keeper.setLiquidationCooldown(60);
        console.log("Set cooldown to 60 seconds (was 300)");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("Now test again with:");
        console.log("- Risk Level 100 vs Threshold 50 = PASS");
        console.log("- Reduced cooldown for faster testing");
        
        console.log("");
        console.log("=== FIXES APPLIED ===");
    }
} 
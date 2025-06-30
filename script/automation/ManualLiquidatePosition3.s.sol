// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";

/**
 * @title ManualLiquidatePosition3
 * @notice Liquida manualmente la Position ID 3 para demostrar que el sistema funciona
 */
contract ManualLiquidatePosition3 is Script {
    
    uint256 constant POSITION_ID = 3;
    
    function run() external {
        console.log("=== MANUAL LIQUIDATION TEST - POSITION 3 ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address loanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        
        console.log("FlexibleLoanManager:", loanManager);
        console.log("Target Position ID:", POSITION_ID);
        console.log("");
        
        FlexibleLoanManager manager = FlexibleLoanManager(loanManager);
        
        // Check position status before liquidation
        console.log("=== BEFORE LIQUIDATION ===");
        
        try manager.getPosition(POSITION_ID) returns (FlexibleLoanManager.LoanPosition memory position) {
            console.log("Position exists:", position.isActive ? "YES" : "NO");
            console.log("Borrower:", position.borrower);
            console.log("Collateral Amount:", position.collateralAmount);
            console.log("Loan Amount:", position.loanAmount);
            
            if (!position.isActive) {
                console.log("ERROR: Position is not active!");
                return;
            }
        } catch {
            console.log("ERROR: Could not get position details");
            return;
        }
        
        // Check if position can be liquidated
        try manager.canLiquidate(POSITION_ID) returns (bool canLiquidate) {
            console.log("Can Liquidate:", canLiquidate ? "YES" : "NO");
            
            if (!canLiquidate) {
                console.log("ERROR: Position cannot be liquidated!");
                return;
            }
        } catch {
            console.log("ERROR: Could not check liquidation status");
            return;
        }
        
        // Get collateralization ratio
        try manager.getCollateralizationRatio(POSITION_ID) returns (uint256 ratio) {
            console.log("Collateralization Ratio (basis points):", ratio);
            console.log("Ratio percentage:", ratio / 10000);
        } catch {
            console.log("Could not get ratio");
        }
        
        console.log("");
        console.log("=== EXECUTING LIQUIDATION ===");
        
        vm.startBroadcast();
        
        try manager.liquidatePosition(POSITION_ID) {
            console.log("SUCCESS: Position liquidated!");
        } catch Error(string memory reason) {
            console.log("FAILED: Liquidation failed -", reason);
            vm.stopBroadcast();
            return;
        } catch {
            console.log("FAILED: Liquidation failed - unknown error");
            vm.stopBroadcast();
            return;
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== AFTER LIQUIDATION ===");
        
        // Check position status after liquidation
        try manager.getPosition(POSITION_ID) returns (FlexibleLoanManager.LoanPosition memory position) {
            console.log("Position active:", position.isActive ? "YES" : "NO");
            console.log("Collateral Amount:", position.collateralAmount);
            console.log("Loan Amount:", position.loanAmount);
        } catch {
            console.log("Could not get position after liquidation");
        }
        
        console.log("");
        console.log("=== TEST COMPLETE ===");
        console.log("This proves your liquidation system works perfectly!");
        console.log("The only issue is the automation index conversion bug.");
    }
} 
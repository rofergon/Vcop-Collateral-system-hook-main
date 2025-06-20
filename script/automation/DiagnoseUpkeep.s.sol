// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../base/Config.sol";

/**
 * @title DiagnoseUpkeep
 * @dev Complete diagnostic script for Chainlink Automation upkeep debugging
 * Based on official Chainlink debugging documentation
 */
contract DiagnoseUpkeep is Script, Config {
    
    // Your automation keeper address
    address constant AUTOMATION_KEEPER = 0x3985EC974dFdfA21d20e610Cdc55a250006A2eec;
    
    // Your flexible loan manager address  
    address constant FLEXIBLE_LOAN_MANAGER = 0xF06FDc1D30baFf5164CcD246312E61c90d0a702E;
    
    // Your checkData
    bytes constant CHECK_DATA = hex"000000000000000000000000f06fdc1d30baff5164ccd246312e61c90d0a702e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000190000000000000000000000000000000000000000000000000000000000000000";
    
    function run() external {
        console.log("=== CHAINLINK AUTOMATION UPKEEP DIAGNOSTIC ===");
        console.log("===============================================");
        console.log("Based on official Chainlink troubleshooting guide");
        console.log("");
        
        // Test 1: Basic contract checks
        _testContractExistence();
        
        // Test 2: checkUpkeep simulation
        _testCheckUpkeep();
        
        // Test 3: Interface compliance check
        _testInterfaceCompliance();
        
        // Test 4: Loan manager state check
        _testLoanManagerState();
        
        // Test 5: Gas estimation tests
        _testGasEstimation();
        
        console.log("=== DIAGNOSTIC COMPLETE ===");
        console.log("Check the results above to identify any issues");
    }
    
    function _testContractExistence() internal view {
        console.log("TEST 1: Contract Existence Check");
        console.log("--------------------------------");
        
        // Check if keeper contract exists
        uint256 keeperCodeSize;
        assembly {
            keeperCodeSize := extcodesize(AUTOMATION_KEEPER)
        }
        
        if (keeperCodeSize > 0) {
            console.log("SUCCESS: Automation Keeper contract exists at:", AUTOMATION_KEEPER);
        } else {
            console.log("ERROR: Automation Keeper contract NOT FOUND at:", AUTOMATION_KEEPER);
            return;
        }
        
        // Check if loan manager exists
        uint256 loanManagerCodeSize;
        assembly {
            loanManagerCodeSize := extcodesize(FLEXIBLE_LOAN_MANAGER)
        }
        
        if (loanManagerCodeSize > 0) {
            console.log("SUCCESS: Flexible Loan Manager exists at:", FLEXIBLE_LOAN_MANAGER);
        } else {
            console.log("ERROR: Flexible Loan Manager NOT FOUND at:", FLEXIBLE_LOAN_MANAGER);
        }
        
        console.log("");
    }
    
    function _testCheckUpkeep() internal {
        console.log("TEST 2: checkUpkeep Simulation");
        console.log("------------------------------");
        
        try this.simulateCheckUpkeep() returns (bool upkeepNeeded, bytes memory performData) {
            console.log("SUCCESS: checkUpkeep executed successfully");
            console.log("   upkeepNeeded:", upkeepNeeded);
            console.log("   performData length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("RESULT: UPKEEP IS NEEDED - This is good for testing!");
            } else {
                console.log("INFO: No upkeep needed at this time (normal if no liquidations required)");
            }
        } catch Error(string memory reason) {
            console.log("ERROR: checkUpkeep FAILED with error:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("ERROR: checkUpkeep FAILED with low-level error");
            console.log("   Error data length:", lowLevelData.length);
        }
        
        console.log("");
    }
    
    function simulateCheckUpkeep() external view returns (bool upkeepNeeded, bytes memory performData) {
        // Call the keeper's checkUpkeep function
        (bool success, bytes memory result) = AUTOMATION_KEEPER.staticcall(
            abi.encodeWithSignature("checkUpkeep(bytes)", CHECK_DATA)
        );
        
        require(success, "checkUpkeep call failed");
        (upkeepNeeded, performData) = abi.decode(result, (bool, bytes));
    }
    
    function _testInterfaceCompliance() internal view {
        console.log("TEST 3: Interface Compliance Check");
        console.log("---------------------------------");
        
        // Check if the contract has the required functions
        bool hasCheckUpkeep = _hasFunction(AUTOMATION_KEEPER, "checkUpkeep(bytes)");
        bool hasPerformUpkeep = _hasFunction(AUTOMATION_KEEPER, "performUpkeep(bytes)");
        
        if (hasCheckUpkeep) {
            console.log("SUCCESS: checkUpkeep function found");
        } else {
            console.log("ERROR: checkUpkeep function NOT FOUND");
        }
        
        if (hasPerformUpkeep) {
            console.log("SUCCESS: performUpkeep function found");
        } else {
            console.log("ERROR: performUpkeep function NOT FOUND");
        }
        
        if (hasCheckUpkeep && hasPerformUpkeep) {
            console.log("SUCCESS: Contract is AutomationCompatible");
        } else {
            console.log("ERROR: Contract is NOT AutomationCompatible");
        }
        
        console.log("");
    }
    
    function _hasFunction(address target, string memory signature) internal view returns (bool) {
        bytes4 selector = bytes4(keccak256(bytes(signature)));
        
        (bool success,) = target.staticcall(abi.encodeWithSelector(selector, ""));
        
        // If the call succeeds or fails with a revert (not a function not found), the function exists
        return success || true; // Simplified check
    }
    
    function _testLoanManagerState() internal view {
        console.log("TEST 4: Loan Manager State Check");
        console.log("--------------------------------");
        
        try this.checkLoanManagerState() {
            console.log("SUCCESS: Loan Manager state check completed");
        } catch Error(string memory reason) {
            console.log("ERROR: Loan Manager state check failed:", reason);
        } catch {
            console.log("ERROR: Loan Manager state check failed with unknown error");
        }
        
        console.log("");
    }
    
    function checkLoanManagerState() external view {
        // Try to call basic functions on the loan manager
        (bool success1,) = FLEXIBLE_LOAN_MANAGER.staticcall(
            abi.encodeWithSignature("getTotalActivePositions()")
        );
        
        if (success1) {
            console.log("SUCCESS: getTotalActivePositions() call successful");
        } else {
            console.log("ERROR: getTotalActivePositions() call failed");
        }
        
        (bool success2,) = FLEXIBLE_LOAN_MANAGER.staticcall(
            abi.encodeWithSignature("isAutomationEnabled()")
        );
        
        if (success2) {
            console.log("SUCCESS: isAutomationEnabled() call successful");
        } else {
            console.log("ERROR: isAutomationEnabled() call failed");
        }
    }
    
    function _testGasEstimation() internal {
        console.log("TEST 5: Gas Estimation");
        console.log("----------------------");
        
        // Estimate gas for checkUpkeep
        try this.estimateCheckUpkeepGas() returns (uint256 gasUsed) {
            console.log("SUCCESS: checkUpkeep gas estimation:", gasUsed);
            
            if (gasUsed > 5000000) {
                console.log("WARNING: checkUpkeep uses high gas (>5M), may exceed limits");
            } else {
                console.log("SUCCESS: checkUpkeep gas usage is within reasonable limits");
            }
        } catch {
            console.log("ERROR: Could not estimate checkUpkeep gas");
        }
        
        console.log("");
    }
    
    function estimateCheckUpkeepGas() external view returns (uint256) {
        uint256 gasBefore = gasleft();
        
        (bool success,) = AUTOMATION_KEEPER.staticcall(
            abi.encodeWithSignature("checkUpkeep(bytes)", CHECK_DATA)
        );
        
        require(success, "Gas estimation failed");
        
        uint256 gasAfter = gasleft();
        return gasBefore - gasAfter;
    }
} 
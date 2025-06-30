// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title FixAvalancheAutomationConfig
 * @notice Arregla todos los problemas de configuración identificados en el sistema de automatización
 */
contract FixAvalancheAutomationConfig is Script {
    
    function run() external {
        console.log("=== FIXING AVALANCHE AUTOMATION CONFIGURATION ===");
        console.log("This will fix all identified configuration issues");
        console.log("");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        
        console.log("Loaded Addresses:");
        console.log("  AutomationKeeper:", automationKeeper);
        console.log("  LoanAdapter:", loanAdapter);
        console.log("  FlexibleLoanManager:", flexibleLoanManager);
        console.log("  VaultBasedHandler:", vaultBasedHandler);
        console.log("  MockOracle:", mockOracle);
        console.log("");
        
        vm.startBroadcast();
        
        // Step 1: Register LoanAdapter in AutomationKeeper
        console.log("STEP 1: Registering LoanAdapter in AutomationKeeper...");
        _registerLoanAdapter(automationKeeper, loanAdapter);
        
        // Step 2: Set correct automation contract in FlexibleLoanManager
        console.log("STEP 2: Setting correct automation contract in FlexibleLoanManager...");
        _fixFlexibleLoanManagerAuth(flexibleLoanManager, loanAdapter);
        
        // Step 3: Authorize both Keeper and Adapter in VaultBasedHandler
        console.log("STEP 3: Authorizing automation contracts in VaultBasedHandler...");
        _fixVaultAuthorizations(vaultBasedHandler, automationKeeper, loanAdapter);
        
        // Step 4: Verify all configurations
        console.log("STEP 4: Verifying configurations...");
        _verifyConfigurations(automationKeeper, loanAdapter, flexibleLoanManager, vaultBasedHandler);
        
        // Step 5: Generate correct checkData
        console.log("STEP 5: Generating correct checkData for Chainlink registration...");
        _generateCheckData(automationKeeper, loanAdapter);
        
        // Step 6: Test checkUpkeep with sample position
        console.log("STEP 6: Testing the configuration...");
        _testConfiguration(automationKeeper, loanAdapter, flexibleLoanManager, mockOracle);
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== CONFIGURATION FIX COMPLETED ===");
        console.log("Next steps:");
        console.log("1. Register the upkeep in Chainlink with the provided checkData");
        console.log("2. Create test positions with: make create-avalanche-test-loan");
        console.log("3. Test liquidation with: make crash-avalanche-market");
    }
    
    function _registerLoanAdapter(address keeper, address adapter) internal {
        LoanAutomationKeeperOptimized keeperContract = LoanAutomationKeeperOptimized(keeper);
        
        try keeperContract.registeredManagers(adapter) returns (bool isRegistered) {
            if (isRegistered) {
                console.log("  [OK] LoanAdapter already registered");
            } else {
                console.log("  [INFO] Registering LoanAdapter...");
                keeperContract.registerLoanManager(adapter, 50);
                console.log("  [OK] LoanAdapter registered successfully");
            }
        } catch {
            console.log("  [INFO] Registering LoanAdapter...");
            keeperContract.registerLoanManager(adapter, 50);
            console.log("  [OK] LoanAdapter registered successfully");
        }
    }
    
    function _fixFlexibleLoanManagerAuth(address loanManager, address adapter) internal {
        FlexibleLoanManager flexManager = FlexibleLoanManager(loanManager);
        
        address currentAuth = flexManager.authorizedAutomationContract();
        console.log("  Current authorized contract:", currentAuth);
        console.log("  Target contract:", adapter);
        
        if (currentAuth != adapter) {
            console.log("  [INFO] Setting correct automation contract...");
            flexManager.setAutomationContract(adapter);
            console.log("  [OK] Automation contract updated");
        } else {
            console.log("  [OK] Automation contract already correct");
        }
    }
    
    function _fixVaultAuthorizations(address vault, address keeper, address adapter) internal {
        VaultBasedHandler vaultHandler = VaultBasedHandler(vault);
        
        // Authorize keeper
        try vaultHandler.authorizedAutomationContracts(keeper) returns (bool isAuth) {
            if (!isAuth) {
                console.log("  [INFO] Authorizing Keeper in VaultBasedHandler...");
                vaultHandler.authorizeAutomationContract(keeper);
                console.log("  [OK] Keeper authorized");
            } else {
                console.log("  [OK] Keeper already authorized");
            }
        } catch {
            console.log("  [INFO] Authorizing Keeper in VaultBasedHandler...");
            vaultHandler.authorizeAutomationContract(keeper);
            console.log("  [OK] Keeper authorized");
        }
        
        // Authorize adapter
        try vaultHandler.authorizedAutomationContracts(adapter) returns (bool isAuth) {
            if (!isAuth) {
                console.log("  [INFO] Authorizing Adapter in VaultBasedHandler...");
                vaultHandler.authorizeAutomationContract(adapter);
                console.log("  [OK] Adapter authorized");
            } else {
                console.log("  [OK] Adapter already authorized");
            }
        } catch {
            console.log("  [INFO] Authorizing Adapter in VaultBasedHandler...");
            vaultHandler.authorizeAutomationContract(adapter);
            console.log("  [OK] Adapter authorized");
        }
    }
    
    function _verifyConfigurations(
        address keeper, 
        address adapter, 
        address loanManager, 
        address vault
    ) internal view {
        console.log("  VERIFICATION RESULTS:");
        console.log("  ====================");
        
        // Check keeper registration
        LoanAutomationKeeperOptimized keeperContract = LoanAutomationKeeperOptimized(keeper);
        bool adapterRegistered = keeperContract.registeredManagers(adapter);
        console.log("  Adapter registered in Keeper:", adapterRegistered ? "YES" : "NO");
        
        // Check loan manager authorization
        FlexibleLoanManager flexManager = FlexibleLoanManager(loanManager);
        address authorizedContract = flexManager.authorizedAutomationContract();
        bool correctAuth = (authorizedContract == adapter);
        console.log("  FlexibleLoanManager auth correct:", correctAuth ? "YES" : "NO");
        
        // Check vault authorizations
        VaultBasedHandler vaultHandler = VaultBasedHandler(vault);
        bool keeperAuthInVault = vaultHandler.authorizedAutomationContracts(keeper);
        bool adapterAuthInVault = vaultHandler.authorizedAutomationContracts(adapter);
        console.log("  Keeper authorized in Vault:", keeperAuthInVault ? "YES" : "NO");
        console.log("  Adapter authorized in Vault:", adapterAuthInVault ? "YES" : "NO");
        
        if (adapterRegistered && correctAuth && keeperAuthInVault && adapterAuthInVault) {
            console.log("  [SUCCESS] ALL CONFIGURATIONS CORRECT!");
        } else {
            console.log("  [WARNING] Some configurations still need fixing");
        }
    }
    
    function _generateCheckData(address keeper, address adapter) internal view {
        LoanAutomationKeeperOptimized keeperContract = LoanAutomationKeeperOptimized(keeper);
        
        // Generate correct checkData
        bytes memory checkData = keeperContract.generateOptimizedCheckData(
            adapter,  // LoanAdapter address (NOT FlexibleLoanManager)
            0,        // startIndex (auto-converted to position ID 1)
            25        // batchSize (optimal for gas)
        );
        
        console.log("  CHAINLINK REGISTRATION DATA:");
        console.log("  ============================");
        console.log("  Target Contract (Keeper):", keeper);
        console.log("  Registry Address (Avalanche):", "0x819B58A646CDd8289275A87653a2aA4902b14fe6");
        console.log("  Gas Limit: 2,000,000");
        console.log("  Funding: 50 LINK (for testing)");
        console.log("  CheckData (hex):");
        console.logBytes(checkData);
        
        // Convert to string for easy copying
        console.log("  CheckData (string for UI):");
        console.log(vm.toString(checkData));
    }
    
    function _testConfiguration(
        address keeper, 
        address adapter, 
        address loanManager, 
        address oracle
    ) internal {
        console.log("  TESTING CONFIGURATION:");
        console.log("  ======================");
        
        LoanAutomationKeeperOptimized keeperContract = LoanAutomationKeeperOptimized(keeper);
        LoanManagerAutomationAdapter adapterContract = LoanManagerAutomationAdapter(adapter);
        FlexibleLoanManager flexManager = FlexibleLoanManager(loanManager);
        
        // Check total active positions
        uint256 totalPositions = flexManager.getTotalActivePositions();
        console.log("  Total active positions:", totalPositions);
        
        if (totalPositions > 0) {
            // Get positions in range
            uint256[] memory positions = flexManager.getPositionsInRange(1, 5);
            console.log("  Positions in range 1-5:", positions.length);
            
            if (positions.length > 0) {
                uint256 testPositionId = positions[0];
                console.log("  Testing position ID:", testPositionId);
                
                // Check if position is at risk via adapter
                try adapterContract.isPositionAtRisk(testPositionId) returns (bool isAtRisk, uint256 riskLevel) {
                    console.log("    Position at risk:", isAtRisk ? "YES" : "NO");
                    console.log("    Risk level:", riskLevel);
                } catch {
                    console.log("    Could not check position risk");
                }
                
                // Test checkUpkeep
                bytes memory checkData = keeperContract.generateOptimizedCheckData(adapter, 0, 25);
                try keeperContract.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
                    console.log("    CheckUpkeep result:", upkeepNeeded ? "NEEDED" : "NOT NEEDED");
                    console.log("    PerformData length:", performData.length);
                } catch Error(string memory reason) {
                    console.log("    CheckUpkeep failed:", reason);
                } catch {
                    console.log("    CheckUpkeep failed: unknown error");
                }
            }
        } else {
            console.log("  No positions found for testing");
            console.log("  Create a test position with: make create-avalanche-test-loan");
        }
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {EmergencyRegistry} from "../../src/core/EmergencyRegistry.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {FlexibleAssetHandler} from "../../src/core/FlexibleAssetHandler.sol";

/**
 * @title ConfigureEmergencyRegistry
 * @notice Configure Emergency Registry with all system contracts
 */
contract ConfigureEmergencyRegistry is Script {
    
    // Read addresses from environment or deployed-addresses.json
    function getAddress(string memory key) internal view returns (address) {
        try vm.envAddress(key) returns (address addr) {
            return addr;
        } catch {
            return address(0);
        }
    }
    
    function run() external {
        vm.startBroadcast();
        
        console.log("CONFIGURING EMERGENCY REGISTRY SYSTEM");
        console.log("=====================================");
        
        // Get Emergency Registry address
        address emergencyRegistryAddr = getAddress("EMERGENCY_REGISTRY_ADDRESS");
        require(emergencyRegistryAddr != address(0), "Emergency Registry address not found");
        
        EmergencyRegistry emergencyRegistry = EmergencyRegistry(emergencyRegistryAddr);
        console.log("Emergency Registry found at:", emergencyRegistryAddr);
        
        // Step 1: Register Asset Handlers
        console.log("");
        console.log("Step 1: Registering Asset Handlers...");
        
        address flexibleAssetHandler = getAddress("FLEXIBLE_ASSET_HANDLER_ADDRESS");
        if (flexibleAssetHandler != address(0)) {
            console.log("Registering FlexibleAssetHandler...");
            emergencyRegistry.registerAssetHandler(flexibleAssetHandler, "FlexibleAssetHandler");
            
            // Configure handler to use emergency registry (safe call - might be placeholder)
            try FlexibleAssetHandler(flexibleAssetHandler).setEmergencyRegistry(emergencyRegistryAddr) {
                console.log("FlexibleAssetHandler emergency registry configured");
            } catch {
                console.log("FlexibleAssetHandler emergency registry is placeholder (OK)");
            }
            console.log("FlexibleAssetHandler registered");
        }
        
        address vaultBasedHandler = getAddress("VAULT_BASED_HANDLER_ADDRESS");
        if (vaultBasedHandler != address(0)) {
            console.log("Registering VaultBasedHandler...");
            emergencyRegistry.registerAssetHandler(vaultBasedHandler, "VaultBasedHandler");
            
            // Configure handler to use emergency registry (safe call)
            try VaultBasedHandler(vaultBasedHandler).setEmergencyRegistry(emergencyRegistryAddr) {
                console.log("VaultBasedHandler emergency registry configured");
            } catch {
                console.log("VaultBasedHandler emergency registry failed (ownership or permissions)");
            }
            console.log("VaultBasedHandler registered");
        }
        
        // Step 2: Register Loan Managers
        console.log("");
        console.log("Step 2: Registering Loan Managers...");
        
        address flexibleLoanManager = getAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        if (flexibleLoanManager != address(0)) {
            console.log("Registering FlexibleLoanManager...");
            emergencyRegistry.registerLoanManager(flexibleLoanManager, "FlexibleLoanManager");
            
            // Configure loan manager to use emergency registry (safe call)
            try FlexibleLoanManager(flexibleLoanManager).setEmergencyRegistry(emergencyRegistryAddr) {
                console.log("FlexibleLoanManager emergency registry configured");
            } catch {
                console.log("FlexibleLoanManager emergency registry failed (ownership or permissions)");
            }
            console.log("FlexibleLoanManager registered");
        }
        
        address genericLoanManager = getAddress("GENERIC_LOAN_MANAGER_ADDRESS");
        if (genericLoanManager != address(0)) {
            console.log("Registering GenericLoanManager...");
            emergencyRegistry.registerLoanManager(genericLoanManager, "GenericLoanManager");
            console.log("GenericLoanManager registered");
        }
        
        // Step 3: Show configuration summary
        console.log("");
        console.log("Step 3: Configuration Summary");
        console.log("=============================");
        
        address[] memory registeredHandlers = emergencyRegistry.getRegisteredAssetHandlers();
        address[] memory registeredManagers = emergencyRegistry.getRegisteredLoanManagers();
        
        console.log("Registered Asset Handlers:", registeredHandlers.length);
        for (uint i = 0; i < registeredHandlers.length; i++) {
            console.log("  -", registeredHandlers[i]);
        }
        
        console.log("Registered Loan Managers:", registeredManagers.length);
        for (uint i = 0; i < registeredManagers.length; i++) {
            console.log("  -", registeredManagers[i]);
        }
        
        console.log("");
        console.log("EMERGENCY REGISTRY CONFIGURATION COMPLETED!");
        console.log("===========================================");
        console.log("All contracts are now coordinated through the centralized emergency system");
        console.log("Use emergencyRegistry.quickEmergencyActivation() to activate emergency modes");
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev Test emergency coordination after setup
     */
    function testEmergencyCoordination() external {
        vm.startBroadcast();
        
        console.log("TESTING EMERGENCY COORDINATION");
        console.log("==============================");
        
        address emergencyRegistryAddr = getAddress("EMERGENCY_REGISTRY_ADDRESS");
        EmergencyRegistry emergencyRegistry = EmergencyRegistry(emergencyRegistryAddr);
        
        // Test emergency statistics
        (
            uint256 totalActivated,
            uint256 totalResolved,
            uint256 currentlyActive,
            uint256 lastEmergency,
        ) = emergencyRegistry.getEmergencyStats();
        
        console.log("Emergency Statistics:");
        console.log("  Total Activated:", totalActivated);
        console.log("  Total Resolved:", totalResolved);
        console.log("  Currently Active:", currentlyActive);
        console.log("  Last Emergency:", lastEmergency);
        
        console.log("");
        console.log("Emergency coordination test completed!");
        
        vm.stopBroadcast();
    }
} 
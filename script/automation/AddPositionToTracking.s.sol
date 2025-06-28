// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title AddPositionToTracking
 * @notice Agrega la nueva posición al tracking del automation adapter
 */
contract AddPositionToTracking is Script {
    
    function run() external {
        console.log("=== AGREGANDO POSICION AL TRACKING ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(loanAdapter);
        
        console.log("Adapter: ", loanAdapter);
        console.log("Agregando posicion ID: 12");
        console.log("");
        
        // Add position 12 to tracking
        adapter.addPositionToTracking(12);
        
        console.log("SUCCESS: Posicion 12 agregada al tracking");
        console.log("");
        
        // Verify tracking
        (uint256 totalTracked,,,, ) = adapter.getTrackingStats();
        console.log("Total posiciones tracked: ", totalTracked);
        
        vm.stopBroadcast();
        
        console.log("===================================");
        console.log("POSICION AGREGADA EXITOSAMENTE");
        console.log("El automation ahora puede detectar la posicion 12");
    }
} 
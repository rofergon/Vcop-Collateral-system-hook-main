// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title FixAuthorization
 * @notice Autoriza el AutomationKeeper en el LoanAdapter para ejecutar liquidaciones
 */
contract FixAuthorization is Script {
    
    // Direcciones del sistema
    address constant AUTOMATION_KEEPER = 0x15C7298Dd649DcDc17D281cB0dAE84E945573c93;
    address constant LOAN_ADAPTER = 0x6A444D8e037672535879AEF7C668D6d5D15B84d7;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== FIXING AUTOMATION AUTHORIZATION ===");
        console.log("AutomationKeeper:", AUTOMATION_KEEPER);
        console.log("LoanAdapter:", LOAN_ADAPTER);
        console.log("");
        
        // Instanciar adapter
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(LOAN_ADAPTER);
        
        // Verificar estado actual
        address currentAuth = adapter.authorizedAutomationContract();
        console.log("Current authorized contract:", currentAuth);
        
        if (currentAuth == AUTOMATION_KEEPER) {
            console.log("Already correctly authorized!");
            vm.stopBroadcast();
            return;
        }
        
        // Autorizar el keeper
        console.log("Authorizing AutomationKeeper...");
        adapter.setAutomationContract(AUTOMATION_KEEPER);
        
        // Verificar nueva configuracion
        address newAuth = adapter.authorizedAutomationContract();
        console.log("New authorized contract:", newAuth);
        
        if (newAuth == AUTOMATION_KEEPER) {
            console.log("SUCCESS: AutomationKeeper authorized!");
        } else {
            console.log("ERROR: Authorization failed!");
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== AUTHORIZATION FIX COMPLETED ===");
        console.log("Chainlink Automation should now be able to execute liquidations!");
        console.log("Wait 2-3 minutes and check your dashboard for LINK spending.");
    }
} 
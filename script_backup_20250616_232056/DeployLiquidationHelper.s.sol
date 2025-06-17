// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {LiquidationHelper} from "./LiquidationHelper.sol";

/**
 * @title DeployLiquidationHelper
 * @notice Script para desplegar únicamente el LiquidationHelper
 * @dev El sistema core ya está desplegado, solo necesitamos el helper para testing
 */
contract DeployLiquidationHelper is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==================================================");
        console.log("DESPLEGANDO LIQUIDATION HELPER");
        console.log("==================================================");
        console.log("Deployer:", deployer);
        console.log("Network: Base Sepolia");
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy LiquidationHelper
        LiquidationHelper liquidationHelper = new LiquidationHelper();
        
        vm.stopBroadcast();
        
        console.log("==================================================");
        console.log("DESPLIEGUE COMPLETADO");
        console.log("==================================================");
        console.log("LiquidationHelper:", address(liquidationHelper));
        console.log("");
        console.log("Para agregar a deployed-addresses.json:");
        console.log("  liquidationHelper:", address(liquidationHelper));
        console.log("");
                 console.log("NOTA: Copiar esta direccion al script de testing");
        console.log("==================================================");
    }
} 
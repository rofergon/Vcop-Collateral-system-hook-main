// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeployVCOPBase} from "./DeployVCOPBase.sol";
import {ConfigureVCOPSystem} from "./ConfigureVCOPSystem.sol";
import {VCOPOracle} from "../src/VcopCollateral/VCOPOracle.sol";
import {VCOPPriceCalculator} from "../src/VcopCollateral/VCOPPriceCalculator.sol";
import {PoolManagerAddresses} from "./base/PoolManagerAddresses.sol";
import {PositionManagerAddresses} from "./base/PositionManagerAddresses.sol";

/**
 * @title DeployFullSystemFixedParidad
 * @notice Script to deploy the entire VCOP system with corrected paridad (1:1 VCOP/COP)
 * @dev Run with: forge script script/DeployFullSystemFixedParidad.s.sol:DeployFullSystemFixedParidad --broadcast --rpc-url https://sepolia.base.org
 */
contract DeployFullSystemFixedParidad is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        // Get chain ID to use correct contract addresses
        uint256 chainId = block.chainid;
        address poolManagerAddress;
        address positionManagerAddress;
        
        // Use address libraries to get correct addresses for current network
        try this.getPoolManagerAddress(chainId) returns (address poolManager) {
            poolManagerAddress = poolManager;
        } catch {
            // Fallback to environment variables if library doesn't have the chain
            poolManagerAddress = vm.envOr("POOL_MANAGER_ADDRESS", address(0));
            require(poolManagerAddress != address(0), "Pool Manager address not found for this chain");
        }
        
        try this.getPositionManagerAddress(chainId) returns (address positionManager) {
            positionManagerAddress = positionManager;
        } catch {
            // Fallback to environment variables if library doesn't have the chain
            positionManagerAddress = vm.envOr("POSITION_MANAGER_ADDRESS", address(0));
            require(positionManagerAddress != address(0), "Position Manager address not found for this chain");
        }
        
        // Set environment variables for other scripts to use
        vm.setEnv("POOL_MANAGER_ADDRESS", vm.toString(poolManagerAddress));
        vm.setEnv("POSITION_MANAGER_ADDRESS", vm.toString(positionManagerAddress));
        
        // Configurar un gas price mas alto para acelerar las transacciones (3 gwei)
        vm.txGasPrice(3_000_000_000); // 3 gwei
        
        console.log("=== Desplegando sistema completo VCOP con paridad fija 1:1 ===");
        console.log("Deployer address:", deployerAddress);
        console.log("Chain ID:", chainId);
        console.log("Pool Manager address:", poolManagerAddress);
        console.log("Position Manager address:", positionManagerAddress);
        console.log("Gas price configurado: 3 gwei");
        
        // Paso 1: Desplegar los contratos base con DeployVCOPBase
        DeployVCOPBase baseDeployer = new DeployVCOPBase();
        console.log("Ejecutando DeployVCOPBase...");
        
        (
            address usdcAddress, 
            address vcopAddress, 
            address oracleAddress, 
            address collateralManagerAddress
        ) = baseDeployer.run();
        
        console.log("Contratos base desplegados:");
        console.log("USDC:", usdcAddress);
        console.log("VCOP:", vcopAddress);
        console.log("Oracle:", oracleAddress);
        console.log("CollateralManager:", collateralManagerAddress);
        
        // Verificar que el oraculo tenga la configuracion correcta
        vm.startBroadcast(deployerPrivateKey);
        
        VCOPOracle oracle = VCOPOracle(oracleAddress);
        uint256 vcopToCopRate = oracle.getVcopToCopRateView();
        uint256 usdToCopRate = oracle.getUsdToCopRateView();
        
        console.log("Verificando configuracion inicial del oraculo:");
        console.log("VCOP/COP rate inicial:", vcopToCopRate);
        console.log("USD/COP rate inicial:", usdToCopRate);
        
        // Confirmar que ya estamos en la configuracion correcta
        // VCOP/COP deberia ser 1:1 (1,000,000) directamente en el constructor del oraculo
        // Verificamos que tenga el valor esperado
        require(vcopToCopRate == 1000000, "La tasa VCOP/COP inicial no es 1:1 (1,000,000)");
        console.log("Confirmado: La tasa VCOP/COP ya esta correctamente fijada en 1:1");
        
        // Solo para asegurarnos, configuramos la tasa USD/COP
        uint256 expectedUsdToCopRate = 4200000000; // 4200 COP = 1 USD con 6 decimales
        if (usdToCopRate != expectedUsdToCopRate) {
            console.log("Configurando tasa USD/COP a 4200:");
            oracle.setUsdToCopRate(expectedUsdToCopRate);
            console.log("Tasa USD/COP actualizada a:", expectedUsdToCopRate);
        }
        
        vm.stopBroadcast();
        
        // Paso 2: Configurar el sistema con ConfigureVCOPSystem
        ConfigureVCOPSystem configSystem = new ConfigureVCOPSystem();
        console.log("Ejecutando ConfigureVCOPSystem...");
        
        configSystem.run();
        
        console.log("Sistema VCOP completamente desplegado y configurado con paridad fija 1:1");
        console.log("IMPORTANTE: Verificar que las transacciones de swap esten usando la tasa correcta");
        console.log("Prueba con: make swap-usdc-to-vcop AMOUNT=10000000");
        
        // Verificación final de tasas
        vm.startBroadcast(deployerPrivateKey);
        
        vcopToCopRate = oracle.getVcopToCopRateView();
        usdToCopRate = oracle.getUsdToCopRateView();
        
        console.log("=== Verificacion final de tasas ===");
        console.log("VCOP/COP rate:", vcopToCopRate);
        console.log("USD/COP rate:", usdToCopRate);
        console.log("Tasa de conversion esperada: 1 USDC = 4,200 VCOP");
        
        // Calcular tasa efectiva
        uint256 effectiveRate = (usdToCopRate * 1e6) / vcopToCopRate;
        console.log("Tasa efectiva USDC/VCOP:", effectiveRate);
        
        vm.stopBroadcast();
    }
    
    // Helper functions to get contract addresses based on chain ID
    function getPoolManagerAddress(uint256 chainId) external pure returns (address) {
        return PoolManagerAddresses.getPoolManagerByChainId(chainId);
    }
    
    function getPositionManagerAddress(uint256 chainId) external pure returns (address) {
        return PositionManagerAddresses.getPositionManagerByChainId(chainId);
    }
} 
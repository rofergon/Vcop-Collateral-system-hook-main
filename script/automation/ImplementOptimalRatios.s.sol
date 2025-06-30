// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title ImplementOptimalRatios
 * @notice Implementa los ratios optimos para permitir 80% LTV con seguridad
 */
contract ImplementOptimalRatios is Script {
    
    function run() external {
        console.log("=== IMPLEMENTANDO RATIOS OPTIMOS PARA 80% LTV ===");
        console.log("");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        
        address ethToken = vm.parseJsonAddress(json, ".tokens.mockETH");
        address usdcToken = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address wbtcToken = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        VaultBasedHandler vaultHandler = VaultBasedHandler(vaultBasedHandler);
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        console.log("CONFIGURACION OPTIMA PARA 80% LTV:");
        console.log("===================================");
        console.log("");
        
        // MockETH (volatile asset)
        console.log("1. MockETH (Volatil - Buffer conservador):");
        console.log("   - Collateral: 135% (permite 74% LTV max)");
        console.log("   - Liquidacion: 107% (buffer 28%)");
        vaultHandler.updateBothRatios(
            ethToken,
            1350000,  // 135% collateral ratio
            1070000   // 107% liquidation ratio
        );
        
        // MockUSDC (stable asset)
        console.log("2. MockUSDC (Estable - Permite mayor LTV):");
        console.log("   - Collateral: 125% (permite 80% LTV max)");
        console.log("   - Liquidacion: 105% (buffer 20%)");
        vaultHandler.updateBothRatios(
            usdcToken,
            1250000,  // 125% collateral ratio
            1050000   // 105% liquidation ratio
        );
        
        // MockWBTC (volatile asset)
        console.log("3. MockWBTC (Volatil - Buffer conservador):");
        console.log("   - Collateral: 135% (permite 74% LTV max)");
        console.log("   - Liquidacion: 107% (buffer 28%)");
        vaultHandler.updateBothRatios(
            wbtcToken,
            1350000,  // 135% collateral ratio
            1070000   // 107% liquidation ratio
        );
        
        console.log("");
        console.log("AJUSTANDO AUTOMATION PARA NUEVOS RATIOS:");
        console.log("=========================================");
        console.log("- Risk Threshold: 75 (detectar riesgo temprano)");
        console.log("- Cooldown: 180 segundos (balance optimo)");
        
        keeper.setMinRiskThreshold(75); // More sensitive to risk
        keeper.setLiquidationCooldown(180); // Balanced cooldown
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== CONFIGURACION COMPLETADA ===");
        console.log("");
        console.log("RESULTADO:");
        console.log("- MockETH:  Max LTV 74%, liquidacion segura a 107%");
        console.log("- MockUSDC: Max LTV 80%, liquidacion segura a 105%");
        console.log("- MockWBTC: Max LTV 74%, liquidacion segura a 107%");
        console.log("");
        console.log("RECOMENDACIONES DE USO:");
        console.log("=======================");
        console.log("1. Para 80% LTV: Usar SOLO MockUSDC (activo estable)");
        console.log("2. Para ETH/WBTC: Usar maximo 74% LTV (mayor seguridad)");
        console.log("3. Buffer de 20-28% protege contra volatilidad");
        console.log("4. Automation activara a partir de 75% risk level");
        console.log("");
        console.log("ESTO ES SIMILAR A:");
        console.log("- AAVE: USDC permite 90% LTV");
        console.log("- Compound: USDC permite ~92% LTV");
        console.log("- Tu sistema: USDC permite 80% LTV (conservador)");
    }
} 
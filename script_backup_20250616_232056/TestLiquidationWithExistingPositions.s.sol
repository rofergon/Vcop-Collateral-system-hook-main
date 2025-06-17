// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FlexibleLoanManager} from "../src/core/FlexibleLoanManager.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {FlexibleAssetHandler} from "../src/core/FlexibleAssetHandler.sol";
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";
import {IAssetHandler} from "../src/interfaces/IAssetHandler.sol";
import {MockETH} from "../src/mocks/MockETH.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

/**
 * @title TestLiquidationWithExistingPositions
 * @notice Crea nuevas posiciones y las liquida inmediatamente para testing
 */
contract TestLiquidationWithExistingPositions is Script {
    
    // Direcciones desplegadas (ACTUALIZADAS)
    address constant GENERIC_LOAN_MANAGER = 0xd66706C24920eF1eA2b919F349ae56b5C995b431;
    address constant FLEXIBLE_LOAN_MANAGER = 0x92ea2E50733b23F23d0958dab79BBcA1e49F627a;
    address constant FLEXIBLE_ASSET_HANDLER = 0xA5688b57eD0854807085B9c73046FdE548cc43CD;
    
    // Mock tokens (ACTUALIZADOS)
    address constant MOCK_ETH = 0xBec09f97BA8730D7e58CeD55CB5957B0dccD1BE7;
    address constant MOCK_USDC = 0x19F3d0Ca2b49A1097906cFc641a4789807BBC497;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==================================================");
        console.log("CREANDO POSICION LIQUIDABLE PARA TESTING");
        console.log("==================================================");
        console.log("Usuario:", deployer);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        MockETH mockETH = MockETH(MOCK_ETH);
        MockUSDC mockUSDC = MockUSDC(MOCK_USDC);
        GenericLoanManager loanManager = GenericLoanManager(GENERIC_LOAN_MANAGER);
        
        // PASO 1: Mintear tokens
        console.log("=== PASO 1: Minteando tokens ===");
        mockETH.mint(deployer, 2 * 1e18); // 2 ETH
        mockUSDC.mint(deployer, 100000 * 1e6); // 100,000 USDC para liquidacion
        
        console.log("ETH balance:", mockETH.balanceOf(deployer) / 1e18);
        console.log("USDC balance:", mockUSDC.balanceOf(deployer) / 1e6);
        
        // PASO 2: Crear posicion APENAS liquidable
        console.log("");
        console.log("=== PASO 2: Creando posicion riesgosa ===");
        
        uint256 collateralAmount = 1 * 1e18; // 1 ETH
        uint256 loanAmount = 2400 * 1e6;     // $2400 USDC (asumiendo ETH = $2500)
        
        // Configurar approvals
        mockETH.approve(GENERIC_LOAN_MANAGER, collateralAmount);
        
        // Crear posicion con ratio ~104% (justo arriba del umbral 102%)
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: MOCK_ETH,
            loanAsset: MOCK_USDC,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: 980000,  // 98% LTV 
            interestRate: 500000,    // 50% anual para acumular rapido
            duration: 0
        });
        
        uint256 positionId = loanManager.createLoan(terms);
        console.log("Posicion creada con ID:", positionId);
        
        // PASO 3: Verificar estado inicial
        console.log("");
        console.log("=== PASO 3: Estado inicial ===");
        
        uint256 initialRatio = loanManager.getCollateralizationRatio(positionId);
        uint256 initialDebt = loanManager.getTotalDebt(positionId);
        bool initialLiquidable = loanManager.canLiquidate(positionId);
        
        console.log("Ratio inicial:", initialRatio / 10000, "%");
        console.log("Deuda inicial:", initialDebt / 1e6, "USDC");
        console.log("Es liquidable:", initialLiquidable);
        
        // PASO 4: Acelerar tiempo para acumular interes
        console.log("");
        console.log("=== PASO 4: Acumulando interes (30 dias) ===");
        
        vm.warp(block.timestamp + 30 days);
        loanManager.updateInterest(positionId);
        
        uint256 ratioAfterInterest = loanManager.getCollateralizationRatio(positionId);
        uint256 debtAfterInterest = loanManager.getTotalDebt(positionId);
        bool liquidableAfterInterest = loanManager.canLiquidate(positionId);
        
        console.log("Ratio despues de interes:", ratioAfterInterest / 10000, "%");
        console.log("Deuda despues de interes:", debtAfterInterest / 1e6, "USDC");
        console.log("Es liquidable:", liquidableAfterInterest);
        
        // PASO 5: Intentar liquidacion si es posible
        if (liquidableAfterInterest) {
            console.log("");
            console.log("=== PASO 5: Ejecutando liquidacion ===");
            
            // Aprobar USDC para pagar la deuda
            mockUSDC.approve(GENERIC_LOAN_MANAGER, debtAfterInterest);
            
            uint256 ethBalanceBefore = mockETH.balanceOf(deployer);
            uint256 usdcBalanceBefore = mockUSDC.balanceOf(deployer);
            
            console.log("ETH antes:", ethBalanceBefore / 1e18);
            console.log("USDC antes:", usdcBalanceBefore / 1e6);
            
            // Ejecutar liquidacion
            loanManager.liquidatePosition(positionId);
            
            uint256 ethBalanceAfter = mockETH.balanceOf(deployer);
            uint256 usdcBalanceAfter = mockUSDC.balanceOf(deployer);
            
            console.log("ETH despues:", ethBalanceAfter / 1e18);
            console.log("USDC despues:", usdcBalanceAfter / 1e6);
            
            uint256 ethGained = ethBalanceAfter - ethBalanceBefore;
            uint256 usdcSpent = usdcBalanceBefore - usdcBalanceAfter;
            
            console.log("");
            console.log("RESULTADO LIQUIDACION:");
            console.log("- ETH ganado:", ethGained / 1e18);
            console.log("- USDC gastado:", usdcSpent / 1e6);
            console.log("- EXITO: Liquidacion completada!");
            
        } else {
            console.log("");
            console.log("=== POSICION AUN NO ES LIQUIDABLE ===");
            console.log("RAZON: El umbral de liquidacion es muy bajo");
            
            // Obtener configuracion actual
            FlexibleAssetHandler assetHandler = FlexibleAssetHandler(FLEXIBLE_ASSET_HANDLER);
            IAssetHandler.AssetConfig memory config = assetHandler.getAssetConfig(MOCK_ETH);
            
            console.log("Umbral configurado:", config.liquidationRatio / 10000, "%");
            console.log("Ratio actual:", ratioAfterInterest / 10000, "%");
            console.log("NECESITAS ratio menor a:", config.liquidationRatio / 10000, "%");
            
            console.log("");
            console.log("RECOMENDACIONES:");
            console.log("1. Aumentar mas el tiempo (90+ dias)");
            console.log("2. Configurar umbrales menos agresivos");
            console.log("3. Usar FlexibleLoanManager que requiere ratio < 51%");
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("==================================================");
        console.log("TEST DE LIQUIDACION COMPLETADO");
        console.log("==================================================");
    }
} 
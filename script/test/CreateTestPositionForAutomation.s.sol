// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

/**
 * @title CreateTestPositionForAutomation
 * @notice Crea posiciones de prueba que pueden ser liquidadas por el sistema de automatización
 */
contract CreateTestPositionForAutomation is Script {
    
    // Direcciones desde deployed-addresses-mock.json
    address constant FLEXIBLE_LOAN_MANAGER = 0xc8Bf18B4D6B459b17b9298D5Ed6B2feC1f0D9b3D;
    address constant MOCK_ETH = 0x5e2e783F84EF0b6D58115DF458F7F04e593011B7;
    address constant MOCK_USDC = 0xfF63beAFB949ffeb8df366e4738001cf54e97eD1;
    address constant MOCK_ORACLE = 0x8C59715a208FDe0445d7046a6B4612796810C846;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== CREANDO POSICIONES DE PRUEBA PARA AUTOMATION ===");
        console.log("Deployer:", deployer);
        console.log("FlexibleLoanManager:", FLEXIBLE_LOAN_MANAGER);
        console.log("");
        
        // Instanciar contratos
        ILoanManager loanManager = ILoanManager(FLEXIBLE_LOAN_MANAGER);
        MockERC20 ethToken = MockERC20(MOCK_ETH);
        MockERC20 usdcToken = MockERC20(MOCK_USDC);
        MockVCOPOracle oracle = MockVCOPOracle(MOCK_ORACLE);
        
        // Paso 1: Verificar precios actuales
        console.log("PASO 1: Verificando precios actuales...");
        uint256 ethPrice = oracle.getPrice(MOCK_ETH, MOCK_USDC);
        console.log("ETH Price:", ethPrice, "($", ethPrice / 1e6, ")");
        
        // Paso 2: Obtener tokens para colateral
        console.log("PASO 2: Obteniendo tokens para colateral...");
        uint256 collateralAmount = 2 ether; // 2 ETH
        ethToken.mint(deployer, collateralAmount);
        console.log("ETH minted:", collateralAmount);
        
        // Paso 3: Aprobar y crear posicion segura
        console.log("PASO 3: Creando posicion inicial (segura)...");
        ethToken.approve(FLEXIBLE_LOAN_MANAGER, collateralAmount);
        
        uint256 loanAmount = 1500 * 1e6; // 1,500 USDC (ratio ~167% con ETH a $2,500)
        
        uint256 positionId = loanManager.createPosition(
            MOCK_ETH,    // collateral token
            collateralAmount,
            MOCK_USDC,   // loan token
            loanAmount,
            30 days      // duration
        );
        
        console.log("Posicion creada con ID:", positionId);
        console.log("Colateral: 2 ETH");
        console.log("Prestamo: 1,500 USDC");
        
        // Paso 4: Verificar ratio inicial
        uint256 currentRatio = loanManager.getCollateralizationRatio(positionId);
        console.log("Ratio inicial:", currentRatio / 10000, "%");
        
        // Paso 5: Crear posicion mas riesgosa
        console.log("PASO 4: Creando posicion mas riesgosa...");
        ethToken.mint(deployer, collateralAmount);
        ethToken.approve(FLEXIBLE_LOAN_MANAGER, collateralAmount);
        
        uint256 riskierLoan = 2000 * 1e6; // 2,000 USDC (ratio ~125% con ETH a $2,500)
        
        uint256 riskyPositionId = loanManager.createPosition(
            MOCK_ETH,
            collateralAmount,
            MOCK_USDC,
            riskierLoan,
            30 days
        );
        
        console.log("Posicion riesgosa creada con ID:", riskyPositionId);
        console.log("Colateral: 2 ETH");
        console.log("Prestamo: 2,000 USDC");
        
        uint256 riskyRatio = loanManager.getCollateralizationRatio(riskyPositionId);
        console.log("Ratio riesgoso:", riskyRatio / 10000, "%");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== POSICIONES CREADAS PARA TESTING ===");
        console.log("Posicion segura ID:", positionId, "- Ratio:", currentRatio / 10000, "%");
        console.log("Posicion riesgosa ID:", riskyPositionId, "- Ratio:", riskyRatio / 10000, "%");
        console.log("");
        console.log("PARA PROBAR LIQUIDACION:");
        console.log("1. Ejecuta: forge script script/test/CrashETHPrice.s.sol --rpc-url https://sepolia.base.org --broadcast");
        console.log("2. El precio ETH bajara a $1,000");
        console.log("3. La posicion riesgosa sera liquidable (ratio ~100%)");
        console.log("4. Chainlink Automation detectara y liquidara automaticamente");
        console.log("5. Podras ver el gasto de LINK en tu upkeep dashboard");
    }
} 
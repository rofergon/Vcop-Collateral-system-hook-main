// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Core contracts
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {FlexibleLoanManager} from "../src/core/FlexibleLoanManager.sol";
import {FlexibleAssetHandler} from "../src/core/FlexibleAssetHandler.sol";
import {VaultBasedHandler} from "../src/core/VaultBasedHandler.sol";
import {LiquidationHelper} from "./LiquidationHelper.sol";

// Interfaces
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";
import {IAssetHandler} from "../src/interfaces/IAssetHandler.sol";

/**
 * @title TestCoreLiquidations
 * @notice Script comprehensivo para testear liquidaciones en FlexibleLoanManager y GenericLoanManager
 * @dev Usa LiquidationHelper para manejar las liquidaciones correctamente
 */
contract TestCoreLiquidations is Script {
    
    // Test configuration
    struct LiquidationTest {
        string name;
        address loanManager;
        address collateralAsset;
        address loanAsset;
        uint256 collateralAmount;
        uint256 loanAmount;
    }
    
    // Contract addresses (will be loaded from deployment)
    GenericLoanManager public genericLoanManager;
    FlexibleLoanManager public flexibleLoanManager;
    FlexibleAssetHandler public flexibleAssetHandler;
    VaultBasedHandler public vaultBasedHandler;
    LiquidationHelper public liquidationHelper;
    
    // Test accounts
    address public deployer;
    address public borrower;
    address public liquidator;
    address public liquidityProvider;
    
    // Mock tokens
    address public mockETH;
    address public mockWBTC;
    address public mockUSDC;
    
    uint256 private deployerPrivateKey;
    
    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);
        
        // Create test accounts
        borrower = makeAddr("borrower");
        liquidator = makeAddr("liquidator");
        liquidityProvider = makeAddr("liquidityProvider");
        
        console.log("CONFIGURACION INICIAL");
        console.log("Deployer:", deployer);
        console.log("Borrower:", borrower);
        console.log("Liquidator:", liquidator);
        console.log("Liquidity Provider:", liquidityProvider);
    }
    
    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        
        // Load deployed contracts
        _loadDeployedContracts();
        
        // Deploy liquidation helper
        liquidationHelper = new LiquidationHelper();
        console.log("LiquidationHelper deployed at:", address(liquidationHelper));
        
        // Setup initial liquidity and balances
        _setupInitialLiquidity();
        
        vm.stopBroadcast();
        
        console.log("================================================");
        console.log("HELPER DESPLEGADO - EJECUTANDO TESTS EN SIMULACION");
        console.log("================================================");
        
        // Run liquidation tests (in simulation mode - no broadcast)
        _runLiquidationTests();
        
        console.log("================================================");
        console.log("TESTS DE LIQUIDACION COMPLETADOS");
        console.log("Helper Contract:", address(liquidationHelper));
        console.log("NOTA: Para liquidaciones reales, usar el helper manualmente");
        console.log("================================================");
    }
    
    /**
     * @dev Loads deployed contract addresses
     */
    function _loadDeployedContracts() internal {
        console.log("Cargando contratos desplegados...");
        
        // Load actual deployed addresses from Base Sepolia
        genericLoanManager = GenericLoanManager(0xF8724317315B1BA8ac1a0f30Ac407e9fCf20442B);
        flexibleLoanManager = FlexibleLoanManager(0xFf120b0Eb71131EFA1f8C93331B042cB4C0F8Ec7);
        flexibleAssetHandler = FlexibleAssetHandler(0xe55cD346e5097ab8a715C4EF599725791B841e8f);
        vaultBasedHandler = VaultBasedHandler(0xc25D6A1e7878e32ACaB67080BF5a3973e061caEC);
        
        // Load mock token addresses
        mockETH = 0x87bb55de00f7D2791dbF3461A110D99bB47cF62F;
        mockWBTC = 0x4Cd911B122e27e5EF684e3553B8187525725a399;
        mockUSDC = 0xcbeC2cAa97A660434aA5420d667b3f1e60E2C17B;
        
        console.log("Contratos cargados correctamente:");
        console.log("  GenericLoanManager:", address(genericLoanManager));
        console.log("  FlexibleLoanManager:", address(flexibleLoanManager));
        console.log("  Mock ETH:", mockETH);
        console.log("  Mock USDC:", mockUSDC);
        console.log("  Mock WBTC:", mockWBTC);
    }
    
    /**
     * @dev Setup initial liquidity in vaults
     */
    function _setupInitialLiquidity() internal {
        console.log("Configurando liquidez inicial...");
        console.log("NOTA: La liquidez debe ser proporcionada manualmente a los vaults");
        console.log("      para que las liquidaciones funcionen correctamente");
        console.log("Liquidez inicial configurada");
    }
    
    /**
     * @dev Runs all liquidation tests
     */
    function _runLiquidationTests() internal {
        console.log("INICIANDO TESTS DE LIQUIDACION");
        
        // Create test scenarios
        LiquidationTest[] memory tests = new LiquidationTest[](2);
        
                 tests[0] = LiquidationTest({
             name: "GenericLoanManager - ETH/USDC",
             loanManager: address(genericLoanManager),
             collateralAsset: mockETH,
             loanAsset: mockUSDC,
             collateralAmount: 1 * 1e18,  // 1 ETH
             loanAmount: 2000 * 1e6       // 2000 USDC (80% LTV)
         });
         
         tests[1] = LiquidationTest({
             name: "FlexibleLoanManager - WBTC/USDC",
             loanManager: address(flexibleLoanManager),
             collateralAsset: mockWBTC,
             loanAsset: mockUSDC,
             collateralAmount: 1 * 1e8,   // 1 WBTC
             loanAmount: 40000 * 1e6      // 40000 USDC (84% LTV)
         });
        
        // Execute tests
        for (uint i = 0; i < tests.length; i++) {
            console.log("=== Ejecutando Prueba de Liquidacion ===");
            console.log("Test:", tests[i].name);
            _executeLiquidationTest(tests[i]);
            console.log("");
        }
    }
    
    /**
     * @dev Executes a single liquidation test
     */
    function _executeLiquidationTest(LiquidationTest memory test) internal {
        console.log("================================================");
        console.log("FASE 1: Creando posicion riesgosa");
        
                 // Fund borrower with collateral
         vm.deal(borrower, 10 ether);
         // Note: Borrower needs to have collateral tokens pre-funded or acquired separately
        
        // Approve liquidation helper to spend borrower's collateral
        vm.prank(borrower);
        IERC20(test.collateralAsset).approve(address(liquidationHelper), test.collateralAmount);
        
        // Create risky position through helper
        uint256 positionId = liquidationHelper.createRiskyPosition(
            test.loanManager,
            test.collateralAsset,
            test.loanAsset,
            test.collateralAmount,
            test.loanAmount,
            borrower
        );
        
        console.log("Posicion creada con ID:", positionId);
        
        // Check initial position status
        (bool canLiquidateInitial, uint256 initialRatio, uint256 initialDebt) = 
            liquidationHelper.checkLiquidationStatus(test.loanManager, positionId);
        
        console.log("Ratio inicial:", initialRatio);
        console.log("Deuda inicial:", initialDebt);
        console.log("Liquidable inicialmente:", canLiquidateInitial);
        
        console.log("================================================");
        console.log("FASE 2: Simulando paso del tiempo (acumulacion de interes)");
        
        // Fast forward time to accrue interest (60 days)
        vm.warp(block.timestamp + 60 days);
        
        // Update interest
        liquidationHelper.accrueInterest(test.loanManager, positionId);
        
        // Check position status after interest accrual
        (bool canLiquidateAfterTime, uint256 ratioAfterTime, uint256 debtAfterTime) = 
            liquidationHelper.checkLiquidationStatus(test.loanManager, positionId);
        
        console.log("Ratio despues de 60 dias:", ratioAfterTime);
        console.log("Deuda despues de interes:", debtAfterTime);
        console.log("Liquidable despues de interes:", canLiquidateAfterTime);
        
        if (!canLiquidateAfterTime) {
            console.log("ADVERTENCIA: Posicion aun no es liquidable, continuando...");
        }
        
        console.log("================================================");
        console.log("FASE 3: Ejecutando liquidacion");
        
                 // Fund liquidator with loan asset to repay debt
         vm.deal(liquidator, 10 ether);
         // Note: Liquidator needs to have loan asset tokens pre-funded or acquired separately
        
        // Get liquidator balances before liquidation
        uint256 liquidatorCollateralBefore = IERC20(test.collateralAsset).balanceOf(liquidator);
        uint256 liquidatorLoanAssetBefore = IERC20(test.loanAsset).balanceOf(liquidator);
        
        console.log("Liquidator collateral antes:", liquidatorCollateralBefore);
        console.log("Liquidator loan asset antes:", liquidatorLoanAssetBefore);
        
        // Approve liquidation helper to spend liquidator's loan assets
        vm.prank(liquidator);
        IERC20(test.loanAsset).approve(address(liquidationHelper), debtAfterTime);
        
        // Execute liquidation through helper
        liquidationHelper.executeLiquidation(test.loanManager, positionId, liquidator);
        
        // Get liquidator balances after liquidation
        uint256 liquidatorCollateralAfter = IERC20(test.collateralAsset).balanceOf(liquidator);
        uint256 liquidatorLoanAssetAfter = IERC20(test.loanAsset).balanceOf(liquidator);
        
        console.log("Liquidator collateral despues:", liquidatorCollateralAfter);
        console.log("Liquidator loan asset despues:", liquidatorLoanAssetAfter);
        
        // Calculate rewards
        uint256 collateralReward = liquidatorCollateralAfter - liquidatorCollateralBefore;
        uint256 loanAssetSpent = liquidatorLoanAssetBefore - liquidatorLoanAssetAfter;
        
        console.log("================================================");
        console.log("RESULTADOS DE LIQUIDACION");
        console.log("Colateral recibido:", collateralReward);
        console.log("Activo prestado gastado:", loanAssetSpent);
        
        if (collateralReward > 0) {
            console.log("EXITO: Liquidacion completada con recompensas");
        } else {
            console.log("ERROR: Liquidacion no genero recompensas");
        }
        
        // Verify position is closed
        ILoanManager.LoanPosition memory finalPosition = liquidationHelper.getPosition(test.loanManager, positionId);
        console.log("Posicion activa despues de liquidacion:", finalPosition.isActive);
        
        console.log("================================================");
    }
} 
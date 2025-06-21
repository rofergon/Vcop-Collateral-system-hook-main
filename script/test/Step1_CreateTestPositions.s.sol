// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";

/**
 * @title Step1_CreateTestPositions
 * @notice Crea posiciones de prestamo para probar el sistema de automatizacion
 */
contract Step1_CreateTestPositions is Script {
    
    // Direcciones del sistema desplegado
    address constant FLEXIBLE_LOAN_MANAGER = 0xc8Bf18B4D6B459b17b9298D5Ed6B2feC1f0D9b3D;
    address constant LOAN_ADAPTER = 0x6A444D8e037672535879AEF7C668D6d5D15B84d7;
    address constant MOCK_ETH = 0x5e2e783F84EF0b6D58115DF458F7F04e593011B7;
    address constant MOCK_USDC = 0xfF63beAFB949ffeb8df366e4738001cf54e97eD1;
    address constant MOCK_ORACLE = 0x8C59715a208FDe0445d7046a6B4612796810C846;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== STEP 1: CREATING TEST POSITIONS FOR AUTOMATION ===");
        console.log("Deployer:", deployer);
        console.log("FlexibleLoanManager:", FLEXIBLE_LOAN_MANAGER);
        console.log("LoanAdapter:", LOAN_ADAPTER);
        console.log("");
        
        // Instanciar contratos
        ILoanManager loanManager = ILoanManager(FLEXIBLE_LOAN_MANAGER);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(LOAN_ADAPTER);
        MockERC20 ethToken = MockERC20(MOCK_ETH);
        MockERC20 usdcToken = MockERC20(MOCK_USDC);
        MockVCOPOracle oracle = MockVCOPOracle(MOCK_ORACLE);
        
        // Verificar precio actual de ETH
        console.log("Verificando precio actual...");
        uint256 ethPrice = oracle.getPrice(MOCK_ETH, MOCK_USDC);
        console.log("ETH Price:", ethPrice / 1e6, "USD");
        
        // Verificar estado del adapter
        console.log("Automation enabled:", adapter.isAutomationEnabled());
        console.log("Total positions before:", adapter.getTotalActivePositions());
        
        // Crear Posicion 1: Conservadora (ratio ~200%)
        console.log("");
        console.log("Creating Position 1: Conservative...");
        _createPosition(
            ethToken,
            loanManager,
            adapter,
            1 ether,        // 1 ETH collateral
            1200 * 1e6,     // 1,200 USDC loan (~208% ratio at $2,500 ETH)
            "Conservative"
        );
        
        // Crear Posicion 2: Moderada (ratio ~150%)
        console.log("");
        console.log("Creating Position 2: Moderate...");
        _createPosition(
            ethToken,
            loanManager,
            adapter,
            1 ether,        // 1 ETH collateral
            1650 * 1e6,     // 1,650 USDC loan (~151% ratio at $2,500 ETH)
            "Moderate"
        );
        
        // Crear Posicion 3: Riesgosa (ratio ~125%)
        console.log("");
        console.log("Creating Position 3: Risky...");
        _createPosition(
            ethToken,
            loanManager,
            adapter,
            1 ether,        // 1 ETH collateral
            2000 * 1e6,     // 2,000 USDC loan (~125% ratio at $2,500 ETH)
            "Risky"
        );
        
        vm.stopBroadcast();
        
        // Verificar estado final
        console.log("");
        console.log("=== FINAL STATE ===");
        console.log("Total positions after:", adapter.getTotalActivePositions());
        
        console.log("");
        console.log("SUCCESS: Test positions created!");
        console.log("Next step: Run Step2_CrashPrices.s.sol to trigger liquidations");
        console.log("");
        console.log("Expected after price crash (ETH to $1,000):");
        console.log("- Position 1: ~120% ratio (SAFE)");
        console.log("- Position 2: ~60% ratio (LIQUIDATABLE)");
        console.log("- Position 3: ~50% ratio (LIQUIDATABLE)");
    }
    
    function _createPosition(
        MockERC20 ethToken,
        ILoanManager loanManager,
        LoanManagerAutomationAdapter adapter,
        uint256 collateralAmount,
        uint256 loanAmount,
        string memory positionType
    ) internal {
        
        // Mint collateral tokens
        ethToken.mint(msg.sender, collateralAmount);
        
        // Approve loan manager
        ethToken.approve(FLEXIBLE_LOAN_MANAGER, collateralAmount);
        
        // Create loan terms
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: MOCK_ETH,
            loanAsset: MOCK_USDC,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: 9000000, // 900% max LTV (very high for testing)
            interestRate: 50000,     // 5% annual interest
            duration: 0              // 0 = perpetual loan
        });
        
        // Create position
        uint256 positionId = loanManager.createLoan(terms);
        
        // Add to automation tracking
        adapter.addPositionToTracking(positionId);
        
        // Get collateralization ratio
        uint256 ratio = loanManager.getCollateralizationRatio(positionId);
        
        console.log(string.concat(positionType, " Position Created:"));
        console.log("  Position ID:", positionId);
        console.log("  Collateral:", collateralAmount / 1e18, "ETH");
        console.log("  Loan:", loanAmount / 1e6, "USDC");
        console.log("  Ratio:", ratio / 10000, "%");
        
        // Check if position is at risk
        (bool isAtRisk, uint256 riskLevel) = adapter.isPositionAtRisk(positionId);
        console.log("  At Risk:", isAtRisk);
        console.log("  Risk Level:", riskLevel);
    }
} 
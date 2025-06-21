// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title Step2_CrashPrices
 * @notice Crashea precios para hacer liquidables las posiciones y activar la automatizacion
 */
contract Step2_CrashPrices is Script {
    
    // Direcciones del sistema desplegado
    address constant MOCK_ORACLE = 0x8C59715a208FDe0445d7046a6B4612796810C846;
    address constant FLEXIBLE_LOAN_MANAGER = 0xc8Bf18B4D6B459b17b9298D5Ed6B2feC1f0D9b3D;
    address constant LOAN_ADAPTER = 0x6A444D8e037672535879AEF7C668D6d5D15B84d7;
    address constant MOCK_ETH = 0x5e2e783F84EF0b6D58115DF458F7F04e593011B7;
    address constant MOCK_USDC = 0xfF63beAFB949ffeb8df366e4738001cf54e97eD1;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== STEP 2: CRASHING PRICES TO TRIGGER LIQUIDATIONS ===");
        console.log("");
        
        // Instanciar contratos
        MockVCOPOracle oracle = MockVCOPOracle(MOCK_ORACLE);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(LOAN_ADAPTER);
        ILoanManager loanManager = ILoanManager(FLEXIBLE_LOAN_MANAGER);
        
        // Verificar estado antes del crash
        console.log("PRE-CRASH STATE:");
        console.log("================");
        uint256 ethPrice = oracle.getPrice(MOCK_ETH, MOCK_USDC);
        console.log("Current ETH Price:", ethPrice / 1e6, "USD");
        
        uint256 totalPositions = adapter.getTotalActivePositions();
        console.log("Total active positions:", totalPositions);
        
        // Verificar ratios de cada posicion antes del crash
        _checkAllPositions(adapter, loanManager, "BEFORE CRASH");
        
        console.log("");
        console.log("EXECUTING PRICE CRASH...");
        console.log("========================");
        
        // CRASH: ETH de $2,500 a $1,000 (60% drop)
        uint256 newETHPrice = 1000 * 1e6; // $1,000
        oracle.setEthPrice(newETHPrice);
        
        console.log("ETH price crashed from $2,500 to $1,000 (-60%)");
        console.log("New ETH Price:", newETHPrice / 1e6, "USD");
        
        // Verificar precio actualizado
        uint256 updatedPrice = oracle.getPrice(MOCK_ETH, MOCK_USDC);
        console.log("Verified new price:", updatedPrice / 1e6, "USD");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("POST-CRASH STATE:");
        console.log("=================");
        
        // Verificar ratios despues del crash
        _checkAllPositions(adapter, loanManager, "AFTER CRASH");
        
        console.log("");
        console.log("=== CRASH COMPLETED ===");
        console.log("Chainlink Automation should detect liquidatable positions");
        console.log("Expected timeline:");
        console.log("- Next minute: checkUpkeep will return true");
        console.log("- Within 2 minutes: performUpkeep will execute liquidations");
        console.log("- LINK balance will decrease with each liquidation");
        console.log("");
        console.log("Run Step3_VerifyLiquidations.s.sol to check results");
    }
    
    function _checkAllPositions(
        LoanManagerAutomationAdapter adapter,
        ILoanManager loanManager,
        string memory phase
    ) internal view {
        console.log("");
        console.log("Position Status -", phase);
        console.log("====================================");
        
        uint256 totalPositions = adapter.getTotalActivePositions();
        
        if (totalPositions == 0) {
            console.log("No active positions found");
            return;
        }
        
        // Get all positions
        uint256[] memory positions = adapter.getPositionsInRange(0, totalPositions - 1);
        
        uint256 liquidatableCount = 0;
        uint256 atRiskCount = 0;
        
        for (uint256 i = 0; i < positions.length; i++) {
            uint256 positionId = positions[i];
            
            try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
                (bool isAtRisk, uint256 riskLevel) = adapter.isPositionAtRisk(positionId);
                bool canLiquidate = loanManager.canLiquidate(positionId);
                
                console.log("Position", positionId, ":");
                console.log("  Ratio:", ratio / 10000, "%");
                console.log("  Risk Level:", riskLevel);
                console.log("  At Risk:", isAtRisk);
                console.log("  Can Liquidate:", canLiquidate);
                
                if (canLiquidate) liquidatableCount++;
                if (isAtRisk) atRiskCount++;
                
            } catch {
                console.log("Position", positionId, ": ERROR reading ratio");
            }
        }
        
        console.log("");
        console.log("Summary:", phase);
        console.log("- Total Positions:", totalPositions);
        console.log("- At Risk:", atRiskCount);
        console.log("- Liquidatable:", liquidatableCount);
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title GenerateNewRiskyPositions
 * @notice Crea posiciones frescas para seguir probando automation
 */
contract GenerateNewRiskyPositions is Script {
    
    function run() external {
        console.log("==========================================");
        console.log("GENERANDO NUEVAS POSICIONES PARA TESTING");
        console.log("==========================================");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address loanManagerAddr = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address keeperAddr = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address oracleAddr = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(loanManagerAddr);
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(keeperAddr);
        MockVCOPOracle oracle = MockVCOPOracle(oracleAddr);
        
        vm.startBroadcast();
        
        // 1. Reset prices to normal levels
        console.log("1. Reseteando precios a niveles normales...");
        oracle.setCurrentMarketDefaults();
        (uint256 ethPrice,,,) = oracle.getCurrentMarketPrices();
        console.log("   ETH Price reset to: $", ethPrice / 1e6);
        
        // 2. Create new risky positions
        console.log("");
        console.log("2. Creando posiciones con alta apalancamiento...");
        
        uint256[] memory newPositions = new uint256[](3);
        
        // Position 1: Very leveraged (will be risky with small price drop)
        newPositions[0] = createHighLeveragePosition(mockETH, mockUSDC, 1.5 ether, 2200 * 1e6, loanManager);
        console.log("   Position A created:", newPositions[0], "- Leverage: ~85%");
        
        // Position 2: Moderately leveraged  
        newPositions[1] = createHighLeveragePosition(mockETH, mockUSDC, 2 ether, 2800 * 1e6, loanManager);
        console.log("   Position B created:", newPositions[1], "- Leverage: ~80%");
        
        // Position 3: High leverage
        newPositions[2] = createHighLeveragePosition(mockETH, mockUSDC, 1 ether, 1400 * 1e6, loanManager);
        console.log("   Position C created:", newPositions[2], "- Leverage: ~82%");
        
        // 3. Show initial health
        console.log("");
        console.log("3. Estado inicial de posiciones:");
        for (uint256 i = 0; i < newPositions.length; i++) {
            showPositionHealth(newPositions[i], loanManager);
        }
        
        // 4. Simulate moderate price drop to create liquidatable positions
        console.log("");
        console.log("4. Simulando caida de precios del 25%...");
        oracle.simulateMarketCrash(25); // 25% drop
        
        (ethPrice,,,) = oracle.getCurrentMarketPrices();
        console.log("   New ETH Price: $", ethPrice / 1e6, "(-25%)");
        
        // 5. Show positions after price drop
        console.log("");
        console.log("5. Estado despues de la caida:");
        for (uint256 i = 0; i < newPositions.length; i++) {
            showPositionHealth(newPositions[i], loanManager);
        }
        
        // 6. Test checkUpkeep
        console.log("");
        console.log("6. Verificando automation trigger...");
        
        bytes memory checkData = keeper.generateOptimizedCheckData(
            loanManagerAddr,
            0,
            25
        );
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("   CheckUpkeep result:");
            console.log("      Upkeep needed:", upkeepNeeded);
            console.log("      PerformData length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("   CHAINLINK SHOULD EXECUTE LIQUIDATIONS!");
            } else {
                console.log("   No liquidations needed yet");
            }
        } catch Error(string memory reason) {
            console.log("   CheckUpkeep failed:", reason);
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("==========================================");
        console.log("NUEVAS POSICIONES LISTAS PARA TESTING");
        console.log("==========================================");
        console.log("");
        console.log("Monitor your upkeep at:");
        console.log("https://automation.chain.link/base-sepolia/113929943640819780336579342444342105693806060483669440168281813464087586560700");
        console.log("");
        console.log("Posiciones creadas:", newPositions[0], ",", newPositions[1], ",", newPositions[2]);
    }
    
    function createHighLeveragePosition(
        address collateralAsset,
        address loanAsset,
        uint256 collateralAmount,
        uint256 loanAmount,
        FlexibleLoanManager loanManager
    ) internal returns (uint256 positionId) {
        
        // Mint collateral
        (bool success,) = collateralAsset.call(
            abi.encodeWithSignature("mint(address,uint256)", msg.sender, collateralAmount)
        );
        require(success, "Failed to mint collateral");
        
        // Approve loan manager
        IERC20(collateralAsset).approve(address(loanManager), collateralAmount);
        
        // Create high-leverage loan terms
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: collateralAsset,
            loanAsset: loanAsset,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: 850000, // 85% max LTV - very risky!
            interestRate: 75000, // 7.5% higher interest
            duration: 0 // Perpetual
        });
        
        // Create position
        positionId = loanManager.createLoan(terms);
    }
    
    function showPositionHealth(uint256 positionId, FlexibleLoanManager loanManager) internal view {
        try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
            bool canLiquidate = loanManager.canLiquidate(positionId);
            string memory status = canLiquidate ? "LIQUIDATABLE" : 
                                 (ratio < 130000) ? "AT RISK" : "HEALTHY";
            
            console.log("   Position", positionId, "- Ratio:", ratio / 10000, "% -", status);
        } catch {
            console.log("   Position", positionId, "- ERROR getting ratio");
        }
    }
} 
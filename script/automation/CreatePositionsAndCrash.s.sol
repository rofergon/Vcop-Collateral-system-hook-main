// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title CreatePositionsAndCrash
 * @notice Creates liquidatable positions to test Chainlink automation
 */
contract CreatePositionsAndCrash is Script {
    
    function run() external {
        console.log("===================================");
        console.log("CREATING POSITIONS FOR AUTOMATION");
        console.log("===================================");
        
        // Load addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        address mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        VaultBasedHandler vaultHandler = VaultBasedHandler(vaultBasedHandler);
        MockVCOPOracle oracle = MockVCOPOracle(mockOracle);
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("MockOracle:", mockOracle);
        
        vm.startBroadcast();
        
        // Set realistic prices
        oracle.setCurrentMarketDefaults();
        oracle.setMockTokens(mockETH, address(0), mockUSDC);
        console.log(">> Market prices set to realistic 2025 values");
        
        // Configure ETH asset
        try vaultHandler.configureAsset(
            mockETH,
            1500000, // 150% collateral ratio
            1200000, // 120% liquidation ratio
            1000000 * 1e18, // 1M max loan
            50000    // 5% interest rate
        ) {
            console.log(">> ETH asset configured");
        } catch {
            console.log(">> ETH already configured");
        }
        
        // Create risky positions
        console.log("");
        console.log("Creating risky positions...");
        
        // Position 1: 1 ETH collateral, $2000 loan (close to liquidation)
        uint256 pos1 = createPosition(mockETH, mockUSDC, 1 ether, 2000 * 1e6);
        console.log("Position 1 created:", pos1);
        
        // Position 2: 1.5 ETH collateral, $3200 loan (very risky)
        uint256 pos2 = createPosition(mockETH, mockUSDC, 1.5 ether, 3200 * 1e6);
        console.log("Position 2 created:", pos2);
        
        // Position 3: 2 ETH collateral, $4800 loan (extremely risky)
        uint256 pos3 = createPosition(mockETH, mockUSDC, 2 ether, 4800 * 1e6);
        console.log("Position 3 created:", pos3);
        
        console.log("");
        console.log("Initial positions created at 2500 ETH price");
        
        // Crash market to trigger liquidations
        console.log("");
        console.log("CRASHING MARKET BY 50%...");
        oracle.simulateMarketCrash(50); // 50% crash: ETH $2500 -> $1250
        
        console.log("ETH price after crash: $1250");
        console.log(">> Positions should now be liquidatable!");
        
        // Check liquidation status
        console.log("");
        console.log("LIQUIDATION STATUS:");
        for (uint256 i = 1; i <= 3; i++) {
            uint256 posId = i == 1 ? pos1 : (i == 2 ? pos2 : pos3);
            
            try loanManager.canLiquidate(posId) returns (bool canLiquidate) {
                try loanManager.getCollateralizationRatio(posId) returns (uint256 ratio) {
                    console.log("Position %s - Ratio: %s%% - Liquidatable: %s", i, ratio / 10000, canLiquidate);
                } catch {
                    console.log("Position %s - Error getting ratio", i);
                }
            } catch {
                console.log("Position", i, "- Error checking liquidation");
            }
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=========================================");
        console.log("POSITIONS READY FOR CHAINLINK AUTOMATION");
        console.log("=========================================");
        console.log("");
        console.log("Next steps:");
        console.log("1. Check your upkeep at:");
        console.log("   https://automation.chain.link/base-sepolia");
        console.log("2. Ensure upkeep has LINK balance");
        console.log("3. Wait for Chainlink nodes to detect liquidations");
        console.log("4. Monitor automatic execution");
        console.log("");
        console.log("Your Upkeep ID:");
        console.log("113929943640819780336579342444342105693806060483669440168281813464087586560700");
    }
    
    function createPosition(
        address collateralAsset,
        address loanAsset,
        uint256 collateralAmount,
        uint256 loanAmount
    ) internal returns (uint256 positionId) {
        
        // Load loan manager address
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        
        // Mint collateral
        (bool success,) = collateralAsset.call(
            abi.encodeWithSignature("mint(address,uint256)", msg.sender, collateralAmount)
        );
        require(success, "Failed to mint collateral");
        
        // Approve loan manager
        IERC20(collateralAsset).approve(flexibleLoanManager, collateralAmount);
        
        // Create loan terms
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: collateralAsset,
            loanAsset: loanAsset,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: 800000, // 80% max LTV
            interestRate: 50000, // 5%
            duration: 0 // Perpetual loan
        });
        
        // Create loan position
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        positionId = loanManager.createLoan(terms);
    }
} 
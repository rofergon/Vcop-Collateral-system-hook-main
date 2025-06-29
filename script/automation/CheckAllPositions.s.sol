// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title CheckAllPositions
 * @notice Verifica todas las posiciones existentes y crea nuevas si es necesario
 */
contract CheckAllPositions is Script {
    
    address public flexibleLoanManager;
    address public automationAdapter;
    address public mockUSDC;
    address public mockETH;
    
    function run() external {
        console.log("=== CHECKING ALL POSITIONS ===");
        console.log("");
        
        loadAddresses();
        checkExistingPositions();
        createNewPositionsForTest();
    }
    
    function loadAddresses() internal {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        automationAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("AutomationAdapter:", automationAdapter);
        console.log("");
    }
    
    function checkExistingPositions() internal view {
        console.log("=== EXISTING POSITIONS (1-10) ===");
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        
        uint256 nextPositionId = loanManager.nextPositionId();
        console.log("Next position ID:", nextPositionId);
        
        uint256 activeCount = 0;
        uint256 trackedCount = 0;
        
        for (uint256 i = 1; i < nextPositionId && i <= 10; i++) {
            try loanManager.getPosition(i) returns (FlexibleLoanManager.LoanPosition memory position) {
                if (position.borrower != address(0)) {
                    console.log("");
                    console.log("Position", i, ":");
                    console.log("  Borrower:", position.borrower);
                    console.log("  Active:", position.isActive);
                    
                    if (position.isActive) {
                        activeCount++;
                        console.log("  Collateral:", position.collateralAmount / 1e18, "ETH");
                        console.log("  Loan:", position.loanAmount / 1e6, "USDC");
                        
                        // Check tracking
                        bool isTracked = adapter.isPositionTracked(i);
                        console.log("  Tracked:", isTracked);
                        if (isTracked) trackedCount++;
                        
                        // Check collateralization ratio
                        try loanManager.getCollateralizationRatio(i) returns (uint256 ratio) {
                            console.log("  Ratio:", ratio / 10000, "%");
                        } catch {
                            console.log("  Ratio: Error");
                        }
                        
                        // Check if liquidatable
                        try loanManager.canLiquidate(i) returns (bool canLiq) {
                            console.log("  Liquidatable:", canLiq);
                        } catch {
                            console.log("  Liquidatable: Error");
                        }
                    }
                }
            } catch {
                // Position doesn't exist
            }
        }
        
        console.log("");
        console.log("SUMMARY:");
        console.log("Active positions:", activeCount);
        console.log("Tracked positions:", trackedCount);
        console.log("");
    }
    
    function createNewPositionsForTest() internal {
        console.log("=== CREATING NEW POSITIONS FOR TEST ===");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        IERC20 ethToken = IERC20(mockETH);
        IERC20 usdcToken = IERC20(mockUSDC);
        
        address deployer = vm.addr(deployerPrivateKey);
        
        // Check balances
        uint256 ethBalance = ethToken.balanceOf(deployer);
        uint256 usdcBalance = usdcToken.balanceOf(deployer);
        
        console.log("Deployer ETH balance:", ethBalance / 1e18);
        console.log("Deployer USDC balance:", usdcBalance / 1e6);
        
        // Mint tokens if needed
        if (ethBalance < 5 * 1e18) {
            console.log("Minting ETH...");
            (bool success,) = mockETH.call(abi.encodeWithSignature("mint(address,uint256)", deployer, 10 * 1e18));
            require(success, "Failed to mint ETH");
        }
        
        if (usdcBalance < 10000 * 1e6) {
            console.log("Minting USDC...");
            (bool success,) = mockUSDC.call(abi.encodeWithSignature("mint(address,uint256)", deployer, 20000 * 1e6));
            require(success, "Failed to mint USDC");
        }
        
        // Create 2 test positions
        console.log("");
        console.log("Creating test positions...");
        
        // Position 1: 1 ETH collateral, 1500 USDC loan (risky with current prices)
        uint256 collateral1 = 1 * 1e18; // 1 ETH
        uint256 loan1 = 1500 * 1e6;     // 1500 USDC
        
        console.log("Position 1: 1 ETH -> 1500 USDC");
        createPosition(loanManager, collateral1, loan1);
        
        // Position 2: 2 ETH collateral, 3000 USDC loan (very risky)
        uint256 collateral2 = 2 * 1e18; // 2 ETH
        uint256 loan2 = 3000 * 1e6;     // 3000 USDC
        
        console.log("Position 2: 2 ETH -> 3000 USDC");
        createPosition(loanManager, collateral2, loan2);
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("New positions created!");
        console.log("Check them with the automation system now.");
    }
    
    function createPosition(FlexibleLoanManager loanManager, uint256 collateralAmount, uint256 loanAmount) internal {
        IERC20 ethToken = IERC20(mockETH);
        
        // Approve collateral
        ethToken.approve(address(loanManager), collateralAmount);
        
        // Create loan terms
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: mockETH,
            loanAsset: mockUSDC,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: 950000, // 95% LTV (very risky)
            interestRate: 50000,    // 5% interest rate
            duration: 0             // Perpetual loan
        });
        
        // Create position
        uint256 positionId = loanManager.createLoan(terms);
        console.log("  Created position ID:", positionId);
        
        // Calculate ratio
        try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
            console.log("  Initial ratio:", ratio / 10000, "%");
        } catch {
            console.log("  Could not calculate ratio");
        }
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title TestLiquidationWithNewVault
 * @notice Crea nuevas posiciones liquidables para probar el sistema de automation
 */
contract TestLiquidationWithNewVault is Script {
    
    // Direcciones del sistema
    address constant FLEXIBLE_LOAN_MANAGER = 0x9cAF99FDfAFdc412aAE2914cDB368E1806449B24;
    address constant MOCK_ORACLE = 0x377100B614BFB71ca489b2F0f1b2C82Ea8f88081;
    address constant MOCK_ETH = 0xff40519308154839EF5772CccE6012ccDEf5b32a;
    address constant MOCK_USDC = 0xabA8AFd2C637c27d09A893fe048A74f94D74108B;
    
    function run() external {
        console.log("=== TESTING LIQUIDATION WITH NEW VAULT ===");
        console.log("");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer:", deployer);
        console.log("FlexibleLoanManager:", FLEXIBLE_LOAN_MANAGER);
        console.log("");
        
        // Check balances first
        uint256 ethBalance = IERC20(MOCK_ETH).balanceOf(deployer);
        uint256 usdcBalance = IERC20(MOCK_USDC).balanceOf(deployer);
        
        console.log("DEPLOYER BALANCES:");
        console.log("==================");
        console.log("ETH:", ethBalance / 1e18);
        console.log("USDC:", usdcBalance / 1e6);
        console.log("");
        
        if (ethBalance < 10 * 1e18) {
            console.log("ERROR: Insufficient ETH balance for testing");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(FLEXIBLE_LOAN_MANAGER);
        MockVCOPOracle oracle = MockVCOPOracle(MOCK_ORACLE);
        
        // STEP 1: Set ETH price high initially (for loan creation)
        console.log("STEP 1: Setting high ETH price for loan creation...");
        oracle.setMockPrice(MOCK_ETH, MOCK_USDC, 2500 * 1e8); // $2500
        console.log("ETH price set to $2500");
        
        // STEP 2: Create risky position
        console.log("");
        console.log("STEP 2: Creating risky test position...");
        
        uint256 collateralAmount = 1 * 1e18; // 1 ETH
        uint256 loanAmount = 2000 * 1e6;    // $2000 USDC (125% ratio at $2500 ETH)
        
        // Approve tokens
        IERC20(MOCK_ETH).approve(FLEXIBLE_LOAN_MANAGER, collateralAmount);
        
        // Create loan terms
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: MOCK_ETH,
            loanAsset: MOCK_USDC,
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: 800000,  // 80% max LTV
            interestRate: 80000,     // 8% APR
            duration: 365 days       // 1 year
        });
        
        // Create position
        uint256 positionId = loanManager.createLoan(terms);
        console.log("Created position ID:", positionId);
        console.log("- Collateral: 1 ETH");
        console.log("- Loan: 2000 USDC");
        console.log("- Initial ratio: 125%");
        
        // STEP 3: Crash ETH price to make position liquidatable
        console.log("");
        console.log("STEP 3: Crashing ETH price for liquidation...");
        oracle.setMockPrice(MOCK_ETH, MOCK_USDC, 1000 * 1e8); // Crash to $1000
        console.log("ETH price crashed to $1000");
        
        // Calculate new ratio
        uint256 newRatio = loanManager.getCollateralizationRatio(positionId);
        console.log("New collateralization ratio:", newRatio / 100, "%");
        
        bool canLiquidate = loanManager.canLiquidate(positionId);
        console.log("Position can be liquidated:", canLiquidate);
        
        if (canLiquidate) {
            console.log("SUCCESS: Position is ready for automation liquidation!");
        } else {
            console.log("WARNING: Position is not liquidatable");
        }
        
        vm.stopBroadcast();
        
        // STEP 4: Monitor position for liquidation
        console.log("");
        console.log("STEP 4: Position created and ready for monitoring");
        console.log("===============================================");
        console.log("Position ID:", positionId);
        console.log("Current ETH price: $1000");
        console.log("Collateral ratio:", newRatio / 100, "%");
        console.log("Liquidatable:", canLiquidate);
        console.log("");
        console.log("NEXT STEPS:");
        console.log("1. Wait 1-2 minutes for Chainlink automation to detect");
        console.log("2. Run verification script to check liquidation");
        console.log("3. Monitor vault activity and position status");
        console.log("");
        console.log("MONITORING COMMANDS:");
        console.log("forge script script/automation/VerifyLiquidationsWorking.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL -v");
    }
} 
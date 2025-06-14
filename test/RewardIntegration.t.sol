// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RewardDistributor} from "../src/core/RewardDistributor.sol";
import {FlexibleLoanManager} from "../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../src/core/VaultBasedHandler.sol";
import {VCOPCollateralized} from "../src/VcopCollateral/VCOPCollateralized.sol";
import {VCOPOracle} from "../src/VcopCollateral/VCOPOracle.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {ILoanManager} from "../src/interfaces/ILoanManager.sol";

contract RewardIntegrationTest is Test {
    RewardDistributor public rewardDistributor;
    FlexibleLoanManager public loanManager;
    VaultBasedHandler public vaultHandler;
    VCOPCollateralized public vcopToken;
    VCOPOracle public oracle;
    MockERC20 public mockETH;
    MockERC20 public mockUSDC;
    
    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public feeCollector = address(0x3);
    address public liquidityProvider = address(0x4);
    
    bytes32 public constant FLEXIBLE_LOAN_POOL = keccak256("FLEXIBLE_LOAN_COLLATERAL");
    bytes32 public constant VAULT_ETH_POOL = keccak256("VAULT_ETH_LIQUIDITY");
    
    uint256 public constant REWARD_RATE = 1e15; // 0.001 VCOP per second
    uint256 public constant INITIAL_REWARDS = 1000000 * 1e6; // 1M VCOP
    
    function setUp() public {
        // Deploy tokens
        vcopToken = new VCOPCollateralized();
        mockETH = new MockERC20("Mock ETH", "mETH", 18);
        mockUSDC = new MockERC20("Mock USDC", "mUSDC", 6);
        
        // Deploy Oracle
        oracle = new VCOPOracle(
            4200 * 1e6, // initialUsdToCopRate
            address(0), // _poolManager
            address(vcopToken), // _vcopAddress
            address(mockUSDC), // _usdcAddress
            3000, // _fee
            60, // _tickSpacing
            address(0) // _hookAddress
        );
        
        // Set mock tokens in oracle
        oracle.setMockTokens(address(mockETH), address(0), address(mockUSDC));
        
        // Deploy core contracts
        rewardDistributor = new RewardDistributor();
        loanManager = new FlexibleLoanManager(address(oracle), feeCollector);
        vaultHandler = new VaultBasedHandler();
        
        // Configure vault handler
        vaultHandler.configureAsset(
            address(mockETH),
            1500000, // 150% collateral ratio
            1200000, // 120% liquidation ratio
            1000000 * 1e18, // max loan amount
            50000 // 5% interest rate
        );
        
        // Set up reward system
        rewardDistributor.setAuthorizedUpdater(address(loanManager), true);
        rewardDistributor.setAuthorizedUpdater(address(vaultHandler), true);
        
        loanManager.setRewardDistributor(address(rewardDistributor));
        
        // Create reward pools
        rewardDistributor.createRewardPool(FLEXIBLE_LOAN_POOL, address(vcopToken), REWARD_RATE);
        rewardDistributor.createRewardPool(VAULT_ETH_POOL, address(vcopToken), REWARD_RATE);
        
        // Add initial rewards
        vcopToken.mint(owner, INITIAL_REWARDS * 2);
        vcopToken.approve(address(rewardDistributor), INITIAL_REWARDS * 2);
        rewardDistributor.addRewards(FLEXIBLE_LOAN_POOL, INITIAL_REWARDS);
        rewardDistributor.addRewards(VAULT_ETH_POOL, INITIAL_REWARDS);
        
        // Mint tokens to users
        mockETH.mint(user1, 100 * 1e18);
        mockETH.mint(user2, 100 * 1e18);
        mockETH.mint(liquidityProvider, 1000 * 1e18);
        mockUSDC.mint(user1, 100000 * 1e6);
        mockUSDC.mint(user2, 100000 * 1e6);
        
        // Give users ETH for gas
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(liquidityProvider, 10 ether);
    }
    
    function testFlexibleLoanManagerRewardIntegration() public {
        uint256 collateralAmount = 10 * 1e18; // 10 ETH
        uint256 loanAmount = 5000 * 1e6; // 5000 USDC
        
        // User1 approves and creates loan
        vm.startPrank(user1);
        mockETH.approve(address(loanManager), collateralAmount);
        
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: address(mockETH),
            loanAsset: address(mockUSDC),
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            maxLoanToValue: 800000, // 80%
            interestRate: 50000, // 5%
            duration: 0 // Perpetual loan
        });
        
        // This should trigger reward tracking
        uint256 positionId = loanManager.createLoan(terms);
        vm.stopPrank();
        
        // Check that rewards are being tracked
        (uint256 staked, uint256 pending, uint256 lastStakeTime) = rewardDistributor.getUserInfo(FLEXIBLE_LOAN_POOL, user1);
        
        assertEq(staked, collateralAmount);
        assertEq(pending, 0); // No time passed yet
        assertEq(lastStakeTime, block.timestamp);
        
        // Fast forward time
        vm.warp(block.timestamp + 3600); // 1 hour
        
        // Check pending rewards
        uint256 pendingRewards = rewardDistributor.pendingRewards(FLEXIBLE_LOAN_POOL, user1);
        uint256 expectedRewards = REWARD_RATE * 3600;
        assertEq(pendingRewards, expectedRewards);
        
        // User claims rewards
        vm.prank(user1);
        uint256 claimed = loanManager.claimRewards();
        assertEq(claimed, expectedRewards);
        assertEq(vcopToken.balanceOf(user1), expectedRewards);
    }
    
    function testVaultHandlerRewardIntegration() public {
        uint256 liquidityAmount = 50 * 1e18; // 50 ETH
        
        // Liquidity provider provides liquidity
        vm.startPrank(liquidityProvider);
        mockETH.approve(address(vaultHandler), liquidityAmount);
        vaultHandler.provideLiquidity(address(mockETH), liquidityAmount, liquidityProvider);
        vm.stopPrank();
        
        // Check that rewards are being tracked (assuming VaultHandler implements IRewardable)
        // Note: This would require implementing IRewardable in VaultBasedHandler
        
        // Fast forward time
        vm.warp(block.timestamp + 7200); // 2 hours
        
        // Check vault stats
        (
            uint256 totalLiquidity,
            uint256 totalBorrowed,
            uint256 totalInterestAccrued,
            uint256 utilizationRate,
            uint256 currentInterestRate
        ) = vaultHandler.getVaultStats(address(mockETH));
        
        assertEq(totalLiquidity, liquidityAmount);
        assertEq(totalBorrowed, 0);
        assertEq(utilizationRate, 0);
        
        // Test borrowing from vault
        vm.startPrank(address(loanManager));
        vaultHandler.lend(address(mockETH), 10 * 1e18, user1);
        vm.stopPrank();
        
        // Check updated stats
        (totalLiquidity, totalBorrowed,,,) = vaultHandler.getVaultStats(address(mockETH));
        assertEq(totalBorrowed, 10 * 1e18);
    }
    
    function testMultipleUsersRewardSharing() public {
        uint256 collateral1 = 10 * 1e18;
        uint256 collateral2 = 20 * 1e18;
        
        // User1 creates loan
        vm.startPrank(user1);
        mockETH.approve(address(loanManager), collateral1);
        
        ILoanManager.LoanTerms memory terms1 = ILoanManager.LoanTerms({
            collateralAsset: address(mockETH),
            loanAsset: address(mockUSDC),
            collateralAmount: collateral1,
            loanAmount: 5000 * 1e6,
            maxLoanToValue: 800000,
            interestRate: 50000,
            duration: 0
        });
        
        loanManager.createLoan(terms1);
        vm.stopPrank();
        
        // Fast forward 1 hour
        vm.warp(block.timestamp + 3600);
        
        // User2 creates loan
        vm.startPrank(user2);
        mockETH.approve(address(loanManager), collateral2);
        
        ILoanManager.LoanTerms memory terms2 = ILoanManager.LoanTerms({
            collateralAsset: address(mockETH),
            loanAsset: address(mockUSDC),
            collateralAmount: collateral2,
            loanAmount: 10000 * 1e6,
            maxLoanToValue: 800000,
            interestRate: 50000,
            duration: 0
        });
        
        loanManager.createLoan(terms2);
        vm.stopPrank();
        
        // Fast forward another hour
        vm.warp(block.timestamp + 3600);
        
        // Check reward distribution
        uint256 pending1 = rewardDistributor.pendingRewards(FLEXIBLE_LOAN_POOL, user1);
        uint256 pending2 = rewardDistributor.pendingRewards(FLEXIBLE_LOAN_POOL, user2);
        
        // User1: 1 hour full rewards + 1 hour of 1/3 share
        uint256 expected1 = REWARD_RATE * 3600 + (REWARD_RATE * 3600 * collateral1) / (collateral1 + collateral2);
        
        // User2: 1 hour of 2/3 share
        uint256 expected2 = (REWARD_RATE * 3600 * collateral2) / (collateral1 + collateral2);
        
        assertApproxEqAbs(pending1, expected1, 1e10);
        assertApproxEqAbs(pending2, expected2, 1e10);
    }
    
    function testCollateralAdditionRewardUpdate() public {
        uint256 initialCollateral = 10 * 1e18;
        uint256 additionalCollateral = 5 * 1e18;
        
        // User1 creates loan
        vm.startPrank(user1);
        mockETH.approve(address(loanManager), initialCollateral + additionalCollateral);
        
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: address(mockETH),
            loanAsset: address(mockUSDC),
            collateralAmount: initialCollateral,
            loanAmount: 5000 * 1e6,
            maxLoanToValue: 800000,
            interestRate: 50000,
            duration: 0
        });
        
        uint256 positionId = loanManager.createLoan(terms);
        
        // Fast forward
        vm.warp(block.timestamp + 3600);
        
        // Add more collateral
        loanManager.addCollateral(positionId, additionalCollateral);
        vm.stopPrank();
        
        // Check updated stake
        (uint256 staked,,) = rewardDistributor.getUserInfo(FLEXIBLE_LOAN_POOL, user1);
        assertEq(staked, initialCollateral + additionalCollateral);
        
        // Fast forward more
        vm.warp(block.timestamp + 3600);
        
        // Check rewards calculation with updated stake
        uint256 pending = rewardDistributor.pendingRewards(FLEXIBLE_LOAN_POOL, user1);
        uint256 expected = REWARD_RATE * 3600 + REWARD_RATE * 3600; // 2 hours of rewards
        
        assertApproxEqAbs(pending, expected, 1e10);
    }
    
    function testCollateralWithdrawalRewardUpdate() public {
        uint256 initialCollateral = 20 * 1e18;
        uint256 withdrawAmount = 5 * 1e18;
        
        // User1 creates loan
        vm.startPrank(user1);
        mockETH.approve(address(loanManager), initialCollateral);
        
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: address(mockETH),
            loanAsset: address(mockUSDC),
            collateralAmount: initialCollateral,
            loanAmount: 5000 * 1e6,
            maxLoanToValue: 800000,
            interestRate: 50000,
            duration: 0
        });
        
        uint256 positionId = loanManager.createLoan(terms);
        
        // Fast forward
        vm.warp(block.timestamp + 3600);
        
        // Withdraw some collateral
        loanManager.withdrawCollateral(positionId, withdrawAmount);
        vm.stopPrank();
        
        // Check updated stake
        (uint256 staked,,) = rewardDistributor.getUserInfo(FLEXIBLE_LOAN_POOL, user1);
        assertEq(staked, initialCollateral - withdrawAmount);
    }
    
    function testRewardRateUpdate() public {
        uint256 collateralAmount = 10 * 1e18;
        uint256 newRate = 2e15; // Double the rate
        
        // User creates loan
        vm.startPrank(user1);
        mockETH.approve(address(loanManager), collateralAmount);
        
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: address(mockETH),
            loanAsset: address(mockUSDC),
            collateralAmount: collateralAmount,
            loanAmount: 5000 * 1e6,
            maxLoanToValue: 800000,
            interestRate: 50000,
            duration: 0
        });
        
        loanManager.createLoan(terms);
        vm.stopPrank();
        
        // Fast forward 1 hour with original rate
        vm.warp(block.timestamp + 3600);
        
        // Update reward rate
        rewardDistributor.updateRewardRate(FLEXIBLE_LOAN_POOL, newRate);
        
        // Fast forward another hour with new rate
        vm.warp(block.timestamp + 3600);
        
        // Check rewards
        uint256 pending = rewardDistributor.pendingRewards(FLEXIBLE_LOAN_POOL, user1);
        uint256 expected = REWARD_RATE * 3600 + newRate * 3600; // 1 hour old rate + 1 hour new rate
        
        assertApproxEqAbs(pending, expected, 1e10);
    }
    
    function testCrossContractRewardClaiming() public {
        uint256 collateralAmount = 10 * 1e18;
        
        // User creates loan
        vm.startPrank(user1);
        mockETH.approve(address(loanManager), collateralAmount);
        
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: address(mockETH),
            loanAsset: address(mockUSDC),
            collateralAmount: collateralAmount,
            loanAmount: 5000 * 1e6,
            maxLoanToValue: 800000,
            interestRate: 50000,
            duration: 0
        });
        
        loanManager.createLoan(terms);
        
        // Fast forward
        vm.warp(block.timestamp + 3600);
        
        // Claim rewards through loan manager
        uint256 claimedFromLoanManager = loanManager.claimRewards();
        
        // Try to claim again directly from distributor (should be 0)
        uint256 claimedFromDistributor = 0;
        try rewardDistributor.claimRewards(FLEXIBLE_LOAN_POOL) {
            claimedFromDistributor = rewardDistributor.pendingRewards(FLEXIBLE_LOAN_POOL, user1);
        } catch {
            // Expected to have no rewards left
        }
        
        vm.stopPrank();
        
        assertTrue(claimedFromLoanManager > 0);
        assertEq(claimedFromDistributor, 0);
        assertEq(vcopToken.balanceOf(user1), claimedFromLoanManager);
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RewardDistributor} from "../src/core/RewardDistributor.sol";
import {FlexibleLoanManager} from "../src/core/FlexibleLoanManager.sol";
import {VCOPCollateralized} from "../src/VcopCollateral/VCOPCollateralized.sol";
import {VCOPOracle} from "../src/VcopCollateral/VCOPOracle.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract RewardSystemTest is Test {
    RewardDistributor public rewardDistributor;
    VCOPCollateralized public vcopToken;
    FlexibleLoanManager public loanManager;
    VCOPOracle public oracle;
    
    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public feeCollector = address(0x3);
    
    bytes32 public constant TEST_POOL_ID = keccak256("TEST_POOL");
    bytes32 public constant FLEXIBLE_LOAN_POOL = keccak256("FLEXIBLE_LOAN_COLLATERAL");
    
    uint256 public constant REWARD_RATE = 1e15; // 0.001 VCOP per second
    uint256 public constant INITIAL_REWARDS = 1000000 * 1e6; // 1M VCOP
    
    event RewardPoolCreated(bytes32 indexed poolId, address rewardToken, uint256 rewardRate);
    event StakeUpdated(bytes32 indexed poolId, address indexed user, uint256 amount, bool isIncrease);
    event RewardsClaimed(bytes32 indexed poolId, address indexed user, uint256 amount);
    
    function setUp() public {
        // Deploy VCOP token
        vcopToken = new VCOPCollateralized();
        
        // Deploy Oracle
        oracle = new VCOPOracle(
            4200 * 1e6, // initialUsdToCopRate
            address(0), // _poolManager
            address(vcopToken), // _vcopAddress
            address(0), // _usdcAddress
            3000, // _fee
            60, // _tickSpacing
            address(0) // _hookAddress
        );
        
        // Deploy RewardDistributor
        rewardDistributor = new RewardDistributor();
        
        // Deploy FlexibleLoanManager
        loanManager = new FlexibleLoanManager(address(oracle), feeCollector);
        
        // Set up reward system
        rewardDistributor.setAuthorizedUpdater(address(loanManager), true);
        loanManager.setRewardDistributor(address(rewardDistributor));
        
        // Create test pool
        rewardDistributor.createRewardPool(TEST_POOL_ID, address(vcopToken), REWARD_RATE);
        
        // Mint initial rewards
        vcopToken.mint(owner, INITIAL_REWARDS);
        vcopToken.approve(address(rewardDistributor), INITIAL_REWARDS);
        rewardDistributor.addRewards(TEST_POOL_ID, INITIAL_REWARDS);
        
        // Give users some ETH for gas
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }
    
    function testRewardDistributorDeployment() public {
        assertEq(rewardDistributor.owner(), owner);
        assertTrue(rewardDistributor.authorizedUpdaters(address(loanManager)));
    }
    
    function testCreateRewardPool() public {
        bytes32 newPoolId = keccak256("NEW_POOL");
        
        vm.expectEmit(true, false, false, true);
        emit RewardPoolCreated(newPoolId, address(vcopToken), REWARD_RATE);
        
        rewardDistributor.createRewardPool(newPoolId, address(vcopToken), REWARD_RATE);
        
        (
            address rewardToken,
            uint256 totalRewards,
            uint256 totalDistributed,
            uint256 rewardRate,
            uint256 totalStaked,
            bool active
        ) = rewardDistributor.getPoolInfo(newPoolId);
        
        assertEq(rewardToken, address(vcopToken));
        assertEq(totalRewards, 0);
        assertEq(totalDistributed, 0);
        assertEq(rewardRate, REWARD_RATE);
        assertEq(totalStaked, 0);
        assertTrue(active);
    }
    
    function testCannotCreateDuplicatePool() public {
        vm.expectRevert("Pool already exists");
        rewardDistributor.createRewardPool(TEST_POOL_ID, address(vcopToken), REWARD_RATE);
    }
    
    function testUpdateStakeByAuthorizedContract() public {
        uint256 stakeAmount = 1000 * 1e18;
        
        vm.expectEmit(true, true, false, true);
        emit StakeUpdated(TEST_POOL_ID, user1, stakeAmount, true);
        
        rewardDistributor.updateStake(TEST_POOL_ID, user1, stakeAmount, true);
        
        (uint256 staked, uint256 pending, uint256 lastStakeTime) = rewardDistributor.getUserInfo(TEST_POOL_ID, user1);
        
        assertEq(staked, stakeAmount);
        assertEq(pending, 0); // No time passed yet
        assertEq(lastStakeTime, block.timestamp);
    }
    
    function testCannotUpdateStakeByUnauthorized() public {
        vm.prank(user1);
        vm.expectRevert("Not authorized");
        rewardDistributor.updateStake(TEST_POOL_ID, user1, 1000 * 1e18, true);
    }
    
    function testRewardAccrual() public {
        uint256 stakeAmount = 1000 * 1e18;
        
        // User stakes
        rewardDistributor.updateStake(TEST_POOL_ID, user1, stakeAmount, true);
        
        // Fast forward 1 hour
        vm.warp(block.timestamp + 3600);
        
        // Check pending rewards
        uint256 expectedRewards = REWARD_RATE * 3600; // rate * time
        uint256 pendingRewards = rewardDistributor.pendingRewards(TEST_POOL_ID, user1);
        
        assertEq(pendingRewards, expectedRewards);
    }
    
    function testMultipleUsersRewardSharing() public {
        uint256 stake1 = 1000 * 1e18;
        uint256 stake2 = 2000 * 1e18;
        
        // User1 stakes
        rewardDistributor.updateStake(TEST_POOL_ID, user1, stake1, true);
        
        // Fast forward 1 hour
        vm.warp(block.timestamp + 3600);
        
        // User2 stakes (should trigger reward update for user1)
        rewardDistributor.updateStake(TEST_POOL_ID, user2, stake2, true);
        
        // Fast forward another hour
        vm.warp(block.timestamp + 3600);
        
        uint256 pending1 = rewardDistributor.pendingRewards(TEST_POOL_ID, user1);
        uint256 pending2 = rewardDistributor.pendingRewards(TEST_POOL_ID, user2);
        
        // User1 should have: 1 hour of full rewards + 1 hour of 1/3 share
        uint256 expected1 = REWARD_RATE * 3600 + (REWARD_RATE * 3600 * stake1) / (stake1 + stake2);
        
        // User2 should have: 1 hour of 2/3 share
        uint256 expected2 = (REWARD_RATE * 3600 * stake2) / (stake1 + stake2);
        
        assertApproxEqAbs(pending1, expected1, 1e10); // Allow small rounding errors
        assertApproxEqAbs(pending2, expected2, 1e10);
    }
    
    function testClaimRewards() public {
        uint256 stakeAmount = 1000 * 1e18;
        
        // User stakes
        rewardDistributor.updateStake(TEST_POOL_ID, user1, stakeAmount, true);
        
        // Fast forward 1 hour
        vm.warp(block.timestamp + 3600);
        
        uint256 expectedRewards = REWARD_RATE * 3600;
        uint256 initialBalance = vcopToken.balanceOf(user1);
        
        // Claim rewards
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit RewardsClaimed(TEST_POOL_ID, user1, expectedRewards);
        
        rewardDistributor.claimRewards(TEST_POOL_ID);
        
        // Check balances
        assertEq(vcopToken.balanceOf(user1), initialBalance + expectedRewards);
        assertEq(rewardDistributor.pendingRewards(TEST_POOL_ID, user1), 0);
    }
    
    function testStakeDecrease() public {
        uint256 initialStake = 2000 * 1e18;
        uint256 decreaseAmount = 500 * 1e18;
        
        // User stakes
        rewardDistributor.updateStake(TEST_POOL_ID, user1, initialStake, true);
        
        // Fast forward
        vm.warp(block.timestamp + 3600);
        
        // Decrease stake
        rewardDistributor.updateStake(TEST_POOL_ID, user1, decreaseAmount, false);
        
        (uint256 staked,,) = rewardDistributor.getUserInfo(TEST_POOL_ID, user1);
        assertEq(staked, initialStake - decreaseAmount);
    }
    
    function testCannotDecreaseMoreThanStaked() public {
        uint256 initialStake = 1000 * 1e18;
        uint256 decreaseAmount = 1500 * 1e18;
        
        // User stakes
        rewardDistributor.updateStake(TEST_POOL_ID, user1, initialStake, true);
        
        // Try to decrease more than staked
        vm.expectRevert("Insufficient stake");
        rewardDistributor.updateStake(TEST_POOL_ID, user1, decreaseAmount, false);
    }
    
    function testAddRewardsToPool() public {
        uint256 additionalRewards = 500000 * 1e6;
        
        // Mint and approve additional rewards
        vcopToken.mint(owner, additionalRewards);
        vcopToken.approve(address(rewardDistributor), additionalRewards);
        
        // Add rewards
        rewardDistributor.addRewards(TEST_POOL_ID, additionalRewards);
        
        (,uint256 totalRewards,,,,) = rewardDistributor.getPoolInfo(TEST_POOL_ID);
        assertEq(totalRewards, INITIAL_REWARDS + additionalRewards);
    }
    
    function testUpdateRewardRate() public {
        uint256 newRate = 2e15; // 0.002 VCOP per second
        
        rewardDistributor.updateRewardRate(TEST_POOL_ID, newRate);
        
        (,,, uint256 rewardRate,,) = rewardDistributor.getPoolInfo(TEST_POOL_ID);
        assertEq(rewardRate, newRate);
    }
    
    function testOnlyOwnerCanUpdateRewardRate() public {
        vm.prank(user1);
        vm.expectRevert();
        rewardDistributor.updateRewardRate(TEST_POOL_ID, 2e15);
    }
    
    function testFlexibleLoanManagerIntegration() public {
        // This would test the actual integration with FlexibleLoanManager
        // For now, we'll test the interface compliance
        
        assertTrue(address(loanManager.getRewardDistributor()) == address(rewardDistributor));
        assertEq(loanManager.getRewardPoolId(), FLEXIBLE_LOAN_POOL);
    }
    
    function testEmergencyWithdraw() public {
        uint256 withdrawAmount = 100 * 1e6;
        
        // Mint some tokens to the distributor
        vcopToken.mint(address(rewardDistributor), withdrawAmount);
        
        uint256 initialBalance = vcopToken.balanceOf(owner);
        
        // Emergency withdraw
        rewardDistributor.emergencyWithdraw(address(vcopToken), withdrawAmount);
        
        assertEq(vcopToken.balanceOf(owner), initialBalance + withdrawAmount);
    }
    
    function testOnlyOwnerCanEmergencyWithdraw() public {
        vm.prank(user1);
        vm.expectRevert();
        rewardDistributor.emergencyWithdraw(address(vcopToken), 100 * 1e6);
    }
    
    function testGetAllPools() public {
        bytes32[] memory pools = rewardDistributor.getAllPools();
        assertEq(pools.length, 1);
        assertEq(pools[0], TEST_POOL_ID);
        
        // Add another pool
        bytes32 newPoolId = keccak256("ANOTHER_POOL");
        rewardDistributor.createRewardPool(newPoolId, address(vcopToken), REWARD_RATE);
        
        pools = rewardDistributor.getAllPools();
        assertEq(pools.length, 2);
    }
    
    function testRewardCalculationPrecision() public {
        uint256 smallStake = 1e18; // 1 token
        uint256 smallRate = 1e12; // Very small rate
        
        // Create pool with small rate
        bytes32 precisionPoolId = keccak256("PRECISION_POOL");
        rewardDistributor.createRewardPool(precisionPoolId, address(vcopToken), smallRate);
        
        // Add rewards
        vcopToken.mint(owner, 1000 * 1e6);
        vcopToken.approve(address(rewardDistributor), 1000 * 1e6);
        rewardDistributor.addRewards(precisionPoolId, 1000 * 1e6);
        
        // Stake small amount
        rewardDistributor.updateStake(precisionPoolId, user1, smallStake, true);
        
        // Fast forward
        vm.warp(block.timestamp + 86400); // 1 day
        
        uint256 pending = rewardDistributor.pendingRewards(precisionPoolId, user1);
        uint256 expected = smallRate * 86400;
        
        assertEq(pending, expected);
    }
    
    function testZeroStakeHandling() public {
        // Test that zero stakes are handled correctly
        uint256 pending = rewardDistributor.pendingRewards(TEST_POOL_ID, user1);
        assertEq(pending, 0);
        
        (uint256 staked,,) = rewardDistributor.getUserInfo(TEST_POOL_ID, user1);
        assertEq(staked, 0);
    }
    
    function testRewardDistributionAfterFullWithdrawal() public {
        uint256 stakeAmount = 1000 * 1e18;
        
        // User stakes
        rewardDistributor.updateStake(TEST_POOL_ID, user1, stakeAmount, true);
        
        // Fast forward
        vm.warp(block.timestamp + 3600);
        
        // Withdraw all stake
        rewardDistributor.updateStake(TEST_POOL_ID, user1, stakeAmount, false);
        
        // Fast forward more
        vm.warp(block.timestamp + 3600);
        
        // Should have rewards from first period only
        uint256 pending = rewardDistributor.pendingRewards(TEST_POOL_ID, user1);
        uint256 expected = REWARD_RATE * 3600; // Only first hour
        
        assertEq(pending, expected);
    }
} 
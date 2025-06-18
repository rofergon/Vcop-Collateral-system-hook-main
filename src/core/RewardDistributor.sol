// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";

// Import VCOP interface for minting
interface IVCOPMintable {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function setMinter(address account, bool status) external;
}

/**
 * @title RewardDistributor
 * @notice Central contract for managing and distributing rewards across all protocol components
 * @dev Now supports VCOP minting for rewards instead of requiring pre-funded tokens
 */
contract RewardDistributor is Ownable {
    using SafeERC20 for IERC20;
    
    // Reward pool information
    struct RewardPool {
        address rewardToken;           // Token used for rewards (VCOP, ETH, etc.)
        uint256 totalRewards;          // Total rewards accumulated
        uint256 totalDistributed;      // Total rewards already distributed
        uint256 rewardRate;            // Rewards per second (18 decimals)
        uint256 lastUpdateTime;        // Last time rewards were calculated
        uint256 rewardPerTokenStored;  // Accumulated reward per token
        bool active;                   // Whether pool is active
        bool usesMinting;              // Whether this pool mints tokens instead of transferring
    }
    
    // User reward information per pool
    struct UserReward {
        uint256 userRewardPerTokenPaid; // Last calculated reward per token for user
        uint256 rewards;                // Pending rewards for user
        uint256 totalStaked;            // Total tokens staked by user
        uint256 lastStakeTime;          // Last time user staked
    }
    
    // Pool configurations
    mapping(bytes32 => RewardPool) public rewardPools;
    bytes32[] public poolIds;
    
    // User rewards: poolId => user => UserReward
    mapping(bytes32 => mapping(address => UserReward)) public userRewards;
    
    // Total staked per pool
    mapping(bytes32 => uint256) public totalStaked;
    
    // Authorized contracts that can update stakes
    mapping(address => bool) public authorizedUpdaters;
    
    // Protocol components
    address public vaultHandler;
    address public flexibleLoanManager;
    address public genericLoanManager;
    address public collateralManager;
    
    // VCOP token address for minting
    address public vcopToken;
    
    // Events
    event RewardPoolCreated(bytes32 indexed poolId, address rewardToken, uint256 rewardRate, bool usesMinting);
    event RewardPoolUpdated(bytes32 indexed poolId, uint256 newRewardRate);
    event StakeUpdated(bytes32 indexed poolId, address indexed user, uint256 amount, bool isIncrease);
    event RewardsClaimed(bytes32 indexed poolId, address indexed user, uint256 amount);
    event RewardsDistributed(bytes32 indexed poolId, uint256 amount);
    event VCOPTokenSet(address vcopToken);
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Sets the VCOP token address for minting
     */
    function setVCOPToken(address _vcopToken) external onlyOwner {
        require(_vcopToken != address(0), "Invalid VCOP token address");
        vcopToken = _vcopToken;
        emit VCOPTokenSet(_vcopToken);
    }
    
    /**
     * @dev Sets authorized updater contracts
     */
    function setAuthorizedUpdater(address updater, bool authorized) external onlyOwner {
        authorizedUpdaters[updater] = authorized;
    }
    
    /**
     * @dev Sets protocol component addresses
     */
    function setProtocolComponents(
        address _vaultHandler,
        address _flexibleLoanManager,
        address _genericLoanManager,
        address _collateralManager
    ) external onlyOwner {
        vaultHandler = _vaultHandler;
        flexibleLoanManager = _flexibleLoanManager;
        genericLoanManager = _genericLoanManager;
        collateralManager = _collateralManager;
    }
    
    /**
     * @dev Creates a new reward pool
     */
    function createRewardPool(
        bytes32 poolId,
        address rewardToken,
        uint256 rewardRate
    ) external onlyOwner {
        require(rewardPools[poolId].rewardToken == address(0), "Pool already exists");
        require(rewardToken != address(0), "Invalid reward token");
        
        // Check if this is VCOP token (will use minting)
        bool usesMinting = (rewardToken == vcopToken);
        
        rewardPools[poolId] = RewardPool({
            rewardToken: rewardToken,
            totalRewards: 0,
            totalDistributed: 0,
            rewardRate: rewardRate,
            lastUpdateTime: block.timestamp,
            rewardPerTokenStored: 0,
            active: true,
            usesMinting: usesMinting
        });
        
        poolIds.push(poolId);
        
        emit RewardPoolCreated(poolId, rewardToken, rewardRate, usesMinting);
    }
    
    /**
     * @dev Updates reward rate for a pool
     */
    function updateRewardRate(bytes32 poolId, uint256 newRate) external onlyOwner {
        _updateReward(poolId, address(0));
        rewardPools[poolId].rewardRate = newRate;
        emit RewardPoolUpdated(poolId, newRate);
    }
    
    /**
     * @dev Updates user stake (called by authorized contracts)
     */
    function updateStake(
        bytes32 poolId,
        address user,
        uint256 amount,
        bool isIncrease
    ) external {
        require(authorizedUpdaters[msg.sender], "Not authorized");
        
        _updateReward(poolId, user);
        
        UserReward storage userReward = userRewards[poolId][user];
        
        if (isIncrease) {
            userReward.totalStaked += amount;
            totalStaked[poolId] += amount;
        } else {
            require(userReward.totalStaked >= amount, "Insufficient stake");
            userReward.totalStaked -= amount;
            totalStaked[poolId] -= amount;
        }
        
        userReward.lastStakeTime = block.timestamp;
        
        emit StakeUpdated(poolId, user, amount, isIncrease);
    }
    
    /**
     * @dev Claims rewards for a user
     */
    function claimRewards(bytes32 poolId) external {
        _updateReward(poolId, msg.sender);
        
        UserReward storage userReward = userRewards[poolId][msg.sender];
        uint256 reward = userReward.rewards;
        
        if (reward > 0) {
            userReward.rewards = 0;
            RewardPool storage pool = rewardPools[poolId];
            pool.totalDistributed += reward;
            
            // Check if this pool uses minting or transferring
            if (pool.usesMinting && pool.rewardToken == vcopToken) {
                // Mint VCOP tokens directly to user
                require(vcopToken != address(0), "VCOP token not set");
                IVCOPMintable(pool.rewardToken).mint(msg.sender, reward);
            } else {
                // Traditional transfer from contract balance
                IERC20(pool.rewardToken).safeTransfer(msg.sender, reward);
            }
            
            emit RewardsClaimed(poolId, msg.sender, reward);
        }
    }
    
    /**
     * @dev Gets pending rewards for a user
     */
    function pendingRewards(bytes32 poolId, address user) external view returns (uint256) {
        UserReward memory userReward = userRewards[poolId][user];
        
        uint256 rewardPerToken = _rewardPerToken(poolId);
        return userReward.totalStaked * (rewardPerToken - userReward.userRewardPerTokenPaid) / 1e18 + userReward.rewards;
    }
    
    /**
     * @dev Gets user staking info
     */
    function getUserInfo(bytes32 poolId, address user) external view returns (
        uint256 staked,
        uint256 pending,
        uint256 lastStakeTime
    ) {
        UserReward memory userReward = userRewards[poolId][user];
        return (
            userReward.totalStaked,
            this.pendingRewards(poolId, user),
            userReward.lastStakeTime
        );
    }
    
    /**
     * @dev Gets pool information
     */
    function getPoolInfo(bytes32 poolId) external view returns (
        address rewardToken,
        uint256 totalRewards,
        uint256 totalDistributed,
        uint256 rewardRate,
        uint256 totalStaked_,
        bool active
    ) {
        RewardPool memory pool = rewardPools[poolId];
        return (
            pool.rewardToken,
            pool.totalRewards,
            pool.totalDistributed,
            pool.rewardRate,
            totalStaked[poolId],
            pool.active
        );
    }
    
    /**
     * @dev Adds rewards to a pool (only for non-minting pools)
     */
    function addRewards(bytes32 poolId, uint256 amount) external {
        RewardPool storage pool = rewardPools[poolId];
        require(pool.active, "Pool not active");
        
        if (pool.usesMinting) {
            // For minting pools, just track the virtual rewards
            pool.totalRewards += amount;
        } else {
            // For non-minting pools, require actual token transfer
            IERC20(pool.rewardToken).safeTransferFrom(msg.sender, address(this), amount);
            pool.totalRewards += amount;
        }
        
        emit RewardsDistributed(poolId, amount);
    }
    
    /**
     * @dev Internal function to update rewards
     */
    function _updateReward(bytes32 poolId, address user) internal {
        RewardPool storage pool = rewardPools[poolId];
        pool.rewardPerTokenStored = _rewardPerToken(poolId);
        pool.lastUpdateTime = block.timestamp;
        
        if (user != address(0)) {
            UserReward storage userReward = userRewards[poolId][user];
            userReward.rewards = this.pendingRewards(poolId, user);
            userReward.userRewardPerTokenPaid = pool.rewardPerTokenStored;
        }
    }
    
    /**
     * @dev Calculates reward per token
     */
    function _rewardPerToken(bytes32 poolId) internal view returns (uint256) {
        RewardPool memory pool = rewardPools[poolId];
        
        if (totalStaked[poolId] == 0) {
            return pool.rewardPerTokenStored;
        }
        
        return pool.rewardPerTokenStored + 
            (block.timestamp - pool.lastUpdateTime) * pool.rewardRate * 1e18 / totalStaked[poolId];
    }
    
    /**
     * @dev Emergency withdrawal (only owner)
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
    
    /**
     * @dev Gets all pool IDs
     */
    function getAllPools() external view returns (bytes32[] memory) {
        return poolIds;
    }
} 
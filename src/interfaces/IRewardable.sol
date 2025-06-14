// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IRewardable
 * @notice Interface for contracts that can distribute rewards to users
 */
interface IRewardable {
    
    /**
     * @dev Emitted when rewards are updated for a user
     */
    event RewardsUpdated(address indexed user, uint256 amount, bytes32 poolId);
    
    /**
     * @dev Emitted when a user claims rewards
     */
    event RewardsClaimed(address indexed user, uint256 amount, bytes32 poolId);
    
    /**
     * @dev Updates rewards for a user based on their activity
     * @param user Address of the user
     * @param amount Amount of activity (deposit, loan, etc.)
     * @param isIncrease Whether this is an increase or decrease in activity
     */
    function updateUserRewards(address user, uint256 amount, bool isIncrease) external;
    
    /**
     * @dev Gets pending rewards for a user
     * @param user Address of the user
     * @return amount Pending reward amount
     */
    function getPendingRewards(address user) external view returns (uint256 amount);
    
    /**
     * @dev Claims rewards for the caller
     * @return amount Amount of rewards claimed
     */
    function claimRewards() external returns (uint256 amount);
    
    /**
     * @dev Gets the reward pool ID for this contract
     * @return poolId The pool identifier
     */
    function getRewardPoolId() external view returns (bytes32 poolId);
    
    /**
     * @dev Gets reward distributor address
     * @return distributor Address of the reward distributor
     */
    function getRewardDistributor() external view returns (address distributor);
    
    /**
     * @dev Sets the reward distributor (only owner)
     * @param distributor Address of the new reward distributor
     */
    function setRewardDistributor(address distributor) external;
} 
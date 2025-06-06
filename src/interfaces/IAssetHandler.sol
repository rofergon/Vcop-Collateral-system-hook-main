// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IAssetHandler
 * @notice Interface for handling different types of assets (mintable/burnable vs vault-based)
 */
interface IAssetHandler {
    enum AssetType {
        MINTABLE_BURNABLE,  // Assets the protocol can mint/burn (like VCOP)
        VAULT_BASED,        // External assets stored in vaults (like ETH, WBTC)
        REBASING            // Assets with rebasing mechanisms
    }
    
    struct AssetConfig {
        address token;
        AssetType assetType;
        uint256 decimals;
        uint256 collateralRatio;     // 150% = 1500000 (6 decimals)
        uint256 liquidationRatio;    // 120% = 1200000 (6 decimals)
        uint256 maxLoanAmount;       // Maximum amount that can be borrowed
        uint256 interestRate;        // Annual interest rate (6 decimals)
        bool isActive;
    }
    
    /**
     * @dev Provides liquidity for lending (vault-based assets only)
     * @param token Address of the token
     * @param amount Amount to provide
     * @param provider Address of the liquidity provider
     */
    function provideLiquidity(address token, uint256 amount, address provider) external;
    
    /**
     * @dev Withdraws provided liquidity (vault-based assets only)
     * @param token Address of the token
     * @param amount Amount to withdraw
     * @param provider Address of the liquidity provider
     */
    function withdrawLiquidity(address token, uint256 amount, address provider) external;
    
    /**
     * @dev Lends tokens to a borrower
     * @param token Address of the token
     * @param amount Amount to lend
     * @param borrower Address of the borrower
     */
    function lend(address token, uint256 amount, address borrower) external;
    
    /**
     * @dev Repays borrowed tokens
     * @param token Address of the token
     * @param amount Amount to repay
     * @param borrower Address of the borrower
     */
    function repay(address token, uint256 amount, address borrower) external;
    
    /**
     * @dev Gets available liquidity for lending
     * @param token Address of the token
     * @return Available amount for lending
     */
    function getAvailableLiquidity(address token) external view returns (uint256);
    
    /**
     * @dev Gets total borrowed amount
     * @param token Address of the token
     * @return Total borrowed amount
     */
    function getTotalBorrowed(address token) external view returns (uint256);
    
    /**
     * @dev Gets asset configuration
     * @param token Address of the token
     * @return Asset configuration
     */
    function getAssetConfig(address token) external view returns (AssetConfig memory);
    
    /**
     * @dev Checks if asset is supported
     * @param token Address of the token
     * @return True if supported
     */
    function isAssetSupported(address token) external view returns (bool);
    
    /**
     * @dev Gets asset type
     * @param token Address of the token
     * @return Asset type
     */
    function getAssetType(address token) external view returns (AssetType);
    
    // Events
    event AssetConfigured(address indexed token, AssetType assetType, uint256 collateralRatio);
    event LiquidityProvided(address indexed token, address indexed provider, uint256 amount);
    event LiquidityWithdrawn(address indexed token, address indexed provider, uint256 amount);
    event TokensLent(address indexed token, address indexed borrower, uint256 amount);
    event TokensRepaid(address indexed token, address indexed borrower, uint256 amount);
} 
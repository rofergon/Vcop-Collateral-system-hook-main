// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IAssetHandler} from "../interfaces/IAssetHandler.sol";

// Interface for mintable/burnable tokens
interface IMintableBurnable {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function decimals() external view returns (uint8);
}

/**
 * @title MintableBurnableHandler
 * @notice Handles assets that the protocol can mint and burn (like VCOP)
 */
contract MintableBurnableHandler is IAssetHandler, Ownable {
    using SafeERC20 for IERC20;
    
    // Asset configurations
    mapping(address => AssetConfig) public assetConfigs;
    address[] public supportedAssets;
    
    // Protocol statistics
    mapping(address => uint256) public totalMinted;
    mapping(address => uint256) public totalBurned;
    mapping(address => uint256) public totalBorrowed;
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Configures a mintable/burnable asset
     */
    function configureAsset(
        address token,
        uint256 collateralRatio,
        uint256 liquidationRatio,
        uint256 maxLoanAmount,
        uint256 interestRate
    ) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(collateralRatio >= 1000000, "Ratio must be at least 100%");
        require(liquidationRatio < collateralRatio, "Liquidation ratio must be below collateral ratio");
        
        IMintableBurnable mintableToken = IMintableBurnable(token);
        uint256 decimals = mintableToken.decimals();
        
        // Add to supported assets if new
        if (assetConfigs[token].token == address(0)) {
            supportedAssets.push(token);
        }
        
        assetConfigs[token] = AssetConfig({
            token: token,
            assetType: AssetType.MINTABLE_BURNABLE,
            decimals: decimals,
            collateralRatio: collateralRatio,
            liquidationRatio: liquidationRatio,
            maxLoanAmount: maxLoanAmount,
            interestRate: interestRate,
            isActive: true
        });
        
        emit AssetConfigured(token, AssetType.MINTABLE_BURNABLE, collateralRatio);
    }
    
    /**
     * @dev Not applicable for mintable/burnable assets
     */
    function provideLiquidity(address, uint256, address) external pure override {
        revert("Not applicable for mintable/burnable assets");
    }
    
    /**
     * @dev Not applicable for mintable/burnable assets
     */
    function withdrawLiquidity(address, uint256, address) external pure override {
        revert("Not applicable for mintable/burnable assets");
    }
    
    /**
     * @dev Lends tokens by minting them to the borrower
     */
    function lend(address token, uint256 amount, address borrower) external override {
        AssetConfig memory config = assetConfigs[token];
        require(config.isActive, "Asset not active");
        require(config.assetType == AssetType.MINTABLE_BURNABLE, "Invalid asset type");
        
        // Check lending limits
        require(
            totalBorrowed[token] + amount <= config.maxLoanAmount,
            "Exceeds maximum loan amount"
        );
        
        // Mint tokens to borrower
        IMintableBurnable(token).mint(borrower, amount);
        
        // Update statistics
        totalMinted[token] += amount;
        totalBorrowed[token] += amount;
        
        emit TokensLent(token, borrower, amount);
    }
    
    /**
     * @dev Repays tokens by burning them from the borrower
     */
    function repay(address token, uint256 amount, address borrower) external override {
        AssetConfig memory config = assetConfigs[token];
        require(config.isActive, "Asset not active");
        require(config.assetType == AssetType.MINTABLE_BURNABLE, "Invalid asset type");
        
        // Burn tokens from borrower
        IMintableBurnable(token).burn(borrower, amount);
        
        // Update statistics
        totalBurned[token] += amount;
        totalBorrowed[token] = totalBorrowed[token] > amount ? totalBorrowed[token] - amount : 0;
        
        emit TokensRepaid(token, borrower, amount);
    }
    
    /**
     * @dev For mintable assets, liquidity is unlimited (we can mint)
     */
    function getAvailableLiquidity(address token) external view override returns (uint256) {
        AssetConfig memory config = assetConfigs[token];
        if (!config.isActive || config.assetType != AssetType.MINTABLE_BURNABLE) {
            return 0;
        }
        
        // Return remaining mintable amount based on maxLoanAmount
        return config.maxLoanAmount > totalBorrowed[token] 
            ? config.maxLoanAmount - totalBorrowed[token]
            : 0;
    }
    
    /**
     * @dev Gets total borrowed amount
     */
    function getTotalBorrowed(address token) external view override returns (uint256) {
        return totalBorrowed[token];
    }
    
    /**
     * @dev Gets asset configuration
     */
    function getAssetConfig(address token) external view override returns (AssetConfig memory) {
        return assetConfigs[token];
    }
    
    /**
     * @dev Checks if asset is supported
     */
    function isAssetSupported(address token) external view override returns (bool) {
        return assetConfigs[token].isActive;
    }
    
    /**
     * @dev Gets asset type
     */
    function getAssetType(address token) external view override returns (AssetType) {
        return assetConfigs[token].assetType;
    }
    
    /**
     * @dev Sets asset active status
     */
    function setAssetStatus(address token, bool isActive) external onlyOwner {
        require(assetConfigs[token].token != address(0), "Asset not configured");
        assetConfigs[token].isActive = isActive;
    }
    
    /**
     * @dev Gets list of all supported assets
     */
    function getSupportedAssets() external view returns (address[] memory) {
        return supportedAssets;
    }
    
    /**
     * @dev Gets protocol statistics for an asset
     */
    function getAssetStats(address token) external view returns (
        uint256 minted,
        uint256 burned,
        uint256 borrowed,
        uint256 netSupply
    ) {
        minted = totalMinted[token];
        burned = totalBurned[token];
        borrowed = totalBorrowed[token];
        netSupply = minted > burned ? minted - burned : 0;
    }
} 
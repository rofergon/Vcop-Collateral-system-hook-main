// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IAssetHandler} from "../interfaces/IAssetHandler.sol";
import {IRewardable} from "../interfaces/IRewardable.sol";
import {IEmergencyRegistry} from "../interfaces/IEmergencyRegistry.sol";
import {RewardDistributor} from "./RewardDistributor.sol";

/**
 * @title VaultBasedHandler
 * @notice Handles external assets that require vault-based lending (like ETH, WBTC)
 */
contract VaultBasedHandler is IAssetHandler, IRewardable, Ownable {
    using SafeERC20 for IERC20;
    
    // Liquidity provider information
    struct LiquidityProvider {
        uint256 totalProvided;
        uint256 totalWithdrawn;
        uint256 earnedInterest;
        uint256 lastUpdateTimestamp;
    }
    
    // Vault information for each asset
    struct VaultInfo {
        uint256 totalLiquidity;      // Total liquidity provided
        uint256 totalBorrowed;       // Total amount currently borrowed
        uint256 totalInterestAccrued; // Total interest accrued
        uint256 utilizationRate;     // Current utilization rate (borrowed/liquidity)
        uint256 lastUpdateTimestamp;
    }
    
    // Asset configurations
    mapping(address => AssetConfig) public assetConfigs;
    address[] public supportedAssets;
    
    // Vault data
    mapping(address => VaultInfo) public vaultInfo;
    
    // Liquidity providers: token => provider => LiquidityProvider
    mapping(address => mapping(address => LiquidityProvider)) public liquidityProviders;
    mapping(address => address[]) public assetProviders; // Track providers per asset
    
    // Interest calculation parameters
    uint256 public constant SECONDS_PER_YEAR = 365 * 24 * 3600;
    uint256 public baseInterestRate = 50000; // 5% base rate (6 decimals: 5% = 50000)
    uint256 public utilizationMultiplier = 200000; // 20% multiplier
    
    // Reward system
    RewardDistributor public rewardDistributor;
    bytes32 public constant VAULT_ETH_POOL_ID = keccak256("VAULT_ETH_LIQUIDITY");
    bytes32 public constant VAULT_WBTC_POOL_ID = keccak256("VAULT_WBTC_LIQUIDITY");
    bytes32 public constant VAULT_USDC_POOL_ID = keccak256("VAULT_USDC_LIQUIDITY");
    
    // ⚡ NEW: Emergency registry for centralized coordination
    IEmergencyRegistry public emergencyRegistry;
    
    // Events
    event InterestAccrued(address indexed token, uint256 amount);
    event UtilizationRateUpdated(address indexed token, uint256 newRate);
    event LiquidationRatioUpdated(address indexed token, uint256 oldRatio, uint256 newRatio);
    event CollateralRatioUpdated(address indexed token, uint256 oldRatio, uint256 newRatio);
    event BothRatiosUpdated(address indexed token, uint256 oldCollateralRatio, uint256 newCollateralRatio, uint256 oldLiquidationRatio, uint256 newLiquidationRatio);
    event EmergencyLiquidationEnabled(address indexed token);
    event EmergencyLiquidationDisabled(address indexed token);
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Configures a vault-based asset
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
        require(liquidationRatio > 0, "Liquidation ratio must be positive");
        require(liquidationRatio < collateralRatio, "Liquidation ratio must be below collateral ratio");
        
        // Add to supported assets if new
        if (assetConfigs[token].token == address(0)) {
            supportedAssets.push(token);
        }
        
        assetConfigs[token] = AssetConfig({
            token: token,
            assetType: AssetType.VAULT_BASED,
            decimals: 18, // Most tokens use 18, can be overridden
            collateralRatio: collateralRatio,
            liquidationRatio: liquidationRatio,
            maxLoanAmount: maxLoanAmount,
            interestRate: interestRate,
            isActive: true
        });
        
        emit AssetConfigured(token, AssetType.VAULT_BASED, collateralRatio);
    }
    
    /**
     * @dev Provides liquidity to the vault
     */
    function provideLiquidity(address token, uint256 amount, address provider) external override {
        AssetConfig memory config = assetConfigs[token];
        require(config.isActive, "Asset not active");
        require(config.assetType == AssetType.VAULT_BASED, "Invalid asset type");
        require(amount > 0, "Amount must be greater than zero");
        
        // Transfer tokens to vault
        IERC20(token).safeTransferFrom(provider, address(this), amount);
        
        // Update provider information
        LiquidityProvider storage providerInfo = liquidityProviders[token][provider];
        if (providerInfo.totalProvided == 0) {
            assetProviders[token].push(provider);
        }
        
        // Accrue interest before updating
        _accrueInterest(token);
        
        providerInfo.totalProvided += amount;
        providerInfo.lastUpdateTimestamp = block.timestamp;
        
        // Update vault information
        VaultInfo storage vault = vaultInfo[token];
        vault.totalLiquidity += amount;
        vault.lastUpdateTimestamp = block.timestamp;
        
        // Update reward system
        _updateUserRewards(provider, token, amount, true);
        
        // Update utilization rate
        _updateUtilizationRate(token);
        
        emit LiquidityProvided(token, provider, amount);
    }
    
    /**
     * @dev Withdraws provided liquidity
     */
    function withdrawLiquidity(address token, uint256 amount, address provider) external override {
        AssetConfig memory config = assetConfigs[token];
        require(config.isActive, "Asset not active");
        require(config.assetType == AssetType.VAULT_BASED, "Invalid asset type");
        
        LiquidityProvider storage providerInfo = liquidityProviders[token][provider];
        require(providerInfo.totalProvided >= amount, "Insufficient provided liquidity");
        
        VaultInfo storage vault = vaultInfo[token];
        uint256 availableLiquidity = vault.totalLiquidity - vault.totalBorrowed;
        require(availableLiquidity >= amount, "Insufficient available liquidity");
        
        // Accrue interest before updating
        _accrueInterest(token);
        
        // Calculate and distribute earned interest
        uint256 interest = _calculateProviderInterest(token, provider);
        if (interest > 0) {
            providerInfo.earnedInterest += interest;
        }
        
        // Update provider information
        providerInfo.totalProvided -= amount;
        providerInfo.totalWithdrawn += amount;
        providerInfo.lastUpdateTimestamp = block.timestamp;
        
        // Update vault information
        vault.totalLiquidity -= amount;
        vault.lastUpdateTimestamp = block.timestamp;
        
        // Update reward system
        _updateUserRewards(provider, token, amount, false);
        
        // Transfer tokens back to provider
        IERC20(token).safeTransfer(provider, amount);
        
        // Update utilization rate
        _updateUtilizationRate(token);
        
        emit LiquidityWithdrawn(token, provider, amount);
    }
    
    /**
     * @dev Lends tokens from the vault
     */
    function lend(address token, uint256 amount, address borrower) external override {
        AssetConfig memory config = assetConfigs[token];
        require(config.isActive, "Asset not active");
        require(config.assetType == AssetType.VAULT_BASED, "Invalid asset type");
        
        VaultInfo storage vault = vaultInfo[token];
        uint256 availableLiquidity = vault.totalLiquidity - vault.totalBorrowed;
        require(availableLiquidity >= amount, "Insufficient vault liquidity");
        
        // Check lending limits
        require(
            vault.totalBorrowed + amount <= config.maxLoanAmount,
            "Exceeds maximum loan amount"
        );
        
        // Accrue interest before updating
        _accrueInterest(token);
        
        // Update vault statistics
        vault.totalBorrowed += amount;
        vault.lastUpdateTimestamp = block.timestamp;
        
        // Transfer tokens to borrower
        IERC20(token).safeTransfer(borrower, amount);
        
        // Update utilization rate
        _updateUtilizationRate(token);
        
        emit TokensLent(token, borrower, amount);
    }
    
    /**
     * @dev Repays borrowed tokens to the vault
     */
    function repay(address token, uint256 amount, address borrower) external override {
        AssetConfig memory config = assetConfigs[token];
        require(config.isActive, "Asset not active");
        require(config.assetType == AssetType.VAULT_BASED, "Invalid asset type");
        
        // Transfer tokens from borrower to vault
        IERC20(token).safeTransferFrom(borrower, address(this), amount);
        
        // Accrue interest before updating
        _accrueInterest(token);
        
        // Update vault statistics
        VaultInfo storage vault = vaultInfo[token];
        vault.totalBorrowed = vault.totalBorrowed > amount ? vault.totalBorrowed - amount : 0;
        vault.lastUpdateTimestamp = block.timestamp;
        
        // Update utilization rate
        _updateUtilizationRate(token);
        
        emit TokensRepaid(token, borrower, amount);
    }
    
    /**
     * @dev Gets available liquidity for lending
     */
    function getAvailableLiquidity(address token) external view override returns (uint256) {
        VaultInfo memory vault = vaultInfo[token];
        return vault.totalLiquidity > vault.totalBorrowed 
            ? vault.totalLiquidity - vault.totalBorrowed 
            : 0;
    }
    
    /**
     * @dev Gets total borrowed amount
     */
    function getTotalBorrowed(address token) external view override returns (uint256) {
        return vaultInfo[token].totalBorrowed;
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
     * @dev Accrues interest for all liquidity providers
     */
    function _accrueInterest(address token) internal {
        VaultInfo storage vault = vaultInfo[token];
        
        if (vault.totalBorrowed == 0 || vault.lastUpdateTimestamp == block.timestamp) {
            return;
        }
        
        uint256 timeElapsed = block.timestamp - vault.lastUpdateTimestamp;
        uint256 currentRate = _getCurrentInterestRate(token);
        
        // Calculate interest: principal * rate * time / seconds_per_year
        uint256 interest = (vault.totalBorrowed * currentRate * timeElapsed) / (SECONDS_PER_YEAR * 1000000);
        
        if (interest > 0) {
            vault.totalInterestAccrued += interest;
            emit InterestAccrued(token, interest);
        }
    }
    
    /**
     * @dev Calculates interest earned by a specific provider
     */
    function _calculateProviderInterest(address token, address provider) internal view returns (uint256) {
        VaultInfo memory vault = vaultInfo[token];
        LiquidityProvider memory providerInfo = liquidityProviders[token][provider];
        
        if (vault.totalLiquidity == 0 || providerInfo.totalProvided == 0) {
            return 0;
        }
        
        // Provider's share of total interest = (provider_liquidity / total_liquidity) * total_interest
        uint256 providerShare = (providerInfo.totalProvided * vault.totalInterestAccrued) / vault.totalLiquidity;
        return providerShare > providerInfo.earnedInterest ? providerShare - providerInfo.earnedInterest : 0;
    }
    
    /**
     * @dev Updates utilization rate for an asset
     */
    function _updateUtilizationRate(address token) internal {
        VaultInfo storage vault = vaultInfo[token];
        
        if (vault.totalLiquidity == 0) {
            vault.utilizationRate = 0;
        } else {
            vault.utilizationRate = (vault.totalBorrowed * 1000000) / vault.totalLiquidity;
        }
        
        emit UtilizationRateUpdated(token, vault.utilizationRate);
    }
    
    /**
     * @dev Calculates current interest rate based on utilization
     */
    function _getCurrentInterestRate(address token) internal view returns (uint256) {
        VaultInfo memory vault = vaultInfo[token];
        
        // Interest rate = base_rate + (utilization_rate * multiplier)
        uint256 variableRate = (vault.utilizationRate * utilizationMultiplier) / 1000000;
        return baseInterestRate + variableRate;
    }
    
    /**
     * @dev Gets vault statistics
     */
    function getVaultStats(address token) external view returns (
        uint256 totalLiquidity,
        uint256 totalBorrowed,
        uint256 totalInterestAccrued,
        uint256 utilizationRate,
        uint256 currentInterestRate
    ) {
        VaultInfo memory vault = vaultInfo[token];
        return (
            vault.totalLiquidity,
            vault.totalBorrowed,
            vault.totalInterestAccrued,
            vault.utilizationRate,
            _getCurrentInterestRate(token)
        );
    }
    
    /**
     * @dev Gets provider information
     */
    function getProviderInfo(address token, address provider) external view returns (
        uint256 totalProvided,
        uint256 totalWithdrawn,
        uint256 earnedInterest,
        uint256 pendingInterest
    ) {
        LiquidityProvider memory providerInfo = liquidityProviders[token][provider];
        uint256 pending = _calculateProviderInterest(token, provider);
        
        return (
            providerInfo.totalProvided,
            providerInfo.totalWithdrawn,
            providerInfo.earnedInterest,
            pending
        );
    }
    
    /**
     * @dev Sets interest rate parameters
     */
    function setInterestRateParams(uint256 _baseRate, uint256 _multiplier) external onlyOwner {
        baseInterestRate = _baseRate;
        utilizationMultiplier = _multiplier;
    }
    
    /**
     * @dev Updates liquidation ratio for an asset (for testing/emergency)
     */
    function updateLiquidationRatio(address token, uint256 newLiquidationRatio) external onlyOwner {
        require(assetConfigs[token].token != address(0), "Asset not configured");
        require(newLiquidationRatio > 0, "Liquidation ratio must be positive");
        require(newLiquidationRatio < assetConfigs[token].collateralRatio, "Must be below collateral ratio");
        
        uint256 oldRatio = assetConfigs[token].liquidationRatio;
        assetConfigs[token].liquidationRatio = newLiquidationRatio;
        
        emit LiquidationRatioUpdated(token, oldRatio, newLiquidationRatio);
    }
    
    /**
     * @dev Updates collateral ratio for an asset
     */
    function updateCollateralRatio(address token, uint256 newCollateralRatio) external onlyOwner {
        require(assetConfigs[token].token != address(0), "Asset not configured");
        require(newCollateralRatio > assetConfigs[token].liquidationRatio, "Must be above liquidation ratio");
        
        uint256 oldRatio = assetConfigs[token].collateralRatio;
        assetConfigs[token].collateralRatio = newCollateralRatio;
        
        emit CollateralRatioUpdated(token, oldRatio, newCollateralRatio);
    }
    
    /**
     * @dev Batch update both ratios safely
     */
    function updateBothRatios(
        address token, 
        uint256 newCollateralRatio, 
        uint256 newLiquidationRatio
    ) external onlyOwner {
        require(assetConfigs[token].token != address(0), "Asset not configured");
        require(newLiquidationRatio > 0, "Liquidation ratio must be positive");
        require(newCollateralRatio > newLiquidationRatio, "Collateral ratio must be higher than liquidation ratio");
        
        uint256 oldCollateralRatio = assetConfigs[token].collateralRatio;
        uint256 oldLiquidationRatio = assetConfigs[token].liquidationRatio;
        
        assetConfigs[token].collateralRatio = newCollateralRatio;
        assetConfigs[token].liquidationRatio = newLiquidationRatio;
        
        emit BothRatiosUpdated(token, oldCollateralRatio, newCollateralRatio, oldLiquidationRatio, newLiquidationRatio);
    }
    
    /**
     * @dev Standard interface for updating both ratios (compatible with FlexibleAssetHandler)
     */
    function updateEnforcedRatios(
        address token, 
        uint256 newCollateralRatio, 
        uint256 newLiquidationRatio
    ) external onlyOwner {
        // FIXED: Use internal logic instead of external call to avoid ownership issues
        require(assetConfigs[token].token != address(0), "Asset not configured");
        require(newLiquidationRatio > 0, "Liquidation ratio must be positive");
        require(newCollateralRatio > newLiquidationRatio, "Collateral ratio must be higher than liquidation ratio");
        
        uint256 oldCollateralRatio = assetConfigs[token].collateralRatio;
        uint256 oldLiquidationRatio = assetConfigs[token].liquidationRatio;
        
        assetConfigs[token].collateralRatio = newCollateralRatio;
        assetConfigs[token].liquidationRatio = newLiquidationRatio;
        
        emit BothRatiosUpdated(token, oldCollateralRatio, newCollateralRatio, oldLiquidationRatio, newLiquidationRatio);
    }

    /**
     * @dev ⚡ ENHANCED: Emergency function that coordinates with centralized registry
     */
    function emergencyLiquidationMode(address token, bool enableEmergency) external onlyOwner {
        require(assetConfigs[token].token != address(0), "Asset not configured");
        
        if (enableEmergency) {
            // ⚡ LOCAL: Set liquidation ratio very high to make positions liquidatable
            assetConfigs[token].liquidationRatio = 2000000; // 200% - most positions will be liquidatable
            
            // ⚡ CENTRALIZED: Also update emergency registry for system-wide coordination
            if (address(emergencyRegistry) != address(0)) {
                emergencyRegistry.setAssetEmergencyLevel(
                    token,
                    IEmergencyRegistry.EmergencyLevel.EMERGENCY,
                    2000000, // Same ratio as local setting
                    "VaultBasedHandler emergency activation"
                );
            }
            
            emit EmergencyLiquidationEnabled(token);
        } else {
            // ⚡ LOCAL: Reset to reasonable ratio
            assetConfigs[token].liquidationRatio = 1200000; // 120% - back to normal
            
            // ⚡ CENTRALIZED: Also resolve emergency in registry
            if (address(emergencyRegistry) != address(0)) {
                emergencyRegistry.setAssetEmergencyLevel(
                    token,
                    IEmergencyRegistry.EmergencyLevel.NONE,
                    0,
                    "VaultBasedHandler emergency resolved"
                );
            }
            
            emit EmergencyLiquidationDisabled(token);
        }
    }
    
    /**
     * @dev ⚡ NEW: Sets emergency registry for coordination
     */
    function setEmergencyRegistry(address _emergencyRegistry) external onlyOwner {
        emergencyRegistry = IEmergencyRegistry(_emergencyRegistry);
    }
    
    // ========================================
    // 🤖 AUTOMATION LIQUIDATION SUPPORT
    // ========================================
    
    // Authorized automation contracts that can use vault liquidity
    mapping(address => bool) public authorizedAutomationContracts;
    
    // Track automation liquidations
    mapping(address => uint256) public automationLiquidationsCount;
    mapping(address => uint256) public automationRecoveredAmount;
    
    // Events for automation
    event AutomationContractAuthorized(address indexed automationContract);
    event AutomationContractDeauthorized(address indexed automationContract);
    event AutomationLiquidationExecuted(address indexed token, uint256 debtAmount, uint256 collateralAmount);
    
    /**
     * @dev 🤖 Authorizes an automation contract to use vault liquidity for liquidations
     */
    function authorizeAutomationContract(address automationContract) external onlyOwner {
        require(automationContract != address(0), "Invalid automation contract");
        authorizedAutomationContracts[automationContract] = true;
        emit AutomationContractAuthorized(automationContract);
    }
    
    /**
     * @dev 🤖 Deauthorizes an automation contract
     */
    function deauthorizeAutomationContract(address automationContract) external onlyOwner {
        authorizedAutomationContracts[automationContract] = false;
        emit AutomationContractDeauthorized(automationContract);
    }
    
    /**
     * @dev 🤖 AUTOMATION REPAY: Uses vault liquidity to repay debt during liquidation
     * This function allows authorized automation contracts to use vault funds to execute liquidations
     */
    function automationRepay(
        address token, 
        uint256 amount, 
        address collateralToken,
        uint256 collateralAmount,
        address liquidatedBorrower
    ) external returns (bool success) {
        // Security: Only authorized automation contracts
        require(authorizedAutomationContracts[msg.sender], "Unauthorized automation contract");
        
        AssetConfig memory config = assetConfigs[token];
        require(config.isActive, "Asset not active");
        require(config.assetType == AssetType.VAULT_BASED, "Invalid asset type");
        
        VaultInfo storage vault = vaultInfo[token];
        uint256 availableLiquidity = vault.totalLiquidity - vault.totalBorrowed;
        
        // Check if vault has enough liquidity
        if (availableLiquidity < amount) {
            return false; // Not enough liquidity for automation repay
        }
        
        // Accrue interest before updating
        _accrueInterest(token);
        
        // Use vault liquidity (mark as "borrowed" temporarily)
        vault.totalBorrowed += amount;
        vault.lastUpdateTimestamp = block.timestamp;
        
        // Transfer tokens to automation contract for liquidation execution
        IERC20(token).safeTransfer(msg.sender, amount);
        
        // 📝 NOTE: The automation contract MUST transfer collateral back to this vault
        // This will be handled in the automation contract's liquidation flow
        
        // Track automation activity
        automationLiquidationsCount[token]++;
        
        // Update utilization rate
        _updateUtilizationRate(token);
        
        emit AutomationLiquidationExecuted(token, amount, collateralAmount);
        emit TokensLent(token, msg.sender, amount);
        
        return true;
    }
    
    /**
     * @dev 🤖 AUTOMATION RECOVERY: Receives collateral from liquidation and sells it
     * Called by automation contract after successful liquidation to return collateral
     */
    function automationRecovery(
        address debtToken,
        uint256 debtAmount,
        address collateralToken,
        uint256 collateralAmount
    ) external {
        require(authorizedAutomationContracts[msg.sender], "Unauthorized automation contract");
        
        // Receive collateral from automation contract
        IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), collateralAmount);
        
        // 💰 TODO: Implement collateral selling logic here
        // For now, we'll assume collateral is worth at least the debt amount
        // In production, you'd integrate with a DEX or oracle-based selling mechanism
        
        VaultInfo storage vault = vaultInfo[debtToken];
        
        // Reduce the "borrowed" amount since we've recovered funds
        vault.totalBorrowed = vault.totalBorrowed > debtAmount ? vault.totalBorrowed - debtAmount : 0;
        
        // Track recovery
        automationRecoveredAmount[debtToken] += debtAmount;
        
        // Update utilization rate
        _updateUtilizationRate(debtToken);
        
        emit TokensRepaid(debtToken, msg.sender, debtAmount);
    }
    
    /**
     * @dev 🤖 Gets automation liquidity status for a token
     */
    function getAutomationLiquidityStatus(address token) external view returns (
        uint256 availableForAutomation,
        uint256 totalAutomationLiquidations,
        uint256 totalRecovered,
        bool canLiquidate
    ) {
        VaultInfo memory vault = vaultInfo[token];
        uint256 available = vault.totalLiquidity > vault.totalBorrowed 
            ? vault.totalLiquidity - vault.totalBorrowed 
            : 0;
            
        return (
            available,
            automationLiquidationsCount[token],
            automationRecoveredAmount[token],
            available > 0 && assetConfigs[token].isActive
        );
    }
    
    // ========================================
    // IRewardable Implementation
    // ========================================
    
    /**
     * @dev Updates user rewards when liquidity changes
     */
    function updateUserRewards(address user, uint256 amount, bool isIncrease) external override {
        require(msg.sender == address(this), "Only self can update rewards");
        // For now, we'll use a generic pool ID - in production you'd determine the correct pool based on the token
        bytes32 poolId = VAULT_ETH_POOL_ID; // This should be determined dynamically
        if (address(rewardDistributor) != address(0)) {
            rewardDistributor.updateStake(poolId, user, amount, isIncrease);
            emit RewardsUpdated(user, amount, poolId);
        }
    }
    
    /**
     * @dev Gets pending rewards for a user
     */
    function getPendingRewards(address user) external view override returns (uint256) {
        if (address(rewardDistributor) == address(0)) return 0;
        // For now, we'll check the ETH pool - in production you'd check all pools
        return rewardDistributor.pendingRewards(VAULT_ETH_POOL_ID, user);
    }
    
    /**
     * @dev Claims rewards for the caller
     */
    function claimRewards() external override returns (uint256) {
        require(address(rewardDistributor) != address(0), "Reward distributor not set");
        
        // For now, we'll claim from ETH pool - in production you'd claim from all pools
        uint256 pending = rewardDistributor.pendingRewards(VAULT_ETH_POOL_ID, msg.sender);
        if (pending > 0) {
            rewardDistributor.claimRewards(VAULT_ETH_POOL_ID);
            emit RewardsClaimed(msg.sender, pending, VAULT_ETH_POOL_ID);
        }
        return pending;
    }
    
    /**
     * @dev Gets the reward pool ID for this contract
     */
    function getRewardPoolId() external pure override returns (bytes32) {
        return VAULT_ETH_POOL_ID; // Default to ETH pool
    }
    
    /**
     * @dev Gets reward distributor address
     */
    function getRewardDistributor() external view override returns (address) {
        return address(rewardDistributor);
    }
    
    /**
     * @dev Sets the reward distributor (only owner)
     */
    function setRewardDistributor(address distributor) external override onlyOwner {
        rewardDistributor = RewardDistributor(distributor);
    }
    
    /**
     * @dev Internal function to update rewards when liquidity changes
     */
    function _updateUserRewards(address user, address token, uint256 amount, bool isIncrease) internal {
        if (address(rewardDistributor) != address(0)) {
            bytes32 poolId = _getPoolIdForToken(token);
            rewardDistributor.updateStake(poolId, user, amount, isIncrease);
            emit RewardsUpdated(user, amount, poolId);
        }
    }
    
    /**
     * @dev Gets the pool ID for a specific token
     */
    function _getPoolIdForToken(address token) internal pure returns (bytes32) {
        // This is a simplified version - in production you'd have a proper mapping
        return keccak256(abi.encodePacked("VAULT_", token, "_LIQUIDITY"));
    }
} 
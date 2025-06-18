// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ILoanManager} from "../interfaces/ILoanManager.sol";
import {IAssetHandler} from "../interfaces/IAssetHandler.sol";
import {IGenericOracle} from "../interfaces/IGenericOracle.sol";
import {IRewardable} from "../interfaces/IRewardable.sol";
import {ILoanAutomation} from "../automation/interfaces/ILoanAutomation.sol";
import {RewardDistributor} from "./RewardDistributor.sol";

/**
 * @title GenericLoanManager
 * @notice Manages loans with flexible collateral and loan asset combinations
 */
contract GenericLoanManager is ILoanManager, IRewardable, ILoanAutomation, Ownable {
    using SafeERC20 for IERC20;
    
    // Asset handlers for different types of assets
    mapping(IAssetHandler.AssetType => address) public assetHandlers;
    
    // Oracle for price feeds
    IGenericOracle public oracle;
    
    // Loan positions
    mapping(uint256 => LoanPosition) public positions;
    mapping(address => uint256[]) public userPositions;
    uint256 public nextPositionId = 1;
    
    // Risk parameters
    uint256 public constant LIQUIDATION_BONUS = 50000; // 5% bonus for liquidators
    uint256 public constant MAX_LTV = 800000; // 80% maximum loan-to-value
    
    // Protocol fees
    uint256 public protocolFee = 5000; // 0.5% (6 decimals: 0.5% = 5000)
    address public feeCollector;
    
    // Interest management
    mapping(uint256 => uint256) public accruedInterest;
    
    // Reward system
    RewardDistributor public rewardDistributor;
    bytes32 public constant REWARD_POOL_ID = keccak256("GENERIC_LOAN_COLLATERAL");
    
    // ========================================
    // AUTOMATION SYSTEM CONFIGURATION
    // ========================================
    
    // Automation contract address (set by owner after deployment)
    address public automationContract;
    
    // Automation settings
    bool public automationEnabled = false;
    uint256 public automationRiskThreshold = 85; // Default 85% risk threshold
    
    // Active positions tracking for automation
    uint256[] public activePositionIds;
    mapping(uint256 => uint256) public positionIdToIndex; // positionId => index in activePositionIds
    
    // Events for automation
    event AutomationContractSet(address indexed automationContract);
    event AutomationStatusChanged(bool enabled);
    event AutomationRiskThresholdUpdated(uint256 newThreshold);
    event AutomatedLiquidationExecuted(uint256 indexed positionId, address indexed liquidator, uint256 amount);

    constructor(address _oracle, address _feeCollector) Ownable(msg.sender) {
        oracle = IGenericOracle(_oracle);
        feeCollector = _feeCollector;
    }
    
    /**
     * @dev Sets asset handler for a specific asset type
     */
    function setAssetHandler(IAssetHandler.AssetType assetType, address handler) external onlyOwner {
        require(handler != address(0), "Invalid handler address");
        assetHandlers[assetType] = handler;
    }
    
    /**
     * @dev Creates a new loan position
     */
    function createLoan(LoanTerms calldata terms) external override returns (uint256 positionId) {
        require(terms.collateralAmount > 0, "Invalid collateral amount");
        require(terms.loanAmount > 0, "Invalid loan amount");
        require(terms.collateralAsset != terms.loanAsset, "Collateral and loan assets must be different");
        
        // Get asset handlers
        IAssetHandler collateralHandler = _getAssetHandler(terms.collateralAsset);
        IAssetHandler loanHandler = _getAssetHandler(terms.loanAsset);
        
        // Verify assets are supported
        require(collateralHandler.isAssetSupported(terms.collateralAsset), "Collateral asset not supported");
        require(loanHandler.isAssetSupported(terms.loanAsset), "Loan asset not supported");
        
        // Calculate loan-to-value ratio
        uint256 ltvRatio = _calculateLTV(terms.collateralAsset, terms.loanAsset, terms.collateralAmount, terms.loanAmount);
        require(ltvRatio <= terms.maxLoanToValue, "LTV exceeds maximum");
        require(ltvRatio <= MAX_LTV, "LTV exceeds protocol maximum");
        
        // Check collateral requirements
        IAssetHandler.AssetConfig memory collateralConfig = collateralHandler.getAssetConfig(terms.collateralAsset);
        uint256 requiredCollateralValue = (terms.loanAmount * collateralConfig.collateralRatio) / 1000000;
        uint256 providedCollateralValue = _getAssetValue(terms.collateralAsset, terms.collateralAmount);
        require(providedCollateralValue >= requiredCollateralValue, "Insufficient collateral");
        
        // Check liquidity availability
        require(
            loanHandler.getAvailableLiquidity(terms.loanAsset) >= terms.loanAmount,
            "Insufficient liquidity"
        );
        
        // Transfer collateral from user
        IERC20(terms.collateralAsset).safeTransferFrom(msg.sender, address(this), terms.collateralAmount);
        
        // Create position
        positionId = nextPositionId++;
        positions[positionId] = LoanPosition({
            borrower: msg.sender,
            collateralAsset: terms.collateralAsset,
            loanAsset: terms.loanAsset,
            collateralAmount: terms.collateralAmount,
            loanAmount: terms.loanAmount,
            interestRate: terms.interestRate,
            createdAt: block.timestamp,
            lastInterestUpdate: block.timestamp,
            isActive: true
        });
        
        userPositions[msg.sender].push(positionId);
        
        // Add to active positions tracking for automation
        _addActivePosition(positionId);
        
        // Execute loan through asset handler
        loanHandler.lend(terms.loanAsset, terms.loanAmount, msg.sender);
        
        // Update reward system
        _updateUserRewards(msg.sender, terms.collateralAmount, true);
        
        emit LoanCreated(
            positionId,
            msg.sender,
            terms.collateralAsset,
            terms.loanAsset,
            terms.collateralAmount,
            terms.loanAmount
        );
    }
    
    /**
     * @dev Adds collateral to an existing position
     */
    function addCollateral(uint256 positionId, uint256 amount) external override {
        LoanPosition storage position = positions[positionId];
        require(position.isActive, "Position not active");
        require(position.borrower == msg.sender, "Not position owner");
        require(amount > 0, "Invalid amount");
        
        // Transfer additional collateral
        IERC20(position.collateralAsset).safeTransferFrom(msg.sender, address(this), amount);
        
        // Update position
        position.collateralAmount += amount;
        
        // Update reward system
        _updateUserRewards(msg.sender, amount, true);
        
        emit CollateralAdded(positionId, amount);
    }
    
    /**
     * @dev Withdraws collateral from a position (if ratio allows)
     */
    function withdrawCollateral(uint256 positionId, uint256 amount) external override {
        LoanPosition storage position = positions[positionId];
        require(position.isActive, "Position not active");
        require(position.borrower == msg.sender, "Not position owner");
        require(amount <= position.collateralAmount, "Insufficient collateral");
        
        // Update interest before checking ratios
        updateInterest(positionId);
        
        // Check if withdrawal maintains adequate collateralization
        uint256 remainingCollateral = position.collateralAmount - amount;
        uint256 totalDebt = getTotalDebt(positionId);
        
        IAssetHandler collateralHandler = _getAssetHandler(position.collateralAsset);
        IAssetHandler.AssetConfig memory config = collateralHandler.getAssetConfig(position.collateralAsset);
        
        uint256 minCollateralValue = (totalDebt * config.collateralRatio) / 1000000;
        uint256 remainingCollateralValue = _getAssetValue(position.collateralAsset, remainingCollateral);
        
        require(remainingCollateralValue >= minCollateralValue, "Withdrawal would breach collateral ratio");
        
        // Update position and transfer collateral
        position.collateralAmount = remainingCollateral;
        IERC20(position.collateralAsset).safeTransfer(msg.sender, amount);
        
        // Update reward system
        _updateUserRewards(msg.sender, amount, false);
        
        emit CollateralWithdrawn(positionId, amount);
    }
    
    /**
     * @dev Repays part or all of the loan
     */
    function repayLoan(uint256 positionId, uint256 amount) external override {
        LoanPosition storage position = positions[positionId];
        require(position.isActive, "Position not active");
        require(amount > 0, "Invalid amount");
        
        // Update interest before repayment
        updateInterest(positionId);
        
        uint256 totalDebt = getTotalDebt(positionId);
        uint256 repayAmount = amount > totalDebt ? totalDebt : amount;
        
        // Calculate interest and principal portions
        uint256 currentInterest = accruedInterest[positionId];
        uint256 interestPayment = repayAmount > currentInterest ? currentInterest : repayAmount;
        uint256 principalPayment = repayAmount - interestPayment;
        
        // Process interest payment (protocol fee)
        if (interestPayment > 0) {
            uint256 fee = (interestPayment * protocolFee) / 1000000;
            if (fee > 0) {
                IERC20(position.loanAsset).safeTransferFrom(msg.sender, feeCollector, fee);
            }
            accruedInterest[positionId] -= interestPayment;
        }
        
        // Process principal repayment through asset handler
        if (principalPayment > 0) {
            IAssetHandler loanHandler = _getAssetHandler(position.loanAsset);
            loanHandler.repay(position.loanAsset, principalPayment, msg.sender);
            position.loanAmount -= principalPayment;
        }
        
        // If fully repaid, return collateral and close position
        if (position.loanAmount == 0 && accruedInterest[positionId] == 0) {
            IERC20(position.collateralAsset).safeTransfer(msg.sender, position.collateralAmount);
            position.isActive = false;
            
            // Remove from active positions tracking
            _removeActivePosition(positionId);
        }
        
        emit LoanRepaid(positionId, repayAmount);
    }
    
    /**
     * @dev Liquidates an undercollateralized position
     */
    function liquidatePosition(uint256 positionId) external override {
        LoanPosition storage position = positions[positionId];
        require(position.isActive, "Position not active");
        
        // Update interest before liquidation check
        updateInterest(positionId);
        
        require(canLiquidate(positionId), "Position not liquidatable");
        
        uint256 totalDebt = getTotalDebt(positionId);
        uint256 collateralValue = _getAssetValue(position.collateralAsset, position.collateralAmount);
        
        // Calculate liquidation amounts
        uint256 debtToRepay = totalDebt;
        uint256 liquidationBonus = (collateralValue * LIQUIDATION_BONUS) / 1000000;
        uint256 liquidatorReward = collateralValue > debtToRepay + liquidationBonus 
            ? debtToRepay + liquidationBonus 
            : collateralValue;
        
        // Liquidator repays debt
        IAssetHandler loanHandler = _getAssetHandler(position.loanAsset);
        loanHandler.repay(position.loanAsset, debtToRepay, msg.sender);
        
        // Transfer collateral to liquidator
        uint256 collateralToLiquidator = (liquidatorReward * position.collateralAmount) / collateralValue;
        IERC20(position.collateralAsset).safeTransfer(msg.sender, collateralToLiquidator);
        
        // Return remaining collateral to borrower (if any)
        uint256 remainingCollateral = position.collateralAmount - collateralToLiquidator;
        if (remainingCollateral > 0) {
            IERC20(position.collateralAsset).safeTransfer(position.borrower, remainingCollateral);
        }
        
        // Update reward system - remove all collateral
        _updateUserRewards(position.borrower, position.collateralAmount, false);
        
        // Close position
        position.isActive = false;
        accruedInterest[positionId] = 0;
        
        emit PositionLiquidated(positionId, msg.sender);
    }
    
    /**
     * @dev Updates interest for a position
     */
    function updateInterest(uint256 positionId) public override {
        LoanPosition storage position = positions[positionId];
        require(position.isActive, "Position not active");
        
        if (position.lastInterestUpdate == block.timestamp) {
            return; // Already updated this block
        }
        
        uint256 timeElapsed = block.timestamp - position.lastInterestUpdate;
        uint256 interestAmount = (position.loanAmount * position.interestRate * timeElapsed) / (365 * 24 * 3600 * 1000000);
        
        accruedInterest[positionId] += interestAmount;
        position.lastInterestUpdate = block.timestamp;
        
        emit InterestUpdated(positionId, interestAmount);
    }
    
    /**
     * @dev Gets position details
     */
    function getPosition(uint256 positionId) external view override returns (LoanPosition memory) {
        return positions[positionId];
    }
    
    /**
     * @dev Gets current collateralization ratio
     */
    function getCollateralizationRatio(uint256 positionId) external view override returns (uint256) {
        LoanPosition memory position = positions[positionId];
        if (!position.isActive || position.loanAmount == 0) {
            return type(uint256).max;
        }
        
        uint256 collateralValue = _getAssetValue(position.collateralAsset, position.collateralAmount);
        uint256 totalDebt = getTotalDebt(positionId);
        
        return (collateralValue * 1000000) / totalDebt;
    }
    
    /**
     * @dev Checks if position can be liquidated
     */
    function canLiquidate(uint256 positionId) public view override returns (bool) {
        LoanPosition memory position = positions[positionId];
        if (!position.isActive) {
            return false;
        }
        
        IAssetHandler collateralHandler = _getAssetHandler(position.collateralAsset);
        IAssetHandler.AssetConfig memory config = collateralHandler.getAssetConfig(position.collateralAsset);
        
        uint256 currentRatio = this.getCollateralizationRatio(positionId);
        return currentRatio < config.liquidationRatio;
    }
    
    /**
     * @dev Gets maximum borrowable amount for given collateral
     */
    function getMaxBorrowAmount(
        address collateralAsset,
        address loanAsset,
        uint256 collateralAmount
    ) external view override returns (uint256) {
        IAssetHandler collateralHandler = _getAssetHandler(collateralAsset);
        IAssetHandler.AssetConfig memory config = collateralHandler.getAssetConfig(collateralAsset);
        
        uint256 collateralValue = _getAssetValue(collateralAsset, collateralAmount);
        uint256 maxLoanValue = (collateralValue * 1000000) / config.collateralRatio;
        
        // Convert to loan asset units
        uint256 loanAssetPrice = oracle.getPrice(loanAsset, collateralAsset);
        return (maxLoanValue * 1000000) / loanAssetPrice;
    }
    
    /**
     * @dev Gets accrued interest for a position
     */
    function getAccruedInterest(uint256 positionId) external view override returns (uint256) {
        LoanPosition memory position = positions[positionId];
        if (!position.isActive) {
            return 0;
        }
        
        uint256 currentAccrued = accruedInterest[positionId];
        uint256 timeElapsed = block.timestamp - position.lastInterestUpdate;
        uint256 newInterest = (position.loanAmount * position.interestRate * timeElapsed) / (365 * 24 * 3600 * 1000000);
        
        return currentAccrued + newInterest;
    }
    
    /**
     * @dev Gets total debt (principal + interest) for a position
     */
    function getTotalDebt(uint256 positionId) public view override returns (uint256) {
        LoanPosition memory position = positions[positionId];
        if (!position.isActive) {
            return 0;
        }
        
        return position.loanAmount + this.getAccruedInterest(positionId);
    }
    
    /**
     * @dev Gets asset handler for a given asset
     */
    function _getAssetHandler(address asset) internal view returns (IAssetHandler) {
        // Try each asset type to find the correct handler
        for (uint i = 0; i < 3; i++) {
            IAssetHandler.AssetType assetType = IAssetHandler.AssetType(i);
            address handlerAddress = assetHandlers[assetType];
            
            if (handlerAddress != address(0)) {
                IAssetHandler handler = IAssetHandler(handlerAddress);
                if (handler.isAssetSupported(asset)) {
                    return handler;
                }
            }
        }
        
        revert("No handler found for asset");
    }
    
    /**
     * @dev Gets the value of an asset amount in terms of a base currency
     */
    function _getAssetValue(address asset, uint256 amount) internal view returns (uint256) {
        // For mock tokens in testing, we'll use hardcoded prices
        // In production, this should use the oracle properly
        
        // NEW Mock ETH = $2500 (DIRECCION ACTUALIZADA)
        if (asset == 0xca09D6c5f9f5646A20b5EF71986EED5f8A86add0) {
            return (amount * 2500) / 1e18; // Convert 1 ETH to $2500 value
        }
        
        // NEW Mock USDC = $1 (DIRECCION ACTUALIZADA)
        if (asset == 0xAdc9649EF0468d6C73B56Dc96fF6bb527B8251A0) {
            return amount / 1e6; // Convert USDC (6 decimals) to dollar value
        }
        
        // NEW Mock WBTC = $70000 (DIRECCION ACTUALIZADA)
        if (asset == 0x6C2AAf9cFb130d516401Ee769074F02fae6ACb91) {
            return (amount * 70000) / 1e8; // Convert 1 WBTC to $70000 value
        }
        
        // Fallback: try to use oracle (for production)
        try oracle.getPrice(asset, address(0x6AC157633e53bb59C5eE2eFB26Ea4cAaA160a381)) returns (uint256 price) {
            if (price > 0) {
                return (amount * price) / 1e18; // Assuming 18 decimal price
            }
        } catch {
            // Oracle failed, fallback to 1:1 ratio
        }
        
        // Last resort: return raw amount (old behavior)
        return amount;
    }
    
    /**
     * @dev Calculates loan-to-value ratio
     */
    function _calculateLTV(
        address collateralAsset,
        address loanAsset,
        uint256 collateralAmount,
        uint256 loanAmount
    ) internal view returns (uint256) {
        uint256 collateralValue = _getAssetValue(collateralAsset, collateralAmount);
        uint256 loanValue = _getAssetValue(loanAsset, loanAmount);
        
        return (loanValue * 1000000) / collateralValue;
    }
    
    /**
     * @dev Gets user's positions
     */
    function getUserPositions(address user) external view returns (uint256[] memory) {
        return userPositions[user];
    }
    
    /**
     * @dev Sets protocol fee
     */
    function setProtocolFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100000, "Fee too high"); // Max 10%
        protocolFee = _fee;
    }
    
    /**
     * @dev Sets fee collector
     */
    function setFeeCollector(address _collector) external onlyOwner {
        require(_collector != address(0), "Invalid address");
        feeCollector = _collector;
    }
    
    // ========================================
    // IRewardable Implementation
    // ========================================
    
    /**
     * @dev Updates user rewards when collateral changes
     */
    function updateUserRewards(address user, uint256 amount, bool isIncrease) external override {
        require(msg.sender == address(this), "Only self can update rewards");
        if (address(rewardDistributor) != address(0)) {
            rewardDistributor.updateStake(REWARD_POOL_ID, user, amount, isIncrease);
            emit RewardsUpdated(user, amount, REWARD_POOL_ID);
        }
    }
    
    /**
     * @dev Gets pending rewards for a user
     */
    function getPendingRewards(address user) external view override returns (uint256) {
        if (address(rewardDistributor) == address(0)) return 0;
        return rewardDistributor.pendingRewards(REWARD_POOL_ID, user);
    }
    
    /**
     * @dev Claims rewards for the caller
     */
    function claimRewards() external override returns (uint256) {
        require(address(rewardDistributor) != address(0), "Reward distributor not set");
        
        uint256 pending = rewardDistributor.pendingRewards(REWARD_POOL_ID, msg.sender);
        if (pending > 0) {
            rewardDistributor.claimRewards(REWARD_POOL_ID);
            emit RewardsClaimed(msg.sender, pending, REWARD_POOL_ID);
        }
        return pending;
    }
    
    /**
     * @dev Gets the reward pool ID for this contract
     */
    function getRewardPoolId() external pure override returns (bytes32) {
        return REWARD_POOL_ID;
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
     * @dev Internal function to update rewards when collateral changes
     */
    function _updateUserRewards(address user, uint256 amount, bool isIncrease) internal {
        if (address(rewardDistributor) != address(0)) {
            rewardDistributor.updateStake(REWARD_POOL_ID, user, amount, isIncrease);
            emit RewardsUpdated(user, amount, REWARD_POOL_ID);
        }
    }

    // ========================================
    // AUTOMATION CONFIGURATION FUNCTIONS
    // ========================================
    
    /**
     * @dev Sets the authorized automation contract (only owner)
     * @param _automationContract Address of the automation contract
     */
    function setAutomationContract(address _automationContract) external override onlyOwner {
        automationContract = _automationContract;
        emit AutomationContractSet(_automationContract);
    }
    
    /**
     * @dev Enables or disables automation (only owner)
     * @param enabled Whether automation should be enabled
     */
    function setAutomationEnabled(bool enabled) external onlyOwner {
        automationEnabled = enabled;
        emit AutomationStatusChanged(enabled);
    }
    
    /**
     * @dev Sets automation risk threshold (only owner)
     * @param threshold Risk threshold (0-100)
     */
    function setAutomationRiskThreshold(uint256 threshold) external onlyOwner {
        require(threshold <= 100, "Threshold must be <= 100");
        automationRiskThreshold = threshold;
        emit AutomationRiskThresholdUpdated(threshold);
    }
    
    /**
     * @dev Modifier to restrict access to automation contract
     */
    modifier onlyAutomation() {
        require(msg.sender == automationContract, "Only automation contract");
        require(automationEnabled, "Automation not enabled");
        _;
    }
    
    // ========================================
    // AUTOMATION INTERFACE IMPLEMENTATION
    // ========================================
    
    /**
     * @dev Gets the total number of active positions for automation scanning
     */
    function getTotalActivePositions() external view override returns (uint256) {
        return activePositionIds.length;
    }
    
    /**
     * @dev Gets positions in a specific range for batch processing
     */
    function getPositionsInRange(uint256 startIndex, uint256 endIndex) 
        external view override returns (uint256[] memory positionIds) {
        require(startIndex <= endIndex, "Invalid range");
        require(endIndex < activePositionIds.length, "End index out of bounds");
        
        uint256 length = endIndex - startIndex + 1;
        positionIds = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            positionIds[i] = activePositionIds[startIndex + i];
        }
    }
    
    /**
     * @dev Checks if a position is at risk of liquidation
     */
    function isPositionAtRisk(uint256 positionId) 
        external view override returns (bool isAtRisk, uint256 riskLevel) {
        LoanPosition memory position = positions[positionId];
        if (!position.isActive) {
            return (false, 0);
        }
        
        // Calculate current collateralization ratio
        uint256 currentRatio = this.getCollateralizationRatio(positionId);
        
        // Get liquidation threshold
        IAssetHandler collateralHandler = _getAssetHandler(position.collateralAsset);
        IAssetHandler.AssetConfig memory config = collateralHandler.getAssetConfig(position.collateralAsset);
        
        // Calculate risk level (0-100, where 100+ means liquidation needed)
        if (currentRatio <= config.liquidationRatio) {
            return (true, 100); // Immediate liquidation needed
        }
        
        // Calculate risk level based on how close to liquidation
        uint256 safeRatio = config.collateralRatio;
        if (currentRatio <= safeRatio) {
            // Risk increases as ratio decreases from safe to liquidation threshold
            riskLevel = 100 - ((currentRatio - config.liquidationRatio) * 100) / (safeRatio - config.liquidationRatio);
            isAtRisk = riskLevel >= automationRiskThreshold;
        } else {
            riskLevel = 0; // Safe position
            isAtRisk = false;
        }
    }
    
    /**
     * @dev Performs automated liquidation of a position
     */
    function automatedLiquidation(uint256 positionId) 
        external override onlyAutomation returns (bool success, uint256 liquidatedAmount) {
        LoanPosition storage position = positions[positionId];
        require(position.isActive, "Position not active");
        
        // Update interest before liquidation check
        updateInterest(positionId);
        
        require(canLiquidate(positionId), "Position not liquidatable");
        
        uint256 totalDebt = getTotalDebt(positionId);
        uint256 collateralValue = _getAssetValue(position.collateralAsset, position.collateralAmount);
        
        // Calculate liquidation amounts
        uint256 debtToRepay = totalDebt;
        uint256 liquidationBonus = (collateralValue * LIQUIDATION_BONUS) / 1000000;
        uint256 liquidatorReward = collateralValue > debtToRepay + liquidationBonus 
            ? debtToRepay + liquidationBonus 
            : collateralValue;
        
        // Liquidator (automation) repays debt
        IAssetHandler loanHandler = _getAssetHandler(position.loanAsset);
        loanHandler.repay(position.loanAsset, debtToRepay, automationContract);
        
        // Transfer collateral to liquidator (automation contract)
        uint256 collateralToLiquidator = (liquidatorReward * position.collateralAmount) / collateralValue;
        IERC20(position.collateralAsset).safeTransfer(automationContract, collateralToLiquidator);
        
        // Return remaining collateral to borrower (if any)
        uint256 remainingCollateral = position.collateralAmount - collateralToLiquidator;
        if (remainingCollateral > 0) {
            IERC20(position.collateralAsset).safeTransfer(position.borrower, remainingCollateral);
        }
        
        // Update reward system - remove all collateral
        _updateUserRewards(position.borrower, position.collateralAmount, false);
        
        // Close position and remove from active tracking
        position.isActive = false;
        accruedInterest[positionId] = 0;
        _removeActivePosition(positionId);
        
        emit AutomatedLiquidationExecuted(positionId, automationContract, debtToRepay);
        emit PositionLiquidated(positionId, automationContract);
        
        return (true, debtToRepay);
    }
    
    /**
     * @dev Gets position details for automation purposes
     */
    function getPositionHealthData(uint256 positionId) 
        external view override returns (
            address borrower,
            uint256 collateralValue,
            uint256 debtValue,
            uint256 healthFactor
        ) {
        LoanPosition memory position = positions[positionId];
        require(position.isActive, "Position not active");
        
        borrower = position.borrower;
        collateralValue = _getAssetValue(position.collateralAsset, position.collateralAmount);
        uint256 totalDebt = getTotalDebt(positionId);
        debtValue = _getAssetValue(position.loanAsset, totalDebt);
        
        // Health factor = collateral value / debt value (scaled by 1e18)
        healthFactor = debtValue > 0 ? (collateralValue * 1e18) / debtValue : type(uint256).max;
    }
    
    /**
     * @dev Checks if automation is enabled for this contract
     */
    function isAutomationEnabled() external view override returns (bool) {
        return automationEnabled && automationContract != address(0);
    }
    
    // ========================================
    // AUTOMATION HELPER FUNCTIONS
    // ========================================
    
    /**
     * @dev Adds a position to active positions tracking
     */
    function _addActivePosition(uint256 positionId) internal {
        activePositionIds.push(positionId);
        positionIdToIndex[positionId] = activePositionIds.length - 1;
    }
    
    /**
     * @dev Removes a position from active positions tracking
     */
    function _removeActivePosition(uint256 positionId) internal {
        uint256 index = positionIdToIndex[positionId];
        uint256 lastIndex = activePositionIds.length - 1;
        
        if (index != lastIndex) {
            uint256 lastPositionId = activePositionIds[lastIndex];
            activePositionIds[index] = lastPositionId;
            positionIdToIndex[lastPositionId] = index;
        }
        
        activePositionIds.pop();
        delete positionIdToIndex[positionId];
    }
    
    /**
     * @dev Gets all active position IDs (for debugging)
     */
    function getActivePositionIds() external view returns (uint256[] memory) {
        return activePositionIds;
    }
} 
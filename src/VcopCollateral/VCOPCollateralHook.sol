// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/src/types/PoolOperation.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {VCOPCollateralManager} from "./VCOPCollateralManager.sol";
import {VCOPCollateralized} from "./VCOPCollateralized.sol";
import {VCOPOracle} from "./VCOPOracle.sol";
import {console2 as console} from "forge-std/console2.sol";

/**
 * @title VCOPCollateralHook
 * @notice Uniswap v4 hook that monitors VCOP price and provides stability through market operations
 */
contract VCOPCollateralHook is BaseHook, Ownable {
    using PoolIdLibrary for PoolKey;
    using SafeERC20 for IERC20;
    
    // ===== STRUCTS TO AVOID STACK TOO DEEP =====
    
    struct PSMSwapParams {
        uint256 inputAmount;
        uint256 outputAmount; 
        uint256 fee;
        address tokenAddress;
    }
    
    struct StabilizationParams {
        uint256 currentRate;
        uint256 deviationPercent;
        uint256 stabilizationAmount;
        bool isVcopSell;
    }
    
    // VCOP collateral manager
    address public collateralManagerAddress;
    
    // Oracle for price data
    VCOPOracle public immutable oracle;
    
    // Currency ID of VCOP token
    Currency public vcopCurrency;
    
    // Currency ID of stablecoin reference (USDC)
    Currency public stablecoinCurrency;
    
    // Stability parameters
    uint256 public pegUpperBound = 1010000; // 1.01 * 1e6
    uint256 public pegLowerBound = 990000;  // 0.99 * 1e6
    
    // PSM (Peg Stability Module) settings
    uint256 public psmFee = 1000; // 0.1% (1e6 basis)
    uint256 public psmMaxSwapAmount = 10000 * 1e6; // 10,000 VCOP
    bool public psmPaused = false;
    
    // Treasury address for fees
    address public treasury;
    
    // Large swap threshold (in VCOP value)
    uint256 public largeSwapThreshold = 5000 * 1e6; // 5,000 VCOP
    
    // Events
    event PriceMonitored(uint256 vcopToCopRate, bool isWithinBounds);
    event StabilityParametersUpdated(uint256 upperBound, uint256 lowerBound);
    event PSMParametersUpdated(uint256 fee, uint256 maxAmount);
    event PSMSwap(address account, bool isVcopToCollateral, uint256 amountIn, uint256 amountOut);
    event PSMPaused(bool paused);
    event PSMStabilizationExecuted(bool isBuy, uint256 amount, uint256 price);
    event CollateralManagerUpdated(address newManager);
    
    constructor(
        IPoolManager _poolManager,
        address _collateralManager,
        address _oracle,
        Currency _vcopCurrency,
        Currency _stablecoinCurrency,
        address _treasury,
        address _owner
    ) BaseHook(_poolManager) Ownable(_owner) {
        collateralManagerAddress = _collateralManager;
        oracle = VCOPOracle(_oracle);
        vcopCurrency = _vcopCurrency;
        stablecoinCurrency = _stablecoinCurrency;
        treasury = _treasury;
        
        console.log("VCOPCollateralHook initialized with owner:", _owner);
    }
    
    /**
     * @dev Returns the current collateral manager
     */
    function collateralManager() public view returns (VCOPCollateralManager) {
        require(collateralManagerAddress != address(0), "Collateral Manager not set");
        return VCOPCollateralManager(collateralManagerAddress);
    }
    
    /**
     * @dev Sets the collateral manager address
     */
    function setCollateralManager(address _manager) external onlyOwner {
        require(_manager != address(0), "Zero address not allowed");
        collateralManagerAddress = _manager;
        emit CollateralManagerUpdated(_manager);
    }
    
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }
    
    /**
     * @dev Sets the pause state of the PSM
     */
    function pausePSM(bool paused) external {
        require(msg.sender == collateralManager().owner(), "Not authorized");
        psmPaused = paused;
        emit PSMPaused(paused);
    }
    
    /**
     * @dev Updates peg stability parameters
     */
    function updateStabilityParameters(uint256 _upperBound, uint256 _lowerBound) external {
        require(msg.sender == collateralManager().owner(), "Not authorized");
        require(_upperBound > _lowerBound, "Invalid bounds");
        
        pegUpperBound = _upperBound;
        pegLowerBound = _lowerBound;
        
        emit StabilityParametersUpdated(_upperBound, _lowerBound);
    }
    
    /**
     * @dev Updates PSM parameters
     */
    function updatePSMParameters(uint256 _fee, uint256 _maxAmount) external {
        require(msg.sender == collateralManager().owner(), "Not authorized");
        
        psmFee = _fee;
        psmMaxSwapAmount = _maxAmount;
        
        emit PSMParametersUpdated(_fee, _maxAmount);
    }
    
    /**
     * @dev Updates large swap threshold
     */
    function updateLargeSwapThreshold(uint256 _threshold) external {
        require(msg.sender == collateralManager().owner(), "Not authorized");
        largeSwapThreshold = _threshold;
    }
    
    /**
     * @dev Monitors price and triggers stability mechanism if needed
     */
    function monitorPrice() public returns (bool) {
        // Get VCOP/COP rate from oracle
        uint256 vcopToCopRate;
        try oracle.getVcopToCopRate() returns (uint256 rate) {
            vcopToCopRate = rate;
        } catch {
            console.log("Failed to get VCOP/COP rate from oracle");
            return false;
        }
        
        // Check if price is within bounds
        bool withinBounds = (vcopToCopRate >= pegLowerBound && vcopToCopRate <= pegUpperBound);
        
        emit PriceMonitored(vcopToCopRate, withinBounds);
        
        return withinBounds;
    }
    
    /**
     * @dev Determines if pool includes VCOP token
     */
    function _isVCOPPool(PoolKey calldata key) internal view returns (bool) {
        return key.currency0 == vcopCurrency || key.currency1 == vcopCurrency;
    }
    
    /**
     * @dev Check if a swap would be considered large
     */
    function _isLargeSwap(SwapParams calldata params) internal view returns (bool) {
        // Simplified - we should convert to a common unit (VCOP value) for better comparison
        if (params.amountSpecified < 0) {
            return uint256(-params.amountSpecified) > largeSwapThreshold;
        } else {
            return uint256(params.amountSpecified) > largeSwapThreshold;
        }
    }
    
    /**
     * @dev Estimate if a swap would break the peg
     */
    function _wouldBreakPeg(PoolKey calldata key, SwapParams calldata params) internal view returns (bool) {
        // This is a simplified check that would need to be enhanced with actual price impact calculation
        // Typically would use price simulation or historical data
        bool isVcopSelling = (key.currency0 == vcopCurrency && params.zeroForOne) || 
                            (key.currency1 == vcopCurrency && !params.zeroForOne);
                            
        // If selling large amount of VCOP, peg could break downward
        // If buying large amount of VCOP, peg could break upward
        return _isLargeSwap(params);
    }
    
    /**
     * @dev Before swap hook to check for PSM interactions
     */
    function _beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        // Only process VCOP pools
        if (_isVCOPPool(key)) {
            // Detect if this swap might destabilize the price
            if (_isLargeSwap(params) && _wouldBreakPeg(key, params)) {
                console.log("Large swap detected that might break peg");
                
                // Try to stabilize preemptively
                stabilizePriceWithPSM();
            }
        }
        
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
    
    /**
     * @dev After swap hook to monitor price and take action if needed
     */
    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        if (_isVCOPPool(key)) {
            console.log("VCOP pool swap detected");
            
            // Monitor price after swap
            bool isStable = monitorPrice();
            console.log("Price within stability bounds:", isStable);
            
            // If price outside bounds, try to stabilize
            if (!isStable && !psmPaused) {
                stabilizePriceWithPSM();
            }
        }
        
        return (BaseHook.afterSwap.selector, 0);
    }
    
    /**
     * @dev After add liquidity hook to monitor price
     */
    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata,
        BalanceDelta delta,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        if (_isVCOPPool(key)) {
            // Monitor price after liquidity changes
            // Wrap in try-catch to handle errors during initial pool creation
            try this.monitorPrice() {
                // Price monitored successfully
            } catch {
                // Silently ignore errors during initial liquidity provision
                console.log("Price monitoring failed - likely during pool initialization");
            }
        }
        
        return (BaseHook.afterAddLiquidity.selector, delta);
    }
    
    /**
     * @dev Allows PSM to swap VCOP for collateral at near-peg rate
     * User gives VCOP, receives collateral
     */
    function psmSwapVCOPForCollateral(uint256 vcopAmount) external {
        require(!psmPaused, "PSM is paused");
        require(vcopAmount <= psmMaxSwapAmount, "Amount exceeds PSM limit");
        
        PSMSwapParams memory params;
        params.inputAmount = vcopAmount;
        params.tokenAddress = Currency.unwrap(stablecoinCurrency);
        
        // Calculate amounts using helper
        (params.outputAmount, params.fee) = _calculatePSMAmounts(vcopAmount, true);
        
        // Execute the swap
        _executePSMVCOPToCollateral(params);
        
        emit PSMSwap(msg.sender, true, vcopAmount, params.outputAmount);
    }
    
    /**
     * @dev Helper function to execute VCOP to collateral swap
     */
    function _executePSMVCOPToCollateral(PSMSwapParams memory params) internal {
        // Verify reserves
        require(
            collateralManager().hasPSMReservesFor(params.tokenAddress, params.outputAmount), 
            "Insufficient PSM reserves"
        );
        
        // Handle VCOP transfer and burn
        VCOPCollateralized vcop = VCOPCollateralized(Currency.unwrap(vcopCurrency));
        require(vcop.transferFrom(msg.sender, address(this), params.inputAmount), "VCOP transfer failed");
        vcop.burn(address(this), params.inputAmount);
        
        // Transfer collateral and fee
        collateralManager().transferPSMCollateral(msg.sender, params.tokenAddress, params.outputAmount);
        if (params.fee > 0) {
            collateralManager().transferPSMCollateral(treasury, params.tokenAddress, params.fee);
        }
    }
    
    /**
     * @dev Allows PSM to swap collateral for VCOP at near-peg rate
     * User gives collateral, receives VCOP
     */
    function psmSwapCollateralForVCOP(uint256 collateralAmount) external {
        require(!psmPaused, "PSM is paused");
        require(collateralAmount > 0, "Invalid amount");
        
        PSMSwapParams memory params;
        params.inputAmount = collateralAmount;
        params.tokenAddress = Currency.unwrap(stablecoinCurrency);
        
        // Calculate amounts using helper
        (params.outputAmount, params.fee) = _calculatePSMAmounts(collateralAmount, false);
        require(params.outputAmount <= psmMaxSwapAmount, "Amount exceeds PSM limit");
        
        // Execute the swap
        _executePSMCollateralToVCOP(params);
        
        emit PSMSwap(msg.sender, false, collateralAmount, params.outputAmount);
    }
    
    /**
     * @dev Helper function to execute collateral to VCOP swap
     */
    function _executePSMCollateralToVCOP(PSMSwapParams memory params) internal {
        IERC20 collateralToken = IERC20(params.tokenAddress);
        
        // Transfer collateral from user to collateral manager
        collateralToken.safeTransferFrom(msg.sender, address(collateralManager()), params.inputAmount);
        
        // Update PSM reserves and mint VCOP
        collateralManager().registerPSMFunds(params.tokenAddress, params.inputAmount);
        collateralManager().mintPSMVcop(msg.sender, params.tokenAddress, params.outputAmount);
        
        // Mint fee to treasury if any
        if (params.fee > 0) {
            collateralManager().mintPSMVcop(treasury, params.tokenAddress, params.fee);
        }
    }
    
    /**
     * @dev Helper function to calculate PSM amounts and fees
     */
    function _calculatePSMAmounts(uint256 inputAmount, bool isVcopInput) internal returns (uint256 outputAmount, uint256 fee) {
        if (isVcopInput) {
            outputAmount = calculateCollateralForVCOP(inputAmount);
        } else {
            outputAmount = calculateVCOPForCollateral(inputAmount);
        }
        
        fee = (outputAmount * psmFee) / 1000000;
        outputAmount = outputAmount - fee;
    }
    
    /**
     * @dev Stabilizes VCOP price using PSM operations
     * If price is too low (below pegLowerBound), buy VCOP with collateral
     * If price is too high (above pegUpperBound), sell VCOP for collateral
     */
    function stabilizePriceWithPSM() public {
        require(!psmPaused, "PSM is paused");
        
        StabilizationParams memory params;
        
        // Get price from oracle
        try oracle.getVcopToCopRate() returns (uint256 rate) {
            params.currentRate = rate;
        } catch {
            console.log("Failed to get price from oracle");
            return;
        }
        
        console.log("Current VCOP/COP rate:", params.currentRate);
        console.log("Lower bound:", pegLowerBound);
        console.log("Upper bound:", pegUpperBound);
        
        if (params.currentRate < pegLowerBound) {
            // Price too low - buy VCOP with collateral
            params.deviationPercent = ((pegLowerBound - params.currentRate) * 1000000) / pegLowerBound;
            params.stabilizationAmount = (psmMaxSwapAmount * params.deviationPercent) / 1000000;
            params.isVcopSell = false;
            
            _executeStabilization(params);
        } else if (params.currentRate > pegUpperBound) {
            // Price too high - sell VCOP for collateral
            params.deviationPercent = ((params.currentRate - pegUpperBound) * 1000000) / pegUpperBound;
            params.stabilizationAmount = (psmMaxSwapAmount * params.deviationPercent) / 1000000;
            params.isVcopSell = true;
            
            _executeStabilization(params);
        } else {
            console.log("Price within bounds, no stabilization needed");
        }
    }
    
    /**
     * @dev Helper function to execute stabilization
     */
    function _executeStabilization(StabilizationParams memory params) internal {
        // Limit to available resources
        params.stabilizationAmount = _constrainToAvailableReserves(params.stabilizationAmount, params.isVcopSell);
        
        if (params.stabilizationAmount > 0) {
            if (params.isVcopSell) {
                console.log("Executing PSM sell of", params.stabilizationAmount, "VCOP");
                _executePSMSell(params.stabilizationAmount);
            } else {
                console.log("Executing PSM buy of", params.stabilizationAmount, "VCOP");
                _executePSMBuy(params.stabilizationAmount);
            }
        }
    }
    
    /**
     * @dev Constrains the stabilization amount to what's available in reserves
     * @param amount Amount to constrain
     * @param isVcopSell If true, we're selling VCOP for collateral. If false, buying VCOP with collateral.
     */
    function _constrainToAvailableReserves(uint256 amount, bool isVcopSell) internal view returns (uint256) {
        address tokenAddress = Currency.unwrap(stablecoinCurrency);
        (uint256 collateralAmount, uint256 vcopAmount, bool active) = collateralManager().getPSMReserves(tokenAddress);
        
        if (!active) {
            return 0;
        }
        
        if (isVcopSell) {
            // Selling VCOP - check if there's enough collateral to support the sell
            uint256 collateralNeeded = calculateCollateralForVCOPView(amount);
            if (collateralNeeded > collateralAmount) {
                // Scale down to match available collateral
                return (amount * collateralAmount) / collateralNeeded;
            }
            return amount;
        } else {
            // Buying VCOP with collateral - check VCOP reserves
            return amount; // For buying, we mint VCOP directly
        }
    }
    
    /**
     * @dev Executes PSM buy operation - buys VCOP from market with collateral
     * @param amount Amount of VCOP to buy
     */
    function _executePSMBuy(uint256 amount) internal {
        // In a real implementation, this would interact with market maker contracts
        // or directly with the Uniswap pool to buy VCOP
        
        // For this implementation we'll just emit an event
        emit PSMStabilizationExecuted(true, amount, oracle.getVcopToCopRateView());
    }
    
    /**
     * @dev Executes PSM sell operation - sells VCOP to market for collateral
     * @param amount Amount of VCOP to sell
     */
    function _executePSMSell(uint256 amount) internal {
        // In a real implementation, this would interact with market maker contracts
        // or directly with the Uniswap pool to sell VCOP
        
        // For this implementation we'll just emit an event
        emit PSMStabilizationExecuted(false, amount, oracle.getVcopToCopRateView());
    }
    
    /**
     * @dev Returns stats about the PSM
     */
    function getPSMStats() external view returns (
        uint256 vcopReserve,
        uint256 collateralReserve,
        uint256 lastOperationTimestamp,
        uint256 totalSwapsCount
    ) {
        address collateralTokenAddress = Currency.unwrap(stablecoinCurrency);
        (collateralReserve, vcopReserve, ) = collateralManager().getPSMReserves(collateralTokenAddress);
        lastOperationTimestamp = collateralManager().lastPSMOperationTimestamp();
        totalSwapsCount = collateralManager().totalPSMSwapsCount();
    }
    
    /**
     * @dev Calculates collateral amount for VCOP (using view functions)
     */
    function calculateCollateralForVCOPView(uint256 vcopAmount) public view returns (uint256) {
        uint256 vcopToCopRate = oracle.getVcopToCopRateView();
        uint256 usdToCopRate = oracle.getUsdToCopRateView();
        
        return (vcopAmount * vcopToCopRate) / usdToCopRate;
    }
    
    /**
     * @dev Calculates VCOP amount for collateral (using view functions)
     */
    function calculateVCOPForCollateralView(uint256 collateralAmount) public view returns (uint256) {
        uint256 usdToCopRate = oracle.getUsdToCopRateView();
        uint256 vcopToCopRate = oracle.getVcopToCopRateView();
        
        return (collateralAmount * usdToCopRate) / vcopToCopRate;
    }
    
    /**
     * @dev Calculates collateral amount for VCOP
     */
    function calculateCollateralForVCOP(uint256 vcopAmount) public returns (uint256) {
        // This would need to be implemented based on your collateral pricing model
        // For example, for USDC collateral:
        uint256 vcopToCopRate = oracle.getVcopToCopRate();
        uint256 usdToCopRate = oracle.getUsdToCopRate();
        
        return (vcopAmount * vcopToCopRate) / usdToCopRate;
    }
    
    /**
     * @dev Calculates VCOP amount for collateral
     */
    function calculateVCOPForCollateral(uint256 collateralAmount) public returns (uint256) {
        // For example, for USDC collateral:
        uint256 usdToCopRate = oracle.getUsdToCopRate();
        uint256 vcopToCopRate = oracle.getVcopToCopRate();
        
        return (collateralAmount * usdToCopRate) / vcopToCopRate;
    }
}
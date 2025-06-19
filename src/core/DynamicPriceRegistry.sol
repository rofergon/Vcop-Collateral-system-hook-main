// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "v4-core/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IPriceRegistry} from "../interfaces/IPriceRegistry.sol";
import {IGenericOracle} from "../interfaces/IGenericOracle.sol";

/**
 * @title DynamicPriceRegistry
 * @notice Dynamic price configuration system replacing hardcoded addresses
 * @dev Provides flexible price management with oracle integration and fallbacks
 */
contract DynamicPriceRegistry is IPriceRegistry, Ownable {
    
    // Token price configurations
    mapping(address => TokenPriceConfig) public tokenConfigs;
    address[] public supportedTokens;
    
    // Oracle integration
    IGenericOracle public oracle;
    bool public fallbackEnabled = true;
    
    // Constants
    uint256 public constant USD_DECIMALS = 6;  // All prices in 6 decimal USD
    uint256 public constant ORACLE_TIMEOUT = 3600; // 1 hour oracle timeout
    
    constructor(address _oracle) Ownable(msg.sender) {
        if (_oracle != address(0)) {
            oracle = IGenericOracle(_oracle);
        }
    }
    
    /**
     * @dev Configures price for a token
     */
    function configureTokenPrice(
        address token, 
        uint256 priceInUSD, 
        uint8 decimals
    ) external override onlyOwner {
        require(token != address(0), "Invalid token address");
        require(priceInUSD > 0, "Price must be positive");
        require(decimals <= 18, "Decimals too high");
        
        // Add to supported tokens if new
        if (!tokenConfigs[token].isActive && tokenConfigs[token].token == address(0)) {
            supportedTokens.push(token);
        }
        
        tokenConfigs[token] = TokenPriceConfig({
            token: token,
            priceInUSD: priceInUSD,
            decimals: decimals,
            isActive: true,
            lastUpdated: block.timestamp
        });
        
        emit TokenPriceConfigured(token, priceInUSD, decimals);
    }
    
    /**
     * @dev Updates price for an existing token
     */
    function updateTokenPrice(address token, uint256 newPriceInUSD) external override onlyOwner {
        require(tokenConfigs[token].token != address(0), "Token not configured");
        require(newPriceInUSD > 0, "Price must be positive");
        
        uint256 oldPrice = tokenConfigs[token].priceInUSD;
        tokenConfigs[token].priceInUSD = newPriceInUSD;
        tokenConfigs[token].lastUpdated = block.timestamp;
        
        emit TokenPriceUpdated(token, oldPrice, newPriceInUSD);
    }
    
    /**
     * @dev Sets token active status
     */
    function setTokenStatus(address token, bool isActive) external override onlyOwner {
        require(tokenConfigs[token].token != address(0), "Token not configured");
        
        tokenConfigs[token].isActive = isActive;
        emit TokenStatusChanged(token, isActive);
    }
    
    /**
     * @dev Batch configure multiple tokens
     */
    function batchConfigureTokens(
        address[] calldata tokens,
        uint256[] calldata prices,
        uint8[] calldata decimals
    ) external override onlyOwner {
        require(
            tokens.length == prices.length && prices.length == decimals.length,
            "Array length mismatch"
        );
        
        for (uint256 i = 0; i < tokens.length; i++) {
            _configureTokenPriceInternal(tokens[i], prices[i], decimals[i]);
        }
    }
    
    /**
     * @dev Gets token price with oracle fallback
     */
    function getTokenPrice(address token) external view override returns (uint256 priceInUSD) {
        TokenPriceConfig memory config = tokenConfigs[token];
        
        // Try oracle first if available and enabled
        if (address(oracle) != address(0)) {
            try oracle.getPrice(token, address(0)) returns (uint256 oraclePrice) {
                if (oraclePrice > 0) {
                    // Convert oracle price to our 6-decimal format
                    return _normalizePrice(oraclePrice, 18, uint8(USD_DECIMALS));
                }
            } catch {
                // Oracle failed, continue to fallback
            }
        }
        
        // Use configured price if available and active
        if (config.isActive) {
            return config.priceInUSD;
        }
        
        // If fallback is disabled, revert
        if (!fallbackEnabled) {
            revert("No price available and fallback disabled");
        }
        
        // Last resort: return 0 (calling contract should handle this)
        return 0;
    }
    
    /**
     * @dev Gets complete token configuration
     */
    function getTokenConfig(address token) external view override returns (TokenPriceConfig memory) {
        return tokenConfigs[token];
    }
    
    /**
     * @dev Calculates USD value of token amount
     */
    function calculateAssetValue(address token, uint256 amount) external view override returns (uint256 valueInUSD) {
        TokenPriceConfig memory config = tokenConfigs[token];
        
        if (!config.isActive) {
            return 0;
        }
        
        uint256 price = this.getTokenPrice(token);
        if (price == 0) {
            return 0;
        }
        
        // Calculate value: (amount * price) / (10^token_decimals)
        // Result is in USD with 6 decimals
        return (amount * price) / (10 ** config.decimals);
    }
    
    /**
     * @dev Checks if token is supported
     */
    function isTokenSupported(address token) external view override returns (bool) {
        return tokenConfigs[token].isActive;
    }
    
    /**
     * @dev Gets all supported tokens
     */
    function getSupportedTokens() external view override returns (address[] memory) {
        return supportedTokens;
    }
    
    /**
     * @dev Gets prices for multiple tokens
     */
    function getMultipleTokenPrices(address[] calldata tokens) external view override returns (uint256[] memory prices) {
        prices = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            prices[i] = this.getTokenPrice(tokens[i]);
        }
    }
    
    /**
     * @dev Sets oracle address
     */
    function setOracle(address newOracle) external override onlyOwner {
        oracle = IGenericOracle(newOracle);
    }
    
    /**
     * @dev Sets fallback enabled status
     */
    function setFallbackEnabled(bool enabled) external override onlyOwner {
        fallbackEnabled = enabled;
    }
    
    /**
     * @dev Initializes common tokens from deployed-addresses.json
     */
    function initializeFromDeployment(
        address ethToken,
        address usdcToken,
        address wbtcToken
    ) external onlyOwner {
        // Configure ETH - $2500 with 18 decimals
        _configureTokenPriceInternal(ethToken, 2500000000, 18);  // $2500 in 6-decimal format
        
        // Configure USDC - $1 with 6 decimals  
        _configureTokenPriceInternal(usdcToken, 1000000, 6);     // $1 in 6-decimal format
        
        // Configure WBTC - $70000 with 8 decimals
        _configureTokenPriceInternal(wbtcToken, 70000000000, 8); // $70000 in 6-decimal format
    }
    
    /**
     * @dev Internal function to configure token price
     */
    function _configureTokenPriceInternal(
        address token, 
        uint256 priceInUSD, 
        uint8 decimals
    ) internal {
        require(token != address(0), "Invalid token address");
        require(priceInUSD > 0, "Price must be positive");
        require(decimals <= 18, "Decimals too high");
        
        // Add to supported tokens if new
        if (!tokenConfigs[token].isActive && tokenConfigs[token].token == address(0)) {
            supportedTokens.push(token);
        }
        
        tokenConfigs[token] = TokenPriceConfig({
            token: token,
            priceInUSD: priceInUSD,
            decimals: decimals,
            isActive: true,
            lastUpdated: block.timestamp
        });
        
        emit TokenPriceConfigured(token, priceInUSD, decimals);
    }
    
    /**
     * @dev Emergency function to update all prices from current deployment
     */
    function syncWithCurrentDeployment() external onlyOwner {
        // This function can be called after redeployment to update token addresses
        // Implementation would read from deployed-addresses.json equivalent
        emit FallbackPriceUsed(address(0), 0); // Placeholder event
    }
    
    /**
     * @dev Internal function to normalize price between different decimal formats
     */
    function _normalizePrice(
        uint256 price, 
        uint8 fromDecimals, 
        uint8 toDecimals
    ) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) {
            return price;
        } else if (fromDecimals > toDecimals) {
            return price / (10 ** (fromDecimals - toDecimals));
        } else {
            return price * (10 ** (toDecimals - fromDecimals));
        }
    }
    
    /**
     * @dev Gets registry statistics
     */
    function getRegistryStats() external view returns (
        uint256 totalTokens,
        uint256 activeTokens,
        bool oracleConnected,
        bool fallbackStatus
    ) {
        totalTokens = supportedTokens.length;
        
        // Count active tokens
        activeTokens = 0;
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            if (tokenConfigs[supportedTokens[i]].isActive) {
                activeTokens++;
            }
        }
        
        oracleConnected = address(oracle) != address(0);
        fallbackStatus = fallbackEnabled;
    }
} 
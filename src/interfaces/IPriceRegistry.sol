// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IPriceRegistry
 * @notice Interface for dynamic price configuration system
 * @dev Replaces hardcoded addresses with configurable price mappings
 */
interface IPriceRegistry {
    
    struct TokenPriceConfig {
        address token;
        uint256 priceInUSD;      // Price in USD with 6 decimals (e.g., 2500000000 = $2500)
        uint8 decimals;          // Token decimals (18 for ETH, 6 for USDC, 8 for WBTC)
        bool isActive;           // Whether this price config is active
        uint256 lastUpdated;     // Timestamp of last price update
    }
    
    // Events
    event TokenPriceConfigured(address indexed token, uint256 priceInUSD, uint8 decimals);
    event TokenPriceUpdated(address indexed token, uint256 oldPrice, uint256 newPrice);
    event TokenStatusChanged(address indexed token, bool isActive);
    event FallbackPriceUsed(address indexed token, uint256 fallbackPrice);
    
    // Configuration functions
    function configureTokenPrice(
        address token, 
        uint256 priceInUSD, 
        uint8 decimals
    ) external;
    
    function updateTokenPrice(address token, uint256 newPriceInUSD) external;
    function setTokenStatus(address token, bool isActive) external;
    function batchConfigureTokens(
        address[] calldata tokens,
        uint256[] calldata prices,
        uint8[] calldata decimals
    ) external;
    
    // Price retrieval functions
    function getTokenPrice(address token) external view returns (uint256 priceInUSD);
    function getTokenConfig(address token) external view returns (TokenPriceConfig memory);
    function calculateAssetValue(address token, uint256 amount) external view returns (uint256 valueInUSD);
    function isTokenSupported(address token) external view returns (bool);
    
    // Batch functions
    function getSupportedTokens() external view returns (address[] memory);
    function getMultipleTokenPrices(address[] calldata tokens) external view returns (uint256[] memory prices);
    
    // Admin functions
    function setOracle(address newOracle) external;
    function setFallbackEnabled(bool enabled) external;
} 
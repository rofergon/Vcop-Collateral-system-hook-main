// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IGenericOracle
 * @notice Interface for a flexible oracle system supporting multiple price feeds
 */
interface IGenericOracle {
    enum PriceFeedType {
        CHAINLINK,
        UNISWAP_V4,
        MANUAL,
        HYBRID
    }
    
    struct PriceFeedConfig {
        address feedAddress;        // Address of the price feed contract
        PriceFeedType feedType;
        uint8 decimals;            // Decimals of the price feed
        uint256 heartbeat;         // Maximum time between updates (seconds)
        bool isActive;
        bool isInverse;            // If true, price = 1/rawPrice
    }
    
    struct PriceData {
        uint256 price;             // Price with 6 decimals
        uint256 timestamp;
        bool isValid;
    }
    
    /**
     * @dev Gets price for a token pair
     * @param baseToken Address of base token
     * @param quoteToken Address of quote token
     * @return price Price of baseToken in terms of quoteToken (6 decimals)
     */
    function getPrice(address baseToken, address quoteToken) external view returns (uint256 price);
    
    /**
     * @dev Gets detailed price data for a token pair
     * @param baseToken Address of base token
     * @param quoteToken Address of quote token
     * @return priceData Detailed price information
     */
    function getPriceData(address baseToken, address quoteToken) external view returns (PriceData memory priceData);
    
    /**
     * @dev Updates price for a token pair (for manual feeds)
     * @param baseToken Address of base token
     * @param quoteToken Address of quote token
     * @param price New price (6 decimals)
     */
    function updatePrice(address baseToken, address quoteToken, uint256 price) external;
    
    /**
     * @dev Configures a price feed for a token pair
     * @param baseToken Address of base token
     * @param quoteToken Address of quote token
     * @param config Price feed configuration
     */
    function configurePriceFeed(
        address baseToken, 
        address quoteToken, 
        PriceFeedConfig calldata config
    ) external;
    
    /**
     * @dev Sets primary and fallback feeds for a token pair
     * @param baseToken Address of base token
     * @param quoteToken Address of quote token
     * @param primaryType Primary feed type
     * @param fallbackType Fallback feed type
     */
    function setFeedPriority(
        address baseToken,
        address quoteToken,
        PriceFeedType primaryType,
        PriceFeedType fallbackType
    ) external;
    
    /**
     * @dev Checks if price feed exists for a token pair
     * @param baseToken Address of base token
     * @param quoteToken Address of quote token
     * @return exists True if price feed exists
     */
    function hasPriceFeed(address baseToken, address quoteToken) external view returns (bool exists);
    
    /**
     * @dev Gets price feed configuration
     * @param baseToken Address of base token
     * @param quoteToken Address of quote token
     * @param feedType Type of price feed
     * @return config Price feed configuration
     */
    function getPriceFeedConfig(
        address baseToken,
        address quoteToken,
        PriceFeedType feedType
    ) external view returns (PriceFeedConfig memory config);
    
    /**
     * @dev Validates if price is within acceptable bounds
     * @param baseToken Address of base token
     * @param quoteToken Address of quote token
     * @param price Price to validate
     * @return isValid True if price is valid
     */
    function validatePrice(address baseToken, address quoteToken, uint256 price) external view returns (bool isValid);
    
    // Events
    event PriceFeedConfigured(
        address indexed baseToken,
        address indexed quoteToken,
        PriceFeedType feedType,
        address feedAddress
    );
    event PriceUpdated(
        address indexed baseToken,
        address indexed quoteToken,
        uint256 price,
        PriceFeedType feedType
    );
    event FeedPrioritySet(
        address indexed baseToken,
        address indexed quoteToken,
        PriceFeedType primaryType,
        PriceFeedType fallbackType
    );
} 
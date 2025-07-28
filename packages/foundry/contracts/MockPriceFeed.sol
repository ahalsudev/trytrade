// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockPriceFeed
 * @dev Mock price feed for testing and development
 * @notice Provides historical and current price data for supported assets
 */
contract MockPriceFeed is Ownable {

    struct PriceFeed {
        uint256[] prices;           // Array of historical prices
        uint256 startTimestamp;     // When the price feed starts
        uint256 intervalSeconds;    // Time interval between price points
        uint8 feedDecimals;         // Changed from 'decimals' to 'feedDecimals'
        string feedDescription;     // Changed from 'description' to 'feedDescription'
        bool isActive;              // Whether the feed is active
    }

    // Mapping from asset symbol to price feed data
    mapping(string => PriceFeed) public priceFeeds;

    // Array to track supported assets
    string[] public supportedAssets;

    // Mapping to check if asset is supported
    mapping(string => bool) public assetExists;

    // Events
    event PriceFeedCreated(
        string indexed asset,
        uint256[] prices,
        uint256 startTimestamp,
        uint256 intervalSeconds
    );

    event PriceFeedUpdated(
        string indexed asset,
        uint256[] newPrices
    );

    event PriceRequested(
        string indexed asset,
        uint256 timestamp,
        uint256 price,
        uint256 roundId
    );

    // Modifiers
    modifier assetSupported(string memory _asset) {
        require(assetExists[_asset], "Asset not supported");
        require(priceFeeds[_asset].isActive, "Price feed is not active");
        _;
    }

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Create a new price feed for an asset
     * @param _asset Asset symbol (e.g., "ETH", "BTC")
     * @param _prices Array of historical prices
     * @param _startTimestamp Starting timestamp for the price feed
     * @param _intervalSeconds Time interval between each price point
     * @param _decimals Number of decimals for price precision
     * @param _description Description of the price feed
     */
    function createPriceFeed(
        string memory _asset,
        uint256[] memory _prices,
        uint256 _startTimestamp,
        uint256 _intervalSeconds,
        uint8 _decimals,
        string memory _description
    ) external onlyOwner {
        require(_prices.length > 0, "Prices array cannot be empty");
        require(_intervalSeconds > 0, "Interval must be greater than 0");
        require(!assetExists[_asset], "Asset already exists");

        priceFeeds[_asset] = PriceFeed({
            prices: _prices,
            startTimestamp: _startTimestamp,
            intervalSeconds: _intervalSeconds,
            feedDecimals: _decimals,
            feedDescription: _description,
            isActive: true
        });

        supportedAssets.push(_asset);
        assetExists[_asset] = true;

        emit PriceFeedCreated(_asset, _prices, _startTimestamp, _intervalSeconds);
    }

    /**
     * @dev Update existing price feed with new prices
     * @param _asset Asset symbol
     * @param _newPrices New array of prices
     */
    function updatePriceFeed(
        string memory _asset,
        uint256[] memory _newPrices
    ) external onlyOwner assetSupported(_asset) {
        require(_newPrices.length > 0, "Prices array cannot be empty");

        priceFeeds[_asset].prices = _newPrices;

        emit PriceFeedUpdated(_asset, _newPrices);
    }

    /**
     * @dev Get price at a specific timestamp
     * @param _asset Asset symbol
     * @param _timestamp Target timestamp
     * @return price Price at the given timestamp
     * @return timestamp Actual timestamp of the price data point
     */
    function getPriceAtTimestamp(
        string memory _asset,
        uint256 _timestamp
    ) external view assetSupported(_asset) returns (uint256 price, uint256 timestamp) {
        PriceFeed storage feed = priceFeeds[_asset];

        if (_timestamp <= feed.startTimestamp) {
            // Return first price if timestamp is before or at start
            return (feed.prices[0], feed.startTimestamp);
        }

        // Calculate index based on timestamp
        uint256 elapsed = _timestamp - feed.startTimestamp;
        uint256 index = elapsed / feed.intervalSeconds;

        if (index >= feed.prices.length) {
            // Return last price if beyond available data
            index = feed.prices.length - 1;
        }

        uint256 priceTimestamp = feed.startTimestamp + (index * feed.intervalSeconds);

        // Removed the event emission since this is a view function
        return (feed.prices[index], priceTimestamp);
    }

    /**
     * @dev Get the latest price (current time)
     * @param _asset Asset symbol
     * @return price Latest price
     * @return timestamp Timestamp of the latest price
     * @return roundId Round ID for Chainlink compatibility
     */
    function getLatestPrice(
        string memory _asset
    ) external view assetSupported(_asset) returns (uint256 price, uint256 timestamp, uint256 roundId) {
        return _getPriceAtTimestamp(_asset, block.timestamp);
    }

    /**
     * @dev Get price at a specific round
     * @param _asset Asset symbol
     * @param _roundId Round ID (1-indexed)
     * @return price Price at the given round
     * @return timestamp Timestamp of the price
     */
    function getPriceAtRound(
        string memory _asset,
        uint256 _roundId
    ) external view assetSupported(_asset) returns (uint256 price, uint256 timestamp) {
        require(_roundId > 0, "Round ID must be greater than 0");

        PriceFeed storage feed = priceFeeds[_asset];
        require(_roundId <= feed.prices.length, "Round ID exceeds available data");

        uint256 index = _roundId - 1; // Convert to 0-indexed
        timestamp = feed.startTimestamp + (index * feed.intervalSeconds);
        price = feed.prices[index];

        return (price, timestamp);
    }

    /**
     * @dev Internal function to get price at timestamp with round ID
     */
    function _getPriceAtTimestamp(
        string memory _asset,
        uint256 _timestamp
    ) internal view returns (uint256 price, uint256 timestamp, uint256 roundId) {
        PriceFeed storage feed = priceFeeds[_asset];

        if (_timestamp <= feed.startTimestamp) {
            return (feed.prices[0], feed.startTimestamp, 1);
        }

        uint256 elapsed = _timestamp - feed.startTimestamp;
        uint256 index = elapsed / feed.intervalSeconds;

        if (index >= feed.prices.length) {
            index = feed.prices.length - 1;
        }

        timestamp = feed.startTimestamp + (index * feed.intervalSeconds);
        price = feed.prices[index];
        roundId = index + 1; // 1-indexed

        return (price, timestamp, roundId);
    }

    /**
     * @dev Request price with event emission (non-view function)
     * @param _asset Asset symbol
     * @param _timestamp Target timestamp
     * @return price Price at the given timestamp
     * @return timestamp Actual timestamp of the price data point
     */
    function requestPriceAtTimestamp(
        string memory _asset,
        uint256 _timestamp
    ) external assetSupported(_asset) returns (uint256 price, uint256 timestamp) {
        PriceFeed storage feed = priceFeeds[_asset];

        if (_timestamp <= feed.startTimestamp) {
            emit PriceRequested(_asset, feed.startTimestamp, feed.prices[0], 1);
            return (feed.prices[0], feed.startTimestamp);
        }

        uint256 elapsed = _timestamp - feed.startTimestamp;
        uint256 index = elapsed / feed.intervalSeconds;

        if (index >= feed.prices.length) {
            index = feed.prices.length - 1;
        }

        uint256 priceTimestamp = feed.startTimestamp + (index * feed.intervalSeconds);

        emit PriceRequested(_asset, priceTimestamp, feed.prices[index], index + 1);
        return (feed.prices[index], priceTimestamp);
    }

    /**
     * @dev Get feed information
     * @param _asset Asset symbol
     * @return feedDecimals Number of decimals
     * @return feedDescription Feed description
     * @return totalRounds Total number of price rounds
     * @return startTimestamp Feed start timestamp
     * @return intervalSeconds Interval between prices
     * @return isActive Whether feed is active
     */
    function getFeedInfo(
        string memory _asset
    ) external view assetSupported(_asset) returns (
        uint8 feedDecimals,
        string memory feedDescription,
        uint256 totalRounds,
        uint256 startTimestamp,
        uint256 intervalSeconds,
        bool isActive
    ) {
        PriceFeed storage feed = priceFeeds[_asset];
        return (
            feed.feedDecimals,
            feed.feedDescription,
            feed.prices.length,
            feed.startTimestamp,
            feed.intervalSeconds,
            feed.isActive
        );
    }

    /**
     * @dev Get all prices for an asset
     * @param _asset Asset symbol
     * @return Array of all prices
     */
    function getAllPrices(string memory _asset) external view assetSupported(_asset) returns (uint256[] memory) {
        return priceFeeds[_asset].prices;
    }

    /**
     * @dev Get supported assets list
     * @return Array of supported asset symbols
     */
    function getSupportedAssets() external view returns (string[] memory) {
        return supportedAssets;
    }

    /**
     * @dev Toggle price feed active status
     * @param _asset Asset symbol
     */
    function togglePriceFeed(string memory _asset) external onlyOwner {
        require(assetExists[_asset], "Asset does not exist");
        priceFeeds[_asset].isActive = !priceFeeds[_asset].isActive;
    }

    // Chainlink AggregatorV3Interface compatibility functions

    /**
     * @dev Get decimals for Chainlink compatibility
     * @param _asset Asset symbol
     * @return Number of decimals
     */
    function decimals(string memory _asset) external view assetSupported(_asset) returns (uint8) {
        return priceFeeds[_asset].feedDecimals;
    }

    /**
     * @dev Get description for Chainlink compatibility
     * @param _asset Asset symbol
     * @return Feed description
     */
    function description(string memory _asset) external view assetSupported(_asset) returns (string memory) {
        return priceFeeds[_asset].feedDescription;
    }

    /**
     * @dev Get latest round data for Chainlink compatibility
     * @param _asset Asset symbol
     * @return roundId Round ID
     * @return answer Price
     * @return startedAt Started timestamp
     * @return updatedAt Updated timestamp
     * @return answeredInRound Answered in round
     */
    function latestRoundData(
        string memory _asset
    ) external view assetSupported(_asset) returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        (uint256 price, uint256 timestamp, uint256 round) = _getPriceAtTimestamp(_asset, block.timestamp);

        return (
            uint80(round),
            int256(price),
            timestamp,
            timestamp,
            uint80(round)
        );
    }
}
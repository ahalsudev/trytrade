// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MockPriceFeed
 * @dev Mock implementation of Chainlink price feed for testing
 * @notice Simulates price feed with predefined price arrays that iterate over time
 */
contract MockPriceFeed {
    struct PriceFeedData {
        uint256[] prices;
        uint256 startTimestamp;
        uint256 intervalSeconds;
        uint256 currentIndex;
        bool isActive;
        uint8 decimals;
        string description;
    }

    mapping(string => PriceFeedData) public priceFeeds;
    string[] public supportedAssets;
    mapping(string => bool) public assetExists;

    address public owner;

    event PriceFeedCreated(string indexed asset, uint256[] prices, uint256 startTimestamp, uint256 intervalSeconds);
    event PriceFeedUpdated(string indexed asset, uint256[] newPrices);
    event PriceRequested(string indexed asset, uint256 timestamp, uint256 price, uint256 roundId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier assetSupported(string memory _asset) {
        require(assetExists[_asset], "Asset not supported");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Create a new price feed with mock data
     * @param _asset Asset symbol (e.g., "ETH", "BTC")
     * @param _prices Array of mock prices
     * @param _startTimestamp When the price feed starts
     * @param _intervalSeconds Time interval between each price point
     * @param _decimals Number of decimals for the price (usually 8 for Chainlink)
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

        priceFeeds[_asset] = PriceFeedData({
            prices: _prices,
            startTimestamp: _startTimestamp,
            intervalSeconds: _intervalSeconds,
            currentIndex: 0,
            isActive: true,
            decimals: _decimals,
            description: _description
        });

        supportedAssets.push(_asset);
        assetExists[_asset] = true;

        emit PriceFeedCreated(_asset, _prices, _startTimestamp, _intervalSeconds);
    }

    /**
     * @dev Update prices for an existing feed
     */
    function updatePriceFeed(
        string memory _asset,
        uint256[] memory _newPrices
    ) external onlyOwner assetSupported(_asset) {
        require(_newPrices.length > 0, "Prices array cannot be empty");

        priceFeeds[_asset].prices = _newPrices;
        priceFeeds[_asset].currentIndex = 0; // Reset index

        emit PriceFeedUpdated(_asset, _newPrices);
    }

    /**
     * @dev Get the current price index based on timestamp
     */
    function _getCurrentIndex(string memory _asset, uint256 _timestamp) internal view returns (uint256) {
        PriceFeedData storage feed = priceFeeds[_asset];

        if (_timestamp < feed.startTimestamp) {
            return 0;
        }

        uint256 elapsedTime = _timestamp - feed.startTimestamp;
        uint256 index = elapsedTime / feed.intervalSeconds;

        // If index exceeds array length, return last price
        if (index >= feed.prices.length) {
            return feed.prices.length - 1;
        }

        return index;
    }

    /**
     * @dev Get price at specific timestamp
     * @param _asset Asset symbol
     * @param _timestamp Timestamp to get price for
     * @return price Price at the given timestamp
     * @return timestamp Actual timestamp of the price
     */
    function getPriceAtTimestamp(
        string memory _asset,
        uint256 _timestamp
    ) external view assetSupported(_asset) returns (uint256 price, uint256 timestamp) {
        PriceFeedData storage feed = priceFeeds[_asset];
        require(feed.isActive, "Price feed is not active");

        uint256 index = _getCurrentIndex(_asset, _timestamp);
        price = feed.prices[index];

        // Calculate the actual timestamp for this price point
        timestamp = feed.startTimestamp + (index * feed.intervalSeconds);

        return (price, timestamp);
    }

    /**
     * @dev Get latest price (current timestamp)
     */
    function getLatestPrice(
        string memory _asset
    ) external view assetSupported(_asset) returns (uint256 price, uint256 timestamp, uint256 roundId) {
        uint256 currentTime = block.timestamp;
        (price, timestamp) = this.getPriceAtTimestamp(_asset, currentTime);

        // Calculate round ID based on index
        uint256 index = _getCurrentIndex(_asset, currentTime);
        roundId = index + 1; // Round IDs start from 1

        return (price, timestamp, roundId);
    }

    /**
     * @dev Get price at specific round
     */
    function getPriceAtRound(
        string memory _asset,
        uint256 _roundId
    ) external view assetSupported(_asset) returns (uint256 price, uint256 timestamp) {
        require(_roundId > 0, "Round ID must be greater than 0");

        PriceFeedData storage feed = priceFeeds[_asset];
        require(feed.isActive, "Price feed is not active");

        uint256 index = _roundId - 1; // Convert to 0-based index
        require(index < feed.prices.length, "Round ID exceeds available data");

        price = feed.prices[index];
        timestamp = feed.startTimestamp + (index * feed.intervalSeconds);

        return (price, timestamp);
    }

    /**
     * @dev Get feed metadata
     */
    function getFeedInfo(
        string memory _asset
    ) external view assetSupported(_asset) returns (
        uint8 decimals,
        string memory description,
        uint256 totalRounds,
        uint256 startTimestamp,
        uint256 intervalSeconds,
        bool isActive
    ) {
        PriceFeedData storage feed = priceFeeds[_asset];

        return (
            feed.decimals,
            feed.description,
            feed.prices.length,
            feed.startTimestamp,
            feed.intervalSeconds,
            feed.isActive
        );
    }

    /**
     * @dev Get all prices for an asset
     */
    function getAllPrices(
        string memory _asset
    ) external view assetSupported(_asset) returns (uint256[] memory) {
        return priceFeeds[_asset].prices;
    }

    /**
     * @dev Get supported assets
     */
    function getSupportedAssets() external view returns (string[] memory) {
        return supportedAssets;
    }

    /**
     * @dev Toggle price feed active status
     */
    function togglePriceFeed(
        string memory _asset
    ) external onlyOwner assetSupported(_asset) {
        priceFeeds[_asset].isActive = !priceFeeds[_asset].isActive;
    }

    /**
     * @dev Chainlink-like interface functions for compatibility
     */
    function latestRoundData(
        string memory _asset
    ) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        (uint256 price, uint256 timestamp, uint256 round) = this.getLatestPrice(_asset);

        return (
            uint80(round),
            int256(price),
            timestamp,
            timestamp,
            uint80(round)
        );
    }

    /**
     * @dev Get decimals for Chainlink compatibility
     */
    function decimals(string memory _asset) external view assetSupported(_asset) returns (uint8) {
        return priceFeeds[_asset].decimals;
    }

    /**
     * @dev Get description for Chainlink compatibility
     */
    function description(string memory _asset) external view assetSupported(_asset) returns (string memory) {
        return priceFeeds[_asset].description;
    }
}
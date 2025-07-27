// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IFtsoV2
 * @notice Interface for interacting with individual FTSO contracts (relevant for getting specific price details if needed).
 * @dev This might not be directly needed if using FtsoManager's bulk fetch functions, but included for completeness.
 */
interface IFtsoV2 {
    function getCurrentPrice() external view returns (uint256 _price, uint256 _timestamp);
    function getCurrentPriceWithDecimals() external view returns (uint256 _price, uint256 _timestamp, uint256 _decimals);
    function getFeedId() external view returns (uint256);
    // Add other relevant functions based on Flare documentation if needed
}

/**
 * @title IFtsoManagerV2
 * @notice Interface for interacting with the FTSO Manager contract.
 * @dev Provides functions to get current prices for multiple feeds simultaneously.
 */
interface IFtsoManagerV2 {
    /**
     * @notice Returns the current prices and timestamp for a list of feed IDs.
     * @param _feedIds Array of feed IDs to query.
     * @return _prices Array of corresponding prices (uint256). Prices align with the order of _feedIds.
     * @return _timestamp The timestamp associated with the returned prices.
     * @dev Reverts if any feed ID is invalid or has no price available. Prices typically have 5 decimals for USD pairs on Flare, but verify.
     */
    function getCurrentPriceFeeds(uint256[] calldata _feedIds) external view returns (uint256[] memory _prices, uint256 _timestamp);

    /**
     * @notice Returns the current prices, timestamp, and decimals for a list of feed IDs.
     * @param _feedIds Array of feed IDs to query.
     * @return _prices Array of corresponding prices (uint256).
     * @return _timestamp The timestamp associated with the returned prices.
     * @return _decimals Array of decimals for each corresponding price.
     */
    function getCurrentPriceFeedsWithDecimals(uint256[] calldata _feedIds) external view returns (uint256[] memory _prices, uint256 _timestamp, uint8[] memory _decimals);

    // Add other relevant functions based on Flare documentation if needed (e.g., getting FTSO contract addresses by feed ID)
}

/**
 * @title IFtsoRegistryV2
 * @notice Interface for interacting with the FTSO Registry contract.
 * @dev Used to find the active FTSO Manager address.
 */
interface IFtsoRegistryV2 {
    /**
     * @notice Returns the address of the current FtsoManager contract.
     */
    function getFtsoManager() external view returns (address);

    /**
     * @notice Returns the FTSO contract addresses for specific feed IDs.
     * @param _feedIds Array of feed IDs.
     * @return Array of FTSO contract addresses.
     */
    function getFtsos(uint256[] calldata _feedIds) external view returns (IFtsoV2[] memory);

    // Add other relevant functions based on Flare documentation if needed
}

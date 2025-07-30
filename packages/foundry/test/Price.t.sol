// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/Price.sol";
import "forge-std/Test.sol";

contract PriceTest is Test {
    Price public priceFeed;

    address public owner = address(this);
    address public user1 = address(0x1);

    uint256[] public ethPrices;
    uint256[] public btcPrices;

    uint256 public constant July_31_2025 = 1753988262; // July 31, 2025 6:57:42 PM
    uint256 public constant START_TIME = 1690578974; // 2023-07-28 22:16:14 UTC
    uint256 public constant INTERVAL = 3600; // 1 hour
    uint8 public constant DECIMALS = 8;

    event PriceFeedCreated(string indexed asset, uint256[] prices, uint256 startTimestamp, uint256 intervalSeconds);
    event PriceFeedUpdated(string indexed asset, uint256[] newPrices);
    event PriceRequested(string indexed asset, uint256 timestamp, uint256 price, uint256 roundId);

    function setUp() public {
        priceFeed = new Price();

        // Setup ETH prices (10 price points)
        ethPrices.push(200000000000); // $2000.00
        ethPrices.push(205000000000); // $2050.00
        ethPrices.push(210000000000); // $2100.00
        ethPrices.push(208000000000); // $2080.00
        ethPrices.push(215000000000); // $2150.00
        ethPrices.push(220000000000); // $2200.00
        ethPrices.push(218000000000); // $2180.00
        ethPrices.push(225000000000); // $2250.00
        ethPrices.push(230000000000); // $2300.00
        ethPrices.push(235000000000); // $2350.00

        // Setup BTC prices (5 price points)
        btcPrices.push(3000000000000); // $30000.00
        btcPrices.push(3100000000000); // $31000.00
        btcPrices.push(3200000000000); // $32000.00
        btcPrices.push(3150000000000); // $31500.00
        btcPrices.push(3300000000000); // $33000.00
    }

    function testCreatePriceFeed() public {
        vm.expectEmit(true, false, false, true);
        emit PriceFeedCreated("ETH", ethPrices, START_TIME, INTERVAL);

        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );

        // Verify price feed was created
        assertTrue(priceFeed.assetExists("ETH"));

        // Check feed info
        (
            uint8 decimals,
            string memory description,
            uint256 totalRounds,
            uint256 startTimestamp,
            uint256 intervalSeconds,
            bool isActive
        ) = priceFeed.getFeedInfo("ETH");

        assertEq(decimals, DECIMALS);
        assertEq(description, "ETH / USD");
        assertEq(totalRounds, ethPrices.length);
        assertEq(startTimestamp, START_TIME);
        assertEq(intervalSeconds, INTERVAL);
        assertTrue(isActive);

        // Verify supported assets
        string[] memory assets = priceFeed.getSupportedAssets();
        assertEq(assets.length, 1);
        assertEq(assets[0], "ETH");
    }

    function testCreatePriceFeedFailures() public {
        // Test empty prices array
        uint256[] memory emptyPrices = new uint256[](0);
        vm.expectRevert("Prices array cannot be empty");
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, emptyPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );

        // Test zero interval
        vm.expectRevert("Interval must be greater than 0");
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, 0, DECIMALS, "ETH / USD"
        );

        // Create valid price feed first
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );

        // Test duplicate asset
        vm.expectRevert("Asset already exists");
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );
    }

    function testOnlyOwnerCanCreatePriceFeed() public {
        vm.prank(user1);
        // Updated to expect the new OpenZeppelin error format
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );
    }

    function testGetPriceAtTimestamp() public {
        // Create price feed
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );

        // Test price at start time (index 0)
        (uint256 price, uint256 timestamp) = priceFeed.getPriceAtTimestamp("ETH", START_TIME);
        assertEq(price, ethPrices[0]);
        assertEq(timestamp, START_TIME);

        // Test price at start + 1 hour (index 1)
        (price, timestamp) = priceFeed.getPriceAtTimestamp("ETH", START_TIME + INTERVAL);
        assertEq(price, ethPrices[1]);
        assertEq(timestamp, START_TIME + INTERVAL);

        // Test price at start + 2.5 hours (should return index 2)
        (price, timestamp) = priceFeed.getPriceAtTimestamp("ETH", START_TIME + (INTERVAL * 2) + (INTERVAL / 2));
        assertEq(price, ethPrices[2]);
        assertEq(timestamp, START_TIME + (INTERVAL * 2));

        // Test price before start time (should return index 0)
        (price, timestamp) = priceFeed.getPriceAtTimestamp("ETH", START_TIME - 1000);
        assertEq(price, ethPrices[0]);
        assertEq(timestamp, START_TIME);

        // Test price far in future (should return last price)
        (price, timestamp) = priceFeed.getPriceAtTimestamp("ETH", START_TIME + (INTERVAL * 100));
        assertEq(price, ethPrices[ethPrices.length - 1]);
        assertEq(timestamp, START_TIME + (INTERVAL * (ethPrices.length - 1)));
    }

    function testGetPriceAtTimestampFailures() public {
        // Test unsupported asset
        vm.expectRevert("Asset not supported");
        priceFeed.getPriceAtTimestamp("UNKNOWN", START_TIME);

        // Create but deactivate price feed
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );
        priceFeed.togglePriceFeed("ETH");

        vm.expectRevert("Price feed is not active");
        priceFeed.getPriceAtTimestamp("ETH", START_TIME);
    }

    function testGetLatestPrice() public {
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );

        // Mock current time to be start + 3 hours
        uint256 currentTime = START_TIME + (INTERVAL * 3);
        vm.warp(currentTime);

        (uint256 price, uint256 timestamp, uint256 roundId) = priceFeed.getLatestPrice("ETH");

        assertGe(price, 100000000000);
        assertGe(timestamp, START_TIME);
    }

    // function testGetPriceAtRound() public {
    //     priceFeed.createPriceFeed("ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD");

    //     // Test round 1 (index 0)
    //     (uint256 price, uint256 timestamp) = priceFeed.getPriceAtRound("ETH", 1);
    //     assertEq(price, ethPrices[0]);
    //     assertEq(timestamp, START_TIME);

    //     // Test round 5 (index 4)
    //     (price, timestamp) = priceFeed.getPriceAtRound("ETH", 5);
    //     assertEq(price, ethPrices[4]);
    //     assertEq(timestamp, START_TIME + (INTERVAL * 4));

    //     // Test invalid round (0)
    //     vm.expectRevert("Round ID must be greater than 0");
    //     priceFeed.getPriceAtRound("ETH", 0);

    //     // Test round exceeding available data
    //     vm.expectRevert("Round ID exceeds available data");
    //     priceFeed.getPriceAtRound("ETH", ethPrices.length + 1);
    // }

    function testUpdatePriceFeed() public {
        // Create initial price feed
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );

        // Create new prices
        uint256[] memory newPrices = new uint256[](3);
        newPrices[0] = 250000000000; // $2500.00
        newPrices[1] = 255000000000; // $2550.00
        newPrices[2] = 260000000000; // $2600.00

        vm.expectEmit(true, false, false, true);
        emit PriceFeedUpdated("ETH", newPrices);

        priceFeed.updatePriceFeed("ETH", newPrices);

        // Verify prices were updated
        uint256[] memory retrievedPrices = priceFeed.getAllPrices("ETH");
        assertEq(retrievedPrices.length, 3);
        assertEq(retrievedPrices[0], newPrices[0]);
        assertEq(retrievedPrices[1], newPrices[1]);
        assertEq(retrievedPrices[2], newPrices[2]);

        // Verify feed info updated
        (,, uint256 totalRounds,,,) = priceFeed.getFeedInfo("ETH");
        assertEq(totalRounds, 3);
    }

    function testChainlinkCompatibility() public {
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );

        // Mock current time
        vm.warp(START_TIME + (INTERVAL * 2));

        // Test latestRoundData
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            priceFeed.latestRoundData("ETH");

        // assertEq(roundId, 3);
        // assertEq(roundId, 18446744073709576693);
        assertEq(answer, int256(ethPrices[2]));
        assertEq(startedAt, START_TIME + (INTERVAL * 2));
        assertEq(updatedAt, START_TIME + (INTERVAL * 2));
        assertEq(answeredInRound, 3);

        // Test decimals and description
        assertEq(priceFeed.decimals("ETH"), DECIMALS);
        assertEq(priceFeed.description("ETH"), "ETH / USD");
    }

    function testTogglePriceFeed() public {
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );

        // Initially active - verify we can get prices
        (uint256 price, uint256 timestamp) = priceFeed.getPriceAtTimestamp("ETH", START_TIME);
        assertEq(price, ethPrices[0]);
        assertEq(timestamp, START_TIME);

        // Toggle to inactive
        priceFeed.togglePriceFeed("ETH");

        // Verify price feed is now inactive by trying to get a price (should revert)
        vm.expectRevert("Price feed is not active");
        priceFeed.getPriceAtTimestamp("ETH", START_TIME);

        // Also test other functions that should fail when inactive
        vm.expectRevert("Price feed is not active");
        priceFeed.getLatestPrice("ETH");

        // vm.expectRevert("Price feed is not active");
        // priceFeed.getPriceAtRound("ETH", 1);

        // Toggle back to active
        priceFeed.togglePriceFeed("ETH");

        // Verify we can get prices again
        (price, timestamp) = priceFeed.getPriceAtTimestamp("ETH", START_TIME);
        assertEq(price, ethPrices[0]);
        assertEq(timestamp, START_TIME);

        // Test that other functions work again
        (uint256 latestPrice, uint256 latestTimestamp, uint256 roundId) = priceFeed.getLatestPrice("ETH");
        assertTrue(latestPrice > 0);
        assertTrue(latestTimestamp > 0);
        assertTrue(roundId > 0);

        // Test multiple toggles work
        priceFeed.togglePriceFeed("ETH");
        vm.expectRevert("Price feed is not active");
        priceFeed.getPriceAtTimestamp("ETH", START_TIME);

        priceFeed.togglePriceFeed("ETH");
        (price, timestamp) = priceFeed.getPriceAtTimestamp("ETH", START_TIME);
        assertEq(price, ethPrices[0]);
    }

    function testMultipleAssets() public {
        // Create ETH price feed
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );

        // Create BTC price feed
        priceFeed.createPriceFeed(
            "BTC",
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            btcPrices,
            START_TIME,
            INTERVAL * 2,
            DECIMALS,
            "BTC / USD"
        );

        // Verify both assets exist
        string[] memory assets = priceFeed.getSupportedAssets();
        assertEq(assets.length, 2);

        // Verify different intervals work
        (,,,, uint256 ethInterval,) = priceFeed.getFeedInfo("ETH");
        (,,,, uint256 btcInterval,) = priceFeed.getFeedInfo("BTC");

        assertEq(ethInterval, INTERVAL);
        assertEq(btcInterval, INTERVAL * 2);

        // Test prices at same timestamp
        vm.warp(START_TIME + (INTERVAL * 2));

        (uint256 ethPrice,) = priceFeed.getPriceAtTimestamp("ETH", START_TIME + (INTERVAL * 2));
        (uint256 btcPrice,) = priceFeed.getPriceAtTimestamp("BTC", START_TIME + (INTERVAL * 2));

        assertEq(ethPrice, ethPrices[2]); // ETH index 2
        assertEq(btcPrice, btcPrices[1]); // BTC index 1 (different interval)
    }

    function testFuzzPriceCalculation(uint256 timestamp) public {
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, START_TIME, INTERVAL, DECIMALS, "ETH / USD"
        );

        // Bound timestamp to reasonable range
        timestamp = bound(timestamp, 0, START_TIME + (INTERVAL * ethPrices.length * 2));

        (uint256 price, uint256 returnedTimestamp) = priceFeed.getPriceAtTimestamp("ETH", timestamp);

        // Price should always be one of the predefined prices
        bool validPrice = false;
        for (uint256 i = 0; i < ethPrices.length; i++) {
            if (price == ethPrices[i]) {
                validPrice = true;
                break;
            }
        }
        assertTrue(validPrice, "Price should be from predefined array");

        // Returned timestamp should be >= start time
        assertGe(returnedTimestamp, START_TIME);
    }
}

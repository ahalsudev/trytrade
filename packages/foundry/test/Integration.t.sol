// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/TryTrade.sol";
import "../contracts/MockPriceFeed.sol";

contract IntegrationTest is Test {
    TryTrade public tryTrade;
    MockPriceFeed public priceFeed;

    address[] public users;
    uint256 public constant NUM_USERS = 10;
    uint256 public constant LEAGUE_DURATION = 7 days;
    uint256 public constant ENTRY_FEE = 0.1 ether;

    function setUp() public {
        // Deploy contracts
        priceFeed = new MockPriceFeed();
        tryTrade = new TryTrade(address(priceFeed));

        // Create users
        for (uint i = 0; i < NUM_USERS; i++) {
            address user = address(uint160(i + 1));
            users.push(user);
            vm.deal(user, 100 ether);
        }

        // Setup realistic price data
        _setupRealisticPriceFeeds();
    }

    function _setupRealisticPriceFeeds() internal {
        uint256 startTime = block.timestamp + 1 days;
        uint256 interval = 1 hours;
        uint256 duration = LEAGUE_DURATION;
        uint256 pricePoints = duration / interval;

        // ETH: Bull market scenario (+25% over week)
        uint256[] memory ethPrices = new uint256[](pricePoints);
        for (uint i = 0; i < pricePoints; i++) {
            uint256 basePrice = 200000000000; // $2000
            uint256 growth = (basePrice * 25 * i) / (100 * pricePoints); // 25% growth
            uint256 volatility = (i % 12 == 0) ? 1000000000 : 0; // Some volatility every 12 hours
            ethPrices[i] = basePrice + growth + volatility;
        }

        // WBTC: Bear market scenario (-15% over week)
        uint256[] memory wbtcPrices = new uint256[](pricePoints);
        for (uint i = 0; i < pricePoints; i++) {
            uint256 basePrice = 3000000000000; // $30000
            uint256 decline = (basePrice * 15 * i) / (100 * pricePoints); // 15% decline
            wbtcPrices[i] = basePrice - decline;
        }

        priceFeed.createPriceFeed("ETH", ethPrices, startTime, interval, 8, "ETH/USD");
        priceFeed.createPriceFeed("WBTC", wbtcPrices, startTime, interval, 8, "WBTC/USD");
    }

    function testFullLeagueLifecycle() public {
        uint256 startTime = block.timestamp + 1 days;
        uint256 endTime = startTime + LEAGUE_DURATION;

        // 1. Create league
        uint256 leagueId = tryTrade.createLeague(
            "Integration Test League",
            "Full lifecycle test",
            startTime,
            endTime,
            ENTRY_FEE,
            NUM_USERS
        );

        // 2. All users join
        for (uint i = 0; i < NUM_USERS; i++) {
            vm.prank(users[i]);
            tryTrade.joinLeague{value: ENTRY_FEE}(leagueId);
        }

        // Verify all joined
        TryTrade.LeagueInfo memory info = tryTrade.getLeagueInfo(leagueId);
        assertEq(info.currentParticipants, NUM_USERS);
        assertEq(info.prizePool, ENTRY_FEE * NUM_USERS);

        // 3. League starts - users submit portfolios
        vm.warp(startTime + 1);

        // Different portfolio strategies
        string[] memory ethOnly = new string[](1);
        ethOnly[0] = "ETH";
        uint256[] memory ethOnlyAlloc = new uint256[](1);
        ethOnlyAlloc[0] = 100;

        string[] memory wbtcOnly = new string[](1);
        wbtcOnly[0] = "WBTC";
        uint256[] memory wbtcOnlyAlloc = new uint256[](1);
        wbtcOnlyAlloc[0] = 100;

        string[] memory balanced = new string[](2);
        balanced[0] = "ETH";
        balanced[1] = "WBTC";
        uint256[] memory balancedAlloc = new uint256[](2);
        balancedAlloc[0] = 50;
        balancedAlloc[1] = 50;

        // Submit different strategies
        for (uint i = 0; i < NUM_USERS; i++) {
            vm.prank(users[i]);
            if (i < 3) {
                // First 3 users: ETH only (should win)
                tryTrade.submitPortfolio(leagueId, ethOnly, ethOnlyAlloc);
            } else if (i < 6) {
                // Next 3 users: WBTC only (should lose)
                tryTrade.submitPortfolio(leagueId, wbtcOnly, wbtcOnlyAlloc);
            } else {
                // Remaining users: Balanced (middle performance)
                tryTrade.submitPortfolio(leagueId, balanced, balancedAlloc);
            }
        }

        // 4. Time passes, league ends
        vm.warp(endTime + 1);

        // 5. Finalize league
        uint256[] memory balancesBefore = new uint256[](NUM_USERS);
        for (uint i = 0; i < NUM_USERS; i++) {
            balancesBefore[i] = users[i].balance;
        }

        tryTrade.finalizeLeague(leagueId);

        // 6. Verify results
        info = tryTrade.getLeagueInfo(leagueId);
        assertTrue(info.isFinalized);
        assertFalse(info.isActive);

        address[] memory winners = tryTrade.getLeagueWinners(leagueId);
        assertEq(winners.length, 3);

        // Winners should be from ETH-only group (users 0, 1, 2)
        bool winner1Valid = winners[0] == users[0] || winners[0] == users[1] || winners[0] == users[2];
        bool winner2Valid = winners[1] == users[0] || winners[1] == users[1] || winners[1] == users[2];
        bool winner3Valid = winners[2] == users[0] || winners[2] == users[1] || winners[2] == users[2];

        assertTrue(winner1Valid, "First place should be ETH-only user");
        assertTrue(winner2Valid, "Second place should be ETH-only user");
        assertTrue(winner3Valid, "Third place should be ETH-only user");

        // Verify prize distribution
        uint256 totalPrizes = (ENTRY_FEE * NUM_USERS * 50) / 100 +
            (ENTRY_FEE * NUM_USERS * 30) / 100 +
            (ENTRY_FEE * NUM_USERS * 20) / 100;

        uint256 totalDistributed = 0;
        for (uint i = 0; i < 3; i++) {
            uint256 prizeReceived = winners[i].balance - balancesBefore[_findUserIndex(winners[i])];
            totalDistributed += prizeReceived;
        }

        assertEq(totalDistributed, totalPrizes);
    }

    function testMultipleSimultaneousLeagues() public {
        uint256 numLeagues = 3;
        uint256[] memory leagueIds = new uint256[](numLeagues);

        // Create multiple leagues with different parameters
        for (uint i = 0; i < numLeagues; i++) {
            leagueIds[i] = tryTrade.createLeague(
                string.concat("League ", vm.toString(i)),
                "Multi-league test",
                block.timestamp + 1 days + (i * 1 hours), // Staggered start times
                block.timestamp + 8 days + (i * 1 hours),
                ENTRY_FEE * (i + 1), // Different entry fees
                5 // Smaller leagues
            );
        }

        // Users join different combinations of leagues
        for (uint u = 0; u < 5; u++) {
            for (uint l = 0; l < numLeagues; l++) {
                if ((u + l) % 2 == 0) { // Some users join some leagues
                    vm.prank(users[u]);
                    tryTrade.joinLeague{value: ENTRY_FEE * (l + 1)}(leagueIds[l]);
                }
            }
        }

        // Verify league states
        for (uint i = 0; i < numLeagues; i++) {
            TryTrade.LeagueInfo memory info = tryTrade.getLeagueInfo(leagueIds[i]);
            assertGt(info.currentParticipants, 0);
            assertGt(info.prizePool, 0);
        }
    }

    function testPriceVolatilityHandling() public {
        // Create league
        uint256 leagueId = tryTrade.createLeague(
            "Volatility Test",
            "Testing price volatility",
            block.timestamp + 1 days,
            block.timestamp + 8 days,
            ENTRY_FEE,
            3
        );

        // Add users
        for (uint i = 0; i < 3; i++) {
            vm.prank(users[i]);
            tryTrade.joinLeague{value: ENTRY_FEE}(leagueId);
        }

        // Start league and submit portfolios
        vm.warp(block.timestamp + 1 days + 1);

        string[] memory tokens = new string[](2);
        tokens[0] = "ETH";
        tokens[1] = "WBTC";

        uint256[] memory allocations = new uint256[](2);
        allocations[0] = 70;
        allocations[1] = 30;

        for (uint i = 0; i < 3; i++) {
            vm.prank(users[i]);
            tryTrade.submitPortfolio(leagueId, tokens, allocations);
        }

        // Fast forward and finalize
        vm.warp(block.timestamp + 8 days + 1);
        tryTrade.finalizeLeague(leagueId);

        // Should complete without issues despite volatility
        TryTrade.LeagueInfo memory info = tryTrade.getLeagueInfo(leagueId);
        assertTrue(info.isFinalized);
    }

    function _findUserIndex(address user) internal view returns (uint256) {
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == user) return i;
        }
        revert("User not found");
    }
}
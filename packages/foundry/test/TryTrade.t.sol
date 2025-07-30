// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/TryTrade.sol";
import "../contracts/Price.sol";

contract TryTradeTest is Test {
    TryTrade public tryTrade;
    Price public priceFeed;

    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    address public user4 = address(0x4);

    uint256 public constant LEAGUE_START = 1753988262; // July 31, 2025 6:57:42 PM
    uint256 public constant INVALID_LEAGUE_START = 1690578974; // 2023-07-28 22:16:14 UTC
    uint256 public constant LEAGUE_END = LEAGUE_START + 7 days;
    uint256 public constant ENTRY_FEE = 0.1 ether;
    uint256 public constant MAX_PARTICIPANTS = 10;
    uint256 public constant PRICE_INTERVAL = 1 hours;

    uint256[] public ethPrices;
    uint256[] public btcPrices;

    event LeagueCreated(
        uint256 indexed leagueId,
        address indexed creator,
        string name,
        uint256 startTime,
        uint256 endTime,
        uint256 entryFee,
        uint256 maxParticipants
    );

    event PlayerJoined(uint256 indexed leagueId, address indexed player, uint256 entryFee);

    event PortfolioSubmitted(uint256 indexed leagueId, address indexed player, string[] tokens, uint256[] allocations);

    event LeagueFinalized(uint256 indexed leagueId, address[] winners, uint256[] prizes);

    function setUp() public {
        // Deploy PriceFeed
        priceFeed = new Price();

        // Setup price data for league duration (7 days = 168 hours)
        _setupPriceData();

        // Create price feeds
        priceFeed.createPriceFeed(
            "ETH", 0x694AA1769357215DE4FAC081bf1f309aDC325306, ethPrices, LEAGUE_START, PRICE_INTERVAL, 8, "ETH / USD"
        );

        priceFeed.createPriceFeed(
            "BTC", 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43, btcPrices, LEAGUE_START, PRICE_INTERVAL, 8, "BTC / USD"
        );

        // Deploy TryTrade
        tryTrade = new TryTrade(address(priceFeed));

        // Give users some ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);
    }

    function _setupPriceData() internal {
        // ETH prices: starts at $2000, ends at $2200 (+10% gain)
        ethPrices.push(200000000000); // Start: $2000
        for (uint256 i = 1; i < 168; i++) {
            // Gradual increase with some volatility
            uint256 baseIncrease = (20000000000 * i) / 167; // Linear increase to +$200
            uint256 volatility = (i % 3 == 0) ? 5000000000 : 0; // Some volatility
            ethPrices.push(200000000000 + baseIncrease + volatility);
        }
        ethPrices.push(220000000000); // End: $2200

        // BTC prices: starts at $30000, ends at $27000 (-10% loss)
        btcPrices.push(3000000000000); // Start: $30000
        for (uint256 i = 1; i < 168; i++) {
            // Gradual decrease
            uint256 decrease = (300000000000 * i) / 167; // Linear decrease to -$3000
            btcPrices.push(3000000000000 - decrease);
        }
        btcPrices.push(2700000000000); // End: $27000
    }

    function testCreateLeague() public {
        vm.expectEmit(true, true, false, true);
        emit LeagueCreated(1, owner, "Test League", LEAGUE_START, LEAGUE_END, ENTRY_FEE, MAX_PARTICIPANTS);

        uint256 leagueId = tryTrade.createLeague(
            "Test League", "A test fantasy trading league", LEAGUE_START, LEAGUE_END, ENTRY_FEE, MAX_PARTICIPANTS
        );

        assertEq(leagueId, 1);
        assertEq(tryTrade.getTotalLeagues(), 1);

        // Verify league info
        TryTrade.LeagueInfo memory info = tryTrade.getLeagueInfo(leagueId);
        assertEq(info.creator, owner);
        assertEq(info.name, "Test League");
        assertEq(info.startTime, LEAGUE_START);
        assertEq(info.endTime, LEAGUE_END);
        assertEq(info.entryFee, ENTRY_FEE);
        assertEq(info.maxParticipants, MAX_PARTICIPANTS);
        assertEq(info.currentParticipants, 0);
        assertEq(info.prizePool, 0);
        assertTrue(info.isActive);
        assertFalse(info.isFinalized);
    }

    function testJoinLeague() public {
        uint256 leagueId =
            tryTrade.createLeague("Test League", "Description", LEAGUE_START, LEAGUE_END, ENTRY_FEE, MAX_PARTICIPANTS);

        vm.expectEmit(true, true, false, true);
        emit PlayerJoined(leagueId, user1, ENTRY_FEE);

        vm.prank(user1);
        tryTrade.joinLeague{ value: ENTRY_FEE }(leagueId);

        // Verify league state
        TryTrade.LeagueInfo memory info = tryTrade.getLeagueInfo(leagueId);
        assertEq(info.currentParticipants, 1);
        assertEq(info.prizePool, ENTRY_FEE);

        // Verify participant
        address[] memory participants = tryTrade.getLeagueParticipants(leagueId);
        assertEq(participants.length, 1);
        assertEq(participants[0], user1);

        // Verify user leagues
        uint256[] memory userLeagues = tryTrade.getUserLeagues(user1);
        assertEq(userLeagues.length, 1);
        assertEq(userLeagues[0], leagueId);
    }

    function testJoinLeagueFailures() public {
        uint256 leagueId = tryTrade.createLeague(
            "Test League",
            "Description",
            LEAGUE_START,
            LEAGUE_END,
            ENTRY_FEE,
            3 // Max 3 participants
        );

        // Incorrect entry fee
        vm.prank(user1);
        vm.expectRevert("Incorrect entry fee");
        tryTrade.joinLeague{ value: ENTRY_FEE + 1 }(leagueId);

        // Join successfully
        vm.prank(user1);
        tryTrade.joinLeague{ value: ENTRY_FEE }(leagueId); // Fixed: use leagueId instead of user1

        // Already joined
        vm.prank(user1);
        vm.expectRevert("Already joined this league");
        tryTrade.joinLeague{ value: ENTRY_FEE }(leagueId);

        // Fill up league
        vm.prank(user2);
        tryTrade.joinLeague{ value: ENTRY_FEE }(leagueId);
        vm.prank(user3);
        tryTrade.joinLeague{ value: ENTRY_FEE }(leagueId);

        // League full
        vm.prank(user4);
        vm.expectRevert("League is full");
        tryTrade.joinLeague{ value: ENTRY_FEE }(leagueId);

        // League started
        vm.warp(LEAGUE_START + 1);
        vm.prank(user4);
        vm.expectRevert("League has already started");
        tryTrade.joinLeague{ value: ENTRY_FEE }(leagueId);
    }

    // Add more test functions as needed...

    function testSubmitPortfolio() public {
        uint256 leagueId = _createAndJoinLeague();

        // Warp to league start
        vm.warp(LEAGUE_START + 1);

        string[] memory tokens = new string[](2);
        tokens[0] = "ETH";
        tokens[1] = "BTC";

        uint256[] memory allocations = new uint256[](2);
        allocations[0] = 60; // 60% ETH
        allocations[1] = 40; // 40% BTC

        vm.expectEmit(true, true, false, true);
        emit PortfolioSubmitted(leagueId, user1, tokens, allocations);

        vm.prank(user1);
        tryTrade.submitPortfolio(leagueId, tokens, allocations);

        // Verify portfolio
        (string[] memory portfolioTokens, uint256[] memory portfolioAllocations, bool isSubmitted) =
            tryTrade.getUserPortfolio(leagueId, user1);

        assertEq(portfolioTokens.length, 2);
        assertEq(portfolioTokens[0], "ETH");
        assertEq(portfolioTokens[1], "BTC");
        assertEq(portfolioAllocations[0], 60);
        assertEq(portfolioAllocations[1], 40);
        assertTrue(isSubmitted);
    }

    // Helper functions
    function _createAndJoinLeague() internal returns (uint256 leagueId) {
        leagueId =
            tryTrade.createLeague("Test League", "Description", LEAGUE_START, LEAGUE_END, ENTRY_FEE, MAX_PARTICIPANTS);

        vm.prank(user1);
        tryTrade.joinLeague{ value: ENTRY_FEE }(leagueId);
    }
}

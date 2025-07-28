// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMockPriceFeed {
    function getPriceAtTimestamp(string memory _asset, uint256 _timestamp) external view returns (uint256 price, uint256 timestamp);
    function getLatestPrice(string memory _asset) external view returns (uint256 price, uint256 timestamp, uint256 roundId);
    function decimals(string memory _asset) external view returns (uint8);
}

/**
 * @title TryTrade
 * @dev Decentralized Fantasy Trading Platform
 * @notice Allows users to create and participate in fantasy trading leagues
 */
contract TryTrade is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _leagueIds;

    // Constants
    uint256 public constant VIRTUAL_UNITS = 100;
    uint256 public constant FIRST_PLACE_PERCENTAGE = 50;
    uint256 public constant SECOND_PLACE_PERCENTAGE = 30;
    uint256 public constant THIRD_PLACE_PERCENTAGE = 20;

    // Token structure
    struct Token {
        string symbol;
        address contractAddress;
        bool isActive;
    }

    // Structs
    struct League {
        uint256 leagueId;
        address creator;
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 entryFee;
        uint256 maxParticipants;
        uint256 currentParticipants;
        uint256 prizePool;
        bool isActive;
        bool isFinalized;
        address[] participants;
        mapping(address => bool) hasJoined;
        mapping(address => Portfolio) portfolios;
        mapping(address => uint256) finalScores;
        address[] winners; // [1st, 2nd, 3rd]
    }

    struct Portfolio {
        mapping(string => uint256) allocations; // token symbol => allocated units
        string[] tokens; // list of allocated tokens
        uint256 totalAllocated;
        bool isSubmitted;
        uint256 finalReturn; // final return percentage (basis points)
    }

    struct LeagueInfo {
        uint256 leagueId;
        address creator;
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 entryFee;
        uint256 maxParticipants;
        uint256 currentParticipants;
        uint256 prizePool;
        bool isActive;
        bool isFinalized;
    }

    // State variables
    mapping(uint256 => League) public leagues;
    mapping(address => uint256[]) public userLeagues;
    mapping(string => Token) public supportedTokens; // symbol => Token struct
    string[] public tokenSymbols; // array of supported token symbols
    mapping(string => bool) public isTokenSupported;

    // Price feed contract
    IMockPriceFeed public priceFeed;

    // Events
    event LeagueCreated(
        uint256 indexed leagueId,
        address indexed creator,
        string name,
        uint256 startTime,
        uint256 endTime,
        uint256 entryFee,
        uint256 maxParticipants
    );

    event PlayerJoined(
        uint256 indexed leagueId,
        address indexed player,
        uint256 entryFee
    );

    event PortfolioSubmitted(
        uint256 indexed leagueId,
        address indexed player,
        string[] tokens,
        uint256[] allocations
    );

    event LeagueFinalized(
        uint256 indexed leagueId,
        address[] winners,
        uint256[] prizes
    );

    event PrizeDistributed(
        uint256 indexed leagueId,
        address indexed winner,
        uint256 position,
        uint256 amount
    );

    event TokenAdded(
        string indexed symbol,
        address indexed contractAddress
    );

    event TokenRemoved(
        string indexed symbol
    );

    event PriceFeedUpdated(
        address indexed oldPriceFeed,
        address indexed newPriceFeed
    );

    // Modifiers
    modifier leagueExists(uint256 _leagueId) {
        require(_leagueId > 0 && _leagueId <= _leagueIds.current(), "League does not exist");
        _;
    }

    modifier leagueActive(uint256 _leagueId) {
        require(leagues[_leagueId].isActive, "League is not active");
        require(block.timestamp >= leagues[_leagueId].startTime, "League has not started");
        require(block.timestamp <= leagues[_leagueId].endTime, "League has ended");
        _;
    }

    modifier onlyParticipant(uint256 _leagueId) {
        require(leagues[_leagueId].hasJoined[msg.sender], "Not a participant");
        _;
    }

    constructor(address _priceFeed) {
        require(_priceFeed != address(0), "Price feed address cannot be zero");
        priceFeed = IMockPriceFeed(_priceFeed);

        // Initialize with common cryptocurrency tokens
        _addToken("ETH", address(0)); // ETH uses zero address
        _addToken("WBTC", 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); // Example WBTC address on mainnet
    }

    /**
     * @dev Internal function to add a token
     */
    function _addToken(string memory _symbol, address _contractAddress) internal {
        supportedTokens[_symbol] = Token({
            symbol: _symbol,
            contractAddress: _contractAddress,
            isActive: true
        });
        tokenSymbols.push(_symbol);
        isTokenSupported[_symbol] = true;
    }

    /**
     * @dev Update price feed contract address
     */
    function setPriceFeed(address _priceFeed) external onlyOwner {
        require(_priceFeed != address(0), "Price feed address cannot be zero");
        address oldPriceFeed = address(priceFeed);
        priceFeed = IMockPriceFeed(_priceFeed);
        emit PriceFeedUpdated(oldPriceFeed, _priceFeed);
    }

    /**
     * @dev Create a new trading league
     */
    function createLeague(
        string memory _name,
        string memory _description,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _entryFee,
        uint256 _maxParticipants
    ) external returns (uint256) {
        require(bytes(_name).length > 0, "League name cannot be empty");
        require(_startTime > block.timestamp, "Start time must be in the future");
        require(_endTime > _startTime, "End time must be after start time");
        require(_maxParticipants > 0, "Max participants must be greater than 0");
        require(_maxParticipants >= 3, "Need at least 3 participants for prizes");

        _leagueIds.increment();
        uint256 newLeagueId = _leagueIds.current();

        League storage newLeague = leagues[newLeagueId];
        newLeague.leagueId = newLeagueId;
        newLeague.creator = msg.sender;
        newLeague.name = _name;
        newLeague.description = _description;
        newLeague.startTime = _startTime;
        newLeague.endTime = _endTime;
        newLeague.entryFee = _entryFee;
        newLeague.maxParticipants = _maxParticipants;
        newLeague.isActive = true;

        userLeagues[msg.sender].push(newLeagueId);

        emit LeagueCreated(
            newLeagueId,
            msg.sender,
            _name,
            _startTime,
            _endTime,
            _entryFee,
            _maxParticipants
        );

        return newLeagueId;
    }

    /**
     * @dev Join an existing league
     */
    function joinLeague(uint256 _leagueId)
    external
    payable
    leagueExists(_leagueId)
    nonReentrant
    {
        League storage league = leagues[_leagueId];

        require(league.isActive, "League is not active");
        require(block.timestamp < league.startTime, "League has already started");
        require(!league.hasJoined[msg.sender], "Already joined this league");
        require(league.currentParticipants < league.maxParticipants, "League is full");
        require(msg.value == league.entryFee, "Incorrect entry fee");

        league.hasJoined[msg.sender] = true;
        league.participants.push(msg.sender);
        league.currentParticipants++;
        league.prizePool += msg.value;

        userLeagues[msg.sender].push(_leagueId);

        emit PlayerJoined(_leagueId, msg.sender, msg.value);
    }

    /**
     * @dev Submit portfolio allocation for a league
     */
    function submitPortfolio(
        uint256 _leagueId,
        string[] memory _tokens,
        uint256[] memory _allocations
    )
    external
    leagueExists(_leagueId)
    leagueActive(_leagueId)
    onlyParticipant(_leagueId)
    {
        require(_tokens.length == _allocations.length, "Arrays length mismatch");
        require(_tokens.length > 0, "Must allocate to at least one token");

        League storage league = leagues[_leagueId];
        Portfolio storage portfolio = league.portfolios[msg.sender];

        require(!portfolio.isSubmitted, "Portfolio already submitted");

        uint256 totalAllocation = 0;

        // Clear existing allocations
        for (uint i = 0; i < portfolio.tokens.length; i++) {
            delete portfolio.allocations[portfolio.tokens[i]];
        }
        delete portfolio.tokens;

        // Set new allocations
        for (uint i = 0; i < _tokens.length; i++) {
            require(isTokenSupported[_tokens[i]], "Token not supported");
            require(_allocations[i] > 0, "Allocation must be greater than 0");

            portfolio.allocations[_tokens[i]] = _allocations[i];
            portfolio.tokens.push(_tokens[i]);
            totalAllocation += _allocations[i];
        }

        require(totalAllocation == VIRTUAL_UNITS, "Total allocation must equal 100 units");

        portfolio.totalAllocated = totalAllocation;
        portfolio.isSubmitted = true;

        emit PortfolioSubmitted(_leagueId, msg.sender, _tokens, _allocations);
    }

    /**
     * @dev Calculate portfolio return percentage using price feed
     */
    function calculatePortfolioReturn(
        uint256 _leagueId,
        address _participant
    ) public view returns (uint256) {
        League storage league = leagues[_leagueId];
        Portfolio storage portfolio = league.portfolios[_participant];

        require(portfolio.isSubmitted, "Portfolio not submitted");

        uint256 totalStartValue = 0;
        uint256 totalEndValue = 0;

        for (uint i = 0; i < portfolio.tokens.length; i++) {
            string memory token = portfolio.tokens[i];
            uint256 allocation = portfolio.allocations[token];

            // Get start and end prices from price feed
            (uint256 startPrice, ) = priceFeed.getPriceAtTimestamp(token, league.startTime);
            (uint256 endPrice, ) = priceFeed.getPriceAtTimestamp(token, league.endTime);

            // Get token decimals for proper calculation
            uint8 tokenDecimals = priceFeed.decimals(token);

            // Calculate value for this allocation
            uint256 startValue = (allocation * startPrice) / (10 ** tokenDecimals);
            uint256 endValue = (allocation * endPrice) / (10 ** tokenDecimals);

            totalStartValue += startValue;
            totalEndValue += endValue;
        }

        if (totalStartValue == 0) return 0;

        // Calculate return percentage in basis points (10000 = 100%)
        if (totalEndValue >= totalStartValue) {
            return ((totalEndValue - totalStartValue) * 10000) / totalStartValue;
        } else {
            return 0; // No negative returns for this MVP
        }
    }

    /**
     * @dev Finalize league with automatic price fetching from price feed
     */
    function finalizeLeague(uint256 _leagueId)
    external
    onlyOwner
    leagueExists(_leagueId)
    nonReentrant
    {
        League storage league = leagues[_leagueId];

        require(league.isActive, "League is not active");
        require(block.timestamp > league.endTime, "League has not ended yet");
        require(!league.isFinalized, "League already finalized");
        require(league.currentParticipants >= 3, "Need at least 3 participants");

        // Calculate pnls for all participants
        address[] memory participants = league.participants;
        uint256[] memory pnls = new uint256[](participants.length);

        for (uint i = 0; i < participants.length; i++) {
            if (league.portfolios[participants[i]].isSubmitted) {
                pnls[i] = calculatePortfolioReturn(_leagueId, participants[i]);
                league.finalScores[participants[i]] = pnls[i];
            } else {
                pnls[i] = 0; // No portfolio submitted = 0 return
                league.finalScores[participants[i]] = 0;
            }
        }

        // Sort participants by returns
        address[] memory sortedParticipants = _sortParticipantsByReturns(participants, pnls);

        // Set winners (top 3)
        league.winners = new address[](3);
        for (uint i = 0; i < 3 && i < sortedParticipants.length; i++) {
            league.winners[i] = sortedParticipants[i];
        }

        // Calculate and distribute prizes
        uint256[] memory prizes = new uint256[](3);
        prizes[0] = (league.prizePool * FIRST_PLACE_PERCENTAGE) / 100;
        prizes[1] = (league.prizePool * SECOND_PLACE_PERCENTAGE) / 100;
        prizes[2] = (league.prizePool * THIRD_PLACE_PERCENTAGE) / 100;

        // Distribute prizes
        for (uint i = 0; i < 3 && i < league.winners.length; i++) {
            if (league.winners[i] != address(0) && prizes[i] > 0) {
                (bool success, ) = payable(league.winners[i]).call{value: prizes[i]}("");
                require(success, "Prize transfer failed");

                emit PrizeDistributed(_leagueId, league.winners[i], i + 1, prizes[i]);
            }
        }

        league.isFinalized = true;
        league.isActive = false;

        emit LeagueFinalized(_leagueId, league.winners, prizes);
    }

    /**
     * @dev Sort participants by returns (descending order)
     */
    function _sortParticipantsByReturns(
        address[] memory _participants,
        uint256[] memory _pnls
    ) private pure returns (address[] memory) {
        address[] memory sortedParticipants = new address[](_participants.length);
        uint256[] memory sortedReturns = new uint256[](_pnls.length);

        // Copy arrays
        for (uint i = 0; i < _participants.length; i++) {
            sortedParticipants[i] = _participants[i];
            sortedReturns[i] = _pnls[i];
        }

        // Simple bubble sort (for MVP - optimize for production)
        for (uint i = 0; i < sortedReturns.length - 1; i++) {
            for (uint j = 0; j < sortedReturns.length - i - 1; j++) {
                if (sortedReturns[j] < sortedReturns[j + 1]) {
                    // Swap returns
                    uint256 tempReturn = sortedReturns[j];
                    sortedReturns[j] = sortedReturns[j + 1];
                    sortedReturns[j + 1] = tempReturn;

                    // Swap participants
                    address tempParticipant = sortedParticipants[j];
                    sortedParticipants[j] = sortedParticipants[j + 1];
                    sortedParticipants[j + 1] = tempParticipant;
                }
            }
        }

        return sortedParticipants;
    }

    /**
     * @dev Get current price from price feed
     */
    function getCurrentPrice(string memory _asset) external view returns (uint256 price, uint256 timestamp) {
        (price, timestamp, ) = priceFeed.getLatestPrice(_asset);
        return (price, timestamp);
    }

    /**
     * @dev Get historical price from price feed
     */
    function getHistoricalPrice(string memory _asset, uint256 _timestamp) external view returns (uint256 price, uint256 timestamp) {
        return priceFeed.getPriceAtTimestamp(_asset, _timestamp);
    }

    // ... (rest of the getter functions remain the same as in the previous version)

    /**
     * @dev Get league information
     */
    function getLeagueInfo(uint256 _leagueId)
    external
    view
    leagueExists(_leagueId)
    returns (LeagueInfo memory)
    {
        League storage league = leagues[_leagueId];

        return LeagueInfo({
            leagueId: league.leagueId,
            creator: league.creator,
            name: league.name,
            description: league.description,
            startTime: league.startTime,
            endTime: league.endTime,
            entryFee: league.entryFee,
            maxParticipants: league.maxParticipants,
            currentParticipants: league.currentParticipants,
            prizePool: league.prizePool,
            isActive: league.isActive,
            isFinalized: league.isFinalized
        });
    }

    /**
     * @dev Get league participants
     */
    function getLeagueParticipants(uint256 _leagueId)
    external
    view
    leagueExists(_leagueId)
    returns (address[] memory)
    {
        return leagues[_leagueId].participants;
    }

    /**
     * @dev Get league winners
     */
    function getLeagueWinners(uint256 _leagueId)
    external
    view
    leagueExists(_leagueId)
    returns (address[] memory)
    {
        require(leagues[_leagueId].isFinalized, "League not finalized");
        return leagues[_leagueId].winners;
    }

    /**
     * @dev Get participant's final score
     */
    function getParticipantScore(uint256 _leagueId, address _participant)
    external
    view
    leagueExists(_leagueId)
    returns (uint256)
    {
        require(leagues[_leagueId].isFinalized, "League not finalized");
        return leagues[_leagueId].finalScores[_participant];
    }

    /**
     * @dev Get user's portfolio for a league
     */
    function getUserPortfolio(uint256 _leagueId, address _user)
    external
    view
    leagueExists(_leagueId)
    returns (string[] memory tokens, uint256[] memory allocations, bool isSubmitted)
    {
        Portfolio storage portfolio = leagues[_leagueId].portfolios[_user];

        tokens = portfolio.tokens;
        allocations = new uint256[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            allocations[i] = portfolio.allocations[tokens[i]];
        }

        isSubmitted = portfolio.isSubmitted;
    }

    /**
     * @dev Get user's leagues
     */
    function getUserLeagues(address _user)
    external
    view
    returns (uint256[] memory)
    {
        return userLeagues[_user];
    }

    /**
     * @dev Get supported tokens with their contract addresses
     */
    function getSupportedTokens()
    external
    view
    returns (string[] memory symbols, address[] memory addresses)
    {
        symbols = new string[](tokenSymbols.length);
        addresses = new address[](tokenSymbols.length);

        uint256 activeCount = 0;
        for (uint i = 0; i < tokenSymbols.length; i++) {
            if (supportedTokens[tokenSymbols[i]].isActive) {
                symbols[activeCount] = supportedTokens[tokenSymbols[i]].symbol;
                addresses[activeCount] = supportedTokens[tokenSymbols[i]].contractAddress;
                activeCount++;
            }
        }

        // Resize arrays to only include active tokens
        assembly {
            mstore(symbols, activeCount)
            mstore(addresses, activeCount)
        }
    }

    /**
     * @dev Get token info by symbol
     */
    function getTokenInfo(string memory _symbol)
    external
    view
    returns (Token memory)
    {
        require(isTokenSupported[_symbol], "Token not supported");
        return supportedTokens[_symbol];
    }

    /**
     * @dev Add supported token (only owner)
     */
    function addSupportedToken(string memory _symbol, address _contractAddress)
    external
    onlyOwner
    {
        require(!isTokenSupported[_symbol], "Token already supported");
        require(bytes(_symbol).length > 0, "Symbol cannot be empty");

        _addToken(_symbol, _contractAddress);
        emit TokenAdded(_symbol, _contractAddress);
    }

    /**
     * @dev Remove supported token (only owner)
     */
    function removeSupportedToken(string memory _symbol)
    external
    onlyOwner
    {
        require(isTokenSupported[_symbol], "Token not supported");

        supportedTokens[_symbol].isActive = false;
        isTokenSupported[_symbol] = false;

        // Remove from tokenSymbols array
        for (uint i = 0; i < tokenSymbols.length; i++) {
            if (keccak256(bytes(tokenSymbols[i])) == keccak256(bytes(_symbol))) {
                tokenSymbols[i] = tokenSymbols[tokenSymbols.length - 1];
                tokenSymbols.pop();
                break;
            }
        }

        emit TokenRemoved(_symbol);
    }

    /**
     * @dev Get total number of leagues
     */
    function getTotalLeagues() external view returns (uint256) {
        return _leagueIds.current();
    }

    /**
     * @dev Emergency withdraw function (only owner)
     */
    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Emergency withdraw failed");
    }
}
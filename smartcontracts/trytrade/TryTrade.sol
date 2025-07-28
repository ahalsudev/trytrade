// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "openzeppelin/contracts/security/ReentrancyGuard.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/utils/Counters.sol";

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
        mapping(string => uint256) allocations; // token addr => allocated units
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
    string[] public supportedTokens;
    mapping(string => bool) public isSupportedToken;

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

    constructor() {
        // Initialize with common cryptocurrency tokens
        supportedTokens = ["ETH", "WBTC"];

        for (uint i = 0; i < supportedTokens.length; i++) {
            isSupportedToken[supportedTokens[i]] = true;
        }
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
            require(isSupportedToken[_tokens[i]], "Token not supported");
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
     * @dev Finalize league and distribute prizes (only owner can call for MVP)
     * @notice In production, this would integrate with price oracles
     */
    function finalizeLeague(
        uint256 _leagueId,
        address[] memory _participants,
        uint256[] memory _returns
    )
    external
    onlyOwner
    leagueExists(_leagueId)
    nonReentrant
    {
        League storage league = leagues[_leagueId];

        require(league.isActive, "League is not active");
        require(block.timestamp > league.endTime, "League has not ended yet");
        require(!league.isFinalized, "League already finalized");
        require(_participants.length == _returns.length, "Arrays length mismatch");
        require(league.currentParticipants >= 3, "Need at least 3 participants");

        // Store final returns
        for (uint i = 0; i < _participants.length; i++) {
            require(league.hasJoined[_participants[i]], "Invalid participant");
            league.finalScores[_participants[i]] = _returns[i];
        }

        // Find top 3 performers
        address[] memory sortedParticipants = _sortParticipantsByReturns(_leagueId, _participants, _returns);

        league.winners = new address[](3);
        league.winners[0] = sortedParticipants[0]; // 1st place
        league.winners[1] = sortedParticipants[1]; // 2nd place
        league.winners[2] = sortedParticipants[2]; // 3rd place

        // Calculate prizes
        uint256[] memory prizes = new uint256[](3);
        prizes[0] = (league.prizePool * FIRST_PLACE_PERCENTAGE) / 100;
        prizes[1] = (league.prizePool * SECOND_PLACE_PERCENTAGE) / 100;
        prizes[2] = (league.prizePool * THIRD_PLACE_PERCENTAGE) / 100;

        // Distribute prizes
        for (uint i = 0; i < 3; i++) {
            if (prizes[i] > 0) {
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
        uint256 _leagueId,
        address[] memory _participants,
        uint256[] memory _returns
    ) private pure returns (address[] memory) {
        address[] memory sortedParticipants = new address[](_participants.length);
        uint256[] memory sortedReturns = new uint256[](_returns.length);

        // Copy arrays
        for (uint i = 0; i < _participants.length; i++) {
            sortedParticipants[i] = _participants[i];
            sortedReturns[i] = _returns[i];
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
     * @dev Get supported tokens
     */
    function getSupportedTokens()
    external
    view
    returns (string[] memory)
    {
        return supportedTokens;
    }

    /**
     * @dev Add supported token (only owner)
     */
    function addSupportedToken(string memory _token)
    external
    onlyOwner
    {
        require(!isSupportedToken[_token], "Token already supported");

        supportedTokens.push(_token);
        isSupportedToken[_token] = true;
    }

    /**
     * @dev Remove supported token (only owner)
     */
    function removeSupportedToken(string memory _token)
    external
    onlyOwner
    {
        require(isSupportedToken[_token], "Token not supported");

        isSupportedToken[_token] = false;

        // Remove from array
        for (uint i = 0; i < supportedTokens.length; i++) {
            if (keccak256(bytes(supportedTokens[i])) == keccak256(bytes(_token))) {
                supportedTokens[i] = supportedTokens[supportedTokens.length - 1];
                supportedTokens.pop();
                break;
            }
        }
    }

    /**
     * @dev Get total number of leagues
     */
    function getTotalLeagues() external view returns (uint256) {
        return _leagueIds.current();
    }
}
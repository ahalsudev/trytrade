// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@flarenetwork/flare-periphery-contracts/coston2/ContractRegistry.sol";
import "@flarenetwork/flare-periphery-contracts/coston2/FtsoV2Interface.sol";

interface ICompetitionFactory {
    function registerUserParticipation(address user, address competitionAddress) external;
}

/**
 * @title Competition
 * @dev A contract for managing a single fantasy cryptocurrency investing competition
 */
contract Competition is ReentrancyGuard {
    // State variables
    address public owner;
    string public name;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public stakeAmount;
    bool public finalized;
    address public factoryAddress;
    FtsoV2Interface public ftsoV2;
    
    // Participant data structures
    struct Asset {
        bytes21 feedId;
        uint8 allocation; // 0-100 points
        uint256 initialPrice;
        uint256 finalPrice;
        int8 decimals; // Store decimals to properly calculate returns
    }
    
    struct Participant {
        address userAddress;
        Asset[] portfolio;
        int256 totalReturn; // Can be negative, stored as basis points (1% = 100)
        bool hasJoined;
        bool hasWithdrawnReward;
        uint256 rank; // 0 means not ranked yet
    }
    
    // Storage
    address[] public participantAddresses;
    mapping(address => Participant) public participants;
    address[] public rankedParticipants; // Sorted by totalReturn, highest first
    
    // Events
    event CompetitionCreated(string name, uint256 startDate, uint256 endDate, uint256 stakeAmount);
    event UserJoined(address indexed user);
    event InitialPricesRecorded(address indexed user);
    event FinalPricesRecorded();
    event CompetitionFinalized();
    event RewardDistributed(address indexed winner, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier beforeStart() {
        require(block.timestamp < startDate, "Competition already started");
        _;
    }
    
    modifier afterStart() {
        require(block.timestamp >= startDate, "Competition not started yet");
        _;
    }
    
    modifier afterEnd() {
        require(block.timestamp > endDate, "Competition not ended yet");
        _;
    }
    
    modifier notFinalized() {
        require(!finalized, "Competition already finalized");
        _;
    }
    
    /**
     * @dev Constructor to create a new competition
     * @param _owner The address that will own this competition
     * @param _name The name of the competition
     * @param _startDate The timestamp when the competition starts
     * @param _endDate The timestamp when the competition ends
     * @param _stakeAmount The amount in C2FLR tokens required to join
     * @param _factoryAddress The address of the factory that created this competition
     */
    constructor(
        address _owner,
        string memory _name,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _stakeAmount,
        address _factoryAddress
    ) {
        require(_startDate > block.timestamp, "Start date must be in the future");
        require(_endDate > _startDate, "End date must be after start date");
        require(_stakeAmount > 0, "Stake amount must be greater than zero");
        require(bytes(_name).length > 0, "Competition name cannot be empty");
        
        owner = _owner;
        name = _name;
        startDate = _startDate;
        endDate = _endDate;
        stakeAmount = _stakeAmount;
        // Get FTSOv2 instance from ContractRegistry
        ftsoV2 = ContractRegistry.getFtsoV2();
        factoryAddress = _factoryAddress;
        finalized = false;
        
        emit CompetitionCreated(name, startDate, endDate, stakeAmount);
    }
    
    /**
     * @dev Allows a user to join the competition
     * @param feedIds Array of FTSO feed IDs representing chosen cryptocurrencies
     * @param allocations Array of point allocations (0-100) for each feed ID
     */
    function joinCompetition(bytes21[] calldata feedIds, uint8[] calldata allocations) external payable beforeStart nonReentrant {
        require(!participants[msg.sender].hasJoined, "Already joined");
        require(feedIds.length == allocations.length, "Feedids and allocations length mismatch");
        require(feedIds.length > 0, "Must select at least one asset");
        require(msg.value == stakeAmount, "Incorrect stake amount");
        
        // Validate allocations sum to 100
        uint16 totalAllocation = 0;
        for (uint256 i = 0; i < allocations.length; i++) {
            totalAllocation += allocations[i];
        }
        require(totalAllocation == 100, "Allocations must sum to 100");
        
        // Create participant entry
        Participant storage newParticipant = participants[msg.sender];
        newParticipant.userAddress = msg.sender;
        newParticipant.hasJoined = true;
        
        // Create portfolio
        for (uint256 i = 0; i < feedIds.length; i++) {
            Asset memory newAsset = Asset({
                feedId: feedIds[i],
                allocation: allocations[i],
                initialPrice: 0,
                finalPrice: 0,
                decimals: 0
            });
            newParticipant.portfolio.push(newAsset);
        }
        
        participantAddresses.push(msg.sender);
        
        // Register with factory if available
        if (factoryAddress != address(0)) {
            ICompetitionFactory(factoryAddress).registerUserParticipation(msg.sender, address(this));
        }
        
        emit UserJoined(msg.sender);
    }
    
    /**
     * @dev Checks if a user has joined the competition
     * @param user The address of the user
     * @return bool True if the user has joined
     */
    function hasUserJoined(address user) external view returns (bool) {
        return participants[user].hasJoined;
    }

    /**
     * @dev Records initial prices for all participants who haven't had them recorded yet
     */
    function recordInitialPrices() external afterStart notFinalized {
        // This function can be called once the competition starts to record initial prices for all participants
        require(!_areAllInitialPricesRecorded(), "Initial prices already recorded for all participants");
        
        for (uint256 i = 0; i < participantAddresses.length; i++) {
            address userAddr = participantAddresses[i];
            Participant storage participant = participants[userAddr];
            
            // Skip if initial prices already recorded
            if (participant.portfolio.length > 0 && participant.portfolio[0].initialPrice > 0) {
                continue;
            }
            
            _recordInitialPricesForUser(userAddr);
        }
    }
    
    /**
     * @dev Checks if all participants have initial prices recorded
     * @return bool True if all participants have initial prices recorded
     */
    function _areAllInitialPricesRecorded() internal view returns (bool) {
        for (uint256 i = 0; i < participantAddresses.length; i++) {
            Participant storage participant = participants[participantAddresses[i]];
            
            if (participant.portfolio.length > 0 && participant.portfolio[0].initialPrice == 0) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @dev Records initial prices for a specific user's portfolio
     * @param userAddr The address of the user
     */
    function _recordInitialPricesForUser(address userAddr) internal {
        Participant storage participant = participants[userAddr];
        
        // Skip if already recorded
        if (participant.portfolio.length > 0 && participant.portfolio[0].initialPrice > 0) {
            return;
        }
        
        // Prepare an array of feed IDs for the batch request
        bytes21[] memory feedIds = new bytes21[](participant.portfolio.length);
        for (uint256 i = 0; i < participant.portfolio.length; i++) {
            feedIds[i] = participant.portfolio[i].feedId;
        }
        
        // Get all prices in a single call to reduce gas costs
        if (feedIds.length > 0) {
            (uint256[] memory prices, int8[] memory decimalsArr, ) = ftsoV2.getFeedsById(feedIds);
            
            // Store prices and decimals for each asset
            for (uint256 i = 0; i < participant.portfolio.length; i++) {
                participant.portfolio[i].initialPrice = prices[i];
                participant.portfolio[i].decimals = decimalsArr[i];
            }
        }
        
        emit InitialPricesRecorded(userAddr);
    }
    
    /**
     * @dev Finalizes the competition, recording final prices and calculating rankings
     */
    function finalizeCompetition() external afterEnd notFinalized nonReentrant {
        require(participantAddresses.length > 0, "No participants");
        
        // Ensure all initial prices are recorded
        if (!_areAllInitialPricesRecorded()) {
            for (uint256 i = 0; i < participantAddresses.length; i++) {
                _recordInitialPricesForUser(participantAddresses[i]);
            }
        }
        
        // Record final prices for all assets of all participants
        for (uint256 i = 0; i < participantAddresses.length; i++) {
            address userAddr = participantAddresses[i];
            Participant storage participant = participants[userAddr];
            
            // Prepare an array of feed IDs for the batch request
            bytes21[] memory feedIds = new bytes21[](participant.portfolio.length);
            for (uint256 j = 0; j < participant.portfolio.length; j++) {
                feedIds[j] = participant.portfolio[j].feedId;
            }
            
            // Get all prices in a single call to reduce gas costs
            if (feedIds.length > 0) {
                (uint256[] memory prices, , ) = ftsoV2.getFeedsById(feedIds);
                
                // Store final prices for each asset
                for (uint256 j = 0; j < participant.portfolio.length; j++) {
                    participant.portfolio[j].finalPrice = prices[j];
                }
            }
            
            // Calculate participant's return
            _calculateReturn(userAddr);
        }
        
        emit FinalPricesRecorded();
        
        // Rank participants
        _rankParticipants();
        
        finalized = true;
        emit CompetitionFinalized();
    }
    
    /**
     * @dev Calculates the total return for a user's portfolio
     * @param userAddr The address of the user
     */
    function _calculateReturn(address userAddr) internal {
        Participant storage participant = participants[userAddr];
        int256 totalReturn = 0;
        
        for (uint256 i = 0; i < participant.portfolio.length; i++) {
            Asset memory asset = participant.portfolio[i];
            if (asset.initialPrice == 0) continue; // Skip assets with no initial price
            
            // Calculate percentage return for this asset ((finalPrice - initialPrice) / initialPrice * 10000)
            // Result is in basis points (1% = 100)
            int256 assetReturn;
            if (asset.finalPrice > asset.initialPrice) {
                assetReturn = int256(((asset.finalPrice - asset.initialPrice) * 10000) / asset.initialPrice);
            } else {
                assetReturn = -int256(((asset.initialPrice - asset.finalPrice) * 10000) / asset.initialPrice);
            }
            
            // Weight by allocation
            totalReturn += (assetReturn * int256(uint256(asset.allocation))) / 100;
        }
        
        participant.totalReturn = totalReturn;
    }
    
    /**
     * @dev Ranks all participants based on their total returns
     */
    function _rankParticipants() internal {
        // Copy participants to an array for sorting
        address[] memory addrs = new address[](participantAddresses.length);
        for (uint256 i = 0; i < participantAddresses.length; i++) {
            addrs[i] = participantAddresses[i];
        }
        
        // Sort by totalReturn (bubble sort for simplicity)
        for (uint256 i = 0; i < addrs.length; i++) {
            for (uint256 j = i + 1; j < addrs.length; j++) {
                if (participants[addrs[i]].totalReturn < participants[addrs[j]].totalReturn) {
                    address temp = addrs[i];
                    addrs[i] = addrs[j];
                    addrs[j] = temp;
                }
            }
        }
        
        // Store ranked participants and update ranks
        rankedParticipants = new address[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            rankedParticipants[i] = addrs[i];
            participants[addrs[i]].rank = i + 1;
        }
    }
    
    /**
     * @dev Allows a user to claim their reward if they placed in the top 3
     */
    function claimReward() external nonReentrant {
        require(finalized, "Competition not finalized");
        require(participants[msg.sender].hasJoined, "Not a participant");
        require(!participants[msg.sender].hasWithdrawnReward, "Already claimed reward");
        
        uint256 rank = participants[msg.sender].rank;
        require(rank > 0, "Not ranked yet");
        
        uint256 rewardAmount = 0;
        uint256 totalPool = stakeAmount * participantAddresses.length;
        
        // Calculate reward based on rank and total participants
        if (participantAddresses.length == 1) {
            // If only one participant, they get their stake back
            rewardAmount = stakeAmount;
        } else if (participantAddresses.length == 2) {
            // If two participants, winner gets all
            if (rank == 1) {
                rewardAmount = totalPool;
            }
        } else {
            // Normal distribution for 3+ participants
            if (rank == 1) {
                rewardAmount = (totalPool * 50) / 100; // 50% for 1st place
            } else if (rank == 2) {
                rewardAmount = (totalPool * 30) / 100; // 30% for 2nd place
            } else if (rank == 3) {
                rewardAmount = (totalPool * 20) / 100; // 20% for 3rd place
            }
        }
        
        if (rewardAmount > 0) {
            participants[msg.sender].hasWithdrawnReward = true;
            payable(msg.sender).transfer(rewardAmount);
            emit RewardDistributed(msg.sender, rewardAmount);
        }
    }
    
    /**
     * @dev Returns the total number of participants
     * @return uint256 The participant count
     */
    function getParticipantCount() external view returns (uint256) {
        return participantAddresses.length;
    }
    
    /**
     * @dev Returns a user's portfolio details
     * @param user The address of the user
     * @return feedIds The feed IDs of the assets in the portfolio
     * @return allocations The allocations for each asset
     * @return initialPrices The initial prices for each asset
     * @return finalPrices The final prices for each asset
     * @return decimals The number of decimals for each asset
     */
    function getUserPortfolio(address user) external view returns (
        bytes21[] memory feedIds,
        uint8[] memory allocations,
        uint256[] memory initialPrices,
        uint256[] memory finalPrices,
        int8[] memory decimals
    ) {
        require(participants[user].hasJoined, "User not joined");
        
        Participant storage participant = participants[user];
        uint256 assetCount = participant.portfolio.length;
        
        feedIds = new bytes21[](assetCount);
        allocations = new uint8[](assetCount);
        initialPrices = new uint256[](assetCount);
        finalPrices = new uint256[](assetCount);
        decimals = new int8[](assetCount);
        
        for (uint256 i = 0; i < assetCount; i++) {
            feedIds[i] = participant.portfolio[i].feedId;
            allocations[i] = participant.portfolio[i].allocation;
            initialPrices[i] = participant.portfolio[i].initialPrice;
            finalPrices[i] = participant.portfolio[i].finalPrice;
            decimals[i] = participant.portfolio[i].decimals;
        }
    }
    
    /**
     * @dev Returns a user's ranking in the competition
     * @param user The address of the user
     * @return uint256 The user's ranking (0 if not ranked yet)
     */
    function getUserRanking(address user) external view returns (uint256) {
        require(participants[user].hasJoined, "User not joined");
        return participants[user].rank;
    }
    
    /**
     * @dev Returns a user's current portfolio return
     * @param user The address of the user
     * @return int256 The total return in basis points (e.g., 1000 = 10%)
     */
    function getUserReturn(address user) external returns (int256) {
        require(participants[user].hasJoined, "User not joined");
        
        // If competition is finalized, return stored return
        if (finalized) {
            return participants[user].totalReturn;
        }
        
        // If initial prices not recorded yet, return 0
        Participant storage participant = participants[user];
        if (participant.portfolio.length == 0 || participant.portfolio[0].initialPrice == 0) {
            return 0;
        }
        
        // Calculate current return
        int256 totalReturn = 0;
        
        // Prepare an array of feed IDs for the batch request
        bytes21[] memory feedIds = new bytes21[](participant.portfolio.length);
        for (uint256 i = 0; i < participant.portfolio.length; i++) {
            feedIds[i] = participant.portfolio[i].feedId;
        }
        
        // Get all current prices in a single call
        if (feedIds.length > 0) {
            (uint256[] memory currentPrices, , ) = ftsoV2.getFeedsById(feedIds);
            
            // Calculate return for each asset
            for (uint256 i = 0; i < participant.portfolio.length; i++) {
                Asset memory asset = participant.portfolio[i];
                uint256 currentPrice = currentPrices[i];
                
                // Calculate percentage return for this asset (in basis points)
                int256 assetReturn;
                if (currentPrice > asset.initialPrice) {
                    assetReturn = int256(((currentPrice - asset.initialPrice) * 10000) / asset.initialPrice);
                } else {
                    assetReturn = -int256(((asset.initialPrice - currentPrice) * 10000) / asset.initialPrice);
                }
                
                // Weight by allocation
                totalReturn += (assetReturn * int256(uint256(asset.allocation))) / 100;
            }
        }
        
        return totalReturn;
    }
    
    /**
     * @dev Returns the top ranked participants and their returns
     * @return address[] Array of addresses of top ranked participants
     * @return int256[] Array of returns for the top ranked participants
     */
    function getTopRankedParticipants() external view returns (address[] memory, int256[] memory) {
        uint256 count = finalized ? rankedParticipants.length : 0;
        if (count == 0) return (new address[](0), new int256[](0));
        
        if (count > 3) count = 3;
        
        address[] memory topAddrs = new address[](count);
        int256[] memory topReturns = new int256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            topAddrs[i] = rankedParticipants[i];
            topReturns[i] = participants[rankedParticipants[i]].totalReturn;
        }
        
        return (topAddrs, topReturns);
    }
    
    /**
     * @dev Returns detailed information about the competition
     * @return competitionOwner The owner of the competition
     * @return competitionName The name of the competition
     * @return competitionStartDate The start date of the competition
     * @return competitionEndDate The end date of the competition
     * @return competitionStakeAmount The stake amount required to join
     * @return isFinalized Whether the competition is finalized
     * @return participantCount The number of participants
     */
    function getCompetitionInfo() external view returns (
        address competitionOwner,
        string memory competitionName,
        uint256 competitionStartDate,
        uint256 competitionEndDate,
        uint256 competitionStakeAmount,
        bool isFinalized,
        uint256 participantCount
    ) {
        return (
            owner,
            name,
            startDate,
            endDate,
            stakeAmount,
            finalized,
            participantAddresses.length
        );
    }
    
    /**
     * @dev Allows the owner to withdraw any remaining funds after 30 days
     */
    function emergencyWithdraw() external onlyOwner {
        require(finalized, "Competition not finalized");
        require(block.timestamp > endDate + 30 days, "Too early to emergency withdraw");
        
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner).transfer(balance);
        }
    }
}
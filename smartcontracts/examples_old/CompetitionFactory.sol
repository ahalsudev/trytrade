// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Competition.sol";
import "@flarenetwork/flare-periphery-contracts/coston2/ContractRegistry.sol";

/**
 * @title CompetitionFactory
 * @dev Factory contract for creating and tracking Competition instances
 */
contract CompetitionFactory {
    // State variables
    address public owner;
    address[] public competitions;
    mapping(address => bool) public isCompetition;
    
    // User to competitions mapping for efficient querying
    mapping(address => address[]) private userCompetitions;
    
    // Events
    event CompetitionCreated(address indexed creator, address competitionAddress, string name, uint256 startDate, uint256 endDate, uint256 stakeAmount);
    event UserParticipationRegistered(address indexed user, address indexed competitionAddress);
    
    /**
     * @dev Constructor
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Creates a new competition
     * @param name The name of the competition
     * @param startDate The timestamp when the competition starts
     * @param endDate The timestamp when the competition ends
     * @param stakeAmount The amount in C2FLR tokens required to join
     * @return address The address of the newly created competition
     */
    function createCompetition(string memory name, uint256 startDate, uint256 endDate, uint256 stakeAmount) external returns (address) {
        Competition newCompetition = new Competition(
            msg.sender,
            name,
            startDate,
            endDate,
            stakeAmount,
            address(this)  // Pass factory address
        );
        
        address competitionAddress = address(newCompetition);
        competitions.push(competitionAddress);
        isCompetition[competitionAddress] = true;
        
        emit CompetitionCreated(msg.sender, competitionAddress, name, startDate, endDate, stakeAmount);
        return competitionAddress;
    }
    
    /**
     * @dev Register when a user joins a competition
     * @param user The address of the user joining
     * @param competitionAddress The address of the competition being joined
     */
    function registerUserParticipation(address user, address competitionAddress) external {
        require(isCompetition[msg.sender], "Only competitions can register");
        require(msg.sender == competitionAddress, "Sender must be the competition");
        
        userCompetitions[user].push(competitionAddress);
        emit UserParticipationRegistered(user, competitionAddress);
    }
    
    /**
     * @dev Returns all competitions
     * @return address[] Array of all competition addresses
     */
    function getAllCompetitions() external view returns (address[] memory) {
        return competitions;
    }
    
    /**
     * @dev Returns all competitions a user has joined
     * @param user The address of the user
     * @return address[] Array of competition addresses
     */
    function getUserCompetitions(address user) external view returns (address[] memory) {
        return userCompetitions[user];
    }
    
    /**
     * @dev Returns all active competitions (current time between start and end)
     * @return address[] Array of active competition addresses
     */
    function getActiveCompetitions() external view returns (address[] memory) {
        uint256 count = 0;
        
        // First, count active competitions
        for (uint256 i = 0; i < competitions.length; i++) {
            Competition comp = Competition(competitions[i]);
            if (block.timestamp >= comp.startDate() && block.timestamp <= comp.endDate()) {
                count++;
            }
        }
        
        // Then populate the array
        address[] memory activeCompetitions = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < competitions.length; i++) {
            Competition comp = Competition(competitions[i]);
            if (block.timestamp >= comp.startDate() && block.timestamp <= comp.endDate()) {
                activeCompetitions[index] = competitions[i];
                index++;
            }
        }
        
        return activeCompetitions;
    }
    
    /**
     * @dev Returns all upcoming competitions (start date in the future)
     * @return address[] Array of upcoming competition addresses
     */
    function getUpcomingCompetitions() external view returns (address[] memory) {
        uint256 count = 0;
        
        // First, count upcoming competitions
        for (uint256 i = 0; i < competitions.length; i++) {
            Competition comp = Competition(competitions[i]);
            if (block.timestamp < comp.startDate()) {
                count++;
            }
        }
        
        // Then populate the array
        address[] memory upcomingCompetitions = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < competitions.length; i++) {
            Competition comp = Competition(competitions[i]);
            if (block.timestamp < comp.startDate()) {
                upcomingCompetitions[index] = competitions[i];
                index++;
            }
        }
        
        return upcomingCompetitions;
    }
    
    /**
     * @dev Returns all finished competitions (end date has passed)
     * @return address[] Array of finished competition addresses
     */
    function getFinishedCompetitions() external view returns (address[] memory) {
        uint256 count = 0;
        
        // First, count finished competitions
        for (uint256 i = 0; i < competitions.length; i++) {
            Competition comp = Competition(competitions[i]);
            if (block.timestamp > comp.endDate()) {
                count++;
            }
        }
        
        // Then populate the array
        address[] memory finishedCompetitions = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < competitions.length; i++) {
            Competition comp = Competition(competitions[i]);
            if (block.timestamp > comp.endDate()) {
                finishedCompetitions[index] = competitions[i];
                index++;
            }
        }
        
        return finishedCompetitions;
    }
    
    /**
     * @dev Returns active competitions a user has joined
     * @param user The address of the user
     * @return address[] Array of active competition addresses
     */
    function getUserActiveCompetitions(address user) external view returns (address[] memory) {
        address[] memory userComps = userCompetitions[user];
        uint256 count = 0;
        
        // First, count active competitions
        for (uint256 i = 0; i < userComps.length; i++) {
            Competition comp = Competition(userComps[i]);
            if (block.timestamp >= comp.startDate() && block.timestamp <= comp.endDate()) {
                count++;
            }
        }
        
        // Then populate the array
        address[] memory activeCompetitions = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userComps.length; i++) {
            Competition comp = Competition(userComps[i]);
            if (block.timestamp >= comp.startDate() && block.timestamp <= comp.endDate()) {
                activeCompetitions[index] = userComps[i];
                index++;
            }
        }
        
        return activeCompetitions;
    }
    
    /**
     * @dev Returns finished competitions a user has joined
     * @param user The address of the user
     * @return address[] Array of finished competition addresses
     */
    function getUserFinishedCompetitions(address user) external view returns (address[] memory) {
        address[] memory userComps = userCompetitions[user];
        uint256 count = 0;
        
        // First, count finished competitions
        for (uint256 i = 0; i < userComps.length; i++) {
            Competition comp = Competition(userComps[i]);
            if (block.timestamp > comp.endDate()) {
                count++;
            }
        }
        
        // Then populate the array
        address[] memory finishedCompetitions = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < userComps.length; i++) {
            Competition comp = Competition(userComps[i]);
            if (block.timestamp > comp.endDate()) {
                finishedCompetitions[index] = userComps[i];
                index++;
            }
        }
        
        return finishedCompetitions;
    }
    
    /**
     * @dev Returns competitions a user has not joined and that haven't started yet
     * @param user The address of the user
     * @return address[] Array of available competition addresses
     */
    function getAvailableCompetitionsForUser(address user) external view returns (address[] memory) {
        uint256 count = 0;
        
        // First, count available competitions
        for (uint256 i = 0; i < competitions.length; i++) {
            Competition comp = Competition(competitions[i]);
            if (block.timestamp < comp.startDate() && !comp.hasUserJoined(user)) {
                count++;
            }
        }
        
        // Then populate the array
        address[] memory availableCompetitions = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < competitions.length; i++) {
            Competition comp = Competition(competitions[i]);
            if (block.timestamp < comp.startDate() && !comp.hasUserJoined(user)) {
                availableCompetitions[index] = competitions[i];
                index++;
            }
        }
        
        return availableCompetitions;
    }
    
    /**
     * @dev Transfers ownership of the factory
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Not owner");
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
}
/**
 * This file is autogenerated by Scaffold-ETH.
 * You should not edit it manually or your changes might be overwritten.
 */
import { GenericContractsDeclaration } from "~~/utils/scaffold-eth/contract";

const deployedContracts = {
  31337: {
    TryTrade: {
      address: "0xe1aa25618fa0c7a1cfdab5d6b456af611873b629",
      abi: [
        {
          type: "constructor",
          inputs: [
            {
              name: "_priceFeed",
              type: "address",
              internalType: "address",
            },
          ],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "FIRST_PLACE_PERCENTAGE",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "SECOND_PLACE_PERCENTAGE",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "THIRD_PLACE_PERCENTAGE",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "VIRTUAL_UNITS",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "addSupportedToken",
          inputs: [
            {
              name: "_symbol",
              type: "string",
              internalType: "string",
            },
            {
              name: "_contractAddress",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "calculatePortfolioReturn",
          inputs: [
            {
              name: "_leagueId",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "_participant",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "createLeague",
          inputs: [
            {
              name: "_name",
              type: "string",
              internalType: "string",
            },
            {
              name: "_description",
              type: "string",
              internalType: "string",
            },
            {
              name: "_startTime",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "_endTime",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "_entryFee",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "_maxParticipants",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "emergencyWithdraw",
          inputs: [],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "finalizeLeague",
          inputs: [
            {
              name: "_leagueId",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "getCurrentPrice",
          inputs: [
            {
              name: "_asset",
              type: "string",
              internalType: "string",
            },
          ],
          outputs: [
            {
              name: "price",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "timestamp",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getHistoricalPrice",
          inputs: [
            {
              name: "_asset",
              type: "string",
              internalType: "string",
            },
            {
              name: "_timestamp",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "price",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "timestamp",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getLeagueInfo",
          inputs: [
            {
              name: "_leagueId",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "tuple",
              internalType: "struct TryTrade.LeagueInfo",
              components: [
                {
                  name: "leagueId",
                  type: "uint256",
                  internalType: "uint256",
                },
                {
                  name: "creator",
                  type: "address",
                  internalType: "address",
                },
                {
                  name: "name",
                  type: "string",
                  internalType: "string",
                },
                {
                  name: "description",
                  type: "string",
                  internalType: "string",
                },
                {
                  name: "startTime",
                  type: "uint256",
                  internalType: "uint256",
                },
                {
                  name: "endTime",
                  type: "uint256",
                  internalType: "uint256",
                },
                {
                  name: "entryFee",
                  type: "uint256",
                  internalType: "uint256",
                },
                {
                  name: "maxParticipants",
                  type: "uint256",
                  internalType: "uint256",
                },
                {
                  name: "currentParticipants",
                  type: "uint256",
                  internalType: "uint256",
                },
                {
                  name: "prizePool",
                  type: "uint256",
                  internalType: "uint256",
                },
                {
                  name: "isActive",
                  type: "bool",
                  internalType: "bool",
                },
                {
                  name: "isFinalized",
                  type: "bool",
                  internalType: "bool",
                },
              ],
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getLeagueParticipants",
          inputs: [
            {
              name: "_leagueId",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "address[]",
              internalType: "address[]",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getLeagueWinners",
          inputs: [
            {
              name: "_leagueId",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "address[]",
              internalType: "address[]",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getParticipantScore",
          inputs: [
            {
              name: "_leagueId",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "_participant",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getSupportedTokens",
          inputs: [],
          outputs: [
            {
              name: "symbols",
              type: "string[]",
              internalType: "string[]",
            },
            {
              name: "addresses",
              type: "address[]",
              internalType: "address[]",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getTokenInfo",
          inputs: [
            {
              name: "_symbol",
              type: "string",
              internalType: "string",
            },
          ],
          outputs: [
            {
              name: "",
              type: "tuple",
              internalType: "struct TryTrade.Token",
              components: [
                {
                  name: "symbol",
                  type: "string",
                  internalType: "string",
                },
                {
                  name: "contractAddress",
                  type: "address",
                  internalType: "address",
                },
                {
                  name: "isActive",
                  type: "bool",
                  internalType: "bool",
                },
              ],
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getTotalLeagues",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getUserLeagues",
          inputs: [
            {
              name: "_user",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [
            {
              name: "",
              type: "uint256[]",
              internalType: "uint256[]",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getUserPortfolio",
          inputs: [
            {
              name: "_leagueId",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "_user",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [
            {
              name: "tokens",
              type: "string[]",
              internalType: "string[]",
            },
            {
              name: "allocations",
              type: "uint256[]",
              internalType: "uint256[]",
            },
            {
              name: "isSubmitted",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "isTokenSupported",
          inputs: [
            {
              name: "",
              type: "string",
              internalType: "string",
            },
          ],
          outputs: [
            {
              name: "",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "joinLeague",
          inputs: [
            {
              name: "_leagueId",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [],
          stateMutability: "payable",
        },
        {
          type: "function",
          name: "leagues",
          inputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "leagueId",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "creator",
              type: "address",
              internalType: "address",
            },
            {
              name: "name",
              type: "string",
              internalType: "string",
            },
            {
              name: "description",
              type: "string",
              internalType: "string",
            },
            {
              name: "startTime",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "endTime",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "entryFee",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "maxParticipants",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "currentParticipants",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "prizePool",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "isActive",
              type: "bool",
              internalType: "bool",
            },
            {
              name: "isFinalized",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "owner",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "address",
              internalType: "address",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "priceFeed",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "address",
              internalType: "contract IMockPriceFeed",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "removeSupportedToken",
          inputs: [
            {
              name: "_symbol",
              type: "string",
              internalType: "string",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "renounceOwnership",
          inputs: [],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "setPriceFeed",
          inputs: [
            {
              name: "_priceFeed",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "submitPortfolio",
          inputs: [
            {
              name: "_leagueId",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "_tokens",
              type: "string[]",
              internalType: "string[]",
            },
            {
              name: "_allocations",
              type: "uint256[]",
              internalType: "uint256[]",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "supportedTokens",
          inputs: [
            {
              name: "",
              type: "string",
              internalType: "string",
            },
          ],
          outputs: [
            {
              name: "symbol",
              type: "string",
              internalType: "string",
            },
            {
              name: "contractAddress",
              type: "address",
              internalType: "address",
            },
            {
              name: "isActive",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "tokenSymbols",
          inputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "string",
              internalType: "string",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "transferOwnership",
          inputs: [
            {
              name: "newOwner",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "userLeagues",
          inputs: [
            {
              name: "",
              type: "address",
              internalType: "address",
            },
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "event",
          name: "LeagueCreated",
          inputs: [
            {
              name: "leagueId",
              type: "uint256",
              indexed: true,
              internalType: "uint256",
            },
            {
              name: "creator",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "name",
              type: "string",
              indexed: false,
              internalType: "string",
            },
            {
              name: "startTime",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
            {
              name: "endTime",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
            {
              name: "entryFee",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
            {
              name: "maxParticipants",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "LeagueFinalized",
          inputs: [
            {
              name: "leagueId",
              type: "uint256",
              indexed: true,
              internalType: "uint256",
            },
            {
              name: "winners",
              type: "address[]",
              indexed: false,
              internalType: "address[]",
            },
            {
              name: "prizes",
              type: "uint256[]",
              indexed: false,
              internalType: "uint256[]",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "OwnershipTransferred",
          inputs: [
            {
              name: "previousOwner",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "newOwner",
              type: "address",
              indexed: true,
              internalType: "address",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "PlayerJoined",
          inputs: [
            {
              name: "leagueId",
              type: "uint256",
              indexed: true,
              internalType: "uint256",
            },
            {
              name: "player",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "entryFee",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "PortfolioSubmitted",
          inputs: [
            {
              name: "leagueId",
              type: "uint256",
              indexed: true,
              internalType: "uint256",
            },
            {
              name: "player",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "tokens",
              type: "string[]",
              indexed: false,
              internalType: "string[]",
            },
            {
              name: "allocations",
              type: "uint256[]",
              indexed: false,
              internalType: "uint256[]",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "PriceFeedUpdated",
          inputs: [
            {
              name: "oldPriceFeed",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "newPriceFeed",
              type: "address",
              indexed: true,
              internalType: "address",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "PrizeDistributed",
          inputs: [
            {
              name: "leagueId",
              type: "uint256",
              indexed: true,
              internalType: "uint256",
            },
            {
              name: "winner",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "position",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
            {
              name: "amount",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "TokenAdded",
          inputs: [
            {
              name: "symbol",
              type: "string",
              indexed: true,
              internalType: "string",
            },
            {
              name: "contractAddress",
              type: "address",
              indexed: true,
              internalType: "address",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "TokenRemoved",
          inputs: [
            {
              name: "symbol",
              type: "string",
              indexed: true,
              internalType: "string",
            },
          ],
          anonymous: false,
        },
        {
          type: "error",
          name: "OwnableInvalidOwner",
          inputs: [
            {
              name: "owner",
              type: "address",
              internalType: "address",
            },
          ],
        },
        {
          type: "error",
          name: "OwnableUnauthorizedAccount",
          inputs: [
            {
              name: "account",
              type: "address",
              internalType: "address",
            },
          ],
        },
        {
          type: "error",
          name: "ReentrancyGuardReentrantCall",
          inputs: [],
        },
      ],
      inheritedFunctions: {},
      deploymentFile: "run-1753812661.json",
      deploymentScript: "Deploy.s.sol",
    },
  },
} as const;

export default deployedContracts satisfies GenericContractsDeclaration;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/TryTrade.sol";
import "../contracts/Price.sol";

/**
 * @notice Deploy script for TryTrade contracts
 * @dev Inherits ScaffoldETHDeploy which:
 *      - Includes forge-std/Script.sol for deployment
 *      - Includes ScaffoldEthDeployerRunner modifier
 *      - Provides `deployer` variable
 * Example:
 * yarn deploy --file DeployTryTrade.s.sol  # local anvil chain
 * yarn deploy --file DeployTryTrade.s.sol --network sepolia # live network (requires keystore)
 */
contract DeployTryTrade is ScaffoldETHDeploy {
    /**
     * @dev Deployer setup based on `ETH_KEYSTORE_ACCOUNT` in `.env`:
     *      - "scaffold-eth-default": Uses Anvil's account #9 (0xa0Ee7A142d267C1f36714E4a8F75612F20a79720), no password prompt
     *      - "scaffold-eth-custom": requires password used while creating keystore
     *
     * Note: Must use ScaffoldEthDeployerRunner modifier to:
     *      - Setup correct `deployer` account and fund it
     *      - Export contract addresses & ABIs to `nextjs` packages
     */
    function run() external ScaffoldEthDeployerRunner {
        // Deploy Price contract first
        Price priceContract = new Price();
        console.log("Price contract deployed at:", address(priceContract));
        
        // Deploy TryTrade contract with Price contract address
        TryTrade tryTradeContract = new TryTrade(address(priceContract));
        console.log("TryTrade contract deployed at:", address(tryTradeContract));
        
        // Initialize Price contract with sample data for local testing
        if (block.chainid == 31337) { // Only for local anvil chain
            _initializePriceContract(priceContract);
        }
    }
    
    /**
     * @dev Initialize price contract with sample data for local testing
     */
    function _initializePriceContract(Price priceContract) internal {
        // Sample ETH prices (in USD with 8 decimals) - simulating 1 hour intervals
        uint256[] memory ethPrices = new uint256[](24);
        ethPrices[0] = 230000000000; // $2300.00
        ethPrices[1] = 231500000000; // $2315.00
        ethPrices[2] = 229800000000; // $2298.00
        ethPrices[3] = 232100000000; // $2321.00
        ethPrices[4] = 230700000000; // $2307.00
        ethPrices[5] = 233200000000; // $2332.00
        ethPrices[6] = 231900000000; // $2319.00
        ethPrices[7] = 234500000000; // $2345.00
        ethPrices[8] = 232800000000; // $2328.00
        ethPrices[9] = 235100000000; // $2351.00
        ethPrices[10] = 233600000000; // $2336.00
        ethPrices[11] = 236300000000; // $2363.00
        ethPrices[12] = 234900000000; // $2349.00
        ethPrices[13] = 237800000000; // $2378.00
        ethPrices[14] = 236200000000; // $2362.00
        ethPrices[15] = 239100000000; // $2391.00
        ethPrices[16] = 237500000000; // $2375.00
        ethPrices[17] = 240600000000; // $2406.00
        ethPrices[18] = 238900000000; // $2389.00
        ethPrices[19] = 242200000000; // $2422.00
        ethPrices[20] = 240800000000; // $2408.00
        ethPrices[21] = 243700000000; // $2437.00
        ethPrices[22] = 242100000000; // $2421.00
        ethPrices[23] = 245000000000; // $2450.00
        
        // Sample BTC prices (in USD with 8 decimals)
        uint256[] memory btcPrices = new uint256[](24);
        btcPrices[0] = 4300000000000; // $43000.00
        btcPrices[1] = 4315000000000; // $43150.00
        btcPrices[2] = 4298000000000; // $42980.00
        btcPrices[3] = 4332000000000; // $43320.00
        btcPrices[4] = 4307000000000; // $43070.00
        btcPrices[5] = 4345000000000; // $43450.00
        btcPrices[6] = 4329000000000; // $43290.00
        btcPrices[7] = 4358000000000; // $43580.00
        btcPrices[8] = 4341000000000; // $43410.00
        btcPrices[9] = 4372000000000; // $43720.00
        btcPrices[10] = 4356000000000; // $43560.00
        btcPrices[11] = 4385000000000; // $43850.00
        btcPrices[12] = 4368000000000; // $43680.00
        btcPrices[13] = 4399000000000; // $43990.00
        btcPrices[14] = 4381000000000; // $43810.00
        btcPrices[15] = 4412000000000; // $44120.00
        btcPrices[16] = 4394000000000; // $43940.00
        btcPrices[17] = 4426000000000; // $44260.00
        btcPrices[18] = 4408000000000; // $44080.00
        btcPrices[19] = 4441000000000; // $44410.00
        btcPrices[20] = 4423000000000; // $44230.00
        btcPrices[21] = 4456000000000; // $44560.00
        btcPrices[22] = 4438000000000; // $44380.00
        btcPrices[23] = 4470000000000; // $44700.00
        
        // Start timestamp (24 hours ago)
        uint256 startTimestamp = block.timestamp - 24 hours;
        
        // Create price feeds with 1 hour intervals
        priceContract.createPriceFeed(
            "ETH",
            0x694AA1769357215DE4FAC081bf1f309aDC325306, // Sepolia ETH/USD feed
            ethPrices,
            startTimestamp,
            3600, // 1 hour intervals
            8,
            "ETH/USD Price Feed"
        );
        
        priceContract.createPriceFeed(
            "BTC",
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43, // Sepolia BTC/USD feed
            btcPrices,
            startTimestamp,
            3600, // 1 hour intervals
            8,
            "BTC/USD Price Feed"
        );
        
        console.log("Price contract initialized with sample data");
    }
}

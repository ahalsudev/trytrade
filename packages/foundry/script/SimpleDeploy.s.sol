// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../contracts/TryTrade.sol";

contract SimpleDeploy is Script {
    function run() external {
        // Start broadcasting with your private key
        vm.startBroadcast();
        
        // Deploy TryTrade with the Price contract address
        TryTrade tryTradeContract = new TryTrade(0x443CA1D7869c8073Ab5003d2661653044d3b52c9);
        
        console.log("TryTrade deployed at:", address(tryTradeContract));
        
        vm.stopBroadcast();
    }
}
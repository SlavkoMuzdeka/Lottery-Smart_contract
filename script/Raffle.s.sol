// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";

contract RaffleScript is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle({
            entranceFee: networkConfig.entranceFee,
            interval: networkConfig.interval,
            vrfCoordinator: networkConfig.vrfCoordinator,
            keyHash: networkConfig.keyHash,
            subscriptionId: networkConfig.subscriptionId,
            callbackGasLimit: networkConfig.callbackGasLimit
        });
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}

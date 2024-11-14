// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract RaffleScript is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getConfig();

        if (networkConfig.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            uint subId = createSubscription.run(networkConfig.vrfCoordinator);
            networkConfig.subscriptionId = subId;

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.run(
                networkConfig.vrfCoordinator,
                networkConfig.subscriptionId,
                networkConfig.link
            );
        }

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

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.run(
            address(raffle),
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId
        );

        return (raffle, helperConfig);
    }
}

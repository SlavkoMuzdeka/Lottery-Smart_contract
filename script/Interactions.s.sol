// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {CodeConstants} from "./HelperConfig.sol";
import {LinkToken} from "../test/mock/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function run(address vrfCoordinator) external returns (uint) {
        console2.log("Creating subscription on chain Id: ", block.chainid);

        vm.startBroadcast();
        uint subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        console2.log("Your subscription Id is: ", subscriptionId);
        console2.log(
            "Please update you subscription Id in your HelperConfig.s.sol"
        );
        return subscriptionId;
    }
}

contract FundSubscription is Script, CodeConstants {
    uint public constant FUND_AMOUNT = 10 ether;

    function run(
        address vrfCoordinator,
        uint subscriptionId,
        address linkToken
    ) external {
        console2.log("Funding subscription: ", subscriptionId);
        console2.log("Using vrfCoordinator: ", vrfCoordinator);
        console2.log("On Chain Id: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encodePacked(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
    function run(
        address contractToAddToVrf,
        address vrfCoordinator,
        uint subscriptionId
    ) external {
        console2.log("Adding consumer contract: ", contractToAddToVrf);
        console2.log("To vrfCoordinator: ", vrfCoordinator);
        console2.log("On Chain Id: ", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            contractToAddToVrf
        );
        vm.stopBroadcast();
    }
}

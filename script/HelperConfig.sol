// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LinkToken} from "../test/mock/LinkToken.sol";
import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;

    uint96 public constant MOCK_BASE_FEE = 0.00025 ether;
    uint96 public constant MOCK_GAS_PRICE = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
}

contract HelperConfig is Script, CodeConstants {
    /* Errors */
    error HelperConfig__InvalidChainId();

    /* Type declarations */
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        address account;
    }

    /* State variables */
    NetworkConfig public localNetworkConfig;

    /* Functions */
    function getConfig() external returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) private returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateEthAnvilConfig();
        } else if (chainId == ETH_SEPOLIA_CHAIN_ID) {
            return getEthSepliaConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getOrCreateEthAnvilConfig() private returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        console2.log("You have deployed a mock contract!");
        console2.log("Make sure this was intentional");

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mockVrfCoordinator =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE, MOCK_WEI_PER_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.0025 ether,
            interval: 60,
            vrfCoordinator: address(mockVrfCoordinator),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscriptionId: 0,
            link: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 // This is the default address of msg.sender (it is found in forge-std/Base.sol)
        });

        return localNetworkConfig;
    }

    function getEthSepliaConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.0025 ether,
            interval: 60,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscriptionId: 0,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0xA2358D11ABf324976095c7E6cfF07D6B5DE9fA09
        });
    }
}

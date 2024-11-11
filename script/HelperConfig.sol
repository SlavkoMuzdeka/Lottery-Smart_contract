// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    uint public constant LOCAL_CHAIN_ID = 31337;
    uint public constant ETH_SEPOLIA_CHAIN_ID = 11155111;

    uint96 public constant MOCK_BASE_FEE = 0.00025 ether;
    uint96 public constant MOCK_GAS_PRICE = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
}

contract HelperConfig is Script, CodeConstants {
    /* Errors */
    error HelperConfig__InvalidChainId();

    /* Type declarations */
    struct NetworkConfig {
        uint entranceFee;
        uint interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }

    /* State variables */
    NetworkConfig public localNetworkConfig;

    /* Functions */
    function getConfig() external returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(
        uint chainId
    ) private returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateEthAnvilConfig();
        } else if (chainId == ETH_SEPOLIA_CHAIN_ID) {
            return getEthSepliaConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getOrCreateEthAnvilConfig()
        private
        returns (NetworkConfig memory)
    {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        console2.log("You have deployed a mock contract!");
        console2.log("Make sure this was intentional");

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mockVrfCoordinator = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE,
            MOCK_WEI_PER_UNIT_LINK
        );
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.0025 ether,
            interval: 60,
            vrfCoordinator: address(mockVrfCoordinator),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscriptionId: 0 // TODO Fix this
        });

        return localNetworkConfig;
    }

    function getEthSepliaConfig() private pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.0025 ether,
                interval: 60,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 500000,
                subscriptionId: 0
            });
    }
}

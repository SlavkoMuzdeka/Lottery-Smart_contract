// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__RaffleNotOpen();
    error Raffle__TransferFailed();
    error Raffle__TimeHasNotPassed();
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__UpkeepNotNeeded(
        uint balance,
        uint playersLength,
        uint raffleState
    );

    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State variables */
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    uint private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint private immutable i_entranceFee;
    uint private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    address payable[] private s_players;

    /* Events */
    event WinnerPicked(address indexed winner);
    event RaffleEntered(address indexed player);

    /* Constructor */
    constructor(
        uint entranceFee,
        uint interval,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        interval = i_interval;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_subscriptionId = subscriptionId;

        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    /* Functions */
    function enterRaffle() external payable {
        require(msg.value >= i_entranceFee, Raffle__SendMoreToEnterRaffle());
        require(s_raffleState == RaffleState.OPEN, Raffle__RaffleNotOpen());
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function performUpkeep() external returns (uint) {
        (bool upkeepNeeded, ) = checkUpkeep();
        require(
            upkeepNeeded,
            Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint(s_raffleState)
            )
        );

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        return requestId;
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        uint indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_players = new address payable[](0);
        emit WinnerPicked(s_recentWinner);

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        require(success, Raffle__TransferFailed());
    }

    function checkUpkeep() public view returns (bool, bytes memory) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        bool upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "0x");
    }

    /* Get functions */
    function getPlayer(
        uint indexOfPlayer
    ) external view returns (address payable) {
        return s_players[indexOfPlayer];
    }
}

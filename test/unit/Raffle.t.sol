// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {RaffleScript} from "../../script/Raffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.sol";

contract RaffleTest is Test {
    uint public constant STARTING_BALANCE = 100 ether;
    uint public constant ENTERING_BALANCE = 0.25 ether;

    address public USER = makeAddr("user");

    Raffle private raffle;
    HelperConfig helperConfig;

    /* Events */
    event WinnerPicked(address indexed winner);
    event RaffleEntered(address indexed player);

    function setUp() public {
        RaffleScript raffleScript = new RaffleScript();
        (raffle, helperConfig) = raffleScript.run();

        vm.deal(USER, STARTING_BALANCE);
    }

    function testCheckIfRaffleInitalValuesAreSetCorrectly() external {
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getConfig();

        assert(networkConfig.entranceFee == raffle.getEntranceFee());
        assert(networkConfig.interval == raffle.getInterval());
        assert(networkConfig.vrfCoordinator == raffle.getVrfCoordinator());
        assert(networkConfig.keyHash == raffle.getKeyHash());
        assert(networkConfig.subscriptionId == raffle.getSubscriptionId());
        assert(networkConfig.callbackGasLimit == raffle.getCallBackGasLimit());

        assert(Raffle.RaffleState.OPEN == raffle.getRaffleState());
    }

    function testEnterRuffleWithErrorSendMoreToEnterRaffle() external {
        vm.prank(USER);
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    // TODO Test when we try to enter raffle but it is not open

    function testEnterRaffleSuccessfully() external {
        vm.prank(USER);
        vm.expectEmit(true, false, false, false, address(raffle)); // Note, first three parameters are for indexed parameters, four is for not-indexed
        emit RaffleEntered(USER);

        raffle.enterRaffle{value: ENTERING_BALANCE}();
        assert(USER == raffle.getPlayer(0));
    }
}

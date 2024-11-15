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

    /* Constructor */
    function testCheckIfRaffleInitalValuesAreSetCorrectly() external {
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getConfig();

        assert(networkConfig.entranceFee == raffle.getEntranceFee());
        assert(networkConfig.interval == raffle.getInterval());
        assert(networkConfig.vrfCoordinator == raffle.getVrfCoordinator());
        assert(networkConfig.keyHash == raffle.getKeyHash());
        assert(networkConfig.callbackGasLimit == raffle.getCallBackGasLimit());

        assert(Raffle.RaffleState.OPEN == raffle.getRaffleState());
    }

    /* Enter raffle */
    function testEnterRuffleWithErrorSendMoreToEnterRaffle() external {
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() external {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTERING_BALANCE}();

        vm.warp(raffle.getLastTimeStamp() + raffle.getInterval());
        vm.roll(block.number + 1);

        raffle.performUpkeep();

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(USER);
        raffle.enterRaffle{value: ENTERING_BALANCE}();
    }

    function testEnterRaffleSuccessfully() external {
        vm.expectEmit(true, false, false, false, address(raffle)); // Note, first three parameters are for indexed parameters, four is for not-indexed
        emit RaffleEntered(USER);

        vm.prank(USER);
        raffle.enterRaffle{value: ENTERING_BALANCE}();
        assert(address(raffle).balance == ENTERING_BALANCE);
        assert(raffle.getPlayer(0) == USER);
    }

    /* Perform upkeep */
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() external {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTERING_BALANCE}();

        vm.warp(raffle.getLastTimeStamp() + raffle.getInterval());
        vm.roll(block.number + 1);

        raffle.performUpkeep();
    }

    function testPerformUpkeepRevertsBecauseTimeHasNotPassed() external {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTERING_BALANCE}();

        uint currentBalance = ENTERING_BALANCE;
        uint numPlayers = 1;
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep();
    }

    function testPerformUpkeepRevertsBecauseTheBalanceIsNull() external {
        vm.warp(raffle.getLastTimeStamp() + raffle.getInterval());
        vm.roll(block.number + 1);

        uint currentBalance = 0;
        uint numPlayers = 0;
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep();
    }

    function testPerformUpkeepRevertsBecauseRaffleIsNotOpen() external {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTERING_BALANCE}();
        vm.warp(raffle.getLastTimeStamp() + raffle.getInterval());
        vm.roll(block.number + 1);

        raffle.performUpkeep();

        uint currentBalance = ENTERING_BALANCE;
        uint numPlayers = 1;
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep();
    }

    /* Check upkeep */
    function testCheckUpkeepFailsIfTimeHasNotPassed() external {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTERING_BALANCE}();

        (bool upkeepNeeded, ) = raffle.checkUpkeep();
        require(!upkeepNeeded);
    }

    function testCheckUpkeepFailsIfThereIsNoBalance() external {
        vm.warp(raffle.getLastTimeStamp() + raffle.getInterval());
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep();
        require(!upkeepNeeded);
    }

    function testCheckUpkeepFailsIfRaffleIsNotOpen() external {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTERING_BALANCE}();

        vm.warp(raffle.getLastTimeStamp() + raffle.getInterval());
        vm.roll(block.number + 1);

        raffle.performUpkeep();

        (bool upkeepNeeded, ) = raffle.checkUpkeep();
        require(!upkeepNeeded);
    }

    function testCheckUpkeepSuccessfullyExecute() external {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTERING_BALANCE}();

        vm.warp(raffle.getLastTimeStamp() + raffle.getInterval());
        vm.roll(block.number + 1);

        (bool upkeedNeeded, ) = raffle.checkUpkeep();
        require(upkeedNeeded);
    }
}

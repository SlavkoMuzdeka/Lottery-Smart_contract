// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {console2} from "forge-std/console2.sol";
import {RaffleScript} from "../../script/Raffle.s.sol";
import {HelperConfig, CodeConstants} from "../../script/HelperConfig.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, CodeConstants {
    uint public constant STARTING_BALANCE = 100 ether;
    uint public constant ENTERING_BALANCE = 0.25 ether;

    address public USER = makeAddr("user");

    Raffle private raffle;
    HelperConfig helperConfig;

    /* Events */
    event WinnerPicked(address indexed winner);
    event RaffleEntered(address indexed player);

    /* Modifiers */
    modifier raffleEntered() {
        vm.prank(USER);
        raffle.enterRaffle{value: ENTERING_BALANCE}();
        vm.warp(raffle.getLastTimeStamp() + raffle.getInterval());
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

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
    function testEnterRaffleRevertsWithSendMoreToEnterRaffle() external {
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testEnterRaffleRevertsBecauseRaffleIsCalculating()
        external
        raffleEntered
    {
        raffle.performUpkeep();

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(USER);
        raffle.enterRaffle{value: ENTERING_BALANCE}();
    }

    function testEnterRaffleSuccessfullyExecutes() external {
        vm.expectEmit(true, false, false, false, address(raffle)); // Note, first three parameters are for indexed parameters, four is for not-indexed
        emit RaffleEntered(USER);

        vm.prank(USER);
        raffle.enterRaffle{value: ENTERING_BALANCE}();
        assert(address(raffle).balance == ENTERING_BALANCE);
        assert(raffle.getPlayer(0) == USER);
    }

    /* Perform upkeep */
    function testPerformUpkeepSuccessfullyExecutes() external raffleEntered {
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

    function testPerformUpkeepRevertsBecauseRaffleIsNotOpen()
        external
        raffleEntered
    {
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

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        external
        raffleEntered
    {
        vm.recordLogs();
        raffle.performUpkeep();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(uint(requestId) > 0);
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

    function testCheckUpkeepFailsIfRaffleIsNotOpen() external raffleEntered {
        raffle.performUpkeep();

        (bool upkeepNeeded, ) = raffle.checkUpkeep();
        require(!upkeepNeeded);
    }

    function testCheckUpkeepSuccessfullyExecute() external raffleEntered {
        (bool upkeedNeeded, ) = raffle.checkUpkeep();
        require(upkeedNeeded);
    }

    /* Fulfill random words */
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint randomRequestId
    ) external raffleEntered skipFork {
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getConfig();

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(networkConfig.vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        external
        raffleEntered
        skipFork
    {
        address expectedWinner = address(uint160(1));

        for (uint i = 1; i <= 3; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, STARTING_BALANCE);
            raffle.enterRaffle{value: ENTERING_BALANCE}();
        }

        uint startingTimeStamp = raffle.getLastTimeStamp();
        uint winnerStartingBalance = expectedWinner.balance;

        vm.recordLogs();
        raffle.performUpkeep();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(helperConfig.getConfig().vrfCoordinator)
            .fulfillRandomWords(uint(requestId), address(raffle));

        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint winnerEndingBalance = recentWinner.balance;
        uint endingTimeStamp = raffle.getLastTimeStamp();
        uint prize = ENTERING_BALANCE * 4;

        assert(recentWinner == expectedWinner);
        assert(raffleState == Raffle.RaffleState.OPEN);
        assert(winnerEndingBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}

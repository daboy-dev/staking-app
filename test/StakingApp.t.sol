// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingAppTest is Test {
    StakingToken stakingToken;
    StakingApp stakingApp;

    string name = "Staking Token";
    string symbol = "STK";

    address owner = vm.addr(1);
    uint256 stakingPeriod = 1 days;
    uint256 fixedStakingAmount = 10;
    uint256 rewardPerPeriod = 1 ether;
    address randomUser = vm.addr(2);

    function setUp() public {
        stakingToken = new StakingToken(name, symbol);
        stakingApp = new StakingApp(address(stakingToken), owner, stakingPeriod, fixedStakingAmount, rewardPerPeriod);
    }

    function testChangeStakingPeriodAsRandomUser() external {
        vm.startPrank(randomUser);

        uint256 newStakingPeriod = 1 weeks;
        vm.expectRevert();
        stakingApp.changeStakingPeriod(newStakingPeriod);

        vm.stopPrank();
    }

    function testChangeStakingPeriodAsOwner() external {
        vm.startPrank(owner);

        uint256 beforeStakingPeriod = stakingApp.stakingPeriod();
        uint256 newStakingPeriod = 1 weeks;
        stakingApp.changeStakingPeriod(newStakingPeriod);
        uint256 currentStakingPeriod = stakingApp.stakingPeriod();

        assertNotEq(beforeStakingPeriod, newStakingPeriod);
        assertEq(currentStakingPeriod, newStakingPeriod);

        vm.stopPrank();
    }

    function testContractReceivesEther() external {
        vm.startPrank(owner);
        vm.deal(owner, 1 ether);

        uint256 etherToReceive = 1 ether;
        uint256 beforeBalance = address(stakingApp).balance;

        (bool success,) = address(stakingApp).call{ value: etherToReceive }("");
        uint256 afterBalance = address(stakingApp).balance;

        assertTrue(success);
        assertEq(afterBalance - beforeBalance, etherToReceive);

        vm.stopPrank();
    }

    function testIncorrectAmountShouldRevert() external {
        vm.startPrank(randomUser);

        vm.expectRevert("Incorrect amount");
        stakingApp.depositTokens(5);

        vm.stopPrank();
    }

    function testDepositTokensCorrectly() external {
        vm.startPrank(randomUser);

        uint256 amount = stakingApp.fixedStakingAmount();
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        uint256 claimTimestampBefore = stakingApp.claimTimestamp(randomUser);
        _depositTokens(amount);

        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 claimTimestampAfter = stakingApp.claimTimestamp(randomUser);

        assertEq(userBalanceAfter - userBalanceBefore, amount);
        assertEq(claimTimestampBefore, 0);
        assertEq(claimTimestampAfter, block.timestamp);

        vm.stopPrank();
    }

    function testCanNotDepositTwice() external {
        vm.startPrank(randomUser);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        uint256 claimTimestampBefore = stakingApp.claimTimestamp(randomUser);
        uint256 amount = stakingApp.fixedStakingAmount();
        _depositTokens(amount);

        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 claimTimestampAfter = stakingApp.claimTimestamp(randomUser);

        assertEq(userBalanceAfter - userBalanceBefore, amount);
        assertEq(claimTimestampBefore, 0);
        assertEq(claimTimestampAfter, block.timestamp);


        stakingToken.mint(amount);
        vm.expectRevert("User already deposited");
        stakingApp.depositTokens(amount);

        vm.stopPrank();
    }

    function testCanNotWithdrawIfNotStaking() external {
        vm.startPrank(randomUser);

        vm.expectRevert("You haven't deposited yet");
        stakingApp.withdrawTokens();

        vm.stopPrank();
    }


    function testWithdrawTokensCorrectly() external {
        vm.startPrank(randomUser);

        uint256 amount = stakingApp.fixedStakingAmount();
        _depositTokens(amount);

        uint256 balanceBeforeWithdraw = IERC20(stakingToken).balanceOf(randomUser);
        stakingApp.withdrawTokens();
        uint256 balanceAfterWithdraw = IERC20(stakingToken).balanceOf(randomUser);

        assertEq(balanceAfterWithdraw - balanceBeforeWithdraw, amount);
        assertEq(stakingApp.userBalance(randomUser), 0);

        vm.stopPrank();
    }

    function testCanNotClaimIfNotStaking() external {
        vm.startPrank(randomUser);

        vm.expectRevert("You haven't deposited yet");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    function testCanNotClaimIfNotElapsedTime() external {
        vm.startPrank(randomUser);

        uint256 amount = stakingApp.fixedStakingAmount();
        _depositTokens(amount);

        vm.expectRevert("Need to wait!");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    function testShouldRevertClaimIfNoEther() external {
        vm.startPrank(randomUser);

        uint256 amount = stakingApp.fixedStakingAmount();
        stakingToken.mint(amount);
        IERC20(stakingToken).approve(address(stakingApp), amount);
        stakingApp.depositTokens(amount);

        vm.warp(block.timestamp + stakingApp.stakingPeriod());

        vm.expectRevert("Transfer failed");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    function testCanClaimRewardsCorrectly() external {
        vm.startPrank(randomUser);

        uint256 amount = stakingApp.fixedStakingAmount();
        _depositTokens(amount);

        vm.warp(block.timestamp + stakingApp.stakingPeriod());

        vm.stopPrank();
        vm.startPrank(owner);
        uint256 etherAmount = 100000 ether;
        vm.deal(owner, etherAmount);
        (bool success,) = address(stakingApp).call{ value: etherAmount }("");
        assertTrue(success);
        vm.stopPrank();
        vm.startPrank(randomUser);

        uint256 userBalanceBefore = address(randomUser).balance;
        stakingApp.claimRewards();
        uint256 userBalanceAfter = address(randomUser).balance;
        uint256 elapsedPeriodAfter = stakingApp.claimTimestamp(randomUser);

        assertEq(userBalanceAfter - userBalanceBefore, rewardPerPeriod);
        assertEq(elapsedPeriodAfter, block.timestamp);

        vm.stopPrank();
    }

    function _depositTokens(uint256 amount) internal {
        stakingToken.mint(amount);
        IERC20(stakingToken).approve(address(stakingApp), amount);
        stakingApp.depositTokens(amount);
    }

}
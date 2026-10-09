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

}
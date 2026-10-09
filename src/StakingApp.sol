// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingApp is Ownable {
    address public stakingToken;
    uint256 public stakingPeriod;
    uint256 public fixedStakingAmount;
    uint256 public rewardPerPeriod;
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public claimTimestamp;

    event ChangeStakingPeriod(uint256 newPeriod);
    event DepositTokens(address userAddress, uint256 amount);
    event WithdrawTokens(address userAddress, uint256 amount);
    event EtherReceived(uint256 amount);

    constructor(address stakingToken_, address owner_ , uint256 stakingPeriod_, uint256 fixedStakingAmount_, uint256 rewardPerPeriod_) Ownable(owner_) {
        stakingToken = stakingToken_;
        stakingPeriod = stakingPeriod_;
        fixedStakingAmount = fixedStakingAmount_;
        rewardPerPeriod = rewardPerPeriod_;
    }

    function depositTokens(uint256 amount) external {
        require(amount == fixedStakingAmount, "Incorrect amount");
        require(userBalance[msg.sender] == 0, "User already deposited");

        IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
        userBalance[msg.sender] += amount;
        claimTimestamp[msg.sender] = block.timestamp;

        emit DepositTokens(msg.sender, amount);
    }

    function withdrawTokens() external {
        require(userBalance[msg.sender] == fixedStakingAmount, "You haven't deposited yet");

        uint256 currentBalance = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        IERC20(stakingToken).transfer(msg.sender, currentBalance);

        emit WithdrawTokens(msg.sender, fixedStakingAmount);
    }

    function claimRewards() external {
        require(userBalance[msg.sender] == fixedStakingAmount, "You haven't deposited yet");

        uint256 elapsedTime = block.timestamp - claimTimestamp[msg.sender];
        require(elapsedTime >= stakingPeriod, "Need to wait!");

        claimTimestamp[msg.sender] = block.timestamp;

        (bool success,) = msg.sender.call{value: rewardPerPeriod}("");
        require(success, "Transfer failed");
    }

    receive() external payable onlyOwner {
        emit EtherReceived(msg.value);
    }

    function changeStakingPeriod(uint256 newPeriod_) external onlyOwner {
        stakingPeriod = newPeriod_;
        emit ChangeStakingPeriod(newPeriod_);
    }

}
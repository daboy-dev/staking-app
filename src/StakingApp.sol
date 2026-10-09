// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingApp is Ownable {
    address public stakingToken;
    uint256 public stakePeriod;
    uint256 public fixedStakingAmount;
    mapping(address => uint256) public userBalance;

    event ChangeStakingPeriod(uint256 newPeriod);
    event DepositTokens(address userAddress, uint256 amount);

    constructor(address stakingToken_, address owner_ , uint256 stakePeriod_, uint256 fixedStakingAmount_) Ownable(owner_) {
        stakingToken = stakingToken_;
        stakePeriod = stakePeriod_;
        fixedStakingAmount = fixedStakingAmount_;
    }

    function depositTokens(uint256 amount) external {
        require(amount == fixedStakingAmount, "Incorrect amount");
        require(userBalance[msg.sender] == 0, "User already deposited");

        IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
        userBalance[msg.sender] += amount;

        emit DepositTokens(msg.sender, amount);
    }

    function changeStakingPeriod(uint256 newPeriod_) external onlyOwner {
        stakePeriod = newPeriod_;
        emit ChangeStakingPeriod(newPeriod_);
    }

}
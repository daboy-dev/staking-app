// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title StakingApp
/// @notice Lets users stake a fixed amount of an ERC20 token and periodically claim ETH rewards.
/// @dev The owner funds the contract with ETH (used for rewards) and can change the staking period.
contract StakingApp is Ownable {
    /// @notice ERC20 token accepted for staking.
    address public stakingToken;
    /// @notice Minimum time, in seconds, that must pass between reward claims.
    uint256 public stakingPeriod;
    /// @notice Exact amount of tokens each user must stake.
    uint256 public fixedStakingAmount;
    /// @notice Amount of ETH (in wei) paid out per claim.
    uint256 public rewardPerPeriod;
    /// @notice Amount of tokens currently staked by each user.
    mapping(address => uint256) public userBalance;
    /// @notice Timestamp of each users last deposit or reward claim.
    mapping(address => uint256) public claimTimestamp;

    /// @notice Emitted when the owner changes the staking period.
    /// @param newPeriod The new staking period, in seconds.
    event ChangeStakingPeriod(uint256 newPeriod);
    /// @notice Emitted when a user stakes tokens.
    /// @param userAddress The staker.
    /// @param amount The amount of tokens staked.
    event DepositTokens(address userAddress, uint256 amount);
    /// @notice Emitted when a user withdraws their staked tokens.
    /// @param userAddress The staker.
    /// @param amount The amount of tokens withdrawn.
    event WithdrawTokens(address userAddress, uint256 amount);
    /// @notice Emitted when the owner sends ETH to the contract.
    /// @param amount The amount of ETH received, in wei.
    event EtherReceived(uint256 amount);

    /// @param stakingToken_ Address of the ERC20 token used for staking.
    /// @param owner_ Address that will own the contract.
    /// @param stakingPeriod_ Time, in seconds, between reward claims.
    /// @param fixedStakingAmount_ Exact amount of tokens each user must stake.
    /// @param rewardPerPeriod_ ETH (in wei) paid per claim.
    constructor(
        address stakingToken_,
        address owner_,
        uint256 stakingPeriod_,
        uint256 fixedStakingAmount_,
        uint256 rewardPerPeriod_
    ) Ownable(owner_) {
        stakingToken = stakingToken_;
        stakingPeriod = stakingPeriod_;
        fixedStakingAmount = fixedStakingAmount_;
        rewardPerPeriod = rewardPerPeriod_;
    }

    /// @notice Stakes the fixed amount of tokens and starts the reward timer.
    /// @dev Requires prior ERC20 approval for this contract. Each user can only have one active deposit.
    /// @param amount Amount of tokens to stake (should be the same as fixedStakingAmount).
    function depositTokens(uint256 amount) external {
        require(amount == fixedStakingAmount, "Incorrect amount");
        require(userBalance[msg.sender] == 0, "User already deposited");

        IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
        userBalance[msg.sender] += amount;
        claimTimestamp[msg.sender] = block.timestamp;

        emit DepositTokens(msg.sender, amount);
    }

    /// @notice Withdraws the caller's entire staked amount.
    /// @dev Reverts if the caller has no active deposit. Does not claim pending rewards.
    function withdrawTokens() external {
        require(userBalance[msg.sender] == fixedStakingAmount, "You haven't deposited yet");

        uint256 currentBalance = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        IERC20(stakingToken).transfer(msg.sender, currentBalance);

        emit WithdrawTokens(msg.sender, fixedStakingAmount);
    }

    /// @notice Claims the ETH reward once `stakingPeriod` has elapsed since the last deposit or claim.
    /// @dev Resets the claim timer before sending ETH. Reverts if the contract lacks enough ETH.
    function claimRewards() external {
        require(userBalance[msg.sender] == fixedStakingAmount, "You haven't deposited yet");

        uint256 elapsedTime = block.timestamp - claimTimestamp[msg.sender];
        require(elapsedTime >= stakingPeriod, "Need to wait!");

        claimTimestamp[msg.sender] = block.timestamp;

        (bool success,) = msg.sender.call{value: rewardPerPeriod}("");
        require(success, "Transfer failed");
    }

    /// @notice Lets the owner fund the contract with ETH for rewards.
    /// @dev Reverts if called by anyone other than the owner.
    receive() external payable onlyOwner {
        emit EtherReceived(msg.value);
    }

    /// @notice Updates the time required between reward claims.
    /// @dev Only callable by the owner.
    /// @param newPeriod_ New staking period, in seconds.
    function changeStakingPeriod(uint256 newPeriod_) external onlyOwner {
        stakingPeriod = newPeriod_;
        emit ChangeStakingPeriod(newPeriod_);
    }
}

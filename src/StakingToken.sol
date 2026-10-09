// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title StakingToken
/// @notice Simple ERC20 token used for staking in StakingApp.
/// @dev Anyone can mint; intended for testing and educational purposes only.
contract StakingToken is ERC20 {
    /// @param name_ Name of the token.
    /// @param symbol_ Symbol of the token.
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /// @notice Mints tokens to the caller.
    /// @param amount Amount of tokens to mint, in the token's smallest unit.
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
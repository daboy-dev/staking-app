# Staking App

A simple staking dApp built with Foundry as part of Blockchain Accelerator academy.

Users stake a fixed amount of an ERC20 token and, after each staking period, can claim an ETH reward. The owner funds the contract with ETH and can adjust the staking period.

This is an educational project. It has not been audited and is not intended for production use.

## Contracts

### `StakingToken`

A minimal ERC20 token (OpenZeppelin) used as the staking asset.

| Function | Description |
| --- | --- |
| `mint(uint256 amount)` | Mints `amount` tokens to the caller. Open to anyone (testing purposes only). |

### `StakingApp`

| Function | Access | Description |
| --- | --- | --- |
| `depositTokens(uint256 amount)` | Anyone | Stakes exactly `fixedStakingAmount` tokens. One active deposit per user. Requires prior ERC20 approval. |
| `withdrawTokens()` | Staker | Withdraws the full staked amount. Does not claim pending rewards. |
| `claimRewards()` | Staker | Sends `rewardPerPeriod` ETH once `stakingPeriod` has elapsed since the last deposit or claim. |
| `changeStakingPeriod(uint256 newPeriod)` | Owner | Updates the time required between claims. |
| `receive()` | Owner | Lets the owner fund the contract with ETH for rewards. |

Constructor parameters:

| Parameter | Description |
| --- | --- |
| `stakingToken_` | Address of the ERC20 token accepted for staking. |
| `owner_` | Address that owns the contract. |
| `stakingPeriod_` | Seconds between reward claims. |
| `fixedStakingAmount_` | Exact amount of tokens each user must stake. |
| `rewardPerPeriod_` | ETH (in wei) paid per claim. |

### Flow

1. The owner deploys `StakingToken` and `StakingApp`, then funds `StakingApp` with ETH.
2. A user mints tokens, approves `StakingApp`, and calls `depositTokens`.
3. After `stakingPeriod` seconds, the user calls `claimRewards` (repeatable each period).
4. The user calls `withdrawTokens` to get the staked tokens back.

## Getting started

### Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Install

```shell
git clone --recurse-submodules git@github.com:daboy-dev/staking-app.git
cd staking-app
```

If you already cloned the repository without submodules:

```shell
git submodule update --init --recursive
```

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Coverage

```shell
forge coverage
```

Current coverage is 100% of lines, statements, branches and functions for both contracts.

## Project structure

```
src/
  StakingApp.sol      # Staking logic and ETH rewards
  StakingToken.sol    # ERC20 staking token
test/
  StakingApp.t.sol
  StakingToken.t.sol
lib/
  forge-std/
  openzeppelin-contracts/
```

## CI

GitHub Actions runs `forge fmt --check`, `forge build` and `forge test` on every push and pull request (see [.github/workflows/test.yml](.github/workflows/test.yml)).

## License

[MIT](LICENSE)

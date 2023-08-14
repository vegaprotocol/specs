# Rewards Vesting Specification

## Summary

The aim of the rewards vesting mechanics is to prevent farming rewards by delaying the payout of rewards through vesting. To encourage longer term behaviour parties can accelerate their rewards vesting rate through the [activity streak program](./0086-ASPR-activity_streak_program.md).

## Network Parameters

- `rewards.vesting.baseRate`: the proportion of rewards in a vesting account which are vested each epoch, value defaults to `0.1` and must be a float strictly greater than 0.
- `rewards.vesting.minimumTransfer`: the minimum amount (expressed in quantum) which can be vested each epoch, value defaults to 100 and must be an integer greater or equal than `0`.
- `rewards.vesting.rewardPayoutTiers`: is an ordered list of dictionaries defining the requirements and multipliers for each tier.

## Vesting mechanics

As detailed in [distributing rewards](./0056-REWA-rewards_overview.md#distributing-rewards-amongst-entities), each party has their rewards paid into vesting rewards accounts (one for each asset).

At the end of each epoch, a proportion of the rewards accumulated in each "vesting" account should be released and transferred to the respective "vested" account. The percentage released can be scaled by the account owner increasing their [activity streak](./0086-ASPR-activity_streak_program.md) and a minimum transfer amount will be applied to ensure the account is eventually emptied. The proportion released and minimum applied are controlled for parameters for the asset.

Now, let:

- $T$ be the amount to be "vested" (transferred from the vesting account to the vested account)
- $B_{vested}$ be the total quantum amount in the vesting account
- $r$ be the network parameter `rewards.vesting.baseRate`
- $a$ be the account owners current [`activity_streak_vesting_multiplier`](./0086-ASPR-activity_streak_program.md#setting-activity-benefits)
- $m$ be the network parameter `rewards.vesting.minimumTransfer`

The quantum amount to be transferred from each "vesting" account to the relevant "vested" account is defined as:

$$T = max(B_{vesting} * r * a, m)$$

When transferring funds from the vesting account to the vested account, a new transfer type should be used, `TRANSFER_TYPE_REWARDS_VESTED`.

## Rewards bonus multiplier

Once vested rewards are transferred to the vested account, the party will be able to transfer funds to their general account using a normal transfer.

Alternatively, they can leave their rewards in the vested account to increase their total rewards balance and receive a multiplier on their reward payout share. The size of this multiplier is dependent on their total rewards balance, i.e. the sum of the parties locked rewards, vesting rewards and vested rewards. Note, funds removed from the vested account are not included in this total.

Note, a party will be unable to transfer funds in to the vested account.

### Determining the rewards bonus multiplier

Before [distributing rewards](./0056-REWA-rewards_overview.md#distributing-rewards-amongst-entities), each parties `reward_distribution_bonus_multiplier` should be set according to the highest tier they qualify for.

```pseudo
Given:
    rewards.vesting.benefitTiers: [
        [
            {"minimum_quantum_balance": 10000, "reward_multiplier": 1.0},
            {"minimum_quantum_balance": 100000, "reward_multiplier": 5.0},
            {"minimum_quantum_balance": 1000000, "reward_multiplier": 10.0},
        ],
    ]

And:
    locked_quantum_amount=2
    vesting_quantum_amount=999
    vested_quantum_amount=99000

Then:
    reward_distribution_bonus_multiplier=5.0
```

## APIs

### Accounts API

Must expose the following:

- every account with `ACCOUNT_TYPE_VESTING_REWARDS` for each party
- every account with `ACCOUNT_TYPE_VESTED_REWARDS` for each party

### Ledger Entries API

Must expose the following:

- every transfer with `TRANSFER_TYPE_REWARDS_VESTED` for each party

## Acceptance Criteria

WIP

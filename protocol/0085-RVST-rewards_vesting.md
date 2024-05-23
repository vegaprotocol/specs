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
When transferring funds from a vested account to the general account held by their key a party will incur no transfer fees and if transferring the full balance they will not be subject to the minimum quantum transfer amount.

Alternatively, they can leave their rewards in the vested account to increase their total rewards balance and receive a multiplier on their reward payout share. The size of this multiplier is dependent on their total rewards balance, i.e. the sum of the parties locked rewards, vesting rewards and vested rewards. Note, funds removed from the vested account are not included in this total.

Note, a party will be unable to transfer funds in to the vested account.

### Clarification for AMM sub accounts

For a party which has created one or more AMMs, any rewards earned by those AMMs will be paid into the relevant vesting account of the sub-key associated with that AMM (and then vested over time into the sub-keys vested account). When calculating the rewards balance used to set the multiplier in this case, the balance of each of a parties sub-keys vesting and vested accounts should be aggregated, and the resulting rewards multiplier set for all sub-keys.

For example:

```pseudo
- A party has accumulated the following rewards
    - locked_quantum_amount = 20
    - vesting_quantum_amount = 30
    - vested_quantum_amount = 150

- And has created an AMM which has accumulated the following rewards
    - locked_quantum_amount = 200
    - vesting_quantum_amount = 300
    - vested_quantum_amount = 1500

Their total reward balance should be (20+30+50) + (200+300+500) = (100) + (1000) = 1100
```

A party will be able to rewards earned by an AMM sub-key by submitting a transfer transaction signed with their primary key. This transfer must be from the sub-keys vested account and to the primary keys general account. As with the mechanics for redeeming rewards normally from a primary key's general account, these transfers will not incur any fees and if transferring the full balance will not be subject to the minimum quantum transfer amount requirement.

Note, as with normal redemptions, once the rewards are transferred from the sub-keys vested account, the funds will no longer contribute to the total reward balance.

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

### Network parameters

1. When `rewards.vesting.baseTransfer` is updated, the new value should be applied to rewards vesting at the end of the current epoch. (<a name="0085-RVST-001" href="#0085-RVST-001">0085-RVST-001</a>)
1. When `rewards.vesting.minimumTransfer` is updated, the new value should be applied to rewards vesting at the end of the current epoch. (<a name="0085-RVST-002" href="#0085-RVST-002">0085-RVST-002</a>)
1. When `rewards.vesting.rewardPayoutTiers` is updated, the new value should be applied when distributing rewards at the end of the current epoch. (<a name="0085-RVST-003" href="#0085-RVST-003">0085-RVST-003</a>)

### Vesting / vested accounts

1. A party should have one vesting account per asset. Rewards distributed from reward pools should be transferred to the correct vesting account. (<a name="0085-RVST-004" href="#0085-RVST-004">0085-RVST-004</a>)
1. A party should have one vested account per asset. Rewards distributed from vesting accounts should be transferred to the correct vested account. (<a name="0085-RVST-005" href="#0085-RVST-005">0085-RVST-005</a>)
1. Funds **cannot** be transferred from a vesting account by a user. (<a name="0085-RVST-006" href="#0085-RVST-006">0085-RVST-006</a>)
1. Funds **can** be transferred from a vested account by a user. (<a name="0085-RVST-007" href="#0085-RVST-007">0085-RVST-007</a>)
1. Funds **cannot** be transferred to a vested account by a user. (<a name="0085-RVST-008" href="#0085-RVST-008">0085-RVST-008</a>)

### Vesting mechanics

1. If a party has unlocked rewards in a vesting account (expressed in quantum) strictly greater than the network parameter `rewards.vesting.minimumTransfer` then rewards should be transferred to the respective vested account for the asset at the end of the epoch as per the formula defined in the specification. (<a name="0085-RVST-009" href="#0085-RVST-009">0085-RVST-009</a>)
1. If a party has unlocked rewards in a vesting account (expressed in quantum) less than or equal to the network parameter `rewards.vesting.minimumTransfer` then the entire balance should be transferred to the respective vested account for the asset at the end of the epoch. (<a name="0085-RVST-010" href="#0085-RVST-010">0085-RVST-010</a>)
1. Locked rewards in the vesting account should not start vesting un till the lock period has expired. (<a name="0085-RVST-011" href="#0085-RVST-011">0085-RVST-011</a>)

### Rewards bonus multiplier

1. A parties `reward_distribution_bonus_multiplier` should be set equal to the value in the highest tier where they fulfil the `minimum_quantum_balance` required. (<a name="0085-RVST-012" href="#0085-RVST-012">0085-RVST-012</a>)
1. Funds in both the parties vesting account and vested account should contribute to their `minimum_quantum_balance`. (<a name="0085-RVST-013" href="#0085-RVST-013">0085-RVST-013</a>)
1. Assuming all parties perform equally, a party with a greater `reward_distribution_bonus_multiplier` should receive a larger share of a reward pool. (<a name="0085-RVST-014" href="#0085-RVST-014">0085-RVST-014</a>)


### Contributions from AMM sub-keys

- Given a party with multiple AMM subkeys, each of the subkeys locked rewards should contribute to the parties total quantum balance. (<a name="0085-RVST-015" href="#0085-RVST-015">0085-RVST-015</a>)
- Given a party with multiple AMM subkeys, each of the subkeys vesting rewards should contribute to the parties total quantum balance. (<a name="0085-RVST-016" href="#0085-RVST-016">0085-RVST-016</a>)
- Given a party with multiple AMM subkeys, each of the subkeys vested rewards should contribute to the parties total quantum balance. (<a name="0085-RVST-017" href="#0085-RVST-017">0085-RVST-017</a>)
- Given a party with multiple AMM subkeys, redeemed rewards should not contribute to the parties total quantum balance. (<a name="0085-RVST-018" href="#0085-RVST-018">0085-RVST-018</a>)
- Given a party with multiple AMM subkeys each earning rewards in assets using different quantums, contributions from each subkey should be scaled correctly by the assets quantum. (<a name="0085-RVST-019" href="#0085-RVST-019">0085-RVST-019</a>)

- Given a party with multiple AMM subkeys, the parties `reward_distribution_bonus_multiplier` should be set equal to the value in the highest tier where they fulfil the `minimum_quantum_balance` required. This multiplier must also be given to each of the parties subkeys and applied for future rewards. (<a name="0085-RVST-020" href="#0085-RVST-020">0085-RVST-020</a>)

### Redemptions from AMM sub-keys

- A party attempting to transfer funds from an AMM sub-key's vested account will be rejected if the party does not own the sub-key. (<a name="0085-RVST-021" href="#0085-RVST-021">0085-RVST-021</a>)
- A party attempting to transfer funds from an AMM sub-key's vested account will be accepted if the party owns the sub-key. (<a name="0085-RVST-022" href="#0085-RVST-022">0085-RVST-022</a>)

- Given a party owns the relevant sub-key, attempting to transfer funds into the sub-key's vesting account will be rejected. (<a name="0085-RVST-023" href="#0085-RVST-023">0085-RVST-023</a>)
- Given a party owns the relevant sub-key, attempting to transfer funds into the sub-key's vested account will be rejected. (<a name="0085-RVST-024" href="#0085-RVST-024">0085-RVST-024</a>)
- Given a party owns the relevant sub-key, attempting to transfer funds from the sub-key's vested account to any account other than the parties general account will be rejected. (<a name="0085-RVST-025" href="#0085-RVST-025">0085-RVST-025</a>)

- Given a non-zero transfer fee factor, a party redeeming funds from an appropriate sub-key's vested account will incur no fees. (<a name="0085-RVST-026" href="#0085-RVST-026">0085-RVST-026</a>)
- A party redeeming funds will not be subject to the minimum transfer requirement if transferring the full balance. The transfer should be accepted. (<a name="0085-RVST-027" href="#0085-RVST-027">0085-RVST-027</a>)
- A party redeeming funds will be subject to the minimum transfer requirement if transferring less than the full balance. The transfer should be rejected. (<a name="0085-RVST-028" href="#0085-RVST-028">0085-RVST-028</a>)

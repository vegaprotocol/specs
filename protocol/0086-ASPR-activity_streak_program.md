# Activity Streak Program

The purpose of the activity streak program is to reward loyal, active traders with the following tiered benefits:

- a greater share of rewards schemes
- an accelerated vesting rate on locked rewards

Parties access higher tiers and greater benefits by maintaining an activity streak. The length of a streak is measured in epochs and a party is considered active if they made a trade or held an open position during the epoch. If a party is inactive for more than a specified number of epochs they lose their streak.

## Network parameters

- `rewards.activityStreak.benefitTiers`: is an ordered list of dictionaries defining the requirements and benefits for each tier.
- `rewards.activityStreak.inactivityLimit`: the maximum number of epochs a trader can be inactive before loosing their streak.
- `rewards.activityStreak.minQuantumOpenNotionalVolume`: the minimum open notional volume (expressed in quantum) for a trader to be considered active in an epoch
- `rewards.activityStreak.minQuantumTradeVolume`: the minimum trade volume (expressed in quantum) for a trader to be considered active in an epoch


## Governance proposals

The network parameter [`rewards.activityStreak.benefitTiers`](#network-parameters) can be updated via a `UpdateNetworkParameter` governance proposal. Each tier in the ordered list must have the following fields:

- `minimum_activity_streak`: int greater or equal to `0` defining the minimum activity streak a party must have to access this tier
- `reward_multiplier`: float greater or equal to `1` defining the factor to scale a parties [reward shares](./0056-REWA-rewards_overview.md#distributing-rewards-amongst-entities) by
- `vesting_multiplier`: float greater or equal to `1` defining the factor to scale a parties [base vesting rate](./0085-RVST-rewards_vesting.md#vesting-mechanics) by

*Example:*

```proto
message UpdateNetworkParameter{
    changes: NetworkParameter{
        key: "rewards.activityStreak.benefitTiers",
        value: [
            {"minimum_activity_streak": 1, "reward_multiplier": 1.0, "vesting_multiplier": 1.05},
            {"minimum_activity_streak": 7, "reward_multiplier": 5.0, "vesting_multiplier": 1.25},
            {"minimum_activity_streak": 31, "reward_multiplier": 10.0, "vesting_multiplier": 1.50},
            {"minimum_activity_streak": 365, "reward_multiplier": 20.0, "vesting_multiplier": 2.00},

        ],
    }
}
```

## Activity streak mechanics

The following steps should occur **before** rewards are [distributed] and [vested].

### Setting activity / inactivity streak

For the feature, the network must track each parties "activity streak". At the end of an epoch:

- if a party was "active" in the epoch

  - increment their `activity_streak` by `1`
  - reset their `inactivity_streak` to `0`.

- if a party was "inactive" in the epoch

  - increment their `inactivity_streak` streak by `1`
  - if their `inactivity_streak` is greater than or equal to the `rewards.activityStreak.inactivityLimit`, reset their `activity_streak` to `0`.

A party is defined as active if they fulfil **either** of the following criteria:

- their open interest was strictly greater than `rewards.activityStreak.minQuantumOpenNotionalVolume` at any point in the epoch
- their total trade volume was strictly greater than `rewards.activityStreak.minQuantumTradeVolume` at the end of the epoch

### Setting activity benefits

After determining a parties "activity streak" there `reward_distribution_activity_multiplier` and `reward_vesting_activity_multiplier` should be set according to the highest tier they qualify for.

```pseudo
Given:
    rewards.activityStreak.benefitTiers: [
        [
            {"minimum_activity_streak": 1, "reward_multiplier": 1.0, "vesting_multiplier": 1.05},
            {"minimum_activity_streak": 7, "reward_multiplier": 5.0, "vesting_multiplier": 1.25},
            {"minimum_activity_streak": 31, "reward_multiplier": 10.0, "vesting_multiplier": 1.50},
            {"minimum_activity_streak": 365, "reward_multiplier": 20.0, "vesting_multiplier": 2.00},

        ],
    ]

And:
    activity_streak=48
    inactivity_streak=3

Then:
    reward_distribution_activity_multiplier=10.0
    reward_vesting_activity_multiplier=1.50
```

### Applying activity benefits

#### Applying the activity reward multiplier

The `activity_streak_reward_multiplier` scales the parties [reward share](./0056-REWA-rewards_overview.md#distributing-rewards-amongs-entities) for all rewards they are eligible for.

#### Applying the activity vesting multiplier

The `activity_streak_vesting_multiplier` scales the parties [vesting rate](./0085-RVST-rewards_vesting.md#vesting-mechanics) of all funds locked in the parties vesting accounts.


## APIs

### Parties API

Must expose the following:

- a parties `activity_streak`
- a parties `inactivity_streak`
- whether a party has been considered "active" in the current epoch
- a parties current `reward_distribution_activity_multiplier`
- a parties current `reward_vesting_activity_multiplier`

## Acceptance Criteria

### Governance proposals

Too be added

### Setting activity / inactivity streak

Too be added

### Setting activity benefits

Too be added

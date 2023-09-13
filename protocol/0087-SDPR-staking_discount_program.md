# Staking Discount Program

The staking discount program provides tiered discounts on taker fees to traders. A trader accesses greater discounts by staking $VEGA governance tokens for at least a specified number of epochs.

## Network parameters

- `stakingDiscountProgram.benefitTiers`: is an ordered list of dictionaries defining the requirements and benefits for each tier.
- `stakingDiscountProgram.windowLength`: is an integer defining the number of epochs over which a party must have staked the tokens to receive a benefit. This value must be an integer strictly greater than 0 and less than 100. It should default to 1.

## Benefit Mechanics

### Setting benefit factors

At the start of an epoch the network should calculate each parties `party_staked_tokens` by determining the smallest number of tokens a party has staked over the last n epochs where n is the network parameter `stakingDiscountProgram.windowLength`.

Each parties `staking_discount_factor` is then fixed to the value in the highest benefit tier they qualify for. A parties benefit tier is defined as the highest tier for which their `party_average_staked_tokens` is greater or equal to the tiers `minimum_average_staked_tokens`. If a party does not qualify for any tier, their `staking_discount_factor` is set to `0`.

```pseudo
Given:
    stakingDiscountProgram.benefitTiers=[
        {
            "minimum_staked_tokens": 1000,
            "staking_discount_factor": 0.001,
        },
        {
            "minimum_staked_tokens": 5000,
            "staking_discount_factor": 0.005,
        },
        {
            "minimum_staked_tokens": 20000,
            "staking_discount_factor": 0.010,
        },
    ]

And:
    party_staked_tokens=2432

Then:
    staking_discount_factor=0.005
```

This benefit factor is then fixed for the duration of the next epoch.

### Applying benefit factors

Staking discount program benefit factors are applied by modifying [the fees](./0029-FEES-fees.md) paid by a party (either during continuous trading or on auction exit).

## APIs

The Parties API should expose the following information:

- a list of all **parties** (by `id`) and the following metrics:
  - current `party_staked_tokens` (value at the start of the epoch)
  - current `staking_discount_factor` applied to fees

The Trades API should now also expose the following additional information for every trade:

- Volume discount program discounts
  - `infrastructure_fee_staking_discount`
  - `liquidity_fee_staking_discount`
  - `maker_fee_staking_discount`

## Acceptance Criteria

### Setting benefit factors

1. At the start of an epoch, each parties `staking_discount_factor` is reevaluated and fixed for the epoch (<a name="0087-SDPR-001" href="#0087-SDPR-001">0087-SDPR-001</a>).
1. A parties `staking_discount_factor`  is set equal to the factors in the highest benefit tier they qualify for (<a name="0087-SDPR-002" href="#0087-SDPR-002">0087-SDPR-002</a>).
1. If a party does not qualify for the lowest tier, their `staking_discount_factor`is set to `0` (<a name="0087-SDPR-003" href="#0087-SDPR-003">0087-SDPR-003</a>).

### Updating network parameters

1. If `stakingDiscountProgram.benefitTiers` is updated in the middle of an epoch, each parties `staking_discount_factor` value will not change un till the next epoch when they are reevaluated (<a name="0087-SDPR-004" href="#0087-SDPR-004">0087-SDPR-004</a>).
1. If `stakingDiscountProgram.windowLength` is updated in the middle of an epoch, each parties `staking_discount_factor` value will not change un till the next epoch when they are reevaluated (<a name="0087-SDPR-005" href="#0087-SDPR-005">0087-SDPR-005</a>).

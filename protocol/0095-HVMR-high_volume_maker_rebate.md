# High Volume Maker Rebate

The high volume maker rebate program is a network-wide community governed set of parameters to provide an additional reward to market makers on the network who are involved in a significant fraction of all trading on the network. When enabled, eligible market makers receive an additional fraction of trading fees from trades in which they are involved on top of any standard received maker fee (and would receive this even were the default maker fee removed).

## Configuration

The configuration of the High Volume Maker rebate is performed very similarly to that of the [volume discount program](./0084-VDPR-volume_discount_program.md):
Enabling or changing the terms of the program can be proposed via governance. As part of the proposal, the proposer specifies the following fields:

- `benefit_tiers`: a list of dictionaries with the following fields
  - `minimum_party_maker_volume_fraction`: the required `party_maker_volume_fraction` for a party to access this tier
  - `additional_maker_rebate`: the additional rebate factor (in percentage of `trade_value_for_fee_purposes`) a party at this tier will receive when they are the maker side of a trade
- `end_of_program_timestamp`: the timestamp after which when the current epoch ends, the program will become inactive and benefits will be disabled. If this field is empty, the program runs indefinitely.
- `window_length`:  the number of epochs over which to measure a party's cumulative maker volume.


## Calculation

For each party, the network must track the maker volume they created in each epoch.

At the start of an epoch the network should calculate each parties `party_maker_volume_fraction` by calculating what proportion of the maker volume over the last $m$ epochs a party made up (where m is the `window_length` set configured in the program), i.e.

$$\text{partyMakerVolumeFraction}_j = \frac{\sum_{i=1}^{m} V_{i,j}}{\sum_{i=1}^{m} \sum_{k=1}^{n} V_{i,k}}$$

where:

- ${V_i}_j$ is the maker volume of party `j` in epoch `i`


Each parties `additional_maker_rebate` is then fixed to the value in the highest tier they qualify for. A parties tier is defined as the highest tier for which their `party_maker_volume_fraction` is greater or equal to the tiers `minimum_party_maker_volume_fraction`. If a party does not qualify for any tier, their `additional_maker_rebate` is set to `0`.

```pseudo
Given:
    benefit_tiers=[
        {
            "minimum_party_maker_volume_fraction": 0.1,
            "additional_maker_rebate": 0.01,
        },
        {
            "minimum_party_maker_volume_fraction": 0.2,
            "additional_maker_rebate": 0.02,

        },
        {
            "minimum_party_maker_volume_fraction": 0.3,
            "additional_maker_rebate": 0.03,

        },
    ]

And:
    party_maker_volume_fraction=0.23

Then:
    additional_maker_rebate=0.02
```

This `additional_maker_rebate` factor is then fixed for the duration of the next epoch.

## Application

As variable fees for the taker depending upon with whom they are trading would not be a good experience, the additional maker rebate should be taken from a weighted combination of the network treasury and network buyback components of the total fee. The exact calculations are laid out in [0029-FEES](./0029-FEES-fees.md) but are broadly:

   1. `high_volume_maker_fee = high_volume_factor * trade_value_for_fee_purposes`
   1. `treasury_fee = treasury_fee * (1 - high_volume_maker_fee / (treasury_fee + buyback_fee))`
   1. `buyback_fee = treasury_fee * (1 - buyback_fee / (treasury_fee + buyback_fee))`

## Governance Requirements

As the rebate possible level interacts with other fee settings there must be a restriction on it's possible values in governance change proposals. However, as both the rebate and the relevant fees could be changed at once the failure should occur at enactment of the proposal rather than initial validation. The criterion `max(additional_maker_rebate) <= market.fee.factors.treasuryFee + market.fee.factors.buybackFee` should be checked at changes of both the maker rebate program and the two fee factor values to ensure this constraint remains true.

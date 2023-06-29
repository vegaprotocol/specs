# Reward framework

The reward framework provides a mechanism for measuring and rewarding a number of key activities on the Vega network.
These rewards operate in addition to the main protocol economic incentives which come from
[fees](0029-FEES-fees.md) on every trade.
These fees are the fundamental income stream for [liquidity providers LPs](0042-LIQF-setting_fees_and_rewarding_lps.md) and [validators](./0061-REWP-pos_rewards.md).

The additional rewards described here can be funded arbitrarily by users of the network and may be used by the project team, token holders (via governance), and individual traders and market makers to incentivise mutually beneficial behaviour.
Note that transfers via governance, including to fund rewards, is a post-Oregon Trail feature.

Note that validator rewards (and the reward account for those) is covered in [validator rewards](./0061-REWP-pos_rewards.md) and is separate from the trading reward framework described here.

## New network parameter for market creation threshold

The parameter `rewards.marketCreationQuantumMultiple` will be used together with [quantum](0040-ASSF-asset_framework.md) to asses market size when deciding whether a market qualifies for the payment of market creation rewards.
It is reasonable to assume that `quantum` will be set to a value around `1 USD` (though there will likely be quite significant variation from this for assets that are not well correlated with USD).
Therefore, for example, to reward futures markets when they reach a lifetime traded notional over 1 mil USD, then this parameter should be set to around `1000000`. Any decimal value strictly greater than `0` is valid.

## Reward process high level

At a high level, rewards work as follows:

- Reward metrics are calculated for each combination of [reward type, party, market].
  - The calculation used for the reward metric is specific to each reward type.

At the end of the epoch:

1. Recurring reward transfers (set up by the parties funding the rewards) are made to the reward account(s) for a specific reward type, for one or more markets in scope where the total reward metric is `>0`. See [transfers](./0057-TRAN-transfers.md#recurring-transfers-to-reward-accounts).
1. Then the entire balance of each reward account is distributed to the parties with a non-zero reward metric for that reward type and market, pro-rata by their reward metric.

## Reward metrics

Fee-based reward metrics are scoped by [`reward type`, `market`, `party`] (this triplet can be thought of as a primary key for fee-based reward metrics).
Therefore a party may be in scope for the same reward type multiple times but no more than once per market per epoch.
Metrics will be calculated at the end of every epoch, for every eligible party, in each market for each reward type.
Metrics only need to be calculated where the [market, reward type] reward account has a non-zero balance of at least one asset.

Reward metrics will be calculated once for each party/market combination in the reward metric asset which is the [settlement asset](0070-MKTD-market-decimal-places.md) of the market.
This is the original precision for the metric source data.

### Market activity (fee based) reward metrics

There will be three market activity reward metrics calculated based on fees (as a proxy for activity).
Each of these represents a reward type with its own segregated reward accounts for each market.

1. Sum of maker fees paid by the party on the market this epoch
1. Sum of maker fees received by the party on the market this epoch
1. Sum of LP fees received by the party on the market this epoch

These metrics apply only to the sum of fees for the epoch in question.
That is, the metrics are reset to zero for all parties at the end of the epoch.
If the reward account balance is 0 at the end of the epoch for a given market, any parties with non-zero metrics will not be rewarded for that epoch and their metric scores do not roll over (they are still zeroed).

Market activity (fee based) reward metrics (the total fees paid/received by each party as defined above) are stored in [LNL checkpoints](./0073-LIMN-limited_network_life.md) and are restored after a checkpoint restart to ensure rewards are not lost.

### Market creation reward metrics

There will be a single market creation reward metric and reward type.
This makes it possible to reward creation of markets achieving at least a minimum lifetime trading volume, as a proxy for identifying the creation of useful markets:

Where:

- there is a single eligible party for each market, which is the party that created the market by submitting the original new market governance proposal (**all other parties** have market creation metric = 0)
- `cumulative volume` is defined as the cumulative total [trade value for fee purposes](0029-FEES-fees.md)
- `rewards.marketCreationQuantumMultiple` is a network parameter described above
- `quantum` is an asset level field described in the [asset framework](0040-ASSF-asset_framework.md)

The reward metric for the single *market creator* party is as follows (the metric is `0` for all other parties):

- **IF** `cumulative volume < rewards.marketCreationQuantumMultiple * quantum` **THEN** `market creation metric := 0`
- **ELSE** `market creation metric := 1` (NB: this is 1 as market creation rewards are paid equally to all qualifying creators for *reaching* the volume threshold, not pro-rata based on cumulative volume)

When the `market creation metric` for a party is `>0` and the reward account balance for a specific reward asset is also `>0` (i.e. when a market creator is rewarded):

- The reward account will have been funded in that epoch from one or more source accounts (the `funders`) via recurring transfers.
See the [transfers](./0057-TRAN-transfers.md) spec.

- These transfers will each have targeted, for a specific settlement asset (reward metric asset), either a specific list of markets, or an empty list meaning all markets with that settlement asset (the `market scopes`).

- A flag is stored on each market for each combination of [`funder`, `market scope`, `reward asset`] that was included in the reward payout.
This flag is used to prevent any given funder from funding a creation reward in the same reward asset more than once for any given *market scope*.

Market creation reward metrics (both each market's `cumulative volume` and the payout record flags to identify [funder, market scope, reward asset] combinations that have already been rewarded) are stored in [LNL checkpoints](./0073-LIMN-limited_network_life.md) and will be restored after a checkpoint restart.

## Reward accounts

Trading reward accounts are defined by the reward asset (the asset in which the reward is paid out), the market, and the reward type (metric).
That is, there can be multiple rewards with the same type paid in different assets for the same market.

Note that the market settlement asset has nothing to do in particular with the asset used to pay out a reward for a market.
That is, a participant might receive rewards in the settlement asset of the market, in VEGA governance tokens, and in any number of other unrelated tokens (perhaps governance of "loyalty"/reward tokens issued by LPs or market creators, or stablecoins like DAI).

Reward accounts are funded by setting up recurring transfers, which may be set to occur only once for a one off reward.
These allow a reward type to be automatically funded on an ongoing basis from a pool of assets.
Recurring transfers can target groups of markets, or all markets for a settlement asset, in which case the amount paid to each market is determined pro-rata by the markets' relative total reward metrics for the given reward type. See [transfers](./0057-TRAN-transfers.md) for more detail.

Reward accounts and balances must be saved in [LNL checkpoints](./0073-LIMN-limited_network_life.md) to ensure all funds remain accounted for across a restart.

## Reward distribution

All rewards are paid out at the end of each epoch *after* [recurring transfers](0057-TRAN-transfers.md) have been executed.
The entire reward account balance is paid out every epoch unless the total value of the metric over all parties is zero, in which case the balance will also be zero anyway (there are no fractional payouts).
There are no payout delays, rewards are paid out instantly at epoch end.

Rewards will be distributed pro-rata by the party's reward metric value to all parties that have metric values `>0`. Note that for the market creation reward, the metric is defined to either be `0` or `1`, which will lead to equal payments for each eligible market under the pro-rata calculation. If we have reward account balance `R` and parties `p_1 – p_n` with non-zero metrics `m_1 – m_n` on the market in question:

```math
[p_1, m_1]
[p_2, m_2]
...
[p_n, m_n]
```

Then calculate `M := m_1 + m_2 + … + m_n` and transfer `R ✖️ m_i / M` to party `p_i` (for each `p_i`) at the end of the epoch.

If `M=0` (no-one incurred or received fees as specified by the metric type for the given market) then no transfer will have been made to the reward account and therefore there are no rewards to pay out.
The transfer will be retried the next epoch if it is still active.

Reward payouts will be calculated using the decimal precision of the reward payout asset. If this allows less precision than the reward metric asset (the market's settlement asset) then the ratios between reward payouts may not match exactly the ratio between the reward metrics for any two parties. All funds will always be paid out.

## Acceptance criteria

### Funding reward accounts (<a name="0056-REWA-001" href="#0056-REWA-001">0056-REWA-001</a>)(<a name="0056-SP-REWA-001" href="#0056-SP-REWA-001">0056-SP-REWA-001</a>)

Trading reward accounts are defined by a pair: [`payout_asset, dispatch_strategy`].

There are two assets configured on the Vega chain: $VEGA and USDT.

Setup a recurring transfer of 1000 $VEGA with the following dispatch strategy: asset=`USDT`, metric=`DISPATCH_METRIC_TAKER_FEES_PAID`, markets=[].
Create 3 markets settling in USDT. Wait for a new epoch to begin, in the next epoch generate fees in the markets with the following distribution:
`Market1` contributes 20% of the fees, `market2` contributes 30% of the fees and `market3` contributes 50% of the fees - e.g. in `market1` 200 USDT were paid in taker fees, in `market2` 300 USDT and in `market3` 500. At the time the transfer is distributed, expect the reward accounts for the corresponding markets are funded proportionally to the contribution defined above, so if the transfer is of 1000 $VEGA, then `market1` is funded with 200, `market2` is funded with 300 and `market3` is funded with 500.

Run for another epoch with no fee generated. Expect no transfer to be made to the reward pools of the accounts.

### Funding reward accounts - with markets in scope (<a name="0056-REWA-002" href="#0056-REWA-002">0056-REWA-002</a>)(<a name="0056-SP-REWA-002" href="#0056-SP-REWA-002">0056-SP-REWA-002</a>)

There are two assets configured on the Vega chain: $VEGA and USDT.

Setup a recurring transfer of 1000 $VEGA with the following dispatch strategy: asset=`USDT`, metric=`DISPATCH_METRIC_TAKER_FEES_PAID`, markets=[`market1`, `market2`].
Create 3 markets settling in USDT. Wait for a new epoch to begin, in the next epoch generate fees in the markets with the following distribution:
`Market1` contributes 20% of the fees, `market2` contributes 30% of the fees and `market3` contributes 50% of the fees - e.g. in `market1` 200 USDT were paid in taker fees, in `market2` 300 USDT and in `market3` 500. At the time the transfer is distributed, expect the reward accounts for the corresponding markets are funded proportionally to the contribution defined above, so if the transfer is of 1000 $VEGA, then `market1` is funded with 400, `market2` is funded with 600 and `market3` is funded with 0.

Run for another epoch with no fee generated. Expect no transfer to be made to the reward pools of the accounts.

### Distributing fees paid rewards (<a name="0056-REWA-010" href="#0056-REWA-010">0056-REWA-010</a>)(<a name="0056-SP-REWA-010" href="#0056-SP-REWA-010">0056-SP-REWA-010</a>)

#### Rationale 1

A market has 2 reward accounts for the metric, one paying in $VEGA and the other paying in USDC.

#### Setup 1

There are 3 assets configured on the Vega chain: $VEGA, USDT, USDC.
There are no markets.

- `transfer.fee.factor` = 0
- `maker_fee` = 0.0001
- `infrastructure_fee` = 0.0002
- `ETHUSD-MAR22` market which settles in USDT is launched anytime in epoch 1 by `party_0`
- `party_0` and `party_1` provide auction orders so there is a trade to leave the opening auction and the remaining best bid = 2700 and and best offer = 2800 are supplied by party_0 each with volume 10.
- Moreover `party_0` provides liquidity with `liquidity_fee` = 0.0003 and offset + 10 (so their LP volume lands on 2690 and 2810).
- During epoch `2` we have `party_1` make one buy market order with volume `2`.
- During epoch `2` we have `party_2` make one sell market order each with notional `1`.

#### Funding reward accounts 1

- `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
  - `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of fees paid | VEGA` in epoch `2`. (`ETHUSD-MAR22` is just for brevity here, the transfer is specified by market id not its name).
  - `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of fees paid | USDC` in epoch `2`. (`ETHUSD-MAR22` is just for brevity here, the transfer is specified by market id not its name).

#### Expectation 1

At the end of epoch 2 the metric `sum of fees paid` for `party_1` should be:

```math
2 x 2800 x (0.0001 + 0.0002 + 0.0003) = 3.36
```

and for `party_2` it is:

```math
1 x 2700 x (0.0001 + 0.0002 + 0.0003) = 1.62
```

At the end of epoch 2:

- `party_1` is paid `90 x 3.36 / 4.98 = 60.72.` $VEGA from the reward account into its $VEGA general account.
- `party_2` is paid `90 x 1.62 / 4.98 = 29.28.` $VEGA from the reward account into its $VEGA general account.
- `party_1` is paid `120 x 3.36 / 4.98 = 80.96.` USDC from the reward account into its USDC general account.
- `party_2` is paid `120 x 1.62 / 4.98 = 39.03.` USDC from the reward account into its USDC general account.

### Distributing fees paid rewards - unfunded account (<a name="0056-REWA-011" href="#0056-REWA-011">0056-REWA-011</a>)(<a name="0056-SP-REWA-011" href="#0056-SP-REWA-011">0056-SP-REWA-011</a>)

#### Rationale 2

This is identical to [acceptance code REWA-010](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-fees-paid-rewards-0056-rewa-010) just without funding the corresponding reward account.

#### Setup 2

Identical to [acceptance code REWA-010](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-fees-paid-rewards-0056-rewa-010)

#### Funding reward accounts 2

No funding done.

#### Expectation 2

At the end of epoch 2 although there was trading in the market `ETHUSD-MAR22`, no reward is given to any participant as the reward account was not funded.

### Distributing fees paid rewards - funded account - no trading activity (<a name="0056-REWA-012" href="#0056-REWA-012">0056-REWA-012</a>)(<a name="0056-SP-REWA-012" href="#0056-SP-REWA-012">0056-SP-REWA-012</a>)

#### Rationale 3

After having an epoch with trading activity, fund the reward account, but have no trading activity and assert that no payout is made.

#### Setup 3

Identical to [acceptance code REWA-010](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-fees-paid-rewards-0056-rewa-010)

#### Funding reward accounts 3

Identical to [acceptance code REWA-010](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-fees-paid-rewards-0056-rewa-010)

Then, during epoch 3 we fund the reward accounts for the metric:

- `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
  - `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of fees paid | $VEGA` in epoch `3`. (`ETHUSD-MAR22` is just brevity, this should be the market id not name).
  - `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of fees paid | $USDC` in epoch `3`. (`ETHUSD-MAR22` is just brevity, this should be the market id not name).

#### Expectation 3

Looking only at epoch 3 - as no trading activity was done, we expect the reward balances in both $VEGA and USDC for the metric to remain unchanged.

### Distributing fees paid rewards - multiple markets (<a name="0056-REWA-013" href="#0056-REWA-013">0056-REWA-013</a>)(<a name="0056-SP-REWA-013" href="#0056-SP-REWA-013">0056-SP-REWA-013</a>)

#### Rationale 4

There are multiple markets, each paying its own reward where due.

#### Setup 4

There are 3 assets configured on the Vega chain: $VEGA, USDT, USDC.
There are no markets.

- `transfer.fee.factor` = 0
- `maker_fee` = 0.0001
- `infrastructure_fee` = 0.0002
- `ETHUSD-MAR22` market which settles in USDT is launched anytime in epoch 1 by `party_0`
- `ETHUSD-JUN22` market which settles in USDC is launched anytime in epoch 1 by `party_0`
- For each market in {`ETHUSD-MAR22`, `ETHUSD-JUN22`}
  - `party_0` and `party_1` provide auction orders so there is a trade to leave the opening auction and the remaining best bid = 2700 and and best offer = 2800 are supplied by party_0 each with volume 10.
  - Moreover `party_0` provides liquidity with `liquidity_fee` = 0.0003 and offset + 10 (so their LP volume lands on 2690 and 2810).
  - During epoch `2` we have `party_1` make one buy market order with volume `2`.
  - During epoch `2` we have `party_2` make one sell market order each with notional `1`.

#### Funding reward accounts 4

- `party_R` is funding multiple the reward accounts for both markets:
  - `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of fees paid | $VEGA` in epoch `2`.
  - `party_R` makes a transfer of `120` `$VEGA` to `ETHUSD-JUN22 | Sum of fees paid | $VEGA` in epoch `2`.

#### Expectation 4

The calculation of eligibility is identical to [acceptance code REWA-010](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-fees-paid-rewards-0056-rewa-010) but the expected payout is:

- for market `ETHUSD-MAR22`:
  - `party_1` is paid `90 x 3.36 / 4.98 = 60.72.` $VEGA from the reward account into its $VEGA general account.
  - `party_2` is paid `90 x 1.62 / 4.98 = 29.28.` $VEGA from the reward account into its $VEGA general account.
- for market `ETHUSD-Jun22`:
  - `party_1` is paid `120 x 3.36 / 4.98 = 80.96.` $VEGA from the reward account into its $VEGA general account.
  - `party_2` is paid `120 x 1.62 / 4.98 = 39.03.` $VEGA from the reward account into its $VEGA general account.

### Distributing maker fees received rewards (<a name="0056-REWA-020" href="#0056-REWA-020">0056-REWA-020</a>)(<a name="0056-SP-REWA-020" href="#0056-SP-REWA-020">0056-SP-REWA-020</a>)

#### Rationale 5

A market has 2 reward accounts for the metric, one paying in $VEGA and the other paying in USDC.

#### Setup 5

There are 3 assets configured on the Vega chain: $VEGA, USDT, USDC.
There are no markets.

- `transfer.fee.factor` = 0
- `maker_fee` = 0.0001
- `infrastructure_fee` = 0.0002
- `ETHUSD-MAR22` market which settles in USDT is launched anytime in epoch 1 by `party_0`
- `party_0` and `party_1` provide auction orders so there is a trade to leave the opening auction and the remaining best bid = 2700 and and best offer = 2800 are supplied by party_0 each with volume 10.
- Moreover `party_0` provides liquidity with `liquidity_fee` = 0.0003 and offset + 10 (so their LP volume lands on 2690 and 2810).
- During epoch 2 `party_1` puts a limit buy order of vol 10 at 2710 and a limit sell order of vol 10 at 2790
- After that, during epoch 2 `party_2` puts in a market buy order of volume 20.

#### Funding reward accounts 5

- `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
  - `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of maker fees received | VEGA` in epoch `2`.
  - `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of maker fees received | USDC` in epoch `2`.

#### Expectation 5

At the end of epoch `2` the metric `sum of maker fees received` for `party_1` should be:

```math
10 x 2790 x 0.0001 = 2.79
```

and for `party_0` it is

```math
10 x 2800 x 0.0001 = 2.8
```

At the end of epoch `2` `party_1` is paid `90 x 2.79 / (2.79+2.8)` $VEGA from the reward account into its `$VEGA` general account.
At the end of epoch `2` `party_0` is paid `90 x 2.8 / (2.79+2.8)` $VEGA from the reward account into its `$VEGA` general account.
At the end of epoch `2` `party_1` is paid `120 x 2.79 / (2.79+2.8)` USDC from the reward account into its `USDC` general account.
At the end of epoch `2` `party_0` is paid `120 x 2.8 / (2.79+2.8)` USDC from the reward account into its `USDC` general account.

### Distributing maker fees received rewards - unfunded account (<a name="0056-REWA-021" href="#0056-REWA-021">0056-REWA-021</a>)(<a name="0056-SP-REWA-021" href="#0056-SP-REWA-021">0056-SP-REWA-021</a>)

#### Rationale 6

This is identical to [acceptance code REWA-020](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020) just without funding the corresponding reward account.

#### Setup 6

Identical to [acceptance code REWA-020](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020).

#### Funding reward accounts 6

No funding done.

#### Expectation 6

At the end of epoch 2 although there was trading in the market `ETHUSD-MAR22`, no reward is given to any participant as the reward account was not funded.

### Distributing maker fees received rewards - funded account - no trading activity (<a name="0056-REWA-022" href="#0056-REWA-022">0056-REWA-022</a>)(<a name="0056-SP-REWA-022" href="#0056-SP-REWA-022">0056-SP-REWA-022</a>)

#### Rationale 7

After having an epoch with trading activity, fund the reward account, but have no trading activity and assert that no payout is made.

#### Setup 7

Identical to [acceptance code REWA-020](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020)

#### Funding reward accounts 7

Identical to [acceptance code REWA-020](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020)

Then, during epoch 3 we fund the reward accounts for the metric:

- `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
  - `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of maker fees received | VEGA` in epoch `3`.
  - `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of maker fees received | USDC` in epoch `3`.

#### Expectation 7

Looking only at epoch 3 - as no trading activity was done, we expect the reward balances in both $VEGA and USDC for the metric to remain unchanged.

### Distributing maker fees received rewards - multiple markets (<a name="0056-REWA-023" href="#0056-REWA-023">0056-REWA-023</a>)(<a name="0056-SP-REWA-023" href="#0056-SP-REWA-023">0056-SP-REWA-023</a>)

#### Rationale 8

There are multiple markets, each paying its own reward where due.

#### Setup 8

There are 3 assets configured on the Vega chain: $VEGA, USDT, USDC.
There are no markets.

- `transfer.fee.factor` = 0
- `maker_fee` = 0.0001
- `infrastructure_fee` = 0.0002
- `ETHUSD-MAR22` market which settles in USDT is launched anytime in epoch 1 by `party_0`
- `ETHUSD-JUN22` market which settles in USDC is launched anytime in epoch 1 by `party_0`
- For each market in {`ETHUSD-MAR22`, `ETHUSD-JUN22`}
  - `party_0` and `party_1` provide auction orders so there is a trade to leave the opening auction and the remaining best bid = 2700 and and best offer = 2800 are supplied by party_0 each with volume 10.
  - Moreover `party_0` provides liquidity with `liquidity_fee` = 0.0003 and offset + 10 (so their LP volume lands on 2690 and 2810).
  - During epoch 2 `party_1` puts a limit buy order of vol 10 at 2710 and a limit sell order of vol 10 at 2790
  - After that, during epoch 2 `party_2` puts in a market buy order of volume 20.

#### Funding reward accounts 8

- `party_R` is funding multiple the reward accounts for both markets:
  - `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of maker fees received | $VEGA` in epoch `2`.
  - `party_R` makes a transfer of `120` `$VEGA` to `ETHUSD-JUN22 | Sum of maker fees received | $VEGA` in epoch `2`.

#### Expectation 8

The calculation of eligibility is identical to [acceptance code REWA-020](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020) but the expected payout is:

- for market `ETHUSD-MAR22`:
  - At the end of epoch `2` `party_1` is paid `90 x 2.79 / (2.79+2.8)` $VEGA from the reward account into its `$VEGA` general account.
  - At the end of epoch `2` `party_0` is paid `90 x 2.8 / (2.79+2.8)` $VEGA from the reward account into its `$VEGA` general account.
- for market `ETHUSD-Jun22`:
  - At the end of epoch `2` `party_1` is paid `120 x 2.79 / (2.79+2.8)` USDC from the reward account into its `$VEGA` general account.
  - At the end of epoch `2` `party_0` is paid `120 x 2.8 / (2.79+2.8)` USDC from the reward account into its `$VEGA` general account.

### Distributing LP fees received rewards (<a name="0056-REWA-030" href="#0056-REWA-030">0056-REWA-030</a>)(<a name="0056-SP-REWA-030" href="#0056-SP-REWA-030">0056-SP-REWA-030</a>)

#### Rationale 9

A market has 2 reward accounts for the metric, one paying in $VEGA and the other paying in USDC.

#### Setup 9

Identical to [acceptance code REWA-020](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020).

#### Funding reward accounts 9

Identical to [acceptance code REWA-020](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020).

#### Expectation 9

At the end of epoch `2` the metric `sum of lp fees received` for `party_0` is:

```math
10 x 2790 x 0.0003 + 10 x 2800 x 0.0003 = 16.77
```

At the end of epoch `2` `party_0` is paid `90` `$VEGA` from the reward account into its `$VEGA` general account.
At the end of epoch `2` `party_0` is paid `120` `USDC` from the reward account into its `USDC` general account.

### Distributing LP fees received rewards - unfunded account (<a name="0056-REWA-031" href="#0056-REWA-031">0056-REWA-031</a>)
(<a name="0056-SP-REWA-031" href="#0056-SP-REWA-031">0056-SP-REWA-031</a>)

#### Rationale 10

Identical to [acceptance code REWA-030](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-lp-fees-received-rewards-0056-rewa-030), but without funding the corresponding reward account.

#### Setup 10

Identical to [acceptance code REWA-030](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-lp-fees-received-rewards-0056-rewa-030)

#### Funding reward accounts 10

No funding done.

#### Expectation 10

At the end of epoch 2 although there was trading in the market `ETHUSD-MAR22`, no reward is given to any participant as the reward account was not funded.

### Distributing maker fees received  rewards - funded account - no trading activity (<a name="0056-REWA-032" href="#0056-REWA-032">0056-REWA-032</a>)(<a name="0056-SP-REWA-032" href="#0056-SP-REWA-032">0056-SP-REWA-032</a>)

#### Rationale 11

After having an epoch with trading activity, fund the reward account, but have no trading activity and assert that no payout is made.

#### Setup 11

Identical to [acceptance code REWA-030](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-lp-fees-received-rewards-0056-rewa-030)

#### Funding reward accounts 11

Identical to [acceptance code REWA-030](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-lp-fees-received-rewards-0056-rewa-030)

Then, during epoch 3 we fund the reward accounts for the metric:

- `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
  - `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of LP fees received | VEGA` in epoch `3`.
  - `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of LP fees received | USDC` in epoch `3`.

#### Expectation 11

Looking only at epoch 3 - as no trading activity was done, we expect the reward balances in both $VEGA and USDC for the metric to remain unchanged.

### Distributing LP fees received - multiple markets (<a name="0056-REWA-033" href="#0056-REWA-033">0056-REWA-033</a>)(<a name="0056-SP-REWA-033" href="#0056-SP-REWA-033">0056-SP-REWA-033</a>)

#### Rationale 12

There are multiple markets, each paying its own reward where due.

#### Setup 12

Identical to [acceptance code REWA-023](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards---multiple-markets-0056-rewa-023)

#### Funding reward accounts 12

- `party_R` is funding multiple the reward accounts for both markets:
  - `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of LP fees received | $VEGA` in epoch `2`.
  - `party_R` makes a transfer of `120` `$VEGA` to `ETHUSD-JUN22 | Sum of LP fees received | $VEGA` in epoch `2`.

#### Expectation 12

The calculation of eligibility is identical to [acceptance code REWA-030](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-lp-fees-received-rewards-0056-rewa-030) but the expected payout is:

- for market `ETHUSD-MAR22`:
  - At the end of epoch `2` `party_0` is paid `90` `$VEGA` from the reward account into its `$VEGA` general account.
- for market `ETHUSD-Jun22`:
  - t the end of epoch `2` `party_0` is paid `120` `USDC` from the reward account into its `USDC` general account.

### Distributing market creation rewards - no eligibility (<a name="0056-REWA-040" href="#0056-REWA-040">0056-REWA-040</a>)(<a name="0056-SP-REWA-040" href="#0056-SP-REWA-040">0056-SP-REWA-040</a>)

#### Rationale 13

Market has been trading but not yet eligible for proposer bonus.

#### Setup 13

- Setup a market `ETHUSDT` settling in USDT.
- The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`.
- Setup and fund multiple recurring reward account transfers using the market_proposer metric and `USDT` metric asset:
  - Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA`
  - Transfer 20000 USDC to `ETHUSDT | market creation | USDC`
- start trading in the market such that traded value for fee purposes in USDT is less than 10^6

#### Expectation 13

At the end of the epoch no payout has been made for the market `ETHUSDT` and the reward account balances should remain unchanged.

### Distributing market creation rewards - eligible are paid no more than once (<a name="0056-REWA-041" href="#0056-REWA-041">0056-REWA-041</a>)(<a name="0056-SP-REWA-041" href="#0056-SP-REWA-041">0056-SP-REWA-041</a>)

#### Rationale 14

Once a market creator has been paid, they are not paid again from the same reward pool

#### Setup 14

- Setup a market `ETHUSDT` settling in USDT.
- The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`.
- Setup and fund multiple recurring reward account transfers using the market_proposer metric and `USDT` metric asset:
  - Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA`
  - Transfer 20000 USDC to `ETHUSDT | market creation | USDC`
- start trading in the market such that traded value for fee purposes in USDT is less than `10^6`
- During the epoch 2 let the traded value be greater than 10^6

#### Expectation 14

At the end of the epoch 2 the proposer of the market `ETHUSDT` is paid 10000 `$VEGA` and 20000 `USDC`

At the end of epoch 3 make sure that no transfer is made to the reward account as the proposer of the market has already been paid the proposer bonus once and there are no other eligible markets.

### Distributing market creation rewards - account funded after reaching requirement (<a name="0056-REWA-042" href="#0056-REWA-042">0056-REWA-042</a>)(<a name="0056-SP-REWA-042" href="#0056-SP-REWA-042">0056-SP-REWA-042</a>)

#### Rationale 15

Market goes above the threshold in trading value in an epoch before the reward account for the market for the reward type has any balance - proposer does receive reward even if account is funded at a later epoch.

#### Setup 15

- Setup a market `ETHUSDT` settling in USDT.
- The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`.
- start trading in the market such that trading volume in USDT is less than `10^6`
- During the epoch 2 let the traded value be greater than `10^6`
- in Epoch 3 setup and fund multiple recurring reward account transfers using the market_proposer metric and `USDT` metric asset:
  - Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA`
  - Transfer 20000 USDC to `ETHUSDT | market creation | USDC`

#### Expectation 15

At the end of epoch 3, a payout of 10000 VEGA and 20000 USDC is made for the market `ETHUSDT` to the creator's general account balance.
The reward pool balance should be 0.

### Distributing market creation rewards - multiple asset rewards (<a name="0056-REWA-043" href="#0056-REWA-043">0056-REWA-043</a>)(<a name="0056-SP-REWA-043" href="#0056-SP-REWA-043">0056-SP-REWA-043</a>)

#### Rationale 16

A market should be able to be rewarded multiple times if several reward pools are created with different payout assets.

#### Setup 16

- Setup a market `ETHUSDT` settling in USDT.
- The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`.
- Setup and fund recurring reward account transfers using the market_proposer metric and `USDT` metric asset:
  - Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA`
- start trading in the market such that traded value for fee purposes in USDT is less than 10^6
- During epoch 2 let the traded value be greater than `10^6`
- During epoch 3, transfer 20000 USDC to `all | market creation | USDC`

#### Expectation 16

At the end of epoch 2 1000 VEGA rewards should be distributed to the market creator's general account balance.
Then, at the end of epoch 3, the 20000 USDC rewards should be distributed again to the market creator's general balance.
The reward pool balance should be 0.

### Distributing market creation rewards - multiple asset rewards simultaneous payout (<a name="0056-REWA-045" href="#0056-REWA-045">0056-REWA-045</a>)(<a name="0056-SP-REWA-045" href="#0056-SP-REWA-045">0056-SP-REWA-045</a>)

#### Rationale 17

A market should be able to be rewarded multiple times if several reward pools are created with different payout assets.

#### Setup 17

- Setup a market `ETHUSDT` settling in USDT.
- The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`.
- Setup and fund multiple recurring reward account transfers using the market_proposer metric and `USDT` metric asset:
  - 10000 $VEGA to `ETHUSDT | market creation | $VEGA`
  - 20000 USDC to `all | market creation | USDC`
- start trading in the market for one epoch such that traded value for fee purposes in USDT is less than `10^6`
- During epoch 2 let the traded value be greater than `10^6`

#### Expectation 17

At the end of epoch 1 no transfers should be made and all rewards accounts should remain at `0`
At the end of epoch 2 the creator of `ETHUSDT` should receive both 10000 VEGA and 20000 USDC into their
general account.
The reward pool balance should be 0.

### Distributing market creation rewards - Same asset multiple party rewards (<a name="0056-REWA-044" href="#0056-REWA-044">0056-REWA-044</a>)(<a name="0056-SP-REWA-044" href="#0056-SP-REWA-044">0056-SP-REWA-044</a>)

#### Rationale 18

A market reward pool funded with the same asset by different parties should pay out to eligible markets as many times as there are parties, assuming threshold is reached.

#### Setup 18

- Setup a market `ETHUSDT` settling in USDT.
- The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`.
- Setup and fund recurring reward account transfers using the market_proposer metric and `USDT` metric asset:
  - Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA`
- start trading in the market such that traded value for fee purposes in USDT is less than 10^6
- During the epoch 2 let the traded value be greater than `10^6`
- During epoch 3, setup and fund multiple reward account for the market `ETHUSDT` with a different party:
  - Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA`

#### Expectation 18

At the end of epoch 2, 10000 VEGA rewards should be distributed to the proposer of the `ETHUSDT` market, bringing their general `USDT` balance to 10000.
The reward account balance should be empty.

Then, at the end of epoch 3, the 10000 VEGA rewards should again be distributed to the proposer of `ETHUSDT`, bringing their general `USDT` balance to 20000.
The reward account balance should again be empty

Then, at the end of epoch 4, no further VEGA rewards should be distributed, the proposer of `ETHUSDTs` general `USDT` balance should stay at 20000.
The reward account balance should still be empty, as there were no eligible markets so no transfer should occur.

### Distributing market creation rewards - Multiple markets eligible, one already paid (<a name="0056-REWA-046" href="#0056-REWA-046">0056-REWA-046</a>)(<a name="0056-SP-REWA-046" href="#0056-SP-REWA-046">0056-SP-REWA-046</a>)

#### Rationale 19

A market reward pool funded with the same asset by the same party with different market scopes should pay to all markets even if already paid

#### Setup 19

- Setup a market `ETHUSDT` settling in USDT.
- Setup a market `BTCDAI` settling in DAI with a different proposing party.
- The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for both `USDT` and `DAI` is `1`.
- Setup and fund recurring reward account transfers using the market_proposer metric and blank metric asset:
  - Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA`
- start trading in the market such that traded value for fee purposes in USDT is less than 10^6
- During epoch 2 let the traded value on `ETHUSDT` and `BTCDAI` be greater than 10^6
- During epoch 3, setup and fund recurring reward account transfers using the market_proposer metric and blank metric asset:
  - Transfer 10000 $VEGA to `all | market creation | $VEGA`

#### Expectation 19

At the end of epoch 2, 10000 VEGA rewards should be distributed to only the `ETHUSDT` creator.

- The general account balance of the `ETHUSDT` creator should be 10000.
- The general account balance of the `BTCDAI` creator should be 0.
- The reward pool balance should be 0.

At the end of epoch 3, 10000 VEGA should be split between the `BTCDAI` creator and the `ETHUSDT` creator.

- The general account balance of the `ETHUSDT` creator should be 15000.
- The general account balance of the `BTCDAI` creator should be 5000.
- The reward pool balance should be 0.

### Reward accounts cannot be topped up with a one-off transfer (<a name="0056-REWA-049" href="#0056-REWA-049">0056-REWA-049</a>)(<a name="0056-SP-REWA-049" href="#0056-SP-REWA-049">0056-SP-REWA-049</a>)

The following account types require metric-based distribution. As a one-off transfer cannot specify how it is rewarded, one-off transfers to metric-based reward pools must be **rejected**.
A one-off transfer from a user to any of the following account types is rejected. No assets are transferred:

- `ACCOUNT_TYPE_REWARD_LP_RECEIVED_FEES`,
- `ACCOUNT_TYPE_REWARD_MAKER_RECEIVED_FEES`,
- `ACCOUNT_TYPE_REWARD_TAKER_PAID_FEES`,
- `ACCOUNT_TYPE_REWARD_MARKET_PROPOSERS`

### Distributing market creation rewards - Market ineligible through metric asset (<a name="0056-REWA-048" href="#0056-REWA-048">0056-REWA-048</a>)(<a name="0056-SP-REWA-048" href="#0056-SP-REWA-048">0056-SP-REWA-048</a>)

#### Rationale 20

A market reward pool funded with the a specific metric asset should not pay out to markets not trading in that asset

#### Setup 20

- Setup a market `ETHUSDT` settling in USDT.
- Setup a market `BTCDAI` settling in DAI with a different proposing party.
- The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for both `USDT` and `DAI` is `1`.
- Setup and fund recurring reward account transfers using the market_proposer metric and `USDT` metric asset:
  - Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA`
- start trading in the market such that traded value for fee purposes in USDT is less than `10^6`
- During epoch 2 let the traded value on `ETHUSDT` and `BTCUSDT` be greater than `10^6`

#### Expectation 20

At the end of epoch 2, 10000 VEGA rewards should be distributed to only the `ETHUSDT` creator.

- The general account balance of the `ETHUSDT` creator should be 10000.
- The general account balance of the `BTCDAI` creator should be 0.
- The reward pool balance should be 0.

### Distributing market creation rewards - Multiple markets eligible, one already paid, specified asset (<a name="0056-REWA-047" href="#0056-REWA-047">0056-REWA-047</a>)(<a name="0056-SP-REWA-047" href="#0056-SP-REWA-047">0056-SP-REWA-047</a>)

#### Rationale 21

A market reward pool funded with the same asset by the same party with different market scopes should pay to all markets even if already paid

#### Setup 21

- Setup a market `ETHUSDT` settling in USDT.
- Setup a market `BTCUSDT` settling in USDT using a different proposing party.
- The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT`is `1`.
- Setup and fund recurring reward account transfers for the market `ETHUSDT`, specifying `USDT` markets for the metric asset:
  - Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA`
- start trading in the market such that traded value for fee purposes in USDT is less than `10^6`
- During epoch 2 let the traded value on `ETHUSDT` and `BTCUSDT` be greater than `10^6`
- During epoch 3, setup and fund recurring reward account for all markets, leaving a blank metric asset, with the same party:
  - Transfer 10000 $VEGA to `all | market creation | $VEGA`

#### Expectation 21

At the end of epoch 2 the full 10000 VEGA rewards should be distributed to only the `ETHUSDT` creator. At the end of epoch 3 the full 10000 VEGA rewards should be distributed to the `BTCUSDT` creator.

At the end of epoch 2, 10000 VEGA rewards should be distributed to only the `ETHUSDT` creator.

- The general account balance of the `ETHUSDT` creator should be 10000.
- The general account balance of the `BTCUSDT` creator should be 0.
- The reward pool balance should be 0.

At the end of epoch 3, 10000 VEGA should be distributed split between the `BTCUSDT` creator and the `ETHUSDT` creator.

- The general account balance of the `ETHUSDT` creator should be 15000.
- The general account balance of the `BTCUSDT` creator should be 5000.
- The reward pool balance should be 0.

### Updating the network parameter `rewards.marketCreationQuantumMultiple` (<a name="0056-REWA-050" href="#0056-REWA-050">0056-REWA-050</a>)(<a name="0056-SP-REWA-050" href="#0056-SP-REWA-050">0056-SP-REWA-050</a>)

#### Rationale 22

When the network parameter `rewards.marketCreationQuantumMultiple` is changed via governance, the change should take affect
immediately and the new value used at the end of the epoch to decide if market creators are eligible for reward.

#### Setup 22

- Setup a market `ETHUSDT` settling in USDT.
- The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`.
- Setup and fund recurring reward account transfers using the market_proposer metric and `USDT` metric asset:
  - Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA`
- During epoch 1 start trading such that traded value for fee purposes in USDT is less than 10^6 but greater than 10^5
- During epoch 2 update the value of `marketCreationQuantumMultiple` via governance to `10^5`.
  
#### Expectation 22

At the end of epoch 2, 10000 VEGA rewards should be distributed to the `ETHUSDT` creator.

- The general account balance of the `ETHUSDT` creator should be 10000.
- The reward pool balance should be 0.

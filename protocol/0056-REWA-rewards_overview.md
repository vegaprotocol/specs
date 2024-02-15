# Reward framework

The reward framework provides a mechanism for measuring and rewarding individuals or [teams](./0083-RFPR-on_chain_referral_program.md#glossary) (collectively referred to within this spec as entities) for a number of key activities on the Vega network.
These rewards operate in addition to the main protocol economic incentives which come from
[fees](0029-FEES-fees.md) on every trade.
These fees are the fundamental income stream for [liquidity providers LPs](0042-LIQF-setting_fees_and_rewarding_lps.md) and [validators](./0061-REWP-pos_rewards.md).

The additional rewards described here can be funded arbitrarily by users of the network and may be used by the project team, token holders (via governance), and individual traders and market makers to incentivise mutually beneficial behaviour.

Note that validator rewards (and the reward account for those) is covered in [validator rewards](./0061-REWP-pos_rewards.md) and is separate from the trading reward framework described here.

## New network parameter for market creation threshold

The parameter `rewards.marketCreationQuantumMultiple` will be used together with [quantum](0040-ASSF-asset_framework.md) to asses market size when deciding whether a market qualifies for the payment of market creation rewards.
It is reasonable to assume that `quantum` will be set to a value around `1 USD` (though there will likely be quite significant variation from this for assets that are not well correlated with USD).
Therefore, for example, to reward futures markets when they reach a lifetime traded notional over 1 mil USD, then this parameter should be set to around `1000000`. Any decimal value strictly greater than `0` is valid.

## Reward process high level

At a high level, rewards work as follows:

- Individual reward metrics are calculated for each combination of [reward type, party, market] and team reward metrics for each combination of [reward type, team, market].

At the end of the epoch:

1. Recurring reward transfers (set up by the parties funding the rewards or via governance) are made to the reward account(s) for a specific reward type, for one or more markets in scope where the total reward metric is `>0`. See [transfers](./0057-TRAN-transfers.md#recurring-transfers-to-reward-accounts).
1. Then the entire balance of each reward account is distributed amongst entities with a non-zero reward metric for that reward type and market using the mechanism specified in the recurring transfer.
1. Distributed rewards are transferred to a [vesting account](./0085-RVST-rewards_vesting.md).

## Individual reward metrics

Individual reward metrics are scoped by [`recurring transfer`, `market`, `party`] (this triplet can be thought of as a primary key for fee-based reward metrics).

Therefore a party may be in scope for the same reward type multiple times per epoch.
Metrics will be calculated at the end of every epoch, for every eligible party, in each market, for each recurring transfer.
Metrics only need to be calculated where the [market, reward type] reward account has a non-zero balance of at least one asset.

Reward metrics will be calculated once for each party/market combination in the reward metric asset which is the [settlement asset](0070-MKTD-market-decimal-places.md) of the market.
This is the original precision for the metric source data.

For reward metrics relating to trading, an individual must meet the [staking requirement](./0057-TRAN-transfers.md#recurring-transfers-to-reward-accounts) **AND** [notional time-weighted average position requirement](./0057-TRAN-transfers.md#recurring-transfers-to-reward-accounts)) set in the recurring transfer. If they do not then their reward metric is set to `0`. Note, these requirements do not apply to the [validator ranking metric](#validator-ranking-metric) or the [market creation reward metric](#market-creation-reward-metrics).

For reward transfers where the [scope](./0057-TRAN-transfers.md#recurring-transfers-to-reward-accounts) is set to teams, each party must meet the minimum time in team requirement. That is, given a party has been in a team for $N$ epochs, if $N$ is strictly less than the network parameter `rewards.minimumEpochsInTeam` (an integer defaulting to `0`) their reward metric is set to `0`.

### Fee-based reward metrics

There will be three reward metrics calculated based on fees.

1. Sum of maker fees paid by the party on the market this epoch
1. Sum of maker fees received by the party on the market this epoch
1. Sum of LP fees received by the party on the market this epoch

These metrics apply only to the sum of fees for the epoch in question.
That is, the metrics are reset to zero for all parties at the end of the epoch.
If the reward account balance is `0` at the end of the epoch for a given recurring transfer, any parties with non-zero metrics will not be rewarded for that epoch and their metric scores do not roll over (they are still zeroed).

Fee-based reward metrics (the total fees paid/received by each party as defined above) are stored in [LNL checkpoints](./0073-LIMN-limited_network_life.md) and are restored after a checkpoint restart to ensure rewards are not lost.

### Average position metric

The average position metric, $m_{ap}$, measures each parties time-weighted average position over a number of epochs.

At the start of each epoch, the network must reset each parties time weighted average position for the epoch ($\bar{P}$) to `0`. Whenever a parties position changes during an epoch, **and** at the end of the epoch, this value should be updated as follows.

Let:

- $\bar{P}$ be the parties time weighted average position in the epoch so far
- $P_{n}$ be the parties position before their position changed
- $t_{n}$ be the time the party held the previous position in seconds
- $t$ be the amount of time elapsed in the current epoch so far


$$\bar{P}  \leftarrow  \bar{P} \cdot \left(1 - \frac{t_{n}}{t}\right) + \frac{|P_{n}| \cdot t_{n}}{t}$$

At the end of the epoch, the network must store the parties time weighted average position and then calculate their average position reward metric as follows.

Let:

- $m_{ap}$ be the parties average position reward metric
- $\bar{P_{i}}$ be the parties time weighted average position in the $i$-th epoch
- $N$ be the window length specified in the recurring transfer.

$$m_{ap} = \frac{\sum_{i}^{n}\bar{P_{i}}}{N}$$

### Relative return metric

The relative return metric, $m_{rr}$, measures each parties average relative return, weighted by their [time-weighted average position](#average-position-metric), over a number of epochs.

At the end of each epoch, the network must calculate and store the parties relative returns as follows.

Let:

- $r_i$ be the parties relative returns in the epoch
- $m2m_{wins}$ be the sum of all mark-to-market win transfers in the epoch
- $m2m_{losses}$ be the sum of all mark-to-market loss transfers in the epoch
- $\bar{P}$ be the parties time-weighted average position in the epoch.

$$r = \frac{|m2m_{wins}| - |m2m_{losses}|}{\bar{P}}$$

And calculate their average relative returns over the last $N$ epochs as follows.

Let:

- $m_{rr}$ be the parties relative return reward metric
- $r_i$ be the parties change in pnl in the i th epoch
- $N$ be the window length specified in the recurring transfer.

$$m_{rr} = \max(\frac{\sum_{i}^{n}{r_{i}}}{N}, 0)$$

### Returns volatility metric

The return volatility metric, $m_{rv}$, measures the volatility of a parties returns across a number of epochs.

At the end of an epoch, if a party has had net returns less than or equal to `0` over the last $N$ epochs (where $N$ is the window length specified in the recurring transfer), their reward metric $m_{rv}$ is set to `0`. Otherwise, the network should calculate the variance of the set of each parties returns over the last $N$ epochs.

Given the set:

$$R = \{r_i \mid i = 1, 2, \ldots, N\}$$

The reward metric $m_{rv}$ is the variance of the set $R$.

### Validator ranking metric

The validator ranking metric, $m_v$, measures the ranking score of consensus and standby validators.

At the end of each epoch, for each party who **is** a consensus or standby validator set their reward metric as follows.

$$m_v = ranking_score$$

If a party **is not** a consensus or standby validator, their reward metric is simply:

$$m_v = 0$$

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

Note this reward metric **is not** available for team rewards.

## Team reward metrics

All metrics (except [market creation](#market-creation-reward-metrics)) can be used to define the distribution of both individual rewards and team rewards.

A team’s reward metric is the average metric score of the top performing `n` % of team members by number where `n` is specified when creating the recurring transfer (i.e. for a team of 100 parties with `n=0.1`, the 10 members with the highest metric score).

## Reward accounts

Trading reward accounts are defined by a hash of the fields specified in the recurring transfer funding the reward account (see the [transfers](./0057-TRAN-transfers.md#recurring-transfers-to-reward-accounts) spec for relevant details about each field). This allows multiple recurring transfers to fund the same reward pool.

Note as part of the recurring transfer a user specifies a settlement asset. The market settlement asset has nothing to do in in particular with the asset used to pay out a reward.

That is, a participant might receive rewards in the settlement asset of the market, in VEGA governance tokens, and in any number of other unrelated tokens (perhaps governance of "loyalty"/reward tokens issued by LPs or market creators, or stablecoins like DAI).

Reward accounts are funded by setting up recurring transfers, which may be set to occur only once for a one off reward. These allow a reward type to be automatically funded on an ongoing basis from a pool of assets.
Recurring transfers can target groups of markets, or all markets for a settlement asset. See [transfers](./0057-TRAN-transfers.md) for more detail.

Reward accounts and balances must be saved in [LNL checkpoints](./0073-LIMN-limited_network_life.md) to ensure all funds remain accounted for across a restart.

## Reward distribution

All rewards are distributed to [vesting accounts](./0085-RVST-rewards_vesting.md) at the end of each epoch *after* [recurring transfers](0057-TRAN-transfers.md) have been executed. Funds distributed to the vesting account will not start vesting until the [`lock period`](./0057-TRAN-transfers.md#recurring-transfers-to-reward-accounts) defined in the recurring transfer has expired.

The entire reward account balance is paid out every epoch unless the total value of the metric over all entities is zero, in which case the balance will also be zero anyway (there are no fractional payouts).

Rewards are first [distributed amongst entities](#distributing-rewards-amongst-entities) (individuals or teams) and then any rewards distributed to teams are [distributed amongst team members](#distributing-rewards-amongst-team-members).

### Distributing rewards amongst entities

Rewards are distributed amongst entities based on the distribution method defined in the recurring transfer.

The protocol currently supports the following distribution strategies:

- [pro-rata]:(#distributing-pro-rata) distributed pro-rata by reward metric
- [rank]:(#distributing-based-on-rank) distributed by entities rank when ordered by reward metric

#### Distributing pro-rata

Rewards funded using the pro-rata strategy should be distributed pro-rata by each entities reward metric scaled by any active multipliers that party has, i.e.

Let:

- $d_{i}$ be the payout factor for entity $i$
- $r_{i}$ be the reward metric value for entity $i$
- $M_{i}$ be the sum of all reward payout multipliers for entity $i$ (reward payout multipliers include the [activity streak multiplier](./0086-ASPR-activity_streak_program.md#applying-the-activity-reward-multiplier) and [bonus rewards multiplier](./0085-RVST-rewards_vesting.md#determining-the-rewards-bonus-multiplier)).
- $s_{i}$ be the share of the rewards for entity $i$

$$d_{i}=r_{i} M_{i}$$

Note if the entity is a team, $M_{i}$ is set to `1` as reward payout multipliers are considered later when distributing rewards [amongst the team members](#distributing-rewards-amongst-team-members).

Calculate each entities share of the rewards, $s_{i}$ pro-rata based on $d_{i}$, i.e.

$$s_{i} = \frac{d_{i}}{\sum_{i=1}^{n}d_{i}}$$

#### Distributing based on rank

Rewards funded using the rank-distribution strategy should be distributed as follows.

1. Calculate each entity's reward metric.
2. Arrange all entities in a list in descending order based on their reward metric values and determine their rank. If multiple entities share the same reward metric value, they should be assigned the same rank. The next entity's rank should be adjusted to account for the shared rank among the previous entities. For instance, if two entities share rank 2, the next entity should be assigned rank 4 (since there are two entities with rank 2).
3. Set the entities `share_ratio` based on their position in the `rank_table` specified in the recurring transfer.
4. Calculate each entities share of the rewards.

```pseudo
Given:
    rank_table = [
        {"start_rank": 1, "share_ratio": 10},
        {"start_rank": 2, "share_ratio": 5},
        {"start_rank": 4, "share_ratio": 2},
        {"start_rank": 10, "share_ratio": 1},
        {"start_rank": 20, "share_ratio": 0},
    ]
    rank=6

Then:
    share_ratio=2
```

Calculate each entities share of the rewards as follows.

Let:

- $d_{i}$ be the payout factor for entity $i$
- $s_{i}$ be the share of the rewards for entity $i$
- $r_{i}$ be the share ratio of entity $i$ as determined from the rank table
- $M_{i}$ be the sum of all reward payout multipliers for entity $i$ (reward payout multipliers include the [activity streak multiplier](./0086-ASPR-activity_streak_program.md#applying-the-activity-reward-multiplier) and [bonus rewards multiplier](./0085-RVST-rewards_vesting.md#determining-the-rewards-bonus-multiplier)).

$$d_{i}=M_{i} * r_{i}$$

Note if the entity is a team, $M_{i}$ is set to 1 as reward payout multipliers are considered later when distributing rewards [amongst the team members](#distributing-rewards-amongst-team-members).

Calculate each entities share of the rewards, $s_{i}$ pro-rata based on $d_{i}$, i.e.

$$s_{i} = \frac{d_{i}}{\sum_{i=1}^{n}d_{i}}$$

### Distributing rewards amongst team members

If rewards are distributed to a team, rewards must then be distributed between team members who had a reward metric, $m$, greater than `0` based on their payout multipliers.

Let:

- $d_{i}$ be the payout for team member $i$
- $s_{i}$ be the share of the rewards for team member $i$
- $m$ be the reward metric of the team member
- $M_{i}$ be the sum of all reward payout multipliers for entity $i$ (reward payout multipliers include the [activity streak multiplier](./0086-ASPR-activity_streak_program.md#applying-the-activity-reward-multiplier) and [bonus rewards multiplier](./0085-RVST-rewards_vesting.md#determining-the-rewards-bonus-multiplier)).

$$d_{i} = \begin{cases}
   0 &\text{if } m = 0 \\
   M_{i} &\text{if } m > 0
\end{cases}$$

Calculate each parties share of the rewards, $s_{i}$ pro-rata based on $d_{i}$, i.e.

$$s_{i} = \frac{d_{i}}{\sum_{i=1}^{n}d_{i}}$$

## Acceptance criteria

### Funding reward accounts (<a name="0056-REWA-001" href="#0056-REWA-001">0056-REWA-001</a>)

for product spot: (<a name="0056-REWA-062" href="#0056-REWA-062">0056-REWA-062</a>)

Trading reward accounts are defined by a pair: [`payout_asset, dispatch_strategy`].

There are two assets configured on the Vega chain: $VEGA and USDT.

Setup a recurring transfer of 1000 $VEGA with the following dispatch strategy: asset=`USDT`, metric=`DISPATCH_METRIC_TAKER_FEES_PAID`, markets=[].
Create 3 markets settling in USDT. Wait for a new epoch to begin, in the next epoch generate fees in the markets with the following distribution:
`Market1` contributes 20% of the fees, `market2` contributes 30% of the fees and `market3` contributes 50% of the fees - e.g. in `market1` 200 USDT were paid in taker fees, in `market2` 300 USDT and in `market3` 500. At the time the transfer is distributed, expect the reward accounts for the corresponding markets are funded proportionally to the contribution defined above, so if the transfer is of 1000 $VEGA, then `market1` is funded with 200, `market2` is funded with 300 and `market3` is funded with 500.

Run for another epoch with no fee generated. Expect no transfer to be made to the reward pools of the accounts.

### Funding reward accounts - with markets in scope (<a name="0056-REWA-002" href="#0056-REWA-002">0056-REWA-002</a>)

for product spot: (<a name="0056-REWA-061" href="#0056-REWA-061">0056-REWA-061</a>)

There are two assets configured on the Vega chain: $VEGA and USDT.

Setup a recurring transfer of 1000 $VEGA with the following dispatch strategy: asset=`USDT`, metric=`DISPATCH_METRIC_TAKER_FEES_PAID`, markets=[`market1`, `market2`].
Create 3 markets settling in USDT. Wait for a new epoch to begin, in the next epoch generate fees in the markets with the following distribution:
`Market1` contributes 20% of the fees, `market2` contributes 30% of the fees and `market3` contributes 50% of the fees - e.g. in `market1` 200 USDT were paid in taker fees, in `market2` 300 USDT and in `market3` 500. At the time the transfer is distributed, expect the reward accounts for the corresponding markets are funded proportionally to the contribution defined above, so if the transfer is of 1000 $VEGA, then `market1` is funded with 400, `market2` is funded with 600 and `market3` is funded with 0.

Run for another epoch with no fee generated. Expect no transfer to be made to the reward pools of the accounts.

### Distributing fees paid rewards (<a name="0056-REWA-010" href="#0056-REWA-010">0056-REWA-010</a>)

for product spot: (<a name="0056-REWA-060" href="#0056-REWA-060">0056-REWA-060</a>)

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

### Distributing fees paid rewards - unfunded account (<a name="0056-REWA-011" href="#0056-REWA-011">0056-REWA-011</a>)

for product spot: (<a name="0056-REWA-059" href="#0056-REWA-059">0056-REWA-059</a>)

#### Rationale 2

This is identical to [acceptance code `REWA 010`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-fees-paid-rewards-0056-rewa-010) just without funding the corresponding reward account.

#### Setup 2

Identical to [acceptance code `REWA 010`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-fees-paid-rewards-0056-rewa-010)

#### Funding reward accounts 2

No funding done.

#### Expectation 2

At the end of epoch 2 although there was trading in the market `ETHUSD-MAR22`, no reward is given to any participant as the reward account was not funded.

### Distributing fees paid rewards - funded account - no trading activity (<a name="0056-REWA-012" href="#0056-REWA-012">0056-REWA-012</a>)

for product spot: (<a name="0056-REWA-058" href="#0056-REWA-058">0056-REWA-058</a>)

#### Rationale 3

After having an epoch with trading activity, fund the reward account, but have no trading activity and assert that no payout is made.

#### Setup 3

Identical to [acceptance code `REWA 010`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-fees-paid-rewards-0056-rewa-010)

#### Funding reward accounts 3

Identical to [acceptance code `REWA 010`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-fees-paid-rewards-0056-rewa-010)

Then, during epoch 3 we fund the reward accounts for the metric:

- `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
  - `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of fees paid | $VEGA` in epoch `3`. (`ETHUSD-MAR22` is just brevity, this should be the market id not name).
  - `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of fees paid | $USDC` in epoch `3`. (`ETHUSD-MAR22` is just brevity, this should be the market id not name).

#### Expectation 3

Looking only at epoch 3 - as no trading activity was done, we expect the reward balances in both $VEGA and USDC for the metric to remain unchanged.

### Distributing fees paid rewards - multiple markets (<a name="0056-REWA-013" href="#0056-REWA-013">0056-REWA-013</a>)

for product spot: (<a name="0056-REWA-057" href="#0056-REWA-057">0056-REWA-057</a>)

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

The calculation of eligibility is identical to [acceptance code `REWA 010`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-fees-paid-rewards-0056-rewa-010) but the expected payout is:

- for market `ETHUSD-MAR22`:
  - `party_1` is paid `90 x 3.36 / 4.98 = 60.72.` $VEGA from the reward account into its $VEGA general account.
  - `party_2` is paid `90 x 1.62 / 4.98 = 29.28.` $VEGA from the reward account into its $VEGA general account.
- for market `ETHUSD-Jun22`:
  - `party_1` is paid `120 x 3.36 / 4.98 = 80.96.` $VEGA from the reward account into its $VEGA general account.
  - `party_2` is paid `120 x 1.62 / 4.98 = 39.03.` $VEGA from the reward account into its $VEGA general account.

### Distributing maker fees received rewards (<a name="0056-REWA-020" href="#0056-REWA-020">0056-REWA-020</a>)

for product spot: (<a name="0056-REWA-056" href="#0056-REWA-056">0056-REWA-056</a>)

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

### Distributing maker fees received rewards - unfunded account (<a name="0056-REWA-021" href="#0056-REWA-021">0056-REWA-021</a>)

for product spot: (<a name="0056-REWA-055" href="#0056-REWA-055">0056-REWA-055</a>)

#### Rationale 6

This is identical to [acceptance code `REWA 020`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020) just without funding the corresponding reward account.

#### Setup 6

Identical to [acceptance code `REWA 020`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020).

#### Funding reward accounts 6

No funding done.

#### Expectation 6

At the end of epoch 2 although there was trading in the market `ETHUSD-MAR22`, no reward is given to any participant as the reward account was not funded.

### Distributing maker fees received rewards - funded account - no trading activity (<a name="0056-REWA-022" href="#0056-REWA-022">0056-REWA-022</a>)

for product spot: (<a name="0056-REWA-054" href="#0056-REWA-054">0056-REWA-054</a>)

#### Rationale 7

After having an epoch with trading activity, fund the reward account, but have no trading activity and assert that no payout is made.

#### Setup 7

Identical to [acceptance code `REWA 020`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020)

#### Funding reward accounts 7

Identical to [acceptance code `REWA 020`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020)

Then, during epoch 3 we fund the reward accounts for the metric:

- `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
  - `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of maker fees received | VEGA` in epoch `3`.
  - `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of maker fees received | USDC` in epoch `3`.

#### Expectation 7

Looking only at epoch 3 - as no trading activity was done, we expect the reward balances in both $VEGA and USDC for the metric to remain unchanged.

### Distributing maker fees received rewards - multiple markets (<a name="0056-REWA-023" href="#0056-REWA-023">0056-REWA-023</a>)

for product spot: (<a name="0056-REWA-053" href="#0056-REWA-053">0056-REWA-053</a>)

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

The calculation of eligibility is identical to [acceptance code `REWA 020`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020) but the expected payout is:

- for market `ETHUSD-MAR22`:
  - At the end of epoch `2` `party_1` is paid `90 x 2.79 / (2.79+2.8)` $VEGA from the reward account into its `$VEGA` general account.
  - At the end of epoch `2` `party_0` is paid `90 x 2.8 / (2.79+2.8)` $VEGA from the reward account into its `$VEGA` general account.
- for market `ETHUSD-Jun22`:
  - At the end of epoch `2` `party_1` is paid `120 x 2.79 / (2.79+2.8)` USDC from the reward account into its `$VEGA` general account.
  - At the end of epoch `2` `party_0` is paid `120 x 2.8 / (2.79+2.8)` USDC from the reward account into its `$VEGA` general account.

### Distributing LP fees received rewards (<a name="0056-REWA-030" href="#0056-REWA-030">0056-REWA-030</a>)

for product spot: (<a name="0056-REWA-052" href="#0056-REWA-052">0056-REWA-052</a>)

#### Rationale 9

A market has 2 reward accounts for the metric, one paying in $VEGA and the other paying in USDC.

#### Setup 9

Identical to [acceptance code `REWA 020`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020).

#### Funding reward accounts 9

Identical to [acceptance code `REWA 020`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards-0056-rewa-020).

#### Expectation 9

At the end of epoch `2` the metric `sum of lp fees received` for `party_0` is:

```math
10 x 2790 x 0.0003 + 10 x 2800 x 0.0003 = 16.77
```

At the end of epoch `2` `party_0` is paid `90` `$VEGA` from the reward account into its `$VEGA` general account.
At the end of epoch `2` `party_0` is paid `120` `USDC` from the reward account into its `USDC` general account.

### Distributing LP fees received rewards - unfunded account (<a name="0056-REWA-031" href="#0056-REWA-031">0056-REWA-031</a>)

for product spot:
(<a name="0056-REWA-051" href="#0056-REWA-051">0056-REWA-051</a>)

#### Rationale 10

Identical to [acceptance code `REWA-030`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-lp-fees-received-rewards-0056-rewa-030), but without funding the corresponding reward account.

#### Setup 10

Identical to [acceptance code `REWA-030`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-lp-fees-received-rewards-0056-rewa-030)

#### Funding reward accounts 10

No funding done.

#### Expectation 10

At the end of epoch 2 although there was trading in the market `ETHUSD-MAR22`, no reward is given to any participant as the reward account was not funded.

### Distributing maker fees received  rewards - funded account - no trading activity (<a name="0056-REWA-032" href="#0056-REWA-032">0056-REWA-032</a>)

for product spot: (<a name="0056-REWA-063" href="#0056-REWA-063">0056-REWA-063</a>)

#### Rationale 11

After having an epoch with trading activity, fund the reward account, but have no trading activity and assert that no payout is made.

#### Setup 11

Identical to [acceptance code `REWA-030`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-lp-fees-received-rewards-0056-rewa-030)

#### Funding reward accounts 11

Identical to [acceptance code `REWA-030`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-lp-fees-received-rewards-0056-rewa-030)

Then, during epoch 3 we fund the reward accounts for the metric:

- `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
  - `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of LP fees received | VEGA` in epoch `3`.
  - `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of LP fees received | USDC` in epoch `3`.

#### Expectation 11

Looking only at epoch 3 - as no trading activity was done, we expect the reward balances in both $VEGA and USDC for the metric to remain unchanged.

### Distributing LP fees received - multiple markets (<a name="0056-REWA-033" href="#0056-REWA-033">0056-REWA-033</a>)

for product spot: (<a name="0056-REWA-064" href="#0056-REWA-064">0056-REWA-064</a>)

#### Rationale 12

There are multiple markets, each paying its own reward where due.

#### Setup 12

Identical to [acceptance code `REWA-023`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-maker-fees-received-rewards---multiple-markets-0056-rewa-023)

#### Funding reward accounts 12

- `party_R` is funding multiple the reward accounts for both markets:
  - `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of LP fees received | $VEGA` in epoch `2`.
  - `party_R` makes a transfer of `120` `$VEGA` to `ETHUSD-JUN22 | Sum of LP fees received | $VEGA` in epoch `2`.

#### Expectation 12

The calculation of eligibility is identical to [acceptance code `REWA-030`](https://github.com/vegaprotocol/specs/blob/master/protocol/0056-REWA-rewards_overview.md#distributing-lp-fees-received-rewards-0056-rewa-030) but the expected payout is:

- for market `ETHUSD-MAR22`:
  - At the end of epoch `2` `party_0` is paid `90` `$VEGA` from the reward account into its `$VEGA` general account.
- for market `ETHUSD-Jun22`:
  - t the end of epoch `2` `party_0` is paid `120` `USDC` from the reward account into its `USDC` general account.

### Distributing market creation rewards - no eligibility (<a name="0056-REWA-040" href="#0056-REWA-040">0056-REWA-040</a>)

for product spot: (<a name="0056-REWA-065" href="#0056-REWA-065">0056-REWA-065</a>)

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

### Distributing market creation rewards - eligible are paid no more than once (<a name="0056-REWA-041" href="#0056-REWA-041">0056-REWA-041</a>)

for product spot: (<a name="0056-REWA-066" href="#0056-REWA-066">0056-REWA-066</a>)

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

### Distributing market creation rewards - account funded after reaching requirement (<a name="0056-REWA-042" href="#0056-REWA-042">0056-REWA-042</a>)

for product spot: (<a name="0056-REWA-067" href="#0056-REWA-067">0056-REWA-067</a>)

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

### Distributing market creation rewards - multiple asset rewards (<a name="0056-REWA-043" href="#0056-REWA-043">0056-REWA-043</a>)

for product spot: (<a name="0056-REWA-068" href="#0056-REWA-068">0056-REWA-068</a>)

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

### Distributing market creation rewards - multiple asset rewards simultaneous payout (<a name="0056-REWA-045" href="#0056-REWA-045">0056-REWA-045</a>)

for product spot: (<a name="0056-REWA-069" href="#0056-REWA-069">0056-REWA-069</a>)

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

### Distributing market creation rewards - Same asset multiple party rewards (<a name="0056-REWA-044" href="#0056-REWA-044">0056-REWA-044</a>)

for product spot: (<a name="0056-REWA-070" href="#0056-REWA-070">0056-REWA-070</a>)

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

### Distributing market creation rewards - Multiple markets eligible, one already paid (<a name="0056-REWA-046" href="#0056-REWA-046">0056-REWA-046</a>)

for product spot: (<a name="0056-REWA-071" href="#0056-REWA-071">0056-REWA-071</a>)

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

### Reward accounts cannot be topped up with a one-off transfer (<a name="0056-REWA-049" href="#0056-REWA-049">0056-REWA-049</a>)

for product spot: (<a name="0056-REWA-072" href="#0056-REWA-072">0056-REWA-072</a>)

The following account types require metric-based distribution. As a one-off transfer cannot specify how it is rewarded, one-off transfers to metric-based reward pools must be **rejected**.
A one-off transfer from a user to any of the following account types is rejected. No assets are transferred:

- `ACCOUNT_TYPE_REWARD_LP_RECEIVED_FEES`,
- `ACCOUNT_TYPE_REWARD_MAKER_RECEIVED_FEES`,
- `ACCOUNT_TYPE_REWARD_TAKER_PAID_FEES`,
- `ACCOUNT_TYPE_REWARD_MARKET_PROPOSERS`

### Distributing market creation rewards - Market ineligible through metric asset (<a name="0056-REWA-048" href="#0056-REWA-048">0056-REWA-048</a>)

for product spot: (<a name="0056-REWA-073" href="#0056-REWA-073">0056-REWA-073</a>)

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

### Distributing market creation rewards - Multiple markets eligible, one already paid, specified asset (<a name="0056-REWA-047" href="#0056-REWA-047">0056-REWA-047</a>)

for product spot: (<a name="0056-REWA-074" href="#0056-REWA-074">0056-REWA-074</a>)

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

### Updating the network parameter `rewards.marketCreationQuantumMultiple` (<a name="0056-REWA-050" href="#0056-REWA-050">0056-REWA-050</a>)

for product spot: (<a name="0056-REWA-075" href="#0056-REWA-075">0056-REWA-075</a>)

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

### Reward Eligibility

- If a parties staked governance tokens ($VEGA) is strictly less than the `staking_requirement` specified in the recurring transfer funding the reward pool, then their reward metric should be `0` and they should receive no rewards (<a name="0056-REWA-076" href="#0056-REWA-076">0056-REWA-076</a>).
- If a parties time-weighted average position (across all in scope-markets) is strictly less than the `notional_time_weighted_average_position_requirement` specified in the recurring transfer funding the reward pool, then their reward metric should be `0` and they should receive no rewards (<a name="0056-REWA-077" href="#0056-REWA-077">0056-REWA-077</a>).

### Average Position

- If an eligible party opens a position at the beginning of the epoch, their average position reward metric should be equal to the size of the position at the end of the epoch (<a name="0056-REWA-078" href="#0056-REWA-078">0056-REWA-078</a>).
- If an eligible party held an open position at the start of the epoch, their average position reward metric should be equal to the size of the position at the end of the epoch (<a name="0056-REWA-079" href="#0056-REWA-079">0056-REWA-079</a>).
- If an eligible party opens a position half way through the epoch, their average position reward metric should be half the size of the position at the end of the epoch (<a name="0056-REWA-080" href="#0056-REWA-080">0056-REWA-080</a>).
- If an eligible party held an open position at the start of the epoch and closes it half-way through the epoch, their average position reward metric should be equal to the size of that position at the end of the epoch (<a name="0056-REWA-081" href="#0056-REWA-081">0056-REWA-081</a>).
- If an eligible party held positions in multiple in-scope markets, their average position reward metric should be the sum of the size of their time-weighted-average-position in each market (<a name="0056-REWA-082" href="#0056-REWA-082">0056-REWA-082</a>).
- If a `window_length>1` is specified in the recurring transfer, an eligible parties average position reward metric should be the average of their reward metrics over the last `window_length` epochs (<a name="0056-REWA-083" href="#0056-REWA-083">0056-REWA-083</a>).

### Relative returns

- If an eligible party has negative net returns, their relative returns reward metric should be zero (<a name="0056-REWA-084" href="#0056-REWA-084">0056-REWA-084</a>).
- If an eligible party has positive net returns, their relative returns reward metric should be equal to the size of their returns divided by their time-weighted average position (<a name="0056-REWA-085" href="#0056-REWA-085">0056-REWA-085</a>).
- If an eligible party is participating in multiple in-scope markets, their relative returns reward metric should be the sum of their relative returns from each market (<a name="0056-REWA-086" href="#0056-REWA-086">0056-REWA-086</a>).
- If a `window_length>1` is specified in the recurring transfer, an eligible parties relative returns reward metric should be the average of their reward metrics over the last `window_length` epochs (<a name="0056-REWA-087" href="#0056-REWA-087">0056-REWA-087</a>).

### Returns volatility

- If an eligible party has net relative returns less than or equal to `0` over the last `window_length` epochs, their returns volatility reward metric should be zero (<a name="0056-REWA-088" href="#0056-REWA-088">0056-REWA-088</a>).
- If an eligible party has net relative returns strictly greater than `0` over the last `window_length` epochs, their returns volatility reward metric should equal the variance of their relative returns over the last `window_length` epochs (<a name="0056-REWA-089" href="#0056-REWA-089">0056-REWA-089</a>).
- If an eligible party has net relative returns strictly greater than `0` over the last `window_length` epochs in multiple in-scope markets, their return volatility reward metric should be the variance of their relative returns in each market (<a name="0056-REWA-090" href="#0056-REWA-090">0056-REWA-090</a>).

### Validator ranking metric

- If a party is a consensus or standby validator their validator ranking reward metric should be set to their ranking score (<a name="0056-REWA-091" href="#0056-REWA-091">0056-REWA-091</a>).
- If a party is not a consensus or standby validator their validator ranking reward metric should be set to `0` (<a name="0056-REWA-092" href="#0056-REWA-092">0056-REWA-092</a>).
- For a party that is a consensus or standby validator, the [staking requirement](https://github.com/vegaprotocol/specs/blob/palazzo/protocol/0057-TRAN-transfers.md#recurring-transfers-to-reward-accounts) and [notional time-weighted average position requirement](https://github.com/vegaprotocol/specs/blob/palazzo/protocol/0057-TRAN-transfers.md#recurring-transfers-to-reward-accounts) do not apply to their validator ranking metric.  (<a name="0056-REWA-109" href="#0056-REWA-109">0056-REWA-109</a>).
- A party does not need to meet the staking requirements and notional time-weighted average position set in the recurring transfer for market creation reward metric.  (<a name="0056-REWA-110" href="#0056-REWA-110">0056-REWA-110</a>).

### Distribution Strategy

- If the pro-rata distribution strategy was specified in the recurring transfer, each eligible parties share of the rewards pool should be equal to their reward metric (assuming no other multipliers) (<a name="0056-REWA-093" href="#0056-REWA-093">0056-REWA-093</a>).
- If the rank distribution strategy was specified in the recurring transfer, each eligible parties share of the reward pool should be equal to the `share_ratio` defined by their position in the `rank_table` (assuming no other multipliers) (<a name="0056-REWA-094" href="#0056-REWA-094">0056-REWA-094</a>).


### Entity Scope

#### Individuals

- If the entity scope is `ENTITY_SCOPE_INDIVIDUALS`, transfers setting the `teams_scope` field should be rejected as invalid (<a name="0056-REWA-095" href="#0056-REWA-095">0056-REWA-095</a>).
- If the entity scope is `ENTITY_SCOPE_INDIVIDUALS`, transfers not setting the `individual_scope` field should be rejected as invalid (<a name="0056-REWA-096" href="#0056-REWA-096">0056-REWA-096</a>).
- If the entity scope is `ENTITY_SCOPE_INDIVIDUALS` and the individual scope is `INDIVIDUAL_SCOPE_ALL`, all individual parties should be eligible for rewards providing they meet all other eligibility conditions (<a name="0056-REWA-097" href="#0056-REWA-097">0056-REWA-097</a>).
- If the entity scope is `ENTITY_SCOPE_INDIVIDUALS` and the individual scope is `INDIVIDUAL_SCOPE_IN_A_TEAM`, only individual parties who are in a team should be eligible for rewards providing they meet all other eligibility conditions (<a name="0056-REWA-098" href="#0056-REWA-098">0056-REWA-098</a>).
- If the entity scope is `ENTITY_SCOPE_INDIVIDUALS` and the individual scope is `INDIVIDUAL_SCOPE_NOT_IN_A_TEAM`, only individual parties not in a team should be eligible for rewards providing they meet all other eligibility conditions (<a name="0056-REWA-099" href="#0056-REWA-099">0056-REWA-099</a>).
- If the entity scope is `ENTITY_SCOPE_INDIVIDUALS`, rewards should be distributed among eligible individual parties according to each parties reward metric value (<a name="0056-REWA-100" href="#0056-REWA-100">0056-REWA-100</a>).

#### Teams

- If the entity scope is `ENTITY_SCOPE_TEAMS`, transfers setting the `individual_scope` field should be rejected as invalid (<a name="0056-REWA-101" href="#0056-REWA-101">0056-REWA-101</a>).
- If the entity scope is `ENTITY_SCOPE_TEAMS` transfers not setting the `n_top_performers` field should be rejected as invalid (<a name="0056-REWA-102" href="#0056-REWA-102">0056-REWA-102</a>).
- If the entity scope is `ENTITY_SCOPE_TEAMS` and the teams scope is not-set, then all teams are eligible for rewards (<a name="0056-REWA-103" href="#0056-REWA-103">0056-REWA-103</a>).
- If the entity scope is `ENTITY_SCOPE_TEAMS` and the teams scope is set, then only the teams specified in the teams scope are eligible for rewards (<a name="0056-REWA-104" href="#0056-REWA-104">0056-REWA-104</a>).
- If the entity scope is `ENTITY_SCOPE_TEAMS`, then rewards should be allocated to teams according to each teams reward metric value (<a name="0056-REWA-105" href="#0056-REWA-105">0056-REWA-105</a>).
- Each team’s reward metric should be the average metric of the top `n_top_performers` % of team members, e.g. for a team of 100 parties with `n_top_performers=0.1`, the 10 members with the highest metric (<a name="0056-REWA-106" href="#0056-REWA-106">0056-REWA-106</a>).
- If a team member has a non-zero reward metric, they should receive a share of the rewards proportional to their individual payout multipliers (<a name="0056-REWA-107" href="#0056-REWA-107">0056-REWA-107</a>).
- If a team member has a zero reward metric, they should receive no share of the rewards allocated to the team (<a name="0056-REWA-108" href="#0056-REWA-108">0056-REWA-108</a>).

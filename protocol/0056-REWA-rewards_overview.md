# Reward framework

The reward framework provides a mechanism for measuring and rewarding a number of key activties on the Vega network. 
These rewards operate in addition to the main protocol economic incentives which come from 
[fees](0029-FEES-fees.md) on every trade. 
These fees are the fundamental income stream for [liquidity providers LPs](0042-LIQF-setting_fees_and_rewarding_lps.md) and [validators](0061-REWP-simple_pos_rewards_sweetwater.md). 

The additional rewards described here can be funded arbitrarily by users of the network and may be used by the project team, token holders (via governance), and individual traders and market makers to incentivise mutually beneficial behaviour.
Note that transfers via governance, including to fund rewards, is a post-Oregon Trail feature.

Note that validator rewards (and the reward account for those) is covered in [validator rewards](0061-REWP-simple_pos_rewards_sweetwater.md) and is separate from the trading reward framework described here. 


## New network parameter for market creation threshold

The parameter `rewards.marketCreationQuantumMultiple` will be used together with [quantum](0040-ASSF-asset_framework.md) to asses market size when deciding whether a market qualifies for the payment of market creation rewards. 
It is reasonable to assume that `quantum` will be set to a value around `1 USD` (though there will likely be quite significant variation from this for assets that are not well correlated with USD).
Therefore, for example, to reward futures markets when they reach a lifetime traded notional over 1 mil USD, then this parameter should be set to around `1000000`. Any decimal value strictly greater than `0` is valid. 


## Reward process high level

At a high level, rewards work as follows:

- Reward metrics are calculated for each combination of [reward type, party, market].
 The calculation used for the reward metric is specific to each reward type.
-  A transfer is made to the reward account(s) for a specific reward type, for one or more markets. This is either a one-off transfer for a single market, or a recurring transfer for one, several, or all markets. (See [transfers](./0057-TRAN-transfers.md).)
- At the end of the epoch, the entire balance of each reward account is distributed to the parties with a non-zero reward metric pro-rata by their reward metric.
If the sum of all reward metrics is zero, the balance rolls over to the next epoch.


## Reward metrics

Reward metrics are scoped by [reward type, market, party] (this triplet can be thought of as a primary key for reward metrics).
Therefore a party may be in scope for the same reward type multiple times but no more than once per market.
Metrics will be calculated at the end of every epoch, for every eligible party, in each market for each reward type.
Metrics only need to be calculated where the [market, reward type] reward account has a non-zero balance of at least one asset. 


### Market activity (fee based) reward metrics

There will be three market activity reward metrics calculated based on fees (as a proxy for activity). 
Each of these represents a reward type with its own segregated reward accounts for each market.

1. Sum of maker fees paid by the party on the market this epoch
1. Sum of maker fees received by the party on the market this epoch
1. Sum of LP fees received by the party on the market this epoch

Theese metrics apply only to the sum of fees for the epoch in question.
That is, the metrics are reset to zero for all parties at the end of the epoch.
If the reward account balance is 0 at the end of the epoch for a given market, any parties with non-zero metrics will not be rewarded for that epoch and their metric scores do not roll over (they are still zeroed).

Market activity (fee based) reward metrics are not stored in [LNL checkpoints](./0073-LIMN-limited_network_life.md) and are reset after a checkpoint restart.


### Market creation reward metrics

There will be a single creation reward metricand reward tyype. 
This makes it possible to reward creation of markets achieving at least a minimum lifetime trading volume, as a proxy for identifying the creation of useful markets:

Where:

- there is a single eligible party for each market, which is the party that created the market by submitting the original new market governance proposal (**all other parties** have market creation metric = 0)
- `cumulative volume` is defined as the cumulative total [trade value for fee purposes](0029-FEES-fees.md)
- `rewards.marketCreationQuantumMultiple` is a network parameter described above
-  `quantum` is an asset level field described in the [asset framework](0040-ASSF-asset_framework.md)

The reward metric for the single *market creator* party is as follows:

- **IF** `cumulative volume < rewards.marketCreationQuantumMultiple * quantum` **THEN** `market creation metric := 0`
- **ELSE** `market creation metric := 1` (NB: this is 1 as market creation rewards are paid equally to all qualifying creators for *reaching* the volume threshold, not pro-rata based on cumulative volume)

When the `market creation metric` for a party is `>0` and the reward account balance for a specific reward asset is also `>0` (i.e. when a creator is rewarded):

- A flag is added for each of the recorded `funders` of the reward account paired with the market and reward asset.
This flag is used to prevent a recurring transfer from funding a creation reward in the same asset more than once.
See the [transfers](./0057-TRAN-transfers.md) spec.
- The list of funders for the reward account is cleared after the account is emptied (i.e. after one or more parties are rewarded for market creation).

Market creation reward metrics (both each market's `cumulative volume` and the `payout record flags` to identify [market, payout asset, funder] combinations that have already been rewarded) are stored in [LNL checkpoints](./0073-LIMN-limited_network_life.md) and will be restored after a checkpoint restart.



## Reward accounts

Trading reward accounts are defined by the reward asset (the asset in which the reward is paid out), the market, and the reward type (metric). 
That is, there can be multiple rewards with the same type paid in different assets for the same market.

Note that the market settlement asset has nothing to do in particular with the asset used to pay out a reward for a market. 
That is, a participant might recieve rewards in the settlement asset of the market, in VEGA governance tokens, and in any number of other unrelated tokens (perhaps governance of "loyalty"/reward tokens issued by LPs or market creators, or stablecoins like DAI).

Reward accounts can be individually funded by normal single transfers. They can also be funded on an ongoing (recurring) basis in groups, pro-rata by their relative total reward metrics for the given reward type. See [transfers](./0057-TRAN-transfers.md).

Reward accounts and balances must be saved in [LNL checkpoints](./0073-LIMN-limited_network_life.md) to ensure all funds remain accounted for accross a restart.


## Reward distribution

All rewards are paid out at the end of any epoch *after* [recurring transfers](0057-TRAN-Transfers.md) have been executed. 
The entire reward account balance is paid out every epoch unless the total value of the metric over all parties is zero (there are no fractional payouts). 
There are no payout delays, rewards are paid out instantly at epoch end.

Rewards will be distributed pro-rata by the party's reward metric value to all parties that have metric values `>0`. That is, if we have reward account balance `R` and parties `p_1 – p_n` with non-zero metrics on the market in question:

```
[p_1,m_1]
[p_2,m_2]
...
[p_n,m_n]
```

Then calculate `M:= m_1+m_2+...+m_n` and transfer `R x m_i / M` to party `p_i` (for each `p_i`) at the end of the epoch.

If `M = 0` (no-one incurred or received fees as specified by the metric type for a given *market scope*) then nothing is paid out of the reward account for that *market scope* and the balance rolls into next epoch. 

Rewards will be calculated using the [decimal precision of the settlement asset](0070-MKTD-market-decimal-places.md).


## Acceptance criteria

### Funding reward accounts (<a name="0056-REWA-001" href="#0056-REWA-001">0056-REWA-001</a>)

Trading reward accounts are defined by a pair: [`payout_asset, dispatch_strategy`].

There are two assets configured on the Vega chain: $VEGA and USDT. 

Setup a recurring transfer of 1000 $VEGA with the following dispatch strategy: asset=USDT, metric=DISPATCH_METRIC_TAKER_FEES_PAID, markets=[].
Create 3 markets settling in USDT. Wait for a new epoch to begin, in the next epoch generate fees in the markets with the following distribution:
Market1 contributes 20% of the fees, market2 contributes 30% of the fees and market3 contributes 50% of the fees - e.g. in market1 200 USDT were paid in taker fees, in market2 300 USDT and in market3 500. At the time the transafer is distributed, expect the reward accounts for the corresponding markets are funded proportionally to the contribution defined above, so if the transfer is of 1000 $VEGA, then market1 is funded with 200, market2 is funded with 300 and market3 is funded with 500. 

Run for another epoch with no fee generated. Expect no transfer to be made to the reward pools of the accounts. 

### Funding reward accounts - with markets in scope (<a name="0056-REWA-002" href="#0056-REWA-002">0056-REWA-002</a>)
There are two assets configured on the Vega chain: $VEGA and USDT. 

Setup a recurring transfer of 1000 $VEGA with the following dispatch strategy: asset=USDT, metric=DISPATCH_METRIC_TAKER_FEES_PAID, markets=[market1, market2].
Create 3 markets settling in USDT. Wait for a new epoch to begin, in the next epoch generate fees in the markets with the following distribution:
Market1 contributes 20% of the fees, market2 contributes 30% of the fees and market3 contributes 50% of the fees - e.g. in market1 200 USDT were paid in taker fees, in market2 300 USDT and in market3 500. At the time the transafer is distributed, expect the reward accounts for the corresponding markets are funded proportionally to the contribution defined above, so if the transfer is of 1000 $VEGA, then market1 is funded with 400, market2 is funded with 600 and market3 is funded with 0. 

Run for another epoch with no fee generated. Expect no transfer to be made to the reward pools of the accounts. 

### Distributing fees paid rewards (<a name="0056-REWA-010" href="#0056-REWA-010">0056-REWA-010</a>)

#### Rationale
A market has 2 reward accounts for the metric, one paying in $VEGA and the other paying in USDC. 

#### Setup
There are 3 assets configured on the Vega chain: $VEGA, USDT, USDC. 
There are no markets.

* `transfer.fee.factor` = 0
* `maker_fee` = 0.0001
* `infrastructure_fee` = 0.0002
*  `ETHUSD-MAR22` market which settles in USDT is launched anytime in epoch 1 by `party_0`
* `party_0` and `party_1` provide auction orders so there is a trade to leave the opening auction and the remaining best bid = 2700 and and best offer = 2800 are supplied by party_0 each with volume 10. 
* Moreover `party_0` provides liquidity with `liquidity_fee` = 0.0003 and offset + 10 (so their LP volume lands on 2690 and 2810).
* During epoch `2` we have `party_1` make one buy market order with volume `2`.
* During epoch `2` we have `party_2` make one sell market order each with notional `1`.

#### Funding reward accounts
* `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
   * `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of fees paid | VEGA` in epoch `2`. (`ETHUSD-MAR22` is just for brevity here, the transfer is specified by market id not its name).
   * `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of fees paid | USDC` in epoch `2`. (`ETHUSD-MAR22` is just for brevity here, the transfer is specified by market id not its name).


#### Expectation
At the end of epoch 2 the metric `sum of fees paid` for `party_1` should be:
```
2 x 2800 x (0.0001 + 0.0002 + 0.0003) = 3.36
```
and for `party_2` it is:
```
1 x 2700 x (0.0001 + 0.0002 + 0.0003) = 1.62
```

At the end of epoch 2:
* `party_1` is paid `90 x 3.36 / 4.98 = 60.72.` $VEGA from the reward account into its $VEGA general account. 
* `party_2` is paid `90 x 1.62 / 4.98 = 29.28.` $VEGA from the reward account into its $VEGA general account. 
* `party_1` is paid `120 x 3.36 / 4.98 = 80.96.` USDC from the reward account into its USDC general account. 
* `party_2` is paid `120 x 1.62 / 4.98 = 39.03.` USDC from the reward account into its USDC general account. 

### Distributing fees paid rewards - unfunded account (<a name="0056-REWA-011" href="#0056-REWA-011">0056-REWA-011</a>)

#### Rationale
This is identical to (<a name="0056-REWA-010" href="#0056-REWA-010">0056-REWA-010</a>) just without funding the corresponding reward account. 

#### Setup
Identical to (<a name="0056-REWA-010" href="#0056-REWA-010">0056-REWA-010</a>)

#### Funding reward accounts
No funding done.

#### Expectation
At the end of epoch 2 although there was trading in the market `ETHUSD-MAR22`, no reward is given to any participant as the reward account was not funded. 

### Distributing fees paid rewards - funded account - no trading activity (<a name="0056-REWA-012" href="#0056-REWA-012">0056-REWA-012</a>)
#### Rationale 
After having an epoch with trading activity, fund the reward account, but have no trading activity and assert that no payout is made. 

#### Setup
Identical to (<a name="0056-REWA-010" href="#0056-REWA-010">0056-REWA-010</a>)

#### Funding reward accounts
Identical to (<a name="0056-REWA-010" href="#0056-REWA-010">0056-REWA-010</a>)

Then, during epoch 3 we fund the reward accounts for the metric: 
* `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
   * `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of fees paid | $VEGA` in epoch `3`. (`ETHUSD-MAR22` is just brevity, this should be the market id not name).
   * `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of fees paid | $USDC` in epoch `3`. (`ETHUSD-MAR22` is just brevity, this should be the market id not name).

#### Expectation
Looking only at epoch 3 - as no trading activity was done, we expect the reward balances in both $VEGA and USDC for the metric to remain unchanged. 

### Distributing fees paid rewards - multiple markets (<a name="0056-REWA-013" href="#0056-REWA-013">0056-REWA-013</a>)
#### Rationale 
There are multiple markets, each paying its own reward where due. 

#### Setup
There are 3 assets configured on the Vega chain: $VEGA, USDT, USDC. 
There are no markets.

* `transfer.fee.factor` = 0
* `maker_fee` = 0.0001
* `infrastructure_fee` = 0.0002
*  `ETHUSD-MAR22` market which settles in USDT is launched anytime in epoch 1 by `party_0`
*  `ETHUSD-JUN22` market which settles in USDC is launched anytime in epoch 1 by `party_0`
* For each market in {`ETHUSD-MAR22`, `ETHUSD-JUN22`}
    * `party_0` and `party_1` provide auction orders so there is a trade to leave the opening auction and the remaining best bid = 2700 and and best offer = 2800 are supplied by party_0 each with volume 10. 
    * Moreover `party_0` provides liquidiity with `liquidity_fee` = 0.0003 and offset + 10 (so their LP volume lands on 2690 and 2810).
    * During epoch `2` we have `party_1` make one buy market order with volume `2`.
    * During epoch `2` we have `party_2` make one sell market order each with notional `1`.

#### Funding reward accounts
* `party_R` is funding multiple the reward accounts for both markets: 
   * `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of fees paid | $VEGA` in epoch `2`.
   * `party_R` makes a transfer of `120` `$VEGA` to `ETHUSD-JUN22 | Sum of fees paid | $VEGA` in epoch `2`.

#### Expectation
The calculation of eligibility is identical to (<a name="0056-REWA-010" href="#0056-REWA-010">0056-REWA-010</a>) but the expected payout is:
* for market `ETHUSD-MAR22`:
    * `party_1` is paid `90 x 3.36 / 4.98 = 60.72.` $VEGA from the reward account into its $VEGA general account. 
    * `party_2` is paid `90 x 1.62 / 4.98 = 29.28.` $VEGA from the reward account into its $VEGA general account. 
* for market `ETHUSD-Jun22`:
    * `party_1` is paid `120 x 3.36 / 4.98 = 80.96.` $VEGA from the reward account into its $VEGA general account. 
    * `party_2` is paid `120 x 1.62 / 4.98 = 39.03.` $VEGA from the reward account into its $VEGA general account. 

### Distributing maker fees received rewards (<a name="0056-REWA-020" href="#0056-REWA-020">0056-REWA-020</a>)

#### Rationale
A market has 2 reward accounts for the metric, one paying in $VEGA and the other paying in USDC. 

#### Setup
There are 3 assets configured on the Vega chain: $VEGA, USDT, USDC. 
There are no markets.

* `transfer.fee.factor` = 0
* `maker_fee` = 0.0001
* `infrastructure_fee` = 0.0002
*  `ETHUSD-MAR22` market which settles in USDT is launched anytime in epoch 1 by `party_0`
* `party_0` and `party_1` provide auction orders so there is a trade to leave the opening auction and the remaining best bid = 2700 and and best offer = 2800 are supplied by party_0 each with volume 10. 
* Moreover `party_0` provides liquidiity with `liquidity_fee` = 0.0003 and offset + 10 (so their LP volume lands on 2690 and 2810).
* During epoch 2 `party_1` puts a limit buy order of vol 10 at 2710 and a limit sell order of vol 10 at 2790
* After that, during epoch 2 `party_2` puts in a market buy order of volume 20.

#### Funding reward accounts
* `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
   * `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of maker fees received | VEGA` in epoch `2`. 
   * `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of maker fees received | USDC` in epoch `2`. 

#### Expectation
At the end of epoch `2` the metric `sum of maker fees received` for `party_1` should be:
```
10 x 2790 x 0.0001 = 2.79
```
and for `party_0` it is 
```
10 x 2800 x 0.0001 = 2.8
```

At the end of epoch `2` `party_1` is paid `90 x 2.79 / (2.79+2.8)` $VEGA from the reward account into its `$VEGA` general account. 
At the end of epoch `2` `party_0` is paid `90 x 2.8 / (2.79+2.8)` $VEGA from the reward account into its `$VEGA` general account. 
At the end of epoch `2` `party_1` is paid `120 x 2.79 / (2.79+2.8)` USDC from the reward account into its `USDC` general account. 
At the end of epoch `2` `party_0` is paid `120 x 2.8 / (2.79+2.8)` USDC from the reward account into its `USDC` general account. 


### Distributing maker fees received rewards - unfunded account (<a name="0056-REWA-021" href="#0056-REWA-021">0056-REWA-021</a>)

#### Rationale
This is identical to (<a name="0056-REWA-020" href="#0056-REWA-020">0056-REWA-020</a>) just without funding the corresponding reward account. 

#### Setup
Identical to (<a name="0056-REWA-020" href="#0056-REWA-020">0056-REWA-020</a>).

#### Funding reward accounts
No funding done.

#### Expectation
At the end of epoch 2 although there was trading in the market `ETHUSD-MAR22`, no reward is given to any participant as the reward account was not funded. 

### Distributing maker fees received  rewards - funded account - no trading activity (<a name="0056-REWA-022" href="#0056-REWA-022">0056-REWA-022</a>)
#### Rationale 
After having an epoch with trading activity, fund the reward account, but have no trading activity and assert that no payout is made. 

#### Setup
Identical to (<a name="0056-REWA-020" href="#0056-REWA-020">0056-REWA-020</a>)

#### Funding reward accounts
Identical to (<a name="0056-REWA-020" href="#0056-REWA-020">0056-REWA-020</a>)

Then, during epoch 3 we fund the reward accounts for the metric: 
* `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
   * `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of maker fees received | VEGA` in epoch `3`. 
   * `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of maker fees received | USDC` in epoch `3`. 

#### Expectation
Looking only at epoch 3 - as no trading activity was done, we expect the reward balances in both $VEGA and USDC for the metric to remain unchanged. 

### Distributing maker fees received rewards - multiple markets (<a name="0056-REWA-023" href="#0056-REWA-023">0056-REWA-023</a>)
#### Rationale 
There are multiple markets, each paying its own reward where due. 

#### Setup
There are 3 assets configured on the Vega chain: $VEGA, USDT, USDC. 
There are no markets.

* `transfer.fee.factor` = 0
* `maker_fee` = 0.0001
* `infrastructure_fee` = 0.0002
*  `ETHUSD-MAR22` market which settles in USDT is launched anytime in epoch 1 by `party_0`
*  `ETHUSD-JUN22` market which settles in USDC is launched anytime in epoch 1 by `party_0`
* For each market in {`ETHUSD-MAR22`, `ETHUSD-JUN22`}
    * `party_0` and `party_1` provide auction orders so there is a trade to leave the opening auction and the remaining best bid = 2700 and and best offer = 2800 are supplied by party_0 each with volume 10. 
    * Moreover `party_0` provides liquidiity with `liquidity_fee` = 0.0003 and offset + 10 (so their LP volume lands on 2690 and 2810).
    * During epoch 2 `party_1` puts a limit buy order of vol 10 at 2710 and a limit sell order of vol 10 at 2790
    * After that, during epoch 2 `party_2` puts in a market buy order of volume 20.

#### Funding reward accounts
* `party_R` is funding multiple the reward accounts for both markets: 
   * `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of maker fees received | $VEGA` in epoch `2`.
   * `party_R` makes a transfer of `120` `$VEGA` to `ETHUSD-JUN22 | Sum of maker fees received | $VEGA` in epoch `2`.

#### Expectation
The calculation of eligibility is identical to (<a name="0056-REWA-020" href="#0056-REWA-020">0056-REWA-020</a>) but the expected payout is:
* for market `ETHUSD-MAR22`:
    *  At the end of epoch `2` `party_1` is paid `90 x 2.79 / (2.79+2.8)` $VEGA from the reward account into its `$VEGA` general account. 
    * At the end of epoch `2` `party_0` is paid `90 x 2.8 / (2.79+2.8)` $VEGA from the reward account into its `$VEGA` general account. 

* for market `ETHUSD-Jun22`:
    * At the end of epoch `2` `party_1` is paid `120 x 2.79 / (2.79+2.8)` USDC from the reward account into its `$VEGA` general account. 
    * At the end of epoch `2` `party_0` is paid `120 x 2.8 / (2.79+2.8)` USDC from the reward account into its `$VEGA` general account. 

### Distributing LP fees received rewards (<a name="0056-REWA-030" href="#0056-REWA-030">0056-REWA-030</a>)
#### Rationale
A market has 2 reward accounts for the metric, one paying in $VEGA and the other paying in USDC. 

#### Setup
Identical to (<a name="0056-REWA-020" href="#0056-REWA-020">0056-REWA-020</a>).

#### Funding reward accounts
Identical to (<a name="0056-REWA-020" href="#0056-REWA-020">0056-REWA-020</a>).

#### Expectation
At the end of epoch `2` the metric `sum of lp fees received` for `party_0` is:
```
10 x 2790 x 0.0003 + 10 x 2800 x 0.0003 = 16.77
```
At the end of epoch `2` `party_0` is paid `90` `$VEGA` from the reward account into its `$VEGA` general account. 
At the end of epoch `2` `party_0` is paid `120` `USDC` from the reward account into its `USDC` general account. 


### Distributing LP fees received rewards - unfunded account (<a name="0056-REWA-031" href="#0056-REWA-031">0056-REWA-031</a>)

#### Rationale
Identical to (<a name="0056-REWA-030" href="#0056-REWA-030">0056-REWA-030</a>). just without funding the corresponding reward account. 

#### Setup
Identical to (<a name="0056-REWA-030" href="#0056-REWA-030">0056-REWA-030</a>)

#### Funding reward accounts
No funding done.

#### Expectation
At the end of epoch 2 although there was trading in the market `ETHUSD-MAR22`, no reward is given to any participant as the reward account was not funded. 

### Distributing maker fees received  rewards - funded account - no trading activity (<a name="0056-REWA-032" href="#0056-REWA-032">0056-REWA-032</a>)
#### Rationale 
After having an epoch with trading activity, fund the reward account, but have no trading activity and assert that no payout is made. 

#### Setup
Identical to (<a name="0056-REWA-030" href="#0056-REWA-030">0056-REWA-030</a>)

#### Funding reward accounts
Identical to (<a name="0056-REWA-030" href="#0056-REWA-030">0056-REWA-030</a>)

Then, during epoch 3 we fund the reward accounts for the metric: 
* `party_R` is funding multiple reward accounts for the same metric and same market to be paid in different assets (`$VEGA`, `USDC`)
   * `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of LP fees received | VEGA` in epoch `3`. 
   * `party_R` makes a transfer of `120` `USDC` to `ETHUSD-MAR22 | Sum of LP fees received | USDC` in epoch `3`. 

#### Expectation
Looking only at epoch 3 - as no trading activity was done, we expect the reward balances in both $VEGA and USDC for the metric to remain unchanged. 

### Distributing LP fees received - multiple markets (<a name="0056-REWA-33" href="#0056-REWA-033">0056-REWA-033</a>)
#### Rationale 
There are multiple markets, each paying its own reward where due. 

#### Setup
Identical to (<a name="0056-REWA-023" href="#0056-REWA-023">0056-REWA-023</a>)

#### Funding reward accounts
* `party_R` is funding multiple the reward accounts for both markets: 
   * `party_R` makes a transfer of `90` `$VEGA` to `ETHUSD-MAR22 | Sum of LP fees received | $VEGA` in epoch `2`.
   * `party_R` makes a transfer of `120` `$VEGA` to `ETHUSD-JUN22 | Sum of LP fees received | $VEGA` in epoch `2`.

#### Expectation
The calculation of eligibility is identical to (<a name="0056-REWA-030" href="#0056-REWA-030">0056-REWA-030</a>) but the expected payout is:

* for market `ETHUSD-MAR22`:
    * At the end of epoch `2` `party_0` is paid `90` `$VEGA` from the reward account into its `$VEGA` general account. 
    
* for market `ETHUSD-Jun22`:
    * t the end of epoch `2` `party_0` is paid `120` `USDC` from the reward account into its `USDC` general account. 


### Distributing market creation rewards - no eligibility (<a name="0056-REWA-040" href="#0056-REWA-040">0056-REWA-040</a>)
#### Rationale 
Market has been trading but not yet eligible for proposer bonus. 

#### Setup
* Setup a market ETHUSDT settling in USDT.
* The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`. 
* Setup and fund multiple reward account for the market ETHUSDT:
    * Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA` 
    * Transfer 20000 USDC to `ETHUSDT | market creation | USDC` 
* start trading in the market such that traded value for fee purposes in USDT is less than 10^6

#### Expectation
At the end of the epoch no payout has been made for the market ETHUSDT and the reward account balances should remain unchanged.


### Distributing market creation rewards - eligible are paid no more than once (<a name="0056-REWA-041" href="#0056-REWA-041">0056-REWA-041</a>)
#### Rationale 
Market has been trading but not yet eligible for proposer bonus. 

#### Setup
* Setup a market ETHUSDT settling in USDT.
* The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`. 
* Setup and fund multiple reward account for the market ETHUSDT:
    * Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA` 
    * Transfer 20000 USDC to `ETHUSDT | market creation | USDC` 
* start trading in the market such that traded value for fee purposes in USDT is less than 10^6
* During the epoch 2 let the traded value be greater than 10^6

#### Expectation
At the end of the epoch 2 the proposer of the market ETHUSDT is paid 10000 `$VEGA` and 20000 `USDC`

Then during epoch 3 make the following transfers:
* Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA` 
* Transfer 20000 USDC to `ETHUSDT | market creation | USDC` 

At the end of epoch 3 make sure that no payout is made from the reward account as the proposer of the market has already been paid the proposer bonus once.

### Distributing market creation rewards - missed opportunity (<a name="0056-REWA-042" href="#0056-REWA-042">0056-REWA-042</a>)
#### Rationale 
Market goes above the threshold in trading value in an epoch before the reward account for the market for the reward type has any balance - therefore the proposer will not get compensated, not now, not ever. 

#### Setup
* Setup a market ETHUSDT settling in USDT.
* The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`. 
* start trading in the market such that trading volume in USDT is less than 10^6
* During the epoch 2 let the traded value be greater than 10^6
* in Epoch 3 setup and fund multiple reward account for the market ETHUSDT:
    * Transfer 10000 $VEGA to `ETHUSDT | market creation | $VEGA` 
    * Transfer 20000 USDC to `ETHUSDT | market creation | USDC` 

#### Expectation
At the end of the epoch 2 and at the end of epoch 3 no payout has been made for the market ETHUSDT and the reward account balances should remain unchanged.







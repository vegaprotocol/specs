# Reward framework

## New network parameter
- `rewards.marketCreationQuantumMultiple` will be used to asses market size together with [quantum](0040-ASSF-asset_framework.md) when deciding whether to pay market creation reward or not. 
It is reasonable to assume that `quantum` is set to be about `1 USD` so if we want to reward futures markets with traded notional over 1 mil USD then set this to `1000000`. Any decimal value strictly greater than `0` is valid. 

The reward framework provides a mechanism for measuring and rewarding a number of trading activties on the Vega network. 
These rewards operate in addition to the main protocol economic incentives which come from 
[fees](0029-FEES-fees.md) on every trade. 
Said fees are the fundamental income stream for [liquidity providers LPs](0042-LIQF-setting_fees_and_rewarding_lps.md) and [validators](0061-REWP-simple_pos_rewards_sweetwater.md). 

The additional trading rewards described here can be funded arbitrarily by users of the network and will be used by the project team, token holders (via governance), and individual traders and market makers to incentivise mutually beneficial behaviour.
Note that transfers via governance is post-Oregon trail feature.

Note that validator rewards (and the reward account for those) is covered in [validator rewards](0061-REWP-simple_pos_rewards_sweetwater.md) and is separate from the trading reward framework described here. 

## Reward metrics

Reward metrics need to be calculated for every relevant Vega [party](0017-PART-party.md). By relevant we mean that the metric is `> 0`. 

Reward metrics are scoped by market and measured per epoch hence are reset at the end of the epoch. 

There will be the following fee metrics:
1. Sum of maker fees paid (in a given market).
1. Sum of maker fees received (in a given market).
1. Sum of LP fees received (in a given market).

There will be the following market creation metrics:
1. Where `cumulative volume` is defined as market cumulative total [trade value for fee purposes](0029-FEES-fees.md) since market creation:
   - **IF** `cumulative volume < rewards.marketCreationQuantumMultiple * quantum` (where [quantum is described here](0040-ASSF-asset_framework.md)) **THEN** `market creation metric := 0`
   - **ELSE IF** any non-zero market creation reward has previously been paid out for this {reward account, market} combination **THEN** `market creation metric := 0`
   - **ELSE** `market creation metric := cumulative volume`

Reward metrics are not stored in [LNL checkpoints](./0073-LIMN-limited_network_life.md). 

## Rewards accounts

Trading reward accounts are defined by the payment asset (the asset in which the reward is paid out), the market in scope, and the reward type (metric). I.e. there can be multiple rewards with the same type paid in different assets for the same market.

It must be possible for any party to run a one off [transfer](0057-TRAN-transfers.md) or create a [recurring transfer](0057-TRAN-transfers.md) to any of these reward accounts. 
Note that the market settlement asset has nothing to do in particular with the asset used to pay out a reward for the market for any of the relevant trading rewards. 

Reward accounts and balances are to be saved in [LNL checkpoint](./0073-LIMN-limited_network_life.md). 

## Reward distribution

All rewards are paid out at the end of any epoch *after* [recurring transfers](0057-TRAN-Transfers.md) have been executed. 
There are no fractional payouts and no delays.

### For fee based metrics

Every epoch the entire reward account for every [market in scope, metric type, payout asset] will be distributed pro-rata to the parties that have the metric `>0`. 
That is if we have reward account balance `R`
```
[p_1,m_1]
[p_2,m_2]
...
[p_n,m_n]
```
then calculate `M:= m_1+m_2+...+m_n` and transfer `R x m_i / M` to party `p_i` at the end of each epoch. 
If `M = 0` (no-one incurred / received fees for a given reward account)  then nothing is paid out of the reward account and the balance rolls into next epoch. 

Metrics are reset at the end of the epoch, so in the case where there is no reward account or no reward balance at the end of the epoch for the given market in scope, the participants contributing to the relevant metric will not be compensated for their contribution. Their contribution to fees is not being carried over to the next epoch. 

Metrics will be calculated using the [decimal precision of the settlement asset](0070-MKTD-market-decimal-places.md).

### For market creation metrics

Every epoch the entire reward account for every [market in scope, payout asset] will be distributed to the parties that submitted the original market creation governance proposal for any markets that have the market creation metric (described above) `>0`. 
Markets in scope can be ALL markets (including those that have not been created or even proposed yet) for a given settlement assets OR any set of 1 or more markets (listed by ID) which have the same settlement asset. #TODO: confirm this is correct
The payout for each market having a non-zero market creation metric will be the same, that is, the eligible markets share the reward pool equally. 
This means that the total market creation reward received by a party can vary, as their reward may reflect having created multiple eligible markets, each of which earns the same payout.
Similarly to the other metrics market creation rewards may be paid in more than one asset if someone funds a reward account with the corresponding metric type and market in scope with an arbitrary payout asset. 

That is if we have:
- reward account balance: `R` of some asset
- number of markets with a non-zero market creation metric: `M`
- parties `p_0 … p_M` being the creators of the markets with non-zero market creations metrics, where the creator is defined as the party that submitted the original market proposal that was enacted to create the market

Then transfer `R / M` to each party `p_i` (`i` from 0 to `M`) identified above. 
If `M = 0` (no markets newly met or exceeded the reward threshold since the last payout) then nothing is paid out of the reward account and the balance rolls into next epoch. 

Market creation metrics are not reset at the end of the epoch, so the cumulative volume for each market continues to accrue across epochs and is always equal to the total trade value for fee purposes since the creation of the market.

Metrics will be calculated using the [decimal precision of the settlement asset](0070-MKTD-market-decimal-places.md).

NB: if a market is being recreated from checkpoint, and trading in it is restarted - the tracking of trading value and which market creation rewards have been paid must be restored from the checkpoint too, so each market proposal can only generate a single payout for any given [market in scope, payout asset] combination, even across checkpoint restarts.


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







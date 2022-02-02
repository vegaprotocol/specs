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

## Reward metrics

Reward metrics need to be calculated for every relevant Vega [party](0017-PART-party.md). By relevant we mean that the metric is `> 0`. 

There will be the following fee metrics:
1. Sum of fees paid (accross all markets for an asset).
1. Sum of maker fees received (accross all markets for an asset).
1. Sum of LP fees received (accross all markets for an asset).

There will be the following market creation metrics:
1. Market total [trade value for fee purposes](0029-FEES-fees.md) since market creation multiplied by either `1` if the market creation reward for this market has never been paid or by `0` if the reward has already been paid.

Reward metrics are not stored in [LNL checkpoints](../non-protocol-specs/0005-limited-network-life.md). 

## Rewards accounts

There will be *one* reward account per every Vega asset (settlement asset) and per every reward metric per every Vega asset (reward asset). 
Any asset on Vega can be either settlement asset or reward asset or both. 

It must be possible for any party to run a one off [transfer](????-????-transfers.md) or create a [periodic transfer](????-????-transfers.md) to any of these reward accounts. 
Note that saying "per every Vega asset" twice above isn't a typo. We want to be able to pay rewards e.g. in $VEGA for markets settling in e.g. $USDT. 

Reward accounts and balances are to be saved in [LNL checkpoint](../non-protocol-specs/0005-limited-network-life.md). 


## Reward distribution

All rewards are paid out at the end of any epoch. There are no fractional payouts and no delays. 

### For fee based metrics
Every epoch the entire reward account for every asset and *fee* metric type will be distributed pro-rata to the parties that have the metric `>0`. 
That is if we have reward account balance `R`
```
[p_1,m_1]
[p_2,m_2]
...
[p_n,m_n]
```
then calculate `M:= m_1+m_2+...+m_n` and transfer `R x m_i / M` to party `p_i` at the end of each epoch. 
If `M = 0` (no-one incurred / received fees for a given reward account)  then nothing is paid out of the reward account and the balance rolls into next epoch. 

Metrics will be calculated using the [decimal precision of the settlement asset](????-????-market-decimal-places.md).

### For market creation metrics

In any epoch when for any asset and for any markets settling in the asset, if market total [trade value for fee purposes](0029-FEES-fees.md) since market creation exceeds `quantum x rewards.marketCreationQuantumMultiple` then split the reward pool (for market creation in said asset) equally between all markets. 


## Acceptance criteria


### Funding reward accounts (<a name="0056-rewa-001" href="#0056-rewa-001">0056-rewa-001</a>)

There are two assets configured on the Vega chain: $VEGA and USDT. There are `4` reward metrics. Then there will be `2 x 4 x 2 = 16` reward accounts. 
More specifically, for each metric `i=1,2,3,4` there will be
```
settlement asset | metric   | reward asset 
-----------------|----------|--------------
USDT             | metric i | USDT
USDT             | metric i | $VEGA
$VEGA            | metric i | USDT 
$VEGA            | metric i | $VEGA
```

A party with USDT balance can do one-off transfers to `USDT  | metric i | USDT` and `$VEGA | metric i | USDT` for `i=1,2,3,4`. 

A party with VEGA balance can set up a periodic tranfers to `USDT  | metric i | $VEGA` and `$VEGA  | metric i | $VEGA` for `i=1,2,3,4`. 

### Distributing fees paid rewards (<a name="0056-rewa-010" href="#0056-rewa-010">0056-rewa-010</a>)

There are two assets configured on the Vega chain: $VEGA and USDT. There are no markets.
The fees are as follows: `maker_fee = 0.0001`, `infrastructure_fee = 0.0002`.  
`ETHUSD-MAR22` market which settles in USDT is launched anytime in epoch 1 by `party_0`; `party_0` and `party_1` provide auction orders so there is a trade to leave the opening auction and the remaining best bid = `2700` and and best offer = `2800` are supplied by `party_0` each with volume `10`. 
Moreover `party_0` provides liquidiity with `liquidity_fee = 0.0003` and offset + 10 (so their LP volume lands on `2690` and `2810`). 

A `party_0` makes a transfer of `90` `$VEGA` to `USDT | Sum of fees paid | VEGA` in epoch `2`.
During epoch `2` we have `party_1` make one buy market order with volume `2` USDT. 
During epoch `2` we have `party_2` make one sell market order each with notional `1` USDT.  
Verify that at the end of epoch `2` the metric `sum of fees paid` for `party_1` is:
```
2 x 2800 x (0.0001 + 0.0002 + 0.0003) = 3.36
```
and for `party_2` it is 
```
1 x 2700 x (0.0001 + 0.0002 + 0.0003) = 1.62
```
At the end of epoch `2` `party_1` is paid `90 x 3.36 / 4.98 = 60.72..` $VEGA from the reward account into its general account. 

At the end of epoch `2` `party_2` is paid `90 x 1.62 / 4.98 = 29.28..` $VEGA from the reward account into its general account. 

### Distributing maker fees received rewards (<a name="0056-rewa-011" href="#0056-rewa-011">0056-rewa-011</a>)

There are two assets configured on the Vega chain: $VEGA and USDT. There are no markets.
The fees are as follows: `maker_fee = 0.0001`, `infrastructure_fee = 0.0002`.  
`ETHUSD-MAR22` market which settles in USDT is launched anytime in epoch 1 by `party_0`; `party_0` and `party_1` provide auction orders so there is a trade to leave the opening auction and the remaining best bid = `2700` and and best offer = `2800` are supplied by `party_0` each with volume `10`. Moreover `party_0` provides liquidiity with `liquidity_fee = 0.0003` and offset + 10 (so their LP volume lands on `2690` and `2810`). 

During epoch 2 `party_R` makes a transfer of `120` `$VEGA` to `USDT | Sum of maker fees received | VEGA`. 
During epoch 2 `party_1` puts a limit buy order of vol `10` at `2710` and a limit sell order of vol `10` at `2790`. 
After that, during epoch 2 `party_2` puts in a market buy order of volume `20`. 

Verify that at the end of epoch `2` the metric `sum of maker fees received` for `party_1` is:
```
10 x 2790 x 0.0001 = 2.79
```
and for `party_0` it is 
```
10 x 2800 x 0.0001 = 2.8
```

At the end of epoch `2` `party_1` is paid `90 x 2.79 / (2.79+2.8)` $VEGA from the reward account into its general account. 

At the end of epoch `2` `party_0` is paid `90 x 2.8 / (2.79+2.8)` $VEGA from the reward account into its general account. 

### Distributing LP fees received rewards (<a name="0056-rewa-012" href="#0056-rewa-012">0056-rewa-012</a>)

There are two assets configured on the Vega chain: $VEGA and USDT. There are no markets.
The fees are as follows: `maker_fee = 0.0001`, `infrastructure_fee = 0.0002`.  
`ETHUSD-MAR22` market which settles in USDT is launched anytime in epoch 1 by `party_0`; `party_0` and `party_1` provide auction orders so there is a trade to leave the opening auction and the remaining best bid = `2700` and and best offer = `2800` are supplied by `party_0` each with volume `10`. Moreover `party_0` provides liquidiity with `liquidity_fee = 0.0003` and offset + 10 (so their LP volume lands on `2690` and `2810`). 

During epoch 2 `party_R` makes a transfer of `120` `$VEGA` to `USDT | Sum of maker fees received | VEGA`. 
During epoch 2 `party_1` puts a limit buy order of vol `10` at `2710` and a limit sell order of vol `10` at `2790`. 
After that, during epoch 2 `party_2` puts in a market buy order of volume `20`. 

Verify that at the end of epoch `2` the metric `sum of maker fees received` for `party_0` is:
```
10 x 2790 x 0.0003 + 10 x 2800 x 0.0003 = 16.77
```

At the end of epoch `2` `party_0` is paid `90` $VEGA from the reward account into its general account. 


### Distributing market creation rewards (<a name="0056-rewa-013" href="#0056-rewa-013">0056-rewa-013</a>)


There are two markets settling in USDT: BTCUSDT futures and ETHUSDT futures.  
For BTCUSDT opening auction end during Epoch 105 and for ETHUSDT opening auction ends in Epoch 107 (this is in fact irrelevant). 
The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`. The reward account balance for `USDT| market creation | $VEGA` market creation is `10^4 $VEGA`.

##### Case a) 
In epoch `110` the total trade value for fee purposes on BTCUSDT is `10^5` and on ETHUSDT it is `2x10^5`. No reward is paid from this reward account. 
In epoch `120` the total trade value for fee purposes on BTCUSDT is `10^6+1` and on ETHUSDT it is `9x10^5`. 
The entire balance of the `USDT| market creation | $VEGA` is transferred to the party that proposed the `BTCUSD` market. 
The balance of `USDT| market creation | $VEGA` is now `0`. 
In epoch `121` the total trade value for fee purposes on BTCUSDT metric is `0` (reward paid already). 
On ETHUSDT it is `10^6+1`. The entire balance of the `USDT| market creation | $VEGA` is transferred to the party that proposed the `ETHUSD` market (the party that created `ETHUSD` market gets nothing). 
In epoch `122` the `USDT| market creation | $VEGA` is funded by transfer with  `10^4 $VEGA`. 
The total trade value for fee purposes on BTCUSDT and ETHUSD metric is `0` (reward paid already). 

##### Case b) 
In epoch `110` the total trade value for fee purposes on BTCUSDT is `10^5` and on ETHUSDT it is `2x10^5`. No reward is paid from this reward account. 
In epoch `120` the total trade value for fee purposes on BTCUSDT is `10^6+1` and on ETHUSDT it is `10^7`. The balance of the `USDT| market creation | $VEGA` is split equally (up to arbitrarily applied roundin) and transferred to the party that proposed the `BTCUSD` market and the party that proposed the `ETHUSD` market.

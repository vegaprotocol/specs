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


## Rewards accounts

There will be *one* reward account per every Vega asset and per every reward metric per every Vega asset.  
It must be possible for any party to run a one off [transfer](????-????-transfers.md) or create a [periodic transfer](????-????-transfers.md) to any of these reward accounts. 
Note that saying "per every Vega asset" twice above isn't a typo. We want to be able to pay rewards e.g. in $VEGA for markets settling in e.g. $USDT. 

Example: There are two assets configured on the Vega chain: $VEGA and USDT. There are `4` reward metrics. Then there will be `2 x 4 x 2 = 16` reward accounts. 
More specifically, for each metric `i=1,2,3,4` there will be
```
USDT  | metric i | USDT
USDT  | metric i | $VEGA
$VEGA | metric i | USDT 
$VEGA | metric i | $VEGA
```

## Reward distribution

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

### For market creation metrics

In any epoch when for any asset and for any markets settling in the asset, if market total [trade value for fee purposes](0029-FEES-fees.md) since market creation exceeds `quantum x rewards.marketCreationQuantumMultiple` then split the reward pool (for market creation in said asset) equally between all markets. 

Example: 
There are two markets settling in USDT: BTCUSDT futures and ETHUSDT futures.  
For BTCUSDT opening auction end during Epoch 105 and for ETHUSDT opening auction ends in Epoch 107 (this is in fact irrelevant). 
The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`. The reward account balance for `USDT| market creation | $VEGA` market creation is `10^4 $VEGA`.

Possible case a) In epoch `110` the total trade value for fee purposes on BTCUSDT is `10^5` and on ETHUSDT it is `2x10^5`. No reward is paid from this reward account. 
In epoch `120` the total trade value for fee purposes on BTCUSDT is `10^6+1` and on ETHUSDT it is `9x10^5`. 
The entire balance of the `USDT| market creation | $VEGA` is transferred to the party that proposed the `BTCUSD` market. 
The balance of `USDT| market creation | $VEGA` is now `0`. 
In epoch `121` the total trade value for fee purposes on BTCUSDT metric is `0` (reward paid already). 
On ETHUSDT it is `10^6+1`. The entire balance of the `USDT| market creation | $VEGA` is transferred to the party that proposed the `ETHUSD` market (the party that created `ETHUSD` market gets nothing). 
In epoch `122` the `USDT| market creation | $VEGA` is funded by transfer with  `10^4 $VEGA`. 
The total trade value for fee purposes on BTCUSDT and ETHUSD metric is `0` (reward paid already). 


Possible case b) In epoch `110` the total trade value for fee purposes on BTCUSDT is `10^5` and on ETHUSDT it is `2x10^5`. No reward is paid from this reward account. 
In epoch `120` the total trade value for fee purposes on BTCUSDT is `10^6+1` and on ETHUSDT it is `10^7`. The balance of the `USDT| market creation | $VEGA` is split equally (up to arbitrarily applied roundin) and transferred to the party that proposed the `BTCUSD` market and the party that proposed the `ETHUSD` market.


## Acceptance criteria



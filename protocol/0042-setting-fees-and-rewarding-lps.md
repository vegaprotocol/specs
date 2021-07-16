# Setting fees and rewarding liquidity providers

## Summary

The aim of this specification is to set out how fees on Vega are set based on committed liquidity provider stake and prevailing open interest on the market leading to [target stake](./0041-target-stake.md). Let us recall that liquidity providers can commit and withdraw stake by submitting / amending a special liquidity provider pegged order type [liquidity provider order spec](./0038-liquidity-provision-order-type.md). 

## Definitions / Glossary of terms used
- **Market value proxy window length `t_market_value_window_length`**: sets the length of the window over which we estimate the market value. This is a network parameter.  
- **Target stake**: as defined in [target stake spec](./0041-target-stake.md). The amount of stake we would like LPs to commit to this market.
- `min_LP_stake`: There is an minimum LP stake specified per asset, see [asset framework spec](0040-asset-framework.md).


## CALCULATING LIQUIDITY FEE FACTOR

The [liquidity fee factor](0029-fees.md) is an input to the total taker fee that a price taker of a trade pays:

`total_fee = infrastructure_fee + maker_fee + liquidity_fee`

`liquidity_fee = fee_factor[liquidity] x trade_value_for_fee_purposes`

As part of the [commit liquidity network transaction](./0044-lp-mechanics.md), the liquidity provider submits their desired level for the [liquidity fee factor](./0029-fees.md) for the market. Here we describe how this fee factor is set from the values submitted by all liquidity providers for a given market. 
First, we produce a list of pairs which capture committed liquidity of each LP together with their desired liquidity fee factor and arrange this list in an increasing order by fee amount. Thus we have 
```
[LP-1-stake, LP-1-liquidity-fee-factor]
[LP-2-stake, LP-2-liquidity-fee-factor]
...
[LP-N-stake, LP-N-liquidity-fee-factor]
```
where `N` is the number of liquidity providers who have committed to supply liquidity to this market. Note that `LP-1-liquidity-fee-factor <= LP-2-liquidity-fee-factor <= ... <= LP-N-liquidity-fee-factor` because we demand this list of pairs to be sorted in this way. 

We now find smallest integer `k` such that `[target stake] < sum from i=1 to k of [LP-stake-i]`. In other words we want in this ordered list to find the liquidity providers that supply the liquidity that's required. If no such `k` exists we set `k=N`.

Finally, we set the liquidity-fee-factor for this market to be the fee `LP-k-liquidity-fee-factor`. 

### Example for fee setting mechanism
``` 
[LP 1 stake = 120 ETH, LP 1 liquidity-fee-factor = 0.5%]
[LP 2 stake = 20 ETH, LP 2 liquidity-fee-factor = 0.75%]
[LP 3 stake = 60 ETH, LP 3 liquidity-fee-factor = 3.75%]
```
1. If the `target stake = 119` then the needed liquidity is given by LP 1, thus `k=1` and so the market's liquidity-fee-factor is  `LP 1 fee = 0.5%`. 
1. If the `target stake = 123` then the needed liquidity is given by LP 1 and LP 2, thus `k=2` and so the market's liquidity-fee-factor is  `LP 2 fee = 0.75%`. 
1. If the `target stake = 240` then even putting all the liquidity supplied above does not meet the estimated market liquidity demand and thus we set `k=N` and so the market's liquidity-fee-factor is `LP N fee = LP 3 fee = 3.75%`. 
1. Initially (before market opened) the `[target stake]` is by definition zero (it's not possible to have a position on a market that's not opened yet). Hence by default the market's initial liquidity-fee-factor is the lowest liquidity-fee-factor.

### Timing market's liquidity-fee-factor changes

Once the market opens (opening auction starts) a clock starts ticking. We calculate the `[target stake]` using [target stake](????-target-stake.md). The fee is continuously re-evaluated using the mechanism above. 

### APIs for fee factor calculations - what should core be exposing?

At time of call:
* The `liquidity-fee-factor` for the market.
* Current liquidity provider commitments and their individually nominated fee factors
* [Target stake](./0041-target-stake.md)

## SPLITTING FEES BETWEEN LIQUIDITY PROVIDERS

### Calculating market value proxy

This will be used for determining what "equity like share" does committing liquidity provider stage at a given time lead to. 
It's calculated, with `t` denoting time now measured so that at `t=0` the opening auction ended, as follows:
```
total_stake = sum of all LP stakes
active_time_window = [max(t-t_market_value_window_length,0), t]
active_window_length = t - max(t-t_market_value_window_length,0)

if (active_window_length > 0)
    factor =  t_market_value_window_length / active_window_length
    traded_value_over_window = total trade value for fee purposes of all trades executed on a given market during the active_time_window
    market_value_proxy = max(total_stake, factor x traded_value_over_window)
else
    market_value_proxy = total_stake
```

Note that trade value for fee purposes is provided by each instrument, see [fees](./0024-fees.md). For futures it's just the notional and in the examples below we will only think of futures. 

#### Example 
Let's say `total_stake = 100`. The network parameter `t_market_value_window_length = 60s` (though in practice a more sensible value is e.g. one week).

1. Current time `t = 0s` i.e. the opening auction just resulted in a trade. Then `active_window_length = 0 - max(0-60,0) = 0 - 0 =0` and so `market_value_proxy = 100`.
1. Current time `t = 10s` i.e. the opening auction resulted in a trade and ended `10s` ago. Then `active_time_window = [0,t] = [0,10s]` and `active_window_length = 10 - max(10-60,0) = 10 - 0 = 10`. Let's say the trade value for fee purposes over the time `[0,t]` was `traded_value_over_window = 10 tUSD`. We calculate `factor = 60 / 10 = 6`. Then `market_value_proxy = max(100, 6 x 10)  = 100`. 
1. Current time `t = 30s` i.e. the opening auction resulted in a trade and ended `30s` ago. Then `active_time_window = [0,t] = [0,30s]` and `active_window_length = 30 - max(30-60,0) = 30 - 0 = 30`. Let's say the trade value for fee purposes over the time `[0,30s]` was `traded_value_over_window = 100 tUSD`. We calculate `factor = 60 / 30 = 2`. Then `market_value_proxy = max(100, 2 x 100)  = 200`. 
1. Current time `t = 90s` i.e. the opening auction resulted in a trade and ended `90s` ago. Then `active_time_window = [30s,90s]` and `active_window_length = 90 - max(90-60,0) = 90 - 30 = 60`. Let's say the trade value for fee purposes over the time `[30s,90s]` was `traded_value_over_window = 300 tUSD`. We calculate `factor = 60 / 60 = 1`. Then `market_value_proxy = max(100, 1 x 300)  = 300`. 


#### Example
1. The market was just proposed and one LP committed stake. No trading happened so the `market_value_proxy` is the stake of the committed LP. 
1. A LP has committed stake of `10000 ETH`. The traded notional over `active_time_window` is `9000 ETH`. So the `market_value_proxy` is `10000 ETH`.
1. A LP has committed stake of `10000 ETH`. The traded notional over `active_time_window` is `250 000 ETH`. Thus the `market_value_proxy` is `250 000 ETH`.

### Calculating liquidity provider equity-like share

The guiding principle of this section is that by committing stake a liquidity provider buys a portion of the `market_value_proxy` of the market. 

At any time let's say we have `market_value_proxy` calculated above and existing liquidity providers as below
```
[LP 1 stake, LP 1 avg_entry_valuation]
[LP 2 stake, LP 2 avg_entry_valuation]
...
[LP N stake, LP N avg_entry_valuation]
```

These have to all be greater or equal to `zero` at all times. At market creation all these are set `zero` except at least one LP that commits stake at market creation. So the initial configuration is the `LP i stake = their commitment before market proposal gets enacted` and `LP i avg_entry_valuation = sum of total commited before market proposal is enacted`. We then update these as per the description below.   

From these stored quantities we can calculate, at time step `n` the following:
- `(LP i equity)(n) = (LP i stake)(n) x market_value_proxy(n) / (LP i avg_entry_valuation)(n)`
- `(LP i equity_share)(n) = (LP i equity)(n) / (sum over j from 1 to N of (LP j equity)(n))`
Here `market_value_proxy(n)` is calculated as per Section "Calculating market value proxy".

If at time step `n` liquidity provider `i` submits an order of type [0038-liquidity-provision-order-type.md](./0038-liquidity-provision-order-type.md) that requests its stake to be changed to `new_stake` then update the above values as follows:

```
if new_stake < min_LP_stake then
    reject transaction and stop. 
fi
```

```
total_stake(n+1) = sum of all but i's stake(n) + new_stake 
if new_stake < (LP i stake) then
    check that total_stake(n+1) is sufficient for `market target stake`; if not abort updating stakes and equity like shares (all values stay the same).
fi

if (LP i stake)(n) == 0 then 
    (LP i stake)(n+1) = new_stake
    (LP i avg_entry_valuation)(n+1) = market_value_proxy(n)
elif new_stake < (LP i stake)(n) then
    (LP i stake)(n+1) = new_stake
elif new_stake > (LP i stake)(n) then
    delta = new_stake - (LP i stake)(n) // this will be > 0
    (LP i stake)(n+1) = new_stake
    (LP i avg_entry_valuation)(n+1) = [(LP i equity)(n) x (LP i avg_entry_valuation)(n) 
                            + delta x market_value_proxy(n)] / [(LP i equity)(n) + (LP i stake)(n)]
fi
```

Example: 
In this example we assume that that `market_value_proxy` derives purely from committed stake (no is trading happening). There is only one LP, with index i = 1. At `n=0` we have the following state: 
```
LP 1 stake = 100, LP 1 avg_entry_valuation = 100
```
LP 1 submits a transaction with `new_stake = 200`. (see [0038-liquidity-provision-order-type.md](./0038-liquidity-provision-order-type.md)).
We have `(LP 1 equity)(0) = (LP 1 stake)(0) x market_value_proxy(n) / (LP 1 avg_entry_valuation)(n) = 100 x 100 / 100 = 100` and clearly `(LP 1 equity_share)(0) = 1`. Moreover `market_value_proxy(0) = 100`. 
We will be in the case `new_stake = 200 > (LP 1 stake)(0) = 100`. So then `delta = 100` and then `(LP i avg_entry_valuation)(1) = (100 x 100 + 100 x 100) / (100 + 100) = 20000 / 200 = 100`. 
So at `n=1` we have the following state:
```
LP 1 stake = 200, LP 1 avg_entry_valuation = 100
```

Say now LP 2 wishes to enter and submits a "liquidity-provision-order-type" with `new_stake=200`. We have `n=1` and implicitly `(LP 2 stake)(1) == 0` is `True` and so we set `(LP 2 stake)(2) = 200` and `(LP 2 avg_entry_valuation)(2) = market_value_proxy(1) = 200`. After the update, at `n = 2` we record the state as
```
LP 1 stake = 200, LP 1 avg_entry_valuation = 100
LP 2 stake = 200, LP 2 avg_entry_valuation = 200
```

Another "liquidity-provision-order-type" type comes in saying that LP 1 wants `new_stake = 300`. We have `market_value_proxy(2) = 400` and `(LP 1 equity)(2) = (LP 1 stake)(2) x market_value_proxy(2) / (LP 1 avg_entry_valuation)(2) = 200 x 400 / 100 = 800`.
We will be in the case `new_stake = 300 > (LP 1 stake)(2) = 200`. So then `delta = 100` and then `(LP i avg_entry_valuation)(1) = (800 x 100 + 100 x 400) / (800 + 200) = 120000 / 1000 = 120`.  After the update, at `n = 3` we record the state as
```
LP 1 stake = 300, LP 1 avg_entry_valuation = 120
LP 2 stake = 200, LP 2 avg_entry_valuation = 200
```

Another "liquidity-provision-order-type" type comes in saying that LP 1 wants `new_stake = 1`. We check that `market target stake <= 201` (assume true for purposes of example) and so we proceed so that after the update, at `n=4` we record the state as
```
LP 1 stake =   1, LP 1 avg_entry_valuation = 120
LP 2 stake = 200, LP 2 avg_entry_valuation = 200
```




**Check** the sum from over `i` from `1` to `N` of `LP i equity_share` is equal to `1`.
**Warning** the above will be either floating point calculations  and / or there will be rounding errors arising from rounding (both stake and entry valuation can be kept with decimals) so the above checks will only be true up to a certain tolerance. 

### Distributing fees
The liquidity fee is collected into either a per-market "bucket" belonging to liquidity providers for that market or into an account for each liquidity provider, according to their share of that fee. This account is not accessible by liquidity providers until the fee is distributed to them according to the below mechanism.

We will create a new network parameter (which can be 0 in which case fees are transferred at the end of next block) called `liquidity_providers_fee_distribition_time_step` which will define how frequently fees are distributed to a liquidity provider's general account for the market. 

The liquidity fees are distributed pro-rata depending on the `LP i equity_share` at a given time. 

#### Example
The fee bucket contains `103.5 ETH`. We have `3` LPs with equity shares:
share as below
```
LP 1 eq share = 0.65
LP 2 eq share = 0.25
LP 3 eq share = 0.1
```
When the time defined by ``liquidity_providers_fee_distribution_time_step` elapses we do transfers:
```
0.65 x 103.5 = 67.275 ETH to LP 1's margin account
0.25 x 103.5 = 25.875 ETH to LP 2's margin account
0.10 x 103.5 = 10.350 ETH to LP 3's margin account
```

### APIs for fee splits and payments
* Each liquidity provider's equity-like share
* Each liquidity provider's average entry valuation
* The `market-value-proxy`


## Acceptance Criteria

### CALCULATING LIQUIDITY FEE FACTOR
- [ ] The examples provided result in the given outcomes
- [ ] The resulting liquidity-fee-factor is always equal to one of the liquidity provider's individually nominated fee factors
- [ ] The resulting liquidity-fee-factor is never less than zero
- [ ] Liquidity fee factors are recalculated every time a liquidity provider nominates a new fee factor (using the commit liquidity network transaction).
- [ ] Liquidity fee factors are recalculated every time the liquidity demand estimate changes.
- [ ] If a change in the open interest causes the liquidity demand estimate to change, then fee factor is correctly recalculated. 
- [ ] If passage of time causes the liquidity demand estimate to change, the fee factor is correctly recalculated. 

### SPLITTING FEES BETWEEN liquidity providers
- [ ] The examples provided result in the given outcomes. 
- [ ] The examples provided in a Python notebook give the same outcomes. See [0034 Liquidity measuring](./0034-prob-weighted-liquidity-measure.ipynb)
- [ ] All liquidity providers in the market receive a greater than zero amount of liquidity fee.
- [ ] The total amount of liquidity fee distributed is equal to the most recent `liquidity-fee-factor` x `notional-value-of-the-trade`
- [x] Liquidity providers with a commitment of 0 will not receive a share ot the fees

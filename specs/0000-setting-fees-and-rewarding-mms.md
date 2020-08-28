# Setting fees and rewarding market makers

## Summary

The aim of this specification is to set out how fees on Vega are set based on committed market making stake and prevailing open interest on the market. Let us recall that market makers can commit and withdraw stake by submitting / amending a special market making pegged order type [market maker order spec](????.md). 

## Definitions / Glossary of terms used
- **Liquidity**: measured as per [liquidity measurement spec](0034-prob-weighted-liquidity-measure.ipynb) (but it's basically volume on the book weighted by the probability of trading)
- **Supplied liquidity**: this counts only the liquidity provided through the special market making order that market makers have committed to as per [market maker order spec](????.md) 
- **Liquidity demand window length `t_liquidity_window`**: sets the length of the window over which we estimate liquidity demand for fee setting purposes. This is a network parameter.  
- **Liquidity demand estimate**: as defined in [liquidity demand estimate spes](????-liquidity-demand-estimate.md) using `t_fee_liquidity_window` which is a network paratemer. 
- **Sufficient liquidity trigger `c_2`**: a network parameter `c_2` defined in [liquidity monitoring](????-liquidity-monitoring.md) spec. 
- **Market value estimate** is calculated to be the estimated fee income for the entire future existence of the market using recent fee income. See further in this spec for details.

## CALCULATING LIQUIDITY FEE FACTOR

The [liquidity fee factor](0029-fees.md) is an input to the total taker fee that a price taker of a trade pays:

`total_fee = infrastructure_fee + maker_fee + liquidity_fee`
`liquidity_fee = fee_factor[liquidity] x trade_value_for_fee_purposes`

As part of the [commit liquidity network transaction ](????-mm-mechanics.md), the market maker submits their desired level for the [liquidity fee factor](0029-fees.md) for the market. Here we describe how this fee factor is set from the values submitted by all market makers for a given market. 
First, we produce a list of pairs which capture committed liquidity of each mm together with their desired liquidity fee factor and arrange this list in an increasing order by fee amount. Thus we have 
```
[MM-1-liquidity, MM-1-liquidity-fee-factor]
[MM-2-liquidity, MM-2-liquidity-fee-factor]
...
[MM-N-liquidity, MM-N-liquidity-fee-factor]
```
where `N` is the number of market makers who have committed to supply liquidity to this market. Note that `MM-1-liquidity-fee-factor <= MM-2-liquidity-fee-factor <= ... <= MM-N-liquidity-fee-factor` because we demand this list of pairs to be sorted. 

We now find smallest integer `k` such that `c_2 x [liquidity demand estimate] < sum from i=1 to k of [MM-liquidity-i]`. In other words we want in this ordered list to find the market makers that supply the liquidity that's required. If no such `k` exists we set `k=N`.

Finally, we set the liquidity-fee-factor for this market to be the fee `MM-k-liquidity-fee-factor`. 

### Example for fee setting mechanism
Let us say that `c_2 = 10`. 
``` 
[MM 1 liquidity = 120, MM 1 liquidity-fee-factor = 0.5%]
[MM 2 liquidity = 20, MM 2 liquidity-fee-factor = 0.75%]
[MM 3 liquidity = 60, MM 3 liquidity-fee-factor = 3.75%]
```
1. If the `liquidity demand estimate = 10` then `c_2 x [liquidity demand estimate] = 100` which means that the needed liquidity is given by MM 1, thus `k=1` and so the market's liquidity-fee-factor is  `MM 1 fee = 0.5%`. 
1. If the `liquidity demand estimate = 12.5` then `c_2 x [liquidity demand estimate] = 125` which means that the needed liquidity is given by MM 1 and MM 2, thus `k=2` and so the market's liquidity-fee-factor is  `MM 2 fee = 0.75%`. 
1. If the `liquidity demand estimate = 123` then `c_2 x [liquidity demand estimate] = 1230` which means that even putting all the liquidity supplied above does not meet the estimated market liquidity demand and thus we set `k=N` and so the market's liquidity-fee-factor is `MM N fee = MM 3 fee = 3.75%`. 
1. Initially (before market opened) the `[liquidity demand estimate]` is by definition zero (it's not possible to have a position on a market that's not opened yet). Hence by default the market's initial liquidity-fee-factor is the lowest liquidity-fee-factor.

### Timing market's liquidity-fee-factor changes

Once the market opens (opening auction starts) a clock starts ticking. We calculate the `[liquidity demand estimate]` using [liquidity demand estimate spes](????-liquidity-demand-estimate.md) with the network parameter `t_fee_liquidity_window`. The fee is continuously re-evaluated using the mechanism above. 

### APIs for fee factor calculations - what should core be exposing?

At time of call:
* The `liquidity-fee-factor` for the market.
* Current market making commitments and their individually nominated fee factors
* Liquidity demand estimate

## SPLITTING FEES BETWEEN MARKET MAKERS

### Calculating market value proxy

This will be used for determining what "equity like share" does committing market making stage at a given time lead to. 
It's calculated, with `t` denoting time now, as follows:
```
total_stake = sum of all mm stakes
active_time_window = [max(t-t_fee_liquidity_window,0), t]

traded_value_over_window = total trade value for fee purposes of all trades executed on a given market the active_time_window

market_value_proxy = max(total_stake, traded_value_over_window)
```

Note that trade value for fee purposes is provided by each instrument, see [fees][0024-fees.md]. For futures it's just the notional and in the examples below we will only think of futures. 


#### Example
1. The market was just proposed and one MM commited stake. No trading happened so the `market_value_proxy` is the stake of the committed MM. 
1. A MM has committed stake of `10000 ETH`. The traded notional over `active_time_window` is `9000 ETH`. So the `market_value_proxy` is `10000 ETH`.
1. A MM has committed stake of `10000 ETH`. The traded notional over `active_time_window` is `250 000 ETH`. Thus the `market_value_proxy` is `250 000 ETH`.

### Calculating market maker equity-like share

The guiding principle of this section is that by committing stake a market maker buys a portion of the `market_value_proxy` of the market. 

At any time let's say we have `market_value_proxy` calculated above and existing market makers as below
```
[MM 1 stake, MM 1 entry_valuation]
[MM 1 stake, MM 2 entry_valuation]
...
[MM N stake, MM N entry_valuation]
```

At market creation all these are set `zero`.  

From these stored quantities we can calculate
- `MM i equity = (MM i stake) x market_value_proxy / (MM i entry_valuation)`
- `MM i equity_share = MM i equity / (sum over j from 1 to N of MM j equity)`

If a market maker `i` wishes to set its stake to `new_stake` then update the above values as follows:
1. Calculate new `total_stake` (sum of all but `i`'s stake + `new_stake`). Check that this is sufficient for market demand estimate; if not abort. 
1. Update the `market_value_proxy` using the `new_stake`. 
1. Update `MM i stake` and `MM i entry_valuation` as follows:
```
if new_stake < MM i stake then
    MM i stake = new_stake
else if new_stake > MM i stake then
    delta = new_stake - self.stake
    MM i entry_valuation = ((MM i equity x MM i entry_valuation) 
                            + (delta x market_value_proxy)) / (MM i equity + MM i stake)
    MM i stake = new_stake
```

**Check** the sum from over `i` from `1` to `N` of `MM i equity` is equal to `market_value_proxy`.
**Check** the sum from over `i` from `1` to `N` of `MM i equity_share` is equal to `1`.
**Warning** the above will be either floating point calculations  and / or there will be rounding errors arising from rounding (both stake and entry valuation can be kept with decimals) so the above checks will only be true up to a certain tolerance. 

### Distributing fees
The liquidity fee is collected into either a per-market "bucket" belonging to market makers for that market or into an account for each market maker, according to their share of that fee. This account is not accessible by market makers until the fee is distributed to them according to the below mechanism.

We will create a new network parameter (which can be 0 in which case fees are transferred immediately) called `market_maker_fee_distribition_time_step` which will define how frequently fees are distributed to a market maker's margin account for the market. 

The liquidity fees are distributed pro-rata depending on the `MM i equity_share` at a given time. 

#### Example
The fee bucket contains `103.5 ETH`. We have `3` MMs with equity shares:
share as below
```
MM 1 eq share = 0.65
MM 2 eq share = 0.25
MM 3 eq share = 0.1
```
When the time defined by ``market_maker_fee_distribition_time_step` elapses we do transfers:
```
0.65 x 103.5 = 67.275 ETH to MM 1's margin account
0.25 x 103.5 = 25.875 ETH to MM 2's margin account
0.10 x 103.5 = 10.350 ETH to MM 3's margin account
```

### APIs for fee splits and payments
* Each market maker's equity-like share
* Each market maker's entry valuation
* The `market-value-proxy`


## Acceptance Criteria

### CALCULATING LIQUIDITY FEE FACTOR
- [ ] The examples provided result in the given outcomes
- [ ] The resulting liquidity-fee-factor is always equal to one of the market maker's individually nominated fee factors
- [ ] The resulting liquidity-fee-factor is never less than zero
- [ ] Liquidity fee factors are recalculated every time a market maker nominates a new fee factor (using the commit liquidity network transaction).
- [ ] Liquidity fee factors are recalculated every time the liquidity demand estimate changes.
- [ ] If a change in the open interest causes the liquidity demand estimate to change, then fee factor is correctly recalculated. 
- [ ] If passage of time causes the liquidity demand estimate to change, the fee factor is correctly recalculated. 

### SPLITTING FEES BETWEEN MARKET MAKERS
- [ ] The examples provided result in the given outcomes. 
- [ ] The examples provided in a Python notebook give the same outcomes. See 
`https://github.com/vegaprotocol/sim/sim/notebooks/` 
- [ ] All market makers in the market receive a greater than zero amount of liquidity fee.
- [ ] The total amount of liquidity fee distributed is equal to the most recent liquidity-fee-factor x notional-value-of-the-trade
- [ ] Every time a price taker is charged a trading fee, the mm equity shares are recalculated to determine their relative "ownership" of the liquidity portion of that fee.
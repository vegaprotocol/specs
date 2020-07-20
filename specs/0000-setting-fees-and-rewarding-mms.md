# Setting fees and rewarding market makers

## Summary

The aim of this specification is to set out how fees on Vega are set based on committed market making stake and prevailing open interest on the market. Let us recall that market makers can commit and withdraw stake by submitting / amending a special market making pegged order type [market maker order spec](????.md). 

## Definitions / Glossary of terms used
- **Open interest**: the volume of all open positions in a given market (ie order book)
- **Liquidity**: measured as per [liquidity measurement spec](0034-prob-weighted-liquidity-measure.ipynb) (but it's basically volume on the book weighted by the probability of trading)
- **Supplied liquidity**: this counts only the liquidity provided through the special market making order that market makers have committed to as per [market maker order spec](????.md) 
- **Liquidity demand estimate**: as defined in [liquidity monitoring](????-liquidity-monitoring.md) spec we use maximum open interest in the market captured between the current time t and t-[p](#Liquidity-auction-network-parameters) for now. 
- **Sufficient liquidity trigger `c_2`**: a network parameter `c_2` defined in [liquidity monitoring](????-liquidity-monitoring.md) spec. 
- **Market value estimate** is calculated to be the estimated fee income for the entire future existence of the market using recent fee income. See further in this spec for details.


## Calculating market fees

As part of the market making order type, the market maker submits his desired fee level for the market. Here we describe how the market fee is set from all these submitted values. 
First, we produce a list of pairs which capture committed liquidity of each mm together with their desired fee and arrange this list in an increasing order by fee amount. Thus we have 
```
[MM 1 liquidity, MM 1 fee]
[MM 2 liquidity, MM 2 fee]
...
[MM N liquidity, MM N fee]
```
where `N` is the number of market makers who have committed to supply liquidity to this market. Note that `MM 1 fee <= MM 2 fee <= ... <= MM N fee` because we demand this list of pairs to be sorted. 

We now find smallest integer `k` such that `c_2 x [liquidity demand estimate] < sum from i=1 to k of [MM liquidity i]`. In other words we want in this ordered list to find the market makers that supply the liquidity that's required. If no such `k` exists we set `k=N`.

Finally, we set the fee for this market to be the fee `MM k fee`. 

### Example for fee setting mechanism
Let us say that `c_2 = 10`. 
``` 
[MM 1 liquidity = 120, MM 1 fee = 0.5%]
[MM 2 liquidity = 20, MM 2 fee = 0.75%]
[MM 3 liquidity = 60, MM 3 fee = 3.75%]
```
1. If the `liquidity demand estimate = 10` then `c_2 x [liquidity demand estimate] = 100` which means that the needed liquidity is given by MM 1, thus `k=1` and so the market fee is  `MM 1 fee = 0.5%`. 
1. If the `liquidity demand estimate = 11.5` then `c_2 x [liquidity demand estimate] = 115` which means that the needed liquidity is given by MM 1 and MM 2, thus `k=2` and so the market fee is  `MM 2 fee = 0.75%`. 
1. If the `liquidity demand estimate = 123` then `c_2 x [liquidity demand estimate] = 1230` which means that even putting all the liquidity supplied above does not meet the estimated market liquidity demand and thus we set `k=N` and so the market fee is `MM N fee = MM 3 fee = 3.75%`. 

## Timing market fee changes

Initially (before market opened) the maximum open interest is by definition zero (it's no possible to have a position on a market that's not opened yet). Hence by default the initial fee is the one supplied by the market maker who commited stake *first*. 
Once the market opens (opening auction starts) a clock starts ticking. We have a period over which we measure the maximum open interest to estimate liquidity demand. This is a network parameter as per [liquidity monitoring](????-liquidity-monitoring.md) spec. Every time this period elapses the market fee is re-evaluated. This is written with the assumption that this parameter is something between 24 hours and 7 days. If it's significantly longer then this doesn't really work so well. On the other hand I don't want to introduce more parameters for now... and we don't want to update fees continuously as this will create another source of unpredictability for users. 

## Calculating market value estimate

Is calculated to be the estimated fee income for the entire future existence of the market using recent fee income. If this results in a smaller amount than the committed market making bonds then the market value estimate is the sum of all the committed market making bonds. 

We have a period over which we measure the maximum open interest to estimate liquidity demand. This is a network parameter as per [liquidity monitoring](????-liquidity-monitoring.md) spec. 
We need to keep track of the total amount of fees collected on this market over this period. 

The market value estimate is then then amount of fees collected over the last period (or zero if a full period hasn't elapsed yet) multiplied by the number of full periods until the settlement time. 

### Example
1. The market was just proposed and one MM commited stake. No full fee collecting period has yet elapsed and so the market value estimate is equal to the stake of the committed MM. 
1. A MM has committed stake of `10000 ETH`. The fees collected over the last period were `10 ETH` and there are `100` periods till the settlement. The estimated future fee income is `10 x 100 = 1000 ETH` but that's less than the stake of the MM so the market value estimate is still `10000 ETH`.
1. A MM has committed stake of `10000 ETH`. The fees collected over the last period were `250 ETH` and there are `1000` periods till the settlement. The estimated future fee income is `250 x 1000 = 250000 ETH` so the market value estimate is still `250 000 ETH`.

## Calculating market maker equity-like share

The guiding principle of this section is that by commiting stake a market maker buys a portion of the "value" of the market. 

At any time let's say we have `market value estimate` calculated above and existing market makers with equity-like share as below
```
[MM 1 eq share, MM 1 ownership amt]
[MM 2 eq share, MM 2 ownership amt]
...
[MM N eq share, MM 3 ownership amt]
```
Here `MM i ownership amt = [MM i equity share] x [market value estimate]`. 

If a new market maker `MM N+1` who commits stake (by sucessfully submitting a MM order) equal to `S` then purchases a `MM N+1 eq share = S / ([market value estimate] + S)`. 
This "dilutes" the equity-like share of existing MMs as follows: 
```
New MM i eq share = (1 - [MM N+1 eq share]) x [MM i eq share].
```

**Check** the sum from over `i` from `1` to `N` of `New MM i` is equal to `1`.

If an existing market maker, say, without loss of generality, MM 1 as in the above list there is no order, wishes to reduce their MM stake `S` to a lower amount `0 <= New S < S` then we adjust every MM's `eq share` as follows. 
1. Calculate the MM 1 reduction factor `f=[New S] / S`. 
1. Calculate the rescaling factor `r = 1/(1-[MM 1 eq share] x (1-f))`
1. For MM 1 let `New MM 1 eq share = r x f x [MM 1 eq share]`.
1. For `i` in `2` to `N` update `New MM i eq share = r x [MM i eq share]`. 

**Check** the sum from over `i` from `1` to `N` of `New MM i` is equal to `1`.

# Setting fees and rewarding liquidity providers

## Summary

The aim of this specification is to set out how fees on Vega are set based on committed liquidity provider stake and prevailing open interest on the market leading to [target stake](../protocol/0041-TSTK-target_stake.md). Let us recall that liquidity providers can commit and withdraw stake by submitting / amending a special liquidity provider pegged order type [liquidity provider order spec](./0038-OLIQ-liquidity_provision_order_type.md).

## Definitions / Glossary of terms used
- **Market value proxy window length `market.value.windowLength`**: sets the length of the window over which we estimate the market value. This is a network parameter.  
- **Target stake**: as defined in [target stake spec](./0041-TSTK-target_stake.md). The ideal amount of stake LPs would commit to a market.
- `market.liquidityProvision.minLpStakeQuantumMultiple`: There is a network wide parameter specifying the minimum LP stake as the `quantum` specified per asset, see [asset framework spec](../protocol/0040-ASSF-asset_framework.md).


## CALCULATING LIQUIDITY FEE FACTOR

The [liquidity fee factor](./0029-FEES-fees.md) is an input to the total taker fee that a price taker of a trade pays:

`total_fee = infrastructure_fee + maker_fee + liquidity_fee`

`liquidity_fee = fee_factor[liquidity] x trade_value_for_fee_purposes`

As part of the [commit liquidity network transaction](./0038-OLIQ-liquidity_provision_order_type.md), the liquidity provider submits their desired level for the [liquidity fee factor](./0042-LIQF-setting_fees_and_rewarding_lps.md) for the market. Here we describe how this fee factor is set from the values submitted by all liquidity providers for a given market. 
First, we produce a list of pairs which capture committed liquidity of each LP together with their desired liquidity fee factor and arrange this list in an increasing order by fee amount. Thus we have 
```
[LP-1-stake, LP-1-liquidity-fee-factor]
[LP-2-stake, LP-2-liquidity-fee-factor]
...
[LP-N-stake, LP-N-liquidity-fee-factor]
```
where `N` is the number of liquidity providers who have committed to supply liquidity to this market. Note that `LP-1-liquidity-fee-factor <= LP-2-liquidity-fee-factor <= ... <= LP-N-liquidity-fee-factor` because we demand this list of pairs to be sorted in this way. 

We now find the smallest integer `k` such that `[target stake] < sum from i=1 to k of [LP-i-stake]`. In other words we want in this ordered list to find the liquidity providers that supply the liquidity that's required. If no such `k` exists we set `k=N`.

Finally, we set the liquidity-fee-factor for this market to be the fee `LP-k-liquidity-fee-factor`. 

### Example for fee setting mechanism
In the example below there are 3 liquidity providers all bidding for their chosen fee level. The LP orders they submit are sorted into increasing fee order so that the lowest fee bid is at the top and the highest is at the bottom. The fee level chosen for the market is derived from the liquidity commitment of the market (`target stake`) and the amount of stake committed from each bidder. Vega processes the LP orders from top to bottom by adding up the commitment stake as it goes until it reaches a level greater than or equal to the `target stake`. When that point is reached the fee used is the fee of the last liquidity order processed.
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

Once the market opens (opening auction starts) a clock starts ticking. We calculate the `[target stake]` using [target stake](./0041-TSTK-target_stake.md). The fee is continuously re-evaluated using the mechanism above. 

### APIs for fee factor calculations - what should core be exposing?

At time of call:
* The `liquidity-fee-factor` for the market.
* Current liquidity provider commitments and their individually nominated fee factors
* [Target stake](./0041-TSTK-target_stake.md)

## Splitting Fees Between Liquidity Providers

The guiding principle of this section is that by committing stake a liquidity provider gets virtual stake that depends on how trading has grown on the market. The virtual stake then determines equity-like share as will be set out below. Equity-like share is then used to split fee revenue between LPs.

### Calculating liquidity provider equity-like share

The parameter which determines the period over which market value and hence growth is `market.value.windowLength` which could be e.g. a week. 
From the end of the opening auction, which we will refer to as `t0` until `t0+market.value.windowLength` is the `0th` or "bootstrap period". Then from `t0+market.value.windowLength` until `t0 + 2 x market.value.windowLength` is the `1st` period and so on. 
For each LP we track the stake they have and also their virtual stake. 
Before and during the 0th (bootstrap) any stake commitment or removal is mirrored in the virtual stake. 

For any period `n >= 1` LP can add stake or remove stake but virtual stake is treated differently:

Say an `LP i` wants increases their commitment by `delta > market.liquidityProvision.minLpStakeQuantumMultiple x quantum` (this could also be the initial commitment). Then we update
```
LP i virtual stake <- LP i virtual stake + delta.
```

Say an `LP i` wants to decrease their commitment by `delta < 0`. Then we update 
```
LP i virtual stake <- LP i virtual stake x (LP i stake + delta)/(LP i stake).
``` 

Independently of the above we also update all virtual stakes at start of each new period. 
To that end "total value for fee purposes" is cumulated over the period set by `market.value.windowLength`. For a period `n` call this `T(n)`. 
We let the `0`th period start the moment the opening auction ends and last for `market.value.windowLength`.   
We include the volume of the trades that resolved the opening auction in `T(0)`. 
From this we calculate the running average trade value for fee purposes:
```
A(0) <- T(0),
A(n) <- A(n-1) x n/(n+1) + T(n)/(n+1), for `n=1,2,...
```

For `n = 0` set `r=0` and for `n = 1,2,...` the g`r`owth of the market is then 
```
r = 0
if A(n) > 0 and A(n-1) > 0
    r =  (A(n)-A(n-1))/A(n-1),
```
Thus at the end of period `n` update
```
if n = 0 or n = 1 or A(n) = 0 or A(n-1) = 0
    LP i virtual stake <- LP i physical stake
else
    LP i virtual stake <- max(LP i physical stake, (1 + r) x (LP i virtual stake)).
```
Thus the virtual stake of an LP will always be at least their physical stake.
Moreover, in situations when trading volume was zero in the previous period or if it is zero in the current period then we don't define the growth `r` and so in such extreme situations the virtual stake reverts to the physical stake.

The equity-like share for each LP is then
```
(LP i equity-like share) = (LP i virtual stake) / (sum over j from 1 to N of (LP j virtual stake)).
```
**Check** the sum from over `i` from `1` to `N` of `LP i equity-like share` is equal to `1`.
**Warning** the above will be decimal calculations so the above checks will only be true up to a rounding errors.

There is a [Google sheet - requiring Vega login](https://docs.google.com/spreadsheets/d/14AgZwa6gXVBUFBUUOmB7Y9PsG8D4zmYN/edit#gid=886563806) showing this.

The average entry valuation (which should be reported by the APIs and could be calculated only by the data node as it doesn't itself impact core state) is defined, at the time of change of an LP commitment as follows:
1. There already is `average entry valuation` for the LP in question (and `average entry valuation = 0` for a new LP). The LP has existing physical stake `S` (and `S=0` for new LP) and wishes to add / remove stake `Delta S`. If `Delta S < 0` then `average entry valuation` is unchanged by the transaction. If `S + Delta S = 0` then the LP is exiting their LP commitment and we do not calculate the `average entry valuation` for them in this case. 
So `Delta S > 0` (and so `S+Delta S > 0`) in what follows.
2. Calculate the entry valuation at the time stake `Delta S` is added / removed as 
```
(entry valuation) = sum over j from 1 to N of (LP j virtual stake)
```
Note, the `virtual stake` used in the calcuation of `entry valuation` is after the change of the LP commitmnet is applied.
This in particular means that if this is the first LP commitment on the market then the `(entry valuation) = Delta S`.
3. Update the average entry valuation to 
```
(average entry valuation) <- (average entry valuation) x S / (S + Delta S) + (entry valuation) x (Delta S) / (S + Delta S)
```
Example 1: 
Currently the sum of all virtual stakes is `900`. A new LP has `0` stake and add stake `Delta S = 100`. The sum of all virtual stakes is now `1000`. The average entry valuation is
```
(average entry valuation) <- 0 + 1000 x 100 / (0 + 100) = 1000
```
Example 2: 
A new LP1 has `0` stake and they wish to add `Delta S = 8000` and a new LP2 has `0` stake and they wish to add `Delta S = 2000`. Currently the sum of all virtual stakes is `10000` after the LP commmitments added. The average entry valuations are:
```
(average entry valuation LP1) <- 0 + 8000 x 8000 / (0 + 8000) = 8000
(average entry valuation LP2) <- 0 + (8000 + 2000) x 2000 / (0 + 2000) = 10000
```
Example 3:
An existing LP has `average entry valuation 1000` and `S=100`. Currently the sum of all virtual stakes is `2000`. They wish to add `10` to their stake. 
```
(average entry valuation) <- 1000 x 100 / (100 + 10) + 2000 x 10 / (100 + 10) = 1090.9.... 
```
Example 4: 
An existing LP has `average entry valuation 1090.9` and `S=110`. Currently the sum of all virtual stakes is `3000`. They wish to remove `20` from their stake. Their average entry valuation stays the same
```
(average entry valuation) = 1090.9
```

### Distributing fees

On every trade, liquidity fee should be collected immediately into an account for each liquidity provider (call it LP fee account). Each party will have an LP fee account on every market on which they committed liquidity by providing LP stake. 

This account is not under control of the LP party (they cannot initiate transfers in or out of the account). The account is under control of the network and funds from this account will be transferred to the owning LP party according to the mechanism below.

A network parameter `market.liquidity.providers.fee.distributionTimeStep` will control how often fees are distributed from the LP fee account. Starting with the end of the opening auction the clock starts ticking and then rings every time `market.liquidity.providers.fee.distributionTimeStep` has passed. Every time this happens the balance in this account is transferred to the liquidity provider's margin account for the market. If `market.liquidity.providers.fee.distributionTimeStep` is set to `0` then the balance is distributed either immediately upon collection or at then end of a block. 

The liquidity fees are distributed pro-rata depending on the `LP i equity-like share` at a given time. 

#### Example
We have `4` LPs with equity-like share shares:
share as below
```
LP 1 els = 0.65
LP 2 els = 0.25
LP 3 els = 0.1
```
Trade happened, and the trade value for fee purposes multiplied by the liquidity fee factor is `103.5 ETH`. The following amounts be collected immediately into the LP fee accounts for the market:

```
0.65 x 103.5 = 67.275 ETH to LP 1's LP account
0.25 x 103.5 = 25.875 ETH to LP 2's LP account
0.10 x 103.5 = 10.350 ETH to LP 3's LP account
```

Then LP 4 made a delayed LP commitment, and updated share as below:

LP 1 els = 0.43
LP 2 els = 0.17
LP 3 els = 0.07
LP 4 els = 0.33

When the time defined by `market.liquidity.providers.fee.distributionTimeStep` elapses we do transfers:
```
67.275 ETH from LP 1's LP account to LP 1's margin account 
25.875 ETH from LP 2's LP account to LP 2's margin account 
10.350 ETH from LP 3's LP account to LP 3's margin account 
```

### APIs for fee splits and payments
* Each liquidity provider's equity-like share
* Each liquidity provider's average entry valuation
* The `market-value-proxy`


## Acceptance Criteria

### CALCULATING LIQUIDITY FEE FACTOR
- [ ] The examples provided result in the given outcomes (<a name="0042-LIQF-001" href="#0042-LIQF-001">0042-LIQF-001</a>)
- [ ] The resulting liquidity-fee-factor is always equal to one of the liquidity provider's individually nominated fee factors (<a name="0042-LIQF-002" href="#0042-LIQF-002">0042-LIQF-002</a>)
- [ ] The resulting liquidity-fee-factor is never less than zero (<a name="0042-LIQF-003" href="#0042-LIQF-003">0042-LIQF-003</a>)
- [ ] Liquidity fee factors are recalculated every time a liquidity provider nominates a new fee factor (using the commit liquidity network transaction). (<a name="0042-LIQF-004" href="#0042-LIQF-004">0042-LIQF-004</a>)
- [ ] Liquidity fee factors are recalculated every time the liquidity demand estimate changes. (<a name="0042-LIQF-005" href="#0042-LIQF-005">0042-LIQF-005</a>)
- [ ] If a change in the open interest causes the liquidity demand estimate to change, then fee factor is correctly recalculated.  (<a name="0042-LIQF-006" href="#0042-LIQF-006">0042-LIQF-006</a>)
- [ ] If passage of time causes the liquidity demand estimate to change, the fee factor is correctly recalculated.  (<a name="0042-LIQF-007" href="#0042-LIQF-007">0042-LIQF-007</a>)

### CHANGE OF NETWORK PARAMETERS
- [ ] Change of network parameter "market.liquidityProvision.minLpStakeQuantumMultiple" will change the multiplier of the asset quantum that sets the minimum LP commitment amount. If `market.liquidityProvision.minLpStakeQuantumMultiple` is changed then no LP orders that have already been submitted are affected. However any new submissions or amendments must respect the new amount and those not meeting the new minimum will be rejected. (<a name="0042-LIQF-021" href="#0042-LIQF-021">0042-LIQF-021</a>)
- [ ] Change of network parameter "market.value.windowLength" will affect equity-like share calculations from the next block. Decreasing it so that the current period is already longer then the new parameter value will end it immediately and the next period will have the length specified by the updated parameter. Increasing it will lengthen the current period upto the the length specified by the updated parameter. (<a name="0042-LIQF-022" href="#0042-LIQF-022">0042-LIQF-022</a>)


### SPLITTING FEES BETWEEN liquidity providers
- [ ] The examples provided result in the given outcomes.  (<a name="0042-LIQF-008" href="#0042-LIQF-008">0042-LIQF-008</a>)
- [ ] All liquidity providers in the market receive a greater than zero amount of liquidity fee. (<a name="0042-LIQF-010" href="#0042-LIQF-010">0042-LIQF-010</a>)
- [ ] The total amount of liquidity fee distributed is equal to the most recent `liquidity-fee-factor` x `notional-value-of-all-trades` (<a name="0042-LIQF-011" href="#0042-LIQF-011">0042-LIQF-011</a>)
- [ ] Liquidity providers with a commitment of 0 will not receive a share ot the fees (<a name="0042-LIQF-012" href="#0042-LIQF-012">0042-LIQF-012</a>)
- [ ] If a market has `market.liquidity.providers.fee.distributionTimeStep` set to more than `0` and such market settles then the fees are distributed as part of the settlement process, see [market lifecycle](./0043-MKTL-market_lifecycle.md). Any settled market has zero balances in all the LP fee accounts. (<a name="0042-LIQF-014" href="#0042-LIQF-014">0042-LIQF-014</a>)



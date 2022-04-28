# Setting fees and rewarding liquidity providers

## Summary

The aim of this specification is to set out how fees on Vega are set based on committed liquidity provider stake and prevailing open interest on the market leading to [target stake](../protocol/0041-TSTK-target_stake.md). Let us recall that liquidity providers can commit and withdraw stake by submitting / amending a special liquidity provider pegged order type [liquidity provider order spec](./0038-OLIQ-liquidity_provision_order_type.md).

## Definitions / Glossary of terms used
- **Market value proxy window length `t_market_value_window_length`**: sets the length of the window over which we estimate the market value. This is a network parameter.  
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

We now find the smallest integer `k` such that `[target stake] < sum from i=1 to k of [LP-stake-i]`. In other words we want in this ordered list to find the liquidity providers that supply the liquidity that's required. If no such `k` exists we set `k=N`.

Finally, we set the liquidity-fee-factor for this market to be the fee `LP-k-liquidity-fee-factor`. 

### Example for fee setting mechanism
In the example below we have 3 liquidity providers all bidding for their chosen fee level. The LP orders they submit are sorted into increasing fee order so that the lowest fee bid is at the top and the highest is at the bottom. The fee level chosen for the market is derived from the liquidity commitment of the market (`target stake`) and the amount of commitment stake from each bidder. We process the LP orders by adding up the commitment stake until we reach a level greater than or equal to the `target stake`. When we reach that point the fee we use is the fee of the last liquidity order we processed.
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

The guiding principle of this section is that by committing stake a liquidity provider gets virtual stake that depends on how trading has grown on the market. The virtual stake then determines equity-like-share as will be set out below. Equity like share is then used to split fee revenue between LPs.

### Calculating liquidity provider equity-like share

The parameter which determines the period over which market value and hence growth is `t_market_value_window_length` which could be e.g. a week. 
From the end of the opening auction, which we will refer to as `t0` until `t0+t_market_value_window_length` is the `0th` or "bootstrap period". Then from  `t0+t_market_value_window_length` until `t0 + 2 x t_market_value_window_length` is the `1st` period and so on. 
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
To that end "total value for fee purposes" is cumulated over the period. For a period `n` call this `T(n)`. 
Set `T(0) = trade value for fee purposes of resolving opening auction`.  
From this we calculate the running average trade value for fee purposes:
```
A(n) <- A(n-1) x (n-1)/n + T(n)/n.
```
The g`r`owth of the market is then 
```
r =  (A(n)-A(n-1))/A(n-1)
```
Thus at the end of period `n` update
```
LP i virtual stake <- max(LP i physical stake, (1 + r) x (LP i virtual stake)).
```
Thus the virtual stake of an LP will always be at least their physical stake.

The equity like share for each LP is then
```
(LP i equity) = (LP i virtual stake) / (sum over j from 1 to N of (LP j virtual stake)).
```

There is a [Google sheet - requiring Vega login](https://docs.google.com/spreadsheets/d/14AgZwa6gXVBUFBUUOmB7Y9PsG8D4zmYN/edit#gid=886563806) showing this.


**Check** the sum from over `i` from `1` to `N` of `LP i equity_share` is equal to `1`.
**Warning** the above will be decimal calculations so the above checks will only be true up to a rounding errors.

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
- [ ] The examples provided result in the given outcomes (<a name="0042-LIQF-001" href="#0042-LIQF-001">0042-LIQF-001</a>)
- [ ] The resulting liquidity-fee-factor is always equal to one of the liquidity provider's individually nominated fee factors (<a name="0042-LIQF-002" href="#0042-LIQF-002">0042-LIQF-002</a>)
- [ ] The resulting liquidity-fee-factor is never less than zero (<a name="0042-LIQF-003" href="#0042-LIQF-003">0042-LIQF-003</a>)
- [ ] Liquidity fee factors are recalculated every time a liquidity provider nominates a new fee factor (using the commit liquidity network transaction). (<a name="0042-LIQF-004" href="#0042-LIQF-004">0042-LIQF-004</a>)
- [ ] Liquidity fee factors are recalculated every time the liquidity demand estimate changes. (<a name="0042-LIQF-005" href="#0042-LIQF-005">0042-LIQF-005</a>)
- [ ] If a change in the open interest causes the liquidity demand estimate to change, then fee factor is correctly recalculated.  (<a name="0042-LIQF-006" href="#0042-LIQF-006">0042-LIQF-006</a>)
- [ ] If passage of time causes the liquidity demand estimate to change, the fee factor is correctly recalculated.  (<a name="0042-LIQF-007" href="#0042-LIQF-007">0042-LIQF-007</a>)

### SPLITTING FEES BETWEEN liquidity providers
- [ ] The examples provided result in the given outcomes.  (<a name="0042-LIQF-008" href="#0042-LIQF-008">0042-LIQF-008</a>)
- [ ] All liquidity providers in the market receive a greater than zero amount of liquidity fee. (<a name="0042-LIQF-010" href="#0042-LIQF-010">0042-LIQF-010</a>)
- [ ] The total amount of liquidity fee distributed is equal to the most recent `liquidity-fee-factor` x `notional-value-of-all-trades` (<a name="0042-LIQF-011" href="#0042-LIQF-011">0042-LIQF-011</a>)
- [ ] Liquidity providers with a commitment of 0 will not receive a share ot the fees (<a name="0042-LIQF-012" href="#0042-LIQF-012">0042-LIQF-012</a>)
- [ ] If a market has `liquidity_providers_fee_distribution_time_step` set to more than `0` and such market settles then the fees are distributed as part of the settlement process, see [market lifecycle](./0043-MKTL-market_lifecycle.md). Any settled market has zero balance in the pool used to cumulate LP fees. (<a name="0042-LIQF-013" href="#0042-LIQF-013">0042-LIQF-013</a>)

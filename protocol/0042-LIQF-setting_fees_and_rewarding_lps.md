# Setting fees and rewarding liquidity providers

## Summary

The aim of this specification is to set out how fees on Vega are set based on committed liquidity provider stake and prevailing open interest on the market leading to [target stake](../protocol/0041-TSTK-target_stake.md). Let us recall that liquidity providers can commit and withdraw stake by submitting / amending a special [liquidity commitment transaction](./0044-LIME-lp_mechanics.md).

## Definitions / Glossary of terms used

- **`market.value.windowLength`**: sets the length of the window over which we estimate the market growth. This is a network parameter.
- **Target stake**: as defined in [target stake spec](./0041-TSTK-target_stake.md). The ideal amount of stake LPs would commit to a market.
- `market.liquidityProvision.minLpStakeQuantumMultiple`: There is a network wide parameter specifying the minimum LP stake as the `quantum` specified per asset, see [asset framework spec](../protocol/0040-ASSF-asset_framework.md).

## Calculating the Liquidity Fee Factor

There are three methods for setting the liquidity fee factor, with the default method being the 'Marginal Cost method.' The liquidity fee setting mechanism is configured per market as part of the market proposal.

### Marginal Cost method

The [liquidity fee factor](./0029-FEES-fees.md) is an input to the total taker fee that a price taker of a trade pays:

`total_fee = infrastructure_fee + maker_fee + liquidity_fee`

`liquidity_fee = fee_factor[liquidity] x trade_value_for_fee_purposes`

As part of the [commit liquidity network transaction](./0044-LIME-lp_mechanics.md#commit-liquidity-network-transaction), the liquidity provider submits their desired level for the [liquidity fee factor](./0042-LIQF-setting_fees_and_rewarding_lps.md) for the market. Here we describe how this fee factor is set from the values submitted by all liquidity providers for a given market.
First, we produce a list of pairs which capture committed liquidity of each LP together with their desired liquidity fee factor and arrange this list in an increasing order by fee amount. Thus we have

```text
[LP-1-stake, LP-1-liquidity-fee-factor]
[LP-2-stake, LP-2-liquidity-fee-factor]
...
[LP-N-stake, LP-N-liquidity-fee-factor]
```

where `N` is the number of liquidity providers who have committed to supply liquidity to this market. Note that `LP-1-liquidity-fee-factor <= LP-2-liquidity-fee-factor <= ... <= LP-N-liquidity-fee-factor` because we demand this list of pairs to be sorted in this way.

We now find the smallest integer `k` such that `[target stake] < sum from i=1 to k of [LP-i-stake]`. In other words we want in this ordered list to find the liquidity providers that supply the liquidity that's required. If no such `k` exists we set `k=N`.

Finally, we set the liquidity-fee-factor for this market to be the fee `LP-k-liquidity-fee-factor`.

#### Example for fee setting mechanism using the marginal cost method

In the example below there are 3 liquidity providers all bidding for their chosen fee level. The LP orders they submit are sorted into increasing fee order so that the lowest fee bid is at the top and the highest is at the bottom. The fee level chosen for the market is derived from the liquidity commitment of the market (`target stake`) and the amount of stake committed from each bidder. Vega processes the LP orders from top to bottom by adding up the commitment stake as it goes until it reaches a level greater than or equal to the `target stake`. When that point is reached the fee used is the fee of the last liquidity order processed.

```text
[LP 1 stake = 120 ETH, LP 1 liquidity-fee-factor = 0.5%]
[LP 2 stake = 20 ETH, LP 2 liquidity-fee-factor = 0.75%]
[LP 3 stake = 60 ETH, LP 3 liquidity-fee-factor = 3.75%]
```

1. If the `target stake = 119` then the needed liquidity is given by LP 1, thus `k=1` and so the market's liquidity-fee-factor is  `LP 1 fee = 0.5%`.
1. If the `target stake = 123` then the needed liquidity is given by LP 1 and LP 2, thus `k=2` and so the market's liquidity-fee-factor is  `LP 2 fee = 0.75%`.
1. If the `target stake = 240` then even putting all the liquidity supplied above does not meet the estimated market liquidity demand and thus we set `k=N` and so the market's liquidity-fee-factor is `LP N fee = LP 3 fee = 3.75%`.
1. Initially (before market opened) the `[target stake]` is by definition zero (it's not possible to have a position on a market that's not opened yet). Hence by default the market's initial liquidity-fee-factor is the lowest liquidity-fee-factor.


### Stake-weighted-average method for setting the liquidity fee factor

The liquidity fee factor is set as the weighted average of the liquidity fee factors, with weights assigned based on the supplied stake from each liquidity provider.

#### Example for fee setting mechanism using the Stake-weighted-average method

In the example below there are 3 liquidity providers all bidding for their chosen fee level. The overall liquidity fee factor is the weight-average of their nominations:

```text
[LP 1 stake = 120 ETH, LP 1 liquidity-fee-factor = 0.5%]
[LP 2 stake = 20 ETH, LP 2 liquidity-fee-factor = 0.75%]
[LP 3 stake = 60 ETH, LP 3 liquidity-fee-factor = 3.75%]

then

liquidity-fee-factor = ((120 * 0.5%) + (20 * 0.75%) + (60 * 3.75%)) / (120 + 20 + 60) = 1.5%
```

### "Constant Liquidity Fee" Method

The liquidity fee factor is set to a constant directly as part of the market proposal.

#### Example for fee setting mechanism using the constant method

In the example below there are 3 liquidity providers all bidding for their chosen fee level and the overall liquidity fee factor is:

```text
[LP 1 stake = 120 ETH, LP 1 liquidity-fee-factor = 0.5%]
[LP 2 stake = 20 ETH, LP 2 liquidity-fee-factor = 0.75%]
[LP 3 stake = 60 ETH, LP 3 liquidity-fee-factor = 3.75%]
```

but the market was proposed with a constant fee of 0.8% so that is what the liquidity-fee-factor will be.

### Timing market's liquidity-fee-factor changes

Once the market opens (opening auction starts) a clock starts ticking. We calculate the `[target stake]` using [target stake](./0041-TSTK-target_stake.md). The fee is re-evaluated using the mechanism above at the start of each epoch using LPs commitments at start of epoch.

### APIs for fee factor calculations - what should core be exposing?

At time of call:

- The `liquidity-fee-factor` for the market, and the method used to calculate it.
- Current liquidity provider commitments and their individually nominated fee factors
- [Target stake](./0041-TSTK-target_stake.md)

## Splitting Fees Between Liquidity Providers

The guiding principle of this section is that by committing stake a liquidity provider gets virtual stake that depends on how trading has grown on the market. The virtual stake then determines equity-like share as will be set out below. Equity-like share is then used to split fee revenue between LPs.

### Calculating liquidity provider equity-like share

The parameter which determines the period over which growth is estimated is `market.value.windowLength` which could be e.g. a week.
From the end of the opening auction, which we will refer to as `t0` until `t0+market.value.windowLength` is the `0th` or "bootstrap period". Then from `t0+market.value.windowLength` until `t0 + 2 x market.value.windowLength` is the `1st` period and so on.
For each LP we track the stake they have and also their virtual stake.
For markets that have no "parent" market, see [governance](./0028-GOVE-governance.md)  we postulate that before and during the 0th (bootstrap) any stake commitment or removal is mirrored in the virtual stake.

For any period `n >= 1` LP can add stake or remove stake but virtual stake is treated differently for markets with "parent market":

If the market has a "parent market" then each LP which commits liquidity (to this market) gets the virtual stake copied from the parent market as the 1st step of the process and the stake they are committing here minus the stake on parent market is treated as the `delta` here.

Say an `LP i` wants increases their commitment by `delta > market.liquidityProvision.minLpStakeQuantumMultiple x quantum` (this could also be the initial commitment). Then we update

```text
LP i virtual stake <- LP i virtual stake + delta.
```

Say an `LP i` wants to decrease their commitment by `delta < 0`. Then we update

```text
LP i virtual stake <- LP i virtual stake x (LP i stake + delta)/(LP i stake).
```

Independently of the above we also update all virtual stakes at start of each new period.
To that end "total value for fee purposes" is cumulated over the period set by `market.value.windowLength`. For a period `n` call this `T(n)`.
We let the `0`th period start the moment the opening auction ends and last for `market.value.windowLength`.
We include the volume of the trades that resolved the opening auction in `T(0)` for markets with no parent market.
For markets with a parent market we take `T(0)` to be the most recent `T_{parent}(latest)`.
From this we calculate the running average trade value for fee purposes:

```text
A(0) <- T(0),
A(n) <- A(n-1) x n/(n+1) + T(n)/(n+1), for `n=1,2,...
```

For `n = 0` set `r=0` and for `n = 1,2,...` the `g"r"owth` of the market is then

```go
r = 0
if A(n) > 0 and A(n-1) > 0
    r =  (A(n)-A(n-1))/A(n-1),
```

Thus at the end of period `n` update

```go
if n = 0 or n = 1 or A(n) = 0 or A(n-1) = 0
    LP i virtual stake <- LP i physical stake
else
    LP i virtual stake <- max(LP i physical stake, (1 + r) x (LP i virtual stake)).
```

Thus the virtual stake of an LP will always be at least their physical stake.
Moreover, in situations when trading volume was zero in the previous period or if it is zero in the current period then we don't define the growth `r` and so in such extreme situations the virtual stake reverts to the physical stake.

The equity-like share for each LP is then

```text
(LP i equity-like share) = (LP i virtual stake) / (sum over j from 1 to N of (LP j virtual stake)).
```

**Check** the sum from over `i` from `1` to `N` of `LP i equity-like share` is equal to `1`.
**Warning** the above will be decimal calculations so the above checks will only be true up to a rounding errors.

The average entry valuation (which should be reported by the APIs and could be calculated only by the data node as it doesn't itself impact core state) is defined, at the time of change of an LP commitment as follows:

1. There already is `average entry valuation` for the LP in question (and `average entry valuation = 0` for a new LP). The LP has existing physical stake `S` (and `S=0` for new LP) and wishes to add / remove stake `Delta S`. If `Delta S < 0` then `average entry valuation` is unchanged by the transaction. If `S + Delta S = 0` then the LP is exiting their LP commitment and we do not calculate the `average entry valuation` for them in this case.
So `Delta S > 0` (and so `S+Delta S > 0`) in what follows.
2. Calculate the entry valuation at the time stake `Delta S` is added / removed as

```text
(entry valuation) = sum over j from 1 to N of (LP j virtual stake)
```

Note, the `virtual stake` used in the calculation of `entry valuation` is after the change of the LP commitment is applied.
This in particular means that if this is the first LP commitment on the market then the `(entry valuation) = Delta S`.
3. Update the average entry valuation to

```text
(average entry valuation) <- (average entry valuation) x S / (S + Delta S) + (entry valuation) x (Delta S) / (S + Delta S)
```

Example 1:
Currently the sum of all virtual stakes is `900`. A new LP has `0` stake and add stake `Delta S = 100`. The sum of all virtual stakes is now `1000`. The average entry valuation is

```text
(average entry valuation) <- 0 + 1000 x 100 / (0 + 100) = 1000
```

Example 2:
A new LP1 has `0` stake and they wish to add `Delta S = 8000` and a new LP2 has `0` stake and they wish to add `Delta S = 2000`. Currently the sum of all virtual stakes is `10000` after the LP commitments added. The average entry valuations are:

```text
(average entry valuation LP1) <- 0 + 8000 x 8000 / (0 + 8000) = 8000
(average entry valuation LP2) <- 0 + (8000 + 2000) x 2000 / (0 + 2000) = 10000
```

Example 3:
An existing LP has `average entry valuation 1000` and `S=100`. Currently the sum of all virtual stakes is `2000`. They wish to add `10` to their stake.

```text
(average entry valuation) <- 1000 x 100 / (100 + 10) + 2000 x 10 / (100 + 10) = 1090.9....
```

Example 4:
An existing LP has `average entry valuation 1090.9` and `S=110`. Currently the sum of all virtual stakes is `3000`. They wish to remove `20` from their stake. Their average entry valuation stays the same

```text
(average entry valuation) = 1090.9
```


### Calculating the instantaneous liquidity score

At every vega time change calculate the liquidity score for each committed LP.
This is done by taking into account all orders they have deployed within the `[min_lp_price,max_lp_price]` [range](./0044-LIME-lp_mechanics.md) and then calculating the volume-weighted [probability of trading](./0034-PROB-prob_weighted_liquidity_measure.ipynb) at each price level - call it instantaneous liquidity score.
For orders outside the tightest price monitoring bounds set probability of trading to 0. For orders which have less than 10% [probability of trading], we set the probability to 0 when calculating liquidity score.
Note that parked [pegged orders](./0037-OPEG-pegged_orders.md) and not-yet-triggered [stop orders](./0014-ORDT-order_types.md) are not included.

Now calculate the total of the instantaneous liquidity scores obtained for each committed LP:

`total = the sum of instantaneous liquidity scores for all LPs that have an active liquidity commitment`

Now, if the `total` comes out as `0` then set `fractional instantaneous liquidity score` to `1.0/n`, where `n` is the number of committed LPs.
Otherwise calculate fractional instantaneous liquidity score for each committed LP.

`fractional instantaneous liquidity score = instantaneous liquidity score / total`

Whenever a new LP fee distribution period starts set a counter `n=1`.
Then on every Vega time change, after `fractional instantaneous liquidity score` has been obtained for all the committed LPs, update:

`liquidity score <- ((n-1)/n) x liquidity score + (1/n) x fractional instantaneous liquidity score`

The liquidity score should always be rounded to 10 decimal places to prevent spurious accuracy and overly long string representation of a number.

### Distributing fees into LP-per-market fee account

On every trade, liquidity fee should be collected immediately into the market's aggregate LP fee account.
The account is under control of the network and funds from this account will be transferred to the owning LP party according to the mechanism below.

A network parameter `market.liquidity.providersFeeCalculationTimeStep` will control how often fees are distributed from the market's aggregate LP fee account.
Starting with the end of the opening auction the clock starts ticking and then rings every time `market.liquidity.providersFeeCalculationTimeStep` has passed. Every time this happens the balance in this account is transferred to the liquidity provider's general account for the market settlement asset.

The liquidity fees are transferred from the market's aggregate LP fee account into the LP-per-market fee account from two different configurable size buckets, defined by the network parameter `market.liquidity.equityLikeShareFeeFraction`. The first bucket, a proportion equal to `market.liquidity.equityLikeShareFeeFraction` of the fee, is divided pro-rata depending on the `LP i equity-like share` multiplied by `LP i liquidity score` scaled back to `1` across all LPs at a given time. The other bucket, `1 - market.liquidity.equityLikeShareFeeFraction`, is divided purely by each LP's in-epoch liquidity score `LP i liquidity score`, scaled again across the value of all LPs at that time.

The LP parties don't control the LP-per-market fee account; the fees from there are then transferred to the LPs' general account at the end epoch as described below.

### Calculating SLA performance

#### Measuring time spent meeting their commitment in a single epoch

During the epoch, the amount of time in nanoseconds (of Vega time) that each LP spends meeting the SLA is recorded. This can be done by maintaining a counter `s_i` as shown below:

- At the start of a new epoch, `s_i = 0`

  - If the LP is meeting their commitment, store the Vega time of the start of the epoch as the time the LP began meeting their commitment, otherwise store `nothing`.

- At start of block, for LP `i`, first reset the running minimum valid volume an LP is providing and across the block and then keep updating the minimum volume that the LP is providing that is [within the valid range](./0044-LIME-lp_mechanics.md) (section "Meeting the committed volume of notional").
- Note that the volume check must only happen _after_ iceberg orders, that need refreshing as a result of a transaction are refreshed. This means that while an iceberg order has sufficient `remaining` quantity, it will **never** be considered to be contributing less than its `minimum peak size`.

- At the end of each block:
  - If an LP has started meeting their [committed volume of notional based on the minimum volume recorded during the block](./0044-LIME-lp_mechanics.md) (section "Calculating liquidity from commitment") after previously not doing so (i.e. `nothing` is stored as the time the LP began meeting their commitment):
    - Store the current Vega time attached to the block being processed as the time the LP began meeting their commitment.

  - If an LP has stopped meeting their committed volume of notional after previously doing so:
    - Add the difference in nanoseconds between the current Vega time attached to the block being processed and the time the LP began meeting their commitment (stored in the step above) to `s_i`.
    - Store `nothing` as the time the LP began meeting their commitment, to signify the LP not meeting their commitment.

- At the end of the epoch, calculate the actual observed epoch length `observed_epoch_length` = the difference in nanoseconds between the Vega time at the start of the epoch and the Vega time at the end of the epoch.

Note that because vega time won't be progressing inside a block the above mechanism should ensure that `s_i` gets incremented only if the LP was meeting their commitment at every point this was checked within the block.

#### Calculating the SLA performance penalty for a single epoch

Calculate the fraction of the time the LP spent on the book:

```text
fraction_of_time_on_book = s_i / observed_epoch_length
```

For any LP where `fraction_of_time_on_book < market.liquidity.commitmentMinTimeFraction` the SLA penalty fraction `p_i = 1` (that is, the penalty is 100% of their fees).

For each LP where `fraction_of_time_on_book ≥ market.liquidity.commitmentMinTimeFraction`, the SLA penalty fraction `p_i` is calculated as follows:

Let $t$ be `fraction_of_time_on_book`

Let $s$ be `market.liquidity.commitmentMinTimeFraction`.

Let $c$ be `market.liquidity.slaCompetitionFactor`.

$$p_i = \begin{cases}
    (1 - \frac{t - s}{1 - s}) \cdot c &\text{if } s < 1 \\
    0 &\text{if } s = 1
\end{cases}$$

#### Calculating the SLA performance penalty for over hysteresis period

Now, for each LP $i$ take the $p_i$ values calculated over the last `market.liqudity.performanceHysteresisEpochs - 1`, call these $p_i^1, p_i^2, ..., p_i^{n-1}$ (if all the historical ones are not yet available, take as many as there are - i.e. expanding window till you get to the full length).

Now calculate $p_i^n$ to be the arithmetic average of $p_i^k$ for $k = 1,2,...,n-1$.
Finally set

$$
p_i^n \leftarrow \max(p_i,p_i^n).
$$

i.e. your penalty is the bigger of current epoch and average over the hysteresis period

### Applying LP SLA performance penalties to accrued fees

As defined above, for each LP for each epoch you have "penalty fraction" $p_i^n$ which is between `[0,1]` with `0` indicating LP has met commitment 100% of the time and `1` indicating that LP was below `market.liquidity.commitmentMinTimeFraction` of the time. All vAMM LPs should also receive a $p_i^n$ value, however this will always be `0`, as they are defined as always meeting their commitment.

If for all $i$ (all the LPs) have $p_i^n = 1$ then all the fees go into the market insurance pool and we stop.

Calculate

$$
w_i = \frac{\text{LP-per-market fee account } i}{\sum_k \text{LP-per-market fee account } k}.
$$

For each LP transfer $(1-p_i^n) \times \text{ amount in LP-per-market fee account}$ to their general account with a transfer type that marks this as the "LP net liquidity fee distribution".

Transfer the remaining amount from each LP-per-market fee account back into the market's aggregate LP fee account. Record the total inflow as a result of that operation as $B$.
Let $b_i := (1-p_i^n) \times w_i$ and renormalise $b_i$s so that they sum up to $1$ i.e.

$$
b_i \leftarrow \frac{b_i}{\sum_k b_k}\,.
$$

Each LP further gets a performance bonus: $b_i \times B$ with a transfer type that marks this as the "LP relative SLA performance bonus distribution".

### APIs for fee splits and payments

- Each liquidity provider's equity-like share
- Each liquidity provider's average entry valuation

## Acceptance Criteria

### CALCULATING LIQUIDITY FEE FACTOR TESTS

- The examples provided result in the given outcomes (<a name="0042-LIQF-001" href="#0042-LIQF-001">0042-LIQF-001</a>)
- The resulting liquidity-fee-factor is always equal to one of the liquidity provider's individually nominated fee factors (<a name="0042-LIQF-002" href="#0042-LIQF-002">0042-LIQF-002</a>) For product spot: (<a name="0042-LIQF-063" href="#0042-LIQF-063">0042-LIQF-063</a>).
- The resulting liquidity-fee-factor is never less than zero (<a name="0042-LIQF-003" href="#0042-LIQF-003">0042-LIQF-003</a>)
- Liquidity fee factors are recalculated every time a liquidity provider nominates a new fee factor (using the commit liquidity network transaction). (<a name="0042-LIQF-004" href="#0042-LIQF-004">0042-LIQF-004</a>)
- Liquidity fee factors are recalculated every time the liquidity demand estimate changes. (<a name="0042-LIQF-005" href="#0042-LIQF-005">0042-LIQF-005</a>). For product spot: (<a name="0042-LIQF-064" href="#0042-LIQF-064">0042-LIQF-064</a>).
- If a change in the open interest causes the liquidity demand estimate to change, then fee factor is correctly recalculated.  (<a name="0042-LIQF-006" href="#0042-LIQF-006">0042-LIQF-006</a>)
- If passage of time causes the liquidity demand estimate to change, the fee factor is correctly recalculated.  (<a name="0042-LIQF-007" href="#0042-LIQF-007">0042-LIQF-007</a>). For product spot: (<a name="0042-LIQF-065" href="#0042-LIQF-065">0042-LIQF-065</a>).
- A market can be proposed with a choice of liquidity fee settings. These settings can be updated by a subsequent market update proposal. Moreover, the correct fee value and liquidity fee setting method can be read from the data node APIs. Upon proposal enactment the new liquidity method is applied to recalculate the liquidity fee. The tests should be carried out with the following methods:
  - Weighted average (<a name="0042-LIQF-056" href="#0042-LIQF-056">0042-LIQF-056</a>). For product spot: (<a name="0042-LIQF-066" href="#0042-LIQF-066">0042-LIQF-066</a>).
  - Constant fee (<a name="0042-LIQF-061" href="#0042-LIQF-061">0042-LIQF-061</a>). For product spot: (<a name="0042-LIQF-067" href="#0042-LIQF-067">0042-LIQF-067</a>).
  - Marginal cost (<a name="0042-LIQF-062" href="#0042-LIQF-062">0042-LIQF-062</a>). For product spot: (<a name="0042-LIQF-068" href="#0042-LIQF-068">0042-LIQF-068</a>).
- The above example for the liquidity fee when the method is weighted-average results in a fee-factor of 1.5% (<a name="0042-LIQF-057" href="#0042-LIQF-057">0042-LIQF-057</a>). For product spot: (<a name="0042-LIQF-069" href="#0042-LIQF-069">0042-LIQF-069</a>).
- The above example for the liquidity fee when the method is constant-fee results in a fee-factor of 0.8% (<a name="0042-LIQF-058" href="#0042-LIQF-058">0042-LIQF-058</a>). For product spot: (<a name="0042-LIQF-070" href="#0042-LIQF-070">0042-LIQF-070</a>).
- The above example for the liquidity fee when the method is marginal cost results in a fee-factor of `3.75%` (<a name="0042-LIQF-059" href="#0042-LIQF-059">0042-LIQF-059</a>). For product spot: (<a name="0042-LIQF-071" href="#0042-LIQF-071">0042-LIQF-071</a>).
- For the constant-fee method validate that the fee factor can only be between 0 and 1 inclusive (<a name="0042-LIQF-060" href="#0042-LIQF-060">0042-LIQF-060</a>). For product spot: (<a name="0042-LIQF-072" href="#0042-LIQF-072">0042-LIQF-072</a>).


### CHANGE OF NETWORK PARAMETERS TESTS

- Change of network parameter `market.liquidityProvision.minLpStakeQuantumMultiple` will change the multiplier of the asset quantum that sets the minimum LP commitment amount. If `market.liquidityProvision.minLpStakeQuantumMultiple` is changed then no LP orders that have already been submitted are affected. However any new submissions or amendments must respect the new amount and those not meeting the new minimum will be rejected. (<a name="0042-LIQF-021" href="#0042-LIQF-021">0042-LIQF-021</a>)
- Change of network parameter `market.value.windowLength` will affect equity-like share calculations from the next block. Decreasing it so that the current period is already longer then the new parameter value will end it immediately and the next period will have the length specified by the updated parameter. Increasing it will lengthen the current period up to the the length specified by the updated parameter. (<a name="0042-LIQF-022" href="#0042-LIQF-022">0042-LIQF-022</a>)


### SPLITTING FEES BETWEEN liquidity providers

- The examples provided result in the given outcomes.  (<a name="0042-LIQF-008" href="#0042-LIQF-008">0042-LIQF-008</a>)
- The total amount of liquidity fee distributed is equal to the most recent `liquidity-fee-factor` x `notional-value-of-all-trades` (<a name="0042-LIQF-011" href="#0042-LIQF-011">0042-LIQF-011</a>)
- Liquidity providers with a commitment of 0 will not receive a share of the fees (<a name="0042-LIQF-012" href="#0042-LIQF-012">0042-LIQF-012</a>)
- When a market settles any fees from any intermediate fee accounts are distributed as if the epoch ended as part of the settlement process, see [market lifecycle](./0043-MKTL-market_lifecycle.md). Any settled market has zero balances in all the LP fee accounts. (<a name="0042-LIQF-014" href="#0042-LIQF-014">0042-LIQF-014</a>)
- All liquidity providers with `average fraction of liquidity provided by committed LP > 0` in the market receive a greater than zero amount of liquidity fee. The only exception is if a non-zero amount is rounded to zero due to integer representation. (<a name="0042-LIQF-015" href="#0042-LIQF-015">0042-LIQF-015</a>)
- After fee distribution, if there is a remainder in the liquidity fee account and the market is not being settled, it should be left in the liquidity fee account and carried over to the next distribution window. (<a name="0042-LIQF-032" href="#0042-LIQF-032">0042-LIQF-032</a>)


### LP JOINING AND LEAVING MARKETS

- An LP joining a market that is below the target stake with a higher fee bid than the current fee: their fee is used (<a name="0042-LIQF-019" href="#0042-LIQF-019">0042-LIQF-019</a>)
- Given the fee setting method is marginal cost. An LP joining a spot market that is below the target stake with a higher fee bid than the current fee: their fee is used when the fee is next recalculated (<a name="0042-LIQF-073" href="#0042-LIQF-073">0042-LIQF-073</a>)
- An LP joining a market that is below the target stake with a lower fee bid than the current fee: fee doesn't change (<a name="0042-LIQF-020" href="#0042-LIQF-020">0042-LIQF-020</a>)
- Given the fee setting method is marginal cost. An LP joining a market that is below the target stake with a lower fee bid than the current fee: fee doesn't change (<a name="0042-LIQF-074" href="#0042-LIQF-074">0042-LIQF-074</a>)
- An LP joining a market that is above the target stake with a sufficiently large commitment to push ALL higher bids above the target stake and a lower fee bid than the current fee: their fee is used (<a name="0042-LIQF-029" href="#0042-LIQF-029">0042-LIQF-029</a>)
- Given the fee setting method is marginal cost. An LP joining a spot market that is above the target stake with a sufficiently large commitment to push ALL higher bids above the target stake and a lower fee bid than the current fee: their fee is used when the fee is next recalculated (<a name="0042-LIQF-075" href="#0042-LIQF-075">0042-LIQF-075</a>)
- An LP joining a market that is above the target stake with a commitment not large enough to push any higher bids above the target stake, and a lower fee bid than the current fee: the fee doesn't change (<a name="0042-LIQF-030" href="#0042-LIQF-030">0042-LIQF-030</a>)
- Given the fee setting method is marginal cost. An LP joining a spot market that is above the target stake with a commitment not large enough to push any higher bids above the target stake, and a lower fee bid than the current fee: the fee doesn't change when the fee is next recalculated (<a name="0042-LIQF-076" href="#0042-LIQF-076">0042-LIQF-076</a>)
- An LP joining a market that is above the target stake with a commitment large enough to push one of two higher bids above the target stake, and a lower fee bid than the current fee: the fee changes to the other lower bid (<a name="0042-LIQF-023" href="#0042-LIQF-023">0042-LIQF-023</a>)
- Given the fee setting method is marginal cost. An LP joining a spot market that is above the target stake with a commitment large enough to push one of two higher bids above the target stake, and a lower fee bid than the current fee: the fee changes to the other lower bid when the fee is next recalculated (<a name="0042-LIQF-077" href="#0042-LIQF-077">0042-LIQF-077</a>)
- An LP joining a market that is above the target stake with a commitment large enough to push one of two higher bids above the target stake, and a higher fee bid than the current fee: the fee doesn't change (<a name="0042-LIQF-024" href="#0042-LIQF-024">0042-LIQF-024</a>)
- Given the fee setting method is marginal cost. An LP joining a spot market that is above the target stake with a commitment large enough to push one of two higher bids above the target stake, and a higher fee bid than the current fee: the fee doesn't change when the fee is next recalculated (<a name="0042-LIQF-078" href="#0042-LIQF-078">0042-LIQF-078</a>)
- An LP leaves a market that is above target stake when their fee bid is currently being used: fee changes to fee bid by the LP who takes their place in the bidding order (<a name="0042-LIQF-025" href="#0042-LIQF-025">0042-LIQF-025</a>)
- Given the fee setting method is marginal cost. An LP leaves a market that is above target stake when their fee bid is currently being used: fee changes to fee bid by the LP who takes their place in the bidding order when the fee is next recalculated (<a name="0042-LIQF-079" href="#0042-LIQF-079">0042-LIQF-079</a>)
- An LP leaves a market that is above target stake when their fee bid is lower than the one currently being used and their commitment size changes the LP that meets the target stake: fee changes to fee bid by the LP that is now at the place in the bid order to provide the target stake (<a name="0042-LIQF-026" href="#0042-LIQF-026">0042-LIQF-026</a>)
- Given the fee setting method is marginal cost. An LP leaves a market that is above target stake when their fee bid is lower than the one currently being used and their commitment size changes the LP that meets the target stake: fee changes to fee bid by the LP that is now at the place in the bid order to provide the target stake when the fee is next recalculated (<a name="0042-LIQF-080" href="#0042-LIQF-080">0042-LIQF-080</a>)
- An LP leaves a market that is above target stake when their fee bid is lower than the one currently being used. The loss of their commitment doesn't change which LP meets the target stake: fee doesn't change (<a name="0042-LIQF-027" href="#0042-LIQF-027">0042-LIQF-027</a>)
- Given the fee setting method is marginal cost. An LP leaves a spot market that is above target stake when their fee bid is lower than the one currently being used. The loss of their commitment doesn't change which LP meets the target stake: fee doesn't change when the fee is next recalculated (<a name="0042-LIQF-081" href="#0042-LIQF-081">0042-LIQF-081</a>)
- An LP leaves a market that is above target stake when their fee bid is higher than the one currently being used: fee doesn't change (<a name="0042-LIQF-028" href="#0042-LIQF-028">0042-LIQF-028</a>)
- Given the fee setting method is marginal cost. An LP leaves a spot market that is above target stake when their fee bid is higher than the one currently being used: fee doesn't change (<a name="0042-LIQF-106" href="#0042-LIQF-106">0042-LIQF-106</a>)

### API

- Equity-like share of each active LP can be obtained via the API (<a name="0042-LIQF-016" href="#0042-LIQF-016">0042-LIQF-016</a>)
- Liquidity score of each active LP can be obtained via the API (<a name="0042-LIQF-017" href="#0042-LIQF-017">0042-LIQF-017</a>)
- Through the `LiquidityProviders` API, liquidity score, average entry valuation and equity-like share of each active LP can be obtained
  - GRPC (<a name="0042-LIQF-050" href="#0042-LIQF-050">0042-LIQF-050</a>)
  - GRAPHQL (<a name="0042-LIQF-051" href="#0042-LIQF-051">0042-LIQF-051</a>)
  - REST (<a name="0042-LIQF-052" href="#0042-LIQF-052">0042-LIQF-052</a>)


### Successor markets

- If an LP has virtual stake of `11000` and stake of `10000` on a parent marketID=`m1` and a new market is proposed and enacted as `m2` with `m1` as its parent market and the LP submits a commitment of `10000` to `m2` during the "Pending" period, see [lifecycle](./0043-MKTL-market_lifecycle.md) then for the duration of the first `market.value.windowLength` after the opening auction ends the LP has virtual stake of `11000` and stake of `10000` on `m2`. (<a name="0042-LIQF-031" href="#0042-LIQF-031">0042-LIQF-031</a>)
- If an LP has virtual stake of `11000` and stake of `10000` on a parent `marketID`=`m1` and a new market is proposed and enacted as `m2` with `m1` as its parent market and the LP submits a commitment of `20000` to `m2` during the "Pending" period, see [lifecycle](./0043-MKTL-market_lifecycle.md) then for the duration of the first `market.value.windowLength` after the opening auction ends the LP has virtual stake which must be result of the virtual stake obtained from `m1` with the `delta=10000` added on, so virtual stake of `21000`, assuming all other LPs committed exactly the stake they had on `m1`. (<a name="0042-LIQF-048" href="#0042-LIQF-048">0042-LIQF-048</a>)
- If an LP has virtual stake of `11000` and stake of `10000` on a parent `marketID`=`m1` and a new market is proposed and enacted as `m2` with `m1` as its parent market and the LP submits a commitment of `5000` to `m2` during the "Pending" period, see [lifecycle](./0043-MKTL-market_lifecycle.md) then for the duration of the first `market.value.windowLength` after the opening auction ends the LP has virtual stake obtained from `m1` with the `delta=-5000` added on (i.e. 5000 removed). (<a name="0042-LIQF-033" href="#0042-LIQF-033">0042-LIQF-033</a>)
- If `market.liquidity.providersFeeCalculationTimeStep > 0` for a given market and an LP submits a new liquidity commitment halfway through the time interval then they receive roughly 1/2 the fee income from that market compared with the next time interval when they maintain their commitment (and the traded value is the same in both time intervals). (<a name="0042-LIQF-034" href="#0042-LIQF-034">0042-LIQF-034</a>)


### Calculating SLA Performance

- If an LP has an active liquidity provision at the start of an epoch, `market.liquidity.slaCompetitionFactor = 1`, `market.liquidity.commitmentMinTimeFraction = 0.5` and throughout the epoch meets their liquidity provision requirements such that the `fraction_of_time_on_book = 0.75` then their penalty from that epoch will be `0.5`. This will be true whether:

  - Their liquidity is all provided at the start of the epoch and then none is provided for the second half (<a name="0042-LIQF-037" href="#0042-LIQF-037">0042-LIQF-037</a>). For spot (<a name="0042-LIQF-082" href="#0042-LIQF-082">0042-LIQF-082</a>)
  - Their liquidity is provided scattered throughout the epoch (<a name="0042-LIQF-038" href="#0042-LIQF-038">0042-LIQF-038</a>). For spot (<a name="0042-LIQF-083" href="#0042-LIQF-083">0042-LIQF-083</a>)

- If an LP has an active liquidity provision at the start of an epoch, `market.liquidity.slaCompetitionFactor = 0`, `market.liquidity.commitmentMinTimeFraction = 0.5` and throughout the epoch meets their liquidity provision requirements such that the `fraction_of_time_on_book = 0.75` then their penalty from that epoch will be `0`. (<a name="0042-LIQF-041" href="#0042-LIQF-041">0042-LIQF-041</a>). For spot (<a name="0042-LIQF-084" href="#0042-LIQF-084">0042-LIQF-084</a>)
- If an LP has an active liquidity provision at the start of an epoch, `market.liquidity.slaCompetitionFactor = 0.5`, `market.liquidity.commitmentMinTimeFraction = 0.5` and throughout the epoch meets their liquidity provision requirements such that the `fraction_of_time_on_book = 0.75` then their penalty from that epoch will be `0.25`. (<a name="0042-LIQF-042" href="#0042-LIQF-042">0042-LIQF-042</a>). For spot (<a name="0042-LIQF-085" href="#0042-LIQF-085">0042-LIQF-085</a>)

- When `market.liquidity.performanceHysteresisEpochs = 1`:

  - If an LP has an active liquidity provision at the start of an epoch and throughout the epoch always meets their liquidity provision requirements then they will have a `fraction_of_time_on_book == 1` and no penalty will be applied to their liquidity fee payments at the end of the epoch (<a name="0042-LIQF-035" href="#0042-LIQF-035">0042-LIQF-035</a>). For spot (<a name="0042-LIQF-086" href="#0042-LIQF-086">0042-LIQF-086</a>)
  - If an LP has an active liquidity provision at the start of an epoch and throughout the epoch meets their liquidity provision requirements less than `market.liquidity.commitmentMinTimeFraction` fraction of the time then they will have a full penalty and will receive `0` liquidity fee payments at the end of the epoch (<a name="0042-LIQF-049" href="#0042-LIQF-049">0042-LIQF-049</a>). For spot (<a name="0042-LIQF-087" href="#0042-LIQF-087">0042-LIQF-087</a>)
  - An LP has an active liquidity provision at the start of an epoch. The penalty rate for said LP over the previous `2` epochs is `0.75`. During the epoch `market.liquidity.performanceHysteresisEpochs` is set to `3`. Throughout the current epoch the LP meets their liquidity provision requirements so they will have `fraction_of_time_on_book == 1`. The penalty applied to fee distribution at epoch end will be `0` and will not consider the previous epochs. (<a name="0042-LIQF-053" href="#0042-LIQF-053">0042-LIQF-053</a>). For spot (<a name="0042-LIQF-088" href="#0042-LIQF-088">0042-LIQF-088</a>)

- When `market.liquidity.performanceHysteresisEpochs > 1`:

  - If an LP has an active liquidity provision at the start of an epoch, the average `penalty rate` over the previous `n-1` epochs is `0.75` and throughout the epoch they always meet their liquidity provision requirements then they will have a `fraction_of_time_on_book == 1` for the latest epoch a penalty rate of `0.75` will be applied to liquidity fee payments at the end of the epoch (<a name="0042-LIQF-047" href="#0042-LIQF-047">0042-LIQF-047</a>). For spot (<a name="0042-LIQF-089" href="#0042-LIQF-089">0042-LIQF-089</a>)
  - If an LP has an active liquidity provision at the start of an epoch, the average `penalty rate` over the previous `n-1` epochs is `0.5` and throughout the epoch they always meet their liquidity provision requirements then they will have a `fraction_of_time_on_book == 1` for the latest epoch a penalty rate of `0.5` will be applied to liquidity fee payments at the end of the epoch (<a name="0042-LIQF-039" href="#0042-LIQF-039">0042-LIQF-039</a>). For spot (<a name="0042-LIQF-090" href="#0042-LIQF-090">0042-LIQF-090</a>)
  - If an LP has an active liquidity provision at the start of an epoch, the average `penalty rate` over the previous `n-1` epochs is `0.5` and throughout the epoch they never meet their liquidity provision requirements then they will have a `fraction_of_time_on_book == 0` for the latest epoch a penalty rate of `1` will be applied to liquidity fee payments at the end of the epoch (<a name="0042-LIQF-040" href="#0042-LIQF-040">0042-LIQF-040</a>). For spot (<a name="0042-LIQF-091" href="#0042-LIQF-091">0042-LIQF-091</a>)
  - If an LP has an active liquidity provision at the start of an epoch and no previous performance penalties and throughout the epoch always meets their liquidity provision requirements then they will have a `fraction_of_time_on_book == 1` then no penalty will be applied to their liquidity fee payments at the end of the epoch. (<a name="0042-LIQF-054" href="#0042-LIQF-054">0042-LIQF-054</a>). For spot (<a name="0042-LIQF-100" href="#0042-LIQF-100">0042-LIQF-100</a>)


### SLA Performance bonus transfers

- The net inflow and outflow into and out of the market's aggregate LP fee account should be zero as a result of penalty collection and bonus distribution. (<a name="0042-LIQF-043" href="#0042-LIQF-043">0042-LIQF-043</a>). For spot (<a name="0042-LIQF-101" href="#0042-LIQF-101">0042-LIQF-101</a>)
- With two liquidity providers, one with an effective penalty rate of `0.5` and earned fees of `n`, and the other with an effective rate of `0.75` and earned fees of `m`, `50% * n` and `25% * m` of the second provider's should be transferred back into market's aggregate LP fee account. Then the total provider bonus score should be `b = (m / (n + m)) * 0.25 + (n / (n + m)) * 0.5` and provider 1 should receive `(0.5 * n + 0.25 * m) * (n / (n + m)) * 0.5 / b` and provider 2 should receive `(0.5 * n + 0.25 * m) * (m / (n + m)) * 0.25 / b` as an additional bonus payment (<a name="0042-LIQF-044" href="#0042-LIQF-044">0042-LIQF-044</a>). For spot (<a name="0042-LIQF-102" href="#0042-LIQF-102">0042-LIQF-102</a>)
- With two liquidity providers, one with an effective penalty rate of `1` and earned fees of `n`, and the other with an effective rate of `0` and earned fees of `m`, the entirety of `n` should be transferred to the second liquidity provider as a bonus payment (<a name="0042-LIQF-045" href="#0042-LIQF-045">0042-LIQF-045</a>). For spot (<a name="0042-LIQF-103" href="#0042-LIQF-103">0042-LIQF-103</a>)
- With only one liquidity provider, with an effective penalty rate of `0.5`, `50%` of their initially earned fees will be taken initially but will be entirely paid back to them as a bonus payment (<a name="0042-LIQF-046" href="#0042-LIQF-046">0042-LIQF-046</a>). For spot (<a name="0042-LIQF-104" href="#0042-LIQF-104">0042-LIQF-104</a>)

### Transfers example

Example 1, generated with [supplementary worksheet](https://docs.google.com/spreadsheets/d/1PQC2WYv9qRlyjbvvCYpVWCzO5MzwkcEGOR5aS9rWGEY) [internal only]. Values should match up to rounding used by `core` (<a name="0042-LIQF-055" href="#0042-LIQF-055">0042-LIQF-055</a>). For spot (<a name="0042-LIQF-105" href="#0042-LIQF-105">0042-LIQF-105</a>):
| LP    |   penalty fraction | LP-per-market fee accounts balance | 1st transfer amt |  2nd (bonus) transfer amt |
|   --- |   --------------   | --------------                       | --------------      | --------------           |
|   LP1 |   0                  | 1000                                 | 1000                |   24673.94095              |
|   LP2 |   0.05               | 100                                  | 95                | 2344.02439               |
|   LP3 |   0.6              | 7000                               | 2800                |   69087.03466              |
|   LP4 |   1                  | 91900                              | 0               | 0                          |


### vAMM behaviour

- All vAMMs active on a market at the end of an epoch receive SLA bonus rebalancing payments with `0` penalty fraction. (<a name="0042-LIQF-092" href="#0042-LIQF-092">0042-LIQF-092</a>)
- A vAMM active on a market during an epoch, which was cancelled prior to the end of an epoch, receives SLA bonus rebalancing payments with `0` penalty fraction. (<a name="0042-LIQF-093" href="#0042-LIQF-093">0042-LIQF-093</a>)
- A vAMMs cancelled in a previous epoch does not receive anything and is not considered during SLA rebalancing at the end of an epoch(<a name="0042-LIQF-094" href="#0042-LIQF-094">0042-LIQF-094</a>)

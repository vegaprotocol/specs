# Liquidity Provisioning Order Type

## Summary

When market makers commit to providing liquidity they are required to submit a set of valid buy shapes and sell shapes [Liquidity Provisioning mechanics](./0044-LIME-lp_mechanics.md). This commitment will ensure that they are eligible for portion of the market fees as set out in [Setting Fees and Rewarding Market Makers](./0042-LIQF-setting_fees_and_rewarding_lps.md).

## Liquidity Provisioning order features

LP orders are a special order type with the following features:

- Is a batch order: allows simultaneously specifying multiple orders in one message/transaction
- Initially all are pegged orders but other price types may be available in future
- Are always priced limit orders that sit on the book
- Are “post only” and do not trade on entry (as per normal pegged orders)
- The order is always refreshed after it trades (once the tx is processed so not refreshed before closeouts, etc.) based on the above requirements so that the full commitment is always supplied.

## How they are submitted

2 x shapes are submitted as part of a market making transaction (one for buy side, one for sell side). Each entry in this shape must specify a proportion of the liquidity obligation applicable to that entry and a price peg.

The network will translate these shapes into order book volume by creating an order set according to a set of rules (see below).

Each entry must specify:

1. **Liquidity proportion:** the relative proportion of the commitment to be allocated at a price level. Note, the network will normalise the liquidity proportions of the refined order set (see below). This must be a strictly positive number.

2. A **price peg:** , as per normal [pegged orders](../protocol/0037-OPEG-pegged_orders.md), a price level specified by a reference point (e.g mid, best bid, best offer) and an amount of units away. The amount is always positive and is subtracted for buy orders and added for sell orders to the reference price.

```proto
# Example 1:
Buy-shape: {
  buy-entry-1: [buy-liquidity-proportion-1, [buy-price-peg-reference-1, buy-number-of-units-from-reference-1]],
  buy-entry-2: [buy-liquidity-proportion-2, [buy-price-peg-reference-2, buy-number-of-units-from-reference-2]],
}
Sell-shape: {
  sell-entry-1: [sell-liquidity-proportion-1, [sell-price-peg-reference-1, sell-number-of-units-from-reference-1]],
  sell-entry-2: [sell-liquidity-proportion-2, [sell-price-peg-reference-2, sell-number-of-units-from-reference-2]],
}

# Example 1 with values
Buy-shape: {
  buy-entry-1: [2, [best-bid, 10]],
  buy-entry-2: [13, [best-bid, 11]],
}
Sell-shape: {
  sell-entry-1: [5, [best-ask, 8]],
  sell-entry-2: [5, [best-ask, 9]],
}

```

## How they are constructed for the order book

Input data:

1. The commitment, buy-shape, sell-shape (as submitted in the [liquidity provision network transaction](./0038-OLIQ-liquidity_provision_order_type.md).)
1. Any persistent orders that the liquidity provider has on the book at a point in time.

### Refining list of orders

Steps:

1. From the market parameter - to be set as part of [market proposal](0028-GOVE-governance.md)  `market.liquidity.priceRange` which is a percentage price move (e.g. `0.05 = 5%` and from `mid_price` calculate:

`min_lp_price = (1.0 - market.liquidity.priceRange) x mid_price`

and

`max_lp_price = (1.0 + market.liquidity.priceRange) x mid_price`

1. Calculate `liquidity_obligation`, as per calculation in the [market making mechanics spec](./0044-LIME-lp_mechanics.md).

1. The `liquidity_obligation` calculated as per [LP mechanics](0044-LIME-lp_mechanics.md). Some of it may be fulfilled by persistent orders the liquidity provider has on the book at this point in time that are between and including `min_lp_vol_price` and `max_lp_vol_price`.
The contribution is `volume x price`; sum up the contribution across the relevant side of the book and subtract it from `liquidity_obligation` obtained above.
If you end up with 0 or a negative number, stop, you are done.

1. Using the adjusted `liquidity_obligation`, calculate the `liquidity-normalised-proportion` for each of the remaining entries in the buy / sell shape (for clarity, this does not include any other persistent orders that the market maker has).

1. Calculate the volume implied by each entry in the refined buy/sell order list. You will now create orders from this volume at the relevant price point and apply them to the order book.

#### Normalising liquidity proportions for a set of market making orders (step 3)

Calculate the `liquidity-normalised-proportion` for all entries, where for buy and sell side separately:

`liquidity-normalised-proportion = liquidity-proportion-for-entry / sum-all-entries(liquidity-proportion-for-order)`

```math
Example 1 (from above) where refined-order-list = [buy-entry-1, buy-entry-2, sell-entry-1, sell-entry-2]:

liquidity-normalised-proportion-buy-order-1 = 2 / (2 + 13) = 0.13333...
liquidity-normalised-proportion-buy-order-2 = 13 / (2 + 13) = 0.86666...
liquidity-normalised-proportion-sell-order-1 = 5 / (5 + 5) = 0.5
liquidity-normalised-proportion-sell-order-2 = 5 / (5 + 5) = 0.5

```

The sum of all normalised proportions must = 1 on each side.

#### Calculating volumes for a set of market making orders (step 6)

Any shape entry with a peg less than `min_lp_vol_price` should have the resulting volume implied at `min_lp_vol_price` (instead of what level the peg would be) while any shape entry with peg greater than `max_lp_vol_price` should have the resulting volume implied at `max_lp_vol_price`.

Calculate the volume at the peg as

`volume = ceiling(liquidity_obligation x liquidity-normalised-proportion / price)`.

where `liquidity_obligation` is calculated as defined in the [market making mechanics spec](./0044-LIME-lp_mechanics.md) and `price` is the price level at which the `volume` will be placed.
At this point `volume` may have decimal places.

Note: if the resulting quote price of any of the entries in the buy / sell shape leads to negative product value from the [product quote-to-value function](0051-PROD-product.md#quote-to-value-function) but strictly positive volume then the entire LP order for this LP is undeployed, their stake won't count towards target stake being met and they shall not receive any LP fees regardless of their equity-like share. This can lead to a [liquidity auction](0035-LIQM-liquidity_monitoring.md) if the supplied stake for the market is below the required level due to this LP.

Note: calculating the order volumes needs take into account Position Decimal Places and create values (which may be int64s or similar) that are the correct size and precision given the number of Position Decimal Places specified in the [Market Framework](./0001-MKTF-market_framework.md).
This means that the `integerVolume = ceil(volume x 10^(PDP))`.
For example, if the offset, commitment and prob of trading imply volume of say `0.65` then the `integerVolume` we want to see on the book depends on position decimals. If we have:

- `0dp` then round up to volume `1`
- `1dp` then round up to volume `7` (i.e. `0.7` i.e. `1dp`).
- `3dp` then no need for any rounding it's `650` (i.e. `0.650`)

and so on.

```proto
Example:

best-static-bid-on-order-book = 103

shape-entry = {
  peg: {reference: 'best-bid', units-from-ref: 2},
  liquidity-normalised-proportion-order: 0.32
}

peg-implied-price = 103 - 2 = 101

Call probability-of-trading function with best-static-bid-on-order-book = 105, time-horizon given by risk model tau multiplied by  `market.liquidity.probabilityOfTrading.tau.scaling`, peg-implied-price.

This will return probably of trading at price = 101. This can be used in the formula for volume, above.

```

## Refreshing of orders / recalculating order volume

Liquidity provider orders are recalculated and refreshed whenever an order that is part of the commitment has changed, including if a market maker's order(s) have traded (both persistent orders and shape implied orders), orders are amended, cancelled, or expired.

In these cases, repeat all steps above, preserving the order as an order, but recalculating the volume and price of it. Note, this should only happen at the end of a transaction (that caused the trade), not immediately following the trade itself.

### Time priority for refreshing

1. For all orders that are repriced but not as a result of trading (i.e. pegged orders that move as a result of peg moving), treat as per normal pegged orders.

1. The system should refresh the liquidity provider's pegged orders, in time priority according to which traded first (see below example).

________________________
**Example**: we have a buy side of an order book that looks like this:

```proto
{
 [mm-1-order, buy-volume=3, buy-price=100, order-time=13007]
 [mm-2-order, buy-volume=5, buy-price=99, order-time=13004]
}
```

and a new market order sells 8. Then, a plausible refreshed set of orders could look like this*:

```proto
add this first
 [mm-1-order, buy-volume=3, buy-price=97, order-time=16458]

and then this
 [mm-2-order, buy-volume=5, buy-price=96, order-time=16459]
```

*Note: the actual values of the buy-prices and buy-volumes are dependent on the result of step 2 above and this example is not to test that, so don't try to replicate this with numbers, it's for illustrative purposes only.
________________________

### Transfers in / out of margin account

When the system refreshes orders (because a peg moved) and the implied volumes now sit at different price levels there may be different overall margin requirement for the LP party.
If the resulting amount is outside search / release then there will be *at most* one transfer in / out of the party's margin account for the entire LP order.

## Amending the LP order

Liquidity providers are always allowed to amend their shape generated orders by submitting a new liquidity provider order with a set of revised order shapes (see [Liquidity Provisioning mechanics](./0044-LIME-lp_mechanics.md)). They are not able to amend orders using "normal" amend orders.

No cancellation of orders that arise from this LP batch order type other than by lowering commitment as per [[Liquidity Provisioning mechanics spec](./0044-LIME-lp_mechanics.md).

Note that any other orders that the LP has on the book (limit orders, other pegged orders) that are *not* part of this LP batch order (call them "normal" in this paragraph) can be cancelled and amended as normal. When volume is removed / added / pegs moved (on "normal" orders) then as part of the normal peg updates the LP batch order may add or remove volume as described in section "How they are constructed for the order book" above.

## Network Parameters

- `market.liquidity.probabilityOfTrading.tau.scaling`: scaling factor multiplying risk model value of tau to imply probability of trading.
- `market.liquidity.minimum.probabilityOfTrading.lpOrders`: a minimum probability of trading; any shape proportions at pegs that would have smaller probability of trading are to be moved to pegs that imply price that have probability of trading no less than the `market.liquidity.minimum.probabilityOfTrading.lpOrders`.

## APIs

- Order datatype for LP orders. Any order APIs should contain these orders.

## Acceptance Criteria

- Volume implied by the liquidity provision order is that given by [0034-PROB-liquidity_measure.feature](https://github.com/vegaprotocol/vega/blob/develop/core/integration/features/verified/0034-PROB-liquidity_measure.feature) in all the various scenarios there. (<a name="0038-OLIQ-001" href="#0038-OLIQ-001">0038-OLIQ-001</a>);
- Volume implied by the liquidity provision order is that given by [0034-PROB-liquidity_measure.feature](https://github.com/vegaprotocol/vega/blob/develop/core/integration/features/verified/0034-PROB-liquidity_measure.feature) in all the various scenarios that test fractional order sizes (smallest order position of 0.01). (<a name="0038-OLIQ-002" href="#0038-OLIQ-002">0038-OLIQ-002</a>);
- If an LP order has offset set such that the resulting price falls outside `[min_lp_vol_price, max_lp_vol_price]` then the system adjusts it automatically so that it's placed on the bound (<a name="0038-OLIQ-011" href="#0038-OLIQ-011">0038-OLIQ-011</a>)

### LP commitment order creation

- A liquidity provisioning order must specify orders for both sides of the book (<a name="0038-OLIQ-003" href="#0038-OLIQ-003">0038-OLIQ-003</a>)
- All orders created by an LP commitment must be pegged orders (<a name="0038-OLIQ-004" href="#0038-OLIQ-004">0038-OLIQ-004</a>)
- Filled orders are replaced immediately to conform to the LP commitment shapes (<a name="0038-OLIQ-005" href="#0038-OLIQ-005">0038-OLIQ-005</a>)
- Change of the market parameter `market.liquidity.priceRange` which decreases the value will, when volumes are next recalculated, tighten `[min_lp_vol_price, max_lp_vol_price]` and volume that was previously pegged inside the valid range and would now be outside is shifted to the bounds.   (<a name="0038-OLIQ-012" href="#0038-OLIQ-012">0038-OLIQ-012</a>)
- Change of the market parameter `market.liquidity.priceRange` which increases the value will, when volumes are next recalculated, widen `[min_lp_vol_price, max_lp_vol_price]` and volume that was previously being shifted to stay inside the range is now deployed at the desired peg.   (<a name="0038-OLIQ-013" href="#0038-OLIQ-013">0038-OLIQ-013</a>)

### LP commitment amendment

- If amending a commitment size would reduce the market's supplied liquidity below the target stake, the amendment will be rejected (see [0035 Liquidity Monitoring](./0035-LIQM-liquidity_monitoring.md#decreasing-supplied-stake)) (<a name="0038-OLIQ-006" href="#0038-OLIQ-006">0038-OLIQ-006</a>)

### LP commitment repricing due to peg price moves

- If best bid / ask has changed and the LP order volume is moved around to match the shape / new peg levels then the margin requirement for the party may change. There is at most one transfer in / out of the margin account of the LP party as a result of one of the pegs moving. (<a name="0038-OLIQ-008" href="#0038-OLIQ-008">0038-OLIQ-008</a>)

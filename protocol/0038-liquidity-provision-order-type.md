# Liquidity Provisioning Order Type

## Summary 

When market makers commit to providing liquidity they are required to submit a set of valid buy shapes and sell shapes [Liquidity Provisioning mechanics](./0044-lp-mechanics.md). This commitment will ensure that they are eligible for portion of the market fees as set out in [Setting Fees and Rewarding MMs](./0042-setting-fees-and-rewarding-lps.md).


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

2. A **price peg:** , as per normal [pegged orders](./0037-pegged-orders.md), a price level specified by a reference point (e.g mid, best bid, best offer) and an amount of units away. 

```
# Example 1:
Buy-shape: {
  buy-entry-1: [liquidity-proportion-1, [price-peg-reference-1, number-of-units-from-reference-1]],
  buy-entry-2: [liquidity-proportion-2, [price-peg-reference-2, number-of-units-from-reference-2]],
}

# Example 1 with values
Buy-shape: {
  buy-entry-1: [2, [best-bid, -10]],
  buy-entry-2: [13, [best-bid, -11]],
}

```

## How they are constructed for the order book

Input data:
1. The commitment, buy-shape, sell-shape (as submitted in the [liquidity provision network transaction](./0044-lp-mechanics.md).) 
1. Any persistent orders that the liquidity provider has on the book at a point in time.

### Refining list of orders

Steps:

1. Calculate `liquidity_obligation`, as per calculation in the [market making mechanics spec](./0044-lp-mechanics.md).

1. Subtract from the value obtained from step-1 the amount of the `liquidity_obligation` that is being fulfilled by any persistent orders the liquidity provider has on the book at this point in time according to the probability weighted liquidity measure (see [spec](./0034-prob-weighted-liquidity-measure.ipynb)). If you end up with 0 or a negative number, stop, you are done. 
Note that the book `mid-price` must be used when calculating the probability weighted liquidity measure. 

1. Using the adjusted `liquidity_obligation`, calculate the `liquidity-normalised-proportion` for each of the remaining entries in the buy / sell shape (for clarity, this does not include any other persistent orders that the market maker has).

1. Calculate the volume implied by each entry in the refined buy/sell order list. You will now create orders from this volume at the relevant price point and apply them to the order book. 


#### Normalising liquidity proportions for a set of market making orders (step 3):

Calculate the `liquidity-normalised-proportion` for all entries, where:

`liquidity-normalised-proportion = liquidity-proportion-for-entry / sum-all-buy/sell-entries(liquidity-proportion-for-order)`

```
Example 1 (from above) where refined-buy-order-list = [buy-entry-1, buy-entry-2]:

liquidity-normalised-proportion-order-1 = 2 / (2 + 13) = 0.133333
liquidity-normalised-proportion-order-2 = 13 / (2 + 13) = 0.866666

```
The sum of all normalised proportions must = 1 for all refined buy / sell order list.

#### Calculating volumes for a set of market making orders (step 6):

From the network parameter `minimum-prob-of-trading-for-LP-orders` and from `best static bid-price` we get `minPrice` from the [Quant risk model spec](0018-quant-risk-models.ipynb): the smallest price level that has probability of trading greater than or equal to `minimum-prob-of-trading-for-LP-orders`. 
Similarly from `best static ask-price` we get `maxPrice`: the largest price level that has probability of trading greater than or equal to `minimum-prob-of-trading-for-LP-orders`. 
Any shape entry with a peg less than `minPrice` should have the resulting volume implied at `minPrice` (instead of what the level the peg would be) while any shape entry with peg greater than `maxPrice` should have the resulting volume implied at `maxPrice`. 

Given the price peg information (`peg-reference`, `number-of-units-from-reference`) and  `liquidity-normalised-proportion` we obtain the `probability_of_trading` at the resulting order price, from the risk model, see [Quant risk model spec](0018-quant-risk-models.ipynb). 
Use `best static bid-price` or `best static ask-price` depending on which side of the book the orders are when getting the probability of trading from the risk model. 
Note that for volume pegged between best static bid and best static ask the probability of trading is `1` as per [Quant risk model spec](0018-quant-risk-models.ipynb).

``` volume = ceiling(liquidity_obligation x liquidity-normalised-proportion / probability_of_trading / price)```. 

where `liquidity_obligation` is calculated as defined in the [market making mechanics spec](./0044-lp-mechanics.md) and `price` is the price level at which the `volume` will be placed.

Note: if the resulting price for any of the entries in the buy / sell shape is outside the valid price range as provided by the price monitoring module (the min/max price that would not trigger the price monitoring auction per triggers configured in the market, see [price monitoring](./0032-price-monitoring.md#view-from-quanthttpsgithubcomvegaprotocolquant-library-side) spec for details) it should get shifted to the valid price that's furthest away from the mid for the given order-book side.

Note: calculating the order volumes needs take into account Position Decimal Places and create values (which may be int64s or similar) that are the correct size and precision given the number of Position Decimal Places specified in the [Market Framework](0001-market-framework.md).


```
Example: 

best-static-bid-on-order-book = 103

shape-entry = {
  peg: {reference: 'best-bid', units-from-ref: -2}, 
  liquidity-normalised-proportion-order: 0.32
}

peg-implied-price = 103 - 2 = 101

Call probability-of-trading function with best-static-bid-on-order-book = 105, LP-time-horizon (network parameter), peg-implied-price. 

This will return probably of trading at price = 101. This can be used in the formula for volume, above.

```

## Refreshing of orders / recalculating order volume

Liquidity provider orders are recalculated and refreshed whenever an order that is part of the commitment has changed, including if a market maker's order(s) have traded (both persistent orders and shape implied orders), orders are amended, cancelled, or expired.

In these cases, repeat all steps above, preserving the order as an order, but recalculating the volume and price of it. Note, this should only happen at the end of a transaction (that caused the trade), not immediately following the trade itself. 

TIME PRIORITY FOR REFRESHING:

1. For all orders that are repriced but not as a result of trading (i.e. pegged orders that move as a result of peg moving), treat as per normal pegged orders.

1. The system should refresh the liquidity provider's pegged orders, in time priority according to which traded first (see below example).

________________________
**Example**: we have a buy side of an order book that looks like this:
```
{
 [mm-1-order, buy-volume=3, buy-price=100, order-time=13007]
 [mm-2-order, buy-volume=5, buy-price=99, order-time=13004]
}
```
and a new market order sells 8. Then, a plausible refreshed set of orders could look like this*:

```
add this first
 [mm-1-order, buy-volume=3, buy-price=97, order-time=16458]

and then this
 [mm-2-order, buy-volume=5, buy-price=96, order-time=16459]
```

*NB the actual values of the buy-prices and buy-volumes are dependent on the result of step 2 above and this example is not to test that, so don't try to replicate this with numbers, it's for illustrative purposes only.
________________________

## Amending the LP order:

Liquidity providers are always allowed to amend their shape generated orders by submitting a new liquidity provider order with a set of revised order shapes (see [Liquidity Provisioning mechanics](./0044-lp-mechanics.md)). They are not able to amend orders using "normal" amend orders.

No cancellation of orders that arise from this LP batch order type other than by lowering commitment as per [[Liquidity Provisioning mechanics spec](./0044-lp-mechanics.md).

Note that any other orders that the LP has on the book (limit orders, other pegged orders) that are *not* part of this LP batch order (call them "normal" in this paragraph) can be cancelled and amended as normal. When volume is removed / added / pegs moved (on "normal" orders) then as part of the normal peg updates the LP batch order may add or remove volume as described in section "How they are constructed for the order book" above.


## Network Parameters:
* mm-time-horizon: market making time horizon to imply probability of trading.
* minimum-prob-of-trading-for-LP-orders: a minimum probability of trading; any shape proportions at pegs that would have smaller probability of trading are to be moved to pegs that imply price that have probability of trading no less than the minimum-prob-of-trading-for-LP-orders. Reasonable value `1e-8`. For validation purposes the minimum value is `1e-15` and maximum value is `0.1`. 

## APIs:
* Order datatype for LP orders. Any order APIs should contain these orders.

## Acceptance Criteria:
- [ ] The volume generated on the book matches examples produced from https://github.com/vegaprotocol/sim/notebooks/fee_margin_examples.ipynb

### LP commitment order creation
- [ ] A liquidity provisioning order must specify orders for both sides of the book
- [x] All orders created by an LP commitment must be pegged orders
- [x] Filled orders are replaced immediately to confirm to the LP commitment shapes

### LP commitment amendment
- [x] If amending a commitment size would reduce the market's supplied liquidity below the target stake, the amendment will be rejected (see [0035 Liquidity Monitoring](0035-liquidity-monitoring.md#decreasing-supplied-stake))

### LP commitment fees
See [Setting fees and rewarding LPs](./0042-setting-fees-and-rewarding-lps.md)

### LP commitment at market creation
See [Governance spec](./0028-governance.md)

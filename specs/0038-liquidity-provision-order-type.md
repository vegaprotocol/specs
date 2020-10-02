# Market Making Order Type

## Summary 

When market makers commit to providing liquidity they are required to submit a set of valid buy shapes and sell shapes [market making mechanics](./0044-lp-mechanics.md). This commitment will ensure that they are eligible for portion of the market fees as set out in [Setting Fees and Rewarding MMs](./0042-setting-fees-and-rewarding-lps.md).


## Market making order features

Market maker orders are a special order type with the following features:
- Is a batch order: allows simultaneously specifying multiple orders in one message/transaction
- Initially all are pegged orders but other price types may be available in future
- Are always priced limit orders that sit on the book
- Are “post only” and do not trade on entry (as per normal pegged orders)
- The order is always refreshed after it trades (once the tx is processed so not refreshed before closeouts, etc.) based on the above requirements so that the full commitment is always supplied.


## How they are submitted

2 x shapes are submitted as part of a market making transaction (one for buy side, one for sell side). Each entry in this shape must specify a proportion of the liquidity obligation applicable to that entry and a price peg.

The network will translate these shapes into order book volume by creating an order set according to a set of rules (see below).

Each entry must specify:

1. **Liquidity proportion:** the relative proportion of the commitment to be allocated at a price level. Note, the network will normalise the liquidity proportions of the refined order set (see below). This must be strictly positive number.

2. A **price peg:** , as per normal [pegged orders](), a price level specified by a reference point (e.g mid, best bid, best offer) and an amount of units away. 

```
# Example 1:
Buy-shape: {
  buy-entry-1: [liquidity-proportion-1, [price-peg-reference-1, number-of-units-from-reference-1]],
  buy-entry-2: [liquidity-proportion-2, [price-peg-reference-2, number-of-units-from-reference-2]],
}

# Example 1 with values
Buy-shape: {
  buy-entry-1: [2, [best-offer, -10]],
  buy-entry-2: [13, [price-peg-reference-2, number-of-units-from-reference-2]],
}

```

## How they are constructed for the order book

Input data:
1. The commitment, buy-shape, sell-shape (as submitted in the [liquidity provision network transaction](./0044-lp-mechanics.md).) 
1. Any limit orders that the market maker has on the book at a point in time.

### Refining list of orders

Steps:

1. Calculate `liquidity_obligation`, as per calculation in the [market making mechanics spec](./0044-lp-mechanics.md).

1. Subtract the value obtained from step-1 the amount of the `liquidity_obligation` that is being fulfilled by any limit orders the market maker has on the book at this point in time according to the probability weighted liquidity measure (see [spec](0034-prob-weighted-liqudity-measure.ipynb)). If you end up with 0 or negative number, stop, you are done.

1. Using the adjusted `liquidity_obligation`, calculate the `liquidity-normalised-proportion` for each of the remaining entries in the buy / sell shape (for clarity, this does not include any other limit orders that the market maker has).

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

Given the price peg information (`peg-reference`, `number-of-units-from-reference`) and  `liquidity-normalised-proportion` we obtain the `probability_of_trading` at the resulting order price, from the risk model, see [Quant risk model spec](0018-quant-risk-models.ipynb). Note, if the peg reference is not the `mid-price`, then first calculate the distance from mid price.

``` volume = ceiling(liquidity_obligation x liquidity-normalised-proportion / probability_of_trading)```. 

where `liquidity_obligation` is calculated as defined in the [market making mechanics spec](./0044-lp-mechanics.md).

```
Example: 

best-bid-on-order-book = 103

shape-entry = {
  peg: {reference: 'best-bid', units-from-ref: 2}, 
  liquidity-normalised-proportion-order: 0.32
}

peg-implied-price = 103 - 2 = 101

mid-price-from-order-book = 105

Call probability-of-trading function with current-price = 105, mm-time-horizon (network parameter), peg-implied-price. This will give probably of trading at price = 101. This can be used in the formula for volume, above.

```

## Refreshing of orders / recalculating order volume

Market maker orders are recalculated and refreshed during a normal peg reprice when the order book status has changed, including if a market maker's order(s) have traded (both limit orders and shape implied orders).

In both cases, repeat all steps above, preserving the order as an order, but recalculating the volume and price of it. Note, this should only happen at the end of a transaction (that caused the trade), not immediately following the trade itself. 

TIME PRIORITY FOR REFRESHING:

1. For all orders that are repriced but not as a result of trading (i.e. pegged orders that move as a result of peg moving), treat as per normal pegged orders.

1. The system should refresh the market maker pegged orders, in time priority according to which traded first (see below example).

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

## Amending the MM order:

Market makers are always allowed to amend their orders by submitting a market maker network transaction with a set of revised order shapes (see [market making mechanics spec](./0000-mm-mechanics.md)). They are not able to amend orders using "normal" amend orders.

No cancellation of orders other than by lowering commitment as per [market making mechanics spec](./0000-mm-mechanics.md)


## Network Parameters:
* mm-time-horizon: market making time horizon to imply probability of trading.

## APIs:
* Order datatype for market maker orders. Any order APIs should contain these orders.

## Acceptance Criteria:
- [ ] The volume generated on the book matches examples produced from https://github.com/vegaprotocol/sim/notebooks/fee_margin_examples.ipynb

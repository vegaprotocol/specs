# Market Making Order Type

## Summary 

When market makers commit to providing liquidity they are required to submit a set of valid buy orders and sell orders [market making mechanics](????-mm-mechanics.md). This commitment will ensure that they are eligible for portion of the market fees as set out in [Setting Fees and Rewarding MMs](????-setting-fees-and-rewarding-mms.md).


## Market making order features

Market maker orders are a special order type with the following features:
- Is a batch order: allows simultaneously specifying multiple orders in one message/transaction
- Initially all are pegged orders but other price types may be available in future
- Are always priced limit orders that sit on the book
- Are “post only” and do not trade on entry (as per normal pegged orders)
- The order is always refreshed after it trades (once the tx is processed so not refreshed before closeouts, etc.) based on the above requirements so that the full commitment is always supplied.


## How they are submitted

2 x batch orders are submitted as part of a market making transaction (one for buy side, one for sell side). Each order must specify the proportion of its liquidity applicable to that order and a price peg.

The network will translate these orders into order book volume by refining the order set according to a set of logic directives (see below)

Each order must specify:

1. **Liquidity proportion:** the relative proportion of the commitment to be allocated at a price level. Note, the network will normalise the liquidity proportions of the refined order set (see below).

2. A **price peg:** , as per normal [pegged orders](), the price level specified by a reference point (e.g mid, best bid, best offer) and an amount of units away. These orders work the same as a usual peg order, except that size is calculated from the liquidity proportions.

```
# Example 1:
Buy-batch-orders: {
  buy-order-1: [liquidity-proportion-1, [price-peg-reference-1, number-of-units-from-reference-1]],
  buy-order-2: [liquidity-proportion-2, [price-peg-reference-2, number-of-units-from-reference-2]],
}

# Example 1 with values
Buy-batch-orders: {
  buy-order-1: [2, [best-offer, -10]],
  buy-order-2: [13, [price-peg-reference-2, number-of-units-from-reference-2]],
}

```

## How they are constructed for the order book

### Refining list of orders

Market makers may post 
- remove any that would trade on entry.
- 
- calculate the normalised volume with this filtered list.

1. Subtract limit orders from your liquidity obligations on each side. Subtract the siskas implied by your limit orders from your obligation.

_Example: ADD_

2. If any of the orders submitted would result in a trade, they are excluded from the valid list of market making orders.

_Example: ADD_

Resulting List:

### Calculating volume / size

Once a final valid list of orders is ascertained, we must undertake the following steps:

1. Calculate the `liquidity-normalised-proportion` for all valid orders, where:

`liquidity-normalised-proportion = liquidity-proportion-for-order / sum-all-buy/sell-orders(liquidity-proportion-for-order)`

```
Example 1 (from above) where refined-buy-order-list = [buy-order-1, buy-order-2]:

liquidity-normalised-proportion-order-1 = 2 / (2 + 13) = 0.133333
liquidity-normalised-proportion-order-2 = 13 / (2 + 13) = 0.866666

```

The sum of all normalised proportions must = 1 for all refined buy / sell order list.

2. Calculate the volumes of each order in the refined buy/sell order list:

Given the price peg information (`peg-reference`, `number-of-units-from-reference`) and  `liquidity-normalised-proportion` we obtain the `probability_of_trading` at the resulting order price, from the risk model, see [Quant risk model spec](0018-quant-risk-models.ipynb). 

``` volume = liquidity_obligation x liquidity-normalised-proportion / probability_of_trading```. 

where `liquidity_obligation` is calculated as defined in the [market making mechanics spec](????-mm-mechanics.md).

```
Example: 

Order = {
  peg: {reference: 'best-bid', units-from-ref: 2}, 
  liquidity-normalised-proportion-order: 0.32
}

mid-price = 105


```

## Refreshing of orders

Each market maker's orders will refresh after trading. These should be refreshed 

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
 [mm-1-order, buy-volume=3, buy-price=97, order-time=16458]
 [mm-2-order, buy-volume=5, buy-price=96, order-time=16459]
```

The system should refresh the market maker pegged orders, in time priority according to which traded first. 

*NB the actual values of the buy-prices and buy-volumes are dependent on the result of step 2 above and this example is not to test that, so don't try to replicate this with numbers, it's for illustrative purposes only.
________________________


### Recalculating order volume during peg reprice

1. Order book status has changed: 
2. A market maker's order(s) have traded: 

In both cases, the pegged orders prices are recalculated. As a special case for market maker orders, the volume of the order is also recalculated based on the formula above.

Note on time priority: for all orders that are repriced but not as a result of trading (i.e. pegged orders that move as a result of peg moving), should be given new time priority that preserves their relative ordering (to each other) as per the ordering implied from their time priority prior to the refreshing.



- 


## Adding MM orders to the book:

The set of buy orders are applied to the resulting order price and volume. In the case that there are multiple market makers

## Amending the MM order:

Market makers are always allowed to amend their orders by submitting a market maker network transaction with a set of revised orders (see [market making mechanics spec](./0000-mm-mechanics.md))


## Acceptance Criteria:
# Market Making Order Type

## Summary 

When market makers commit to providing liquidity they are required to submit a set of valid buy orders and sell orders [market making mechanics](????-mm-mechanics.md). This commitment will ensure that they are eligible for portion of the market fees as set out in [Setting Fees and Rewarding MMs](????-setting-fees-and-rewarding-mms.md).


## Market making order features

Market maker orders are a special order type with the following features:
- Is a batch order: allows simultaneously specifying multiple orders in one message/transaction
- Initially all are pegged orders but other price types may be available in future
- Are always priced limit orders that sit on the book
- Are “post only” and do not trade on entry
- The order is always refreshed after trading (once the tx is processed so not refreshed before closeouts, etc.) based on the above requirements so that the full commitment is always supplied (spec coming) 

## Market making order data

_Market maker orders submitted:_

2 x batch orders are submitted as part of a market making transaction (one for buy side, one for sell side). Each order must specify the proportion of its liquidity applicable to that order and then either the price peg or the order size.

### INPUT DATA ###

**Liquidity proportion:** the relative proportion of the commitment to be allocated at a price level. Note, the network will normalise these liquidity proportions by:

`liquidity-normalised-proportion = liquidity-proportion-for-order / sum-all-buy/sell-orders(liquidity-proportion-for-order)`

***PLUS EITHER:***

**Price peg:** the price level specified by a reference point (e.g mid, best bid, best offer) and an amount of units away (initially we offer this specified in ticks. In future this could be specified as a % or number of standard deviations as per risk model distribution).

***OR***

**Size:** the size of the order at the given price

```
# Example 1:
Buy-batch-orders: {
  buy-order-1: [liquidity-proportion-1, [price-peg-reference-1, number-of-units-from-reference-1]],
  buy-order-2: [[price-peg-reference-2, number-of-units-from-reference-2], size-of-order-at-price],
  buy-order-3: [liquidity-proportion-3, [price-peg-reference-3, number-of-units-from-reference-3]],
}

# Example 1 with values
Buy-batch-orders: {
  buy-order-1: [2, [best-offer, -10]],
  buy-order-2: [[best-offer, -12], 100],
  buy-order-3: [4, [price-peg-reference-3, number-of-units-from-reference-3]],
}

```

### CALCULATED ORDERS FOR ORDER BOOK ### 

The network calculates either the price-peg or the size of the order, depending on which field is missing. If both fields are provided, the price-peg takes precedence and the size of the order isn't used.

*Calculating the price peg when size is provided:*



*Calculating size when price peg is provided:*

Given the price peg information (`price-peg-reference`, `number-of-units-from-reference`) and  `liquidity-normalised-proportion` we obtain the `probability_of_trading` at the resulting order price, from the risk model, see [Quant risk model spec](0018-quant-risk-models.ipynb). 

The volume implied by the order at that distance from mid price is then 

``` volume = liquidity_obligation x liquidity-normalised-proportion / probability_of_trading```. 

## Adding MM orders to the book:

The set of buy orders are applied to the resulting order price and volume.

## Amending the MM order:

Market makers are always allowed to amend their orders by submitting a market maker network transaction with a set of revised orders (see [market making mechanics spec](./0000-mm-mechanics.md))
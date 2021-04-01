Feature name: Mark Price
# Summary
A *Mark Price* is a concept derived from traditional markets.  It is a calculated value for the 'current market price' on a market.

# Acceptance criteria

- [ ] The algorithm used to calculate the mark price is specified by a market parameter.
- [ ] The mark price must be non zero when the market opens


Algorithm 1:

- [ ] Any transaction that results in one or more trades causes the mark price to change to the value of the last trade and only the last trade.
- [ ] A transaction that doesn't result in a trade does not cause the mark price to change.
- [ ] The initial mark price for a market is specified by a market parameter.

# Guide-level explanation
The *Mark Price* represents the "current" market value for an instrument that is being traded on a market on Vega. It is a calculated value primarily used to value trader's open portfolios against the prices they executed their trades at. Specifically, it is used to calculate the cash flows for [mark-to-market settlement](./0003-mark-to-market-settlement.md).

Note that a mark price may not be a true "price" in the financial sense of the word, i.e. if the `price` changes by `X` then the value of a position does not necessarily change by `X * position size`, instead, the product's quote-to-value function must be used to ascertain the change, i.e. `change_in_value == product.value(new_mark_price) - product.value(old_mark_price)`.


# Reference-level explanation

The mark price is instantiated at a non-zero level when a market opens, for instance via the [opening auction](./0026-auctions.md).

It will subsequently be calculated according to a methodology selected from a suite of algorithms. The selection of the algorithm for calculating the *Mark Price* is specified at the "market" level as a market parameter.

Mark price can also be adjusted by [product lifecycle events](0051-product.md), in which case the mark price set by the product remains the mark price until it is next recalculated (e.g. if the methodology is last traded price, until there is a new trade).


## Usage of the *Mark Price*:
The most recently calculated *Mark Price* is used in the [mark-to-market settlement](./0003-mark-to-market-settlement.md).  A change in the *Mark Price* is one of the triggers for the mark-to-market settlement to run.


## Algorithms for calculating the *Mark Price*:

 ### 1. Last Traded Price 
 The mark price for the instrument is set to the last trade price in the market following processing of each transaction i.e. submit/amend/delete order.
 
 >*Example:* consider if the mark price was previously $900. If a buy market order is placed for +100 that results in 3 trades; 50 @ $1000, 25 @ $1100 and 25 @ $1200, the mark price changes **once** to a new value of $1200.

 ### 2. Last Traded Price + Order Book 
The mark price is set to the higher / lower of the last traded price, bid/offer.

>*Example a):* consider the last traded price was $1000 and the current best bid in the market is $1,100. The bid price is higher than the last traded price so the new Mark Price is $1,100. 

>*Example b):* consider the last traded price was $1000 and the current best bid in the market is $999. The last traded price is higher than the bid price so the new Mark Price is $1,000. 

 ### 3. Oracle 
 An oracle source external to the market provides updates to the Mark Price. See the [data sourcing spec](./0045-data-sourcing.md).

 ### 4. Model 
 The *Mark Price* may be calculated using a built in model.  
 
 >*Example:* An option price will theoretically decay with time even if the market's order book or trade history does not reflect this.

 ### 5. Defined as part of the product
  The *Mark Price* may be calculated using an algorithm defined by the product -- and 'selected' by a market parameter.
# Mark Price

## Summary

A *Mark Price* is a concept derived from traditional markets.  It is a calculated value for the 'current market price' on a market.

Introduce a network parameter `network.markPriceUpdateMaximumFrequency` with minimum allowable value of `0s` maximum allowable value of `1h` and a default of `5s`.

## Acceptance criteria

- The mark price must be set when the market leaves opening auction. (<a name="0009-MRKP-002" href="#0009-MRKP-002">0009-MRKP-002</a>)
- Each time the mark price changes the market data event containing the new mark price should be emitted. Specifically, the mark price set after leaving each auction, every interim mark price as well as the mark price based on last trade used at market termination and the one based on oracle data used for final settlement should all be observable from market data events. (<a name="0009-MRKP-009" href="#0009-MRKP-009">0009-MRKP-009</a>)

Algorithm 1:

- If `network.markPriceUpdateMaximumFrequency=0s` then any transaction that results in one or more trades causes the mark price to change to the value of the last trade and only the last trade. (<a name="0009-MRKP-003" href="#0009-MRKP-003">0009-MRKP-003</a>)
- If `network.markPriceUpdateMaximumFrequency>0` then out of a sequence of transactions with the same time-stamp the last transaction that results in one or more trades causes the mark price to change to the value of the last trade and only the last trade but only provided that at least `network.markPriceUpdateMaximumFrequency` has elapsed since the last update. (<a name="0009-MRKP-007" href="#0009-MRKP-007">0009-MRKP-007</a>)
- A transaction that doesn't result in a trade does not cause the mark price to change. (<a name="0009-MRKP-004" href="#0009-MRKP-004">0009-MRKP-004</a>)
- A transaction out of a sequence of transactions with the same time stamp which isn't the last trade-causing transaction will *not* result in a mark price change. (<a name="0009-MRKP-008" href="#0009-MRKP-008">0009-MRKP-008</a>)
- The mark price must be using market decimal place setting. (<a name="0009-MRKP-006" href="#0009-MRKP-006">0009-MRKP-006</a>)

## Guide-level explanation

The *Mark Price* represents the "current" market value for an instrument that is being traded on a market on Vega. It is a calculated value primarily used to value trader's open portfolios against the prices they executed their trades at. Specifically, it is used to calculate the cash flows for [mark-to-market settlement](./0003-MTMK-mark_to_market_settlement.md).

Note that a mark price may not be a true "price" in the financial sense of the word, i.e. if the `price` changes by `X` then the value of a position does not necessarily change by `X * position size`, instead, the product's quote-to-value function must be used to ascertain the change, i.e. `change_in_value == product.value(new_mark_price) - product.value(old_mark_price)`.

## Reference-level explanation

The mark price is instantiated when a market opens via the [opening auction](./0026-AUCT-auctions.md).

It will subsequently be calculated according to a methodology selected from a suite of algorithms. The selection of the algorithm for calculating the *Mark Price* is specified at the "market" level as a market parameter.

Mark price can also be adjusted by [product lifecycle events](./0051-PROD-product.md), in which case the mark price set by the product remains the mark price until it is next recalculated (e.g. if the methodology is last traded price, until there is a new trade).

## Usage of the *Mark Price*

The most recently calculated *Mark Price* is used in the [mark-to-market settlement](./0003-MTMK-mark_to_market_settlement.md).  A change in the *Mark Price* is one of the triggers for the mark-to-market settlement to run.

## Algorithms for calculating the *Mark Price*

### 1. Last Traded Price of a Sequence with same time stamp with maximum frequency set by `network.markPriceUpdateMaximumFrequency`

 The mark price for the instrument is set to the last trade price in the market following processing of each transaction (i.e. submit/amend/delete order) from a sequence of transactions with the same time stamp, provided that at least `network.markPriceUpdateMaximumFrequency` has elapsed since the last mark price update.

 >*Example:* Assume `network.markPriceUpdateMaximumFrequency = 10s`.

 Consider the situation where the mark price was last updated to $900 and this was 12s ago. There is a market sell order for -20 and a market buy order for +100 with the same time stamp. The sell order results in two trades: 15 @ 920 and 5 @ 910. The buy order results in 3 trades; 50 @ $1000, 25 @ $1100 and 25 @ $1200, the mark price changes **once** to a new value of $1200.

 Now 8s has elapsed since the last update and there is a market sell order for volume 3 which executes against book volume as 1 @ 1190 and 2 @ 1100.
 The mark price isn't updated because `network.markPriceUpdateMaximumFrequency = 10s` has not elapsed yet.

 Now 10.1s has elapsed since the last update and there is a market buy order for volume 5 which executes against book volume as 1 @ 1220, 2 @ 1250 and 2 @ 1500. The mark price is updated to 1500.

### 2. Last Traded Price + Order Book

The mark price is set to the higher / lower of the last traded price, bid/offer.

>*Example a):* consider the last traded price was $1000 and the current best bid in the market is $1,100. The bid price is higher than the last traded price so the new Mark Price is $1,100.
>*Example b):* consider the last traded price was $1000 and the current best bid in the market is $999. The last traded price is higher than the bid price so the new Mark Price is $1,000.

### 3. Oracle

 An oracle source external to the market provides updates to the Mark Price. See the [data sourcing spec](./0045-DSRC-data_sourcing.md).

### 4. Model

 The *Mark Price* may be calculated using a built in model.

 >*Example:* An option price will theoretically decay with time even if the market's order book or trade history does not reflect this.

### 5. Defined as part of the product

  The *Mark Price* may be calculated using an algorithm defined by the product -- and 'selected' by a market parameter.


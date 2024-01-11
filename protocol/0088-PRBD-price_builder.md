# Price Builder

## Summary

This specification adds a flexible way to configue "mark price" method for different purpose. 

For perpetual futures markets there should be a “mark price” configuration and a “market price for funding” configuration so that the market can, potentially use different mark price for mark-to-market and price monitoring and completely different price for calculating funding.

## Algorithms for calculating the *Mark Price*

### 1. Last Traded Price of a Sequence with same time stamp with maximum frequency set by `network.markPriceUpdateMaximumFrequency`

The mark price for the instrument is set to the last trade price in the market following processing of each transaction (i.e. submit/amend/delete order) from a sequence of transactions with the same time stamp, provided that at least `network.markPriceUpdateMaximumFrequency` has elapsed since the last mark price update.

>*Example:* Assume `network.markPriceUpdateMaximumFrequency = 10s`.

Consider the situation where the mark price was last updated to $900 and this was 12s ago. There is a market sell order for -20 and a market buy order for +100 with the same time stamp. The sell order results in two trades: 15 @ 920 and 5 @ 910. The buy order results in 3 trades; 50 @ $1000, 25 @ $1100 and 25 @ $1200, the mark price changes **once** to a new value of $1200.

Now 8s has elapsed since the last update and there is a market sell order for volume 3 which executes against book volume as 1 @ 1190 and 2 @ 1100.
The mark price isn't updated because `network.markPriceUpdateMaximumFrequency = 10s` has not elapsed yet.

Now 10.1s has elapsed since the last update and there is a market buy order for volume 5 which executes against book volume as 1 @ 1220, 2 @ 1250 and 2 @ 1500. The mark price is updated to 1500.

### 2. Flexible mark price methodology
The calculations are specified in [markprice methodology research note](https://github.com/vegaprotocol/research/blob/markprice-updates/papers/markprice-methodology/markprice-methodology.tex).
Here, we only write the acceptance criteria.
Note that for calculating the median with an even number of entries we sort, pick out the two values that are in the middle of the list and average those. So in particular with two values a median is the same as the average for our purposes.

### Options of prices in the flexible mark price methodology

- traded mark price
- book mark price
- oracle mark price

## Acceptance criteria

- It is possible to obtain a time series for the market mark price from the data node from the time of the market proposal enactment onwards (subject to data node retention policies).(<a name="0088-PRBD-001" href="#0088-PRBD-001">0088-PRBD-001</a>)

- It is possible to obtain a time series for the price used for “vega side price” of the funding twap from the data node from the time of the market proposal enactment onwards (subject to data node retention policies).(<a name="0088-PRBD-002" href="#0088-PRBD-002">0088-PRBD-002</a>)

- It’s possible to specify start and end times / dates when requesting the time series of prices. (<a name="0088-PRBD-003" href="#0088-PRBD-003">0088-PRBD-003</a>)

- When leaving opening auction, market should either wait in opening auction until the first mark price is available or it is certain that leaving the opening auction will set it. (<a name="0088-PRBD-004" href="#0088-PRBD-004">0088-PRBD-004</a>)

- When market is in continous trading mode, mark price is updated when the time indicated by the mark price frequency is crossed (<a name="0088-PRBD-005" href="#0088-PRBD-005">0088-PRBD-005</a>)

- In terms of mark price update during action, we don’t do mark price updates (even if they come from external oracle). We do a MTM update upon leaving the auction with the latest available value. (<a name="0088-PRBD-006" href="#0088-PRBD-006">0088-PRBD-006</a>)





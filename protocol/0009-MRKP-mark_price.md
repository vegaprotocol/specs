# Mark Price

## Summary

A *Mark Price* is a concept derived from traditional markets.  It is a calculated value for the 'current market price' on a market.

Introduce a network parameter `network.markPriceUpdateMaximumFrequency` with minimum allowable value of `0s` maximum allowable value of `1h` and a default of `5s`.

The *Mark Price* represents the "current" market value for an instrument that is being traded on a market on Vega. It is a calculated value primarily used to value trader's open portfolios against the prices they executed their trades at. Specifically, it is used to calculate the cash flows for [mark-to-market settlement](./0003-MTMK-mark_to_market_settlement.md).

The mark price is instantiated when a market opens via the [opening auction](./0026-AUCT-auctions.md).

It will subsequently be calculated according to a methodology selected from a suite of algorithms. The selection of the algorithm for calculating the *Mark Price* is specified at the "market" level as a market parameter.

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


## Acceptance criteria

- The mark price must be set when the market leaves opening auction. (<a name="0009-MRKP-002" href="#0009-MRKP-002">0009-MRKP-002</a>)
- Each time the mark price changes the market data event containing the new mark price should be emitted.Specifically, the mark price set after leaving each auction, every interim mark price as well as the mark price based on last trade used at market termination and the one based on oracle data used for final settlement should all be observable from market data events. (<a name="0009-MRKP-009" href="#0009-MRKP-009">0009-MRKP-009</a>)

### Algorithm 1 (last trade price, excluding network trades):

- If `network.markPriceUpdateMaximumFrequency=0s` then any transaction that results in one or more trades causes the mark price to change to the value of the last trade and only the last trade. (<a name="0009-MRKP-003" href="#0009-MRKP-003">0009-MRKP-003</a>)
- If `network.markPriceUpdateMaximumFrequency>0` then out of a sequence of transactions with the same time-stamp the last transaction that results in one or more trades causes the mark price to change to the value of the last trade and only the last trade but only provided that at least `network.markPriceUpdateMaximumFrequency` has elapsed since the last update. (<a name="0009-MRKP-007" href="#0009-MRKP-007">0009-MRKP-007</a>)
- A transaction that doesn't result in a trade does not cause the mark price to change. (<a name="0009-MRKP-004" href="#0009-MRKP-004">0009-MRKP-004</a>)
- A transaction out of a sequence of transactions with the same time stamp which isn't the last trade-causing transaction will *not* result in a mark price change. (<a name="0009-MRKP-008" href="#0009-MRKP-008">0009-MRKP-008</a>)
- The mark price must be using market decimal place setting. (<a name="0009-MRKP-006" href="#0009-MRKP-006">0009-MRKP-006</a>)


### Flexible mark price methodology, no combinations yet

- It is possible to configure a cash settled futures market to use Algorithm 1 (ie last trade price) (<a name="0009-MRKP-010" href="#0009-MRKP-010">0009-MRKP-010</a>) and a perps market (<a name="0009-MRKP-011" href="#0009-MRKP-011">0009-MRKP-011</a>).
- It is possible to configure a cash settled futures market to use weighted average of trades over `network.markPriceUpdateMaximumFrequency` with decay weight `1` and power `1` (linear decay) (<a name="0009-MRKP-012" href="#0009-MRKP-012">0009-MRKP-012</a>) and a perps market (<a name="0009-MRKP-013" href="#0009-MRKP-013">0009-MRKP-013</a>).
- It is possible to configure a cash settled futures market to use impact of leveraged notional on the order book with the value of USDT `100` for mark price (<a name="0009-MRKP-014" href="#0009-MRKP-014">0009-MRKP-014</a>) and a perps market (<a name="0009-MRKP-015" href="#0009-MRKP-015">0009-MRKP-015</a>).
- It is possible to configure a cash settled futures market to use an oracle source for the mark price (<a name="0009-MRKP-016" href="#0009-MRKP-016">0009-MRKP-016</a>) and a perps market (with the oracle source different to that used for the external price in the perps market) (<a name="0009-MRKP-017" href="#0009-MRKP-017">0009-MRKP-017</a>).

### Flexible mark price methodology, combinations

- It is possible to configure a cash settled futures market to use a weighted average of 1. weighted average of trades over `network.markPriceUpdateMaximumFrequency` and 2. impact of leveraged notional on the order book with the value of USDT `100` and 3. an oracle source and if last trade is last updated more than 1 minute ago then it is removed and the remaining re-weighted and if the oracle is last updated more than 5 minutes ago then it is removed and the remaining re-weighted (<a name="0009-MRKP-018" href="#0009-MRKP-018">0009-MRKP-018</a>) and a perps market (with the oracle source different to that used for the external price in the perps market) (<a name="0009-MRKP-019" href="#0009-MRKP-019">0009-MRKP-019</a>).

- It is possible to configure a cash settled futures market to use a weighted average of 1. weighted average of trades over `network.markPriceUpdateMaximumFrequency` and 2. impact of leveraged notional on the order book with the value of USDT `100` and if last trade is last updated more than 1 minute ago then it is removed and the remaining re-weighted and if the oracle is last updated more than 5 minutes ago then it is removed and the remaining re-weighted and if both sources are stale than the mark price stops updating (<a name="0009-MRKP-020" href="#0009-MRKP-020">0009-MRKP-020</a>) and a perps market (<a name="0009-MRKP-021" href="#0009-MRKP-021">0009-MRKP-021</a>).

- It is possible to configure a cash settled futures market to use a median of 1. weighted average of trades over `network.markPriceUpdateMaximumFrequency` and 2. impact of leveraged notional on the order book with the value of USDT `100` and 3. an oracle source and if last trade is last updated more than 1 minute ago then it is removed and if the oracle is last updated more than 5 minutes ago then it is removed (<a name="0009-MRKP-022" href="#0009-MRKP-022">0009-MRKP-022</a>) and a perps market (with the oracle source different to that used for the external price in the perps market) (<a name="0009-MRKP-023" href="#0009-MRKP-023">0009-MRKP-023</a>).

### Example 1 - A typical path of a cash settled futures market from end of openning auction till expiry (median mark price method)(<a name="0009-MRKP-024" href="#0009-MRKP-024">0009-MRKP-024</a>)

1. Market is in opening auction, no mark price.
2. Order uncrossed, ends of opening auction, market is in active state. New event is emitted for new mark price.
3. New trade triggers new traded price, mark price recalculated, new event is emitted for new mark price.
4. New Oracle price comes, mark price recalculated, new event is emitted for new mark price.
5. Another Oracle price comes, mark price recalculated, new event is emitted for new mark price.
6. Traded price at step 2 is stale, and Oracle price at step 4 is stale, mark price recalculated, new event is emitted for new mark price.
7. market's status is set to trading terminated, An [oracle event occurs] that is eligible to settle the market, new event is emitted for new mark price.

### Example 2 - A typical path of a cash settled perps market from end of openning auction (median mark price method)(<a name="0009-MRKP-025" href="#0009-MRKP-025">0009-MRKP-025</a>)

1. Market is in opening auction, no mark price.
2. Order uncrossed, ends of opening auction, market is in active state. New event is emitted for new mark price.
3. New trade triggers new traded price, mark price recalculated, new event is emitted for new mark price.
4. New Oracle price comes, mark price recalculated, new event is emitted for new mark price.
5. Another Oracle price comes, mark price recalculated, new event is emitted for new mark price.
5. Oracle price comes for funding payments, mark price recalculated, new event is emitted for new mark price.
6. Traded price at step 2 is stale, and Oracle price at step 4 is stale, mark price recalculated, new event is emitted for new mark price.


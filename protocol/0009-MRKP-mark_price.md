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
- If a market mark price is configured in such a way that the mark price methodology hasn't provided a price at the point of uncrossing the opening auction, then the auction uncrossing price is set as the first mark price, regardless of what the mark price methodology says. (<a name="0009-MRKP-001" href="#0009-MRKP-001">0009-MRKP-001</a>)

### Algorithm 1 (last trade price, excluding network trades)

- If `network.markPriceUpdateMaximumFrequency>0` then out of a sequence of transactions with the same time-stamp the last transaction that results in one or more trades causes the mark price to change to the value of the last trade and only the last trade but only provided that at least `network.markPriceUpdateMaximumFrequency` has elapsed since the last update. (<a name="0009-MRKP-007" href="#0009-MRKP-007">0009-MRKP-007</a>)
- A transaction that doesn't result in a trade does not cause the mark price to change. (<a name="0009-MRKP-004" href="#0009-MRKP-004">0009-MRKP-004</a>)
- A transaction out of a sequence of transactions with the same time stamp which isn't the last trade-causing transaction will *not* result in a mark price change. (<a name="0009-MRKP-008" href="#0009-MRKP-008">0009-MRKP-008</a>)
- The mark price must be using market decimal place setting. (<a name="0009-MRKP-006" href="#0009-MRKP-006">0009-MRKP-006</a>)
- It is possible to configure a cash settled futures market to use Algorithm 1 (ie last trade price) (<a name="0009-MRKP-010" href="#0009-MRKP-010">0009-MRKP-010</a>) and a perps market (<a name="0009-MRKP-011" href="#0009-MRKP-011">0009-MRKP-011</a>).

### Flexible mark price methodology, no combinations yet

#### Trade-size-weighted average price

- It is possible to configure a cash settled futures market to use weighted average of trades over `network.markPriceUpdateMaximumFrequency` with decay weight `1` and power `1` (linear decay) (<a name="0009-MRKP-012" href="#0009-MRKP-012">0009-MRKP-012</a>) and a perps market (<a name="0009-MRKP-013" href="#0009-MRKP-013">0009-MRKP-013</a>).
- when choosing price type `weight` and set weight on `trade-size-weight price` only, set decay weight to `0` and decay power to `1`, and set up trade at price `15920`, `15940`, `15960`, `15990` at various size, and check if the weighted average mark price is corrected calculated (<a name="0009-MRKP-110" href="#0009-MRKP-110">0009-MRKP-110</a>) and on perp market (<a name="0009-MRKP-111" href="#0009-MRKP-111">0009-MRKP-111</a>)
-when choosing price type `weight` and set weight on `trade-size-weight price` only, set decay weight to `0` and decay power to `1`, and set up trade at price `15940`, `15960`, `15990` at various size, and check if the weighted average mark price is corrected calculated (<a name="0009-MRKP-112" href="#0009-MRKP-112">0009-MRKP-112</a>) and on perp market (<a name="0009-MRKP-113" href="#0009-MRKP-113">0009-MRKP-113</a>)
- when choosing price type `weight` and set weight on `trade-size-weight price` only, set decay weight to `1` and decay power to `1`, and set up trade at price `15920`, `15940`, `15960`, `15990` at various size, and check if the weighted average mark price is corrected calculated (<a name="0009-MRKP-114" href="#0009-MRKP-114">0009-MRKP-114</a>) and on perp market (<a name="0009-MRKP-115" href="#0009-MRKP-115">0009-MRKP-115</a>)
- when choosing price type `weight` and set weight on `trade-size-weight price` only, set decay weight to `1` and decay power to `0`, and set up trade at price `15920`, `15940`, `15960`, `15990` at various size, and check if the weighted average mark price is corrected calculated (<a name="0009-MRKP-116" href="#0009-MRKP-116">0009-MRKP-116</a>) and on perp market (<a name="0009-MRKP-117" href="#0009-MRKP-117">0009-MRKP-117</a>)
- when choosing price type `weight` and set weight on `trade-size-weight price` only, set decay weight to `0.5` and decay power to `1`, and set up trade at price `15920`, `15940`, `15960`, `15990` at various size, and check if the weighted average mark price is corrected calculated (<a name="0009-MRKP-118" href="#0009-MRKP-118">0009-MRKP-118</a>) and on perp market (<a name="0009-MRKP-119" href="#0009-MRKP-119">0009-MRKP-119</a>)

#### Leverage-notional book price

- It is possible to configure a cash settled futures market to use impact of leveraged notional on the order book with the value of USDT `100` for mark price (<a name="0009-MRKP-014" href="#0009-MRKP-014">0009-MRKP-014</a>) and a perps market (<a name="0009-MRKP-015" href="#0009-MRKP-015">0009-MRKP-015</a>).
- when choosing price type `weight` and set weight on `leverage-notional book price` only, set cash amount to `100` (which should make the notional volume at sell and buy round to `0`), and place a few orders on the book with best bid `15900` and best ask `16000` and the leverage-notional book price should be the mid-price (<a name="0009-MRKP-120" href="#0009-MRKP-120">0009-MRKP-120</a>) and on perp market (<a name="0009-MRKP-121" href="#0009-MRKP-121">0009-MRKP-121</a>)
- when choosing price type `weight` and set weight on `leverage-notional book price` only, set cash amount to `100,000` and place a few orders on the book with best bid `15900` and best ask `16000` and check if leverage-notional book price is corrected calculated (<a name="0009-MRKP-122" href="#0009-MRKP-122">0009-MRKP-122</a>) and on perp market (<a name="0009-MRKP-123" href="#0009-MRKP-123">0009-MRKP-123</a>)
- when choosing price type `weight` and set weight on `leverage-notional book price` only, set cash amount to `5,000,000` (which should make the notional volume too big for the book) and place a few orders on the book with best bid `15900` and best ask `16000` and the leverage-notional book price should be the mid-price (<a name="0009-MRKP-124" href="#0009-MRKP-124">0009-MRKP-124</a>) and on perp market (<a name="0009-MRKP-125" href="#0009-MRKP-125">0009-MRKP-125</a>)
- when choosing price type `weight` and set weight on `leverage-notional book price` only, set cash amount to `100,000` and place a few orders on the book with best bid `15900` and best ask `16000` and check leverage-notional book price, then change the order book by placing a trade, and check if the leverage-notional book price is updated when the time indicated by the mark price frequency is crossed(<a name="0009-MRKP-126" href="#0009-MRKP-126">0009-MRKP-126</a>) and on perp market (<a name="0009-MRKP-127" href="#0009-MRKP-127">0009-MRKP-127</a>)

#### Oracle source price

- It is possible to configure a cash settled futures market to use an oracle source for the mark price (<a name="0009-MRKP-016" href="#0009-MRKP-016">0009-MRKP-016</a>) and a perps market (with the oracle source different to that used for the external price in the perps market) (<a name="0009-MRKP-017" href="#0009-MRKP-017">0009-MRKP-017</a>).

- when choosing price type `weight` and set weight on `oracle source price` only, set up 2 oracle prices at different time, and check if the oracle mark price is correctly calculated (<a name="0009-MRKP-130" href="#0009-MRKP-130">0009-MRKP-130</a>)

- when choosing price type `weight` and set weight on `oracle source price` only, set up oracle prices at different time, and check if the oracle mark price updated according to  is correctly calculated according to `network.markPriceUpdateMaximumFrequency` (<a name="0009-MRKP-131" href="#0009-MRKP-131">0009-MRKP-131</a>)

- when choosing price type `weight` and set weight on `oracle source price` only, set up 3 oracle prices at different time with 1 of them becomes stale, and check if the oracle mark price updated according to  is correctly calculated by using the right price (<a name="0009-MRKP-132" href="#0009-MRKP-132">0009-MRKP-132</a>)

### Flexible mark price methodology, combinations

- It is possible to configure a cash settled futures market to use a weighted average of 1. weighted average of trades over `network.markPriceUpdateMaximumFrequency` and 2. impact of leveraged notional on the order book with the value of USDT `100` and 3. an oracle source and if last trade is last updated more than 1 minute ago then it is removed and the remaining re-weighted and if the oracle is last updated more than 5 minutes ago then it is removed and the remaining re-weighted (<a name="0009-MRKP-018" href="#0009-MRKP-018">0009-MRKP-018</a>) and a perps market (with the oracle source different to that used for the external price in the perps market) (<a name="0009-MRKP-019" href="#0009-MRKP-019">0009-MRKP-019</a>).

- It is possible to configure a cash settled futures market to use a weighted average of 1. weighted average of trades over `network.markPriceUpdateMaximumFrequency` and 2. impact of leveraged notional on the order book with the value of USDT `100` and if last trade is last updated more than 1 minute ago then it is removed and the remaining re-weighted and if the oracle is last updated more than 5 minutes ago then it is removed and the remaining re-weighted and if both sources are stale than the mark price stops updating (<a name="0009-MRKP-020" href="#0009-MRKP-020">0009-MRKP-020</a>) and a perps market (<a name="0009-MRKP-021" href="#0009-MRKP-021">0009-MRKP-021</a>).

- It is possible to configure a cash settled futures market to use a median of 1. weighted average of trades over `network.markPriceUpdateMaximumFrequency` and 2. impact of leveraged notional on the order book with the value of USDT `100` and 3. an oracle source and if last trade is last updated more than 1 minute ago then it is removed and if the oracle is last updated more than 5 minutes ago then it is removed (<a name="0009-MRKP-022" href="#0009-MRKP-022">0009-MRKP-022</a>) and a perps market (with the oracle source different to that used for the external price in the perps market) (<a name="0009-MRKP-023" href="#0009-MRKP-023">0009-MRKP-023</a>).

- When market is leaving auction (including opening auction and monitoring auction), mark price should be recalculated (<a name="0009-MRKP-024" href="#0009-MRKP-024">0009-MRKP-024</a>) and a perps market (with the oracle source different to that used for the external price in the perps market) (<a name="0009-MRKP-025" href="#0009-MRKP-025">0009-MRKP-025</a>).

- When market is at monitoring auction, book price should be indicative uncrossing price, mark price should be recalculated when the time indicated by the mark price frequency is crossed(<a name="0009-MRKP-026" href="#0009-MRKP-026">0009-MRKP-026</a>) and a perps market (with the oracle source different to that used for the external price in the perps market) (<a name="0009-MRKP-027" href="#0009-MRKP-027">0009-MRKP-027</a>).

- It is possible to configure a cash settled futures market to use a weighted average of 1. weighted average of trades over `network.markPriceUpdateMaximumFrequency` and 2. impact of leveraged notional on the order book with the value of USDT `100` and when the book does not have enough volume, then the book price should not be included (<a name="0009-MRKP-028" href="#0009-MRKP-028">0009-MRKP-028</a>) and a perps market (with the oracle source different to that used for the external price in the perps market) (<a name="0009-MRKP-029" href="#0009-MRKP-029">0009-MRKP-029</a>).

- It is possible to configure a cash settled futures market to use a weighted average of 1. weighted average of trades over `network.markPriceUpdateMaximumFrequency` and 2. impact of leveraged notional on the order book with the value of USDT `0` and the book price should be mid price (<a name="0009-MRKP-030" href="#0009-MRKP-030">0009-MRKP-030</a>) and a perps market (with the oracle source different to that used for the external price in the perps market) (<a name="0009-MRKP-031" href="#0009-MRKP-031">0009-MRKP-031</a>).
- Set price type to "median", only have data source available from "Trade-size-weighted average price" and "Leverage-notional book price" and 1 trade at 15920, check the mark price is correctly calculated (<a name="0009-MRKP-032" href="#0009-MRKP-032">0009-MRKP-032</a>) and a perps market (<a name="0009-MRKP-033" href="#0009-MRKP-033">0009-MRKP-033</a>)

- Set price type to "median", only have data source available from "Trade-size-weighted average price" and "Leverage-notional book price" and 1 trade at 15920, and 1 trade at 15940, move time, and check stale price should not be included (<a name="0009-MRKP-034" href="#0009-MRKP-034">0009-MRKP-034</a>) and a perps market (<a name="0009-MRKP-035" href="#0009-MRKP-035">0009-MRKP-035</a>)

- A market can be configured with `markPriceConfiguration: price type` is `Weighted` without oracles (<a name="0009-MRKP-060" href="#0009-MRKP-060">0009-MRKP-060</a>)

- A market can be configured with `markPriceConfiguration: price type` is `Median` without oracles (<a name="0009-MRKP-061" href="#0009-MRKP-061">0009-MRKP-061</a>)

### Validation

- Boundary values are respected for the market parameters

  - `markPriceConfiguration: decayWeight` valid values: `[0,1]`(<a name="0009-MRKP-050" href="#0009-MRKP-050">0009-MRKP-050</a>)

  - `markPriceConfiguration: decayPower` valid values: `{1,2,3}`(<a name="0009-MRKP-051" href="#0009-MRKP-051">0009-MRKP-051</a>)

  - `markPriceConfiguration: cashAmount` valid values: `>=0`(<a name="0009-MRKP-052" href="#0009-MRKP-052">0009-MRKP-052</a>)

  - `markPriceConfiguration: source weight` valid values: `>=0`(<a name="0009-MRKP-053" href="#0009-MRKP-053">0009-MRKP-053</a>)

  - `markPriceConfiguration: source staleness tolerance` valid values: `valid duration string, e.g. "5s", "24h"`(<a name="0009-MRKP-054" href="#0009-MRKP-054">0009-MRKP-054</a>)

  - `markPriceConfiguration: source weight` and `markPriceConfiguration: source staleness tolerance` should have the same length(<a name="0009-MRKP-055" href="#0009-MRKP-055">0009-MRKP-055</a>)

  - Mark price configuration `source_weight` length should be 3 plus number of oracle data sources if the price type is weighted (<a name="0009-MRKP-056" href="#0009-MRKP-056">0009-MRKP-056</a>).

  - If the mark price type is not weighted the source weight must be empty (<a name="0009-MRKP-062" href="#0009-MRKP-062">0009-MRKP-062</a>).

  - Mark price configuration `source staleness tolerance` length must be 3 plus number of oracle data sources if price type is weighted or median (<a name="0009-MRKP-063" href="#0009-MRKP-063">0009-MRKP-063</a>).

  - If the mark price type is weighted, there must be at least one non zero weight (<a name="0009-MRKP-064" href="#0009-MRKP-064">0009-MRKP-064</a>).

  - When `markPriceConfiguration: price type` is **not** `Last Trade Price`, the `markPriceConfiguration: source staleness tolerance`, `markPriceConfiguration: source weight`, `markPriceConfiguration: decayPower` and `markPriceConfiguration: cashAmount` must be provided
    - new market (<a name="0009-MRKP-057" href="#0009-MRKP-057">0009-MRKP-057</a>)
    - update market (<a name="0009-MRKP-058" href="#0009-MRKP-058">0009-MRKP-058</a>)

  - When `markPriceConfiguration: source weight` is provided then it must not be all `0` (<a name="0009-MRKP-059" href="#0009-MRKP-059">0009-MRKP-059</a>)

### Example 1 - A typical path of a cash settled futures market from end of opening auction till expiry (use Algorithm 2 (ie median price))(<a name="0009-MRKP-040" href="#0009-MRKP-040">0009-MRKP-040</a>)

1. Market is in opening auction, no mark price.
2. Order uncrossed, ends of opening auction, market is in active state. New event is emitted for new mark price.
3. New trade triggers new traded price, mark price recalculated when the time indicated by the mark price frequency is crossed, new event is emitted for new mark price.
4. New Oracle price comes, mark price recalculated when the time indicated by the mark price frequency is crossed, new event is emitted for new mark price.
5. Another Oracle price comes, mark price recalculated when the time indicated by the mark price frequency is crossed, new event is emitted for new mark price.
6. Traded price at step 2 is stale, and Oracle price at step 4 is stale, mark price recalculated when the time indicated by the mark price frequency is crossed, new event is emitted for new mark price.
7. market's status is set to trading terminated, An [oracle event occurs] that is eligible to settle the market, new event is emitted for new mark price.

### Example 2 - A typical path of a cash settled perps market from end of opening auction (use Algorithm 2 (ie median price))(<a name="0009-MRKP-041" href="#0009-MRKP-041">0009-MRKP-041</a>)

1. Market is in opening auction, no mark price.
2. Order uncrossed, ends of opening auction, market is in active state. New event is emitted for new mark price.
3. New trade triggers new traded price, mark price recalculated when the time indicated by the mark price frequency is crossed, new event is emitted for new mark price.
4. New Oracle price comes, mark price recalculated when the time indicated by the mark price frequency is crossed, new event is emitted for new mark price.
5. Another Oracle price comes, mark price recalculated when the time indicated by the mark price frequency is crossed, new event is emitted for new mark price.
6. Oracle price comes for funding payments, mark price recalculated when the time indicated by the mark price frequency is crossed, new event is emitted for new mark price.
7. Traded price at step 2 is stale, and Oracle price at step 4 is stale, mark price recalculated, new event is emitted for new mark price.

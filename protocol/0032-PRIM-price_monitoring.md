Feature name: price-monitoring

Start date: 2020-04-29

Specification PR: [275](https://github.com/vegaprotocol/product/pull/275)

# Acceptance Criteria

- [ ] Price monitoring engine exists, holds all the horizon, confidence level, auction extension triplets configured for the market and exposes a function that takes as input the arrival price of the next transaction and returns the signal instructing the matching engine if a price protection auction should commence, and if so, what should its period be. (<a name="0032-PRIM-001" href="#0032-PRIM-001">0032-PRIM-001</a>)
- [ ] Risk model prescribes maximum probability level which it can support. (<a name="0032-PRIM-002" href="#0032-PRIM-002">0032-PRIM-002</a>)
- [ ] `vega` refuses to create a market if the specified probability level for price monitoring exceeds what the risk model specifies - to avoid spurious accuracy and runtime errors. (<a name="0032-PRIM-003" href="#0032-PRIM-003">0032-PRIM-003</a>)
- [ ] The matching engine triggers price protection auction period based on the price monitoring signal. (<a name="0032-PRIM-004" href="#0032-PRIM-004">0032-PRIM-004</a>)
- [ ] The market continues in regular fashion once price protection auction period ends. (<a name="0032-PRIM-005" href="#0032-PRIM-005">0032-PRIM-005</a>)
- [ ] Transactions are processed atomically so that the transaction which directly moved the price beyond allowed band gets processed again via price protection auction period (and no associated trades are generated prior to that period). (<a name="0032-PRIM-006" href="#0032-PRIM-006">0032-PRIM-006</a>)
- [ ] A maximum of 4 price monitoring triggers can be added per market (<a name="0032-PRIM-007" href="#0032-PRIM-007">0032-PRIM-007</a>)

# Summary

The dynamics of market price movements are such that prices don't always represent the participants' true average view of the price, but are instead artefacts of the market microstructure: sometimes low liquidity and/or a large quantity of order volume can cause the price to diverge from the true market price. It is impossible to tell at any point in time if this has happened or not.

As a result, we assume that relatively small moves are "real" and that larger moves might not be. Price monitoring exists to determine the real price in the latter case. Distinguishing between small and large moves can be highly subjective and market-dependent. We are going to rely on the risk model to formalise this process. Risk model can be used to obtain the probability distribution of prices at a future point in time given the current price. A price monitoring trigger can be constructed using a fixed horizon and probability level.
To give an example: get the price distribution in an hour as implied by the risk model given the current mid price, if after the hour has passed and the actual mid price is beyond what the model implied (either too low or too high) with some chosen probability level (say 99%), then we'd characterise such market move as large.  In general we may want to use a few such triggers per market (i.e. different horizon and probability level pairs). The framework should be able to trigger a price protection auction period with any valid trading mode.

As mentioned above, price monitoring is meant to stop large market movements that are not "real" from occurring, rather than just detect them after the fact. To that end, it is necessary to pre-process every transaction and check if it triggers the price monitoring action. If pre-processing the transaction doesn't result in the trigger being activated then it should be "committed" by generating the associated events and modifying the order book accordingly (e.g. generate a trade and take the orders that matched off the book). On the other hand if the trigger is activated and the submitted transaction is valid for auction mode, the entire order book **along with that transaction** needs to be processed via price protection auction. If the transaction which activate the trigger is not valid for auction, then it should get rejected and market should continue in the current trading mode. Auction period associated with a given distribution projection horizon and probability level will be specified as part of market setup. Once the auction period finishes the trading should resume in regular fashion (unless other triggers are active, more on that in [reference-level explanation](#reference-level-explanation)).

Please see the [auction spec](./0026-AUCT-auctions.md) for auction details.

## Note

Price monitoring likely won't be the only possible trigger of auction period ([liquidity monitoring](./0035-LIQM-liquidity_monitoring.md) or governance action could be the other ones). Thus the framework put in place as part of this spec should be flexible enough to easily accommodate other types of triggers.

Likewise, pre-processing transactions will be needed as part of the [fees spec](./0029-FEES-fees.md), hence it should be implemented in such a way that it's easy to repurpose it.

# Guide-level explanation

- We need to emit a "significant price change" event if price move over the horizon τ turned out to be more than what the risk model implied at a probability level α.
  - Take **arrival price of the next transaction** (the value that will be the last traded price if we process the next transaction): V<sub>t</sub>,
  - look-up mid-price S<sub>t-τ</sub>, (prices aren't continuous so will need max(S<sub>s</sub> : s  ≤ t-τ), call it  S<sub>t-τ</sub><sup>*</sup>,
  - get the bounds associated with S<sub>t-τ</sub><sup>*</sup>, at a probability level α:
    - if V<sub>t</sub> falls within those bounds then transaction is processed in the current trading mode
    - otherwise the transaction (along with the rest of order book) needs to be processed via a temporary auction.
- We need to have "atomicity" in transaction processing:
  - When we process transaction we need to check what the arrival price V<sub>t</sub> is.
  - If it results in "significant price change" event then we want the order book to maintain the state from before we started processing the transaction.
    - If the transaction is valid for auction mode then price protection auction gets triggered for a period T.
    - If the transaction is not valid for auction mode then it gets rejected, an appropriate event gets sent and market continues in current trading mode.
- In general we might have a list of triplets: α, τ, T specifying each trigger.
- Once the price protection auction period finishes, the remaining triggers should be examined and if hit the auction period should be extended accordingly.
- Then the market continues in the regular fashion.

# Reference-level explanation

## Parameters

### Market

- `priceMonitoringParameters` - an array of more price monitoring parameters with the following fields:
  - `horizon` - price projection horizon expressed as a year fraction over which price is to be projected by the risk model and compared to the actual market moves during that period. Must be positive.
  - `probability` - probability level used in price monitoring. Must be in the (0,1) range.
  - `auctionExtension` - auction duration (or extension in case market is already in auction mode) per breach of the `horizon`, `probability` trigger pair specified above. Must be greater than 0.

### Network

- `PriceMonitoringDefaultParameters`: Specifies default market parameters outlined in the previous paragraph. These will be used if market parameters don't get explicitly specified.
- `PriceMonitoringUpdateFrequency`: Specifies how often (expressed in seconds) the price monitoring scaling factors should be updated by the risk model.

## View from the [vega](https://github.com/vegaprotocol/vega) side

- Per each transaction:
  - the matching engine sends the **price monitoring engine** the [arrival price of the next transaction](#guide-level-explanation) along with the current `vega time`
  - price monitoring engine sends back signal informing if the price protection auction should be triggered (and if so how long the auction period should be),
  - if no trigger gets activated then the transaction is processed in a regular fashion, otherwise:
    - the price protection auction commences and the transaction considered should be processed in this way (along with any other orders on the book and pending transactions that are valid for auction).

## View from the price monitoring engine side

Price monitoring engine will interface between the matching engine and the risk model. It will communicate with the matching engine every time a new transaction is processed (to check it its' arrival price should trigger an auction). It will communicate with the risk model with a predefined frequency to inform the risk model of the latest price history and obtain a new set of scaling factors used to calculate min/max prices from the reference price.

Specifically:

- Price monitoring engine averages (weighted by volume) all the prices received from the matching engine that have the same timestamp.
- It periodically (in a predefined, deterministic way) sends the:
  - the probability level α,
  - period τ,
  - the associated reference price
to the risk model and obtains the range of valid up/down price moves per each of the specified triggers. Please note that these can be expressed as either additive offsets or multiplicative factors depending on the risk model used. The reference price is the latest price such that it's at least τ old or the earliest available price should price history be shorter than τ.
- It holds the history of volume weighted average prices looking back to the maximum τ configured in the market.
- Everytime a new price is received from the matching engine the price monitoring engine checks all the [τ, up factor, down factor] triplets relevant for the timestamp, looks-up the associated past (volume weighted) price and sends the signal back to the matching engine informing if the received price would breach the min/max move prescribed by the risk model.
- The bounds corresponding to the current time instant and the arrival price of the next transaction will be used to indicate if the price protection auction should commence, and if so, what should its' period be (see below).
- To give an example, with 3 triggers the price protection auction can be calculated as follows:
  - \>=1% move in 10 min window -> 5 min auction,
  - \>=2% move in 30 min window -> 15 min auction (i.e. if after 5 min this trigger condition is satisfied by the price we'd uncross at, extend auction by 10 mins),
  - \>=5% move in 2 hour window -> 1 hour auction (if after 15 mins, this is satisfied by the price we'd uncross at, extend auction by another 45 mins).
- At the market start time and after each price-monitoring auction period the bounds will reset
  - hence the bounds between that time and the minimum τ specified in the triggers will be constant (calculated using current price, the minimum τ and α associated with it).
- The resulting auction length should be at least `min_auction_length` (see the [auctions](./0026-AUCT-auctions.md#auction-config) spec). If the auction length implied by the triggers is less than that it should be extended.

## View from [quant](https://github.com/vegaprotocol/quant) library side

- The risk model calculates the bounds per reference price, horizon τ and confidence level α beyond which a price monitoring auction should be triggered.
- The ranges of valid price moves are returned as either additive offsets or multiplicative factors for the up and down move. The price monitoring engine (PME) will know how to cope with either and apply it to the price bounds.
- These bounds are to be available to other components and included in the market data API
- Internally the risk model implements a function that takes as input: (reference price, confidence level alpha, time period tau) and returns either: 
  - the additive offsets: f<sub>min</sub><sup>additive</sup>, f<sub>max</sub><sup>additive</sup> such that S<sub>min</sub>:=S<sub>ref</sub>+f<sub>min</sub><sup>additive</sup> and S<sub>max</sub>:=S<sub>ref</sub>+f<sub>max</sub><sup>additive</sup>  or
  - the multiplicative factors: f<sub>min</sub><sup>multiplicative</sup>, f<sub>max</sub><sup>multiplicative</sup> such that S<sub>min</sub>:=S<sub>ref</sub>*f<sub>min</sub><sup>multiplicative</sup> and S<sub>max</sub>:=S<sub>ref</sub>*f<sub>max</sub><sup>multiplicative</sup> 

  so that P(S<sup>min</sup> < S<sup>τ</sup> < S<sup>max</sup>) ≥ α.

# Test cases

See acceptance criteria.

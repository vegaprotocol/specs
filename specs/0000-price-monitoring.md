Feature name: price-monitoring
Start date: 2020-04-29
Specification PR: https://github.com/vegaprotocol/product/pull/275

# Acceptance Criteria

- [ ] Risk model exposes a function that takes as input: (current price, confidence level alpha, time period tau) and returns the signal instructing core if a price protection auction should commence, and if so, what should its period be.
- [ ] Risk model prescribes maximum probability level which it can support.
- [ ] `vega` refuses to create a market if the specified probability level for price monitoring exceeds what the risk model specifies - to avoid spurious accuracy and runtime errors.
- [ ] `vega` triggers price protection auction period based on the price monitoring signal.
- [ ] The market continues in regular fashion once price protection auction period ends.
- [ ] Transactions are processed atomically so that the transaction which directly moved the price beyond allowed band gets processed again via price protection auction period (and no associated trades are generated prior to that period).

# Summary

The dynamics of market price movements are such that prices don't always represent the participants' true average view of the price, but are instead artefacts of the market microstructure: sometimes low liquidity and/or a large quantity of order volume can cause the price to diverge from the true market price. It is impossible to tell at any point in time if this has happened or not.

As a result, we assume that relatively small moves are "real" and that larger moves might not be. Price monitoring exists to determine the real price in the latter case. Distinguishing between small and large moves can be highly subjective and market-dependent. We are going to rely on the risk model to formalise this process. Risk model can be used to obtain the probability distribution of prices at a future point in time given the current price. A price monitoring trigger can be constructed using a fixed horizon and probability level.
To give an example: get the price distribution in an hour as implied by the risk model given the current mid price, if after the hour has passed and the actual mid price is beyond what the model implied (either too low or too high) with some chosen probability level (say 99%), then we'd charaterise such market move as large.  In general we may want to use a few such triggers per market (i.e. different horizon and probability level pairs). The framework should be able to trigger a price protection auction period with any valid trading mode.

As mentioned above, price monitoring is meant to stop large market movements that are not "real" from occuring, rather than just detect them after the fact. To that end, it is necessary to pre-process every transaction and check if it triggers the price monitoring action. If pre-processing the transaction doesn't result in the trigger being activated then it should be "committed" by generating the associated events and modifying the order book accordingly (e.g. generate a trade and take the orders that matched off the book). On the other hand if the trigger is activated, the entire order book **along with that transaction** needs to be processed via price protection auction. Auction period associated with a given distribution projection horizon and probability level will be specified as part of market setup. Once the auction period finishes the trading should resume in regular fashion (unless other triggers are active, more on that in [reference-level explanation](#reference-level-explanation)).

Please see the [auction spec](https://github.com/vegaprotocol/product/blob/187-auction-spec/specs/0026-auctions.md) for auction details.

### Note

Price monitoring likely won't be the only possible trigger of auction period (liquidity monitoring - spec pending - or governance action could be the other ones). Thus the framework put in place as part of this spec should be flexible enough to easily accommodate other types of triggers.

Likewise, pre-processing transactions will be needed as part of the [fees spec](https://github.com/vegaprotocol/product/blob/WIP-fees-spec/specs/0029-fees.md), hence it should be implemented in such a way that it's easy to repurpose it.

# Guide-level explanation

- We need to emit a "significant price change" event if price move over the horizon τ turned out to be more than what the risk model implied at a probability level α.
  - Take **arrival price of the next transaction** (the value that will be the last traded price if we process the next transaction): V<sub>t</sub>,
  - look-up mid-price S<sub>t-τ</sub>, (prices aren't continuous so will need max(S<sub>s</sub> : s  ≤ t-τ), call it  S<sub>t-τ</sub><sup>*</sup>,
  - get the bounds associated with S<sub>t-τ</sub><sup>*</sup>, at a probability level α:
    - if V<sub>t</sub> falls within those bounds then transaction is processed in the current trading mode
    - otherwise the transaction (along with the rest of order book) needs to be processed via a temporary auction.
- We need to have "atomicity" in transaction processing:
  - When we process transaction we need to check what the arrival price V<sub>t</sup> is.
  - If it results in "significant price change" event then we want the order book to maintain the state from before we started processing the transation.
  - Price protection auction is then triggered for a period T.
- In general we might have a list of triplets: α, τ, T specifying each trigger.
- Once the price protection auction period finishes, the remaining triggers should be examined and if hit the auction period should be extended accordingly.
- Then the market continues in the regular fashion.

# Reference-level explanation

## View from the [vega](https://github.com/vegaprotocol/vega) side

- for each transaction:
  - The price monitoring engine sends the risk model<sup>[1](#footnote1)</sup> the [arrival price of the next transaction](#guide-level-explanation) along with the current `vega time`
  - risk model sends back signal informing if the price protection auction should be triggered (and if so how long the auction period should be)
  - if no trigger gets activated then the transaction is processed in a regular fashion, otherwise:
    - the price protection auction commences and the transaction considered should be processed in this way (along with any other orders on the book and pending transactions that are valid for auction).

## View from [quant](https://github.com/vegaprotocol/quant) library side<sup>[1](#myfootnote1)</sup>

- we get arrival price of the next transaction and `vega time` from [vega](https://github.com/vegaprotocol/vega)
- we can use that to build a time series and calculate the bounds associated with each trigger
- these bounds are to be available to other components and included in the market data API
- note that bounds themselves will form a timeseries covering range from current time to the maximum τ specified in the triggers.
- the bounds are to be calculated at the one second resolution
- the bounds corresponding to the current time instant and the arrival price of the next transaction will be used to indicate if the price protection auction should commence, and if so, what should its' period be (see below).

- To give an example, with 3 triggers the price protection auction can be calculated as follows:

  - \>=1% move in 10 min window -> 5 min auction
  - \>=2% move in 30 min window -> 15 min auction (i.e. if after 5 min this trigger condiiton is satisfied by the price we'd uncross at, extend auction by 10 mins)
  - \>=5% move in 2 hour window -> 1 hour auction (if after 15 mins, this is satisfied by the price we'd uncross at, extend auction by another 45 mins)

- at the market start time and after each price-monitoring auction period the bounds will reset
  - hence the bounds between that time and the minimum τ specified in the triggers will be constant (calculated using current price, the minimum τ and α associated with it).
- internally the risk model implements a function that takes as input: (current price, confidence level alpha, time period tau) and return limits S<sup>min</sup> and S<sup>max</sup> such that P(S<sup>min</sup> < S<sup>τ</sup> < S<sup>max</sup>) ≥ α. Example input (100, 1 hour, 0.99) returns S_max = 111.2343 and S_min = 93.456.

### Notes

- We need a probability density function (p.d.f.) from the risk model and the inverse p.d.f.
- Should generally handle a vector of triplets: { horizon, probability, auction (extension) duration }
- Implement a cut-off on probability level so we don’t return spuriously accurate results (check tail estimates we get from probability models)
- Cache the results on quant library side.

# Test cases

See acceptance criteria.

<a name="footnote1">[1]: </a>Or perhaps another component that interfaces between the two.

Feature name: price-monitoring
Start date: 2020-04-29
Specification PR: https://github.com/vegaprotocol/product/pull/275

# Acceptance Criteria

- [ ] Risk model returns probability density function (p.d.f.) and the inverse p.d.f.
- [ ] Risk model returns bounds for a move with a specified probability over a specified period.
- [ ] Risk model prescribes maximum probability level which it can support.
- [ ] `vega` refuses to create a market if the specified probability level for price monitoring exceeds what the risk model specifies - to avoid spurious accuracy and runtime errors.
- [ ] `vega` switches trading mode from default based on the price monitoring signal.
- [ ] Mechanism for switching back to default trading mode is implemented.
- [ ] Order book is processed atomically so that the orders which directly moved the price beyond allowed band get processed again under the fallback trading mode (and no associated trades are generated in default trading mode).

# Summary

The dynamics of market price movements are such that prices don't always represent the participants' true average view of the price, but are instead artefacts of the market microstructure: sometimes low liquidity and/or a large quantity of order volume can cause the price to diverge from the true market price. It is impossible to tell at any point in time if this has happened or not.

As a result, we assume that relatively small moves are "real" and that larger moves might not be. Price monitoring exists to determine the real price in the latter case. Distinguishing between small and large moves can be highly subjective and market-dependent. We are going to rely on the risk model to formalise this process. Risk model can be used to obtain the probability distribution of prices at a future point in time given the current price. A price monitoring trigger can be constructed using a fixed horizon and probability level.
To give an example: get the price distribution in an hour as implied by the risk model given the current mid price, if after the hour has passed and the actual mid price is beyond (either too low or too high) what the model implied with some chosen probability level (say 99%), then we'd charaterise such market move as large.  In general we may want to use a few such triggers per market (i.e. different horizon and probability level pairs). The framework should be able to trigger a temporary period with any valid trading mode.

As mentioned above, price monitoring is meant to stop large market movements that are not "real" from occuring, rather than just detect them after the fact. To that end, it is necessary to pre-process every transaction in the current trading mode (e.g. continuous trading) and check if it triggers the price monitornig action. If pre-processing the transaction doesn't result in the trigger being activated then it should be "committed" by generating the associated events and modifying the order book accordingly (e.g. generate a trade and take the orders that matched off the book). On the other hand if the trigger is activated, the entire order book **along with that transaction** needs to be processed in a temporary auction mode. Once the auction period finishes the trading should return to the mode that was used prior to the trigger being hit.

Please see the [auction spec](https://github.com/vegaprotocol/product/blob/187-auction-spec/specs/0026-auctions.md) for details of the auction mode.

### Note

Price monitoring likely won't be the only possible trigger for changing the trading mode (liquidity monitoring - spec pending - or governance action could be the other ones). Thus the framework put in place as part of this spec should be flexible enough to easily accommodate other types of triggers.

Likewise, pre-processing transactions will be needed as part of the [fees spec](https://github.com/vegaprotocol/product/blob/WIP-fees-spec/specs/0029-fees.md), hence it should be implemented in such a way that it's easy to repurpose it.

# Guide-level explanation

- We need to emit a "significant price change" event if price move over the horizon τ turned out to be more than what the risk model implied at a probability level α.
  - Take current mid price S_t,
  - look-up value S_{t-τ} (prices aren't continuous so will need max(S_s : s  ≤ t-τ), call it  S_{t-τ}^*,
  - get the bounds associated with S_{t-τ}^* at a probability level α:
    - if S_t falls within those bounds then order book processing is carried out in the default trading mode,
    - otherwise the orders (if any) which resulted in the price change to S_t get reverted (see point below) and trading mode gets changed to the fallback one.
- We need to have "atomicity" in order processing:
  - When we process orders at t we need to check what the mark price would've been if we processed all of them (S_t).
  - If it results in "significant price change" event then we want the order book to maintain the state from before we started processing any orders.
  - Trading mode is then change to the fallback mode and orders are processed.
  - Market carries on in the suspended mode until trigger to switch back to deafult is received.
- In general we might have a list of pairs of α, τ.
  - In that case we take the most narrow interval implied by the above and compare the S_t against it.

# Reference-level explanation

## View from the [vega](https://github.com/vegaprotocol/vega) side

- at the end of the block:
  - pricing engine sends the risk model<sup>[1](#footnote1)</sup> the **LAST** ([![#f03c15](https://via.placeholder.com/15/f03c15/000000?text=+) `TODO (confirm): is this ok or do we need all/max)` mark price and a flag indicating if it was obtained via auction mode or not [![#f03c15](https://via.placeholder.com/15/f03c15/000000?text=+) `TODO (confirm): Do we care how the price was obtained?`]
  - risk model sends back the price bounds applicable for the next block
- during the block, if processing an order would've resulted in a trade at a price that breaches those bounds the market enters an auction mode (and that order is processed along with the other ones in that mode) [![#f03c15](https://via.placeholder.com/15/f03c15/000000?text=+) `TODO (confirm): what's the finest resolution that we care about - do we want to monitor all price within the block (WG: I think so as getting different outcomes depending how we slice the blocks doesn't seem desirable) or just the final price at the end of the block` ].
  - the market snaps out of the auction mode once the market clearing price is back within those bounds (either inside the block or in any of the ones that follow) ![#f03c15](https://via.placeholder.com/15/f03c15/000000?text=+) `TODO (confirm)`

## View from [quant](https://github.com/vegaprotocol/quant) library side<sup>[1](#myfootnote1)</sup>

- we get a mark price (unless we want more than one) from trading-core and a timestamp (accurate to say a few seconds).
- we can use that to build a time series (of required length) and can generate either (depending on which compontent we think should do the actual policing):
  - a signal that tolerance has been breached
  - a tolerance bound to be checked at a future timestamp
  - a tolerance bound to apply within the next block

### Notes

- we need a probability density function (p.d.f.) from the risk model and the inverse p.d.f.
- should generally handle a vector of pairs of horizons and probabilities
- Implement a cut-off on precision so we don’t return spuriously accurate results
- Think about caching the quant risk library calculations
- check tail estimates we get from prob models

# Test cases

See acceptance criteria.

<a name="footnote1">[1]: </a>Or perhaps another component that interfaces between the two.

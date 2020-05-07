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

There will be times when prices in our markets move by a large amount over a short period of time. While there's nothing wrong with that per se (it may simply be a result of new information being published and market reacting to that), we need to make sure that we minimise the impact of that on the stability of our markets as measured by their volatility and number of traders getting closed-out by the network. One way of achieving this is to put markets into auction mode during those periods as it has been shown that this can result in a more orderly incorporation of new information into the market price.

Another reason why this is important is the reliance on risk models for calculation of margin requirements for each trade and the fact that those margins are implied by the model's view of the range of prices that are possible in the near future with some specified probability level. To give an example, say the actual market move over last hour is larger than what our model was impling at the time, then the margins that were charged on positions that are still open may be insufficient to cover those moves for traders that were negatively impacted by them (if the margins haven't been updated over that time). To prevent that we need to be able to detect those moves as they occur and be able to change the trading mode on the fly.

To achieve the above we need to be able to check if processing the latest set of orders in market's default trading mode (e.g. continuous trading) would result in the "sensible" price level as implied by the risk model being breached. If that's not the case we need to be able to roll-back processing of those orders, switch to the fallback trading mode (e.g. auction mode) and process those, and any new, orders in that way.

![#f03c15](https://via.placeholder.com/15/f03c15/000000?text=+) `TODO (confirm): Once the market is in the fallback trading mode the mid-price will still be update as trading occurs (e.g. via auctions). Throughout this process the risk model will continue to provide projections and once the mid price falls back into the range projected for a given point in time the market will switch trading mode back to market's default.`

### Note

Price monitoring likely won't be the only possible trigger for changing the trading mode (liquidity monitoring - spec pending - or governance action could be the other ones). Thus the framework put in place as part of this spec should be flexible enough to easily accommodate other triggers and possibly different fallback modes (defined in the market configuration) per trigger.

# Guide-level explanation

- We need to emit a "significant price change" event if price move over the horizon τ turned out to be more than what the risk model implied at a probability level α.
  - Take current mid-price S_t,
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

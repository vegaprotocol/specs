Feature name: price-monitoring
Start date: 2020-04-29
Specification PR: https://github.com/vegaprotocol/product/pull/275

# Acceptance Criteria
**TODO**

# Summary
There will be times when prices in our markets move by a large amount over a short period of time. While there's nothing wrong with that per se (it may simply be a result of new information being published and market reacting to that), we need to make sure that we minimise the impact of that on the stability of our markets as measured by their volatility and number of traders getting closed-out by the network. One way of achieving this is to put markets into auction mode during those periods as it has been shown that this can result in a more orderly incorporation of new information into the market price.

Another reason why this is important is the reliance on risk models for calculation of margin requirements for each trade and the fact that those margins are implied by the model's view of the range of prices that are possible in the near future with some specified probability level. To give an example, say the actual market move over last hour is larger than what our model was impling at the time, then the margins that were charged on positions that are still open may be insufficient to cover those moves for traders that were negatively impacted by them (if the margins haven't been updated over that time). To prevent that we need to be able to detect those moves as they occur and be able to change the trading mode on the fly.

To achieve the above we need to be able to check if processing the latest set of orders in market's default trading mode (e.g. continous trading) would result in the "sensible" price level as implied by the risk model being breached. If that's the case we need to be able to roll-back processing of those orders, switch to the fallback trading mode (e.g. auction mode) and process those orders in that way. 

**TODO**: outline how would we switch back to deafault trading.


# Guide-level explanation

- We need to emit a "significant price change" event if price move over the horizon τ turned out to be more more than what the risk model implied at a probability level α.
    - Take current value, S_t
    - look-up value S_(t-τ) (prices aren't continuous so will need max(S_s : s  ≤ t-τ), call it  S_(t-τ)^*
     - Feed S_t and S_(t-τ)^*, τ, α into the risk model get boolean indicating if the price move breached the levels implied by it.
    - In general we might have a list of pairs of α, τ.
- We need to have "atomicity" in order processing:
    - When we process orders at t we need to check what the mark price would've been if we processed all of them (S_t).
    - If is results in "significant price change" event then we want the order book to maintain the state from before we started processing any orders

# Reference-level explanation

- Notes:
    - we need a probability density function (p.d.f.) from the risk model and the inverse p.d.f.
    - vector of pairs of horizons and probabilities
    - take 2 values from risk model for say 1% move up and move down
    - Implement a cut-off on precision so we don’t return spuriously accurate results
    - Think about caching the quant risk library calculations
    - check tail estimates we get from prob models

- View from the `vega` side:
    - at the end of the block:
        - pricing engine sends the risk model the **LAST** (is this ok or do we need all) mark price and a flag indicating if it was obtained via auction mode or not [DO WE CARE ABOUT THIS LAST BIT? CHECK WITH DAVID]
        - risk model sends back the price bounds applicable for the next block
    - during the block, if processing an order would've resulted in a trade at a price that breaches those bounds the market enters an auction mode (and that order is processed along with the other ones in that mode).
    - the market snaps out of the auction mode once the mark price is back within those bounds (either inside the block or in any of the ones that follow) [CHECK WITH DAVID]
- View from `quant` library side (or perhaps another component that interfaces between the two):
    - we get a mark price (unless we want more than one) from trading-core and a timestamp (accurate to say a few seconds).
    - we can use that to build a time series (of required length) and can generate either:
        - a signal that tolerance has been breached
        - a tolerance bound to be checked at a future timestamp
        - a tolerance bound to apply within the next block

# Pseudo-code / Examples
**TODO**

# Test cases
**TODO**
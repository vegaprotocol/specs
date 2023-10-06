# Position resolution

## Acceptance Criteria

- All orders of "distressed traders" are cancelled (<a name="0012-POSR-001" href="#0012-POSR-001">0012-POSR-001</a>)
- Open positions of distressed traders are closed (<a name="0012-POSR-002" href="#0012-POSR-002">0012-POSR-002</a>)
- One market order is submitted for the net liability (<a name="0012-POSR-003" href="#0012-POSR-003">0012-POSR-003</a>)
- Mark Price is never updated during position resolution (<a name="0012-POSR-004" href="#0012-POSR-004">0012-POSR-004</a>)
- Non-distressed traders who trade with the network because their open orders are hit during the close out trade have their positions settled correctly. (<a name="0012-POSR-005" href="#0012-POSR-005">0012-POSR-005</a>)
- When a distressed party has a [staking account](./0013-ACCT-accounts.md) with the same currency as the settlement currency of the market where it's distressed the staking account is NOT used in margin search and liquidation. (<a name="0012-POSR-006" href="#0012-POSR-006">0012-POSR-006</a>)
- When a party is distressed at the point of leaving an auction it should get closed out as soon as the market returns to continuous trading mode and all the parked orders (pegged and LP) get added back to the order book. (<a name="0012-POSR-008" href="#0012-POSR-008">0012-POSR-008</a>)

## Summary

Position resolution is the mechanism which deals with closing out distressed positions on a given market. It is instigated when one or more participant's margin account balance falls below their latest maintenance margin level.

## Guide-level explanation

## Reference-level explanation

Any trader that has insufficient collateral to cover their margin liability is referred to as a "distressed trader".

### Position resolution algorithm

#### Marking party as distressed

Each time a balance is transferred out of party's margin account for a given market the remaining balance should be compared against the last known maintenance margin for the party (no need to recalculate it). If the resulting balance is below the maintenance margin then party should be marked as distressed in the market being considered.

Each time either a mark price is updated or when a party submits, amends or cancels an order, or when an existing passive order fills, the maintenance margin for the party should be recalculated and additional margin should be searched for in the party's general account if needed and if the margining mode allows it. If after that the balance of party's margin account is less than the updated maintenance margin the party should be marked as distressed. If it's equal to or above the maintenance margin then party should not be marked as being distressed, even if it was previously the case.

When a party is marked as distressed it cannot submit or amend any of its orders in the market in which it's been marked as distressed, it can only cancel the existing orders in that market. Margin is never released from the margin account whilst party is marked as distressed. Being marked as distressed doesn't limit party's actions in any other market, even if such market uses the same settlement asset and party is using cross-margaining mode in both of the them.

#### Liquidating distressed party's position in a market

- There is a market parameter `market.positionResolutionFrequency` controlling the maximum (the observed frequency may be slightly lower depending on block time) frequency of position resolution evaluations which needs to be specified when proposing a new market and can be updated any time as long as the market is not in a closed, terminated or settled [state](./0043-MKTL-market_lifecycle.md#market-lifecycle-statuses). The update takes effect immediately (if the paramer is decreased then the next position resolution evaluation time may happen sooner than it would've had the old parameter value been kept).

- Position resolution evaluation is never carried out during an auction. Leaving auction of any type (including opening auction) triggers position resolution evaluation and restarts the timer. Subsequent evaluations are triggered once the elapsed time since last evaluation is greater than `market.positionResolutionFrequency` or when market exits some other auction (whichever comes first).

- If position resolution evaluation happens in the same block as the mark price is updated and/or margin levels are re-evaluated then it should happen as last of the three operations.

- If a party marked as distressed has the cross marginging mode selected for the market being considered:

  - all their open orders on that market get cancelled without releasing any collateral from the margin account,
  - their margin level then gets recalculated to account only for the open volume they hold in a market (TODO: if we generalised Tom's notion of an "order margin" for the isolated margin mode to all margin modes then this step would be redundant)  
  - if party's margin account balance is now above or equal to their latest maintenance margin level then such party is no longer marked as "distressed".

- If party's is marked as distressed then:

  - their open volume get's added to network's open volume for that market,
  - party's open volume in that market gets set to 0,
  - the full amount of party's margin account balance gets transferred to market's insurance pool.

This concludes the position resolution from party's perspective.

#### Managing network's position

Whilst network has a non-zero position in a given market it's treated as any other party with market's insurance in that market acting as its margin account and with and exception that margin search, margin release or liquidation are never attempted on a network party.

Whenever the network party has a non-zero position it attempts to unload it using an [immediate or cancel](./0014-ORDT-order_types.md) limit order. If the the network has a `long` position it will submit a `sell` order. If it has a short position it will submit a buy order. The size of that order is chosen according to the liquidation strategy which forms a part of the marke's configuration. The strategy can be updated at any point whilst market is active with a market change [governance vote](./0028-GOVE-governance.md#2-change-market-parameters).

The liquidation strategy consists of:

- `disposal time step` (mandatory, e.g. `n=10s`): network attempts to unload its position in a given market every time it goes out of auction and then every `n` seconds as long as market is not in auction mode and while the network's position is not equal to `0`,
- `disposal fraction` (e.g. `0.1`): fraction of networks current open volume that it will try to reduce in a single disposal attempt,
- `full disposal size` (e.g. `20`): once net absolute value of network's open volume is at or below that value, the network will attempt to dispose the remaining amount in one go,
- `max fraction of book side within liquidity bounds consumed` (e.g. `m=0.05`): once the network chooses the size of its order (`s_candidate`) the effective size will be calcualted as `s_effective=min(m*N, s_candidate)`, where `N` is the sum of volume (on the side of the book with which the network's order will be matching) that falls within the range implied by the `market.liquidity.priceRange` [parameter](./0044-LIME-lp_mechanics.md#market-parameters),
- `try on next block if trade unsuccessful` (e.g. `true`): if after the network forms and submits its IOC order the resulting trade volume is `0` it will try to reform and resubmit the order in subsequent blocks until it successfully achieves a trade of any size, once the next disposal time step anniversary is reached no further attempts are made and process starts from scratch.

Assume the price range implied by the `market.liquidity.priceRange` is `[a, b]`. Once the network has worked out a size of its immediate or cancel limit order it sets it's price to `a` if it's a sell order or `b` if it's a buy order, and it submits the order.

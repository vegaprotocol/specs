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

#### Liquidating distressed party's position in a market

- Position resolution evaluation gets carried out each time the mark price is update, strictly after the margin levels margin level update and mark-to-market settlement.

- During position resolution evaluation party's margin account balance is compared to it's latest maintenance margin level. If the account balance is below the margin level then the party gets marked as distressed.

- If a party marked as "distressed" has the cross marginging mode selected for the market being considered:

  - all their open orders on that market get cancelled without releasing any collateral from the margin account,
  - their margin level then gets recalculated to account only for the open volume they hold in a market
  - if party's margin account balance is now above or equal to their latest maintenance margin level then such party is no longer marked as "distressed".

- If party's is marked as "distressed" at this stage then:

  - their open volume get's added to network's open volume for that market,
  - party's open volume in that market gets set to 0,
  - the full amount of party's margin account balance gets transferred to market's insurance pool.

This concludes the position resolution from party's perspective.

#### Managing network's position

Whilst network has a non-zero position in a given market it's treated as any other party with market's insurance in that market acting as its margin account and with and exception that margin search, margin release or liquidation are never attempted on a network party.

Whenever the network party has a non-zero position it attempts to unload it using an [immediate or cancel](./0014-ORDT-order_types.md) limit order. If the the network has a `long` position it will submit a `sell` order. If it has a short position it will submit a buy order. The size of that order is chosen according to the liquidation strategy which forms a part of the marke's configuration. The strategy can be updated at any point whilst market is active with a market change [governance vote](./0028-GOVE-governance.md#2-change-market-parameters).

Currently only one liquidation strategy is supported and its defined by the following parameters:

- `disposal time step` (min: `1s`, max: `1h`, default: `10s`): network attempts to unload its position in a given market every time it goes out of auction and then every `n` seconds as long as market is not in auction mode and while the network's position is not equal to `0`,
- `disposal fraction` (min: `0,01`, max: `1`, default: `0.1`): fraction of network's current open volume that it will try to reduce in a single disposal attempt,
- `full disposal size` (min: `0`, max: `max int`, default: `20`): once net absolute value of network's open volume is at or below that value, the network will attempt to dispose the remaining amount in one go,
- `max fraction of book side within liquidity bounds consumed` (min: `0`, max: `1`, default: `0.05`): once the network chooses the size of its order (`s_candidate`) the effective size will be calcualted as `s_effective=min(m*N, s_candidate)`, where `N` is the sum of volume (on the side of the book with which the network's order will be matching) that falls within the range implied by the `market.liquidity.priceRange` [parameter](./0044-LIME-lp_mechanics.md#market-parameters),

Assume the price range implied by the `market.liquidity.priceRange` is `[a, b]`. Once the network has worked out a size of its immediate or cancel limit order it sets it's price to `a` if it's a sell order or `b` if it's a buy order, and it submits the order.

Note that different liquidation strategies with different parameters might be proposed in the future, hence implementation should allow for easy substitution of strategies.

API requirements:

- create an endpoint to easily identify network's position in any given market,
- create an endpoint to easily identify network's margin levels in any given market,
- create an endpoint to easily check time of next liquidation trade attempt.

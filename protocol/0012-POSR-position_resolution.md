# Position resolution

## Acceptance Criteria

- All orders of "distressed traders" in cross-margin mode are cancelled (<a name="0012-POSR-001" href="#0012-POSR-001">0012-POSR-001</a>)
- Open positions of distressed traders are closed immediately (<a name="0012-POSR-002" href="#0012-POSR-002">0012-POSR-002</a>)
- Mark Price is never updated during position resolution (<a name="0012-POSR-004" href="#0012-POSR-004">0012-POSR-004</a>)
- Non-distressed traders who trade with the network because their open orders are hit during the networks' trade have their positions settled correctly. (<a name="0012-POSR-005" href="#0012-POSR-005">0012-POSR-005</a>)
- When a distressed party has a [staking account](./0013-ACCT-accounts.md) with the same currency as the settlement currency of the market where it's distressed the staking account is NOT used in margin search and liquidation. (<a name="0012-POSR-006" href="#0012-POSR-006">0012-POSR-006</a>)
- When a party is distressed and gets closed out the network's position gets modified to reflect that it's now the network party that holds that volume. (<a name="0012-POSR-009" href="#0012-POSR-009">0012-POSR-009</a>)

- When the network party holds a non-zero position and there are not enough funds in market's insurance pool to meet the mark-to-market payment the network's position is unaffected and loss socialisation is applied. (<a name="0012-POSR-010" href="#0012-POSR-010">0012-POSR-010</a>)

- When the network party holds a non-zero position and the market's insurance pool balance is below the network party's maintenance margin for that market the network's position in that market remains unaffected. (<a name="0012-POSR-011" href="#0012-POSR-011">0012-POSR-011</a>)

- The liquidation strategy can be updated using the market update transaction  (<a name="0012-POSR-012" href="#0012-POSR-012">0012-POSR-012</a>)

- When the market is configured to use:
  - `disposal time step` = `10s`,
  - `disposal fraction` =  `0.5`,
  - `full disposal size` = `50`,
  - `max fraction of book side within liquidity bounds consumed` = `0.01`

  and the volume on the buy side of the book within the liquidity bounds is always `10,000` (as volume on the book gets filled new orders get placed) then liquidating a distressed party with an open volume of `280` results in 4 network trades in total spaced `10s` apart with volumes of: `100`, `90`, `45`, `45`.  (<a name="0012-POSR-013" href="#0012-POSR-013">0012-POSR-013</a>)

- It is possible to check the network party's open volume and margin level in any market via the API. (<a name="0012-POSR-014" href="#0012-POSR-014">0012-POSR-014</a>)

- It is possible to check the time of the next liquidation trade attempt in any market via the API. (<a name="0012-POSR-015" href="#0012-POSR-015">0012-POSR-015</a>)

## Summary

Position resolution is the mechanism which deals with closing out distressed positions on a given market. It is instigated when one or more participant's margin account balance falls below their latest maintenance margin level.

## Guide-level explanation

## Reference-level explanation

Any trader that has insufficient collateral to cover their margin liability is referred to as a "distressed trader".

### Position resolution algorithm

#### Liquidating distressed party's position in a market

- Position resolution evaluation gets carried out each time the mark price is updated, strictly after the margin levels margin level update and mark-to-market settlement.

- During position resolution evaluation party's margin account balance is compared to it's latest maintenance margin level. If the account balance is below the margin level then the party gets marked as distressed.

- If a party marked as "distressed" has the cross-margin mode selected for the market being considered:

  - all their open orders on that market get cancelled without releasing any collateral from the margin account,
  - their margin level then gets recalculated to account only for the open volume they hold in a market
  - if party's margin account balance is now above or equal to their latest maintenance margin level then such party is no longer marked as "distressed".

- If party's is marked as "distressed" at this stage then:

  - their open volume gets added to network's open volume for that market,
  - party's open volume in that market gets set to 0,
  - the full amount of party's margin account balance gets transferred to market's insurance pool.

This concludes the position resolution from party's perspective.

#### Managing network's position

Whilst network has a non-zero position in a given market it's treated as any other party with market's insurance in that market acting as its margin account and with and exception that margin search, margin release or liquidation are never attempted on a network party.

Whenever the network party has a non-zero position it attempts to unload it using an [immediate or cancel](./0014-ORDT-order_types.md) limit order. If the the network has a `long` position it will submit a `sell` order. If it has a short position it will submit a buy order. The size of that order is chosen according to the liquidation strategy which forms a part of the market's configuration. The strategy can be updated at any point whilst market is active with a market change [governance vote](./0028-GOVE-governance.md#2-change-market-parameters).

Currently only one liquidation strategy is supported and its defined by the following parameters:

- `disposal time step` (min: `1s`, max: `1h`): network attempts to unload its position in a given market every time it goes out of auction and then every `disposal time step` seconds as long as market is not in auction mode and while the network's position is not equal to `0`,
- `disposal fraction` (min: `0.01`, max: `1`): fraction of network's current open volume that it will try to reduce in a single disposal attempt,
- `full disposal size` (min: `0`, max: `max int`): once net absolute value of network's open volume is at or below that value, the network will attempt to dispose the remaining amount in one go,
- `max fraction of book side within liquidity bounds consumed` (min: `0`, max: `1`): once the network chooses the size of its order (`s_candidate`) the effective size will be calculated as `s_effective=min(m*N, s_candidate)`, where `N` is the sum of volume (on the side of the book with which the network's order will be matching) that falls within the range implied by the `market.liquidity.priceRange` [parameter](./0044-LIME-lp_mechanics.md#market-parameters) and `m` is the `max fraction of book side within liquidity bounds consumed`.

Assume the price range implied by the `market.liquidity.priceRange` is `[a, b]`. Once the network has worked out a size of its immediate or cancel limit order it sets it's price to `a` if it's a sell order or `b` if it's a buy order, and it submits the order.

Note that setting:

- `disposal time step` = `0s`,
- `disposal fraction` = `1`,
- `full disposal size` = `max int`,
- `max fraction of book side within liquidity bounds consumed` = `1`

is closest to reproducing the legacy setup where party would get liquidated immediately (with a difference that closeout now happens immediately even if there's not enough volume on the book to fully absorb it) hence the above values should be used when migrating existing markets to a new version. For all new markets these values should be specified explicitly.

Different liquidation strategies with different parameters might be proposed in the future, hence implementation should allow for easy substitution of strategies.

API requirements:

- create an endpoint to easily identify network's position in any given market,
- create an endpoint to easily identify network's margin levels in any given market,
- create an endpoint to easily check time of next liquidation trade attempt.

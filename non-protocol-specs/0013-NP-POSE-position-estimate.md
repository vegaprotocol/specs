# Position estimate

## Summary

Protocol provides an API endpoint which can estimate the following aspects of a theoretical position (open volume and open orders):

- margin levels,
- expected collateral increase required to support the position,
- liquidation price.

Each estimate is a range between a relevant figure obtained with the assumption of no slippage and maximum slippage configured for the market.

## Details

The endpoint does not access information related to any of the existing positions, it's based entirely on the information specified in the request.
The endpoint only distinguishes between market orders (these are assumed to fill instantly and in full at a current mark price) and limit orders (these are assumed to fill in full once mark price reaches their limit price).

### Margin level

Margin level estimate contains the levels specified in [0019-MCAL-margin_calculator](./../protocol/0019-MCAL-margin_calculator.md#reference-level-explanation) spec as well margin mode and margin factor (0 in cross margin mode).

### Collateral increase estimate

Collateral increase estimate provides an approximate amount of the additional funds above the specified margin and order margin account level balances required.

In cross-margin mode it's the difference between the initial margin level estimate for the specified position and the margin account balance specified in the request.

In isolated margin mode it's the difference between collateral required to support the specified position and orders with the margin factor provided and the balance of margin and order margin accounts specified in the request.

Collateral increase estimate is always floored at 0, it only tries to estimate the increase in the collateral request, not the potential collateral release amount. If the request is made such that the account balances specified are equal to or greater than the required margin then 0 is returned.

### Liquidation price estimate

Liquidation price estimate as specified in [0012-NP-LIPE-liquidation-price-estimate](./0012-NP-LIPE-liquidation-price-estimate.md).

Depending on the [margining mode](../protocol/0019-MCAL-margin_calculator.md#margining-modes) selected by the party for the market on which its position is being considered the $\text{collateral available}$ will differ.

Cross-margin mode: $\text{collateral available} = \text{margin account balance} + \text{general account balance} + \text{order margin account balance}$.

Isolated margin mode: $\text{collateral available} = \text{margin account balance}$.

The position estimate request has an additional `include_collateral_increase_in_available_collateral` argument. It's relevant for the isolated margin mode: when set to `false` the collateral available used in liquidation price estimate will be the margin account balance only. When set to `true` the portion of the collateral increase estimated for the specified position only (not for the additional orders) will also be included in the available collateral.

The endpoint request contains additional optional argument `scale_liquidation_price_to_market_decimals`. When set to `false` the liquidation price estimates are scaled to asset decimal places, when set to `true` these estimates are scaled to market decimal places.

## Acceptance criteria

1. In isolated margin mode the request with `0` open volume and one or more limit orders specified results in a non-zero order margin in the margin level estimate and margin mode correctly representing isolated margin mode. (<a name="0013-NP-POSE-001" href="#0013-NP-POSE-001">0013-NP-POSE-001</a>)
1. When account balances are set to `0` and market has slippage factors set to `0`, the collateral increase figure per specified theoretical position correctly approximates (absolute relative difference of less than $10^{-6}$) the actual margin and order margin account balances for a party which opens such a position. (<a name="0013-NP-POSE-002" href="#0013-NP-POSE-002">0013-NP-POSE-002</a>)
1. When response for a given request contains figure `x` as the collateral increase best case then resubmitting the request with margin account balance increased by `x` should result in `0` collateral increase estimate for the best case. When increasing the margin account balance in the request further the collateral increase should remain at `0`. Same should be true when the above is repeated for the worst case. (<a name="0013-NP-POSE-003" href="#0013-NP-POSE-003">0013-NP-POSE-003</a>)
1. In isolated margin mode increasing general account balance specified in the request has no impact on the collateral increase estimate and the liquidation price estimate. (<a name="0013-NP-POSE-004" href="#0013-NP-POSE-004">0013-NP-POSE-004</a>)
1. In isolated margin mode the liquidation price estimate for a position with non-zero additional margin requirement with `include_collateral_increase_in_available_collateral` argument set to `true` results in liquidation price which is closer to the current mark price than the result obtained with argument set to `false`. (<a name="0013-NP-POSE-005" href="#0013-NP-POSE-005">0013-NP-POSE-005</a>)
1. When market is set with different number of decimal places then its settlement asset then setting `scale_liquidation_price_to_market_decimals` to `false` results in liquidation price estimates scaled to asset decimal places, when set to `true` these estimates get scaled to market decimal places. (<a name="0013-NP-POSE-006" href="#0013-NP-POSE-006">0013-NP-POSE-006</a>)
1. The estimates for open volume of `1` and no orders are the same as those for open volume of `0` and a single buy market order of size `1`. (<a name="0013-NP-POSE-007" href="#0013-NP-POSE-007">0013-NP-POSE-007</a>)
1. The estimates for open volume of `-1` and no orders are the same as those for open volume of `0` and a single sell market order of size `1`. (<a name="0013-NP-POSE-008" href="#0013-NP-POSE-008">0013-NP-POSE-008</a>)

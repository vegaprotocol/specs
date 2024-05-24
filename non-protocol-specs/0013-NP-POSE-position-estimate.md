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

Collateral increase estimate provides an approximate difference between the current collateral and the resulting collateral for the specified theoretical position.

In isolated margin mode it's the difference between collateral required to support the specified position and orders with the margin factor provided and the balance of margin and order margin accounts specified in the request.

In cross-margin mode:

- if the collateral required for the specified position is higher than the combined margin and order margin account balances then it's the difference between the initial margin level for the specified position and the sum of those account balances.
- if the collateral required for the specified position is lower than the combined margin and order margin account balances then:
  - if the combined account balances are above the margin release level for the specified position: it's the difference between the initial margin level for the specified position and the sum of those account balances,
  - otherwise it's `0`.

### Liquidation price estimate

Liquidation price estimate as specified in [0012-NP-LIPE-liquidation-price-estimate](./0012-NP-LIPE-liquidation-price-estimate.md).

Depending on the [margining mode](../protocol/0019-MCAL-margin_calculator.md#margining-modes) selected by the party for the market on which its position is being considered the $\text{collateral available}$ will differ.

Cross-margin mode: $\text{collateral available} = \text{margin account balance} + \text{general account balance} + \text{order margin account balance}$.

Isolated margin mode: $\text{collateral available} = \text{margin account balance}$.

The position estimate request has an additional `include_collateral_increase_in_available_collateral` argument. It's relevant for the isolated margin mode: when set to `false` the collateral available used in liquidation price estimate will be the margin account balance only. When set to `true` the portion of the collateral increase estimated for the specified position only (not for the additional orders) will also be included in the available collateral.

The endpoint request contains additional optional argument `scale_liquidation_price_to_market_decimals`. When set to `false` the liquidation price estimates are scaled to asset decimal places, when set to `true` these estimates are scaled to market decimal places.

### Price cap

When a price cap is specified it should be assumed that the estimate is to be provided for a [capped futures](./../protocol/0016-PFUT-product_builtin_future.md#1-product-parameters) market. The liquidation price estimate should not be returned in that case and margin levels as well collateral increase estimate should be as per fully-collateralised margin [spec](./../protocol/0019-MCAL-margin_calculator.md#fully-collateralised).

## Acceptance criteria

1. In isolated margin mode the request with `0` open volume and one or more limit orders specified results in a non-zero order margin in the margin level estimate and margin mode correctly representing isolated margin mode. (<a name="0013-NP-POSE-001" href="#0013-NP-POSE-001">0013-NP-POSE-001</a>)
1. When account balances are set to `0` and market has slippage factors set to `0`, the collateral increase figure per specified theoretical position correctly approximates (absolute relative difference of less than $10^{-6}$) the actual margin and order margin account balances for a party which opens such a position. (<a name="0013-NP-POSE-002" href="#0013-NP-POSE-002">0013-NP-POSE-002</a>)
1. In cross margin-mode, for a market with slippage cap factor set to `0`, the request to `EstimatePosition` endpoint is made with margin account balance set to less than the initial margin for the specified position, when the response for a given request contains figure `x` as the collateral increase (best and worst case should be the same) then resubmitting the request with margin account balance increased by `x` should result in `0` collateral increase estimate. When increasing the margin account balance in the request further it should remain at `0` until the combined margin and order balances are above the margin release level for the theoretical position. Then the collateral increase amount should be negative and equal to: `initial margin level for the specified position - margin account balance - order account balance`. (<a name="0013-NP-POSE-009" href="#0013-NP-POSE-009">0013-NP-POSE-009</a>)
1. In isolated margin mode: open a position so that open volume is non-zero and there are some open orders. Query the `EstimatePosition` with the details of that position. The collateral increase estimate should be 0. No query the `EstimatePosition` with a higher margin factor. The collateral increase estimate should be positive and equal to the decrease in the general account balance after margin factor is updated for the party. Now lower the margin factor below the value the test originally started with and repeat. The collateral increase estimate should be negative and equal to the decrease in the general account balance (the balance should increase). (<a name="0013-NP-POSE-010" href="#0013-NP-POSE-010">0013-NP-POSE-010</a>)
1. In isolated margin mode increasing general account balance specified in the request has no impact on the collateral increase estimate and the liquidation price estimate. (<a name="0013-NP-POSE-004" href="#0013-NP-POSE-004">0013-NP-POSE-004</a>)
1. In isolated margin mode the liquidation price estimate for a position with non-zero additional margin requirement with `include_collateral_increase_in_available_collateral` argument set to `true` results in liquidation price which is closer to the current mark price than the result obtained with argument set to `false`. (<a name="0013-NP-POSE-005" href="#0013-NP-POSE-005">0013-NP-POSE-005</a>)
1. When market is set with different number of decimal places then its settlement asset then setting `scale_liquidation_price_to_market_decimals` to `false` results in liquidation price estimates scaled to asset decimal places, when set to `true` these estimates get scaled to market decimal places. (<a name="0013-NP-POSE-006" href="#0013-NP-POSE-006">0013-NP-POSE-006</a>)
1. The estimates for open volume of `1` and no orders are the same as those for open volume of `0` and a single buy market order of size `1`. (<a name="0013-NP-POSE-007" href="#0013-NP-POSE-007">0013-NP-POSE-007</a>)
1. The estimates for open volume of `-1` and no orders are the same as those for open volume of `0` and a single sell market order of size `1`. (<a name="0013-NP-POSE-008" href="#0013-NP-POSE-008">0013-NP-POSE-008</a>)

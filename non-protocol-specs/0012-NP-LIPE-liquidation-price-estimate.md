# Liquidation price estimate

## Summary

Provide an estimate of the price range at which the liquidation of a specified position is likely to occur.

## Overview

Provide an estimated liquidation price range, where the lower bound assumes no slippage in the [margin level calculation](../protocol/0019-MCAL-margin_calculator.md) and the upper bound assumes that the slippage cap is applied.

This amounts to carrying out the same computation twice, once with slippage factor set to `0` and once with the actual value used by the market for which the specified position is being considered.

The system carries out [position resolution](../protocol/0012-POSR-position_resolution.md) when the available collateral (amount in margin account for the market along with amount in the general account denominated in the same asset) is less than the maintenance margin level for the position. The first step is to cancel any open orders that a distressed party may have. After that the margin requirement is re-evaluated to see if the position is still distressed. Therefore we provide three sets of estimates of a liquidation price range: current open volume only, current open volume with active buy orders, current open volume with active sell orders.

## Calculation

### Position only

We start with the case which estimates the liquidation price given the current open volume and ignoring any orders a party may have. We need to keep in mind that as the mark price moves the maintenance margin changes and the collateral available a party has changes due to [mark to market](../protocol/0003-MTMK-mark_to_market_settlement.md) gains/losses. Therefore, to estimate the liquidation price we need to find $S^{\text{liquidation}}$ such that:

$$
\text{collateral available} + V(S^{\text{liquidation}}-S^{\text{current}}) = \text{maintenance margin}(S^{\text{liquidation}}),
$$

where $V$ is the open volume (negative for a short position) and $S^\text{current}$ is the current mark price.

We assume margin is calculated as per continuous trading formula (as there are no closeouts in auctions) and that the slippage cap always applies, therefore we get:

$$
\text{collateral available} + V(S^{\text{liquidation}}-S^\text{current}) = S^{\text{liquidation}} (\abs{V} \cdot \text{linear slippage factor}+\abs{V} \cdot \text{risk factor}) + V \cdot \text{constant},
$$

where $\text{risk factor}$ is the long risk factor when $V>0$ and the short risk factor otherwise. The $\text{constant}$ is an optional arbitrary constant scaling with open volume added to the maintenance margin, e.g. the funding payment portion of the margin for [perpetual futures](../protocol/0053-PERP-product_builtin_perpetual_future.md#5-margin-considerations). Solving for $S^{\text{liquidation}}$ we get:

$$
S^{\text{liquidation}} = \frac{\text{collateral available}-V \cdot S^\text{current} - V \cdot \text{constant}}{\abs{V} \cdot \text{linear slippage factor}+\abs{V} \cdot \text{risk factor}-V}
$$

if the denominator in the above expression evaluates to $0$ the liquidation price is undefined and we return an error, otherwise we return the result floored at $0$ (as the negative price is not attainable for any of the currently supported products).

### Including orders

When including orders we sort the orders in the order they will get filled in (descending for buy orders, ascending for sell orders) and assume any market orders get filled instantaneously at the current mark price. Then separately for each side:

- Calculate open volume with including the remaining volume of all the market orders for a given side ($V$) and calculate the liquidation price ($S^{\text{liquidation}}$) using the formula outlined above and the current mark price or indicative uncrossing price if market is in auction ($S^{\text{current}}$).
- For each limit order:
  - if the order price ($S^{\text{order}}$) is above (buy side) / below (sell side) the liquidation price ($S^{\text{liquidation}}$):
    - recalculate $V$ to include the order's remaining volume (assumes order gets filled as soon as its price level is filled),
    - update $\text{collateral available}$ to include the MTM gains/losses: $V(S^{\text{order}}-S^{\text{current}})$,
    - update $S^{\text{current}}$ to equal $S^{\text{order}}$,
  - otherwise return last calculated $S^{\text{liquidation}}$ (assumes other orders will get cancelled and the remaining position will be liquidated).

### Acceptance criteria

1. An estimate is obtained for a long position with no open orders, mark price keeps going down in small increments and the actual liquidation takes place within the estimated range. (<a name="0012-NP-LIPE-001" href="#0012-NP-LIPE-001">0012-NP-LIPE-001</a>)
1. An estimate is obtained for a short position with no open orders, mark price keeps going up in small increments and the actual liquidation takes place within the estimated range. (<a name="0012-NP-LIPE-002" href="#0012-NP-LIPE-002">0012-NP-LIPE-002</a>)
1. An estimate is obtained for a position with no open volume and a single limit buy order, after the order fills the mark price keeps going down in small increments and the actual liquidation takes place within the obtained estimated range. (<a name="0012-NP-LIPE-003" href="#0012-NP-LIPE-003">0012-NP-LIPE-003</a>)
1. An estimate for cross-margin mode with `include_collateral_increase_in_available_collateral` set to `true` is obtained for a long position with multiple limit sell orders with the absolute value of the total remaining size of the orders less than the open volume. The estimated liquidation price with sell orders is lower than that for the open volume only. As the limit orders get filled the estimated liquidation price for the (updated) open volume converges to the estimate originally obtained with open sell orders. (<a name="0012-NP-LIPE-004" href="#0012-NP-LIPE-004">0012-NP-LIPE-004</a>)
1. An estimate for cross-margin mode with `include_collateral_increase_in_available_collateral` set to `true` is obtained for a short position with multiple limit buy orders with the absolute value of the total remaining size of the orders less than the open volume. The estimated liquidation price with buy orders is higher than that for the open volume only. As the limit orders get filled the estimated liquidation price for the (updated) open volume converges to the estimate originally obtained with open buy orders. As the price keeps moving in small increments the liquidation happens within the originally estimated range (with buy orders) (<a name="0012-NP-LIPE-005" href="#0012-NP-LIPE-005">0012-NP-LIPE-005</a>)
1. There's no difference in the estimate for an open volume (use `open_volume_only` field) and that with `0` open volume and market order of the same size (use `including_buy_orders` or `including_sell_orders` depending on the order side). (<a name="0012-NP-LIPE-006" href="#0012-NP-LIPE-006">0012-NP-LIPE-006</a>)
1. When margining mode gets successfully changed to isolated margin mode and party has non-zero general account balance afterwards than its liquidation price estimate for all cases (position only, with buy orders, with sell orders) moves closer to the current mark price (compared to cross-margin figure). (<a name="0012-NP-LIPE-007" href="#0012-NP-LIPE-007">0012-NP-LIPE-007</a>)
1. An estimate for isolated margin mode with `include_collateral_increase_in_available_collateral` set to `true` is obtained for a short position with open sell orders. As the price keeps moving in small increments the liquidation happens within the originally estimated range (`open_volume_only` estimate). The sell orders and order margin account balance remain unchanged. (<a name="0012-NP-LIPE-008" href="#0012-NP-LIPE-008">0012-NP-LIPE-008</a>)
1. An estimate for isolated margin mode with `include_collateral_increase_in_available_collateral` set to `true` is obtained for a long position with open buy orders. As the price keeps moving in small increments the liquidation happens within the originally estimated range (`open_volume_only` estimate). The buy orders and order margin account balance remain unchanged. (<a name="0012-NP-LIPE-009" href="#0012-NP-LIPE-009">0012-NP-LIPE-009</a>)

# Liquidation price estimate

## Summary

Provide an estimate of the price range at which the liquidation of a specified position is likely to occur.

## Overview

Provide a range of liquidation price, where the lower bound assumes no slippage in the [margin level calculation](../protocol/0019-MCAL-margin_calculator.md) and the upper bound assumes that the slippage cap is applied.

This amounts to carrying out the same computation twice, once with both linear and quadratic slippage factor set to `0` and once with the actual values used by the market for which the specified position is being considered.

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
\text{collateral available} + V(S^{\text{liquidation}}-S^\text{current}) = S^{\text{liquidation}} (V \cdot \text{linear slippage factor}+V^2 \cdot \text{quadratic slippage factor}+V \cdot \text{risk factor}),
$$

where $\text{risk factor}$ is the long risk factor when $V>0$ and the short risk factor otherwise. Solving for $S^{\text{liquidation}}$ we get:

$$
S^{\text{liquidation}} = \frac{\text{collateral available}-V \cdot S^\text{current}}{V \cdot \text{linear slippage factor}+V^2 \cdot \text{quadratic slippage factor}+V \cdot \text{risk factor}-V}
$$

if the denominator in the above expression evaluates to $0$ the liquidation price is undefined and we return an error, otherwise we return the result floored at $0$ (as the negative price is not attainable for any of the currently supported products).

### Including orders

When including orders we sort the orders in the order they will get filled in (descending for buy orders, ascending for sell orders) and assume any market orders get filled instantaneously at the current mark price. Then separately for each side:

- Calculate open volume with including the remaining volume of all the market orders for a given side ($V$) and calculate the liquidation price ($S^{\text{liquidation}}$) using the formula outlined above and the current mark price or indicative uncrossing price if market is in auction ($S^{\text{current}}$).
- For each limit order:
  - if the order price ($S^{\text{order}}$) is above (buy side) / below (sell side) ($S^{\text{liquidation}}$):
    - recalculate $V$ to include the order's remaining volume (assumes order gets filled as soon as its price level is filled),
    - update $\text{collateral available}$ to include the MTM gains/losses:  $V(S^{\text{order}}-S^{\text{current}})$,
    - update $S^{\text{current}}$ to equal $S^{\text{order}}$,
  - otherwise return last calculated $S^{\text{liquidation}}$ (assumes other orders will get cancelled and the remaining position will be liquidated).

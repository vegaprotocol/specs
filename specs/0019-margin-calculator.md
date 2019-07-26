The _margin calculator_ returns the set of relevant margin levels for a trader:
1. Maintenance margin
1. Collateral search level
1. Initial margin
1. Collateral release level



## Simple calculation

In this simple methodology, a linearised margin formula is used to return the maintenance margin, using risk factors returned by the [quantitative model](./0018-quant-calculator.md).

The maintenance margin is calculated using the following formula:

```margin_maintenance = close-out-pnl + position_size * [ quantitative_model.risk_factors ] . [ Product.market_observables ] ```

where 

```close-out-pnl = position_size * (Product.value(closeout_price) - Product.value(current_price)) ```

where ```closeout_price``` is the price that would be achieved on the order book if the trader's position were exited.   Note, if there is insufficient order book volume for this ```closeout_price``` to be calculated for an individual trader, the ```closeout_price``` is the price that would be achieved for as much of the volume that could theoretically be closed (in general we expect market protection mechanisms make this unlikely to occur).


The other three margin levels are scaled relative to the maintenance margin level, using scaling levels defined in the risk parameters for a market.

```search_level = margin_maintenance * search_level_scaling_factor```

```initial_margin = margin_maintenance * initial_margin_scaling_factor```

```collateral_release_level = margin_maintenance * collateral_release_scaling_factor```

where the scaling factors are set as risk parameters ( see [market framework](./0001-market-framework.md) ).
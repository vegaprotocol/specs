Feature name: risk boss
Start date: 2019-07-25
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Summary
When the risk boss is called, it's sole job is to return a trader's margin levels:

1. Initial margin
2. Search level
3. Maintenance margin

# Guide-level explanation
The “risk boss” encapsulates the _calibrater_ ,  _quantitative model_ and  _linearised margin calculation_ functionality which  are all necessary to allow it to perform its job of returning a trader's margins.

The “risk boss” has access to:
* a trader’s positions  on a market
* the product logic such as the valuation function and vectors mapping _market observables_ and _risk factors_.
* access to current order book state
* a market's risk parameters

# Reference-level explanation


## _Quantitative model_
The quantitative model returns an array of risk factors which are used in the linearised margin calculation.


## _Linearised margin calculation_

Initially, the maintenance margin is calculated using the following formula:

```margin_maintenance = close-out-pnl + trader.position.open.size * [ quantitative_model.risk_factors ] . [ Product.market_observables ] ```

where 

```close-out-pnl = trader.position.open.size * (Product.value(closeout_price) - Product.value(current_price)) ```

where ```closeout_price``` is the price that would be achieved on the order book if the trader's position were exited.   Note, if there is insufficient order book volume for this closeout_price to be calculated for an individual trader, the market must automatically be placed into a "suspended" mode.


The other two margin levels are scaled relative to the maintenance margin level, using scaling levels defined in the risk parameters for a market.

```search_level = margin_maintenance * Market.risk_parameters.scaling_factors.search_level```

```initial_margin = margin_maintenance * Market.risk_parameters.scaling_factors.initial_margin```



# Pseudo-code / Examples
If you have some data types, or sample code to show interactions, put it here

# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.
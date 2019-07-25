Feature name: quant calculator
Start date: 2019-07-25
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Summary
The quant calculator calculates:

1. Risk factors
1. Margin level scaling factors
1. Margin levels
1. Calibration outputs (not required for Nicenet)

# Guide-level explanation
The “quant calculator” encapsulates a _calibrator_ ,  _quant model_ and  _margin calculator_.


# Reference-level explanation


## _Quantitative model_
The quantitative model returns risk factors which are used in the **_margin calculator_** (see below).

The quantitative model may take one or more of the following as inputs:
* risk parameters (e.g. volatility)
* product parameters (e.g. minimum contract size)
* order book data (full current order book with volume aggregated at price levels)
* position data (for each trader)
* event data (e.g. passage of time) (Not for Futures / Nicenet )

The quantitative model returns two risk factors:

1. Long position risk factor
2. Short position risk factor

## _Calibrator_
The calibrator provides outputs that are used by the risk model.


## _Margin calculator_

The _margin calculator_ returns the set of relevant margin levels for a trader:
1. Maintenance margin
1. Search level
1. Initial margin

The maintenance margin is calculated using the following formula:

```margin_maintenance = close-out-pnl + trader.position.open.size * [ quantitative_model.risk_factors ] . [ Product.market_observables ] ```

where 

```close-out-pnl = trader.position.open.size * (Product.value(closeout_price) - Product.value(current_price)) ```

where ```closeout_price``` is the price that would be achieved on the order book if the trader's position were exited.   Note, if there is insufficient order book volume for this ```closeout_price``` to be calculated for an individual trader, the market must automatically be placed into a "suspended" mode.


The other two margin levels are scaled relative to the maintenance margin level, using scaling levels defined in the risk parameters for a market.

```search_level = margin_maintenance * Market.risk_parameters.scaling_factors.search_level```

```initial_margin = margin_maintenance * Market.risk_parameters.scaling_factors.initial_margin```


# Pseudo-code / Examples

## _Margin calculator_

```

# calling something like

QuantCalculator.getMargins( Product.getObservableValues(), QuantitativeModel.getRiskFactors(), Market.orderBook, party.position, Product.value(current_price) )  -->

# e.g. for a trader's short futures position of size 1025 contracts where the market observable is just the latest "mark price"
QuantCalculator.getMargins( 120, [0.1, 0.12], Market.orderBook, -1025, 120 )

# returns

margin_levels = [margin_maintenance, search_level, margin_initial]

```



# Test cases
Some plain text walk-throughs of some scenarios that would prove that the implementation correctly follows this specification.
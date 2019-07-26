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
The “quant calculator” encapsulates a _calibrator_ ,  _quantitative model_ and  _margin calculator_.


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
The calibrator provides outputs that are used by the risk model... TODO Barney to include a description (something about requiring inputs via consensus)


## _Margin calculator_

The [margin calculator](./0019-margin-calculator) may take one or more of the following as inputs:
1. Data provided by the product.
1. Risk factors provided by the quantitative model.
1. The market's order book
1. The position size that the margin should be calculated for


The [margin calculator](./0019-margin-calculator) returns the set of relevant margin levels for a trader:
1. Maintenance margin
1. Collateral search level
1. Initial margin
1. Collateral release level

See [here](./0019-margin-calculator) for specification of the [margin calculator](./0019-margin-calculator).

# Pseudo-code / Examples

## _Margin calculator_

```

# calling something like

QuantCalculator.getMargins( Product.getObservableValues(), QuantitativeModel.getRiskFactors(), Market.orderBook, position_size, Product.value(current_price) )  -->

# e.g. for a trader's short futures position of size 1025 contracts where the market observable is just the latest "mark price"
QuantCalculator.getMargins( 120, [0.1, 0.12], Market.orderBook, -1025, 120 )

# returns

margin_levels = [margin_maintenance, search_level, margin_initial, release_level]

```

# Test cases

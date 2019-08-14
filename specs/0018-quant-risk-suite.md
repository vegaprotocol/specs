Feature name: quant risk_suite
Start date: 2019-07-25
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Summary
The quant risk suite contains functionality to deliver:

1. Risk factors (calculated by  the _quantitative risk model_)
1. Margin levels (calculated by the _margin calculator_)
1. Calibration outputs (not required for Nicenet)

# Guide-level explanation
The “quant risk suite” encapsulates a _quantitative risk model_, _margin calculator_ and _calibrator_.

The market parameter specifies which _quantitative risk model_ is in play for a market.


# Reference-level explanation


## _Quantitative risk model_
The quantitative risk model calculates **risk factors** which are used in the **_margin calculator_** (see below).

The quantitative risk model may take one or more of the following as inputs:
* risk parameters (e.g. volatility)
* product parameters (e.g. minimum contract size)
* order book data (full current order book with volume aggregated at price levels)
* position data (for each trader)
* event data (e.g. passage of time) (Not for Futures / Nicenet )

The quantitative risk model returns two risk factors:

1. Long position risk factor
2. Short position risk factor

## _Margin calculator_

The [margin calculator](./0019-margin-calculator) may take one or more of the following as inputs:
1. Data provided by the product.
1. Risk factors provided by the quantitative risk model.
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

MarginCalculator.getMargins( Product.getObservableValues(), QuantitativeRiskModel.getRiskFactors().longFactor, Market.orderBook, position_size, Product.value(current_price) )  -->

# e.g. for a trader's short futures position of size 1025 contracts where the market observable is just the latest "mark price"
MarginCalculator.getMargins( 120, [0.1, 0.12], Market.orderBook, -1025, 120 )

# returns

margin_levels = [margin_maintenance, search_level, margin_initial, release_level]

```

## _Calibrator_

The calibrator calculates and/or sources a set of values (collectively, the calibration) that are used by the quantitative model. There can be multiple calibrators that can be used with each quantitative model, and each calibrator may be able to calibrate more than one quantitative model (i.e. `calibrator <--> model` is a many-to-many relationship). However, the set of values needed will vary between quantitative models, therefore not all calibrators will be applicable to all models.

Calibrators may use a combination of data available from oracles and from sources such at the market framework and order book for the market, and indeed other related markets (e.g. a spot or futures market may be used as a calibration source for options). 

In future: calibrators may also implement more complex logic, such as to create economic incentives for providing accurate and timely calibration, where the correct values cannot be easily calculated by Vega. In general this would be done as an extension to the oracle protocol, i.e. by providing hard coded calibrator logic that interprets oracle inputs from potential calibration providers, and distributes rewards from fees based on some set of rules (NOTE: in this case, the calibration fee will be included in fee calculations).

Eventually, some aspects of calibration logic and rules may be specified in the product definition language, though this is not currently a known requirement.

The quant model and calibrator will need to define and share a data structure/interface for the calibration data they require and produce respectively. This should be specified by the design of the model and calibrator themselves. 




# Test cases

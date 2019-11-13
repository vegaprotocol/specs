# Quantitative risk models

## Acceptance Criteria

1. [ ] Different markets can have a different risk model.
2. [ ] The quant math library is called only when the inputs have changed since the last call.
3. [ ] If any of the input data has changed then an update to risk factors is initiated. 
4. [ ] Risk factors are agreed upon by consensus.
5. [ ] If the quant math library reports "guaranteed accuracy" then the risk factors are appropriately rounded. 
6. [ ] If an async update to risk factors is already running, don't start a new one until the previous one has finished. 


## Summary
The quant risk suite contains functionality to deliver:

1. Risk factors (calculated by  the _quantitative risk model_)
1. Margin levels (calculated by the _margin calculator_)
1. Calibration outputs (not required for Nicenet)


The “quant risk suite” encapsulates a _quantitative risk model_, _margin calculator_ and _calibrator_.

The market parameter specifies which _quantitative risk model_ is in play for a market.


## Reference-level explanation

### _Quantitative risk model_
The relevant quantitative risk model for a market is specified on a tradeable instrument. The role of the quantitative risk model is to calculate **risk factors** which are used in the **_margin calculator_** (see below). To achieve this it utilises the quantitative maths library.

The quantitative risk model may take one or more of the following as inputs:
* risk parameters (e.g. volatility)
* product parameters (e.g. minimum contract size)
* order book data (full current order book with volume aggregated at price levels)
* position data (for each trader)
* event data (e.g. passage of time) (Not for Futures / Nicenet )

The quantitative risk model returns two risk factors:

1. Rounded Long position risk factor
1. Rounded Short position risk factor

The quantitative risk model is able to utilise a relevant method from the quant math library to perform the calculations.

The quant math library calculates:
1. Long position risk factor
1. Short position risk factor
1. Guaranteed accuracy (applicable to both risk factors)

#### When to not update risk factors

The call to the quantitative math library should *only* be made if any of the above inputs have changed from last time; if no input has changed then the quantitative risk model doesn't need to update the risk factors.  

#### When to update risk factors

Risk factors are an input to the [margin calculation](./0019-margin-calculator.md) and are calculated using a [quantitative risk model](./0018-quant-risk-suite.md).

Risk factors are updated if  
* An update risk factors call is not already in progress asynchronously; AND
* Any of the required inputs to risk factors change. Examples 1. when the calibrator has updated any risk parameters. 2. a specified period of time has elapsed (period can = 0 for always recalculate) for re-calculating risk factors. This period of time is defined as a risk parameter (see [market framework](./0001-market-framework.md)).

Risk factors are also updated if on creation of a new market that does not yet have risk factors, as any active market needs to have risk factors.

#### Risk factors and consensus

All new risk factors will need to be agreed via consensus when either (or both): 
- asynchronous updates
- the other cause will be due to floating point non-determinism

The rounding should remove all digits beyond the guaranteed accuracy. 

Example: If `Long position risk factor = 1.23456789` and `Guaranteed accuracy = 0.001` then 
`Rounded Long position risk factor = 1.234`. 

```
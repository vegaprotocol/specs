# Instantaneous liquidity scoring function

## Summary

While by default the market uses probability of trading to calculate the [liquidity score](./0042-LIQF-setting_fees_and_rewarding_lps.md#calculating-the-instantaneous-liquidity-score) it should also be possible to explicitly prescribe the instantaneous liquidity scoring function. When such function is specified then it gets used for liquidity score calculation and probability of trading is ignored.

## Specifying the function

The function gets specified sparately for each side of the book as:

* `reference`: reference point to which offset from each `point` is to be applied. It can be MID or BEST BID / BEST ASK depending on the side of the book for which the function is specified.
* `points`: collection of `(offset, value)` tuples prodiving a discrete representation of the function. Tuple `(10,0.4)` means that the value of the instantaneous liquidity function for a price level of reference point with an offset of `10` is `0.4` (specified in the same way as for [pegged orders](./0037-OPEG-pegged_orders.md)).
* `interpolation strategy`: prescribes a way in which price levels not covered by `points` should be calculated. Should be either `flat` resulting in a piecewise-constant function (starting from a lowest offest the value specified for it is assumed to prevail until the next offset is reached) or `linear` resulting in a linear interpolation between points.

Flat extrapolation is always carried out, that is when price level greater than point with a highset offset or smaller than that with a lowest offset needs to be scored we use the nearest values that's been specified.

Validation:
* same as pegged orders for `reference` and `offset`,
* at least two `points` must be specified.

When liquidity scoring function is not specified [probability of trading](./0034-PROB-prob_weighted_liquidity_measure.ipynb) should be used for [liquidity score](./0042-LIQF-setting_fees_and_rewarding_lps.md#calculating-the-instantaneous-liquidity-score) calculation by default. It should also be possible to change it back to a `nil` value later on in market's life to stop using the function prescibed before and return to the default behaviour.
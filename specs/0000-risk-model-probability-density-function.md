# Order types

## Acceptance Critieria

1. [ ] Given an input mid-price $m$, a timestep $\tau > 0$ and a vector of prices a risk model returns a vector of probabilities.
2. [ ] The risk model doesn't assume that the provided price levels are the only possible future states (i.e. the probabilities need not always sum to 1).
3. [ ] Take a fixed vector $\mathbf{v_1}$ of length $n$ of price levels as an input, create another vector $\mathbf{v_2}$ by copying $\mathbf{v_1}$ and adding another dimension $v^2_{n+1}$, given same mid price $m$ and future time $tau$, the vectors $\mathbf{p_1}$ and $\mathbf{p_2}$ (corresponding to inputs $v_1$ and $v_2$) returned by the risk model should have the first $n$ entries equal.

## Summary

When measuring liquidity we will need to take a view on what might be the distribution of the mid-price at a given point in time in the future. This is exactly what the risk model does internally, hence we will want to expose that functionality so it can be accessed as needed.

## Guide-level explanation

We will use a risk model specified for a given market along with the following parameters:

* $\tau > 0$ - the desired timestep for the future distribution of prices,
* $m > 0$ - the current mid-price,
* $\mathbf{v}$ - a vector of prices for which we want the probabilities go get estimated by the model.

We expect the following output:

* $\mathbf{p}$ - a vector of probabilities corresponding to the input prices from $\mathbf{v}$.
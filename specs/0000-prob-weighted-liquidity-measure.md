# Exponentially-in-time Weighted and Probabilistically-in-space-Weighted Liquidity Measure

## Acceptance Criteria
Correctly implement the spirit, not necessarily the letter of this specification.

## Summary
We need to measure liquidity available on a market in order to see whether market makers are keeping 
their commitment. 
Here we propose a method counts liquidity as the probability weighted average of volume on the book. 
This gives view of liquidity at one instant of time; we then use exponential weighted average over time to obtain the desired measure.

## Terminology
- $\Lambda_t$ is the exponentially-in-time weighted and probabilistically-in-space-weighted liquidity which we are defining in this spec file.
- mid price = (best bid - best offer) / 2 (or undefined if either side of the book is empty)
- buy / sell side volume refer to the volume available at a distance from mid price, $`V = V(x)`$, where $`x > 0`$ refers to sell side, $`x < 0`$ refers to buy side and $`x`$ belongs to the set of all price points available on the book
- probability of volume at distance from mid price being hit: $`p = p(x)`$, this will come from risk model
- auction level buy price $`x_{min} < 0`$ and auction level sell price $`x_{max} > 0`$ will come from risk model together with market parameter specifiyng what percentile move triggers auction  
- instantenaous liquidity $`\lambda_t`$, defined below in detail.
- decay parameter $`\delta`$ which determines how far back in time do we go when averaging instantenaous liquidity.
- weighting parameter $`\alpha`$ which determines how steep the exponential decay is.

Note that both $`\delta`$ and $`\alpha`$  are network wide parameters.

## Details
Auction periods should be ignored during calculations (so we pretend time stops).

The instantenaous liquidiy should get calculated periodically.
To be more precise this should be after each "event" if a configurable liquidity time step parameter has been exceeded. 
We will need to keep track of the instantenaous liquidity $`\lambda_{t_k}`$ and the period of time $`[t_k,t_{k+1})`$ for which it was calculated.

### Calculating the instantenaous liquidity

Assume that time now is $`t = t_k`$. We wish to calculate $`\lambda_t`$.

Case 1: no mid price
$`\lambda_t := 0`$ if there is no mid price (i.e. when either the buy or sell side of the book are empty)

Case 2: we have mid price
1. Obtain $`x_{min}`$ and $`x_{max}`$ from the risk model. 
1. Get the list of possible $`x`$ s.t. $`x_{max} \geq x > 0`$ values from the order book. Call these $`x^+_i`$, with $`i = 1,\ldots,N^+`$. 
1. Get the list of possible $`x`$ s.t. $`x_{min} \leq x < 0`$ from the order book and call these $`x^-_i`$, with $`i = 1, \ldots , N^-`$. 
1. Get the volume $`V(x)`$ available at each $`x = x^-_i`$ and $`x^+_i`$ from the order book.
1. Get the probability $`p(x)`$ for each of $`x = x^-_i`$ and $`x^+_i`$ from the risk model. 

Note that in all the above the $`x`$ is relative to the mid-price and so you may need to perform the requisite transformations.

Now you can calculate 
```math
\lambda_t := 
\min\left(
    \sum_{i=1}^{N^+} V(x^+_i) p(x^+_i), 
    \sum_{i=1}^{N^-} V(x^-_i) p(x^-_i), 
\right)\,.
```

### Calculating the time average

We now have a list of $`\lambda_{t_k}`$ and the corresponding time periods $`[t_k,t_{k+1})`$ from the market inception until now (time now is $`t`$). 
From this we get $`\lambda_t`$ for any $`t`$ using peicewise constant extrapolation i.e. $`\lambda_s = \lambda_{t_k}`$ whenever $`s \in [t_k, t_{k+1})`$.

We then have 
```math
\Lambda_t := \int_{t-\delta}^t e^{\alpha (s - (t-\delta))} \lambda_s \,ds\,.
```
Note that the integral above is just a sum but it's an easy way to express over which indices $`k`$ we should sum up.


# Pseudo-code / Examples

To be provided later.

# Test cases

To be provided later.

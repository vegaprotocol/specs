
# vAMM Bounds Estimation Calculator


## Summary

The protocol contains the ability for users to create vAMMs which will automatically trade and manage a position on a given market with no further interaction from the user. These are configured through a few different parameters, which uniquely specify the behaviour and volume profile of the vAMM as the price of the market moves, however are not always immediately obvious and intuitive for a user given the set of inputs. As such, it is necessary to provide an API giving canonical conversions between these values.

The API should take a pool's specification parameters and output various metrics useful for a user deciding on vAMM configuration. Concretely, the API should take the parameters:

 1. Base Price
 1. Upper Price
 1. Lower Price
 1. Leverage At Upper Price
 1. Leverage At Lower Price
 1. Commitment Amount
 1. Optional: Party Key

And then return the metrics:

 1. Loss on Commitment at Upper Bound
 1. Loss on Commitment at Lower Bound
 1. Position Size at Upper Bound
 1. Position Size at Lower Bound
 1. Liquidation Price at Upper Bound
 1. Liquidation Price at Lower Bound
 1. If `party key` is specified:
    1. Approximate trade size on amendment (immediate)
    1. Approximate crystallised loss from position rebalancing (immediate)
    1. Change in Size at Upper Bound vs current specification
    1. Change in Size at Lower Bound vs current specification
    1. Change in Loss at Upper Bound vs current specification
    1. Change in Loss at Lower Bound vs current specification


## Calculations

There are a few values which are generally useful to calculate many of the above required outputs, so these will be calculated first.

Starting with the average entry price, this value for a given range is equal no matter the absolute volume committed, so can be calculated without reference to the bond or leverage at bounds values. This is taken from the unit liquidity, $L_u$

$$
L_u = \frac{\sqrt{p_u} \sqrt{p_l}}{\sqrt{p_u} - \sqrt{p_l}} ,
$$

where $p_u$ is the price at the upper end of the range (`upper price` for the upper range and `base price` for the lower range) and $p_l$ is the corresponding lower price for the range. With this, the average entry price can be found to be

$$
p_a = L_u  p_u  (1 - \frac{L_u}{L_u + p_u}) ,
$$

where $p_a$ is the average execution price across the range and other values are as defined above. Finally, the risk factor which will be used for calculating leverage at bounds

$$
r_f = \min(l_b, \frac{1}{ (f_s + f_l) \cdotp f_i}) ,
$$

where $l_b$ is the sided value `leverage_at_bounds` (`upper ratio` if the upper band is being considered and `lower ratio` if the lower band is), $f_s$ is the market's sided risk factor (different for long and short positions), $f_l$ is the market's linear slippage component and $f_i$ is the market's initial margin factor.


### Position at Bounds

With this, the volumes required to trade to the bounds of the ranges are:

$$
P_{v_l} = \frac{r_f b}{p_l (1 - r_f) + r_f p_a} ,
$$
$$
P_{v_u} = \frac{r_f b}{p_u (1 + r_f) - r_f p_a} ,
$$

where $r_f$ is the `short` factor for the upper range and the `long` factor for the lower range, `b` is the current total balance of the vAMM across all accounts, $P_{v_l}$ is the theoretical volume and the bottom of the lower bound and $P_{v_u}$ is the (absolute value of the) theoretical volume at the top of the upper bound.


### Loss on Commitment at Bound

For the loss on commitment at bound, one needs to use the average entry price, bound price and the position at the bounds

$$
l_c = |p_a - p_b| \cdot P_b ,
$$

where $P_b$ is the position at bounds (Either $P_{v_l}$ or $P_{v_u}$), $p_a$ is the average entry price and $p_b$ is the price at the corresponding outer bound. Note that this is an absolute value of loss, so outstanding balance at bounds would be `initial balance - $L_c$`.


### Liquidation Prices

Using a similar methodology to the standard estimations for liquidation price and the above calculated values, an estimate for liquidation prices above and below the range can be obtained with

$$
p_{liq} = \frac{b - l_c - P_b \cdot p_b}{\abs{P_b} \cdot m_r - P_b} ,
$$

where $p_{liq}$ is the liquidation price (above or below the specified ranges), $b$ is the original commitment balance, $l_c$ is the loss on commitment at the relevant bound, $P_b$ is the position at the relevant bound, $p_b$ is the price at the bound and $m_r$ is the market's long or short risk factor (short for the upper price bound as the position will be negative and long for the lower).


## Specified Key

When a key is specified, the existence of any current vAMM should be checked and, if one exists, the above values also calculated for it and populated in the requisite areas of the response to allow easy comparison.


## Acceptance criteria

- For a request specifying (base, upper, lower, leverage_upper, leverage_lower, commitment) as (1000, 1100, 900, 2, 2, 100) the response is (<a name="0014-NP-VAMM-001" href="#0014-NP-VAMM-001">0014-NP-VAMM-001</a>):

 1. Loss on Commitment at Upper Bound: 8.515
 1. Loss on Commitment at Lower Bound: 9.762
 1. Position Size at Upper Bound: -0.166
 1. Position Size at Lower Bound: 0.201
 1. Liquidation Price at Upper Bound: 1633.663
 1. Liquidation Price at Lower Bound: 454.545


- For a request specifying (base, upper, lower, leverage_upper, leverage_lower, commitment) as (1000, 1300, 900, 1, 5, 100) the response is (<a name="0014-NP-VAMM-001" href="#0014-NP-VAMM-001">0014-NP-VAMM-001</a>):

 1. Loss on Commitment at Upper Bound: 10.948
 1. Loss on Commitment at Lower Bound: 21.289
 1. Position Size at Upper Bound: -0.069
 1. Position Size at Lower Bound: 0.437
 1. Liquidation Price at Upper Bound: 2574.257
 1. Liquidation Price at Lower Bound: 727.273

- A request with an empty upper *or* lower bound price is valid and will return the metrics for the bound which *was* specified with the metrics for the unspecified bound empty. (<a name="0014-NP-VAMM-002" href="#0014-NP-VAMM-002">0014-NP-VAMM-002</a>)
- A request with an empty upper *and* lower bound is invalid and receives an error code back. (<a name="0014-NP-VAMM-003" href="#0014-NP-VAMM-003">0014-NP-VAMM-003</a>)

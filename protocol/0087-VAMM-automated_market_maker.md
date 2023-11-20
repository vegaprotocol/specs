# Automated Market Maker Framework

## Summary

The automated market maker (AMM) framework is designed to allow for the provision of an on-chain market making methodology which automatically provides prices according to a simple set of rules based on current market data. These rulesets are not created with the expectation of providing any profit nor of remaining solvent under any specific conditions, and so should be limited to conceptually simple setups. The initial methodology follows a concentrated-liquidity style constant-function market setup, with configurable maximum and minimum price bounds.

An automated market maker is configured at a per-key level, and is enabled by submitting a transaction with the requisite parameters. At this point in time the protocol will move committed funds to a sub-account which will be used to manage margin for the AMM. Once enabled, the configuration will be added to the pool of available AMMs to be utilised by the matching engine.

Each party may have only one AMM configuration per market.

## Process Overview

The configuration and resultant lifecycle of an automated market maker is as follows:

- Party funds a key which will be used by the strategy with desired token amounts.
- Party submits a transaction containing configuration for the strategy on a given market. This will contain:
  - Amount of funds to commit
  - Price bounds (upper, lower, base)
  - Margin ratios at upper and lower bound (ratio for leverage at bounds. Reciprocal of leverage multiplier e.g. 0.1 = 10x leverage)
- Additionally, the transaction should contain data related to the setup of the position but which does not need to be stored:
  - Maximum slippage (%), used for rebasing position when creating/updating AMM
- Once accepted, the network will transfer funds to a sub-account and use the other parameters for maintaining the position.
- At each block, the party's available balance (including margin and general accounts) for trading on the market will be checked. If the total balance is `0` the AMM configuration will be stopped.
- If the party submits a `CancelAMM` transaction the AMM configuration for that party, on that market, will be cancelled. All active orders from the AMM will be cancelled and all funds and positions associated with the sub-account will be transferred back to the main account.

## Sub-Account Configuration

Each main Vega key will have one associated sub account for a given market, on which an AMM may be set up. The account key should be generated through a hash of the main account key plus the ID of the market to generate a valid Vega address in a predictable manner. Outside of the AMM framework the sub-accounts are treated identically to any other account, they will have the standard associated margin/general accounts and be able to place orders if required as with any other account. The key differentiator is that no external party will have the private key to control these accounts directly. The maintenance of such an account will be performed through a few actions:

- Creation: A sub-account will be funded when a user configures an AMM strategy with a set of criteria and a commitment amount. At this point in time the commitment amount will be transferred to the sub-account's general account and the AMM strategy will commence
- Cancellation: When the AMM is cancelled all funds in the sub-account's margin account should be transferred to the associated main account's margin account, with the same then happening for funds in the general account. Finally, any associated non-zero position on the market should be reassigned from the sub-account to the main account. At this point processing can continue, allowing the standard margining cycle to perform any required transfers from margin to general account.
- Amendment: Updates the strategy or commitment for a sub-account

## Interface

All AMM configurations should implement two key interfaces:

- One taking simply the current state (`position` and `total funds`) and a trade (`volume`, `side`) and returning a quote price. This should also handle a trade of `volume = 0` to return a notional `fair price`
- The second taking (`position`, `total funds`, `side`, `start price`, `end price`) should return the full volume the AMM would trade between the two prices (inclusive).

## AMM Configurations

Initially there will only be one option for AMM behaviour, that of a constant-function curve, however there may be others available in future. As such, the parameters pertaining to this model in particular should be passed in their own structure such that the creation message is similar to:

```json
{
  commitment,
  market,
  slippage_tolerance_percentage,
  proposed_fee,
  concentrated_liquidity_params: {
    base_price,
    lower_price,
    upper_price,
    margin_ratio_at_upper_bound,
    margin_ratio_at_lower_bound,
  }
}
```

### Concentrated Liquidity

The `Concentrated Liquidity` AMM is a market maker utilising a Uniswap v3-style pricing curve for managing price based upon current market price. This allows for the market maker to automatically provide a pricing curve for any prices within some configurable range, alongside offering the capability to control risk by only trading within certain price bounds and out to known position limits.

The concentrated liquidity market maker consists of two liquidity curves of prices joined at a given `base price`, an `upper` consisting of the prices above this price point and a `lower` for prices below it. At prices below the `base price` the market maker will be in a long position, and at prices above this `base price` the market maker will be in a short position. This is configured through a number of parameters:

- **Base Price**: The base price is the central price for the market maker. When trading at this level the market maker will have a position of `0`. Volumes for prices above this level will be taken from the `upper` curve and volumes for prices below will be taken from the `lower` curve.
- **Upper Price**: The maximum price bound for market making. Prices between the `base price` and this price will have volume placed, with no orders above this price. This is optional and if not supplied no volume will be placed above `base price`. At these prices the market maker will always be short
- **Lower Price**: The minimum price bound for market making. Prices between the `base price` and this will have volume placed, with no orders below this price. This is optional and if not supplied no volume will be placed below `base price`. At these prices the market maker will always be long
- **Commitment**: This is the initial volume of funds to transfer into the sub account for use in market making. If this amount is not currently available in the main account's general account the transaction will fail.
- **Margin Ratio at Bounds**: The exact volume scaling is defined by the position at the upper and lower prices. To determine this the commitment must be compared with what leverage that might allow at the price bounds. One way to do this is to assume the network will use the value at which `commitment == initial margin` for the position at that price, however users may wish to take a more conservative approach. Using this parameter allows them to set a value such that `position = commitment / margin ratio at bound`, however with the restriction that commitment must still be `>= initial margin`. This parameter should be optional. There is a separate parameter for each potential bound.
  - **Upper Bound Ratio**: `margin_ratio_at_upper_bound`
  - **Lower Bound Ratio**: `margin_ratio_at_lower_bound`

Note that the independent long and short ranges mean that at `base price` the market maker will be flat with respect to the market with a `0` position. This means that a potential market maker with some inherent exposure elsewhere (likely long in many cases as a token holder) can generate a position which is always either opposite to their position elsewhere (with a capped size), thus offsetting pre-existing exposure, or zero.

Additionally, as all commitments require some processing overhead on the core, there should be a network parameter `market.amm.minCommitmentQuantum` which defines a minimum quantum for commitment. Any `create` or `amend` transaction where `commitment / asset quantum < market.amm.minCommitmentQuantum` should be rejected.

### Creation/Amendment Process

#### Creation

A `Concentrated Liquidity` AMM has an inherent linkage between position and implied price. By configuration, this position is `0` at `base price` but non-zero above and below that (assuming both an upper and lower bound have been provided), however it is possible to configure an AMM such that this `base price` is far from the market's current `mark price`. In order to bring the AMM into line with where it "should" be an initial aggressive trade is attempted based on the configuration and current market `mark price`:

  1. Request from the AMM it's current `fair price` by requesting a quote of volume `0`
  1. Request from the AMM the total trade volume required to move between `fair price` and `mark price`. Note that if `mark price` > `base price` this should be negative (i.e. the AMM will be selling) and it `mark price` < `base price` it should be positive (i.e. the AMM will be buying).
     1. If no upper(/lower) price is specified then if the price is above(/below) the mid the AMM should return `0` volume
  1. Create a limit order with `FOK` execution at a price equal to `mark price` shifted by the AMM's `max slippage %` for this volume. If the limit order would not trade, reject the entire creation/amendment as `CANNOT_REBASE_SLIPPAGE_BEYOND_LIMITS`.

#### Amendment

A similar process is followed in the case of amendments. Changes to the `upper`, `lower` or `base` price, or the `commitment amount` will affect the position implied at a certain price, meaning that the market maker may need to trade to update it's position in line with this. These trades should be calculated as in the process for creation above after the relevant bounds have been changed, and comparing `fair price` from the pool before and after the changes, rather than `mark price`.

When changing `commitment amount`, an increase can be handled trivially, the general account is first topped up by the requisite amount (note that the change should be considered vs the current balance of margin + general rather than the original commitment amount) and then the balancing trade is attempted. If this trade fails then the amount should be moved back to the main key's general account and the transaction stopped.

If reducing the `commitment amount` then the position once the funds are reduced should be calculated, then an attempted balancing trade with relevant slippage limits made. If the trade fails the transaction is stopped. If the trade succeeds then the funds may now be released. These funds should be first taken from the general account, and then from the margin account.

### Determining Volumes and Prices

Although AMM prices are not placed onto the book as orders it is necessary to be able to be able to quote prices for a given volume, or know what trading volume would move the fair price to a certain level.

The volume to offer at each price level is determined by whether the price level falls within the upper or lower price bands alongside the market maker's current position. In order to calculate this, use the concept of `Virtual Liquidity` from Uniswap's concentrated liquidity model, corresponding to a theoretical shifted version of the actual liquidity curve to map to an infinite range liquidity curve. The exact mathematics of this can be found in the Uniswap v3 whitepaper and are expanded in depth in the useful guide [Liquidity Math in Uniswap v3](http://atiselsts.github.io/pdfs/uniswap-v3-liquidity-math.pdf). Here will be covered cover only the steps needed to obtain prices/volumes without much exposition.

The AMM position can be thought of as two separate liquidity provision curves, one between `upper price` and `base price`, and another between `base price` and `lower price`. Within each of these, the AMM is buying/selling position on the market in exchange for the quote currency. As the price lowers the AMM is buying position and reducing currency, and as the price rises the AMM is selling position and increasing currency.

One outcome of this is that the curve between `base price` and `lower price` is marginally easier to conceptualise directly from our parameters. At the lowest price side of a curve (`lower price` in this case) the market should be fully in the market contract position, whilst at the highest price (`base price` in this case) it should be fully sold out into cash. This is exactly the formulation used, where at `base price` a zero position is used and a cash amount of `commitment amount`. However given that there is likely to be some degree of leverage allowed on the market this is not directly the amount of funds to calculate using. An AMM with a `commitment amount` of `X` is ultimately defined by the requirement of using `X` in margin at the outer price bounds, so work backwards from that requirement to determine the theoretical cash value. We then calculate the two ranges separately to determine two different `Liquidity` values for the two ranges, which is a value used to later define volumes required to move the price a specified value.

We can calculate a scaling factor that is the smaller of a fraction specified in the commitment (`margin_ratio_at_bounds`, either upper or lower depending on the side considered) or the market's worst case margin. If `margin_ratio_at_bounds` for the relevant side is not set then the market's worst case initial margin is taken automatically

$$
r_f = \min(\frac{1}{m_r}, \frac{1}{ (f_s + f_l) \cdotp f_i}) ,
$$

where $m_r$ is the sided value `margin_ratio_at_bounds` (`upper ratio` if the upper band is being considered and `lower ratio` if the lower band is), $f_s$ is the market's sided risk factor (different for long and short positions), $f_l$ is the market's linear slippage component and $f_i$ is the market's initial margin factor.

The dollar value at which all margin is utilised will then be

$$
v_{worst} = c \cdotp r_f
$$

where $c$ is the commitment amount and $r_f$ is as above.

Calculating this separately for the upper and lower ranges (using the `short` factor for the upper range and the `long` factor for the lower range) one can calculate the liquidity value `L` for each range with the formula

$$
L = \frac{v_{worst}}{\sqrt{p_u} - \sqrt{p_l}} ,
$$

where $v_{worst}$ is as above, $p_u$ is the price at the top of the range (`upper price` for the upper range and `base price` for the lower range) and $p_l$ is the price at the bottom of the range (`base price` for the lower range and `lower price` for the lower range). This gives the two `L` values for the two ranges.

#### Fair price

From here the first step is calculating a `fair` price, which can be done by utilising the `L` value for the respective range to calculate `virtual` values for the pool balances. From here on `y` will be the cash balance of the pool and `x` the position.

  1. First, identify the current position, `p`. If it is `0` then the current fair price is the base price.
  2. If `P > 0`:
     1. The virtual `x` of the position can be calculated as $x_v = P + \frac{L}{\sqrt{p_l}}$, where $L$ is the value for the lower range, $P$ is the market position and $p_l$ is the `base price`.
     2. The virtual `y` of the position can be calculated as $y_v = c_c \cdotp r_f + L \cdotp \sqrt{p_l}$ where $c_c$ is the current total dollar balance of the AMM across margin and general accounts and `p_l` is the `lower price`. Other variables are as defined above.
  3. If `P < 0`:
     1. The virtual `x` of the position can be calculated as $x_v = P + \frac{c}{p_u} \cdotp r_f + \frac{L}{\sqrt{p_l}}$ where $p_l$ is the `base price` and `p_u` is the `upper price`.
     2. The virtual `y` can be calculated as $v_y = abs(P) \cdotp p_e + L \cdotp p_l$ where $p_e$ is the average entry price of the position and $p_l$ is the `base price`
  4. Now the `fair` price is simply $\frac{y_v}{x_v}$

#### Volume between two prices

For the second interface one needs to calculate the volume which would be posted to the book between two price levels. In order to calculate this for an AMM one is ultimately asking the question "what volume of swap would cause the fair price to move from price A to price B?"

To calculate this, the interface will need the `starting price` $p_s$, `ending price` $p_e$, `upper price of the current range` $p_u$ (`upper price` if `P < 0` else `base price`) and the `L` value for the current range. At `P = 0` use the values for the range which the volume change will cause the position to move into.

We then need to calculate the implied position at `starting price` and `ending price` and return the difference.

For a given price $p$ calculate implied position $P_i$ with

$$
P_i = L * \frac{\sqrt{p_u} - \sqrt{p}}{\sqrt{p} \cdotp \sqrt{p_u}}
$$

Then simply return the absolute difference between these two prices.

## Matching Process (To merge with 0068-MATC once confirmed)

For all incoming active orders, the matching process will coordinate between the on- and off-book sources of liquidity. When an order comes in which may immediately trade (there are not already resting orders of the same type for the best applicable price) the following steps should be followed. If at any point the order's full volume has traded the process is immediately halted:

  1. For the first applicable price level, all on-book orders should be checked. Any volume at this price level which can be met through on-book orders will then trade.
  1. For any `remaining volume`, the AMMs will be checked. This requires an algorithm to ensure the protocol does not have to check every price level individually:
     1. Call the current price level `current price`
     1. Check the price level which has the next resting on-book order, set this to be the `outer price` for the check.
     1. Check all active AMMs, querying their quote price API with the smallest trade unit on the market in the direction of trading (if the incoming order is a `buy`, query the AMM's `ask`, or vice versa). Retain those where this price < `outer price`
     1. Within these, select either the minimum `upper price` (if the incoming order is a buy) or the maximum `lower price` (if the incoming order is a sell), call this `amm bound price`. This is the range where all of these AMMs are active. Finally, select either the minimum (for a buy) or maximum (for a sell) between `amm bound price` and `outer price`. From this form an interval `current price, outer price`.
     1. Now, for each AMM within this range, calculate the volume of trading required to move each from the `current price` to the `outer price`. Call the sum of this volume `total volume`.
     1. If `remaining volume <= total volume` split trades between the AMMs according to their proportional contribution to `total volume` (e.g. larger liquidity receives a higher proportion of the trade). This ensures their mid prices will move equally. Each of these trades should count as a single aggressive trade with the given AMM and pay fees accordingly.
     1. If `remaining volume > total volume` execute all trades to move the respective AMMs to their boundary at `outer price`. Now, return to step `1` with `current price = outer price`, checking first for on-book liquidity at the new level then following this process again until all order volume is traded or liquidity exhausted.  

## Determining Liquidity Contribution

The provided liquidity from an AMM commitment must be determined for two reasons. Firstly to decide instantaneous distribution of liquidity fees between the various liquidity types and secondly to calculate a virtual liquidity commitment amount for assigning AMM users with an ELS value. This will be used for determining the distribution of ELS-eligible fees on a market along with voting weight in market change proposals.

As an AMM does not directly place orders on the book this calculation first needs to infer what the orders would be at each level within the eligible price bounds (those required by SLA parameters on the given market). From here any given AMM curve should implement functionality to take two prices and return the volume it would place to trade fully across that range. Calling this function across the price range out to lower and upper SLA bounds retrieves the full order book shape for each AMM.

Once these are retrieved, the price / volume points should be combined with a precomputed array of the probability of trading at each price level to calculate the liquidity supplied on each side of the orderbook as defined in [probability of trading](./0034-PROB-prob_weighted_liquidity_measure.ipynb). Once this is calculated, use this value as the instantaneous liquidity score for fee distribution as defined in [setting fees and rewards](./0042-LIQF-setting_fees_and_rewarding_lps.md).

As the computation of this virtual order shape may be heavy when run across a large number of passive AMMs the number of AMMs updated per block should be throttled to a fixed maximum number, updating on a rolling frequency, or when updated/first created.

A given AMM's average liquidity score across the epoch should also be tracked, giving a time-weighted average at the end of each epoch (including `0` values for any time when the AMM either did not exist or was not providing liquidity on one side of the book). From this, a virtual stake amount can be calculated by dividing through by the `market.liquidity.stakeToCcyVolume` value and the AMM key'
s ELS updated as normal.

## Setting Fees

The `proposed_fee` provided as part of the AMM construction contributes to the fee determination logic on the market, if a setup where LPs decide on the market fee is in use. In the case where it is the AMM's current assigned ELS, or the running average liquidity provided so far if the commitment was made in the current epoch, is used for weighting the AMM's vote for the fee.

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

A `Concentrated Liquidity` AMM has an inherent linkage between position and implied price. By configuration, this position is `0` at `base price` but non-zero above and below that (assuming both an upper and lower bound have been provided), however it is possible to configure an AMM such that this `base price` is far from the market's current `mark price`. In order to bring the AMM in line with where it "should" be the AMM begins in `single-sided` mode until the position is equal to what is expected at that price. The logic for entering this mode is:

  1. If the AMM's `base price` is between the current `best bid` and `best ask` on the market (including other active AMMs) it is marked as synchronised and enters normal two-sided quoting.
  1. If the AMM's `base price` is below the current `best bid` and the AMM has an upper range specified, it enters `single-sided` mode and will only `sell` until it's position is equal to expected at it's last traded price.
     1. If there is no upper range specified, it is marked as synchronised immediately.
  1. If the AMM's `base price` is above the current `best ask` and the AMM has a lower range specified, it enters `single-sided` mode and will only `buy` until it's position is equal to expected at it's last traded price.
     1. If there is no lower range specified, it is marked as synchronised immediately.

Once in `single-sided` quoting mode, certain behaviour will be different to once in standard `two-sided` quoting mode:

  1. No buy or sell quotes will be provided at a price level where there are existing limit orders or AMMs offering the opposite side (i.e. `single-sided` mode acts as if all orders were `post-only`)
  1. When requested for a volume at any price within the range (i.e. below the `upper price` and above the `lower price`) the volume quoted is the full volume difference between the AMM's current position and that required to move it to the new price.
     1. This can be obtained through first querying the AMM for it's current `fair price` and then asking for the volume quote between said `fair price` and the price level in question.
  1. No volume will be posted to move the AMM's position away from the target (e.g if the price is above the `base price` the AMM will not buy even if the price moves downwards)
  1. No volume will be posted outside of the `upper price` - `lower price` range
  1. Once the AMM's `fair price` is equal to the price level being questioned the AMM will be marked as synchronised and enter normal two-sided quoting.

Note that this rebasing procedure can bound the price range such that movement in either direction will eventually mark the AMM as synchronised. For example, if the price is currently below the `base price` but above the `lower price`, any movement downwards will hit the AMM's buys until it is synchronised, and any movement upwards will eventually bring the price to the `base price` at which point the AMM will become synchronised by default.

#### Amendment

A similar process is followed in the case of amendments. Changes to the `upper`, `lower` or `base` price, or the `commitment amount` will affect the position implied at a certain price, meaning that the market maker may need to enter `single-sided` quoting mode once more until it is synchronised. In general, the behaviour above will be followed. Entering the mode can be checked by comparing the before and after implied positions at the AMM's current fair price. If the implied position increases then the AMM will enter a buy-only `single-sided` mode and if it decreases then it will enter `sell-only` mode.

If reducing the `commitment amount` then only funds contained within the AMMs `general` account are eligible for removal. If the deduction is less than the `general` account's balance then the reduced funds will be removed immediately and the AMM will enter `single-sided` mode as specified above to reduce the position. If a deduction of greater than the `general` account is requested then the transaction is rejected and no changes are made.


#### Cancellation

In addition to amending to reduce the size a user may also cancel their AMM entirely. In order to do this they must submit a transaction containing only a field `Reduction Strategy` which can take two values:

 - `Abandon Position`: In this case, any existing position the AMM holds is given up to the network to close as a liquidation. This is performed in two steps:
   - All funds in the AMM's `general` account are transferred back to the party who created the AMM.
   - The position is marked as requiring liquidation and is taken over by the network through the usual liquidation processes. All funds in the margin account are transferred to the network's insurance pool as in a forced liquidation
 - `Reduce-Only`: This moves the AMM to a reduce-only state, in which case the position is reduced over time and ranges dynamically update to ensure no further position is taken. As such:
   - If the AMM is currently short, the `lower bound` is removed
   - If the AMM is currently long, the `upper bound` is removed
   - The `upper`/`lower` bound (if the AMM is currently short/long) is then set to the AMM's current `fair price`. In this mode the AMM should only ever quote on the side which will reduce it's position (it's `upper`/`lower` bound should always be equal to the current `fair price` belief).
   - Once the position reaches `0` the AMM can be cancelled and all funds in the general account can be returned to the creating party
   - This acts similarly to the mode when an AMM is synchronising, except that the position will be closed in pieces as the price moves towards the `base price` rather than all at once at the nearest price.

Note that, whilst an `Abandon Position` transaction immediately closes the AMM a `Reduce-Only` transaction will keep it active for an uncertain amount of time into the future. During this time, any Amendment transactions received should move the AMM out of `Reduce-Only` mode and back into standard continuous operation.

### Determining Volumes and Prices

Although AMM prices are not placed onto the book as orders it is necessary to be able to be able to quote prices for a given volume, or know what trading volume would move the fair price to a certain level.

The volume to offer at each price level is determined by whether the price level falls within the upper or lower price bands alongside the market maker's current position. In order to calculate this, use the concept of `Virtual Liquidity` from Uniswap's concentrated liquidity model, corresponding to a theoretical shifted version of the actual liquidity curve to map to an infinite range liquidity curve. The exact mathematics of this can be found in the Uniswap v3 whitepaper and are expanded in depth in the useful guide [Liquidity Math in Uniswap v3](http://atiselsts.github.io/pdfs/uniswap-v3-liquidity-math.pdf). Here will be covered cover only the steps needed to obtain prices/volumes without much exposition.

The AMM position can be thought of as two separate liquidity provision curves, one between `upper price` and `base price`, and another between `base price` and `lower price`. Within each of these, the AMM is buying/selling position on the market in exchange for the quote currency. As the price lowers the AMM is buying position and reducing currency, and as the price rises the AMM is selling position and increasing currency.

One outcome of this is that the curve between `base price` and `lower price` is marginally easier to conceptualise directly from our parameters. At the lowest price side of a curve (`lower price` in this case) the market should be fully in the market contract position, whilst at the highest price (`base price` in this case) it should be fully sold out into cash. This is exactly the formulation used, where at `base price` a zero position is used and a cash amount of `commitment amount`. However given that there is likely to be some degree of leverage allowed on the market this is not directly the amount of funds to calculate using. An AMM with a `commitment amount` of `X` is ultimately defined by the requirement of using `X` in margin at the outer price bounds, so work backwards from that requirement to determine the theoretical cash value. Next calculate the two ranges separately to determine two different `Liquidity` values for the two ranges, which is a value used to later define volumes required to move the price a specified value.

One can calculate a scaling factor that is the smaller of a fraction specified in the commitment (`margin_ratio_at_bounds`, either upper or lower depending on the side considered) or the market's worst case margin. If `margin_ratio_at_bounds` for the relevant side is not set then the market's worst case initial margin is taken automatically

$$
r_f = \min(\frac{1}{m_r}, \frac{1}{ (f_s + f_l) \cdotp f_i}) ,
$$

where $m_r$ is the sided value `margin_ratio_at_bounds` (`upper ratio` if the upper band is being considered and `lower ratio` if the lower band is), $f_s$ is the market's sided risk factor (different for long and short positions), $f_l$ is the market's linear slippage component and $f_i$ is the market's initial margin factor.

The dollar value at which all margin is utilised will then be

$$
v_{worst} = c \cdotp r_f
$$

where $c$ is the current commitment amount (the sum of all funds controlled by the key across margin and general accounts) and $r_f$ is as above.

Calculating this separately for the upper and lower ranges (using the `short` factor for the upper range and the `long` factor for the lower range) one can calculate the liquidity value `L` using the knowledge that at the `upper` and `lower` prices the position notional value should be $v_{worst}$. Thus, the absolute position reached at either position bound can be calculated as 

$$
P_v = \frac{v_{worst}}{p} ,
$$

Where $P_v$ is the theoretical volume, $v_{worst}$ is as above and $p$ is either the `upper price` or `lower price` depending on whether the upper or lower range is being considered. The final $L$ scores can then be reached with the equation 

$$
L = P_v \cdot \frac{\sqrt{p_u} \sqrt{p_l}}{\sqrt{p_u} - \sqrt{p_l}} ,
$$

where $P_v$ is the virtual position from the previous formula, $p_u$ is the price at the top of the range (`upper price` for the upper range and `base price` for the lower range) and $p_l$ is the price at the bottom of the range (`base price` for the lower range and `lower price` for the lower range). This gives the two `L` values for the two ranges.

#### Fair price

From here the first step is calculating a `fair` price, which can be done by utilising the `L` value for the respective range to calculate `virtual` values for the pool balances. From here on `y` will be the cash balance of the pool and `x` the position.

  1. First, identify the current position, `P`. If it is `0` then the current fair price is the base price.
  1. If `P != 0` then calculate the implied price from the current position using the virtual position $p_v$ which is equal to $P$ when $P > 0$ or $P + \frac{c}{p_u} \cdotp r_f$ where $P < 0$.
  1. The fair price can then be calculated as 
   
$$
p_f = \frac{p_u}{p_v \cdotp p_u \cdotp \frac{1}{L} + 1}^2 ,
$$

where $p_u$ is `base price` when $P > 0$ or `upper price` when $P < 0$.

#### Price to trade a given volume

Finally, the protocol needs to calculate the inverse of the previous section. That is, given a volume bought from/sold to the AMM, at what price should the trade be executed. This could be calculated naively by summing across all the smallest increment volume differences, however this would be computationally inefficient and can be optimised by instead considering the full trade size. 


To calculate this, the interface will need the `starting price` $p_s$, `ending price` $p_e$, `upper price of the current range` $p_u$ (`upper price` if `P < 0` else `base price`), `lower price of the current range` $p_l$ (`base price` if `P < 0` else `lower price`), the volume to trade $\Delta x$ and the `L` value for the current range. At `P = 0` use the values for the range which the volume change will cause the position to move into.

First, the steps for calculating a fair price should be followed in order to obtain the implied price. Next the virtual `x` and `y` balances must be found:

  1. If `P > 0`:
     1. The virtual `x` of the position can be calculated as $x_v = P + \frac{L}{\sqrt{p_b}}$, where $L$ is the value for the lower range, $P$ is the market position and $p_b$ is the `base price`.
     1. The virtual `y` can be calculated as $y_v = L * \sqrt{p_f}$ where $p_f$ is the fair price calculated above.
  1. If `P < 0`:
     1. The virtual `x` of the position can be calculated as $x_v = P + \frac{c}{p_u} \cdotp r_f + \frac{L}{\sqrt{p_u}}$ where $p_u$ is the `upper price`.
     1. The virtual `y` can be calculated as $y_v = L * \sqrt{p_f}$ where $p_f$ is the fair price calculated above. 

Once obtained, the price can be obtained from the fundamental requirement of the product $y \cdot x$ remaining constant. This gives the relationship

$$
y_v \cdot x_v = (y_v + \Delta y) \cdot (x_v - \Delta x) ,
$$

From which $\Delta y$ must be calculated

$$
\Delta y = \frac{y_v \cdot x_v}{x_v - \Delta x} - y_v ,
$$

Thus giving a final execution price to return of $\frac{\Delta y}{\Delta x}$.

#### Volume between two prices

For the second interface one needs to calculate the volume which would be posted to the book between two price levels. In order to calculate this for an AMM one is ultimately asking the question "what volume of swap would cause the fair price to move from price A to price B?"

To calculate this, the interface will need the `starting price` $p_s$, `ending price` $p_e$, `upper price of the current range` $p_u$ (`upper price` if `P < 0` else `base price`) and the `L` value for the current range. At `P = 0` use the values for the range which the volume change will cause the position to move into.

First, calculate the implied position at `starting price` and `ending price` and return the difference.

For a given price $p$ calculate implied position $P_i$ with

$$
P_i = L \cdot \frac{\sqrt{p_u} - \sqrt{p}}{\sqrt{p} \cdotp \sqrt{p_u}} ,
$$

Then simply return the absolute difference between these two prices.

## Determining Liquidity Contribution

The provided liquidity from an AMM commitment must be determined for two reasons. Firstly to decide instantaneous distribution of liquidity fees between the various liquidity types and secondly to calculate a virtual liquidity commitment amount for assigning AMM users with an ELS value. This will be used for determining the distribution of ELS-eligible fees on a market along with voting weight in market change proposals.

As an AMM does not directly place orders on the book this calculation first needs to infer what the orders would be at each level within the eligible price bounds (those required by SLA parameters on the given market). From here any given AMM curve should implement functionality to take two prices and return the volume it would place to trade fully across that range. Calling this function across the price range out to lower and upper SLA bounds retrieves the full order book shape for each AMM.

Once these are retrieved, the price / volume points should be combined with a precomputed array of the probability of trading at each price level to calculate the liquidity supplied on each side of the orderbook as defined in [probability of trading](./0034-PROB-prob_weighted_liquidity_measure.ipynb). Once this is calculated, use this value as the instantaneous liquidity score for fee distribution as defined in [setting fees and rewards](./0042-LIQF-setting_fees_and_rewarding_lps.md).

As the computation of this virtual order shape may be heavy when run across a large number of passive AMMs the number of AMMs updated per block should be throttled to a fixed maximum number, updating on a rolling frequency, or when updated/first created.

A given AMM's average liquidity score across the epoch should also be tracked, giving a time-weighted average at the end of each epoch (including `0` values for any time when the AMM either did not exist or was not providing liquidity on one side of the book). From this, a virtual stake amount can be calculated by dividing through by the `market.liquidity.stakeToCcyVolume` value and the AMM key'
s ELS updated as normal.

## Setting Fees

The `proposed_fee` provided as part of the AMM construction contributes to the fee determination logic on the market, if a setup where LPs decide on the market fee is in use. In the case where it is the AMM's current assigned ELS, or the running average liquidity provided so far if the commitment was made in the current epoch, is used for weighting the AMM's vote for the fee.

## Market Settlement

At market settlement, an AMM's position will be settled alongside all others as if they are a standard party. Once settlement is complete, any remaining funds in the AMM's account will be transferred back to the creator's general account and the AMM can be removed.

## Acceptance Criteria

- When `market.amm.minCommitmentQuantum` is `1`, mid price of the market `100`, a user with `1000 USDT` is able to create a vAMM with commitment `1000`, base price `100`, upper price `150`, lower price `85` and leverage ratio at each bound `0.25`. (<a name="0087-VAMM-001" href="#0087-VAMM-001">0087-VAMM-001</a>)
- When `market.amm.minCommitmentQuantum` is `1`, mid price of the market `100`, a user with `1000 USDT` is able to create a vAMM with commitment `1000`, base price `100`, no upper price, lower price `85` and leverage ratio at lower bound `0.25`. (<a name="0087-VAMM-002" href="#0087-VAMM-002">0087-VAMM-002</a>)
- When `market.amm.minCommitmentQuantum` is `1`, mid price of the market `100`, a user with `1000 USDT` is able to create a vAMM with commitment `1000`, base price `100`, upper price `150`, no lower price and leverage ratio at upper bound `0.25`. (<a name="0087-VAMM-003" href="#0087-VAMM-003">0087-VAMM-003</a>)

- When `market.amm.minCommitmentQuantum` is `1`, mid price of the market `100`, a user with `100 USDT` is unable to create a vAMM with commitment `1000`, and any other combination of settings. (<a name="0087-VAMM-004" href="#0087-VAMM-004">0087-VAMM-004</a>)
- When `market.amm.minCommitmentQuantum` is `1000`, mid price of the market `100`, a user with `1000 USDT` is able to create a vAMM with commitment `100`, and any other combination of settings. (<a name="0087-VAMM-005" href="#0087-VAMM-005">0087-VAMM-005</a>)

- When `market.amm.minCommitmentQuantum` is `1000`, mid price of the market `100`, and a user with `1000 USDT` creates a vAMM with commitment `1000`, base price `100`, upper price `150`, lower price `85` and leverage ratio at each bound `0.25`:
  - If other traders trade to move the market mid price to `140` the vAMM has a short position. (<a name="0087-VAMM-006" href="#0087-VAMM-006">0087-VAMM-006</a>)
  - If other traders trade to move the market mid price to `90` the vAMM has a long position (<a name="0087-VAMM-007" href="#0087-VAMM-007">0087-VAMM-007</a>)
  - If other traders trade to move the market mid price to `150` the vAMM will post no further sell orders above this price, and the vAMM's position notional value will be equal to `4x` its total account balance. (<a name="0087-VAMM-008" href="#0087-VAMM-008">0087-VAMM-008</a>)
  - If other traders trade to move the market mid price to `85` the vAMM will post no further buy orders below this price, and the vAMM's position notional value will be equal to `4x` its total account balance.(<a name="0087-VAMM-009" href="#0087-VAMM-009">0087-VAMM-009</a>)
  - If other traders trade to move the market mid price to `110` and then trade to move the mid price back to `100` the vAMM will have a position of `0`. (<a name="0087-VAMM-010" href="#0087-VAMM-010">0087-VAMM-010</a>)
  - If other traders trade to move the market mid price to `90` and then trade to move the mid price back to `100` the vAMM will have a position of `0`. (<a name="0087-VAMM-011" href="#0087-VAMM-011">0087-VAMM-011</a>)
  - If other traders trade to move the market mid price to `90` and then in one trade move the mid price to `110` then trade to move the mid price back to `100` the vAMM will have a position of `0`. (<a name="0087-VAMM-012" href="#0087-VAMM-012">0087-VAMM-012</a>)
  - If other traders trade to move the market mid price to `90` and then move the mid price back to `100` in several trades of varying size, the vAMM will have a position of `0`. (<a name="0087-VAMM-013" href="#0087-VAMM-013">0087-VAMM-013</a>)
  - If other traders trade to move the market mid price to `90` and then in one trade move the mid price to `110` then trade to move the mid price to `120` the vAMM will have a larger (more negative) but comparable position to if they had been moved straight from `100` to `120`. (<a name="0087-VAMM-014" href="#0087-VAMM-014">0087-VAMM-014</a>)
  
- A vAMM which has been created and is active contributes with it's proposed fee level to the active fee setting mechanism. (<a name="0087-VAMM-015" href="#0087-VAMM-015">0087-VAMM-015</a>)
- A vAMM's virtual ELS should be equal to the ELS of a regular LP with the same committed volume on the book (i.e. if a vAMM has an average volume on each side of the book across the epoch of 10k USDT, their ELS should be equal to that of a regular LP who has a commitment which requires supplying 10k USDT who joined at the same time as them). (<a name="0087-VAMM-016" href="#0087-VAMM-016">0087-VAMM-016</a>)
  - A vAMM's virtual ELS should grow at the same rate as a full LP's ELS who joined at the same time. (<a name="0087-VAMM-017" href="#0087-VAMM-017">0087-VAMM-017</a>)
- A vAMM can vote in market update proposals with the additional weight of their ELS (i.e. not just from governance token holdings). (<a name="0087-VAMM-018" href="#0087-VAMM-018">0087-VAMM-018</a>)

- If a vAMM is cancelled with `Abandon Position` then it is closed immediately. All funds which were in the `general` account of the vAMM are returned to the user who created the vAMM and the remaining position and margin funds are moved to the network to close out as it would a regular defaulted position. (<a name="0087-VAMM-019" href="#0087-VAMM-019">0087-VAMM-019</a>)

- If a vAMM is cancelled and set in `Reduce-Only` mode when it is currently long, then: (<a name="0087-VAMM-020" href="#0087-VAMM-020">0087-VAMM-020</a>)
  - It creates no further buy orders even if the current price is above the configured lower price.
  - When one of it's sell orders is executed it still does not produce buy orders, and correctly quotes sell orders from a higher price.
  - When the position reaches `0` the vAMM is closed and all funds are released to the user after the next mark to market.


- If a vAMM is cancelled and set in `Reduce-Only` mode when it is currently short, then: (<a name="0087-VAMM-021" href="#0087-VAMM-021">0087-VAMM-021</a>)
  - It creates no further sell orders even if the current price is below the configured upper price.
  - When one of it's buy orders is executed it still does not produce sell orders, and correctly quotes buy orders from a lower price.
  - When the position reaches `0` the vAMM is closed and all funds are released to the user after the next mark to market.

- If a vAMM is cancelled and set in `Reduce-Only` mode when it currently has no position then all funds are released after the next mark to market. (<a name="0087-VAMM-022" href="#0087-VAMM-022">0087-VAMM-022</a>)

- If a vAMM is cancelled and set into `Reduce-Only` mode, then an amend is sent by the user who created it, the vAMM is amended according to those instructions and is moved out of `Reduce-Only` mode back into normal operation. (<a name="0087-VAMM-023" href="#0087-VAMM-023">0087-VAMM-023</a>)

- When `market.amm.minCommitmentQuantum` is `1000`, mid price of the market `100`, and a user with `1000 USDT` creates a vAMM with commitment `1000`, base price `100`, upper price `150`, lower price `85` and leverage ratio at each bound `0.25`: 
  - If other traders trade to move the market mid price to `140` the vAMM has a short position. (<a name="0087-VAMM-024" href="#0087-VAMM-024">0087-VAMM-024</a>)
  - If the vAMM is then amended such that it has a new base price of `140` it should attempt to place a trade to rebalance it's position to `0` at a mid price of `140`.
    - If that trade can execute with the slippage as configured in the request then the transaction is accepted. (<a name="0087-VAMM-025" href="#0087-VAMM-025">0087-VAMM-025</a>)
    - If the trade cannot execute with the slippage as configured in the request then the transaction is rejected and no changes to the vAMM are made. (<a name="0087-VAMM-026" href="#0087-VAMM-026">0087-VAMM-026</a>)

- When a user with `1000 USDT` creates a vAMM with commitment `1000`, base price `100`, upper price `150`, lower price `85` and leverage ratio at each bound `0.25`, if other traders trade to move the market mid price to `140` quotes with a mid price of `140` (volume quotes above `140` should be sells, volume quotes below `140` should be buys). (<a name="0087-VAMM-027" href="#0087-VAMM-027">0087-VAMM-027</a>)

- When a user with `1000 USDT` creates a vAMM with commitment `1000`, base price `100`, upper price `150`, lower price `85` and leverage ratio at each bound `0.25`, the volume quoted to move from price `100` to price `110` in one step is the same as the sum of the volumes to move in 10 steps of `1` e.g. `100` -> `101`, `101` -> `102` etc. (<a name="0087-VAMM-028" href="#0087-VAMM-028">0087-VAMM-028</a>)

- When a user with `1000 USDT` creates a vAMM with commitment `1000`, base price `100`, upper price `150`, lower price `85` and leverage ratio at each bound `0.25`, the volume quoted to move from price `100` to price `90` in one step is the same as the sum of the volumes to move in 10 steps of `1` e.g. `100` -> `99`, `99` -> `98` etc. (<a name="0087-VAMM-029" href="#0087-VAMM-029">0087-VAMM-029</a>)

- When a user with `1000 USDT` creates a vAMM with commitment `1000`, base price `100`, upper price `150`, lower price `85` and leverage ratio at each bound `0.25`:
  1. Take quoted volumes to move to `110` and `90`
  1. Execute a trade of the quoted size to move the fair price to `110`
  1. Take a quote to move to price `90`
  1. Ensure this is equal to the sum of the quotes from step `1` (with the volume from `100` to `110` negated) (<a name="0087-VAMM-030" href="#0087-VAMM-030">0087-VAMM-030</a>)

- When an AMM is active on a market at time of settlement with a position in a well collateralised state, the market can settle successfully and then all funds on the AMM key are transferred back to the main party's account (<a name="0087-VAMM-031" href="#0087-VAMM-031">0087-VAMM-031</a>)

- When an AMM is active on a market at time of settlement but the settlement price means that the party is closed out no funds are transfeered back to the main party's account (<a name="0087-VAMM-032" href="#0087-VAMM-032">0087-VAMM-032</a>)
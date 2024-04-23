# Spot Automated Market Maker Framework

## Summary

The automated market maker (AMM) framework is designed to allow for the provision of an on-chain market making methodology which automatically provides prices according to a simple set of rules based on current market data. These rulesets are not created with the expectation of providing any profit nor of remaining solvent under any specific conditions, and so should be limited to conceptually simple setups. The initial methodology follows a concentrated-liquidity style constant-function market setup, with configurable maximum and minimum price bounds.

An automated market maker is configured at a per-key level, and is enabled by submitting a transaction with the requisite parameters. At this point in time the protocol will move committed funds to a sub-account which will be used to manage margin for the AMM. Once enabled, the configuration will be added to the pool of available AMMs to be utilised by the matching engine.

Each party may have only one AMM configuration per market, and both Spot and Futures markets are eligible, with the behaviour differing slightly for each.

## Process Overview

The configuration and resultant lifecycle of an automated market maker is as follows:

- Party funds a key which will be used by the strategy with desired token amounts.
- Party submits a transaction containing configuration for the strategy on a given market. This will contain:
  - Amount of funds to commit
  - Price bounds (upper, lower)
- Once accepted, the network will transfer funds to a sub-account and use the other parameters for maintaining the position.
- The party can cancel the AMM at any time, with the spot balances immediately returned to their general accounts.

## Sub-Account Configuration

Each main Vega key will have one associated sub account for a given market, on which an AMM may be set up. The account key should be generated through a hash of the main account key plus the ID of the market to generate a valid Vega address in a predictable manner. Outside of the AMM framework the sub-accounts are treated identically to any other account, they will have the standard associated margin/general accounts and be able to place orders if required as with any other account. The key differentiator is that no external party will have the private key to control these accounts directly. The maintenance of such an account will be performed through a few actions:

- Creation: A sub-account will be funded when a user configures an AMM strategy with a set of criteria and a commitment amount. At this point in time the commitment amount will be transferred to the sub-account's general account and the AMM strategy will commence
- Cancellation: When the AMM is cancelled the strategy specified will be followed:
  - Balances are immediately returned to the user.
- Amendment: Updates the strategy or commitment for a sub-account

## Interface

All AMM configurations should implement two key interfaces:

- One taking simply the current state (`position` and `total funds`) and a trade (`volume`, `side`) and returning a quote price. This should also handle a trade of `volume = 0` to return a notional `fair price`
- The second taking (`position`, `total funds`, `side`, `start price`, `end price`) should return the full volume the AMM would trade between the two prices (inclusive).

## AMM Configurations

Initially there will only be one option for AMM behaviour, that of a constant-function curve, however there may be others available in future. As such, the parameters pertaining to this model in particular should be passed in their own structure such that the creation message is similar to:

#### Spot

```json
{
  base_commitment,
  quote_commitment,
  reference_price,
  market,
  slippage_tolerance_percentage,
  proposed_fee,
  concentrated_liquidity_params: {
    upper_price,
    lower_price,
  }
}
```

### Concentrated Liquidity - Spot

The `Concentrated Liquidity` AMM is a market maker utilising a Uniswap v3-style pricing curve for managing price based upon current market price. This allows for the market maker to automatically provide a pricing curve for any prices within some configurable range.

The concentrated liquidity market maker consists of a liquidity curve of prices specified by a given `upper price` at which the market maker will be fully in the `quote` currency and a `lower price` at which the market maker will be fully in the `base` currency. This is configured through a number of parameters:

- **Upper Price**: The base price is the central price for the market maker. When trading at this level the market maker will have a position fully in the `quote` currency. Volumes for prices below this level will be taken from the curve and no volumes will be offered above it.
- **Lower Price**: The maximum price bound for market making. Prices between the `upper price` and this price will have volume placed, with no orders below this price. 
- **Reference Price**: The price at which the specified commitment amount is the account's balance of that token (e.g. if this is the current market price, the commitment amount specified is exactly what will be taken). Note that by design if this price is above the `upper price` a non-zero base commitment specification is invalid, as is a non-zero quote commitment specification if this is below the `lower price`.
- One of:
  - **Commitment Base**: This is the initial volume of base token to transfer into the sub account for use in market making. If this amount is not currently available in the main account's general account the transaction will fail. If specified, the amount of quote token to transfer is implied from current market conditions
  - **Commitment Quote**: This is the initial volume of quote token to transfer into the sub account for use in market making. If this amount is not currently available in the main account's general account the transaction will fail. If specified, the amount of base token to transfer is implied from current market conditions.

Additionally, as all commitments require some processing overhead on the core, there should be a network parameter `market.amm.minCommitmentQuantum` which defines a minimum quantum for commitment. Any `create` or `amend` transaction where `commitment / asset quantum < market.amm.minCommitmentQuantum` should be rejected.

### Creation/Amendment Process

#### Creation

A `Concentrated Liquidity` AMM has an inherent linkage between position and implied price. By configuration, this position is fully in the quote asset at `upper price` and moves towards being fully in the base asset at `lower price`, however it is possible to configure an AMM such that this range is either covering, above or below the current market price. In order to bring the AMM in line with where it "should" be the AMM will take either the amount of base or quote asset desired and then imply the volume of the other at the current market price. The protocol will then attempt to take both amounts of assets from the user.

  1. A `market effective price` will be determined:
     1. If there is currently a `best bid` and `best ask` (including existing AMMs) and the market is in continuous trading then the mid price will be used.
     2. If there is only a bid or only an ask, and the market is in continuous trading, then that best bid or ask will be used.
     3. If the market is in auction the mark price will be used, or if that is unavailable then the indicative uncrossing price
  2. An `L` value will be calculated for the liquidity as specified below.
  3. The correct balances of base and quote tokens will be calculated given the `L` value and the `market effective price`
  4. These correct balances will be transferred from the user's balances to the AMM's. If they cannot be transferred the transaction will be rejected.

#### Amendment

The process as above will be followed. By utilising the new reference price, market price and calculated liquidity values the AMM's balance will be adjusted to be correct by transferring from/to the user's general accounts.

#### Cancellation

The AMM can be cancelled immediately and balances of both tokens will be transferred back to the user's general accounts.

### Determining Volumes and Prices

Although AMM prices are not placed onto the book as orders it is necessary to be able to be able to quote prices for a given volume, or know what trading volume would move the fair price to a certain level.

The volume to offer at each price level is determined by whether the price level falls between the upper and lower price bands alongside the market maker's current position. In order to calculate this, use the concept of `Virtual Liquidity` from Uniswap's concentrated liquidity model, corresponding to a theoretical shifted version of the actual liquidity curve to map to an infinite range liquidity curve. The exact mathematics of this can be found in the Uniswap v3 whitepaper and are expanded in depth in the useful guide [Liquidity Math in Uniswap v3](http://atiselsts.github.io/pdfs/uniswap-v3-liquidity-math.pdf). Here will be covered cover only the steps needed to obtain prices/volumes without much exposition.

The most important value to calculate is the liquidity, or $L$ value, which determines the balances of each token at any given price level. This can be uniquely determined from the specification of the bound prices, reference price and reference quantity.

Calling the reference price specified $p_r$, and the price bounds $p_u$ and $p_l$ for the upper and lower bounds respectively, if $p_r <= p_l$ then

$$
L = c_b \frac{\sqrt{p_l} \sqrt{p_u}}{\sqrt{p_u} - \sqrt{p_l}} ,
$$

$$
c_q = 0 ,
$$

where $c_b$ is the base commitment value specified (note that as $p_r <= p_l$ it would be invalid to specify a quote commitment value). Similarly, if $p_r >= p_u$ then

$$
L = \frac{c_q}{\sqrt{p_u} - \sqrt{p_l}} ,
$$

$$
c_b = 0 ,
$$


where $c_q$ is the quote commitment value specified (note that as $p_r >= p_l$ it would be invalid to specify a base commitment value).

In the final case where $p_l < p_r < p_u$ we can think of there being two separate ranges, one above (from $p_r$ to $p_u$) and one below ($p_l$ to $p_r$). In the upper range the AMM is fully in the base asset, in the lower it is fully in the quote asset. Thus, the protocol can take the specified commitment value, calculate $L$ with that on the relevant range. 

Concretely:

If $c_q$ is specified

$$
L = \frac{c_q}{\sqrt{p_r} - \sqrt{p_l}} ,
$$

$$
c_b = L \frac{\sqrt{p_u} - \sqrt{p_r}}{\sqrt{p_u} \sqrt{p_r}}
$$

and if $c_b$ is specified

$$
L = c_b \frac{\sqrt{p_l} \sqrt{p_r}}{\sqrt{p_r} - \sqrt{p_l}} ,
$$

$$
c_q = L (\sqrt{p_r} - \sqrt{p_l}) ,
$$

#### Fair price

The fair price can then be calculated as 
   
$$
p_f = \frac{b_q + L \sqrt{p_l}}{b_b + \frac{L}{\sqrt{p_u}}} ,
$$

where $b_q$ is the current balance of the quote token and $b_b$ is the current balance of the base token.

#### Price to trade a given volume

Finally, the protocol needs to calculate the inverse of the previous section. That is, given a volume bought from/sold to the AMM, at what price should the trade be executed. This could be calculated naively by summing across all the smallest increment volume differences, however this would be computationally inefficient and can be optimised by instead considering the full trade size. 

First, the virtual `x` and `y` balances must be found (where `x` is the base balance and `y` is the quote balance):

$$
x_v = b_b + \frac{L}{\sqrt{p_u}} ,
$$

$$
y_v = b_q + L \sqrt{p_l} ,
$$

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

To calculate this, the interface will need the `starting price` $p_s$, `ending price` $p_e$, `upper price` $p_u$ and the `L`. At `P = 0` use the values for the range which the volume change will cause the position to move into.

First, calculate the implied position at `starting price` and `ending price` and return the difference.

For a given price $p$ calculate implied position $P_i$ with

$$
P_i = L \cdot \frac{\sqrt{p_u} - \sqrt{p}}{\sqrt{p} \cdotp \sqrt{p_u}} ,
$$

Then simply return the absolute difference between these two prices.

## Determining Liquidity Contribution

Liquidity contribution for spot AMMs should be determined identically to that for futures market vAMMs in [0089-VAMM](./0089-VAMM-automated_market_maker.md)

## Setting Fees

The `proposed_fee` provided as part of the AMM construction contributes to the fee determination logic on the market, if a setup where LPs decide on the market fee is in use. In the case where it is the AMM's current assigned ELS, or the running average liquidity provided so far if the commitment was made in the current epoch, is used for weighting the AMM's vote for the fee.

## Market Settlement

At market settlement, an AMM's position will be settled alongside all others as if they are a standard party. Once settlement is complete, any remaining funds in the AMM's account will be transferred back to the creator's general account and the AMM can be removed.

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
- Once accepted, the network will transfer funds to a sub-account and use the other parameters for maintaining the position.
- At each block, the party's available balance (including margin and general accounts) for trading on the market will be checked. If the total balance is `0` the AMM configuration will be cancelled. 
- If the party submits a `CancelAMM` transaction the AMM configuration for that party, on that market, will be cancelled. All active orders from the AMM will be cancelled and all funds and positions associated with the sub-account will be transferred back to the main account.

## Sub-Account Configuration

Each main Vega key will have one associated sub account for a given market, on which an AMM may be set up. The account key should be generated through a hash of the main account key plus the ID of the market to generate a valid Vega address in a predictable manner. Outside of the AMM framework the sub-accounts are treated identically to any other account, they will have the standard associated margin/general/bond accounts and be able to place orders if required as with any other account. The key differentiator is that no external party will have the private key to control these accounts directly. The maintenance of such an account will be performed through a few actions:

- Creation: A sub-account will be funded when a user configures an AMM strategy with a set of criteria and a commitment amount. At this point in time the commitment amount will be transferred to the sub-account's general account and the AMM strategy will commence
- Cancellation: When the AMM is cancelled all active orders are first cancelled. Following this cancellation, all funds in the sub-account's margin account should be transferred to the associated main account's margin account, with the same then happening for funds in the general account. Finally, any associated non-zero position on the market should be reassigned from the sub-account to the main account. At this point processing can continue, allowing the standard margining cycle to perform any required transfers from margin to general account.

## AMM Configurations

### Concentrated Liquidity

The `Concentrated Liquidity` AMM is a market maker utilising a Uniswap v3-style pricing curve for managing price based upon current market price. This allows for the market maker to automatically provide a pricing curve for any prices within some configurable range, alongside offering the capability to control risk by only trading within certain price bounds and out to known position limits.

The concentrated liquidity market maker consists of two liquidity curves of prices joined at a given `base price`, an `upper` consisting of the prices above this price point and a `lower` for prices below it. At prices below the `base price` the market maker will be in a long position, and at prices above this `base price` the market maker will be in a short position. This is configured through a number of parameters:

- **Base Price**: The base price is the central price for the market maker. When trading at this level the market maker will have a position of `0`. Volumes for prices above this level will be taken from the `upper` curve and volumes for prices below will be taken from the `lower` curve.
- **Upper Price**: The maximum price bound for market making. Prices between the `base price` and this price will have volume placed, with no orders above this price. This is optional and if not supplied no volume will be placed above `base price`. At these prices the market maker will always be short
- **Lower Price**: The minimum price bound for market making. Prices between the `base price` and this will have volume placed, with no orders below this price. This is optional and if not supplied no volume will be placed below `base price`. At these prices the market maker will always be long
- **Commitment**: This is the initial volume of funds to transfer into the sub account for use in market making. If this amount is not currently available in the main account's general account the transaction will fail.

Note that the independent long and short ranges mean that at `base price` the market maker will be flat with respect to the market with a `0` position. This means that a potential market maker with some inherent exposure elsewhere (likely long in many cases as a token holder) can generate a position which is always either opposite to their position elsewhere (with a capped size), thus offsetting pre-existing exposure, or zero.

#### Matching Process (To merge with 0068-MATC once confirmed)

For all incoming active orders, the matching process will coordinate between the on- and off-book sources of liquidity. When an order comes in which may immediately trade (there are not already resting orders of the same type for the best applicable price) the following steps should be followed. If at any point the order's full volume has traded the process is immediately halted:

  1. For the first applicable price level, all on-book orders should be checked. Any volume at this price level which can be met through on-book orders will then trade. 
  1. For any `remaining volume`, the AMMs will be checked. This requires an algorithm to ensure we do not have to check every price level individually:
     1. Call the current price level `current price`
     1. Check the price level which has the next resting on-book order, set this to be the `outer price` for the check.
     1. Check all active AMMs, collect those where `current_price` is between their `upper price` and `lower price`.
     1. Within these, select either the minimum `upper price` (if the incoming order is a buy) or the maximum `lower price` (if the incoming order is a sell), call this `amm bound price`. This is the range where all of these AMMs are active. Finally, select either the minimum (for a buy) or maximum (for a sell) between `amm bound price` and `outer price`. From this form an interval `current price, outer price`. 
     1. Now, for each AMM within this range, calculate the volume of trading required to move each from the `current price` to the `outer price`. Call the sum of this volume `total volume`.
     1. If `remaining volume <= total volume` split trades between the AMMs according to their proportional contribution to `total volume` (e.g. larger liquidity receives a higher proportion of the trade). This ensures their mid prices will move equally (TODO: Is trade splitting more involved than this?).
     1. If `remaining volume > total volume` execute all trades to move the respective AMMs to their boundary at `outer price`. Now, return to step `1` with `current price = outer price`, checking first for on-book liquidity at the new level then following this process again until all order volume is traded or liquidity exhausted.  

#### Determining Margin

TODO


- Expand out order book, sample once per block one LP perhaps
- ELS minimum value per epoch
- Can pools cross? Post only?
  - If they cross they cross
- ELS fraction configuration
- On entry/adjustment rebase AMM


#### Determining Volumes for Display

Although AMM prices are not placed onto the book as orders it is important for users to be able to see a combined view of all available liquidity, and the clearest way to do so is in an orderbook format. As such, we need an algorithm to convert the compact representation of an AMM (`upper price`, `base price`, `lower price`, `available funds`, `position`) to orderbook price levels. This should not be performed in core, which will output the aforementioned compact representation, but may be executed in any downstream component, such as a data node, in order to generate a virtual order book from AMM positions

The volume to offer at each price level is determined by whether the price level falls within the upper or lower price bands alongside the market maker's current position. In order to calculate this we use the concept of `Virtual Liquidity` from Uniswap's concentrated liquidity model, corresponding to a theoretical shifted version of the actual liquidity curve to map to an infinite range liquidity curve. The exact mathematics of this can be found in the Uniswap v3 whitepaper and are expanded in depth in the useful guide [Liquidity Math in Uniswap v3](http://atiselsts.github.io/pdfs/uniswap-v3-liquidity-math.pdf).

The calculation for setting volumes at each level can be broken into two steps. First, the `reference price` must be determined. This is the price implied by the market maker's current position vs the maximum allowed by the configuration and can be thought of as the market maker's current mid price. From there, the shape of the orders can be determined by calculating the volume of futures which would have to be bought(/sold) to move the price to various price levels above(/below) the `reference price`. If a price move would switch to the other curve then the cumulative amount to shift to the `reference price` is taken then the other curve is used.

For calculating the reference price:

  1. Select the appropriate liquidity curve. If the market maker's current position is `<=0` then the curve `[base price, upper price]` should be used. If the market maker's current position is `>0` then the curve `[lower price, base price]` should be used.
  2. Calculate the theoretical liquidity value of the position, which can later be used to calculate the price moves for trade amounts. This is performed by utilising the simplification that at the top of each respective range (`base price` for the lower range and `upper price` for the upper range) the position will be fully in cash.
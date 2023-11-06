# Automated Market Maker Framework

## Summary

The automated market maker (AMM) framework is designed to allow for the provision of an on-chain market making methodology which automatically provides prices according to a simple set of rules based on current market data. These rulesets are not created with the expectation of providing any profit nor of remaining solvent under any specific conditions, and so should be limited to conceptually simple setups. The initial methodology follows a concentrated-liquidity style constant-function market setup, with configurable maximum and minimum price bounds.

An automated market maker is configured at a per-key level, and is enabled by submitting a transaction with the requisite parameters. At this point in time the protocol will move committed funds to a sub-account which will be used to manage order and position margin for the AMM. Once enabled, the configuration will be queried once per block and the resultant orders will be placed on the book, combined with all current orders from the key being cancelled. 

Each party may have only one AMM configuration per market.

## Process Overview

The configuration and resultant lifecycle of an automated market maker is as follows:

- Party funds a key which will be used by the strategy with desired token amounts.
- Party submits a transaction containing configuration for the strategy on a given market. This will contain:
  - Amount of funds to commit
  - Price bounds (upper, lower, base)
  - Granularity of price levels to post
- Once accepted, the network will transfer funds to a sub-account and use the other parameters for maintaining the position.
- At each block, immediately prior to the evaluation of liquidity provision for SLA purposes, for each configured AMM:
  - The party's available balance (including margin and general accounts) for trading on the market will be checked. If the total balance is `0` the AMM configuration will be cancelled. 
  - Each running AMM will be queried for it's provided orders. All orders from this party on this market will then be cancelled, followed by the placement of these new orders on the book. There are a couple of things to note here:
    - All orders are placed as-if arriving from the party's key externally.
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
- **Volume at Upper Limit**: The volume the market maker will hit at the upper limit (this will be a short volume). Note that as the market maker is operating a constant function market curve there is an inherent link between traded price and position which allows this assertion. The combination of this volume and the range between `base price` and `upper price` will determine the volume placed at each price level inbetween.
- **Volume at Lower Limit**: The volume the market maker will hit at the lower limit (this will be a long volume). Note that as the market maker is operating a constant function market curve there is an inherent link between traded price and position which allows this assertion. The combination of this volume and the range between `base price` and `lower price` will determine the volume placed at each price level inbetween.

Note that the independent long and short ranges mean that at `base price` the market maker will be flat with respect to the market with a `0` position. This means that a potential market maker with some inherent exposure elsewhere (likely long in many cases as a token holder) can generate a position which is always either opposite to their position elsewhere (with a capped size), thus offsetting pre-existing exposure, or zero.

#### Determining Margin

Although the AMM does not directly post orders onto 



#### Determining Volumes

There are two potential approaches to how a concentrated liquidity AMM interacts with the market, these can be summarised as:

- Placing orders directly on the book
  - This approach entails the AMM generating orders at some frequency and placing them directly on the book. In this case for the rest of the system behaviour would be identical to if an external party were placing these orders and managing any resulting trades
- A separate off-book liquidity source, which is queried after trades at each price level
  - This approach entails the AMM acting as a separate liquidity pool which only acts when an aggressive order arrives. At that point in time, for each price level the protocol would first check the order book for volume, trading with that if it is available, it would then check for any AMMs offering volume at that price level, trading with those if available, before moving on to the next best price level in a similar manner. 


For each, there are associated benefits and risks:

- Placing orders directly on the book
  - Benefits
    - Outside the loop of generating and placing these orders the system needs very few changes, everything else can interact with and visualise the market as before
  - Risks
    - A large number of orders may need to be generated each time the AMM is updated. It is possible that this compounding with large numbers of people utilising an AMM could result in performance impacts.
    - If the AMMs update too infrequently the spread on the market could widen (as opposed to a true AMM which updates immediately after each trade). A once-per-block update would mean that a buy immediately following someone else's sell would not benefit from the reduced price on the AMM
- Separate off-book liquidity
  - Benefits
    - Only requires updating or interacting with on the arrival of orders which may immediately trade, improving performance
    - Acts as a more 'pure' AMM structure, immediately updating on each trade before interacting with the next
  - Risks
    - The AMMs would have to be each checked for every tick on the market, adding a performance impact to the choice of decimal places, or another parameter which needed to be set for tick size of AMMs on a market. It is possible this performance impact is significant.
      - This also requires that core matching code outside the new AMM logic is aware of these changes and can handle them, potentially adding uncertainty to scope of change work.
    - A "complete" order book picture would now require understanding the AMM presence at a given timepoint too. To build a full order book, calculations would have to be performed in downstream systems to expand the AMM into virtual orders, combining those with real orders resting on the book. Failure to do this correctly would result in an inaccurate picture of available liquidity.
    - Additional margin considerations for the AMM. When expanding out the AMM to virtual orders for a book, how does one ensure liquidity is not shown which would actually not be tradable with the funds available to that AMM.



## TBC

#### Determining Volumes

The volume to offer at each price level is determined by whether the price level falls within the upper or lower price bands alongside the market maker's current position. In order to calculate this we use the concept of `Virtual Liquidity` from Uniswap's concentrated liquidity model, corresponding to a theoretical shifted version of the actual liquidity curve to map to an infinite range liquidity curve. The exact mathematics of this can be found in the Uniswap v3 whitepaper and are expanded in depth in the useful guide [Liquidity Math in Uniswap v3](http://atiselsts.github.io/pdfs/uniswap-v3-liquidity-math.pdf).

The calculation for setting volumes at each level can be broken into two steps. First, the `reference price` must be determined. This is the price implied by the market maker's current position vs the maximum allowed by the configuration and can be thought of as the market maker's current mid price. From there, the shape of the orders can be determined by calculating the volume of futures which would have to be bought(/sold) to move the price to various price levels above(/below) the `reference price`. If a price move would switch to the other curve then the cumulative amount to shift to the `reference price` is taken then the other curve is used.

For calculating the reference price:

  1. Select the appropriate liquidity curve. If the market maker's current position is `<=0` then the curve `[base price, upper price]` should be used. If the market maker's current position is `>0` then the curve `[lower price, base price]` should be used.
  2. Calculate the theoretical liquidity value of the position, which can later be used to calculate the price moves for trade amounts. This is performed by utilising the simplification that at the top of each respective range (`base price` for the lower range and `upper price` for the upper range) the position will be fully in cash.
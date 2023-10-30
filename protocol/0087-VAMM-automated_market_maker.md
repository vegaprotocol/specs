# Automated Market Maker Framework

## Summary

The automated market maker (AMM) framework is designed to allow for the provision of an on-chain market making methodology which automatically provides prices according to a simple set of rules based on current market data. These rulesets are not created with the expectation of providing any profit nor of remaining solvent under any specific conditions, and so should be limited to conceptually simple setups. The initial methodology follows a concentrated-liquidity style constant-function market setup, with configurable maximum and minimum price bounds.

An automated market maker is configured at a per-key level, and is enabled by submitting a transaction with the requisite parameters. Once enabled, the configuration will be queried once per block and the resultant orders will be placed on the book, combined with all current orders from the key being cancelled. The party configuring the market maker is responsible for ensuring that the orders generated meet the requirements for any liquidity commitment which is also associated to the key.

Each party may have only one AMM configuration per market.

## Process Overview

The configuration and resultant lifecycle of an automated market maker is as follows:

- Party funds a key which will be used by the strategy with desired token amounts.
- Party submits a transaction containing configuration for the strategy on a given market. This may vary, but will likely contain parameters such as:
  - Maximum position notional/absolute value
  - Price bounds
  - Granularity of price levels to post
- Once accepted, the network will begin to monitor the configured strategy on that key.
- At each block, immediately prior to the evaluation of liquidity provision for SLA purposes, for each configured AMM:
  - The party's available balance (including margin and general accounts) for trading on the market will be checked. If the total balance is `0` the AMM configuration will be cancelled. 
  - Each running AMM will be queried for it's provided orders. All orders from this party on this market will then be cancelled, followed by the placement of these new orders on the book. There are a couple of things to note here:
  - All orders are placed as-if arriving from the party's key externally.
  - No bond is taken for the market maker, the party is responsible for ensuring the key remains sufficiently collateralised.
  - No lock is placed on the key, the party may continue to sign and submit other trading transactions and orders. However, any orders resting on the book will be cancelled alongside others each time the AMM updates.
- If the party submits a `CancelAMM` transaction the AMM configuration for that party, on that market, will be cancelled, alongside all orders the party currently has active. Any resultant position will remain (will not be closed out) and is the responsibility of the party to manage.

## AMM Configurations

### Concentrated Liquidity

The `Concentrated Liquidity` AMM is a market maker utilising a Uniswap v3-style pricing curve for managing price based upon current market price. This allows for the market maker to automatically provide a pricing curve for any prices within some configurable range, alongside offering the capability to control risk by only trading within certain price bounds and out to known position limits.

The concentrated liquidity market maker consists of two liquidity curves of prices joined at a given `base price`, an `upper` consisting of the prices above this price point and a `lower` for prices below it. At prices below the `base price` the market maker will be in a long position, and at prices above this `base price` the market maker will be in a short position. This is configured through a number of parameters:

- **Base Price**: The base price is the central price for the market maker. When trading at this level the market maker will have a position of `0`. Volumes for prices above this level will be taken from the `upper` curve and volumes for prices below will be taken from the `lower` curve.
- **Upper Price**: The maximum price bound for market making. Prices between the `base price` and this price will have volume placed, with no orders above this price. This is optional and if not supplied no volume will be placed above `base price`. At these prices the market maker will always be short
- **Lower Price**: The minimum price bound for market making. Prices between the `base price` and this will have volume placed, with no orders below this price. This is optional and if not supplied no volume will be placed below `base price`. At these prices the market maker will always be long
- **Volume at Upper Limit**: The volume the market maker will hit at the upper limit (this will be a short volume). Note that as the market maker is operating a constant function market curve there is an inherent link between traded price and position which allows this assertion. The combination of this volume and the range between `base price` and `upper price` will determine the volume placed at each price level inbetween.
- **Volume at Lower Limit**: The volume the market maker will hit at the lower limit (this will be a long volume). Note that as the market maker is operating a constant function market curve there is an inherent link between traded price and position which allows this assertion. The combination of this volume and the range between `base price` and `lower price` will determine the volume placed at each price level inbetween.

_To Determine_: Should tick spacing be customisable or enforced?

Note that the independent long and short ranges mean that at `base price` the market maker will be flat with respect to the market with a `0` position. This means that a potential market maker with some inherent exposure elsewhere (likely long in many cases as a token holder) can generate a position which is always either opposite to their position elsewhere (with a capped size), thus offsetting pre-existing exposure, or zero.

#### Determining Volumes

The volume to offer at each price level is determined by whether the price level falls within the upper or lower 
# Liquidity providing bots on Vega testnets

## Introduction

At the moment bots on Vega run on certain markets to make them look "real".

For that purpose they:

1. Are given large amounts of collateral via faucets.
1. Keep track of current spot or futures price on another exchange (at e.g. 30s, 5 min intervals)
1. Post GTC limit orders randomly on both sides of the order book at random volumes using the above reference price as mid.

This achieves the following: the price on the market looks "real" and there is volume for participants to trade.

The downside is that if the bot is "unlucky" they can run out of even large amount of collateral and their orders / positions are liquidated. To avoid this they need regular collateral top-ups.

From Flamenco Tavern onwards any market on Vega will need a committed liquidity provider, see [LP mechanics spec](../protocol/0044-LIME-lp_mechanics.md) to function. See also [LP order type spec](../protocol/0038-OLIQ-liquidity_provision_order_type.md).

If a feature is marked as "optional" then the bot can be configured in such a way that it is not providing this functionality but still doing other tasks.

The aim of this spec is bots that:

1. submit a market proposal (optional) or connects to an existing market
1. serve as a liquidity provider for the market by submitting the [LP order type](../protocol/0038-OLIQ-liquidity_provision_order_type.md) (optional).
1. participate in an opening auction (optional)
1. create markets that look real with more-or-less correct price by placing limit orders that "steer" the price up-or-down as appropriate (optional)
1. manage their position in such a way so as to not require ever growing amount of collateral. This will mean changing the "shape" in the liquidity provision order and also being strategic about placing limit orders to steer the price. The bot can have an optional position limit.
1. the code should be "nice" and "as simple as possible" so it can be shared with community (open sourced).

## Proposed solution

The bot needs to be able to query Vega to know it's balances, orders and positions.
The bot needs to be able to query Vega to know the risk model and parameters for the market.

### Configuration

- vega Wallet credentials
- market proposal file
- market ID (the market to engage with), can come from proposal above
- reference price source (optional), it is assumed that this is updated in real time. provided by an independent process / bot to keep things simple here. So in particular if a price source has API time limits then a separate bot / process should be accessing the price source and making up random price moves to fill the `time(*)` and , _not_ the bot we are specifying here.
- `expectedMarkPrice` (optional, can be from the reference price above). This will be used in markets that don't yet have mark price to calculate margin cost of orders meeting liquidity requirement.
- `auctionVolume`
- `maxLong` and `maxShort` position limits and `posManagementFraction` controlling size of market order used to manage position
- `stakeFraction`, `ordersFraction`, these will be used in rule-of-thumb heuristics to decide how the bot should deploy collateral.
- `shorteningShape`, `longeningShape` both of these are _both_ sides of the book (note that the initial shape used will be the buying shape because being long is a little cheaper in position margin than being short)
- `positionManagementSleep` e.g. 10s and `posManagementFraction` e.g. `0.1`
- `marketPriceSteeringRate` e.g. 2 per second would be 2
- `targetLNVol` target log-normal volatility (e.g. 0.5 for 50%),  `limitOrderDistributionParams` (a little data structure which sets the algorithm and parameters for how limits orders are generated).

(*) This separate process will then also need to use correct distributions to make the price moves look plausible.

### Submitting a market proposal

This is only relevant if the option to submit a market proposal is enabled.

The bot will read the required market proposal from a file (configuration option), decide if it has minimum LP stake in the right asset, check it's got enough vote tokens and then submit the proposal and vote for it. They will also need to submit [liquidity shapes](../protocol/0038-OLIQ-liquidity_provision_order_type.md) but that will be treated below.
To decide that it will ask Vega for `assetBalance`, `quantum` for asset and `min_LP_stake_quantum_multiple` and proceed if `assetBalance x stakeFraction > min_LP_stake_quantum_multiple x quantum`

It will then check whether it has enough collateral for maintaining the commitment but that will be described below as it applies below too.

### Serving as a liquidity provider for a market

This section is only relevant if: a) the option to act as a liquidity provider is selected or b) the bot submitted a new market proposal as this needs a minimum liquidity commitment [LP mechanics](../protocol/0044-LIME-lp_mechanics.md ).

Step 1. decide what current price is.

```go
if market.Open() == true then
    currentPrice = market.markPrice()
else if haveOwnReferencePrice == true then
    currentPrice = referencePrice
else if haveOwnExpectedPrice == true then
    currentPrice = expectedMarkPrice
else
    throw Error("Can't estimate costs and hence cannot run reasonably safely.")
```

Step 2. take the `currentPrice`, query Vega for risk model and parameters and use these to calculate

```go
defBuyingShapeMarginCost = CalculateMarginCost(risk model params, currentPrice, defaultBuyingShape)

defSellingShapeMarginCost = CalculateMarginCost(risk model params, currentPrice, defaultSellingShape)

shapeMarginCost = max(defBuyingShapeMarginCost,defSellingShapeMarginCost)

if assetBalance * ordersFraction < shapeMarginCost
    throw Error("Not enough collateral to safely keep orders up given current price, risk parameters and supplied default shapes.")
else
    proceed by submitting the LP order with the defaultBuyingShape to the market.
```

Step 3. Repeat the following forever:

```go
positionManagementTimer.start()
if (positionManagementTimer > positionManagementSleep) then
    if botPositionLong() == true and botCurrentMood() == "buying" then
        submit LP order with shorteningShape
    else if botPositionLong() == false and botCurrentMood() == "selling" then
        submit LP order with longeningShape
    fi
    positionManagementTimer.reset()
    positionManagementTimer.start()
fi
```

### Participate in an opening auction

This section is only relevant if the option to participate in an opening auction is selected and the relevant market given by the market ID is still in an opening auction.

If the bot has `currentPrice` then it should place  buy / sell limit orders (good till time with duration a bit longer than opening auction length) in the auction at random distance and volume away from `currentPrice` up to total `auctionVolume`.
The distance and volume should be consistent with market risk parameters.

### Create markets that look real

This section is only relevant if the bot is configured with a price source providing a reference price.

Place good till time limit orders of some duration near the reference price consistently with `targetLNVol` according to `limitOrderDistributionParams`.

Example:

```proto
limitOrderDistributionParams = {
    method = "dicreteThreeLevel"
    gttLengh = "60s"
    tgtTimeHorizon = "1 hour"
    tickSize = 0.01
    numTicksFromMid = 5
    tgtOrdersPerSecond = 2
    numIdenticalBots = 3
}
```

With the above example you can generate the correct orders using the method in the [notebook](./0010-NP-BOTC-bot_parameter_calc_and_test.ipynb) with `delta=tickSize x numTicksFromMid` and `N = 3600 x 2 / 3`.

Another Example:

```proto
limitOrderDistributionParams = {
    method = "coinAndBinomial"
    gttLengh = "60s"
    tgtTimeHorizon = "1 hour"
    tickSize = 0.01
    numTicksFromMidMax = 5 // nMoves in IPython notebook
    tgtOrdersPerSecond = 0.5 // i.e. one order every 2 seconds
    numIdenticalBots = 10
}
```

Again, the algorithm for choosing the parameters and generating samples is in the [notebook](./0010-NP-BOTC-bot_parameter_calc_and_test.ipynb) with `delta=tickSize x numTicksFromMid` and `N = 3600 x 0.5 / 10`.

Generate the orders using the above method _but_:

If the position of the bot is long _only_ place sell orders.

If the position of the bot is short _only_ place buy orders here.

### Manage their position

Some of this is taken care of above already but this is a more drastic behaviour that will lead to placing market orders to actively reduce position.

Note that Vega uses worst long / short internally so orders and positions margins gets mixed up; here we use a more basic heuristic which, while not optimal, is simpler.

Repeat the following:

```go
// positionManagementSleep is a config param, in seconds

positionManagementTimer.start()
if (positionManagementTimer > positionManagementSleep) then


    //asset is the asset of the market the bot is on
    balance = VegaNode.PleaseTellMeMyBalance(asset)
    position = VegaNode.PleaseTellMeMyPosition() // negative for short
    posMarginCost = calculatePositionMarginCost(position, currentPrice, risk parameters)

    shouldBuy = false
    shouldSell = false
    if posMarginCost > (1.0 - stakeFraction - ordersFraction) * currentBalance
        if position > 0 then
            shouldSell = true
        else
            shouldBuy = true
        fi
    else if position > maxLong then
        shouldSell = true
    else if -position > maxShort then
        shouldBuy = true
    fi

    // sanity check
    if shouldBuy and shouldSell then
        throw Error("WTF")
    fi

    if shouldBuy then
        place a market buy order for posManagementFraction x position volume
    else if shouldSell then
        place a market sell order for posManagementFraction x (-position) volume
    fi

    positionManagementTimer.reset()
    positionManagementTimer.start()
fi
```

### The code should be "nice" and "as simple as possible"

Don't use any of the pseudocode above!

### Acceptance criteria

1. Bot can submit a market proposal (optional), commit liquidity and then manage it's position as described above, see also [LP order type](../protocol/0038-OLIQ-liquidity_provision_order_type.md). (<a name="0001-NP-LIQB-001" href="#0001-NP-LIQB-001">0001-NP-LIQB-001</a>)
1. Bot can connect to an existing market, submit an [LP order type](../protocol/0038-OLIQ-liquidity_provision_order_type.md) and then manage it's position as described above. (<a name="0001-NP-LIQB-002" href="#0001-NP-LIQB-002">0001-NP-LIQB-002</a>)
1. Bot can participate in an opening auction placing orders around target price (set via parameters, see above).(<a name="0001-NP-LIQB-003" href="#0001-NP-LIQB-003">0001-NP-LIQB-003</a>)
1. Can read a price target from external source and and places limit orders that "steer" the price up-or-down as appropriate and have the right `targetLNVol` using one of the methods above (note that this has to take into account other identical bots trying to do the same on the same market).(<a name="0001-NP-LIQB-004" href="#0001-NP-LIQB-004">0001-NP-LIQB-004</a>)
1. Bot manages its position in such a way that it stays close to zero and starts placing market orders if configured maxima are breached.(<a name="0001-NP-LIQB-005" href="#0001-NP-LIQB-005">0001-NP-LIQB-005</a>)
    1. The repository is public from the start.
    1. Bot is not called `Bot Mc BotFace`.

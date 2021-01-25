# Liquidity providing bots on Vega testnets

## Introduction

At the moment bots on Vega run on certain markets to make them look "real". 
For that purpose they:
1. Are given large amounts of collateral via faucets.
1. Keep track of current spot or futures price on another exchange (at e.g. 30s, 5 min intervals)
1. Post GTC limit orders randomly on both sides of the order book at random volumes using the above reference price as mid.

This achieves the following: the price on the market looks "real" and there is volume for participants to trade. 

The downside is that if the bot is "unlucky" they can run out of even large amount of collateral and their orders / positions are liquidated. To avoid this they need regular collateral top-ups.  

From Flamenco Tavern onvards any market on Vega will need a committed liquidity provider, see [LP mechanics spec](../specs/0044-lp-mechanics.md) to function. See also [LP order type spec](../specs/0038-liquidity-provision-order-type.md). 

If a feature marked "optional" then the bot can be configured in such a way that it is not providing this functionality but still doing other tasks.
The aim of this spec is bots that
1. submits a market proposal (optional) or connects to an existing market
1. serve as a liquidity provider for the market by submitting the [LP order type](../specs/0038-liquidity-provision-order-type.md) (optional).
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
- reference price source (optional), it is assumed that this is updated in real time and let's discuss this it may be best if this is provided by an independent bot to keep things simple here. So in particular if a price source has API time limits then the bot accessing the price source should be the one making up random price moves to fill the time, *not* the bot we are specc'ing here.
- `expectedMarkPrice` (optional, can be from the reference price above). This will be used in markets that don't yet have mark price to calculate margin cost of orders meeting liquidity requirement.
- `auctionVolume`
- `maxLong` and `maxShort` position limits and `posManagementFraction` controlling size of market order used to manage position
- `stakeFraction`, `ordersFraction`, these will be used in rule-of-thumb heuristics to decide how the bot should deploy collateral.
- `shorteningShape`, `longeningShape` both of these are *both* sides of the book (note that the initial shape used will be the buying shape because being long is a little cheaper in position margin than being short)
- `positionManagementSleep` e.g. 10s and `posManagementFraction` e.g. `0.1`
- `marketPriceSteeringRate` e.g. 2 per second would be 2

### Submitting a market proposal
The bot will read the required market proposal from a file (configuration option), decide if it has minimum LP stake in the right asset, check it's got enough vote tokens and then submit the proposal and vote for it. They will also need to submit [liquidity shapes](../specs/0038-liquidity-provision-order-type.md) but that will be treated below. 
To decide that it will ask Vega for `assetBalance` and `minimumLpStakeForAsset` and proceed if 
```
assetBalance * stakeFraction > minimumLpStakeForAsset
```
It will then check whether it has enough collateral for maintaining the commitment but that will be described below as it applies below too. 

### Serving as a liquidity provider for a market

Step 1. decide what current price is. 
``` 
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
```
defBuyingShapeMarginCost = CalculateMarginCost(risk model params, currentPrice, defaultBuyingShape) 

defSellingShapeMarginCost = CalculateMarginCost(risk model params, currentPrice, defaultSellingShape) 

shapeMarginCost = max(defBuyingShapeMarginCost,defSellingShapeMarginCost)

if assetBalance * ordersFraction < shapeMarginCost
    throw Error("Not enough collateral to safely keep orders up given current price, risk parameters and supplied default shapes.")
else 
    proceed by submitting the LP order with the defaultBuyingShape to the market.
```

Step 3. Repeat the following forever:
```
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

If the bot has `currentPrice` then it should place  buy / sell limit orders (good till time with duration a bit longer than opening auction length) in the auction at random distance and volume away from `currentPrice` up to total `auctionVolume`. 
The distance and volume should be consistent with market risk parameters (spec work for later, Witold, do you feel like coming up with a formula?)

### Create markets that look real

Place good till time limit orders of random duration () near the reference price consistently with the market risk parameters (again, Witold, feel like trying to come up with a formula?). 

If the position of the bot is long *only* place sell orders. 

If the position of the bot is short *only* place buy orders here. 

### Manage their position

Some of this is taken care of above already but this is a more drastic behaviour that will lead to placing market orders to actively reduce position. 

Note that Vega uses worst long / short internally so orders and positions margins gets mixed up; here we use a more basic heuristic which, while not optimal, is simpler.

Repeat the following:
```
positionManagementSleep = 1.0/marketPriceSteeringRate //in seconds

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


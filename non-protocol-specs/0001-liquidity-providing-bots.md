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

The aim of this spec is bots that
1. submits a market proposal (optional) or connects to an existing market
1. serve as a liquidity provider for the market by submitting the [LP order type](../specs/0038-liquidity-provision-order-type.md).
1. participate in an opening auction (optional)
1. create markets that look real with more-or-less correct price by placing limit orders that "steer" the price up-or-down as appropriate
1. manage their position in such a way so as to not require ever growing amount of collateral. This will mean changing the "shape" in the liquidity provision order and also being strategic about placing limit orders to steer the price.
1. the code should be "nice" and "as simple as possible" so it can be shared with community (open sourced).

## Proposed solution

### Submitting a market proposal


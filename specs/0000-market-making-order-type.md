# Market Making Order Type

## Summary 

Market makers can commit to provide liquidity to a market by submitting this special order type. This commitment will ensure that they are eligible for portion of the market fees as set out in [Setting Fees and Rewarding MMs](????-setting-fees-and-rewarding-mms.md). 

The liquidity is measured in "siskas" as set out in the [Probability Weighted Liquidity Measure](0034-prob-weighted-liquidity-measure.ipynb) specification. 

As part of the market making order the market maker submits the following:
1) their desired fee for the market, 
1) the amount of liquidity to commit and how they want to distribute it (details follow below) and
1) optionally, they can submit mid price (this will change where their orders are placed on the order book or nothing else). Otherwise, market mid-price is used.

The liquidity commitment they make (in siskas) is converted using, a per-asset network parameter `siskas_to_bond_in_asset_X` as follows: 
``` mm_bond = liquidity_commitment x siskas_to_bond_in_asset_X.```

The volume implied by these MM order types is *not* placed on the book during auctions. 

## Specifying liquidity in terms of fraction-of-commitment-at-a-distance

The market maker submits:
1) market ID 
1) desired fee
1) liquidity commitment
1) optional mid price
1) sell-side: list of `[distance from mid, fraction-of-sell-side-commitment]` pairs. 
1) buy-side: list of `[distance from mid, fraction-of-buy-side-commitment]` pairs. 

We check that the sum across the list of the `fraction-of-***-side-commitment` is `1`, with `***=[sell,buy]`. If not reject the order.
We check that they have 

``` mm_bond = liquidity_commitment x siskas_to_bond_in_asset_X```

in their general account for the relevant asset; if not the order is rejected. If yes, then the amount is transferred into their per-asset market making bond amount.  

## Converting fraction-of-commitment-at-a-distance into volume

Assumption: Either the MM order specifies mid price or there is a mid price for the book. If not a price monitoring auction should be triggered (!!! Barney, Tamlyn, Witold, true? false? !!!!). 

For each entry on the buy and sell side list we now do the following:

Given `mid_price`, `distance_from_mid` and  `fraction-of-commitment` we obtain the `probability_of_trading` at that `distance_from_mid` at that `mid_price` from the risk model, see [Quant risk model spec](0018-quant-risk-models.ipynb). 

The volume implied by the oder at that distance from mid price is then 

``` volume = liquidity_commitment x fraction-of-commitment / probability_of_trading```. 

This volume should be added to the order book subject to margin account check (and perhaps transfer from general to margin account). If there is still insufficient margin then the required amount should be transferred from the market maker bond account. Additionally there may be a penalty applied as per the [slashing spec](????-????.md). 

## Amending the MM order:

Market makers are always allowed to ammend:
- 2. and 4.,
- 5. and 6. - as long as the relevant fractions add up to `1`, 

Market makers are allowed to increase the liquidity commitment 3. subject to being able to top up the bond commitment from the general account (check the new commitment amount, and transfer the difference from the general account to the bond account). 

Market makers are allowed to decrease the liquidity commitment 3. subject to there being sufficient liquidity committed to the market so that we stay above `liquidity supplied >= c_2 x liquidity demand estimate` see [liquidity monitoring spec](0035-liquidity-monitoring.md). This means we calculate the supplied liquidity with the amended order plus all other committed market makers, if the above inequality is still satisfied the order is accepted, otherwise rejected.


## Network parameters in this spec
1. A per-asset network parameter: `siskas_to_bond_in_asset_X`. This means every new asset that is created on Vega needs to make sure this parameter is assigned.

# Market Making Order Type

## Summary 

Market makers can commit to provide liquidity to a market by submitting this special order type. This commitment will ensure that they are eligible for portion of the market fees as set out in [Setting Fees and Rewarding MMs](????-setting-fees-and-rewarding-mms.md). 

The liquidity is measured in "siskas" as set out in the [Probability Weighted Liquidity Measure](0034-prob-weighted-liquidity-measure.ipynb) specification. 

As part of the market making order the market maker submits the following:
1) their desired fee for the market and
1) something that implies what liquidity commitment (in siskas they are making). This can take two forms: either they submit volume-at-distance from market mid price from which liquidity is calculated (details follow below) or they submit the amount of liquidity to commit and how they want to distribute it (details follow below).
1) Morover, optionally, they can submit mid price (this will change where their orders are placed on the order book or nothing else). Otherwise, market mid-price is used.






# Price Builder

## Summary

This specification adds a flexible way to configure "price" method for different purposes: mark price or the "internal" price for TWAP for perpetuals' funding payments.

For perpetual futures markets there should be a “mark price” configuration and a “market price for funding” configuration so that the market can, potentially use different mark price for mark-to-market and price monitoring and completely different price for calculating funding.

For futures markets there should be a “mark price” configuration for mark-to-market and price monitoring. 

### 1. Flexible mark price methodology

The calculations are specified in [markprice methodology research note](https://github.com/vegaprotocol/research/blob/markprice-updates/papers/markprice-methodology/markprice-methodology.tex).
Here, we only write the acceptance criteria.
Note that for calculating the median with an even number of entries we sort, pick out the two values that are in the middle of the list and average those. So in particular with two values a median is the same as the average for our purposes.

## Acceptance criteria

- It is possible to obtain a time series for the market mark price from the data node from the time of the market proposal enactment onwards (subject to data node retention policies).(<a name="0088-PRBD-001" href="#0088-PRBD-001">0088-PRBD-001</a>)
- It is possible to obtain a time series for the price used for “vega side price” of the funding twap from the data node from the time of the market proposal enactment onwards (subject to data node retention policies).(<a name="0088-PRBD-002" href="#0088-PRBD-002">0088-PRBD-002</a>)
- It’s possible to specify start and end times / dates when requesting the time series of prices. (<a name="0088-PRBD-003" href="#0088-PRBD-003">0088-PRBD-003</a>)
- It is possible to configure a cash settled futures market to use Algorithm 1 (ie last trade price) (<a name="0009-MRKP-010" href="#0009-MRKP-010">0009-MRKP-010</a>) and a perps market (<a name="0009-MRKP-011" href="#0009-MRKP-011">0009-MRKP-011</a>).
- It is possible to create a perpetual futures market which uses the last traded price algorithm for its mark price but uses "impact volume of notional of 1000 USDT" for the purpose of calculating the TWAP of the market price for funding payments (<a name="0053-PERP-033" href="#0053-PERP-033">0053-PERP-033</a>).
- It is possible to create a perpetual futures market which uses an oracle source (same as that used for funding) for the mark price determining the mark-to-market cashflows and that uses "impact volume of notional of 1000 USDT" for the purpose of calculating the TWAP of the market price for funding payments (<a name="0053-PERP-034" href="#0053-PERP-034">0053-PERP-034</a>).
- It is possible to create a perpetual futures market which uses an oracle source (same as that used for funding) for the mark price determining the mark-to-market cashflows and that uses "time-weighted trade prices in over `network.markPriceUpdateMaximumFrequency` if these have been updated within the last 30s but falls back onto impact volume of notional of 1000 USDT" for the purpose of calculating the TWAP of the market price for funding payments (<a name="0053-PERP-035" href="#0053-PERP-035">0053-PERP-035</a>).

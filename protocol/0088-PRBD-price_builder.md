# Price Builder

## Summary

This specification adds a flexible way to configue "price" method for different purpose. 

For perpetual futures markets there should be a “mark price” configuration and a “market price for funding” configuration so that the market can, potentially use different mark price for mark-to-market and price monitoring and completely different price for calculating funding.

## Acceptance criteria

- It is possible to obtain a time series for the market mark price from the data node from the time of the market proposal enactment onwards (subject to data node retention policies).(<a name="0088-PRBD-001" href="#0088-PRBD-001">0088-PRBD-001</a>)
- It is possible to obtain a time series for the price used for “vega side price” of the funding twap from the data node from the time of the market proposal enactment onwards (subject to data node retention policies).(<a name="0088-PRBD-002" href="#0088-PRBD-002">0088-PRBD-002</a>)
- It’s possible to specify start and end times / dates when requesting the time series of prices. (<a name="0088-PRBD-003" href="#0088-PRBD-003">0088-PRBD-003</a>)
- When leaving opening auction, market should either wait in opening auction until the first mark price is available or it is certain that leaving the opening auction will set it. (<a name="0088-PRBD-004" href="#0088-PRBD-004">0088-PRBD-004</a>)
- When market is in continous trading mode, mark price is updated when the time indicated by the mark price frequency is crossed (<a name="0088-PRBD-005" href="#0088-PRBD-005">0088-PRBD-005</a>)
- In terms of mark price update during action, we don’t do mark price updates (even if they come from external oracle). We do a MTM update upon leaving the auction with the latest available value. (<a name="0088-PRBD-006" href="#0088-PRBD-006">0088-PRBD-006</a>)






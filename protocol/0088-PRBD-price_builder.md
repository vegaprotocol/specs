# Price Builder

## Summary

This specification adds a flexible way to configure "price" method for different purpose.

For perpetual futures markets there should be a “mark price” configuration and a “market price for funding” configuration so that the market can, potentially use different mark price for mark-to-market and price monitoring and completely different price for calculating funding.

## Acceptance criteria

- It is possible to obtain a time series for the market mark price from the data node from the time of the market proposal enactment onwards (subject to data node retention policies).(<a name="0088-PRBD-001" href="#0088-PRBD-001">0088-PRBD-001</a>)
- It is possible to obtain a time series for the price used for “vega side price” of the funding twap from the data node from the time of the market proposal enactment onwards (subject to data node retention policies).(<a name="0088-PRBD-002" href="#0088-PRBD-002">0088-PRBD-002</a>)
- It’s possible to specify start and end times / dates when requesting the time series of prices. (<a name="0088-PRBD-003" href="#0088-PRBD-003">0088-PRBD-003</a>)

0032-price-monitoring.mdFeature name: liquidity-monitoring\
Start date: 2020-07-14\
Specification PR: https://github.com/vegaprotocol/product/pull/322

## Summary

Liquidity in the market is not only a desirable feature from a trader's point of view, but also an important consideration from the risk-management standpoint. Position of a distressed trader can only be liquidated if there's enough volume on the order book to offload it, otherwise a potentially insolvent party remains part of the market.

Similarly to [price monitoring](0037-price-monitoring.md), we need to be able to detect when the market liquidity drops below the desired level, launch a liquidity auction and terminate it when the market liquidity level is back at a sufficiently high level.

## Liquidity auction network parameters

**c<sub>1</sub>** - constant multiple of [liquidity demand estimate](#Glossary) triggering the commencement of liquidity auction.

**c<sub>2</sub>** - constant multiple of [liquidity demand estimate](#Glossary) triggering the termination of liquidity auction (such that c<sub>2</sub> > c<sub>1</sub>).

**p** - period of time used for the [liquidity demand estimate](#Glossary).

## Glossary

**Open interest** - volume of all long positions.

**Liquidity demand estimate** - use maximum open interest in the market captured between the current time t and t-[p](#Liquidity-auction-network-parameters) for now. **Note** that we may use a different way to estimate liquidity demand in the future, hence it's important that it's properly abstracted away without a need to refactor it's downstream usage should we change the way we calculate it.

## Required liquidity

Minimum liquidity requirement measured as a constant multiple c<sub>1</sub> (market parameter) of max Open Interest over period p

## Supplied liquidity

Count (probability of trading weighted) liquidity committed via market making orders. Please see the [liquidity measurement spec](0036-prob-weighted-liquidity-measure.ipynb) for details.

## Trigger for entering an auction

When liquidity supplied < c<sub>1</sub> * [liquidity demand estimate](#Glossary).

Similarly to [price monitoring](0037-price-monitoring.md), the auction should be triggered pre-emptively. That is, the transaction that would have triggered the liquidity auction should be re-processed once auction mode is on. Please note that this transaction may be cancelled if it's type is not valid for auction, however even in that case the market should still go into the auction mode to send a signal that it requires more liquidity.

## Trigger for exiting the auction

When liquidity supplied ≥ c_2 * [liquidity demand estimate](#Glossary), \
where c_2 > c_1, to reduce the chance of another auction getting triggered soon after.

During the liquidity monitoring auction new or existing market makers can commit more liquidity through the special market making order type and enable this by posting enough margin - see market making mechanics spec (WIP) for details. These need to be monitored to see if auction mode can be exit.

## What happens during the auction?

The auction proceeds as usual. Please see the auction spec for details.

## Test cases

* Market with no market makers enters liquidity auction immediately.

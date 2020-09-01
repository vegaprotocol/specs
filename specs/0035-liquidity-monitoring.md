Feature name: liquidity-monitoring\
Start date: 2020-07-14\
Specification PR: https://github.com/vegaprotocol/product/pull/322

## Summary

Liquidity in the market is not only a desirable feature from a trader's point of view, but also an important consideration from the risk-management standpoint. Position of a distressed trader can only be liquidated if there's enough volume on the order book to offload it, otherwise a potentially insolvent party remains part of the market.

Similarly to [price monitoring](0032-price-monitoring.md), we need to be able to detect when the market liquidity drops below the desired level, launch a liquidity auction and terminate it when the market liquidity level is back at a sufficiently high level.

## Liquidity auction network parameters

**c<sub>1</sub>** - constant multiple for [target stake](0000-target-stake.md) triggering the commencement of liquidity auction.  

## Glossary

[target stake](0000-target-stake.md) is defined in a separate spec.

## Required stake

Minimum liquidity requirement measured as c<sub>1</sub> (market parameter) times `target_stake`.

## Supplied stake

Total stake of all market makers in the market. 

Count (probability of trading weighted) liquidity committed via market making orders. Please see the [liquidity measurement spec](0034-prob-weighted-liquidity-measure.ipynb) for details.

## Trigger for entering an auction

When supplied stake < c<sub>1</sub> x `target_stake`, 
where 0 < c<sub>1</sub> < 1, to reduce the chance of another auction getting triggered soon after e.g. c<sub>1</sub> = 0.7. 

Similarly to [price monitoring](0032-price-monitoring.md), the auction should be triggered pre-emptively. That is, the transaction that would have triggered the liquidity auction should be re-processed once auction mode is on. Please note that this transaction may be cancelled if it's type is not valid for auction, however even in that case the market should still go into the auction mode to send a signal that it requires more liquidity.

## Trigger for exiting the auction

When supplied stake ≥ `target_stake`, \


During the liquidity monitoring auction new or existing market makers can commit more stake (and hence liquidity) through the special market making order type and enable this by posting enough margin - see market making mechanics spec (WIP) for details. These need to be monitored to see if auction mode can be exit.

## What happens during the auction?

The auction proceeds as usual. Please see the auction spec for details.

## Test cases

* Market with no market makers enters liquidity auction immediately.

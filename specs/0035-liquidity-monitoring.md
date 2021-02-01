Feature name: liquidity-monitoring\
Start date: 2020-07-14\
Specification PR: https://github.com/vegaprotocol/product/pull/322

## Summary

Liquidity in the market is not only a desirable feature from a trader's point of view, but also an important consideration from the risk-management standpoint. Position of a distressed trader can only be liquidated if there's enough volume on the order book to offload it, otherwise a potentially insolvent party remains part of the market.

Similarly to [price monitoring](0032-price-monitoring.md), we need to be able to detect when the market liquidity drops below the desired level, launch a liquidity auction and terminate it when the market liquidity level is back at a sufficiently high level.

Note that there is one-to-one correspondence between the total stake committed by liquidity providers (LPs), see [LP mechanics](specs/0044-lp-mechanics.md) spec, and the total supplied liquidity. Thus even though below we will be comparing `target_stake` with `supplied_stake` what this really monitors is amount of liquidity supplied. 
Note that [target stake](0041-target-stake.md) is defined in a separate spec.

## Liquidity auction network parameters

**c<sub>1</sub>** - constant multiple for [target stake](0041-target-stake.md) triggering the commencement of liquidity auction. 
This is a network parameter. 

## Supplied stake

`supplied_stake` is the sum the stake amounts committed by all the LPs in the market (see [LP mechanics](specs/0044-lp-mechanics.md)). 

## Trigger for entering an auction

When `supplied_stake` < c<sub>1</sub> x `target_stake`, 
where 0 < c<sub>1</sub> < 1, to reduce the chance of another auction getting triggered soon after e.g. c<sub>1</sub> = 0.7. 

Similarly to [price monitoring](0032-price-monitoring.md), the auction should be triggered pre-emptively. That is, the transaction that would have triggered the liquidity auction should be re-processed once auction mode is on. Please note that this transaction may be cancelled if it's type is not valid for auction, however even in that case the market should still go into the auction mode to send a signal that it requires more liquidity.

## Trigger for exiting the auction

When `supplied_stake` ≥ `target_stake`.


During the liquidity monitoring auction new or existing LPs can commit more stake (and hence liquidity) through the special market making order type and enable this by posting enough margin - see the [liquidity provision mechanics](0044-lp-mechanics.md) spec for details. These need to be monitored to see if auction mode can be exit.

## What happens during the auction?

The auction proceeds as usual. Please see the auction spec for details.

## Test cases

* Market with no market makers enters liquidity auction immediately.

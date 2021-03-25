Feature name: liquidity-monitoring\
Start date: 2020-07-14\
Specification PR: https://github.com/vegaprotocol/product/pull/322

## Summary

Liquidity in the market is not only a desirable feature from a trader's point of view, but also an important consideration from the risk-management standpoint. Position of a distressed trader can only be liquidated if there's enough volume on the order book to offload it, otherwise a potentially insolvent party remains part of the market.

Similarly to [price monitoring](0032-price-monitoring.md), we need to be able to detect when the market liquidity drops below the safe level, launch a "liquidity seeking" auction (in which, due to the [liquidity mechanics](./0044-lp-mechanics.md), there is an incentive through the ability to set fees, to provide the missing liquidity) and terminate it when the market liquidity level is back at a sufficiently high level.

Note that as long as all pegs that LP batch orders can peg to exists on the book there is one-to-one correspondence between the total stake committed by liquidity providers (LPs), see [LP mechanics](./0044-lp-mechanics.md) spec, and the total supplied liquidity. 
Indeed 
```
lp_liquidity_obligation_in_ccy_siskas = stake_to_ccy_siskas ⨉ stake.
```
Thus it is sufficient to compare `target_stake` with `total_stake` while also ensuring that `best_bid` and `best_offer` are present on the book (*).
Note that [target stake](0041-target-stake.md) is defined in a separate spec.

(*) Having `best_bid` and `best_offer` implies that `mid` also exists. If, in the future, [LP batch orders](0038-liquidity-provision-order-type.md) are updated to allow other pegs then the protocol must enforce that they are also on the book.

## Liquidity auction network parameters

**c<sub>1</sub>** - constant multiple for [target stake](0041-target-stake.md) triggering the commencement of liquidity auction.  

## Total stake

`total_stake` is the sum the stake amounts committed by all the LPs in the market (see [LP mechanics](./0044-lp-mechanics.md)) for how LPs commit stake and what it obliges them to do. 

## Trigger for entering an auction

The auction is triggered when
```
total_stake < c_1 x target_stake OR there is no best_bid OR there is no best offer.
```
Here 0 < c<sub>1</sub> < 1, to reduce the chance of another auction getting triggered soon after e.g. c<sub>1</sub> = 0.7. The parameter c<sub>1</sub> is a network parameter.

### Increasing target stake

If an incoming order would match orders on the book resulting in trades increasing `target_stake` so that liquidity auction gets triggered then:

- if the incoming order would stay on the book in auction mode the auction should get triggered pre-emptively (the order doesn't get matched in market's current trading mode, market switches to auction mode and the incoming order gets added to the book once market is in auction mode).
- if the incoming would not stay on the book in auction mode then the order gets rejected, appropriate event gets sent to signal to the market that insufficient `supplied_stake` has prevented the market from increasing the open interest and the market remains in the current trading mode.

### Decreasing supplied stake

If the [liquidity provision transaction would decrease](0044-lp-mechanics.md#liquidity-provider-proposes-to-amend-commitment-amount) `supplied_stake` so that liquidity auction gets triggered then the liquidity provision amendment should be rejected and market should stay in it's current trading mode.

If the `supplied_stake` decreases as a result of a closeout of an insolvent liquidity provider, then closeout should proceed and market should go into liquidity auction.

### Removing `best_bid` or `best_offer`

If an incoming order would get matched so that entire side of the order book gets consumed and `best_bid` or `best_offer` no longer exists, then the order should be allowed to go through and market should go into liquidity auction after it gets matched and the resulting trades get generated.

## Trigger for exiting the auction

We exit if
```
total_stake >= target_stake AND there is best_bid AND there is best_offer.
``` 

During the liquidity monitoring auction new or existing LPs can commit more stake (and hence liquidity) through the special market making order type and enable this by posting enough margin - see the [liquidity provision mechanics](0044-lp-mechanics.md) spec for details. These need to be monitored to see if auction mode can be exit.

## What happens during the auction?

The auction proceeds as usual. Please see the auction spec for details.

## Test cases

* Market with no market makers enters liquidity auction immediately.
* Opening auction or price monitoring auction that would end with an uncrossing trade but no `best_bid` or no `best_offer` will enter liquidity monitoring auction.


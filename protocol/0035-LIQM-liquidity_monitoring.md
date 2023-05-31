# Liquidity monitoring

## Summary

Liquidity in the market is not only a desirable feature from a trader's point of view, but also an important consideration from the risk-management standpoint. Position of a distressed trader can only be liquidated if there's enough volume on the order book to offload it, otherwise a potentially insolvent party remains part of the market.

Similarly to [price monitoring](./0032-PRIM-price_monitoring.md), we need to be able to detect when the market liquidity drops below the safe level, launch a "liquidity seeking" auction (in which, due to the [liquidity mechanics](./0044-LIME-lp_mechanics.md), there is an incentive through the ability to set fees, to provide the missing liquidity) and terminate it when the market liquidity level is back at a sufficiently high level.

Note that as long as all pegs that LP batch orders can peg to exists on the book there is one-to-one correspondence between the total stake committed by liquidity providers (LPs), see [LP mechanics](./0044-LIME-lp_mechanics.md) spec, and the total supplied liquidity.
Indeed

`lp_liquidity_obligation_in_ccy_volume = market.liquidity.stakeToCcyVolume ⨉ stake`.

Thus it is sufficient to compare `target_stake` with `total_stake`.
Note that [target stake](./0041-TSTK-target_stake.md) is defined in a separate spec.


## Liquidity auction parameters

**c<sub>1</sub>** - constant multiple for [target stake](./0041-TSTK-target_stake.md) triggering the commencement of liquidity auction. In this spec it is referred to as `c_1` but in fact it `triggering_ratio` in `LiquidityMonitoringParameters` in market creation or update proposal.

## Total stake

`total_stake` is the sum the stake amounts committed by all the LPs in the market (see [LP mechanics](./0044-LIME-lp_mechanics.md)) for how LPs commit stake and what it obliges them to do.

## Trigger for entering an auction

The auction is triggered when

`total_stake < c_1 x target_stake`.

Here 0 < c<sub>1</sub> < 1, to reduce the chance of another auction getting triggered soon after e.g. c<sub>1</sub> = 0.7. The parameter c<sub>1</sub> is a network parameter.

### Increasing target stake

If an incoming order would match orders on the book resulting in trades increasing `target_stake` so that liquidity auction gets triggered then:

- if the incoming order would stay on the book in auction mode the auction should get triggered preemptively (the order doesn't get matched in market's current trading mode, market switches to auction mode and the incoming order gets added to the book once market is in auction mode).

### Decreasing supplied stake

If the [liquidity provision transaction would decrease](./0044-LIME-lp_mechanics.md#liquidity-provider-proposes-to-amend-commitment-amount) `supplied_stake` so that liquidity auction gets triggered then a liquidity auction is triggered the next time the next time conditions for liquidity auctions are evaluated.

If the `supplied_stake` decreases as a result of a closeout of an insolvent liquidity provider, then closeout should proceed and market should go into liquidity auction the next time the next time conditions for liquidity auctions are evaluated.

## Trigger for exiting the auction

We exit if

`total_stake >= target_stake`.

During the liquidity monitoring auction new or existing LPs can commit more stake (and hence liquidity) through the special market making transaction and enable this by posting enough margin - see the [liquidity provision mechanics](./0044-LIME-lp_mechanics.md) spec for details. These need to be monitored to see if auction mode can be exited.

## What happens during the auction?

The auction proceeds as usual. Please see the [auction spec](./0026-AUCT-auctions.md) for details.

## Frequency of checking for liquidity auction entry conditions

 Through a sequence of actions which occur with the same timestamp the market may be moved into a state in which a liquidity auction is expected and then back out of said state. Ideally, liquidity auctions should only be entered when the market truly requires one as once entered a minimum auction length (controlled by `market.auction.minimumDuration`) must be observed. Even with a very short a minimum auction length, a market flickering between two states is suboptimal.

 To resolve this, the conditions for entering a liquidity auction should only be checked at the end of each batch of transactions occurring with an identical timestamp (in the current Tendermint implementation this is equivalent to once per block). At the end of each such period the auction conditions should be checked and the market moved into liquidity auction state if the conditions for entering a liquidity auction are satisfied.
The criteria for exiting any auction (liquidity or price monitoring) should be checked only on timestamp change (ie block boundary with Tendermint). This means that a market cannot leave a liquidity auction only to immediately re-enter it at the end of the block.

A liquidity provider amending LP provision order can reduce their stake even if doing so would mean that at the end of block the system enters liquidity auction.

## Acceptance Criteria

1. The scenarios in the feature test [0026-AUCT-auction_interaction.feature](https://github.com/vegaprotocol/vega/blob/develop/core/integration/features/verified/0026-AUCT-auction_interaction.feature) are verified and pass. (<a name="0035-LIQM-001" href="#0035-LIQM-001">0035-LIQM-001</a>)
1. A market which enters a state requiring liquidity auction at the end of a block through increased open interest remains in open trading between entering that state and the end of the block. (<a name="0035-LIQM-003" href="#0035-LIQM-003">0035-LIQM-003</a>)
1. A market which enters a state requiring liquidity auction at the end of a block through decreased total stake (e.g. through LP bankruptcy) remains in open trading between entering that state and the end of the block. (<a name="0035-LIQM-004" href="#0035-LIQM-004">0035-LIQM-004</a>)
1. A market which enters a state requiring liquidity auction through increased open interest during a block but then leaves state again prior to block completion never enters liquidity auction. (<a name="0035-LIQM-005" href="#0035-LIQM-005">0035-LIQM-005</a>)
1. A market which enters a state requiring liquidity auction through reduced current stake (e.g. through LP bankruptcy) during a block but then leaves state again prior to block completion never enters liquidity auction. (<a name="0035-LIQM-006" href="#0035-LIQM-006">0035-LIQM-006</a>)
1. If the Max Open Interest field decreases for a created block to a level such that a liquidity auction which is active at the start of a block can now be exited the block stays in auction within the block but leaves at the end. (<a name="0035-LIQM-008" href="#0035-LIQM-008">0035-LIQM-008</a>)
1. When the market parameter `triggeringRatio` for an existing market is updated via governance, the next time conditions for entering auction are evaluated, the new triggering ratio is applied. (<a name="0035-LIQM-010" href="#0035-LIQM-010">0035-LIQM-010</a>)
1. When proposing a new market if the triggering_ratio is not supplied then the current value of `market.liquidity.targetstake.triggering.ratio` is used in its place. (<a name="0035-LIQM-011" href="#0035-LIQM-011">0035-LIQM-011</a>)

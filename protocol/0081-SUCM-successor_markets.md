# Successor markets

## Overview

On Vega anyone can propose a market via on-chain [governance](./0028-GOVE-governance.md).
The markets are created and in many cases terminated and settled following the [market lifecycle](./0043-MKTL-market_lifecycle.md).
On every market liquidity is provided by various parties, liquidity providers (LPs), who [commit to provide liquidity](./0044-LIME-lp_mechanics.md) by depositing a bond / stake.
As part of this process the LPs build-up virtual stake on the market, which may be higher than the stake they committed if the market grew.
For [details of virtual stake calculation see how LPs are rewarded](./0042-LIQF-setting_fees_and_rewarding_lps.md).

Many derivative markets would terminate and settle periodically but would be part of a sequence.
Think e.g. of a [cash-settled future](./0016-PFUT-product_builtin_future.md) written on the same underlying that settles every three months.
Successor markets are a feature that allows this sequencing but most importantly allows LPs to keep their virtual stake built up on one market (parent) in the sequence to be transferred to the next one (successor).
Moreover, part of the insurance pool of a parent market can be earmarked for transfer to the successor market instead of being distributed network wide (other markets in same settlement asset, network treasury).

## Relevant network / market parameters

- `market.value.windowLength` is a network parameter specifying how long, after a market has settled, the LPs virtual stakes are retained and the insurance pool is left undistributed to allow a successor to be defined.
- `parent market Id` is part of market proposal which can optionally specify a parent market; see [governance](./0028-GOVE-governance.md).
- `insurancePoolFraction` is is part of market proposal which can optionally specify how much of the insurance pool of the parent is to be transferred to the successor; see [governance](./0028-GOVE-governance.md).

## Specifying a parent market and timing details

A market [governance] proposal for a successor market must contain all the information of a full proposal with additionally specified `parent market Id` and `insurancePoolFraction`.
The product, settlement asset, margin asset, and `market.value.windowLength` must match but all other inputs can be different (e.g. position and price decimal places, risk mode, price monitoring, termination and settlement oracles etc.).
For [spot markets](./0080-SPOT-product_builtin_spot.md) base and quote assets must match.

The parent market must be either: a) in one of `proposed`, `pending`, `active`, `suspended` or `trading terminated`
or b) `settled` state but with time since settlement less than or equal `market.liquidity.successorLaunchWindowLength`
or c) `cancelled` (closed by governance) but with the closing time less than or equal `market.liquidity.successorLaunchWindowLength`.
The point of setting up a market to be successor of an existing market is to
a) allow LPs continue claim their virtual stake / equity-like-share (ELS) by committing liquidity to the successor market during the pending period if they wish to, and
b) allow the successor market to inherit the insurance pool of the parent market. When the successor market leaves the opening auction (moves from pending to active) the amount equal to `insurancePoolFraction x parent market insurance pool balance` is transferred to the successor market insurance pool. Once the parent market moves from "trading terminated" to "settled" state, the entire remaining insurance pool of the successor market is transferred to the successor market insurance pool.

If the parent market is `proposed` or `pending` or the opening auction ends after the settlement time / cancellation time plus `market.liquidity.successorLaunchWindowLength` then the parent marketID may no longer exist in core or there may be no virtual stake to claim (copy). In that case the successor market virtual stakes are initialised as if the market has no parent (and we set the parent market field in market data to null / empty indicating no parent market).

Note that each market can have exactly one market as a _successor_ market.

- if there already is a market (possibly pending, i.e. in opening auction, see [lifecycle spec](./0043-MKTL-market_lifecycle.md)), naming a parent market, then a subsequent proposal referencing that market is rejected.
- if there are two proposals naming the same parent market then whichever one gets into the _active_ state first (i.e. passes governance vote and clears the opening auction) becomes the successor of the named parent; the other proposal is kept but the parent market id field is cleared and when opening auction ends no virtual stake will get carried over.
- if there is a successor market naming a parent market and the parent terminates and settles or is cancelled by governance before the parent market (for whatever reason) then the parent market can again act as successor to  a different market proposed by a another market proposal.

## Carrying over virtual stake

While a successor market is in opening auction any LP party can submit liquidity commitments to it.
LP parties that exist on the parent market will get special treatment.

At the end of opening auction, if the parent market still exists, the following will happen.

1. For each LP that exists on the parent market their virtual stake is carried over.
1. For each LP that exists on the parent market we update their virtual stake using the difference (delta) between the physical stake present on the parent market and the stake committed to the successor market using the update rule given in [the spec detailing LP rewards](./0042-LIQF-setting_fees_and_rewarding_lps.md).

## Transferring insurance pool balance

At the end of opening auction, if the parent market still exists, the fraction of the parent insurance pool balance given by `insurancePoolFraction` is transferred to the successor market.


## Acceptance criteria

### Proposals and timing

Market proposal may specify parent market ID. If it does then:

- It must also specify insurance pool fraction (<a name="0081-SUCM-001" href="#0081-SUCM-001">0081-SUCM-001</a>)
- The product, settlement asset, margin asset, and `market.value.windowLength` must match between parent and successor; if not proposal is rejected (<a name="0081-SUCM-002" href="#0081-SUCM-002">0081-SUCM-002</a>)
- It is possible for the successor to specify different trading termination and settlement oracle data (<a name="0081-SUCM-003" href="#0081-SUCM-003">0081-SUCM-003</a>).

It is possibly to cancel a [spot market](./0080-SPOT-product_builtin_spot.md) via governance and propose a new spot market as a successor with different `market_decimal_places` and `position_decimal_places` (aka `size_decimal_places` for spot); the LPs virtual stakes are carried over (<a name="0081-SUCM-004" href="#0081-SUCM-004">0081-SUCM-004</a>).

Two proposals that name the same parent can be submitted. Both can be approved by governance. The proposed market that clears the opening auction first gets the share of the insurance pool and the virtual stakes get carried over. Once the first market clears the opening auction the other market's parent market Id field is cleared. When it clears the opening auction it gets no insurance pool from the parent and no virtual stakes get carried over (<a name="0081-SUCM-005" href="#0081-SUCM-005">0081-SUCM-005</a>).

A new market proposal sets parent market Id to a market that has settled. The parent market has non-zero insurance pool balance. If the new market clears the opening auction before `parent settlement time + market.value.windowLength` then the virtual stakes are carried over and the relevant fraction of the insurance pool is transferred over (<a name="0081-SUCM-006" href="#0081-SUCM-006">0081-SUCM-006</a>).

A new market proposal sets parent market Id to a market that has settled. The parent market has non-zero insurance pool balance. If the new market clears the opening auction after `parent settlement time + market.value.windowLength` then no virtual stakes are carried over, there is no transfer into the insurance pool of the new market from the parent and the new market has no parent market Id set (<a name="0081-SUCM-007" href="#0081-SUCM-007">0081-SUCM-007</a>)

Successor markets can be enacted if the parent market is still in the "proposed" state. There is no virtual stake to copy over and no insurance pool balance to transfer  (<a name="0081-SUCM-008" href="#0081-SUCM-008">0081-SUCM-008</a>)

Successor markets can be enacted when the parent market is in opening auction (<a name="0081-SUCM-009" href="#0081-SUCM-009">0081-SUCM-009</a>)

A successor market proposal can be enacted when the parent market is in one of the following states: Suspended, Active, Trading terminated or Settled (settled within the successor time window) (<a name="0081-SUCM-010" href="#0081-SUCM-010">0081-SUCM-010</a>)

When a successor market is enacted (i.e. leaves the opening auction), all other related successor market proposals, in the state "pending" or "proposed", are automatically rejected. Any LP submissions associated with these proposals are cancelled, and the funds are released (<a name="0081-SUCM-011" href="#0081-SUCM-011">0081-SUCM-011</a>)

With two successor markets in opening auction, that have the same parent market, and one additional market in the state "Proposed". Get one of the two markets to leave the opening auction (passage of time, LP commitment, crossing trade). The other market in auction and the proposed market should both be "Rejected" and all LP funds will be released (<a name="0081-SUCM-014" href="#0081-SUCM-014">0081-SUCM-014</a>)

Propose a successor market which specifies a parent which is settled, and for which the successor time window has expired. The proposal is declined. (<a name="0081-SUCM-018" href="#0081-SUCM-018">0081-SUCM-018</a>)

### APIs

It is possible to fetch a market "parent / successor chain" containing the initial market and the full successor line (<a name="0081-SUCM-012" href="#0081-SUCM-012">0081-SUCM-012</a>)

When fetching a market that is part of a "parent / successor chain", we should see both the parent and each successor `marketID` (<a name="0081-SUCM-013" href="#0081-SUCM-013">0081-SUCM-013</a>)


### Snapshots / checkpoints

After a LNL checkpoint restart the successor (child) / parent market state is preserved where applicable inc. the LPs ELS	(<a name="0081-SUCM-016" href="#0081-SUCM-016">0081-SUCM-016</a>)

After snapshot restart the successor (child) / parent market state is preserved where applicable inc. the LPs ELS	(<a name="0081-SUCM-017" href="#0081-SUCM-017">0081-SUCM-017</a>)


### Virtual stake

A new market is set with a parent market Id. On the parent there are two parties `A` and `B` with virtual stakes `v1` and `v2` and physical stakes `s1` and `s2`

If

- Both `A` and `B` submit a liquidity commitment of `s1` and `s2` to the new market before the opening auction ends. No other LP submits liquidity to the new market. Then, once the opening auction resolved the LPs `A` and `B` have virtual stakes `v1` and `v2` (<a name="0081-SUCM-020" href="#0081-SUCM-020">0081-SUCM-020</a>).
- As above but `A` submits `s1` and `B` doesn't submit anything. Then `A` has virtual stake `v1` and `B` has virtual stake `0` (<a name="0081-SUCM-021" href="#0081-SUCM-021">0081-SUCM-021</a>).
- As above but `A` submits more than `s1`. Then `A` has virtual stake larger than `v1`. (<a name="0081-SUCM-022" href="#0081-SUCM-022">0081-SUCM-022</a>)

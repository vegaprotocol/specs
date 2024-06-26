# Successor markets

## Overview

On Vega anyone can propose a market via on-chain [governance](./0028-GOVE-governance.md).
The markets are created and in many cases terminated and settled following the [market lifecycle](./0043-MKTL-market_lifecycle.md).
On every market liquidity is provided by various parties, liquidity providers (LPs), who [commit to provide liquidity](./0044-LIME-lp_mechanics.md) by depositing a bond / stake.
As part of this process the LPs build-up virtual stake on the market, which may be higher than the stake they committed if the market grew.
For [details of virtual stake calculation see how LPs are rewarded](./0042-LIQF-setting_fees_and_rewarding_lps.md).

Many derivative markets would terminate and settle periodically but would be part of a lineage.
Think e.g. of a [cash-settled future](./0016-PFUT-product_builtin_future.md) written on the same underlying that settles every three months.
Successor markets are a feature that allows for markets to have a lineage, but most importantly allows LPs to keep their virtual stake built up on one market (parent) in the lineage to be transferred to the next one (successor).
Moreover, part of the insurance pool of a parent market can be earmarked for transfer to the successor market instead of being transferred into the global insurance pool.

## Relevant network / market parameters

- `market.liquidity.successorLaunchWindowLength` is a network parameter specifying how long, after a market has settled, the LPs virtual stakes are retained and the insurance pool is left undistributed to allow a successor to be defined.
- `parent market Id` is part of market proposal which can optionally specify a parent market; see [governance](./0028-GOVE-governance.md).
- `insurancePoolFraction` is is part of market proposal which can optionally specify how much of the insurance pool of the parent is to be transferred to the successor; see [governance](./0028-GOVE-governance.md).

## Specifying a parent market and timing details

A market [governance] proposal for a successor market must contain all the information of a full proposal with additionally specified `parent market Id` and `insurancePoolFraction`.
The product type, settlement asset, and margin asset must match but all other inputs can be different (e.g. position and price decimal places, risk model, price monitoring, termination and settlement oracles etc.).
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
- The product type, settlement asset and margin asset must match between parent and successor; if not proposal is rejected:
  - futures to perpetuals (<a name="0081-SUCM-002" href="#0081-SUCM-002">0081-SUCM-002</a>)
  - perpetuals to spot (<a name="0081-SUCM-033" href="#0081-SUCM-033">0081-SUCM-033</a>)
  - spot to futures (<a name="0081-SUCM-034" href="#0081-SUCM-034">0081-SUCM-034</a>)
- It is possible for the successor to specify different trading termination and settlement oracle data (<a name="0081-SUCM-003" href="#0081-SUCM-003">0081-SUCM-003</a>).

It is possibly to cancel a [spot market](./0080-SPOT-product_builtin_spot.md) via governance and propose a new spot market as a successor with different `market_decimal_places` and `position_decimal_places` (aka `size_decimal_places` for spot); the LPs virtual stakes are carried over (<a name="0081-SUCM-004" href="#0081-SUCM-004">0081-SUCM-004</a>).

It is possibly to cancel a [perpetual futures](./0053-PERP-product_builtin_perpetual_future.md) market via governance and propose a new perpetual futures market as a successor of the aforementioned cancelled / to be cancelled with different `market_decimal_places` and `position_decimal_places`; the LPs virtual stakes are carried over (<a name="0081-SUCM-015" href="#0081-SUCM-015">0081-SUCM-015</a>).

Two proposals that name the same parent can be submitted. Both can be approved by governance. The proposed market that clears the opening auction first gets a share of the insurance pool, and the virtual stakes get carried over. Once the first market clears the opening auction, the other market is "Rejected," and all assets committed into LP bond accounts will be immediately released. Orders placed into the opening auction will be cancelled, and the assets held to support any party's orders will be released. (<a name="0081-SUCM-005" href="#0081-SUCM-005">0081-SUCM-005</a>).

A new market proposal sets parent market Id to a market that has settled. The parent market has non-zero insurance pool balance. If the new market clears the opening auction before `parent settlement time + market.liquidity.successorLaunchWindowLength` then the virtual stakes are carried over and the relevant fraction of the insurance pool is transferred over (<a name="0081-SUCM-006" href="#0081-SUCM-006">0081-SUCM-006</a>).

A new market proposal sets parent market Id to a market that has settled. The parent market has non-zero insurance pool balance. If the new market clears the opening auction after `parent settlement time + market.liquidity.successorLaunchWindowLength` then no virtual stakes are carried over, the successor market is not a successor market anymore, it's just a market like any other, and the insurance pool balance will be transferred into the global insurance pool (<a name="0081-SUCM-036" href="#0081-SUCM-036">0081-SUCM-036</a>)

Successor markets cannot be enacted if the parent market is still in the "proposed" state. Successor market proposals can be submitted when the parent market is still in proposed state. When the voting period for the successor market ends then either: the parent market is already enacted in which case the successor market moves from "proposed" in to opening auction/"pending" state. Or the parent market is still in "proposed" state in which case successor market is rejected. (<a name="0081-SUCM-008" href="#0081-SUCM-008">0081-SUCM-008</a>)

Successor markets which are proposed whilst the parent is also still in a "proposed" state, will be rejected if the parent is rejected. (<a name="0081-SUCM-027" href="#0081-SUCM-027">0081-SUCM-027</a>)

Successor markets can be enacted when the parent market is in opening auction. There is no virtual stake to copy over, and no insurance pool balance to transfer. (<a name="0081-SUCM-009" href="#0081-SUCM-009">0081-SUCM-009</a>)

A successor market proposal can be enacted when the parent market is in one of the following states: Pending, Suspended, Active, Trading terminated or Settled (settled within the successor time window) (<a name="0081-SUCM-010" href="#0081-SUCM-010">0081-SUCM-010</a>)

When a successor market is enacted, all other related successor market proposals, in the state "pending" or "proposed", are automatically rejected. Any LP submissions associated with these proposals are cancelled, and the funds are released (<a name="0081-SUCM-011" href="#0081-SUCM-011">0081-SUCM-011</a>)

With two successor markets in opening auction, that have the same parent market, and one additional market in the state "Proposed". Get one of the two markets to leave the opening auction (passage of time, LP commitment, crossing trade). The other market in auction and the proposed market should both be "Rejected" and all LP funds will be released (<a name="0081-SUCM-014" href="#0081-SUCM-014">0081-SUCM-014</a>)

Propose two markets which are attempting to succeed the same parent, and which have an overlapping voting period. Ensure the first child passes governance and enters opening auction. Ensure that the second child is also able to enter opening auction. The first to complete opening auction becomes the successor, and the other is rejected.(<a name="0081-SUCM-028" href="#0081-SUCM-028">0081-SUCM-028</a>)

Propose a successor market which specifies a parent which is settled, and for which the successor time window has expired. The proposal is declined. (<a name="0081-SUCM-018" href="#0081-SUCM-018">0081-SUCM-018</a>)

### APIs

It is possible to fetch a market "parent / successor chain" containing the initial market and the full successor line via:

- GRPC (<a name="0081-SUCM-012" href="#0081-SUCM-012">0081-SUCM-012</a>)
- GraphQL (<a name="0081-SUCM-023" href="#0081-SUCM-023">0081-SUCM-023</a>)
- REST (<a name="0081-SUCM-024" href="#0081-SUCM-024">0081-SUCM-024</a>)

When fetching a market that is part of a "parent / successor chain", we should see both the parent and each successor `marketID` (<a name="0081-SUCM-013" href="#0081-SUCM-013">0081-SUCM-013</a>)


### Snapshots / Protocol Upgrade / Network History


After snapshot restart the successor (child) / parent market state is preserved where applicable including the LPs ELS (<a name="0081-SUCM-017" href="#0081-SUCM-017">0081-SUCM-017</a>)

A market which has expired before a protocol upgrade is still eligible to be used as a successor market after the upgrade, if it is inside the successor time window (<a name="0081-SUCM-025" href="#0081-SUCM-025">0081-SUCM-025</a>)

A data node restored from network history includes the full succession chain for a market. (<a name="0081-SUCM-026" href="#0081-SUCM-026">0081-SUCM-026</a>)


### Virtual stake

A new market is set with a parent market Id. On the parent there are two parties `A` and `B` with virtual stakes `v1` and `v2` and physical stakes `s1` and `s2`

If

- Both `A` and `B` submit a liquidity commitment of `s1` and `s2` to the new market before the opening auction ends. No other LP submits liquidity to the new market. Then, once the opening auction resolved the LPs `A` and `B` have virtual stakes `v1` and `v2` (<a name="0081-SUCM-020" href="#0081-SUCM-020">0081-SUCM-020</a>).
- As above but `A` submits `s1` and `B` doesn't submit anything. Then `A` has virtual stake `v1` and `B` has virtual stake `0` (<a name="0081-SUCM-021" href="#0081-SUCM-021">0081-SUCM-021</a>).
- As above but `A` submits more than `s1`. Then `A` has virtual stake larger than `v1`. (<a name="0081-SUCM-022" href="#0081-SUCM-022">0081-SUCM-022</a>)

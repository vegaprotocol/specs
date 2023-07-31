# Margin orchestration

## Acceptance criteria

1. If risk factors have been updated, the margin levels for all market participants are recalculated. (<a name="0010-MARG-001" href="#0010-MARG-001">0010-MARG-001</a>)
1. If the mark price changes, margins are recalculated for all participants (<a name="0010-MARG-004" href="#0010-MARG-004">0010-MARG-004</a>)
1. If a trader's open position changes their margins are recalculated.  (<a name="0010-MARG-005" href="#0010-MARG-005">0010-MARG-005</a>)
1. If a trader's open orders change their margins are recalculated  (<a name="0010-MARG-006" href="#0010-MARG-006">0010-MARG-006</a>)
1. The mark price changes causing the trader’s margin to move into the search zone. A collateral search is initiated and the margin is topped back up above the search zone. (<a name="0010-MARG-007" href="#0010-MARG-007">0010-MARG-007</a>)
1. The mark price changes causing the trader’s margin to move into the search zone. A collateral search is initiated and the margin is topped back up to a level which results in the trader still being in the search zone. No further actions are taken. (<a name="0010-MARG-008" href="#0010-MARG-008">0010-MARG-008</a>)
1. The mark price changes causing the trader’s margin to move into the close-out zone. A collateral search is initiated and the margin is topped back up to the search zone. No further actions are taken. (<a name="0010-MARG-009" href="#0010-MARG-009">0010-MARG-009</a>)
1. The mark price changes causing the trader’s margin to move into the close-out zone. A collateral search is initiated and the margin is topped back up to a level which results in the trader still being in the close-out zone.  (<a name="0010-MARG-010" href="#0010-MARG-010">0010-MARG-010</a>)
1. The mark price changes causing the trader’s margin to move in to the release level. Margin should be released back to the trader. (<a name="0010-MARG-011" href="#0010-MARG-011">0010-MARG-011</a>)
1. Maintenance margin is correctly calculated for a party with orders / positions when obtaining risk factors from the lognormal risk model under various different parameters. In particular we see that:
    1. maintenance margin obtained when sigma is 1.0 is lower than maintenance margin obtained when sigma is 1.5 (<a name="0010-MARG-012" href="#0010-MARG-012">0010-MARG-012</a>)
    1. maintenance margin obtained when tau is 1.0/365.25/24 is lower than maintenance margin obtained when tau is 1.0/365.25/24/12 (<a name="0010-MARG-013" href="#0010-MARG-013">0010-MARG-013</a>)
    1. maintenance margin obtained when risk aversion / lambda is 0.01 is lower than maintenance margin obtained when risk aversion / lambda is 0.0001 (<a name="0010-MARG-014" href="#0010-MARG-014">0010-MARG-014</a>)
1. The margin scaling levels (maintenance, search, initial, release) are correctly applied to the maintenance margin that is calculated by the risk model. In particular we see that:
    1. if there are two identical markets except that one has release level set to 1.7 and the other to 2.0 then a party has to see more mark-to-market gains on a position on the market with 2.0 than on the market with 1.7 to see funds transferred into the general account (<a name="0010-MARG-015" href="#0010-MARG-015">0010-MARG-015</a>)
    1. if there are two identical markets except that one has search level set to 1.1 and the other to 1.3 then the system will transfer funds from general to margin for a party that sees mark-to-market losses on its position earlier on the market with 1.3 than on the market with 1.1 to see funds transferred into the general account (<a name="0010-MARG-016" href="#0010-MARG-016">0010-MARG-016</a>)
    1. if there are two identical markets except that one has initial level 1.3 and the other 1.5 then a party with no position or orders that places a market order will see a bigger transfer to the margin account on the market with 1.5 than on the one with 1.3. (<a name="0010-MARG-017" href="#0010-MARG-017">0010-MARG-017</a>)
1. Whenever the `market.margin.scalingFactors` network parameter is updated via governance, when margin calculations are next triggered and margin balances re-evaluated for any party, the new scaling factors are applied (there is no need to recalculate margins on an update) (<a name="0010-MARG-018" href="#0010-MARG-018">0010-MARG-018</a>)

## Summary

This ticket encapsulates the orchestration of business logic which interfaces with the specified [risk model](./0018-RSKM-quant_risk_models.ipynb) (specified at the instrument level) to ensure that margin levels are calculated whenever certain conditions are met.

## Reference-level explanation

This specification outlines:

- When the margin levels are recalculated and for whom
- How the margin levels are utilised in the protocol

### **Background - how margin levels are calculated**

The [margin calculator](./0019-MCAL-margin_calculator.md) will calculate the margin levels when instructed to do so. It will return four margin levels for each trader:

1. maintenance margin
1. order margin
1. collateral search level
1. initial margin
1. collateral release level

The [margin calculator](./0019-MCAL-margin_calculator.md) utilises risk factors which are updated by the [quant risk model](./0018-RSKM-quant_risk_models.ipynb).

### **Conditions for recalculating margins**

#### 1. Updating margins when risk factors have been updated

Recalculate all margins when:

If risk factors have been updated, the margin levels for all market participants needs to also be recalculated and evaluated for solvency (see Step 2).

#### 2. Updating margins when market data changes

Recalculate all margins for when any of the following are met:

1. when market observable used in the [margin calculation](./0019-MCAL-margin_calculator.md) changes,
2. when risk factors are [updated](./0018-RSKM-quant_risk_models.ipynb).

#### 3. Updating margins when positions have changed

If already re-calculating all margins, don’t need to check for this. Otherwise, recalculate one participant's margins if any of the conditions below are met:

1. If a trader’s net open position changes
2. If either or both of a traders net potential long or short position (e.g. the sum of all buy order volume and sum of all sell order volume) has changed

### **Utilising margins to evaluate solvency**

The [margin calculator](./0019-MCAL-margin_calculator.md) returns four margin levels per position; the _collateral release level_, _initial margin_, _collateral search level_ and _maintenance margin_.

The protocol compares these levels to the balance in the trader's margin account for a market.

| Traders Collateral        | Protocol  Action           | Whitepaper Description
| ------------- |:-------------:| -----:|
| less than  _collateral search level_     | Collateral search, possibly close outs | Collateral search, Close out zone
| greater than  _collateral release level_       | Collateral release      | Collateral release
| greater than _collateral search level_ and less than  _initial margin_  | no action     | No financial risk to network

When posting a new order the initial margin for the overall position including the new order is calculated and order is only allowed to go ahead if party has enough funds to bring their margin account balance to that figure. An exception to this is when a party has an open position and tries to reduce it, but cannot afford the new margin. Then orders from the opposite side (short orders for a long position, long orders for a short position) are accepted as follows:

- limit order: accept order when sum sizes of all the party's order's for that side of the book including the one being posted is less than or equal to the absolute open volume that a party has,
- market order: accept order as long as its size is less than or equal to the absolute open volume that a party has.

#### Collateral search

When a trader's balance in their margin account (for a market) is less than their position’s collateral search level the protocol will attempt to transfer sufficient collateral from the trader’s main collateral account to top up their margin account to the level of the _initial margin_.

#### Close outs

After a collateral search, if the amount in the margin account is below the closeout level AFTER the collateral transfer request completes (whether successful or not) OR in an asynchronous (sharded) environment if the latest view of the trader’s available collateral suggests this will be the case, the trader is considered to be _distressed_ and is added to list of traders that will then undergo [position resolution](./0012-POSR-position_resolution.md).

[Position resolution](./0012-POSR-position_resolution.md) is executed simultaneously for ALL traders on a market that have been determined to require it during a single event. That is, the orchestrator ‘batches up’ the traders and runs [position resolution](./0012-POSR-position_resolution.md) once the full set of traders is known for this event. Sometimes that will only be for one trader, sometimes it will be for many.

#### Releasing collateral

Traders who have a margin account balance greater than the  _release level_ should have the excess margin released to their general collateral account, to the point where their new margin level is equal to the _initial margin_.

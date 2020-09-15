# Margin orchestration

## Acceptance criteria

1. [ ] If risk factors have been updated, the margin levels for all market participants are recalculated.
1. [ ] There is no threshold for significant order book changes, and a new order adds or removes volume to the order book, margins are recalculated for all participants.
1. [ ] There is a threshold for significant order book changes, and a new order adds or removes volume to the order book that makes a change that doesn't exceed the threshold, margins are not recalculated for any participants. 
1. [ ] If the mark price changes, margins are recalculated for all participants
1. [ ] If a trader's open position changes their margins are recalculated.
1. [ ] If a trader's open orders change their margins are recalculated
1. [ ] The mark price changes causing the trader’s margin to move into the search zone. A collateral search is initiated and the margin is topped back up above the search zone.
1. [ ] The mark price changes causing the trader’s margin to move into the search zone. A collateral search is initiated and the margin is topped back up to a level which results in the trader still being in the search zone. No further actions are taken.
1. [ ] The mark price changes causing the trader’s margin to move into the close-out zone. A collateral search is initiated and the margin is topped back up to the search zone. No further actions are taken.
1. [ ] The mark price changes causing the trader’s margin to move into the close-out zone. A collateral search is initiated and the margin is topped back up to a level which results in the trader still being in the close-out zone.
1. [ ] The mark price changes causing the trader’s margin to move in to the release level. Margin should be released back to the trader. 

## Summary
This ticket encapsulates the orchestration of business logic which interfaces with the specified [risk model](./0018-quant-risk-models.ipynb) (specified at the instrument level) to ensure that margin levels are calculated whenever certain conditions are met.

## Reference-level explanation

This specification outlines:
- When the margin levels are recalculated and for whom
- How the margin levels are utilised in the protocol

### **Background - how margin levels are calculated**

The [margin calculator](./0019-margin-calculator.md) will calculate the margin levels when instructed to do so. It will return four margin levels for each trader:

1. maintenance margin
1. collateral search level
1. initial margin
1. collateral release level

The [margin calculator](./0019-margin-calculator.md) utilises risk factors which are updated by the [quant risk model](./0018-quant-risk-models.ipynb).  


###  **Conditions for recalculating margins**

#### 1. Updating margins when risk factors have been updated

Recalculate all margins when:

If risk factors have been updated, the margin levels for all market participants needs to also be recalculated and evaluated for solvency (see Step 2).

#### 2. Updating margins when market data changes

Recalculate all margins for when any of the following are met:

1. Order book changes (subject to a threshold being exceeded)
1. If mark price changes
1. When market observable used in the [margin calculation](./0019-margin-calculator.md) changes

#### 3. Updating margins when positions have changed

If already re-calculating all margins, don’t need to check for this. Otherwise, recalculate one participant's margins if any of the conditions below are met:

1. If a trader’s net open position changes
1. If either or both of a traders net potential long or short position (e.g. the sum of all buy order volume and sum of all sell order volume) has changed


### **Utilising margins to evaluate solvency**

The [margin calculator](./0019-margin-calculator.md) returns four margin levels per position; the _collateral release level_, _initial margin_, _collateral search level_ and _maintenance margin_.

The protocol compares these levels to the balance in the trader's margin account for a market.

| Traders Collateral        | Protocol  Action           | Whitepaper Description
| ------------- |:-------------:| -----:|
| less than  _collateral search level_     | Collateral search, possibly close outs | Collateral search, Close out zone
| greater than  _collateral release level_       | Collateral release      | Collateral release
| greater than _collateral search level_ and less than  _initial margin_  | no action     | No financial risk to network

#### Collateral search

When a trader's balance in their margin account (for a market) is less than their position’s collateral search level the protocol will attempt to transfer sufficient collateral from the trader’s main collateral account to top up their margin account to the level of the _initial margin_.

#### Close outs

After a collateral search, if the amount in the margin account is below the closeout level AFTER the collateral transfer request completes (whether successful or not) OR in an async (sharded) environment if the latest view of the trader’s available collateral suggests this will be the case, the trader is considered to be _distressed_ and is added to list of traders that will then undergo [position resolution](./0012-position-resolution.md).

[Position resolution](./0012-position-resolution.md) is executed simultaneously for ALL traders on a market that have been determined to require it during a single event. That is, the orchestrator ‘batches up’ the traders and runs [position resolution](./0012-position-resolution.md) once the full set of traders is known for this event. Sometimes that will only be for one trader, sometimes it will be for many.

#### Releasing collateral
Traders who have a margin account balance greater than the  _release level_ should have the excess margin released to their general collateral account, to the point where their new margin level is equal to the _initial margin_.

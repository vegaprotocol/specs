Feature name: risk and margin orchestration

Start date: YYYY-MM-DD

Specification PR: 

Product Gitlab ticket: 107

Whitepaper sections: 

# Summary
This ticket encapsulates the orchestration of business logic which interfaces with the [quant risk suite](./0018-quant-risk-suite.md) to ensure that margin levels are calculated and utilised correctly according to the protocol.

# Guide-level explanation
- Introducing new named concepts


- Explaining the features, providing some simple high level examples




- If applicable, provide migration guidance

# Reference-level explanation

## Orchestration


### ***Calculating margins***

Vega needs to evaluate after each market event (e.g. after processing each market instruction / transaction) whether or not any risk actions need to be performed. The outcome of this determination logic is either:
- No action

or

- **Updating risk factors** and then getting new margin levels.
- **Getting margin levels** for one or more open positions.

The [quant risk suite](./0018-quant-risk-suite.md) describes interfaces to the specific functionality that calculates the risk factors and margin levels.

Determination  of which action is appropriate to instigate is based on the event details, which include:
* The market instruction that was processed
* The set (possibly empty) of trades that were executed
* The set (possibly empty) of order book updates
* The market data

#### Updating risk factors

Risk factors are an input to the [margin calculation](./0019-margin-calculator.md) and are calculated using a [quantitative risk model](./0018-quant-risk-suite.md).

Risk factors are updated if  
* An update risk factors call is not already in progress asynchronously; AND
* A specified period of time has elapsed (period can = 0 for always recalculate) for re-calculating risk factors. This period of time is defined as a risk parameter (see [market framework](./0001-market-framework.md)).

>Nicenet - for futures you can do this as often as you like since the calculation is dirt cheap

Risk factors are also updated if on creation of a new market that does not yet have risk factors, as any active market needs to have risk factors.

Note, when risk factors are updated, the margin levels for all market participants needs to also be recalculated and evaluated for solvency (see Step 2).


#### Calculating margin levels

Vega needs to recalculate the margin levels for participants if 

  * Market data has changed (recalculate ALL margins)
    * [FUTURE] Dependent market data can be specified by Product
    * [FUTURE] Change can be subject to a threshold
    * [NICENET] If orders on book change at all
    * [NICENET] If mark price changes
 * Positions have changed (recalculate margins for changed positions)
  * If already re-calculating all margins, don’t need to check for this
    * [NICENET] If a trader’s net open position changes
    * [NICENET] If either or both of a traders net potential long or short position (e.g. the sum of all buy order volume and sum of all sell order volume) has changed
    * [NICENET] Risk factors change (recalculate all margins)
    * [NICENET] The market is created


### ***Evaluating level of solvency***

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



# Scenarios 
1. The mark price changes causing the trader’s margin to move into the search zone. A collateral search is initiated and the margin is topped back up above the search zone.
1. The mark price changes causing the trader’s margin to move into the search zone. A collateral search is initiated and the margin is topped back up to a level which results in the trader still being in the search zone. No further actions are taken.
1. The mark price changes causing the trader’s margin to move into the close-out zone. A collateral search is initiated and the margin is topped back up to the search zone. No further actions are taken.
1. The mark price changes causing the trader’s margin to move into the close-out zone. A collateral search is initiated and the margin is topped back up to a level which results in the trader still being in the close-out zone. This trader becomes a werewolf.
1. The mark price changes causing the trader’s margin to move in to the release level. Margin should be released back to the trader. 
1. On the market creation, the initial risk factors are created based on the market risk parameters
# Market Lifecycle

All markets have a "trading mode" (plus its configuration) as part of the [market framework](0001-market-framework.md). 
When a market is Active (i.e. it is open for trading), it will be in a trading period. Normally, the trading period will be defined by the trading mode (additionally, this is one period for the life of the market unless changed by governance once it opens, but in future, trading modes may specify a schedule of periods). 
When created, a market be in a pending state which is currently an opening auction. Markets can also enter exceptional periods of either defined or indefinite length as the result of triggers such as price or liquidity monitoring or a governance vote (this spec does not specify any triggers that should switch periods, only that it must be possible).

## Overview

Markets on Vega are permissionlessly proposed using the [governance mechanism](./0028-governance.md#1-create-market). If a market passes the governance vote, it undergoes various state changes throughout its lifecycle. Aspects of the state that change include:
- trading mode
- whether the market is open for trading
- status of settlement

## Market Creation

Markets proposed via [governance proposals](./0028-governance.md#1-create-market) undergo certain additional validations. 
Please distinguish between a proposal that is `valid` or `accepted` and a proposal that `sucessful`. A valid / accepted proposal just passed validation checks; a successful proposal has been voted for and won.

## Market lifecycle statuses

A market can progress through a number of states through its life. The overall market status flow is shown in the diagram below.
A market is created in a `proposed` state upon submission of a valid market creation governance proposal. 


| State              | Accepting LPs  | Trading Mode        | Entry                                                           | Exit                   
| ------------------ | -------------- | ------------------- | --------------------------------------------------------------- | -----------------------------------------         
| Proposed           |   Yes          | No trading          | Governance proposal valid                                       | Governance proposal voting period ends
| Rejected           |   No           | No trading          | Outcome of governance votes is to reject the market             | N/A                                                    
| Pending            |   Yes          | Opening auction     | Governance vote passes/wins                                     | Governance vote (to close) OR enactment date reached
| Cancelled           |  No           | No trading          | Opening of market cancelled before market becomes Active              | N/A                                                    
| Active             |   Yes          | Normal trading      | Enactment date reached and usual auction exit checks pass       | Governance vote (to close) OR maturity of market      
| Suspended          |   Yes          | Exceptional auction | Price monitoring or liquidity monitoring trigger                | Monitoring definition
| Closed             |   No           | No trading          | Governance vote (to close)                                      | N/A
| Trading Terminated |   No           | No trading          | Market parameter setting closing date OR defined on the product | Settlement event commences                       
| Settled            |   No           | No trading          | Settlement event concludes                                      | N/A                                            



## Market status descriptions

### Proposed

All Markets are first [proposed via the governance mechanism](./0028-governance.md#1-create-market). Once the Market Proposal is accepted as a valid proposal *the Market (see [market framework](./0001-market-framework.md)) is created* and can accept liquidity commitments, voting begins and its state is `proposed`.

**Entry:**

- Valid [governance proposal](./0028-governance.md#1-create-market) submitted and accepted. For the avcoidance of doubt, this Proposal must include a (valid) specification of the Market and a Liquidity Commitment for at least the *market proposer minimum liquidity commitment (stake)*, which is a Network Parameter.

**Exit:**

- Market Proposal voting period ends

  - Passed (yes votes win & thresholds met) → Pending
  - Failed (no votes win or thresholds not met) → Rejected

**Behaviour:**

- Participants can vote for or against the Market Proposal
- Liquidity Providers can make, change, or exit Liquidity Commitments (proposer can't commit below proposer minimum)
- No trading is possible, no orders can be placed (except the buy/sell order shapes that form part of a Liquidity Commitment)
- No market data (price, etc.) is emitted, no positions exist on the market, and no risk management occurs


### Rejected

When a Market Proposal is not successful, see [governance proposal](./0028-governance.md#outcome), Market state is Rejected. 

**Entry:**

- Voting period ends
  - Failed (no votes win or thresholds not met) → Rejected

**Exit:**

- No exit. End state.

**Behaviour:**

- Nothing can happen to the market with this status - it does not exist (Vega core has no need to keep any information about this market proposal).


### Pending

When a Market Proposal is successful at the end of the voting period, the Market state becomes "Pending". Currently a Pending Market is always in an [auction call period](./0026-auctions.md) that ends at the enactment date as specified in the Market Proposal. 

Note: this state represents any market that will be created, which currently means a Market Proposal vote has concluded successfully. In reasonably near future there will be automated market creation e.g. for a series of markets that is voted on once, market creation from an data source (oracle), etc. so market creation and the market lifecycle should be implemented indepdently of the governance framework and the lifecycle of a proposal. 

**Entry:**

- Valid [Market Proposal](./0028-governance.md#1-create-market) was successful (yes votes win & thresholds met)

**Exit:**

- Auction period ends when any of the following occur:

  - Enactment date is reached and the [conditions for exiting an auction](./0026-auctions.md) are met and at least one trade will be generated when uncrossing the auction → Active (the auction is uncrossed during this transition)
  - Enactment date is passed and the product would trigger the Trading Terminated status  →  Cancelled (the market ceases to exist, auction orders are cancelled, and no uncrossing occurs)
  - Enactment date is passed by more than the *maximum opening auction extension duration* Network Parameter →  Cancelled (the market ceases to exist, auction orders are cancelled, and no uncrossing occurs)
  - Market change governance vote approves closure of market → Cancelled (the market ceases to exist, auction orders are cancelled, and no uncrossing occurs)


**Behaviour:**

- Liquidity providers can make, change, or exit commitments (proposer can't commit below proposer minimum)
- Auction orders are accepted as per [any regular auction period](./0026-auctions.md).
- Margins on orders as per auction margin instructions in [margin calculator spec](./0019-margin-calculator.md).


### Cancelled

When a Market Proposal is successful, but conditions are not met to transition the Market to the Active state during the Pending period, and the market either reaches a timeout, the Instrument hits expiry, or goverance votes not to create the market after all, it becomes a Cancelled market. 

In future, it's expected that we will implement the functionality ddescribed in the white paper by which a proposer can revoke their proposal during the voting period by voting against it. In this case the status would also become Cancelled.

**Entry:**

  - Enactment date is passed and the product would trigger the Trading Terminated status  →  Cancelled (the market ceases to exist, auction orders are cancelled, and no uncrossing occurs)
  - Enactment date is passed by more than the *maximum opening auction extension duration* Network Parameter →  Cancelled (the market ceases to exist, auction orders are cancelled, and no uncrossing occurs)
  - Market change governance vote approves closure of market → Cancelled (the market ceases to exist, auction orders are cancelled, and no uncrossing occurs)

**Exit:**

- No exit. End state.

**Behaviour:**

- Nothing can happen to the market with this status - it does not exist (Vega core has no need to keep any information about this market proposal).


### Active

Once the enactment date is reached and the other conditions specified to exit the Pending state are met, the market becomes Active on conclusion of uncrossing of the opening auction. This status indicates it is trading via its normally configured trading mode according to the market framework (continuous trading, frequent batch auction, RFQ, block only, etc.). The specification for the trading mode should describe which orders are accepted and how trading proceeds. The market will terminate trading according to a product trigger (for futures, if the trading termination date is reached) and can be temporarily suspended automatically by various monitoring systems ([price monitoring](./0032-price-monitoring.md), [liquidity monitoring](./0035-liquidity-monitoring.md)). The market can also be closed via a governance vote (market parameter update) to change the status to closed.

**Entry:**

- From Pending: enactment date reached and conditions to transition from Pending state to Active as detailed above are met
- From Suspended: conditions specified in [price monitoring](./0032-price-monitoring.md) and [liquidity monitoring](./0035-liquidity-monitoring.md) are met for the market to exit the suspended status back to Active.

**Exit:**

- Price, liquidity or other monitoring system triggers suspension → Suspended
- Trading termination is triggered by a product trigger (for futures, if the trading termination date, set by a market parameter, is reached) → Trading Terminated
- Market change governance vote approves closure of market → Closed

**Behaviour:**

- Liquidity Providers can make, change, or exit Liquidity Commitments, as per conditions specified in the [liquidity mechanics spec](./0044-lp-mechanics.md). Market Proposer is not committed to provide at least the *market proposer minimum stake* as long as the reduction meets other conditions to reduce/exit Liquidity Commitments.
- Orders can be placed into the market, trading occurs according to normal trading mode rules
- Market data are emitted
- Positions and margins are managed as per the specs


### Suspended

A Suspended market occurs when an Active market is temporarily stopped from trading to protect the market or the network from various types of risk. Suspension is used when the system has determined it is either not safe or not reasonable to operate the market at the current time, for example due to extremely low liquidity. No trades may be created while a market is Suspended.

Suspension currently always operates as an auction call period. Depending on the type of suspension, the aucton call period may have a defined end (which can also be subject to extnesion) or may be indefinite in which case the auction will end once the required conditions are met. The auction is uncrossed as part of the transition back to the Active state and normal trading. Alternatively, a Suspended market may become closed in which case the auction does not uncross and the orders are discarded.

**Entry:**

- Price, liquidity or other monitoring system triggers suspension → Suspended

**Exit:**

- Conditions specified in [price monitoring](./0032-price-monitoring.md) and [liquidity monitoring](./0035-liquidity-monitoring.md) and the usual [ending of auction checks pass](./0026-auctions.md) → Active 
- Governance vote to close a market passes → Closed


**Behaviour:**

- Liquidity providers can make, change, or exit commitments. Market Proposer is not committed to provide at least the *market proposer minimum stake* as long as the reduction meets other conditions to reduce/exit Liquidity Commitments.
- Auction orders are accepted as per [any regular auction period](./0026-auctions.md).
- Margins on orders as per auction based instructions in [margin calculator spec](./0019-margin-calculator.md).


### Closed

Note, this governance action is unspecc'd and not MVP.

**Entry:**

- Governance vote to close a market passes → Closed

**Exit:**

No exit. This is a terminal state.

**Behaviour:**

- Orders may be cancelled, no new orders accepted.


### Trading Terminated

A market may terminate trading if the instrument is one that expires or if the market is otherwise configured to have a finite lifetime. In the case of futures, termination occurs at some point prior to, or at, the settlement of the product. Markets in this state accept no trading but retain the positions and margin balances that were in place after processing the expiry trigger (which may itself generate MTM cashflows, though for futures it doesn't). A market moves from this termination state to Settled when enough information exists and the triggers are reached to settle the market. This could happen instantly upon trading terminating, though usually there will be a delay, for instance to wait for receipt and acceptance of data from a data source (oracle). An example of an instant transition would be where the trigger for terminating trading and the settlement are the publishing of a specific price from another market on the Vega network itself (same shard), or in the rare case of extremely delayed blocks meaning that the settlement data is available before the trigger is activated (note that market creators would be expected to allow enough of a buffer that this should effectively never happen).

**Entry:**

- Triggered by the product (in the case of futures, there is a product parameter that specifies when this will be triggered).

**Exit:**

- Settlement dependencies met (i.e. oracle data received) → Settled

**Behaviour:**

- No trading occurs, no orders are accepted
- Mark to market settlement is performed if required after termination is triggered then never again
- A single set of market data may be emitted for the final settlement data (e.g. settlement mark price), after which no market data are emitted.
- During the transition out of this state:
  - All final settlement cashflows are calculated and applied (settled) 
  - Margins are trannsferred back to general accounts
  - Insurance pool funds are redistributed
- No risk management or price/liquidity monitoring occurs


### Settled

Once the required data to calculate the settlement cashflows is available for an Expired market, these cashflows are calculated and applied to all traders with an open position (settlement). The positions are then closed and all orders cleared. All money held in margin accounts after final settlement is returned to traders' general accounts. The market can be deleted entirely at this point, from a core perspective. Any insurance pool funds are distributed as per the [insurance pool spec](./0015-market-insurance-pool-collateral.md).

**Entry:**

- Trading is Terminated
- Triggered by product logic and inputs (i.e. required data source/oracle data is received)

**Exit:**

- No exit. End state.

**Behaviour:**

- No trading occurs, no orders are accepted
- During the transition into this state:
  - All final settlement cashflows are calculated and applied (settled) 
  - Margins are trannsferred back to general accounts
  - Insurance pool funds are redistributed
- Market is over and can be removed from core data, nothing happens after the final settlement above is complete.
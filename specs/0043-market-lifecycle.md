# Market Lifecycle

## Overview

### Market status

A market can progress through a number of states through its life. The overall market status flow is shown in the diagram below.

![](0029-market-lifecycle-flow-diagram.svg)


### Active markets

All markets have a "trading mode" (plus its configuration) as part of the [market framework](0001-market-framework.md). When a market is Active (i.e. it is open for trading), it will be in a trading period. Normally, the trading period will be defined by the trading mode (additionally, this is one period for the life of the market once it opens, but in future, trading modes may specify a schedule of periods). When created, a market will generally start in an opening auction period. Markets can also enter exeptional periods of either defined or indefinite length as the result of triggers such as price or liquidity monitoring or a governance vote (this spec does not specify any triggers that should switch periods, only that it must be possible).


## Market status details

### Proposed

Markets created via [governance proposals](./0028-governance.md#1-create-market) and voting will always begin in a proposed state. At this point governance is deciding whether the market should be created, and liquidity providers may also support the market proposal by committing liquidity.

**Entry:**

- Valid [governance proposal](./0028-governance.md#1-create-market) submitted and accepted

**Exit:**

- Voting period ends

  - Passed (yes votes win & thresholds met) → Pending
  - Failed (no votes win or thresholds not met) → Pending

**Behaviour:**

- Participants can vote for or against the market
- Liquidity providers can make, change, or exit commitments
- No trading is possible, no orders can be placed (except the liquidity provider order/shape that forms part of their commitment)
- No market data (price, etc.) is emitted, no positions exist on the market, and no risk management occurs


### Pending

Once creation of a market is approved via a governance proposal, or (in future) when a market is scheduled to be created as part of a series of auto-generated markets, it enters a pending state prior to being created. A Pending market becomes an Active market when both the enactment date is reached and it has met the minimum liquidity commitment requirement. A market will be cancelled before creation if the maximum time allowed (network param) to collect liquidity is excdeed, if the market reaches its expiry date (if applicable) whilst in a pending state, or via a governance vote.

**Entry:**

- Governance vote passed (yes votes win & thresholds met)
- [Future: Market creation is scheduled via a series]

**Exit:**

- Enactment date is reached and liquidity stake committed >= minimum required launch liquidity → Active
- Expiry date is reached and liquidity stake committed < minimum required launch liquidity → Cancelled
- Maximum time in Pending (a network parameter) is reached and liquidity stake committed < minimum required launch liquidity → Cancelled
- Market change governance vote approves closure/cancellation of market → Cancelled

**Behaviour:**

- Liquidity providers can make, change, or exit commitments
- No trading is possible, no orders can be placed (except the liquidity provider order/shape that forms part of their commitment)
- No market data (price, etc.) is emitted, no positions exist on the market, and no risk management occurs




### Problematic states and their resolutions

#### Insufficient liquidity to close out a trader
In the situation that there is insufficient liquidity to close out a trader, the market is put in to a [liquidity sourcing auction](./0026-auctions.md). This will be triggered by [liquidity monitoring](./0035-liquidity-monitoring.md).

The parameters for the auction will be as follows:
- Duration: ???

At the auction end, all positions are marked to market, and closeout trades will be created as usual.

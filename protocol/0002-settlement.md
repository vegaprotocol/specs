# Settlement

Settlement is the process of moving collateral between accounts when a position is closed,  the market expires or if there is an interim settlement action defined in the product.

Further to this, the protocol may elect to settle a market at a point in time by carrying out [mark to market settlement](./0003-mark-to-market-settlement.md). This is helpful for maintaining lower margins requirements.

## Overview

Settlement occurs when:

1. **A position is fully or partially closed** - An open position is closed when the owner of the open position enters into a counter trade (including if that trade is created as part of a forced risk management closeout). Settlement occurs for the closed volume / contracts.
1. **[An instrument expires](#settlement-at-instrument-expiry)** - all open positions in the market are settled. After settlement at expiry, all positions are closed and collateral is released.
1. **Interim cash flows are generated** - not relevant for first instruments launched on Vega. Will be potentially relevant for perpetual futures with periodic settlement.
1. **Mark to market event** - when the protocol runs [mark to market settlement](./0003-mark-to-market-settlement.md).


Settlement instructions need to contain information regarding the accounts from which collateral should be sourced and deducted (in order of preference) and accounts to which the collateral should be deposited.

For settlement at expiry scenarios, transfers should attempt to access 
1. the trader's margin account for the Market, 
1. the trader's general collateral account for that asset 
1. the insurance pool. 

## Settlement at instrument expiry
Settlement at instrument expiry is the end of a market.
- Fees 
  - What fees happen at expiry (none) 
- Insurance pool is the only account for a market. How is that transferred
  - How does this interact with any rewards
- What happens if we're in an auction at expiry time
- 
### When does a market settle at instrument expiry
The expiry of a market happens when an oracle publishes data that meets the filter requirements.
1. Default trading mode/auction is happening
2. The product's trading terminated trigger is hit, so no more trading is possible (link), [market status is set to x](./0016-product-builtin-future.md#41-termination-of-trading)
3. Time passes
4. An oracle event occurs that matches the oracle data spec (link)
5. [Final cashflow is calculated](./0016-product-builtin-future.md#42-final-settlement-expiry)
6. Accounts are settled: [Collection and distribution](https://github.com/vegaprotocol/specs-internal/blob/settlement-at-expiry/protocol/0003-mark-to-market-settlement.md#reference-level-explanation) as per Mark to Market settlement
7. Insurance pool stuff is dealt with in some way
8. Market status is now set to SETTLED


### Actions taken at instrument expiry
- All positions are fully closed and settled
- All accounts related to the market are zeroed, balances being transferred elsewhere
- The market's status is set to x

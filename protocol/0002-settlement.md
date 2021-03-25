# Settlement Summary

Settlement is the process of moving collateral between accounts when a position is closed,  the market expires or if there is an interim settlement action defined in the product.

Further to this, the protocol may elect to settle a market at a point in time by carrying out [mark to market settlement](./0003-mark-to-market-settlement.md). This is helpful for maintaining lower margins requirements.

# Guide-level explanation

# Reference-level explanation

Settlement occurs when:

1. **A position is fully or partially closed** - An open position is closed when the owner of the open position enters into a counter trade (including if that trade is created as part of a forced risk management closeout). Settlement occurs for the closed volume / contracts.
1. **An instrument expires** - all open positions in the market are settled. After settlement at expiry, all positions are closed and collateral is released.
1. **Interim cash flows are generated** - not relevant for first instruments launched on Vega. Will be potentially relevant for perpetual futures with periodic settlement.
1. **Mark to market event** - when the protocol runs [mark to market settlement](./0003-mark-to-market-settlement.md).


Settlement instructions need to contain information regarding the accounts from which collateral should be sourced and deducted (in order of preference) and accounts to which the collateral should be deposited.

For settlement at expiry scenarios, transfers should attempt to access 
1. the trader's margin account for the Market, 
1. the trader's general collateral account for that asset 
1. the insurance pool. 

For interim and closeout settlement the trader's collateral account may be accessed first, then the margin account.

Settlement instructions result in ledger entries being generated that strictly conform  to double entry accounting.

# Pseudo Code / Examples

## Settlement data structures

```

TransferRequest {
  from: [Account], // This is an array of accounts ion order of precedence, e.g. the first account in the list is emptied first when making transfers. For settlement at expiry scenarios, transferRequests will be sequenced to access 1. the trader's margin account for the Market, 2. the trader's collateral account and 3. the insurance pool. For interim and closeout settlement the trader's collateral account may be accessed first, then the margin account.
  to: Account, // For settlement scenarios, this is the market's settlement account.
  amount: FinancialAmount,
  reference: ???,  // some way to link back to the causal event that created this transfer
  type: enum ,  // what type of transfer - types TBC, could leave this field out initially
  min_amount: uint // This needs to be scoped to each FinancialAmount
}


TransferResponse {
  transfers: [LedgerEntry]
  balances: ?? // e.g. it is necessary to know the balance of the market's settlement account to know if distribution is simple or requires position resolution calcs. Note it may be that when making the request the settlement engine specifies account IDs for which it requires balances as if there are 1000s of positions that is a "lot" of data and we only require the balance for the settlement account to process further
}

LedgerEntry: {
  from: Account,
  to: Account,
  amount: FinancialAmount,
  reference: String,
  type: String,
  timestamp: DateTime
}

```

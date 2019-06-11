# Outline
Trade settlement is the process of transferring securities between buyers and sellers, see Section 5.2 of the [whitepaper](/vega-protocol/product/wikis/Whitepaper). 


## Settlement actions are triggered when:

### **1. A position is fully or partially closed (0003))**
An open position is closed when the owner of the open position enters into a counter trade (including if that trade is created as part of a forced risk management closeout). Settlement occurs for the closed volume / contracts.

### **2. Interim cash flows are generated**
not relevant for first instruments launched on Vega. Will be potentially relevant for perpetual futures with period settlement.

### **3. An instrument expires (0003-settlement-at-instrument-expiry)[./0003-settlement-at-instrument-expiry.md*
All open positions in the market are settled.  
After settlement at expiry, all positions are closed and collateral is released.


## Settlement actions which apply to all of the above triggers are:

The settlement engine's job is to convert settlement instructions scoped to a market from the [product](https://gitlab.com/vega-protocol/product/issues/80#product) into specific ledger entry instructions for the collateral engine.


## Pseudo Code / Examples

### Settlement Engine data structures

```

// sent by Settlement Engine to the Collateral Engine
TransferRequest {
  from: [Account], // This is an array of accounts ion order of precedence, e.g. the first account in the list is emptied first when making transfers. For settlement at expiry scenarios, transferRequests will be sequenced to access 1. the trader's margin account for the Market, 2. the trader's collateral account and 3. the insurance pool. For interim and closeout settlement the trader's collateral account may be accessed first, then the margin account.
  to: Account, // For settlement scenarios, this is the market's settlement account.
  amount: FinancialAmount,
  reference: ???,  // some way to link back to the causal event that created this transfer
  type: enum ,  // what type of transfer - types TBC, could leave this field out initially
  min_amount: uint // This needs to be scoped to each FinancialAmount
}

// The collateral engine will respond with the LedgerEntry it executed.

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

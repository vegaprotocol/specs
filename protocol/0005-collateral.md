Feature name: collateral

# Acceptance Criteria
* [ ] Transfer requests are the only way the collateral engine will change the amounts of assets
* [ ] A transfer request will always only instruct one asset to be transferred.
* [ ] If a transfer request does not contain an equal amount of debit assets to credit assets it is malformed and should be outright rejected by the collateral engine  
* [ ] One transfer request may result in multiple ledger entries. 
* [ ] Each ledger entry will specify one debit account, one credit account and one amount of a single asset.
* [ ] Creation and deletion of accounts - see [accounts](./0013-accounts.md).

# Summary

The collateral engine's **only job** is to maintain Vega's ledger of accounts and the assets they contain strictly using a double entry accounting system.  

# Guide-level explanation



# Reference-level explanation

The collateral manager will receive a transfer request and return ledger entries of the resulting actions it has undertaken. This is the collateral manager's only job.  It does not treat any transfer request differently to another transfer request. It has no knowledge of the state of the system (e.g whether it's a transfer request due to a market expiring vs a transfer request due to a trader withdrawing collateral).

Every transfer request will detail an account (or accounts) from which an amount of asset should be debited and a corresponding account (or accounts) which should have these assets credited.  Importantly, the total amount that is debited per transaction request must always equal the total amount that is credited for all assets (this maintains the double entry accounting). If the transfer request does not detail this it is malformed and should not be processed at all by the collateral engine

Note, this also includes when an account is initialised. All accounts that are initialised will have an initial value of zero for all assets it holds.  All changes to this value will occur via transfer requests, including from:

1. The trading core (e.g. if a trader has deposited collateral into the Vega Smart Contract).
2. The settlement engine (e.g. during settlement)

Accounts may be created and deleted by transfer requests. Deleted account transfer requests must specify which account should receive any outstanding funds in the account that's being deleted (see [accounts](./0013-accounts.md))


# Pseudo-code / Examples

Data Structures

```
TransferRequest {
  from: [Account], // This is an array of accounts in order of precedence, e.g. the first account in the list is emptied first when making transfers. For settlement at expiry scenarios, transferRequests will be sequenced to access 1. the trader's margin account for the Market, 2. the trader's collateral account and 3. the insurance pool.
  to: Account,
  amount: FinancialAmount,
  reference: ???,  // some way to link back to the causal event that created this transfer
  type: enum ,  // what type of transfer - types TBC, could leave this field out initially
  min_amount: uint // This needs to be scoped to each FinancialAmount
  delete_account: Bool // this specifies if the "from" account should be deleted.
}
```

```
// The collateral engine will respond with the LedgerEntry it executed.

TransferResponse {
  transfers: [LedgerEntry]
  balances: ?? // e.g. it is necessary to know the balance of the market's settlement account to know if distribution is simple or requires position resolution calcs.
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

# Test cases

# APIs
At a minimum on the front end, a trader should know how much money is in each of their "main accounts" and each of their "margin account".  They will typically also want to know how much their Unrealised PnL / Mark to market is for each market, so that they understand the composition of the "margin account".  
# Summary

The collateral engine's **only job** is to maintain Vega's ledger of accounts and the assets they contain strictly using a double entry accounting system.

## Reference-level explanation

### Assets

Collateral on Vega refers to any asset. Vega chain doesn't have any native tokens. Effectively all assets are bridged from other chains, currently only via the [Ethereum ERC20 bridge](./0031-ETHB-ethereum_bridge_spec.md). There is a small exception in that there can be "internal assets" that are used for testing only (balances in those can be obtained by accessing faucets).
Note that there is also a staking bridge for the governance ERC20 token ($VEGA) but such asset is only available for staking and governance and is not a collateral in the sense that it cannot be transferred to other accounts.

Depositing assets: Vega core listens to events on other chains (currently Ethereum) for events on the bridge contract. If asset is locked on the bridge contract with a Vega party key associated then the [general account](./0013-ACCT-accounts.md) balance for the party is incremented by the appropriate amount.

Withdrawing assets: If a Vega party submits a withdrawal transaction containing amount and destination address on the bridged chain then vega nodes sign a withdrawal bundle, decrement the [general account](./0013-ACCT-accounts.md) by the appropriate amount and publish the withdrawal bundle. The requesting party is then expected to submit this immediately on the bridged chain to complete withdrawal.

The withdrawal bundle is only valid at time of creation. It is possible that validator nodes [leave / join](./0069-VCBS-validators_chosen_by_stake.md) thus changing the composition of signers on the [multisig contract](./0030-ETHM-multisig_control_spec.md). At some point the signature bundle may have fewer valid signatures than the `threshold` specified in the multisig contract. At that point it becomes unusable.

### Collateral Manager

The collateral manager will receive a transfer request and return ledger entries of the resulting actions it has undertaken. This is the collateral manager's only job.  It does not treat any transfer request differently to another transfer request. It has no knowledge of the state of the system (e.g whether it's a transfer request due to a market expiring vs a transfer request due to a trader withdrawing collateral).

Every transfer request will detail an account (or accounts) from which an amount of asset should be debited and a corresponding account (or accounts) which should have these assets credited.  Importantly, the total amount that is debited per transaction request must always equal the total amount that is credited for all assets (this maintains the double entry accounting). If the transfer request does not detail this it is malformed and should not be processed at all by the collateral engine.

Note, this also includes when an account is initialised. All accounts that are initialised will have an initial value of zero for all assets it holds.  All changes to this value will occur via transfer requests, including from:

1. The trading core (e.g. if a trader has deposited collateral into the Vega Smart Contract).
2. The settlement engine (e.g. during settlement).

Accounts may be created and deleted by transfer requests. Deleted account transfer requests must specify which account should receive any outstanding funds in the account that's being deleted (see [accounts](./0013-ACCT-accounts.md)).

## Pseudo-code / Examples

Data Structures

```json
TransferRequest {
  from: [Account], // This is an array of accounts in order of precedence, e.g. the first account in the list is emptied first when making transfers. For settlement at expiry scenarios, transferRequests will be sequenced to access 1. the trader's margin account for the Market, 2. the trader's collateral account and 3. the market's insurance pool.
  to: Account,
  amount: FinancialAmount,
  reference: ???,  // some way to link back to the causal event that created this transfer
  type: enum ,  // what type of transfer - types TBC, could leave this field out initially
  min_amount: uint // This needs to be scoped to each FinancialAmount
  delete_account: Bool // this specifies if the "from" account should be deleted.
}
```

```json
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

## Test cases

### APIs

At a minimum on the front end, a trader should know how much money is in each of their "main accounts" and each of their "margin account".  They will typically also want to know how much their Unrealised PnL / Mark to market is for each market, so that they understand the composition of the "margin account".

### Acceptance Criteria

* Collateral engine emits an event on each transfer with source account, destination account and amount (<a name="0005-COLL-001" href="#0005-COLL-001">0005-COLL-001</a>)
* In absence of deposits or withdrawals via a bridge the total amount of any asset across all the accounts for the asset remains constant. (<a name="0005-COLL-002" href="#0005-COLL-002">0005-COLL-002</a>)

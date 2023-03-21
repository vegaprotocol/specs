This feature, particularly when used together with the multisig and permissioned acocunts features, allows for a variety of on-chain funds and fund like structures as well as DAO operations to be performed in a completely non-custodial way.

- A fund account has a list of supported collateral assets, or ALL.
  For each supported asset a cap or maximum total deposits (not maximum total value) can be set.
	There can be no cap (any amount of the asset may be added), or the cap can be zero (no more of the asset can be added regardless of how much is currently there or even if funds are removed).

- A fund account has a list of account IDs that can add collateral, or ALL for an unrestricted fund account.

- An account can only add funds if they are on the list or the acount is unresticted.

- An account can only remove funds if they are on the list or the acount is unresticted or they have a non-zero share of the account's existing balance of any asset.

- When an account ID adds collateral its share of the total value of the fund account in that asset is recorded.
  An account ID's share of the fund account for that asset remains constant if the account gains or loses fund through trading, fees, or liquidity provision, etc.

- When collateral is added or removed from the fund account, the shares are adjusted.
  
- New entrants must always have the correct share for the amount added (i.e. added amount as a fraction of the account's total balance of that asset).
	 
- Participants hat remove funds can only remove up to their share multiplied by the total value of the asset.
  Their share is reduced by the fraction of the asset that is removed.





Qs:
- How to implement spam protection? Minimum deposit amount at creation? What about adding another asset (if we decide to allow that)? A fixed fee then (in what currency)? -> min amount + min lockup



- Can "investors" only remove from fund's general account or also force liquidation of existing positions somehow? 
Extra params:
- removing -> give notice, rate of removal (say. x days of notice to remove my share -> up to fund manager to figure it out, if they don't some atomic option (force pro rata liquidation))
    - cash only account? Not invested, not up for grabs for margining system
    - allow sub-accounts? (keep it simple though)
- wrap up the spec so it makes sense for me at least, then we discuss




# Fund accounts

## Network paramters

- `fund.deposit.minQuantumMultiple`: parameter specifying the minimum allowed deposit amount, expressed as the multiple of the `quantum` specified per asset, see [asset framework spec](../protocol/0040-ASSF-asset_framework.md).
- `fund.epoch`: time window used for actions related to the fund account.

## Key characteristics

- Each fund account supports only one asset.
- Fund account gets a unique, non-mutable ID assigned to it at creation time.
- Fund account cannot receive or initiate direct transfers
- Fund account cannot withdraw funds from the bridge.

## Creating a fund account

Any Vega account can create a fund account.

Account creation requires:

- Initial deposit of at least `fund.minInitialDepositQuantumMultiple` times the quantum of the deposited asset.

Optionally:

- a [fund manager](#fund-manager) account ID can be specified at fund account creation time,
- a list of other fund accounts where fund manager can deposit and withdraw funds,
- a list of market IDs where the fund manager is allowed to trade,
- a list of market IDs where the fund manager is allowed to provide liquidity (note that liquidity provision permission implies trading permission even if not explicitly specified).

## Depositing assets into a fund account

## Withdrawing assets from a fund account

## Modifying a fund account

At any point in time the depositors of the fund account can initiate a governance vote to:

- change the fund manager account ID (including setting it to null value)
- provide a new list of other fund accounts where fund manager can deposit and withdraw funds,
- provide a new a list of market IDs where the fund manager is allowed to trade,
- provide a new a list of market IDs where the fund manager is allowed to provide liquidity,
- cancel any open orders and liquidate the entire position that the fund account holds (via a single market order) in a given market (one or more can be specified)
- a list of fund accounts from which the parent fund account's shares should be withdrawn (the behaviour is the same as for a single party withdrawing assets from a fund account they directly deposited into)

## Deleting a fund account

A fund account gets closed automatically once all the funds have been withdrawn from it.

TODO: Do want some sort of failsafe for a fund account that has no open positions and had no deposits/withdrawals for some amount of time? Move funds into per-asset insurance pool in that case?

## Applying fees

## Fund manager

Fund manager is the account ID which has been allowed to utilise the funds deposited within the fund account for trading and/or liquidity provision.
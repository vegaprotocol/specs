# Fund accounts

This feature allows for a variety of on-chain funds and fund like structures as well as DAO operations to be performed in a completely non-custodial way.

## Network paramters

- `fund.deposit.minQuantumMultiple`: parameter specifying the minimum allowed deposit amount, expressed as the multiple of the `quantum` specified per asset, see [asset framework spec](../protocol/0040-ASSF-asset_framework.md).
- `fund.maxIdleTime`: a period of time after which fund gets liquidated and all the funds get returned to the depositors (can only be lengthened for existing fund accounts, reducing it has no effect on those fund accounts).
- `fund.deposit.minWithdrawalNotice`: minimum notice period that can be specified for the withdrawal. Increasing the value of this network parameter changes the `minWithdrawalNotice` on all existing fund accounts to be at least that value.

## Key characteristics

- Each fund account supports only one asset.
- Fund account gets a unique, non-mutable ID assigned to it at creation time.
- Fund account cannot receive or initiate direct transfers.
- Fund account cannot withdraw funds from the bridge.
- Fund account has a special account type called `unallocated` account. It's the account used for deposits and withdrawals (including fund manager compensation) which cannot be accessed by the margining system directly - funds have to be transferred into the `general` account first.
- Each fund account has it's own `epoch` which specifies the rhythm with which certain actions related to the fund are carried out.

## Creating a fund account

Any Vega account can create a fund account. The account creating a fund has no special power over the fund account, all the actions relating to the management of the fund account are carried out via governance votes where the share of the account is used as the voting power.

Account creation requires:

- Initial deposit of at least `fund.minInitialDepositQuantumMultiple` times the quantum of the deposited asset.

Optionally (these can also be change at any point in the funds life via a governance vote where each participant's share of the fund is used as the voting power):

- `minInitialDeposit`: minimum amount of each subsequent deposit, the minmum allowed value is the quantum of the asset used by the fund account.
- `minWithdrawalNotice`: parameter specifying minimum withdrawal notice that a fund accepts, it must be no shorter than `fund.deposit.minWithdrawalNotice`, if no value is specified then the value of the network parameter is used.
- A [fund manager](#fund-manager) account ID.
- A list of other fund accounts where fund manager can deposit and withdraw funds.
- A list of market IDs where the fund manager is allowed to trade.
- A list of market IDs where the fund manager is allowed to provide liquidity (note that liquidity provision permission implies trading permission for that market even if not explicitly specified).
- A list of public keys allowed to make deposits (if a list is `nil` anyone can deposit).
- A maximum total deposit amount (no limit by default).
- `managementFee`: fraction of fund's value at the beginning of each epoch charged in management fees. `0` by default. Must be between [0,1].
- `epoch`: length of time specifying fund's epochs. Certain actions related to the fund account are carried out only at the beginning or an end of an epoch. `24h` by default. The `0`-th epoch starts when fund account is created.
- `profitFee`: fraction of profits charged in management fees. `0` by default. Must be between [0,1].
- `lossPenalty`: fraction of any losses made by the fund, the amounts computed get netted off against `managementFees` and `profitFee` amounts before the payout is made to fund manager at the end of an epoch. `0` by default. Must be between [0,1].

## Modifying a fund account

In addition to action specified in the [creating a fund account](#creating-a-fund-account) section, at any point in time the depositors of the fund account can initiate a governance vote to:

- cancel any open orders and liquidate the entire position that the fund account holds (via a single market order) in a given market (one or more can be specified),
- a list of fund accounts from which the parent fund account's shares should be withdrawn (the behaviour is the same as for a single party withdrawing assets from a fund account they directly deposited into).

TODO: Should we worry about a conflict of interests? Say the fund's depositors wish to change the fund manager and the said manager in retaliation engages in activities that deliberately reduce the fund's value. Should they be able to submit a bundle transaction with votes that enacts instantaneously?

All the actions that pass the vote are enacted immediately.

## Depositing assets into a fund account

Any public key (that's listed as allowed to make deposits if such list is specified) can deposit funds into the fund account. The first deposit from each key must meet the limit: `fund.minInitialDepositQuantumMultiple` times the quantum of the asset that the fund uses. Deposited funds go into the `unallocated` account of the fund - it's the special account type that is not used by the margining system, funds need to be moved to the `general` account by the fund manager before they can be use to place orders or submit liquidity provision transactions.

If fund account has the maximum total deposit limit specified then a deposit is only allowed if it doesn't bring the deposit total over that limit.

## Tracking fund shares

When a party adds collateral its share of the [total value of the fund account](#fund-value) in that asset is recorded.
A party's share of the fund account for that asset remains constant if the account gains or loses funds through trading, fees, or liquidity provision, etc.
New entrants must always have the correct share for the amount added (i.e. added amount as a fraction of the account's total balance of that asset). When collateral is added to or removed from the fund account the shares of all parties are adjusted.

## Fund value

The value of the fund at an point in time is the sum of all it's accounts (including bond and margin) as well as the current value of fund's shares in other fund accounts minus the sum of pending management [fees](#applying-management-fees) net of penalties (floored at 0).

## Withdrawing assets from a fund account

Each party with shares in the fund account can submit a request to remove it's entire share or part of it from the fund account. If the current value of the remaining share would fall below `minInitialDeposit` then the withdrawal request is processes as if the entire share was removed for that party. Their share is reduced by the fraction of the asset that is removed.

Each withdrawal request must have an enactment date specified. Such date must be at least `minWithdrawalNotice` away from the start of the current fund epoch. The withdrawal is finalised at the end of the epoch where epoch end timestamp is larger or equal to the withdrawal request enactment date. Once submitted the withdrawal request cannot be cancelled. The party can only submit the withdrawal requests up to their current fund account share including any pending withdrawal requests.

### Withdrawal enactment

At the end of the fund epoch which falls at or after the withdrawal request's enactment date the withdrawal amount is calculated based on fund's value at that point in time and the share being withdrawn. Funds are searched for in fund's `unallocated` account. If the amount in that account is insufficient the protocol automatically reduces all of funds holdings by a fixed amount (hardcoded `5%`, unless the value of the entire fund is below `minInitialDeposit` - entire fund should be liquidated in that case). Holdings are reduced across all the markets a fund account has positions in, all it's liquidity provisions (may be rejected by market as per regular liquidity provision) and shares in other funds - these are of course delayed by the withdrawal enactment date.
The funds raised are used to fullfill the pending withdrawal requests pro rata. Withdrawals requests are automatically adjusted so that they carry over to the next epoch with withdrawal shares adjusted by the amount withdrawn this period.

Withdrawals reduce the value of total deposits pro rata (if a party reduces their share of the fund by 50% the total deposits figure is reduced by 50% of the initial deposit of that party irrespective of the amount being withdrawn).

## Fund manager

Fund manager is the account ID which has been allowed to utilise the funds deposited within the fund account for trading, liquidity provision or making deposits into other fund accounts as per the fund permissions.

Fund manager can also initiate transfers between fund account's `general` and `unallocated` accounts.

## Applying management fees

At the beginning of each epoch the fund's value gets evaluated and amount equal to `managementFee` times that value gets recorded as the pending compensation.

Every time a profit is realised (can come from trading, liquidity provision or withdrawing from another fund account which increased in value (net of fees) since the deposit) a `profitFee` fraction of that profit gets recorded as pending compensation.

Every time a loss is realised a `lossPenalty` fraction of that loss gets recorded as the pending penalty.

At the end of each epoch the pending compensation amounts are netted off against the pending penalty amounts and the remaining positive part gets transferred from funds `unallocated` account into the general `account` of fund managers public key. If the amount in `unallocated` account is less than that figure then the entire amount of the `unallocated` account gets transferred. The transfer happens after all the pending withdrawal requests have been fulfilled. If withdrawal requests cannot be completed without automatically reducing fund's holding then any compensation (and penalty) amounts due to the fund manager get forgone. The compensation (and penalty) amounts never get carried over into the next epoch. It is therefore in fund managers best interest to assure that there's always enough funds in the `unallocated` account to meet all the withdrawal requests and the compensation (net of penalties) due to them.

## Deleting a fund account

A fund account gets closed automatically once all the funds have been withdrawn from it.

If the fund account exhibits no activity (no deposits/withdrawals) for at least `fund.maxIdleTime` then all it's positions should be liquidated and the all the funds should be returned to the depositors. This is to prevent the protocol having to indefinitely maintain fund accounts which have been abandoned.

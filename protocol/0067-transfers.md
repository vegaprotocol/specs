# Transfers

This spec introduces a mechanism to transfer funds from one account to another, initiated explicitly by a user of the Vega network.
These transfers are not to be confused with the internal concept of transfers which results from event happening inside the protocol, which are covered in spec [0005-COLL](./0005-COLL-collateral.md).

Allowing users to initiate transfers allows for the following capabilities:
- A user could transfer funds from a public key A to a public key B.
- A user could transfer funds to a reward pool
- A user could transfer funds from and to a locked account used for staking.
- etc..

## Limits
Transfer can only be initiated by a party using their own funds from [accounts](./0013-accounts.md) that they are in control of:

Here's the list of accounts types from which a user send funds from:
- [GENERAL](./0013-accounts.md)
- [LOCKED_FOR_STAKING](./0059-simple-staking-and-delegating.md)

Here's the list of accounts types into which funds can be sent:
- [GENERAL](./0013-accounts.md)
- [LOCKED_FOR_STAKING](./0059-simple-staking-and-delegating.md)
- [REWARD_POOL](./0056-rewards-overview.md)
- [ON_CHAIN_TREASURY](./0055-on-chain-treasury.md)

## Delayed transfer
The system should be able to delay transfer. Such feature would be useful in the context of distributing token related to incentives for example.
In order to do this the request for transfer should contain a field indicating when the destination account should be credited. The funds should be taken straight away from the origin account, but distributed to the destination only once the time is reached.

## Spam protection
In order to prevent the abuse of user-initiated transfers as spam attack, the system will be configurabled with a [network parameter](#network-parameters) that will limit the number of transfers that a user can initiate within a set period of time.

## Recurring transfers
A party can also setup recurring transfers which will happen every epochs. These transfers will happen at the end of the epoch, and before the next one can happen.
A party is limited to a maximum of 1 transfer to another count per epoch (e.g: we have parties A, B, C. A is allowed to one recurring transfer to B AND to C per epochs).

A recurring transfers needs to contain these specific informations:
- start epoch (the epoch at which the network will start transfering funds from the source account)
- end epoch (the last epoch at which the network will transfer funds from the source account), optional, if not specified the transfer run until cancelled.
- factor (a factor used with the amount specified for the transfer).

It's possible to cancel an transfer.
It's not possible to amend a transfer, a party will need to cancel the transfer and submit a new one in this case.

The amount paid at each epoch is calculated using the following fomula:
- amount = start amount * factor ^ (current epoch - start epoch)

If not enough funds are present in the source account at the time a transfer is initied by the network, the whole recurring transfer is cancelled.

## Fees
A fee is taken from all transfers, and paid out to validators in a similar manner to the existing [infrastructure fees](./0059-simple-POS-rewards.md).

The fee is set by a [network parameter](#network-parameter) that defines the proportion of each transfer taken as a fee. The fee is taken from the transfer initiator's account immediately on execution, and is taken on top of the total amount transferred. It is [paid in to the infrastructure fee pool](./0029-fees.md#collecting-and-distributing-fees). Fees are charged in the asset that is being transferred.

## Proposed command
This new functionality requires the introduction of a new command in the transaction API. The payload is as follows:
```
message Transfer {
  // The account type from which the funds of the party
  // should be taken
  vega.AccountType from_account_type = 1;
  // The public key of the destination account
  string to = 2;
  // The type of the destination account
  vega.AccountType to_account_type = 3;
  // The asset
  string asset = 4;
  // The amount to be taken from the source account
  string amount = 5;
  // The reference to be attached to the transfer
  string reference = 6;

  // Specific details of the transfer
  oneof kind {
    OneOffTransfer one_off = 101;
    RecurringTransfer recurring = 102;
  }
}

// Specific details for a one off transfer
message OneOffTransfer {
  // A unix timestamp in second. Time at which the
  // transfer should be delivered in the to account
  int64 deliver_on = 1;
}

// Specific details for a recurring transfer
message RecurringTransfer {
  // The first epoch from which this transfer shall be paid
  uint64 start_epoch = 1;
  // The last epoch at which this transfer shall be paid
  vega.Uint64Value end_epoch = 2;
  // factor needs to be > 0
  string factor = 3;
}

message CancelTransfer {
  // The ID of the transfer to cancel
  string transfer_id = 1;
}
```

## Network Parameters
| Property         | Type   | Example value | Description |
|------------------|--------| ------------|--------------|
| `spam.protection.maxUserTransfersPerMinute`       | String (integer) |  `"1"`        | The most transfers a use can initiate per minute |
| `transfer.fee`       | String (float) |  `"0.0001"`        | The percentage of the transfer charged as a fee |


## Acceptance criteria
### One off transfers
- [ ] As a user I can transfer funds from a general account to an other general account
  - [ ] I can do a delayed transfer in the same conditions
- [ ] As a user I can transfer funds from a general account to reward account
  - [ ] I can do a delayed transfer in the same conditions
- [ ] As a user I can transfer funds from a general account to an locked_for_staking
  - [ ] I can do a delayed transfer in the same conditions
- [ ] As a user I can transfer funds from a locked_from_staking account to a general_account
  - [ ] I can do a delayed transfer in the same conditions
- [ ] As a user I cannot transfer funds from accounts that I do not own
- [ ] As a user I cannot transfer funds from accounts I own but from the type is not supported
- [ ] As a user I can do a transfer from a correct account, and fees are taken from my account to execute the transfer
  - [ ] The fee cost is correctly calculated using the network parameter
  - [ ] If I have enough funds to pay transfer and fees, the transfer happen
  - [ ] If I do not have enough funds to pay transfer and fees, the transfer is stopped.
  - [ ] The fees are being paid into the infrastructure pool
- [ ] As a user, when I initiate a delayed transfer, the funds are taken from my account immediately
  - [ ] The funds arrive in the target account when the transaction is processed, which is not before the timestamp occurs
  - [ ] A delayed transfer that is invalid (to an invalid account type) is rejected when it is received, and the funds are not taken from the origin account.
- [ ] The spam protection mechanics prevent me to do more than X transfers per epoch.
- [ ] As a user, I cannot transfer from my margin accounts
- [ ] As a user, I cannot transfer from my staking accounts

### Recurring transfers
- [ ] As a user I can create a recurring transfer _which expires after a specified epoch_ 
  - [ ] I specify a start and end epoch, and a factor of `1`
  - [ ] Until the epoch is reached not transfers are executed
  - [ ] Once I reach the start epoch transfers happens.
  - [ ] The same amount is transfered every epoch
  - [ ] After I reach the epoch after the `end epoch`, no transfers are executed anymore
- [ ] As a user I can create a recurring transfer _that decreases over time_
  - [ ] I specify a start and end epoch, and a factor of `0.7`
  - [ ] Until the epoch is reached not transfers are executed
  - [ ] Once I reach the start epoch transfers happens.
  - [ ] The amount transfered every epoch decreases
  - [ ] After I reach the epoch `?`, no transfers are executed anymore
- [ ] As a user I can create a recurring transfer that recurs forever, with the same balance transferred each time
  - [ ] I specify a start and no end epoch, and a factor of `1`
  - [ ] Until the epoch is reached not transfers are executed
  - [ ] Once I reach the start epoch transfers happens.
  - [ ] The amount transfered every epoch is the same
  - [ ] The transfers happen forever
- [ ] As a user I can cancel a recurring transfer
  - [ ] I specify a start and no end epoch, and a factor of 1
  - [ ] Once I reach the start epoch transfers happens.
  - [ ] I cancel the recurring transfer after the start epoch, before the end epoch
  - [ ] No transfer are executed anymore
- [ ] As a user I can cancel a recurring transfer before any transfers have executed
  - [ ] I specify a start and no end epoch, and a factor of 1
  - [ ] I cancel the transfer after the start epoch, before the end epoch
  - [ ] No transfer are executed at all
- [ ] A user's recurring transfer is cancelled if any transfer fails due to insufficient funds
  - [ ] I specify a start and no end epoch, and a factor of 1
  - [ ] Until the epoch is reached not transfers are executed
  - [ ] Once I reach the start epoch transfers happens.
  - [ ] The account runs out of funds
  - [ ] The transfer is cancelled
  - [ ] No more transfers are executed.

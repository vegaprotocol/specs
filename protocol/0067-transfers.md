# Transfers

This spec introduces a mechanism to transfer funds from one account to another, initiated explicitly by a user of the Vega network.
These transfers are not to be confused with the internal concept of transfers which results from event happening inside the protocol.

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

## Delayed transfer
The system should be able to delay transfer. Such feature would be useful in the context of distributing token related to incentives for example.
In order to do this the request for transfer should contain a field indicating when the destination account should be credited. The funds should be taken straight away from the origin account, but distributed to the destination only once the time is reached.

## Spam protection
In order to prevent the abuse of user-initiated transfers as spam attack, the system will be configurabled with a [network parameter](#network-parameters) that will limit the number of transfers that a user can initiate within a set period of time.

## Fees
A fee is taken from all transfers, and paid out to validators in a similar manner to the existing [infrastructure fees](./0059-simple-POS-rewards.md).

The fee is set by a [network parameter](#network-parameter) that defines the proportion of each transfer taken as a fee. The fee is taken from the transfer initiator's account immediately on execution, and is taken on top of the total amount transferred. It is [paid in to the infrastructure fee pool](./0029-fees.md#collecting-and-distributing-fees). Fees are charged in the asset that is being transferred.

## Proposed command
This new functionality requires the introduction of a new command in the transaction API. The payload is as follows:
```
message TransferFunds {
  // Support GENERAL and LOCKED_FOR_STAKING at first
  vega.AccountType from_account_type = 1;
  // pubkey of the destination
  string to = 2;
  // shall support GENERAL, REWARD, LOCKED_FOR_STAKING types at first.
  vega.AccountType to_account_type = 3;
  // the asset to be transfered, must exists in the network
  string asset = 4;
  // the amount to be transfered, must be > 0
  string amount = 5;
  // a unix timestamp, anything < time.now means pay now.
  int64 deliver_on = 6;
  // an arbitrary reference, 100 chars max
  string reference = 7;
}
```

## Network Parameters
| Property         | Type   | Example value | Description |
|------------------|--------| ------------|--------------|
| `spam.protection.maxUserTransfersPerMinute`       | String (integer) |  `"1"`        | The most transfers a use can initiate per minute | 
| `transfer.fee`       | String (float) |  `"0.0001"`        | The percentage of the transfer charged as a fee | 


## Acceptance criteria
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

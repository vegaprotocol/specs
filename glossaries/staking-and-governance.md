## Staking
A general term to describe the overall process of [Association](#associate) and [Nomination](#nominate)

## Associate
This allows a user with Vega Tokens on Ethereum to associate their tokens with a vega key so that the Vega key can participate in [Governance](#Governance) and [Nominate](#Nominate) their Stake to a [validator](distributed-ledger-glossary.md#validators).
Note: this was previously known as "Staking" also as "Bonding".

## Dissociate
To opposite of association. Tokens can be un-staked via Ethereum which does not know when an [Epoch](#Epoch) ends meaning the associated Vega key will not be due any rewards from that epoch. Users could instead [De-nominate](#De-nominate) their stake using their Vega key and when the Epoch ends they can dissociate without loosing any due rewards.
Tokens are returned either the Staking bridge or the Vesting contract, depending on how they were [Associated](#associate).

## Governance
Using Vega tokens that are [associated](#associate) with a Vega key to propose changes to the network or vote for or against proposed changes.

## Nominate
The act of securing the Vega Network by staking a Vega validator node. This is done via a Vega key with [associated](#associate) Vega tokens. Users who have nominated a node with their stake will receive a proportional share of the infrastructure fees collected by that validator. 

## De-nominate
The act of removing your staked Vega tokens from a given node at the end of an Epoch using a Vega key.

## Re-nominate
The act of removing your stake of Vega tokens from a given node at the end of an Epoch and nominating another for the next, using a Vega key.

## Epoch
A window of time, In which tokens that are staked on a are due a reward. If tokens are dissociated before an epoch they loose any reward that is due.

## Self Staking 
That act of putting Vega tokens on a Validator node that you are running, as apposed to having tokens staked on a node via [Nomination](#Nominate).
 
## Redeem
Releasing tokens that have vested and can be redeemed (sent to a Vega key and then fully transferred).

## Claim
Where a user has been given a URL/code they can use to claim tokens they have been gifted (e.g. for participating in an incentivised activity). Tokens will need to be [redeemed](#redeem) after claiming as they will be in a Vesting tranche.
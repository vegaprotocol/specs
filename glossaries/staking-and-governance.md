# Staking and governance glossary

## Staking

This is a general term that may have specific meaning in different contexts. Vega is a delegated proof of stake blockchain where parties [Delegate](#delegation) Vega tokens on the Vega chain to validators of their choice. Staking and delegation are sometimes used interchangeably.

## Delegation

This is the process of assigning Vega tokens to validators on Vega chain. It is a two step process consisting of:

1. [Association](#associate) which happens on the Ethereum blockchain by interaction with the Staking and Delegation bridges.
1. [Nomination](#nominate) which happens on the Vega blockchain, assigning voting power to validators.

## Associate

This allows a user with Vega Tokens on Ethereum to associate their tokens with a vega key so that the Vega key can participate in [Governance](#governance) and [Nominate](#nominate) their Stake to a [validator](distributed-ledger-glossary.md#validators).
This is done by interaction with the Staking and Delegation bridge contracts (the vesting contract implements this functionality for Vega held by the vesting contract).

## Dissociate

To opposite of association. Tokens can be dissociated via Ethereum staking and delegation bridge.
Vega tokens are thus no longer associated to a Vega key (on either the Staking bridge or the Vesting contract, depending on how they were [Associated](#associate)). This means that in the future they can be associated to a different (or same) Vega key.
This action happens on Ethereum. The staking and delegation smart contract and does not know when an [Epoch](#epoch) ends meaning the relevant Vega key will not be due any rewards from that epoch.
Users are recommended to first [De-nominate](#de-nominate) sufficient amount using their Vega key and interacting with the Vega chain. This way, when the Epoch ends they can dissociate without loosing any due rewards. Moreover they get to choose which validator they are removing their nomination from.

## Governance

Using Vega tokens that are [associated](#associate) with a Vega key to propose changes to the network or vote for or against proposed changes.

## Nominate

The act of securing the Vega Network by placing trust in a specific Vega validator node. This is done via a Vega key using previously [associated](#associate) Vega tokens. Users who have nominated a node with their stake will receive a proportional share of the infrastructure fees collected by that validator and other relevant rewards due from the on-chain-treasury.

## De-nominate

The act of removing your staked Vega tokens from a given node. The de-nominate transaction can be submitted at any time to the Vega chain but is enacted at the end of an Epoch. Thus rewards due for the epoch still accrue to the appropriate Vega key.

## Re-nominate

The act of removing your stake of Vega tokens from a given node at the end of an Epoch and nominating another for the next, using a Vega key. The re-nominate transaction can be submitted at any time to the Vega chain but is enacted at the end of an Epoch. Thus rewards due for the epoch still accrue to the appropriate Vega key.

## Epoch

A window of time, In which tokens that are staked on a are due a reward. If tokens are dissociated before an epoch they loose any reward that is due.

## Self Staking

That act of putting Vega tokens on a Validator node that you are running, as apposed to having tokens staked on a node via [Nomination](#nominate).

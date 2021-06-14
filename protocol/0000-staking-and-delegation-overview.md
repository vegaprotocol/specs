# Staking and Delegation Overview
Vega runs on a delegated proof of stake (DPOS) blockchain. Participants who hold a balance of the governance asset can stake these on the network by delegating their tokens to a validator that they trust. This helps to secure the network. 

Validators and delegators receive incentives from the network, depending on various factors, including how much stake is delegated. Validators who are dishonest are punished by having these rewards slashed.

## Overview 
Staking requires token holders to first "lock" tokens on the [Vega staking bridge contract](../non-protocol-specs/0004-staking-bridge.md) and then "delegate" these tokens to a single validator. 

More information on delegation can be found [here](./0000-delegation-detail.md)

Question - is this a two step process for the participant?

## Staking for the first time
- To lock tokens, a participant must:
  - Have some balance of vested or unvested governance asset in an Ethereum wallet. These assets must not be locked to another smart contract (including the [Vega collateral bridge]()).
  - Have a Vega wallet
  - Lock the tokens on the [Vega staking bridge contract](../non-protocol-specs/0004-staking-bridge.md)
- To delegate the locked tokens, a participant must:
  - Have enough tokens to satisfy the network parameter: "Minimum delegateable stake" 
  - Delegate the locked tokens to one of the eligible validators.
- These accounts will be created:
  - After locking - a staking account denominated in the governance token asset
  - After delegating - a general account for each settlement currency (so they can receive infrastructure fee rewards)
- Timings
  - Any locked (but undelegated) tokens can be delegated at any time. 
  - The delegation only becomes valid at the next [episode](./0050-epochs.md), though it can be undone through undelegate.
  - The balance of "delegateable stake" is reduced immediately (prior to it coming into effect in the next episode) 

## Adding more stake
- More tokens may be locked at any time on the [Vega staking bridge contract](../non-protocol-specs/0004-staking-bridge.md)
- More stake may be delegated at any time (see [function: Stake](../non-protocol-specs/0004-staking-bridge.md) - amount refers to size by which to increment existing staked amount)
- Same timings apply as per staking for the first time

## Removing stake
- Locked but undelegated stake may be withdrawn from the [Vega staking bridge contract](../non-protocol-specs/0004-staking-bridge.md) at any time
- Delegation may be fully or partially removed. The amount specified in the [function: Remove](../non-protocol-specs/0004-staking-bridge.md) - is the size by which the existing staked amount will be decremented
- Removal of delegation may happen in the following 2 ways:
  - Announcing removal, but maintaining stake until last block of the current episode. This "announced stake" may be then (re)delegated (e.g. to a different validator).
  - Announcing removal and withdrawing stake immediately. Rewards are still collected for this stake until the end fo the episode, but they are sent to the onchain treasury account for that asset.  

### Changing delegation
- Changing the validator to whom a participant wants to validate to involves:
  - Announcing removal of stake for current validator
  - Staking on the new validator, as per normal [function: Stake](../non-protocol-specs/0004-staking-bridge.md)
  - These can happen concurrently, so that at the next epoch, the stake is removed from the current validator and staked on the new validator 

## Payment of rewards
- [Infrastructure fees](./0029-fees.md) are collected into an infrastructure fee account for the asset
- These fees are distributed to the general accounts of the validators and delegators in amounts calculated according to the [staking and delegation rewards]() scheme.

## Use of tokens for governance
- Locked and staked token may be used as voting weight for governance proposals

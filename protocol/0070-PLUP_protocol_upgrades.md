Feature name: protocol-upgrades
Start date: 2022-02-09

## Summary

### Current state of upgrading the vega network

As of today, upgrading the protocol is near impossible when a major changes to the step are possible without proceeding with a [Limited Network Life checkpoint restore](./non-protocol-specs/0005-NP-LIMN-limited_network_life.md). This functionality has the following significant issues:
- A synchronous restart is required
- All node need to be restarted in a very short time so all state can be restore from ethereum, and the network can start properly with a checkpoint.

Limited Network Life is not the end goal. This spec outlines how the protocol evolves from LNL checkpoints to rolling software updates, controlled by a reasonable set of governance and user controls.

### How other protocols proceed

Other protocol e.g Ethereum carry out updates in an asynchronous manner. Usually a new version of the protocol is made available, a hardcoded block height is set
at which a new code path will be enabled. If enough node runners have deployed the updated code, then the network will continue with the new code path. Others nodes
which haven't updated will then fork the blockchain.

### Prior example of updgrading the nodes asynchronously

Back in December 2020, vega proceeded to a LNL restore. Unfortunately, a bug in the code prevented the dispatch of the network parameters after the restore. This left
the network in a semi invalid state where the network parameters were defined by the ones from the genesis block instead of the one from the checkpoint from the previous network.

The solution employed at the time was to:
- implement a hotfix
- keep the hotfix behind a guard until a given time, once the time is reached network parameters would be dispatched.
- distribute the code to the validator so they can test it.
- then decide of an actual date which would give a week for the validator to asynchronously update their node.

This upgrade went quite smoothly without any incident, although it was possible as the fix was located in a single place, and wasn't impacting much of the state
(meaning no changes in the protobuf files were required for example.)

## Asynchronous upgrades mecanism

One of the main challenge with upgrading the network both asynchronously and without a restart / downtime is
the management of the state, and possible incompatible changes between the state of two version of the protocol.

In order to prevent any state incompatibility, this specification introduces a new framework to propose upgrades of the protocol, which will allow the node to be stopped,
and restart from the block it stopped at using the snapshots or by replaying the whole chain. When being restarted
the new node will contain both the previous version of the protocol in use, but also a new version that the
network should start using at a given block. Upon restart, the node will try to send a transaction to
indicate the rest of the network that it's ready to switch to the new version of the protocol. When the block
defined for the upgrade is reached and if enough nodes have send the transaction notifying of their intent of
migrating to the new version of the protocol, then the upgrade is applied. If not enough transaction have been
sent by the validators, the protocol will keep running the current version.


The existing network parameter `"validators.vote.required"` is used to defined the amount of require validators
to proceed with the update.


The upgrade **must** be done in an atomic way. To do so, the core node will need to have been compiled with
the current and next version of the protocol. Once the block height for the upgrade is reached the currently
running version of the protocol will stop executing any transaction (e.g: at the ABCI Commit call), then the
whole state will be serialised, all of the engines will shut down, and the new version of the protocol will be
instantiated, and will have to load the state previously serialised by the old version. The new version of
the protocol will be then to convert the previous state in order to make it compatible with
any changes in the protocol.

The main difficulty here will be the implementation of the serialisation of the whole state of the node.
Fortunately we already have such feature which should work out of the box with minimal changes: [snapshots](../non-protocol-specs/0009-NP-SNAP-snapshots.md).


## Versioning of the protocol

From now on we will need to version the protocol, this can be the current version of the node, and the previous
version. This should probably use a versioning system like semantic versioning (this will be useful in a later
part of this document).


## Types of upgrade

Not all upgrades of the protocol may have the same impact to different kind of actors, or even the same urgency.
e.g: a patch for a critical issue, or major changes in the protocol, or simple patch.

Each of those may require the attention of different actors in the network, and different process to be accepted.

For the rest of this assume that upgrade are using a semantic version, where for a given M.m.P version which changes either of:
- M is a major upgrade
- m is a minor upgrade
- P is a patch upgrade.

Each of those upgrade will go through a different process.

### Patch upgrade

This upgrade should represent very small change in the protocol, for example a bug fix or a quality-of-life improvement.
These upgrade require no involvement from any actors of the network apart from the validators updating their nodes
with a new supported version of the protocol.


### Minor upgrade

These are upgrade which bring more features to the protocol, or larger fixes, and changes in the state
produced by the protocol. They may require more work from the validators and will not be applied automatically.
A new command will be introduce in the vega toolchain so validator can explicitly notify the network of their
support into upgrading to the new version.

### Major upgrade

These are important changes in the protocol, possibly breaking the previously known behaviours of the protocol
but also implementing new important features. Due to the nature of the upgrade, a governance vote will be required
so token holders show of their support for the upgrade.

> note: the definition of a major upgrade will need refinement, and the current version of the specification does not cover it.

## Framework / data structures

As protobuf:
```
message Upgrade {
	enum Type {
		Patch = 1;
		Minor = 2;
		Major = 3;
	}
	string new_version = 1; // the new version proposed for the upgrade. in semver
	uint64 block_height = 2; // the block at which the upgrade will be executed.
	string description = 3; // a description for this upgrade
}

// a message sent by the node to notify that a node is ready to do an upgrade
message UpgradeAccepted {
	string version = 1;
}
```

## Acceptance criteria
- [ ] A new patch upgrade is made available
  - [ ] Enough validators have upgraded their node
  - [ ] At least `validators.vote.required` message have been sent by the validators
  - [ ] The block time for the upgrade is reached
  - [ ] The network is switching to the new version of the protocol (can be checked with APIs)
- [ ] A new patch upgrade is made available
  - [ ] Not enough validator have upgraded their node
  - [ ] At least `validators.vote.required` message have been sent by the validators nodes
  - [ ] The block time for the upgrade is reached
  - [ ] The network haven't change version (can be checked with APIs)
- [ ] A new minor upgrade is made available
  - [ ] Enough validator have upgraded their node
  - [ ] At least `validators.vote.required` validators sent a command to accept the upgrade
  - [ ] The block time for the upgrade is reached
  - [ ] The network is switching to the new version of the protocol (can be checked with APIs)
- [ ] A new minor upgrade is made available
  - [ ] Enough validator have upgraded their node
  - [ ] Less then `validators.vote.required` validators sent a command to accept the upgrade
  - [ ] The block time for the upgrade is reached
  - [ ] The network haven't change the protocol version (can be checked with APIs)
- [ ] A new minor upgrade is made available
  - [ ] Enough validator have upgraded their node
  - [ ] A governance proposal have been created to propose the upgrade
  - [ ] The proposal have been accepted
  - [ ] The block time for the upgrade is reached
  - [ ] The network is switching to the new version of the protocol (can be checked with APIs)
- [ ] A new minor upgrade is made available
  - [ ] Enough validator have upgraded their node
  - [ ] A governance proposal have been created to propose the upgrade
  - [ ] The proposal have been rejected
  - [ ] The block time for the upgrade is reached
  - [ ] The network haven't changed the protocol version (can be checked with APIs)

# Protocol upgrades

## Summary

### Current state of upgrading the vega network

As of today, upgrading the protocol is near impossible when a major changes to the step are possible without proceeding with a [Limited Network Life checkpoint restore](./0073-LIMN-limited_network_life.md). This functionality has the following significant issues:

- A synchronous restart is required
- All node need to be restarted in a very short time so all state can be restore from Ethereum, and the network can start properly with a checkpoint.

Limited Network Life is not the end goal. This spec outlines how the protocol evolves from LNL checkpoints to rolling software updates, controlled by a reasonable set of governance and user controls.

### How other protocols proceed

Other protocol e.g Ethereum carry out updates in an asynchronous manner. Usually a new version of the protocol is made available, a hardcoded block height is set
at which a new code path will be enabled. If enough node runners have deployed the updated code, then the network will continue with the new code path. Others nodes
which haven't updated will then fork the blockchain.

Cosmos is using a small program called cosmovisor. The cosmovisor is listening to proposals and when a proposal for upgrade is accepted, it is preparing the binary for a new release and handling the upgrade - [see cosmovisor docs](https://docs.cosmos.network/main/tooling/cosmovisor).

The idea in this spec is to draw inspiration from the design of cosmovisor and build vega-visor to manage protocol upgrades.

### Prior example of upgrading the nodes asynchronously

Back in December 2021, vega proceeded to a LNL restore. Unfortunately, a bug in the code prevented the dispatch of the network parameters after the restore. This left
the network in a semi invalid state where the network parameters were defined by the ones from the genesis block instead of the one from the checkpoint from the previous network.

The solution employed at the time was to:

- implement a patch fix
- keep the patch fix behind a guard until a given time, once the time is reached network parameters would be dispatched.
- distribute the code to the validator so they can test it.
- then decide of an actual date which would give a week for the validator to asynchronously update their node.

This upgrade went quite smoothly without any incident, although it was possible as the fix was located in a single place, and wasn't impacting much of the state
(meaning no changes in the protobuf files were required for example.)

## Protocol upgrades mechanism

One of the main challenge with upgrading the network both asynchronously and without a restart / downtime is
the management of the state, and possible incompatible changes between the state of two version of the protocol.

The following describes the general workflow of upgrades:

1. Vega continuously make new releases available
2. Validators can suggest to the network an upgrade with a given release tag and a block height for the upgrade to take place
3. If a proposal gets enough votes (`validators.vote.required` of the validators, not stake) at the given height vega will take a snapshot automatically and stop processing further blocks until restarted by the vega-visor, the vega process manager.
4. The validators manually download and build/prepare the new binaries.
5. When restarted, vega will load from the last snapshot and start processing blocks with the new version.
6. If a majority isn't reached and the block height of the proposal has passed, the proposal is rejected.
7. Proposals result in event emitted from the core indicating the proposed upgrade tag, proposed block height for the upgrade, and the validators supporting it.
8. Only tendermint validators can propose an upgrade (i.e. ersatz cannot)
9. The process manager is polling vega to ask whether an upgrade is expected, when an upgrade is expected it's asking if vega is ready to be stopped.
10. Vega will be ready to be stopped only once its completed taking the snapshot and the state from the upgrade block has been committed
11. When vega core returns it is ready to restart (via the admin RPC) - the vega-visor will stop vega and restart it from the last snapshot taken.
12. The network resumes with the new software version.
13. Active proposals should be trackable via data-node
14. The process manager can manage both validator and non validator nodes and data nodes. However, only tendermint validators can propose an upgrade.

NB: by the time of the block height of the upgrade the validators must have downloaded and built the binaries and prepared them in the right location as required by the vega-visor.

## Framework / data structures

As protobuf:

```go
message ProtocolUpgradeProposal {
   // The block height at which to perform the upgrade
   uint64 upgrade_block_height = 1;
   // the release tag for the vega binary
   string vega_release_tag = 2;
   // the release tag for the data-node binary
   string data_node_release_tag = 3;
}

enum ProtocolUpgradeProposalStatus {
  PROTOCOL_UPGRADE_PROPOSAL_STATUS_UNSPECIFIED = 0;
  // The proposal is pending
  PROTOCOL_UPGRADE_PROPOSAL_STATUS_PENDING = 1;
  // The proposal is approved
  PROTOCOL_UPGRADE_PROPOSAL_STATUS_APPROVED = 2;
  // The proposal is rejected
  PROTOCOL_UPGRADE_PROPOSAL_STATUS_REJECTED = 3;
}

message ProtocolUpgradeEvent {
   // The block height at which to perform the upgrade
   uint64 upgrade_block_height = 1;
   // the release tag for the vega binary
   string vega_release_tag = 2;
   // the release tag for the data-node binary
   string data_node_release_tag = 3;
   // tendermint validators that have agreed to the upgrade
  repeated string approvers = 4;
  // the status of the proposal
  ProtocolUpgradeProposalStatus status = 5;
}

```

## Acceptance criteria

### Invalid proposals - Rejections

- A network with 5 validators
- (<a name="0075-PLUP-001" href="#0075-PLUP-001">0075-PLUP-001</a>)(<a name="0075-SP-PLUP-001" href="#0075-SP-PLUP-001">0075-SP-PLUP-001</a>) Validator proposes a protocol upgrade to an invalid [tag](https://semver.org/) - should result in an error
- (<a name="0075-PLUP-002" href="#0075-PLUP-002">0075-PLUP-002</a>)(<a name="0075-SP-PLUP-002" href="#0075-SP-PLUP-002">0075-SP-PLUP-002</a>) Validator proposes a protocol upgrade on a block height preceding the current block - should result in an error
- (<a name="0075-PLUP-003" href="#0075-PLUP-003">0075-PLUP-003</a>)(<a name="0075-SP-PLUP-003" href="#0075-SP-PLUP-003">0075-SP-PLUP-003</a>) Propose and enact a version downgrade
- (<a name="0075-PLUP-004" href="#0075-PLUP-004">0075-PLUP-004</a>)(<a name="0075-SP-PLUP-004" href="#0075-SP-PLUP-004">0075-SP-PLUP-004</a>) Non-validator attempts to propose upgrade
- (<a name="0075-PLUP-005" href="#0075-PLUP-005">0075-PLUP-005</a>)(<a name="0075-SP-PLUP-005" href="#0075-SP-PLUP-005">0075-SP-PLUP-005</a>) Ersatz validator (standby validator) attempts to propose upgrade

### Block height validation

Proposal will not be accepted as valid if validator:

- (<a name="0075-PLUP-006" href="#0075-PLUP-006">0075-PLUP-006</a>)(<a name="0075-SP-PLUP-006" href="#0075-SP-PLUP-006">0075-SP-PLUP-006</a>) Proposes a negative upgrade block
- (<a name="0075-PLUP-007" href="#0075-PLUP-007">0075-PLUP-007</a>)(<a name="0075-SP-PLUP-007" href="#0075-SP-PLUP-007">0075-SP-PLUP-007</a>) Proposes a 0 upgrade block
- (<a name="0075-PLUP-008" href="#0075-PLUP-008">0075-PLUP-008</a>)(<a name="0075-SP-PLUP-008" href="#0075-SP-PLUP-008">0075-SP-PLUP-008</a>) Proposes (string/other upgrade block)
- (<a name="0075-PLUP-009" href="#0075-PLUP-009">0075-PLUP-009</a>)(<a name="0075-SP-PLUP-009" href="#0075-SP-PLUP-009">0075-SP-PLUP-009</a>) Proposes without supplying a block height

### VISOR

- (<a name="0075-PLUP-010" href="#0075-PLUP-010">0075-PLUP-010</a>)(<a name="0075-SP-PLUP-010" href="#0075-SP-PLUP-010">0075-SP-PLUP-010</a>) Can be seen to automatically download the tagged version proposed for install when available at the source location when file meets the format criteria defined
- (<a name="0075-PLUP-011" href="#0075-PLUP-011">0075-PLUP-011</a>)(<a name="0075-SP-PLUP-011" href="#0075-SP-PLUP-011">0075-SP-PLUP-011</a>) Visor automatically upgrades validators to proposed version if required majority has been reached

### Epochs

- (<a name="(0075-COSMICELEVATOR-012)" href="#(0075-COSMICELEVATOR-012)">(0075-COSMICELEVATOR-012)</a>)(<a name="(0075-SP-COSMICELEVATOR-012)" href="#(0075-SP-COSMICELEVATOR-012)">(0075-SP-COSMICELEVATOR-012)</a>) Proposing an upgrade block which ought to be the end of an epoch. After upgrade takes place, confirm rewards are distributed, any pending delegations take effect, and validator joining/leaving takes effect.
- (<a name="0075-PLUP-013" href="#0075-PLUP-013">0075-PLUP-013</a>)(<a name="0075-SP-PLUP-013" href="#0075-SP-PLUP-013">0075-SP-PLUP-013</a>) Propose an upgrade block which should result in a network running new code version in the same epoch.
- (<a name="0075-PLUP-014" href="#0075-PLUP-014">0075-PLUP-014</a>)(<a name="0075-SP-PLUP-014" href="#0075-SP-PLUP-014">0075-SP-PLUP-014</a>) Ensure end of epoch processes still run after restore e.g reward calculation and distributions

### Required Majority

For the purposes of protocol upgrade each validator that participates in consensus has one vote. Required majority is set by `validators.vote.required network parameter`.

- (<a name="0075-PLUP-015" href="#0075-PLUP-015">0075-PLUP-015</a>)(<a name="0075-SP-PLUP-015" href="#0075-SP-PLUP-015">0075-SP-PLUP-015</a>) Counting proposal votes to check if required majority has been reached occurs when any proposed target block has been reached
- (<a name="0075-PLUP-016" href="#0075-PLUP-016">0075-PLUP-016</a>)(<a name="0075-SP-PLUP-016" href="#0075-SP-PLUP-016">0075-SP-PLUP-016</a>) Only proposals from validators participating in consensus are counted when any proposed target block has been reached.
- (<a name="0075-PLUP-017" href="#0075-PLUP-017">0075-PLUP-017</a>)(<a name="0075-SP-PLUP-017" href="#0075-SP-PLUP-017">0075-SP-PLUP-017</a>) Events are emitted for all proposals which fail to reach required majority when target block is reached
- (<a name="0075-PLUP-018" href="#0075-PLUP-018">0075-PLUP-018</a>)(<a name="0075-SP-PLUP-018" href="#0075-SP-PLUP-018">0075-SP-PLUP-018</a>) When majority reached during the process of upgrading, those validators which didn't propose will stop producing blocks
- (<a name="0075-PLUP-019" href="#0075-PLUP-019">0075-PLUP-019</a>)(<a name="0075-SP-PLUP-019" href="#0075-SP-PLUP-019">0075-SP-PLUP-019</a>) Proposals for multiple versions at same block height will be rejected if majority has not been reached, network continues with the current running version
- (<a name="0075-PLUP-020" href="#0075-PLUP-020">0075-PLUP-020</a>)(<a name="0075-SP-PLUP-020" href="#0075-SP-PLUP-020">0075-SP-PLUP-020</a>) Propose with a validator which is moved to Ersatz by the time the upgrade is enacted. If there are 5 validators, 3 vote yes, 2 vote no: One of the yes voters is kicked in favour of a new one, leaving the vote at 2-2 so the upgrade should not happen as counting votes happens at block height only
- (<a name="0075-PLUP-036" href="#0075-PLUP-036">0075-PLUP-036</a>)(<a name="0075-SP-PLUP-036" href="#0075-SP-PLUP-036">0075-SP-PLUP-036</a>) Changing `validators.vote.required` network parameter to a value above two thirds is respected.
- (<a name="0075-PLUP-037" href="#0075-PLUP-037">0075-PLUP-037</a>)(<a name="0075-SP-PLUP-037" href="#0075-SP-PLUP-037">0075-SP-PLUP-037</a>) The value of `validators.vote.required` is checked at upgrade block, i.e: vote on a proposal with all validators, then change the `validators.vote.required` network parameter before upgrade block, to a higher value, which would cause the upgrade to be rejected. Upgrade fails.

### Multiple proposals (<a name="0075-PLUP-021" href="#0075-PLUP-021">0075-PLUP-021</a>)(<a name="0075-SP-PLUP-021" href="#0075-SP-PLUP-021">0075-SP-PLUP-021</a>)

- If multiple proposals are submitted from a validator before the block heights are reached then only the last proposal is considered

## Spam (<a name="0075-COSMICELEVATOR-022" href="#0075-COSMICELEVATOR-022">0075-COSMICELEVATOR-022</a>)(<a name="0075-SP-COSMICELEVATOR-022" href="#0075-SP-COSMICELEVATOR-022">0075-SP-COSMICELEVATOR-022</a>)

- Excessive numbers of proposals from a single validator within an epoch should be detected and rejected - (Future requirement)

## Snapshots

- (<a name="0075-PLUP-023" href="#0075-PLUP-023">0075-PLUP-023</a>)(<a name="0075-SP-PLUP-023" href="#0075-SP-PLUP-023">0075-SP-PLUP-023</a>) Post a validator becoming a consensus-participating validator they should be immediately allowed to propose an upgrade and be included in the overall total count
- (<a name="0075-PLUP-024" href="#0075-PLUP-024">0075-PLUP-024</a>)(<a name="0075-SP-PLUP-024" href="#0075-SP-PLUP-024">0075-SP-PLUP-024</a>) Ensure that required majority is not met when enough validators join between validator proposals and target block, i.e: In a network with 5 validators, required majority is two thirds, 4 vote to upgrade, 2 more validators join before upgrade block and do not vote. Upgrade does not take place.
- (<a name="0075-PLUP-025" href="#0075-PLUP-025">0075-PLUP-025</a>)(<a name="0075-SP-PLUP-025" href="#0075-SP-PLUP-025">0075-SP-PLUP-025</a>) Node starting from snapshot which has a proposal at a given block, ensure during replay when the block height is reached a new version is loaded and also post load an upgrade takes place at target block.
- (<a name="0075-PLUP-045" href="#0075-PLUP-045">0075-PLUP-045</a>)(<a name="0075-SP-PLUP-045" href="#0075-SP-PLUP-045">0075-SP-PLUP-045</a>) Arrange a network where n nodes are required for consensus, and at least n+1 nodes in the network. Schedule a protocol upgrade where n-1 nodes automatically start on the new version after upgrade, i.e: No consensus after upgrade. Start the (n+1)th node and consensus is achieved. For the nth node, clear vega and tm, and restart the node using state-sync at the upgrade block height. All nodes produce blocks.

## LNL Checkpoints

- (<a name="0075-PLUP-026" href="#0075-PLUP-026">0075-PLUP-026</a>)(<a name="0075-SP-PLUP-026" href="#0075-SP-PLUP-026">0075-SP-PLUP-026</a>) Validator proposals should not be stored in the checkpoints and restored into the network
- (<a name="0075-PLUP-027" href="#0075-PLUP-027">0075-PLUP-027</a>)(<a name="0075-SP-PLUP-027" href="#0075-SP-PLUP-027">0075-SP-PLUP-027</a>) Upgrade will not occur after a post checkpoint restore until new proposals are made and block height reached

## API

- (<a name="0075-PLUP-028" href="#0075-PLUP-028">0075-PLUP-028</a>)(<a name="0075-SP-PLUP-028" href="#0075-SP-PLUP-028">0075-SP-PLUP-028</a>) An datanode API should be available to provide information on the upcoming confirmed proposal including total proposals/block details/versions

### Successful upgrade  (<a name="0075-PLUP-029" href="#0075-PLUP-029">0075-PLUP-029</a>)(<a name="0075-SP-PLUP-029" href="#0075-SP-PLUP-029">0075-SP-PLUP-029</a>)

- A new release is made available, and is successfully deployed
- Setup a network with 5 validators running version x
- Have 4 validator submit request to upgrade to release `>x` at block height 1000
- At the end of block height 1000 a snapshot is taken and vega is stopped by the vegavisor
- All nodes are starting from the snapshot of block 1000 and the network resumes with version `>x`

### Failing consensus

- (<a name="0075-PLUP-030" href="#0075-PLUP-030">0075-PLUP-030</a>)(<a name="0075-SP-PLUP-030" href="#0075-SP-PLUP-030">0075-SP-PLUP-030</a>) Upgrade takes place at block N. Restart with a number of validators whose voting power is <= two thirds. Restart one more validator whose voting power would take the total voting power >= two thirds, with an incorrect version. Consensus is not achieved. Now restart that validator with the correct version. Consensus is achieved.
- (<a name="0075-PLUP-031" href="#0075-PLUP-031">0075-PLUP-031</a>)(<a name="0075-SP-PLUP-031" href="#0075-SP-PLUP-031">0075-SP-PLUP-031</a>) 5 validator network. Upgrade takes places at block N. Start 3 validators immediately. Allow several seconds to pass. - no blocks producing as 3 validators do not have enough weight - need 70% weight to produce blocks. Start two remaining validators. (All validators continue to work).
- (<a name="0075-PLUP-032" href="#0075-PLUP-032">0075-PLUP-032</a>)(<a name="0075-SP-PLUP-032" href="#0075-SP-PLUP-032">0075-SP-PLUP-032</a>) Upgrade takes place, but insufficient validators are restored for 1, 5, 10, minutes. Validators which are restored immediately patiently wait for consensus to be achieved, and then blocks continue  - consensus achieved

### Mainnet

- (<a name="0075-COSMICELEVATOR-033" href="#0075-COSMICELEVATOR-033">0075-COSMICELEVATOR-033</a>)(<a name="0075-SP-COSMICELEVATOR-033" href="#0075-SP-COSMICELEVATOR-033">0075-SP-COSMICELEVATOR-033</a>) Check that we can protocol upgrade a system which has been restarted from mainnet snapshots with current mainnet version, to next intended release version. Check all data available pre-upgrade is still available.
- (<a name="0075-PLUP-046" href="#0075-PLUP-046">0075-PLUP-046</a>)(<a name="0075-SP-PLUP-046" href="#0075-SP-PLUP-046">0075-SP-PLUP-046</a>) Check that we can protocol upgrade a system which has been restarted from latest mainnet checkpoint with current mainnet version, to next intended release version. Check all data available pre-upgrade is still available.

### Overwriting transactions

- (<a name="0075-PLUP-034" href="#0075-PLUP-034">0075-PLUP-034</a>)(<a name="0075-SP-PLUP-034" href="#0075-SP-PLUP-034">0075-SP-PLUP-034</a>) A proposal made to upgrade to the currently running version will retract previous proposals. i.e: System is running version V. Make a proposal for block height H and version V + 1 and vote with all validators. Before block height H, submit a new proposal for version V and any future block height, with all validators. Upgrade proposals are retracted, and upgrade does not take place.
- (<a name="0075-PLUP-035" href="#0075-PLUP-035">0075-PLUP-035</a>)(<a name="0075-SP-PLUP-035" href="#0075-SP-PLUP-035">0075-SP-PLUP-035</a>) Rejected proposals do not overwrite previous valid upgrade proposals.

### Data is preserved

- (<a name="0075-PLUP-038" href="#0075-PLUP-038">0075-PLUP-038</a>)(<a name="0075-SP-PLUP-038" href="#0075-SP-PLUP-038">0075-SP-PLUP-038</a>) An open market with active orders which is available prior to upgrade, is still available, active, and can be traded on, post-upgrade.
- (<a name="0075-PLUP-039" href="#0075-PLUP-039">0075-PLUP-039</a>)(<a name="0075-SP-PLUP-039" href="#0075-SP-PLUP-039">0075-SP-PLUP-039</a>) Stake available prior to upgrade is still available post upgrade.
- (<a name="0075-PLUP-040" href="#0075-PLUP-040">0075-PLUP-040</a>)(<a name="0075-SP-PLUP-040" href="#0075-SP-PLUP-040">0075-SP-PLUP-040</a>) Active and pending delegations made prior to upgrade are still active post upgrade.
- (<a name="0075-PLUP-041" href="#0075-PLUP-041">0075-PLUP-041</a>)(<a name="0075-SP-PLUP-041" href="#0075-SP-PLUP-041">0075-SP-PLUP-041</a>) A market due to expire during an upgrade will terminate and/or settle post-upgrade.
- (<a name="0075-PLUP-042" href="#0075-PLUP-042">0075-PLUP-042</a>)(<a name="0075-SP-PLUP-042" href="#0075-SP-PLUP-042">0075-SP-PLUP-042</a>) Trader balances available prior to upgrade is still available post upgrade.
- (<a name="0075-PLUP-043" href="#0075-PLUP-043">0075-PLUP-043</a>) (<a name="0075-PLUP-043" href="#0075-SP-PLUP-043">0075-SP-PLUP-043</a>) Pending and active assets available prior to upgrade is still available post upgrade.
- (<a name="0075-PLUP-044" href="#0075-PLUP-044">0075-PLUP-044</a>)(<a name="0075-SP-PLUP-044" href="#0075-SP-PLUP-044">0075-SP-PLUP-044</a>) Network parameter, market and asset proposals can span a protocol upgrade.

### Ethereum events during outage

- (<a name="0075-PLUP-051" href="#0075-PLUP-051">0075-PLUP-051</a>)(<a name="0075-SP-PLUP-051" href="#0075-SP-PLUP-051">0075-SP-PLUP-051</a>) Deposit events that take place during protocol upgrade are registered by the network once the upgrade is complete.
  1. Schedule an upgrade on a network that is not using visor.
  1. When the nodes stop processing blocks for the upgrade, shut down the nodes.
  1. Deposit tokens via the ERC20 bridge.
  1. Start the network using the upgrade binary.
  1. Balance reported as added in the appropriate account(s).
- (<a name="0075-PLUP-052" href="#0075-PLUP-052">0075-PLUP-052</a>)(<a name="0075-SP-PLUP-052" href="#0075-SP-PLUP-052">0075-SP-PLUP-052</a>) Staking events that take place during protocol upgrade are registered by the network once the upgrade is complete.
  1. Ensure parties A & B have some stake, which is delegated to a/some node(s).
  1. Schedule an upgrade on a network that is not using visor.
  1. When the nodes stop processing blocks for the upgrade, shut down the nodes.
  1. Add stake to party A.
  1. Remove some (not all) stake from party B.
  1. Start the network using the upgrade binary.
  1. Additional stake reported for party A and auto-delegated. Stake removed for party B and delegation reduced.
- (<a name="0075-PLUP-047" href="#0075-PLUP-047">0075-PLUP-047</a>)(<a name="0075-SP-PLUP-047" href="#0075-SP-PLUP-047">0075-SP-PLUP-047</a>) Multisig events that take place during protocol upgrade are registered by the network once the upgrade is complete.
  1. Arrange a network where one validator is promoted to replace another validator. Collect signatures to update the multisig contract, but do not yet update the multisig.
  1. Schedule an upgrade on the network (should not be using visor).
  1. When the nodes stop processing blocks for the upgrade, shut down the nodes.
  1. Update the multisig contract to reflect the correct validators.
  1. Start the network using the upgrade binary.
  1. At the end of the current epoch, rewards are paid out.
- (<a name="0075-PLUP-048" href="#0075-PLUP-048">0075-PLUP-048</a>)(<a name="0075-SP-PLUP-048" href="#0075-SP-PLUP-048">0075-SP-PLUP-048</a>) Multisig events that take place during protocol upgrade are registered by the network once the upgrade is complete.
  1. Arrange a network where one validator is promoted to replace another validator. Collect signatures to update the multisig contract, but do not yet update the multisig.
  1. Schedule an upgrade on the network (should not be using visor).
  1. When the nodes stop processing blocks for the upgrade, shut down the nodes.
  1. Do not update the multisig contract to reflect the correct validators.
  1. Start the network using the upgrade binary.
  1. At the end of the current epoch, rewards are not paid out.
  1. Update the multisig contract to reflect the correct validators.
  1. At the end of the current epoch, rewards are paid out.

### Transactions during upgrade

- (<a name="0075-PLUP-049" href="#0075-PLUP-049">0075-PLUP-049</a>)(<a name="0075-SP-PLUP-049" href="#0075-SP-PLUP-049">0075-SP-PLUP-049</a>) Network handles filled mempool during upgrade.
  1. Schedule a protocol upgrade in a network with no nodes using visor.
  1. When the nodes stop processing blocks for the upgrade, shut down the nodes.
  1. Start one node on the new binary.
  1. Send enough transactions to the node to fill the tendermint mempool. (Expect sane rejection once mempool is full)
  1. Start the other nodes on the correct upgrade binary.
  1. Expect all transactions that reached the mempool without being rejected to be correctly processed over several blocks.
- (<a name="0075-PLUP-050" href="#0075-PLUP-050">0075-PLUP-050</a>)(<a name="0075-SP-PLUP-050" href="#0075-SP-PLUP-050">0075-SP-PLUP-050</a>) Transactions can be made in block immediately before protocol upgrade.
  1. Schedule a protocol upgrade in a network with no nodes using visor.
  1. Continuously send transactions as the upgrade block approaches.
  1. When the nodes stop processing blocks for the upgrade, make a note of all transactions which reached blocks already (transactions which did not are expected to be discarded).
  1. Shut down the nodes.
  1. Start all nodes on the new binary.
  1. Expect all transactions that reached blocks prior to upgrade to have taken effect. None of the other transactions did.

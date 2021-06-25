# Limited network life.

Vega networks will at least initially and perhaps always run for a limited time only. 
This spec covers the necessary features to ensure this works smoothly.

# Relevant network parameters
- `markets_freeze_date` sets the date before which all markets are expected to settle and after which no deposits or trading / governance transactions will be accepted. This can be +infinity or another way of indicating "never". 
- `chain_end_of_life_date` This must be `> markets_freeze_date`. At this time the chain will be shutdown.  
- `time_elapsed_between_checkpoints` sets the minimum time elapsed between checkpoints


# Background

Networks will have a finite lifetime because:

- It is efficient to upgrade the protocol by starting again as it avoids the need to deal with multiple versions of the code (upgrades to a running chain need to respect and be able to recalculate the pre-upgrade deterministic state for earlier blocks, so all versions of criticial code must remain in the system). 
This is especially important early on when rapid iteration is desirable, as the assumption that new chains can be started for new features simplifies things considerably.

- Trading at 1000s of tx/sec generates a lot of data. Given that most instruments are non-perpetual (they expire), this gives the ability to create new markets on a new chain and naturally let the old one come to an end rather than dragging around its history forever.

- Bugs, security breaches, or other issues during alpha could either take out the chain OR make it desirable to halt block production. It's important to consider what happens next if this occurs.

# Overview
There are really two main features:
1. Create checkpoints with relevant (but minimal) information every `time_elapsed_between_checkpoints` and every deposit and every withdrawal request.
1. Ability to load a checkpoint file as part of genesis. 
At load time calculate the hash of the checkpoint file. Send this through consensus to make sure that all the nodes in the new network are agreeing on the state.

# Creating a checkpoint
Information to store:
- All network parameters
- All asset definitions. Insurance pool balance from the markets will be summed up per asset and balance per asset stored. 
- All market proposals.
- All asset proposals.
- All delegation info.
- On chain treasury balances.
- Balances for all parties per asset: sum of general, margin and LP bond accounts. 
- Withdrawal transaction bundles for all bridged chains for all ongoing withdrawals (parties with non-zero "signed-for-withdrawal" balances)
- `chain_end_of_life_date`
- hash of the previous block, block number and transaction id of the block from which the snapshot is derived
When a checkpoint is created, each validator should calculate its hash and submit this as a transaction to the chain(*). 
- last block height and hash and event ID of all bridged chains (e.g. Ethereum) that the core has seen `number_of_confirmations` of the event. 

When to create a checkpoint:
- if `current_time - time_elapsed_between_checkpoints > time_of_last_full_checkpoint`
- if there was withdrawal 
Withdrawal checkpoint can be just a delta containing the balance change + hash of previous checkpoint (either delta or full). Note that for the "Sweetwater" release we don't need to create a checkpoint on every withdrawal.

Information we explicitly don't try to checkpoint:
- Positions
- Balances in the "signed for withdrawal" account. 
- Governance proposals that haven't been enacted yet aren't stored.

When a checkpoint is created, each validator should calculate its hash and submit this is a transaction to the chain(*). 
(*) This is so that non-validating parties can trust the hash being restored represents truly the balances. 

The checkpoint file should either be human-readable OR there should be a command line tool to convert into human readable form. 

# Restoring a checkpoint
The hash of the state file to be restored must be specified in genesis. 
Any validator will submit a transaction containing the checkpoint file. Nodes verify the hash / chain of hashes to verify hash that's in genesis it's ignored otherwise the state is restored. 
If the genesis file has a previous state hash no transactions will be processed until the restore transaction arrives and is processed. 

1. Restore network parameters. 
2. Load the asset definitions. 
The network will compare the asset coming from the restore file with the genesis assets, one by one. 
If there is an exact match on asset id:
- either the rest of the asset definition matches exactly in which case move to next asset coming from restore file. 
- or any of the part of the definition differ, in which case ignore the restore transaction. 
If the asset coming from the restore file is a new asset (asset id not matching any genesis assets) then ignore the restore transaction.(*) 

3. Replay events from bridged chains from the last event id stored in the checkpoint.

There should be a tool to extract all assets from the restore file so that they can be added to genesis block manually, should the validators so desire.

# Taking limited network life into account 
- Participants need access to funds after network ends. This will be facilitaded both 
(a) the chain will run past the configured `market_trading_terminated` until `chain_end_of_life_date` so that people have time to withdraw; and 
(b) using restoration of balances to allow participants to withdraw or continue to trade with funds during the next iteration of the chain.
- A governance proposal to change `markets_freeze_date` and `chain_end_of_life_date` must check that `chain_end_of_life_date > markets_freeze_date`.

# Acceptance criteria

- [ ] Checkpoints are created every `time_elapsed_between_checkpoints` period of time passes. 
- [ ] Checkpoint is created every time a party requests a withdrawal transaction on any chain.
- [ ] We can launch a network with any valid checkpoint file. 
- [ ] Vega network with a restore file hash in genesis will wait for a restore transaction before accepting any other type of transaction.
- [ ] Hash of the checkpoint file is agreed via consensus.
- [ ] A node will not sign a withdrawal transaction bundle before making the relevant checkpoint.
- [ ] Test case 1 (below)

## Test case 1
1. A party has general account balance of 100 tUSD. 
2. The party submits a withdrawal transaction for 100 tUSD. A checkpoint is immediately created. 
3. The network is shut down. 
4. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint replay transaction is submitted and processed.
5. The check the following subcases
6. 1. If the ethereum replay says withrawal completed. The party has general account balance of 0 tUSD. The party has "signed for withdrawal" 0.
6. 2. If the ethereum replay hasn't seen withdrawal transaction processed and the expiry time of the withdrawal hasn't passed yet. Then the party has general account balance of 0 tUSD. The party has "signed for withdrawal" 100.
6. 3. If the ethereum replay hasn't seen withdrawal transaction processed and the expiry time of the withdrawal has passed. Then the party has general account balance of 100 tUSD. 
 

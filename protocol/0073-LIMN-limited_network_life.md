# Limited network life.

Vega networks will at least initially and perhaps always run for a limited time only. This spec covers the necessary features to ensure this works smoothly.

# Background

Networks will have a finite lifetime because:

- It is efficient to upgrade the protocol by starting again as it avoids the need to deal with multiple versions of the code (upgrades to a running chain need to respect and be able to recalculate the pre-upgrade deterministic state for earlier blocks, so all versions of critical code must remain in the system).
This is especially important early on when rapid iteration is desirable, as the assumption that new chains can be started for new features simplifies things considerably.

- Trading at 1000s of tx/sec generates a lot of data. Given that most instruments are non-perpetual (they expire), this gives the ability to create new markets on a new chain and naturally let the old one come to an end rather than dragging around its history forever.

- Bugs, security breaches, or other issues during alpha could either take out the chain OR make it desirable to halt block production. It's important to consider what happens next if this occurs.

# Overview
There are four main features:
1. Create checkpoints with relevant (but minimal) information at regular intervals, and on every withdrawal request.
2. Ability to specify a checkpoint hash as part of genesis.
3. A new 'Restore' transaction that contains the full checkpoint file and triggers state restoration
4. A new 'checkpoint hash' transaction is broadcast by all validators

Point two requires that at load time, each node calculates the hash of the checkpoint file. It then sends this through consensus to make sure that all the nodes in the new network agree on the state.


# Creating a checkpoint
Information to store:
- All [network parameters](../protocol/0054-NETP-network_parameters.md), including those defined [below](#network-parameters).
- All [asset definitions](../protocol/0040-ASSF-asset_framework.md#asset-definition). 
Insurance pool balances, [Reward account balance](../protocol/0056-REWA-rewards_overview.md), [LP committed liquidity](../protocol/0038-OLIQ-liquidity_provision_order_type.md) and [LP fee pool](../protocol/0029-FEES-fees.md) balances for the markets that have been enacted will be stored with the accepted market proposal that must have preceded the market. 
- All market proposals ([creation](../protocol/0028-GOVE-governance.md#1-create-market) and [update](../protocol/0028-GOVE-governance.md#2-change-market-parameters)) that have been *accepted* but not those where the market already started trading and reached *trading terminated* state. 
- All [asset proposals](../protocol/0028-GOVE-governance.md) that have been *accepted*.
- All delegation info.
- On chain treasury balances and on-chain rewards for staking and delegation [Staking and delegation](../protocol/0056-REWA-rewards_overview.md).
- [Account balances](../protocol/0013-ACCT-accounts.md) for all parties per asset: sum of general, margin and LP bond accounts. 
- Event ID of the last processed deposit event for all bridged chains
- Withdrawal transaction bundles for all bridged chains.
- Hash of the previous block, block number and transaction id of the block from which the snapshot is derived
- ERC20 collateral:
  - last block height of a confirmed erc20 deposit on the ethereum chain with `number_of_confirmations`. [ethereum bridge](./0031-ETHB-ethereum_bridge_spec.md#network-parameters)
  - all pending erc20 deposits (not confirmed before this block) [ethereum bridge](./0031-ETHB-ethereum_bridge_spec.md#deposits)
- Staking:
  - last block of a confirmed stake_deposit on the staking contract on the ethereum chain with `number_of_confirmations`. [ethereum bridge](./0031-ETHB-ethereum_bridge_spec.md#network-parameters)
  - last block of a confirmed stake_deposit on the vesting contract on the ethereum chain with `number_of_confirmations`. [ethereum bridge](./0031-ETHB-ethereum_bridge_spec.md#network-parameters)
  - all the staking events from both contracts [staking](./protocol/0059-STKG-simple_staking_and_delegating.md)
  - all the pending staking events [staking](./protocol/0059-STKG-simple_staking_and_delegating.md)


When to create a checkpoint:
- if `current_time - network.checkpoint.timeElapsedBetweenCheckpoints > time_of_last_full_checkpoint`

Information we explicitly don't try to checkpoint:
- Positions, limit orders, pegged orders or any order book data. LP commitments. 
- Market and asset proposals where the voting period hasn't ended.

When a checkpoint is created, each validator should calculate its hash and submit this is a transaction to the chain, so that non-validating parties can trust the hash being restored represents truly the balances.

The checkpoint file should either be human-readable OR there should be a command line tool to convert into human readable form.

# Specifying the checkpoint hash in genesis

# Restoring a checkpoint
The hash of the state file to be restored must be specified in genesis.
Any validator will submit a transaction containing the checkpoint file. Nodes verify the hash / chain of hashes to verify the hash that is in genesis.
- If the hash matches, it will be restored.
- If it does not, the hash transaction will have no effect.

If the genesis file has a previous state hash, all transactions will be rejected until the restore transaction arrives and is processed.

The state will be restored in this order:

1. Restore network parameters.
2. Load the asset definitions.
    1. The network will compare the asset coming from the restore file with the genesis assets, one by one. If there is an exact match on asset id:
      -  either the rest of the asset definition matches exactly in which case move to next asset coming from restore file.
      -  or any of the part of the definition differ, in which case ignore the entire restore transaction, the node should stop with an error.
    2. If the asset coming from the restore file is a new asset (asset id not matching any genesis assets) then restore the asset.
3. Load the accepted market proposals. If the enactment date is in the past then set the enactment date to `now + net_param_min_enact` (so that opening auction can take place) and status to pending.
4. Replay events from bridged chains
   - Concerning bridges used to deposit collateral for trading, replay from the last block specified in the checkpoint and reload the
     pending deposits from the checkpoint so the network can start again to confirm these events.
   - Concerning the staking bridges, all balances will be reconcilied using the staking events from the checkpoint, up to the last seen block
     store as part of the checkpoint, then apply again the delegations to the validators.

There should be a tool to extract all assets from the restore file so that they can be added to genesis block manually, should the validators so desire.

# Taking limited network life into account
- Participants need access to funds after network ends. This will be facilitated both
    - (a) the chain will run past the configured `market_trading_terminated` until `chain_end_of_life_date` so that people have time to withdraw; and
    - (b) using restoration of balances to allow participants to withdraw or continue to trade with funds during the next iteration of the chain.
- A governance proposal to change `markets_freeze_date` and `chain_end_of_life_date` must check that `chain_end_of_life_date > markets_freeze_date`.

# Network parameters
| Name                                                     | Type     | Description                                                       | Version added  |
|----------------------------------------------------------|:--------:|-------------------------------------------------------------------|:--------:|
|`network.checkpoint.timeElapsedBetweenCheckpoints` | String (duration) |  sets the minimum time elapsed between checkpoints|  💧 Sweetwater |

If for `network.checkpoint.timeElapsedBetweenCheckpoints` the value is set to `0` or the parameter is undefined then no checkpoints are created. Otherwise any time-length value `>0` is valid e.g. `1min`, `2h30min10s`, `1month`. If the value is invalid Vega should not start e.g. if set to `3 fish`.

# Acceptance criteria

- [ ] Checkpoints are created every `network.checkpoint.timeElapsedBetweenCheckpoints` period of time passes. 💧 (<a name="0073-LIMN-001" href="#0073-LIMN-001">0073-LIMN-001</a>)
- [ ] Checkpoint is created every time a party requests a withdrawal transaction on any chain. 💧 (<a name="0073-LIMN-002" href="#0073-LIMN-002">0073-LIMN-002</a>)
- [ ] We can launch a network with any valid checkpoint file. 💧 (<a name="0073-LIMN-003" href="#0073-LIMN-003">0073-LIMN-003</a>)
- [ ] Vega network with a restore file hash in genesis will wait for a restore transaction before accepting any other type of transaction. 💧 (<a name="0073-LIMN-004" href="#0073-LIMN-004">0073-LIMN-004</a>)
- [ ] Hash of the checkpoint file is agreed via consensus. 💧 (<a name="0073-LIMN-005" href="#0073-LIMN-005">0073-LIMN-005</a>)
- [ ] A node will not sign a withdrawal transaction bundle before making the relevant checkpoint. 💧 (<a name="0073-LIMN-006" href="#0073-LIMN-006">0073-LIMN-006</a>)

## 💧 Test case 1: Withdrawal status is correctly tracked across resets (<a name="0073-LIMN-007" href="#0073-LIMN-007">0073-LIMN-007</a>)
1. A party has general account balance of 100 tUSD.
2. The party submits a withdrawal transaction for 100 tUSD. A checkpoint is immediately created.
3. The network is shut down.
4. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint replay transaction is submitted and processed.
5. The check the following subcases
6. 1. If the ethereum replay says withrawal completed. The party has general account balance of 0 tUSD. The party has "signed for withdrawal" 0.
6. 2. If the ethereum replay hasn't seen withdrawal transaction processed and the expiry time of the withdrawal hasn't passed yet. Then the party has general account balance of 0 tUSD. The party has "signed for withdrawal" 100.
6. 3. If the ethereum replay hasn't seen withdrawal transaction processed and the expiry time of the withdrawal has passed. Then the party has general account balance of 100 tUSD.

## 💧 Test case 2: Orders and positions are *not* maintained across resets, balances are and *accepted* markets are (<a name="0073-LIMN-008" href="#0073-LIMN-008">0073-LIMN-008</a>)
1. There is an asset tUSD and no asset proposals.
1. There is a market `id_xxx` with status active, no other markets and no market proposals.
1. There are two parties: one LP for the market and one party that is not an LP.
1. The LP has a long position on `LP_long_pos`.
1. The other party has a short position `other_short_pos = LP_long_pos`.
1. The other party has a limit order on the book.
1. The other party has a pegged order on the book.
1. The LP has general balance of `LP_gen_bal`, margin balance `LP_margin_bal` and bond account balance of `LP_bond_bal`, all in `tUSD`
1. The other party has general balance of `other_gen_bal`, margin balance `other_margin_bal` and bond account balance of `0`, all in `tUSD`.
1. Enough time passes so a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset tUSD.
1. There is a market `id_xxx` in status "pending".
1. The party LP has a `tUSD` general account balance equal to `LP_gen_bal + LP_margin_bal`.
1. The party LP has `LP_bond_bal` committed to market `id_xxx`.
1. The other party has a `tUSD` general account balance equal to `other_gen_bal + other_margin_bal`.




## 💧 Test case 3: Governance proposals are maintained across resets. Votes are not.
### 💧 Test case 3.1: Market is proposed, accepted, restored (<a name="0073-LIMN-009" href="#0073-LIMN-009">0073-LIMN-009</a>)
1. There is an asset tUSD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of 10 000 tUSD.
1. A market is proposed by a party called `LP party` and has enactment date 1 year in the future. The market has id `id_xxx`.
1. `LP party` commits a stake of 1000 tUSD to `id_xxx`.
1. Other parties vote on the market and the proposal is accepted (passes rules for vote majority and participation). The market has id `id_xxx`.
1. The market is in `pending` state, see [market lifecycle](../protocol/0043-MKTL-market_lifecycle.md).
1. Another party places a limit sell order on the market and has `other_gen_bal`, margin balance `other_margin_bal`.
1. Enough time passes so a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset tUSD.
1. There is a market with `id_xxx` with all the same parameters as the accepted proposal had.
1. The LP party has general account balance in tUSD of `9000` and bond account balance `1000` on the market `id_xxx`.
1. The other party has no open orders anywhere and general account balance in tUSD of `other_gen_bal + other_margin_bal`.

### 💧 Test case 3.2: Market is proposed, voting hasn't closed, not restored (<a name="0073-LIMN-010" href="#0073-LIMN-010">0073-LIMN-010</a>)
1. There is an asset tUSD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of 10 000 tUSD.
1. A market is proposed by a party called `LP party`. 
1. `LP party` commits a stake of 1000 tUSD. 
1. The voting period ends 1 year in the future. The enactment date is 2 years in the future.
1. Enough time passes (but less than 1 year) so a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset tUSD.
1. There is no market and there are no market proposals.

### 💧 Test case 3.3: Market is proposed, voting has closed, market rejected, proposal not restored (<a name="0073-LIMN-011" href="#0073-LIMN-011">0073-LIMN-011</a>)
1. There is an asset tUSD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of `10 000` tUSD.
1. A market is proposed by a party called `LP party`.
1. The voting period ends 1 minute in the future. The enactment date is 2 years in the future.
1. More than 1 minute has passed and the minimum participation threshold hasn't been met. The market proposal status is `rejected`.
1. Enough time passes after the market has been rejected so a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset tUSD.
1. There is no market and there are no market proposals.
1. The LP party has general account balance in tUSD of `10 000`.

### 💧 Test case 3.4: Recovery from proposed Markets with no votes, voting is open, proposal not restored (<a name="0073-LIMN-012" href="#0073-LIMN-012">0073-LIMN-012</a>)
1. There is an asset tUSD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of 10 000 tUSD.
1. A market is proposed by a party called `LP party`.
2. Checkpoint is taken during voting period.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset tUSD.
1. There is no market and there are no market proposals.
1. The LP party has general account balance in tUSD of `10 000`.

### 💧 Test case 3.5: Recovery from proposed Markets with votes, voting is open, proposal not restored (<a name="0073-LIMN-013" href="#0073-LIMN-013">0073-LIMN-013</a>)
1. There is an asset tUSD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of 10 000 tUSD.
1. A market is proposed by a party called `LP party`.
2. Checkpoint is taken during voting period
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset tUSD.
1. There is no market and there are no market proposals.
1. The LP party has general account balance in tUSD of `10 000`.

### 💧 Test case 3.6: Market proposals ignored when restoring twice from same checkpoint (<a name="0073-LIMN-014" href="#0073-LIMN-014">0073-LIMN-014</a>)
1. A party has general account balance of 100 tUSD.
2. The party submits a withdrawal transaction for 100 tUSD. A checkpoint is immediately created.
3. The network is shut down.
4. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
5. A new market is proposed
6. The network is shut down.
7. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is no market and there are no market proposals.
1. The party has general account balance in tUSD of `0` and The party has "signed for withdrawal" `100`.

## 💧 Test case 4: Party's Margin Account balance is put in to a General Account balance for that asset after a reset (<a name="0073-LIMN-016" href="#0073-LIMN-016">0073-LIMN-016</a>)
1. A party has tUSD general account balance of 100 tUSD.
2. That party has tUSD margin account balance of 100 tUSD.
3. The network is shut down.
4. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
5. That party has a tUSD general account balance of 200 tUSD

## 💧 Test case 5: Delegation (test with N=5, 10, 20000) (<a name="0073-LIMN-017" href="#0073-LIMN-017">0073-LIMN-017</a>)
1. There is a Vega token asset.
1. There are `5` validators on the network.
1. Each validator party `validator_party_1`,...,`validator_party_5` has `1000` Vega tokens locked on the staking Ethereum bridge and this is reflected in Vega core.
1. There are `N` other parties. Each of the other parties has `other_party_i`, `i=1,2,...,N` has locked exactly `i` tokens on that staking Ethereum bridge and these tokens are undelegeated at this point.
1. Other party `i` delegates all its tokens to `validator_party_j` with `j = i mod 5` (i.e. the remainder after integer division of `j` by `i`.). For example if `N=20000` then party `i=15123` will delegate all its `15123` tokens to validator `validator_party_3` since `15123 mod 5 = 3`.
1. The `Staking and delegation` rewards are active so that every hour each party that has delegated tokens receives `0.01` of the delegated amount as a reward.
1. The network runs for 5 hours.
1. Each of the `other_party_i` has Vega token general account balance equal to `5 x 0.01 x i`. Note that these are separate from the tokens locked on the staking Ethereum bridge.
1. Enough time passes after the 5 hour period so that a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. Validator `1` has freed `500` tokens from the Vega Ethereum staking contract.
1. The network is restarted with the same `5` validators and checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is a Vega token asset.
1. Validator parties `validator_party_2`,...,`validator_party_5` has `1000` Vega tokens locked on the staking Ethereum bridge and this is reflected in Vega core.
1. Validator party `validator_party_1` has `500` Vega tokens locked on the staking Ethereum bridge and this is reflected in Vega core.
1. There are `N` other parties and the delegation info in core says that other party `i` has delegated all its tokens to `validator_party_j` with `j = i mod 5`.
1. Each of the `other_party_i` has Vega token general account balance equal to `5 x 0.01 x i`. Note that these are separate from the tokens locked on the staking Ethereum bridge.
1. Each of the `other_party_i` has Vega token general account balance equal to `5 x 0.01 x i`. Note that these are separate from the tokens locked on the staking Ethereum bridge.

## 💧 Test case 6: Network Parameters / Exceptional case handling
### 💧 Test case 6.1: timeElapsedBetweenCheckpoints not set ?
### 💧 Test case 6.2: timeElapsedBetweenCheckpoints set to value outside acceptable range ?

## 💧 Test case 7 (probably untestable): After network restart, stake balances are recovered by replaying all events (<a name="0073-LIMN-018" href="#0073-LIMN-018">0073-LIMN-018</a>)
1. A party deposits 100 tUSD
1. And A party stakes 100 VEGA on Ethereum
1. And A checkpoint is taken
1. And that party has a staking account balance of 100 VEGA.
1. And that party has delegated 60 VEGA to validator 1
1. And that party has delegated 30 VEGA to validator 2
1. And that party has 10 VEGA undelegated
1. And the network is shut down.
1. And the network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint replay transaction is submitted .
1. When the state is restored, but before the EthereumEventListener replays all events
1. Then that party has 100 tUSD restored to their tUSD general account
1. And that party has delegated 60 VEGA to validator 1
1. And that party has delegated 30 VEGA to validator 2
1. And that party has 0 VEGA undelegated
1. And that party has staking account balance of 0
1. When the EthereumEventListener has replayed all staking events
1. Then that party has a staking account balance of 100
1. And that party has 10 VEGA undelegated

## 💧 Test case 8: Transactions submitted before the restore transaction on a chain with a checkpoint hash specified are rejected (<a name="0073-LIMN-019" href="#0073-LIMN-019">0073-LIMN-019</a>)
1. The network is shut down.
1. The network is restarted with the checkpoint hash in genesis, but the replay transaction is not submitted.
1. Any transaction other than replay is submitted
1. Then that transaction is rejected

## 💧 Test case 9: A replay transaction is submitted with a checkpoint that does not match the hash (<a name="0073-LIMN-020" href="#0073-LIMN-020">0073-LIMN-020</a>)
1. The network is shut down.
1. The network is restarted with the checkpoint hash from a checkpoint in genesis
1. A restore transaction is submitted
1. And the checkpoint data in the restore transaction does not match the hash specified in genesis
1. Then the restore transaction is rejected
1. And the state is not restored

## 💧 Test case 10: Only one valid replay transaction can ever occur (<a name="0073-LIMN-021" href="#0073-LIMN-021">0073-LIMN-021</a>)
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint replay transaction is submitted and processed.
1. Another validator submits a replay transaction
1. That transaction is rejected

## Test case 11: Rewards are distributed correctly every epoch including with the use of recurring transfers (<a name="0073-LIMN-022" href="#0073-LIMN-022">0073-LIMN-022</a>)
1. More than one party deposits stake onto Vega
1. The parties delegate stake to the validators
1. Setup the rewards:
   - A party deposits VEGA funds to their Vega general account
   - The party creates a continuing recurring transfer (for e.g: 1 token) from their general account to the reward pool
1. Assert that every end of epoch, the funds are distributed, over the parties delegating stake, at end of every epoch
1. Wait for the next checkpoint, then stop the network
1. Load the checkpoint into a new network
1. Assert that at every epoch, the recurring transfers to the reward pool continues to happen, and that the funds are properly being distributed to the delegator

## Test case 12:
Enacted, listed ERC20 asset is remembered in checkpoint (<a name="0073-LIMN-023" href="#0073-LIMN-023">0073-LIMN-023</a>)
An ERC20 asset loaded from checkpoint can be used in a market loaded from a checkpoint (<a name="0073-LIMN-024" href="#0073-LIMN-024">0073-LIMN-024</a>)
An ERC20 asset loaded from checkpoint can be updated (<a name="0073-LIMN-025" href="#0073-LIMN-025">0073-LIMN-025</a>)
An ERC20 asset loaded from checkpoint can be used in newly proposed markets (<a name="0073-LIMN-026" href="#0073-LIMN-026">0073-LIMN-026</a>)
Can deposit and withdraw funds to/from ERC20 asset loaded from checkpoint (<a name="0073-LIMN-027" href="#0073-LIMN-027">0073-LIMN-027</a>)

1. Propose a valid ERC20 asset.
1. Wait for the next checkpoint, then stop the network.
1. Load the checkpoint into a new network
1. Assert that the proposal and the asset have been reloaded into the network with the correct settings.
1. Propose a new market using this asset
1. Deposit funds to traders via the bridge and assert that funds are received.
1. Place orders on the market that will cross.
1. Withdraw funds for one of the traders.
1. Propose an update to the asset, and ensure that you can update the ERC20 bridge with the asset update and signature bundle.

## Test case 13: A market with future enactment date can become enacted after being restored from checkpoint (<a name="0073-LIMN-028" href="#0073-LIMN-028">0073-LIMN-028</a>)
1. There is an asset tUSD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of 10 000 tUSD.
1. A market is proposed by a party called `LP party` and has enactment date several minutes in the future. The market has id `id_xxx`.
1. `LP party` commits a stake of 1000 tUSD to `id_xxx`.
1. Other parties vote on the market and the proposal is accepted (passes rules for vote majority and participation). The market has id `id_xxx`.
1. The market is in `pending` state, see [market lifecycle](../protocol/0043-MKTL-market_lifecycle.md).
1. Enough time passes so a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis.
1. There is an asset tUSD.
1. There is a market with `id_xxx` with all the same parameters as the accepted proposal had.
1. The LP party has general account balance in tUSD of `9000` and bond account balance `1000` on the market `id_xxx`.
1. The market is still in "pending" state.
1. The market becomes enaced when the enactment time is passed.
1. Other parties can trade on the market, and become continuous.



## Test case 14: Market with trading terminated is not restored, collateral moved correctly 
1. Set LP fee distribution time step to non-zero value.
1. Propose, enact, trade in the market, close out distressed party so that insurance pool balance > 0, submit trading terminated. 
1. System saves LNL checkpoint at a time when undistributed LP fees for the market are > 0.
1. Restart Vega, load LNL checkpoint. 
1. The market is not restored (it doesn't exist in core i.e. it's not possible to submit orders or LP provisions to this market) (<a name="0073-LIMN-029" href="#0073-LIMN-029">0073-LIMN-029</a>) 
1. If the market exists in the data node it is marked as settled with no settlement price info (<a name="0073-LIMN-030" href="#0073-LIMN-030">0073-LIMN-030</a>)
1. For parties that had margin balance position on the market this is now in their general account for the asset.  (<a name="0073-LIMN-030" href="#0073-LIMN-030">0073-LIMN-030</a>)
1. The LP fees that were not distributed have been transferred to the Vega treasury for the asset. (<a name="0073-LIMN-031" href="#0073-LIMN-031">0073-LIMN-031</a>)
1. The insurance pool balance has been transferred to the Vega treasury for the asset. (<a name="0073-LIMN-032" href="#0073-LIMN-032">0073-LIMN-032</a>)
1. The LP bond account balance has been transferred to the party's general account for the asset. (<a name="0073-LIMN-033" href="#0073-LIMN-033">0073-LIMN-033</a>)


## Test case 15: Market with trading terminated that settled is not restored, collateral moved correctly 
1. Propose, enact, trade in the market, submit trading terminated and settlement data, observe final settlement cashflows for at least 2 parties. 
1. System saves LNL checkpoint.
1. Restart Vega, load LNL checkpoint. 
1. The market is not restored (it doesn't exist in core i.e. it's not possible to submit orders or LP provisions to this market) (<a name="0073-LIMN-034" href="#0073-LIMN-034">0073-LIMN-034</a>) 
1. If the market exists in the data node it is marked as settled with correct settlement data. (<a name="0073-LIMN-035" href="#0073-LIMN-035">0073-LIMN-035</a>)
1. For parties that had margin balance position on the market this is now in their general account for the asset.  (<a name="0073-LIMN-036" href="#0073-LIMN-036">0073-LIMN-036</a>)
1. The insurance pool balance has been transferred to the Vega treasury for the asset. (<a name="0073-LIMN-037" href="#0073-LIMN-037">0073-LIMN-037</a>)
1. The LP bond account balance has been transferred to the party's general account for the asset. (<a name="0073-LIMN-038" href="#0073-LIMN-038">0073-LIMN-038</a>)

## Test case 16: Markets can be settled and terminated after restore as propposed
1. Propose, enact a market with some trading termination and settlement date setting. Trade in the market creating positions for at least 2 parties. 
1. System saves LNL checkpoint.
1. Restart Vega, load LNL checkpoint.  
1. A party submits liquidity provision to the market, orders are submitted to the opening auction to allow uncrossing; at least two parties now have a position. 
1. Submit the trading terminated transaction and settlement date transaction as set out in the proposal and observe the final settlement cashflows for the parties with positions.  (<a name="0073-LIMN-039" href="#0073-LIMN-039">0073-LIMN-039</a>)
1. It's not possible to submit orders or LP provisions to this market).  (<a name="0073-LIMN-040" href="#0073-LIMN-040">0073-LIMN-040</a>)

## Test case 17: Markets with internal time trigger for trading terminated that rings between shutdown and restore
1. Propose, enact a market with some traing terminated given by internal time trigger. Trade in the market creating positions for at least 2 parties. 
1. System saves LNL checkpoint before the trading terminated trigger rings. 
1. Restart Vega, load LNL checkpoint at a time which is after trading terminated trigger should have rung. 
1. The market is not restored (it doesn't exist in core i.e. it's not possible to submit orders or LP provisions to this market) (<a name="0073-LIMN-041" href="#0073-LIMN-041">0073-LIMN-041</a>) 
1. If the market exists in the data node it is marked as settled with no settlement price info (<a name="0073-LIMN-042" href="#0073-LIMN-042">0073-LIMN-042</a>)
1. For parties that had margin balance position on the market this is now in their general account for the asset.  (<a name="0073-LIMN-043" href="#0073-LIMN-043">0073-LIMN-043</a>)
1. The LP fees that were not distributed have been transferred to the Vega treasury for the asset. (<a name="0073-LIMN-044" href="#0073-LIMN-044">0073-LIMN-044</a>)
1. The insurance pool balance has been transferred to the Vega treasury for the asset. (<a name="0073-LIMN-045" href="#0073-LIMN-045">0073-LIMN-045</a>)
1. The LP bond account balance has been transferred to the party's general account for the asset. (<a name="0073-LIMN-046" href="#0073-LIMN-046">0073-LIMN-046</a>)

## Test case 18: market definition is the same pre and post LNL restore
1. Propose a market
1. System saves LNL checkpoint.
1. Restart Vega, load LNL checkpoint. 
1. The market has the same:
  - risk model and params (<a name="0073-LIMN-047" href="#0073-LIMN-047">0073-LIMN-047</a>)
  - price monitoring bounds (<a name="0073-LIMN-048" href="#0073-LIMN-048">0073-LIMN-048</a>)
  - oracle settings (<a name="0073-LIMN-049" href="#0073-LIMN-049">0073-LIMN-049</a>)
  - margin scaling factors (<a name="0073-LIMN-050" href="#0073-LIMN-050">0073-LIMN-050</a>)
  



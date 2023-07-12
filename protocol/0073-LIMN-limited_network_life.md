# Limited network life

Vega networks will at least initially and perhaps always run for a limited time only. This spec covers the necessary features to ensure this works smoothly.

## Background

Networks will have a finite lifetime because:

- It is efficient to upgrade the protocol by starting again as it avoids the need to deal with multiple versions of the code (upgrades to a running chain need to respect and be able to recalculate the pre-upgrade deterministic state for earlier blocks, so all versions of critical code must remain in the system).
This is especially important early on when rapid iteration is desirable, as the assumption that new chains can be started for new features simplifies things considerably.

- Trading at 1000s of tx/sec generates a lot of data. Given that most instruments are non-perpetual (they expire), this gives the ability to create new markets on a new chain and naturally let the old one come to an end rather than dragging around its history forever.

- Bugs, security breaches, or other issues during alpha could either take out the chain OR make it desirable to halt block production. It's important to consider what happens next if this occurs.

## Overview

There are four main features:

1. Create checkpoints with relevant (but minimal) information at regular intervals, and on every withdrawal request.
2. Ability to specify a checkpoint hash as part of genesis.
3. A new 'Restore' transaction that contains the full checkpoint file and triggers state restoration
4. A new 'checkpoint hash' transaction is broadcast by all validators

Point two requires that at load time, each node calculates the hash of the checkpoint file. It then sends this through consensus to make sure that all the nodes in the new network agree on the state.

## Creating a checkpoint

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
- ERC-20 collateral:
  - last block height of a confirmed ERC-20 deposit on the Ethereum chain with `number_of_confirmations`. [Ethereum bridge](./0031-ETHB-ethereum_bridge_spec.md#network-parameters)
  - all pending ERC-20 deposits (not confirmed before this block) [Ethereum bridge](./0031-ETHB-ethereum_bridge_spec.md#deposits)
- Staking:
  - last block of a confirmed stake_deposit on the staking contract on the Ethereum chain with `number_of_confirmations`. [Ethereum bridge](./0031-ETHB-ethereum_bridge_spec.md#network-parameters)
  - last block of a confirmed stake_deposit on the vesting contract on the Ethereum chain with `number_of_confirmations`. [Ethereum bridge](./0031-ETHB-ethereum_bridge_spec.md#network-parameters)
  - all the staking events from both contracts [staking](./0059-STKG-simple_staking_and_delegating.md)
  - all the pending staking events [staking](./0059-STKG-simple_staking_and_delegating.md)

When to create a checkpoint:

- if `current_time - network.checkpoint.timeElapsedBetweenCheckpoints > time_of_last_full_checkpoint`

Information we explicitly don't try to checkpoint:

- Positions, limit orders, pegged orders or any order book data. LP commitments.
- Market and asset proposals where the voting period hasn't ended.

When a checkpoint is created, each validator should calculate its hash and submit this is a transaction to the chain, so that non-validating parties can trust the hash being restored represents truly the balances.

The checkpoint file should either be human-readable OR there should be a command line tool to convert into human readable form.

## Specifying the checkpoint hash in genesis

## Restoring a checkpoint

The hash of the state file to be restored must be specified in genesis.
Any validator will submit a transaction containing the checkpoint file. Nodes verify the hash / chain of hashes to verify the hash that is in genesis.

- If the hash matches, it will be restored.
- If it does not, the hash transaction will have no effect.

If the genesis file has a previous state hash, all transactions will be rejected until the restore transaction arrives and is processed.

The state will be restored in this order:

- Restore network parameters.
- Load the asset definitions.
  - The network will compare the asset coming from the restore file with the genesis assets, one by one. If there is an exact match on asset id:
  - either the rest of the asset definition matches exactly in which case move to next asset coming from restore file.
  - or any of the part of the definition differ, in which case ignore the entire restore transaction, the node should stop with an error.
  - If the asset coming from the restore file is a new asset (asset id not matching any genesis assets) then restore the asset.
- Load the accepted market proposals. If the enactment date is in the past then set the enactment date to `now + net_param_min_enact` (so that opening auction can take place) and status to pending.
- Replay events from bridged chains
  - Concerning bridges used to deposit collateral for trading, replay from the last block specified in the checkpoint and reload the pending deposits from the checkpoint so the network can start again to confirm these events.
  - Concerning the staking bridges, all balances will be reconciled using the staking events from the checkpoint, up to the last seen block store as part of the checkpoint, then apply again the delegations to the validators.

There should be a tool to extract all assets from the restore file so that they can be added to genesis block manually, should the validators so desire.

## Restoring balances

- Participants need access to funds after network ends. This will be facilitated by using restoration of balances to allow participants to withdraw or continue to trade with funds during the next iteration of the chain.

## Network parameters

| Name                                                     | Type     | Description                                                       |
|----------------------------------------------------------|:--------:|-------------------------------------------------------------------|:--------:|
|`network.checkpoint.timeElapsedBetweenCheckpoints` | String (duration) |  sets the minimum time elapsed between checkpoints|

If for `network.checkpoint.timeElapsedBetweenCheckpoints` the value is set to `0` or the parameter is undefined then no checkpoints are created. Otherwise any time-length value `>0` is valid e.g. `1min`, `2h30min10s`, `1month`. If the value is invalid Vega should not start e.g. if set to `3 fish`.

## Acceptance criteria

- Checkpoints are created every `network.checkpoint.timeElapsedBetweenCheckpoints` period of time passes. (<a name="0073-LIMN-001" href="#0073-LIMN-001">0073-LIMN-001</a>)
- Checkpoint is created every time a party requests a withdrawal transaction on any chain. (<a name="0073-LIMN-002" href="#0073-LIMN-002">0073-LIMN-002</a>)
- We can launch a network with any valid checkpoint file. (<a name="0073-LIMN-003" href="#0073-LIMN-003">0073-LIMN-003</a>)
- Hash of the checkpoint file is agreed via consensus. (<a name="0073-LIMN-005" href="#0073-LIMN-005">0073-LIMN-005</a>)

### Test case 1: Withdrawal status is correctly tracked across resets (<a name="0073-LIMN-007" href="#0073-LIMN-007">0073-LIMN-007</a>)(<a name="0073-SP-LIMN-007" href="#0073-SP-LIMN-007">0073-SP-LIMN-007</a>)

1. A party has general account balance of 100 USD.
1. The party submits a withdrawal transaction for 100 USD. A checkpoint is immediately created.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint replay transaction is submitted and processed.
1. The check the following sub-cases:
    - If the Ethereum replay says withdrawal completed. The party has general account balance of 0 USD. The party has "signed for withdrawal" 0.
    - If the Ethereum replay hasn't seen withdrawal transaction processed and the expiry time of the withdrawal hasn't passed yet. Then the party has general account balance of 0 USD. The party has "signed for withdrawal" 100.
    - If the Ethereum replay hasn't seen withdrawal transaction processed and the expiry time of the withdrawal has passed. Then the party has general account balance of 100 USD.

### Test case 2: Orders and positions are *not* maintained across resets, balances are and *accepted* markets are (<a name="0073-LIMN-008" href="#0073-LIMN-008">0073-LIMN-008</a>)

1. There is an asset USD and no asset proposals.
1. There is a market `id_xxx` with status active, no other markets and no market proposals.
1. There are two parties: one LP for the market and one party that is not an LP.
1. The LP has a long position on `LP_long_pos`.
1. The other party has a short position `other_short_pos = LP_long_pos`.
1. The other party has a limit order on the book.
1. The other party has a pegged order on the book.
1. The LP has general balance of `LP_gen_bal`, margin balance `LP_margin_bal` and bond account balance of `LP_bond_bal`, all in `USD`
1. The other party has general balance of `other_gen_bal`, margin balance `other_margin_bal` and bond account balance of `0`, all in `USD`.
1. Enough time passes so a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset USD.
1. There is a market `id_xxx` in status "pending".
1. The party LP has a `USD` general account balance equal to `LP_gen_bal + LP_margin_bal`.
1. The party LP has `LP_bond_bal` committed to market `id_xxx`.
1. The other party has a `USD` general account balance equal to `other_gen_bal + other_margin_bal`.

### Test case 3: Governance proposals are maintained across resets, votes are not

#### Test case 3.1: Market is proposed, accepted, restored (<a name="0073-LIMN-009" href="#0073-LIMN-009">0073-LIMN-009</a>)

1. There is an asset USD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of 10 000 USD.
1. A market is proposed by a party called `LP party` and has enactment date 1 year in the future. The market has id `id_xxx`.
1. `LP party` commits a stake of 1000 USD to `id_xxx`.
1. Other parties vote on the market and the proposal is accepted (passes rules for vote majority and participation). The market has id `id_xxx`.
1. The market is in `pending` state, see [market lifecycle](../protocol/0043-MKTL-market_lifecycle.md).
1. Another party places a limit sell order on the market and has `other_gen_bal`, margin balance `other_margin_bal`.
1. Enough time passes so a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset USD.
1. There is a market with `id_xxx` with all the same parameters as the accepted proposal had.
1. The LP party has general account balance in USD of `9000` and bond account balance `1000` on the market `id_xxx`.
1. The other party has no open orders anywhere and general account balance in USD of `other_gen_bal + other_margin_bal`.

#### Test case 3.1: Spot market is proposed, accepted, restored (<a name="0073-SP-LIMN-009" href="#0073-SP-LIMN-009">0073-SP-LIMN-009</a>)

1. There is an asset USD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of 10 000 USD.
1. A market is proposed by a party called `LP party` and has enactment date 1 year in the future. The market has id `id_xxx`.
1. `LP party` commits a stake of 1000 USD to `id_xxx`.
1. Other parties vote on the market and the proposal is accepted (passes rules for vote majority and participation). The market has id `id_xxx`.
1. The market is in `pending` state, see [market lifecycle](../protocol/0043-MKTL-market_lifecycle.md).
1. Another party places a limit sell order on the market and has `other_gen_bal`, holding balance `other_hold_bal`.
1. Enough time passes so a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset USD.
1. There is a market with `id_xxx` with all the same parameters as the accepted proposal had.
1. The LP party has general account balance in USD of `9000` and bond account balance `1000` on the market `id_xxx`.
1. The other party has no open orders anywhere and general account balance in USD of `other_gen_bal + other_hold_bal`.

#### Test case 3.2: Market is proposed, voting hasn't closed, not restored (<a name="0073-LIMN-010" href="#0073-LIMN-010">0073-LIMN-010</a>)(<a name="0073-SP-LIMN-010" href="#0073-SP-LIMN-010">0073-SP-LIMN-010</a>)

1. There is an asset USD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of 10 000 USD.
1. A market is proposed by a party called `LP party`.
1. `LP party` commits a stake of 1000 USD.
1. The voting period ends 1 year in the future. The enactment date is 2 years in the future.
1. Enough time passes (but less than 1 year) so a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset USD.
1. There is no market and there are no market proposals.

#### Test case 3.3: Market is proposed, voting has closed, market rejected, proposal not restored (<a name="0073-LIMN-011" href="#0073-LIMN-011">0073-LIMN-011</a>)(<a name="0073-SP-LIMN-011" href="#0073-SP-LIMN-011">0073-SP-LIMN-011</a>)

1. There is an asset USD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of `10 000` USD.
1. A market is proposed by a party called `LP party`.
1. The voting period ends 1 minute in the future. The enactment date is 2 years in the future.
1. More than 1 minute has passed and the minimum participation threshold hasn't been met. The market proposal status is `rejected`.
1. Enough time passes after the market has been rejected so a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset USD.
1. There is no market and there are no market proposals.
1. The LP party has general account balance in USD of `10 000`.

#### Test case 3.4: Recovery from proposed Markets with no votes, voting is open, proposal not restored (<a name="0073-LIMN-012" href="#0073-LIMN-012">0073-LIMN-012</a>)

for product spot: (<a name="0073-LIMN-077" href="#0073-LIMN-077">0073-LIMN-077</a>)

1. There is an asset USD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of 10 000 USD.
1. A market is proposed by a party called `LP party`.
1. Checkpoint is taken during voting period.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset USD.
1. There is no market and there are no market proposals.
1. The LP party has general account balance in USD of `10 000`.

#### Test case 3.5: Recovery from proposed Markets with votes, voting is open, proposal not restored (<a name="0073-LIMN-013" href="#0073-LIMN-013">0073-LIMN-013</a>)

for product spot: (<a name="0073-LIMN-078" href="#0073-LIMN-078">0073-LIMN-078</a>)

1. There is an asset USD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of 10 000 USD.
1. A market is proposed by a party called `LP party`.
1. Checkpoint is taken during voting period
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is an asset USD.
1. There is no market and there are no market proposals.
1. The LP party has general account balance in USD of `10 000`.

#### Test case 3.6: Market proposals ignored when restoring twice from same checkpoint (<a name="0073-LIMN-014" href="#0073-LIMN-014">0073-LIMN-014</a>)

for product spot: (<a name="0073-LIMN-079" href="#0073-LIMN-079">0073-LIMN-079</a>)

1. A party has general account balance of 100 USD.
1. The party submits a withdrawal transaction for 100 USD. A checkpoint is immediately created.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. A new market is proposed
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is no market and there are no market proposals.
1. The party has general account balance in USD of `0` and The party has "signed for withdrawal" `100`.

### Test case 4a: Party's Margin Account balance is put in to a General Account balance for that asset after a reset (<a name="0073-LIMN-016" href="#0073-LIMN-016">0073-LIMN-016</a>)

1. A party has USD general account balance of 100 USD.
2. That party has USD margin account balance of 100 USD.
3. The network is shut down.
4. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
5. That party has a USD general account balance of 200 USD

### Test case 4b: In Spot market, party's Holding Account balance is put in to a General Account balance for that asset after a reset (<a name="0073-LIMN-080" href="#0073-LIMN-080">0073-LIMN-080</a>)

1. A party has USD general account balance of 100 USD.
2. That party has USD holding account balance of 50 USD.
3. The network is shut down.
4. The network is restarted with the checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
5. That party has a USD general account balance of 150 USD

### Test case 5: Add or remove stake during checkpoint restart (<a name="0073-LIMN-017" href="#0073-LIMN-017">0073-LIMN-017</a>)
1. There is a Vega token asset.
1. There are `5` validators on the network.
1. Each validator party `validator_party_1`,...,`validator_party_5` has `1000` Vega tokens locked on the staking Ethereum bridge and this is reflected in Vega core.
1. There are `N` other parties. Each of the other parties has `other_party_i`, `i=1,2,...,N` has locked exactly `i` tokens on that staking Ethereum bridge and these tokens are undelegated at this point.
1. Other party `i` delegates all its tokens to `validator_party_j` with `j = i mod 5` (i.e. the remainder after integer division of `j` by `i`.). For example if `N=20000` then party `i=15123` will delegate all its `15123` tokens to validator `validator_party_3` since `15123 mod 5 = 3`.
1. The `Staking and delegation` rewards are active so that every hour each party that has delegated tokens receives `0.01` of the delegated amount as a reward.
1. Each of the `other_party_i` has Vega token general account balance equal to `5 x 0.01 x i`. Note that these are separate from the tokens locked on the staking Ethereum bridge.
1. Enough time passes so that a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. One party `1` with stake delegated has freed `500` tokens from the Vega Ethereum staking contract.
1. One party `2` with stake delegated adds `500` tokens to the Vega Ethereum staking contract.
1. The network is restarted with the same `5` validators and checkpoint hash from the above checkpoint in genesis. The checkpoint restore transaction is submitted and processed.
1. There is a Vega token asset.
1. Validator parties `validator_party_1`,...,`validator_party_5` has `1000` Vega tokens locked on the staking Ethereum bridge and this is reflected in Vega core.
1. Other party `1` has `-500` Vega tokens locked on the staking Ethereum bridge and this is reflected in Vega core, including updated delegation amounts.
1. Other party `2` has `+500` Vega tokens locked on the staking Ethereum bridge and this is reflected in Vega core, including updated delegation amounts via auto delegation.
1. There are `N-2` other parties and the delegation info in core says that other party `i` has delegated all its tokens to `validator_party_j` with `j = i mod 5`.
1. Each of the `other_party_i` has Vega token general account balance equal to `5 x 0.01 x i`. Note that these are separate from the tokens locked on the staking Ethereum bridge.

### Test case 6: Network Parameters / Exceptional case handling

#### Test case 6.1: `timeElapsedBetweenCheckpoints` not set

#### Test case 6.2: `timeElapsedBetweenCheckpoints` set to value outside acceptable range

### Test case 11: Rewards are distributed correctly every epoch including with the use of recurring transfers (<a name="0073-LIMN-022" href="#0073-LIMN-022">0073-LIMN-022</a>)

- More than one party deposits stake onto Vega
- The parties delegate stake to the validators
- Setup the rewards:
  - A party deposits VEGA funds to their Vega general account
  - The party creates a continuing recurring transfer (for e.g: 1 token) from their general account to the reward pool
- Assert that every end of epoch, the funds are distributed, over the parties delegating stake, at end of every epoch
- Wait for the next checkpoint, then stop the network
- Load the checkpoint into a new network
- Assert that at every epoch, the recurring transfers to the reward pool continues to happen, and that the funds are properly being distributed to the delegator

### Test case 12

1. Enacted, listed ERC-20 asset is remembered in checkpoint (<a name="0073-LIMN-023" href="#0073-LIMN-023">0073-LIMN-023</a>)
1. An ERC-20 asset loaded from checkpoint can be used in a market loaded from a checkpoint (<a name="0073-LIMN-024" href="#0073-LIMN-024">0073-LIMN-024</a>)
1. An ERC-20 asset loaded from checkpoint can be updated (<a name="0073-LIMN-025" href="#0073-LIMN-025">0073-LIMN-025</a>)
1. An ERC-20 asset loaded from checkpoint can be used in newly proposed markets (<a name="0073-LIMN-026" href="#0073-LIMN-026">0073-LIMN-026</a>) for product spot: (<a name="0073-LIMN-081" href="#0073-LIMN-081">0073-LIMN-081</a>)
1. Can deposit and withdraw funds to/from ERC-20 asset loaded from checkpoint (<a name="0073-LIMN-027" href="#0073-LIMN-027">0073-LIMN-027</a>)

1. Propose a valid ERC-20 asset.
1. Wait for the next checkpoint, then stop the network.
1. Load the checkpoint into a new network
1. Assert that the proposal and the asset have been reloaded into the network with the correct settings.
1. Propose a new market using this asset
1. Deposit funds to traders via the bridge and assert that funds are received.
1. Place orders on the market that will cross.
1. Withdraw funds for one of the traders.
1. Propose an update to the asset, and ensure that you can update the ERC20 bridge with the asset update and signature bundle.

### Test case 13: A market with future enactment date can become enacted after being restored from checkpoint (<a name="0073-LIMN-028" href="#0073-LIMN-028">0073-LIMN-028</a>)

for product spot: (<a name="0073-LIMN-082" href="#0073-LIMN-082">0073-LIMN-082</a>)

1. There is an asset USD and no asset proposals.
1. There are no markets and no market proposals.
1. There is a party a party called `LP party` with general balance of 10 000 USD.
1. A market is proposed by a party called `LP party` and has enactment date several minutes in the future. The market has id `id_xxx`.
1. `LP party` commits a stake of 1000 USD to `id_xxx`.
1. Other parties vote on the market and the proposal is accepted (passes rules for vote majority and participation). The market has id `id_xxx`.
1. The market is in `pending` state, see [market lifecycle](../protocol/0043-MKTL-market_lifecycle.md).
1. Enough time passes so a checkpoint is created and no party submitted any withdrawal transactions throughout.
1. The network is shut down.
1. The network is restarted with the checkpoint hash from the above checkpoint in genesis.
1. There is an asset USD.
1. There is a market with `id_xxx` with all the same parameters as the accepted proposal had.
1. The LP party has general account balance in USD of `9000` and bond account balance `1000` on the market `id_xxx`.
1. The market is still in "pending" state.
1. The market becomes enacted when the enactment time is passed.
1. Other parties can trade on the market, and become continuous.

### Test case 14: Market with trading terminated is not restored, collateral moved correctly

1. Set LP fee distribution time step to non-zero value.
1. Propose, enact, trade in the market, close out distressed party so that insurance pool balance > 0, submit trading terminated.
1. System saves LNL checkpoint at a time when undistributed LP fees for the market are > 0.
1. Restart Vega, load LNL checkpoint.
1. The market is not restored (it doesn't exist in core i.e. it's not possible to submit orders or LP provisions to this market) (<a name="0073-LIMN-029" href="#0073-LIMN-029">0073-LIMN-029</a>) for product spot: (<a name="0073-LIMN-083" href="#0073-LIMN-083">0073-LIMN-083</a>)
1. If the market exists in the data node it is marked as settled with no settlement price info (<a name="0073-LIMN-030" href="#0073-LIMN-030">0073-LIMN-030</a>)
1. For parties that had margin balance position on the market this is now in their general account for the asset.  (<a name="0073-LIMN-031" href="#0073-LIMN-031">0073-LIMN-031</a>)
1. In Spot market, for parties that had holdings in the holding account on the market this is now in their general account for the asset.  (<a name="0073-LIMN-084" href="#0073-LIMN-084">0073-LIMN-084</a>)
1. The LP fees that were not distributed have been transferred to the Vega treasury for the asset. (<a name="0073-LIMN-032" href="#0073-LIMN-032">0073-LIMN-032</a>) for product spot: (<a name="0073-LIMN-085" href="#0073-LIMN-085">0073-LIMN-085</a>)
1. The insurance pool balance has been transferred to the Vega treasury for the asset. (<a name="0073-LIMN-033" href="#0073-LIMN-033">0073-LIMN-033</a>)
1. The LP bond account balance has been transferred to the party's general account for the asset. (<a name="0073-LIMN-034" href="#0073-LIMN-034">0073-LIMN-034</a>) for product spot: (<a name="0073-LIMN-086" href="#0073-LIMN-086">0073-LIMN-086</a>)

### Test case 15: Market with trading terminated that settled is not restored, collateral moved correctly

1. Propose, enact, trade in the market, submit trading terminated and settlement data, observe final settlement cashflows for at least 2 parties.
1. System saves LNL checkpoint.
1. Restart Vega, load LNL checkpoint.
1. The market is not restored (it doesn't exist in core i.e. it's not possible to submit orders or LP provisions to this market) (<a name="0073-LIMN-040" href="#0073-LIMN-040">0073-LIMN-040</a>) for product spot: (<a name="0073-LIMN-087" href="#0073-LIMN-087">0073-LIMN-087</a>)
1. If the market exists in the data node it is marked as settled with correct settlement data. (<a name="0073-LIMN-041" href="#0073-LIMN-041">0073-LIMN-041</a>)
1. For parties that had margin balance position on the market this is now in their general account for the asset.  (<a name="0073-LIMN-042" href="#0073-LIMN-042">0073-LIMN-042</a>)
1. In Spot market, for parties that had holdings in their holding accounts on the market this is now in their general account for the asset.  (<a name="0073-LIMN-088" href="#0073-LIMN-088">0073-LIMN-088</a>)
1. The insurance pool balance has been transferred to the Vega treasury for the asset. (<a name="0073-LIMN-043" href="#0073-LIMN-043">0073-LIMN-043</a>)
1. The LP bond account balance has been transferred to the party's general account for the asset. (<a name="0073-LIMN-044" href="#0073-LIMN-044">0073-LIMN-044</a>) for product spot: (<a name="0073-LIMN-089" href="#0073-LIMN-089">0073-LIMN-089</a>)

### Test case 16: Markets can be settled and terminated after restore as proposed

1. Propose, enact a market with some trading termination and settlement date setting. Trade in the market creating positions for at least 2 parties.
1. System saves LNL checkpoint.
1. Restart Vega, load LNL checkpoint.
1. A party submits liquidity provision to the market, orders are submitted to the opening auction to allow uncrossing; at least two parties now have a position.
1. Submit the trading terminated transaction and settlement date transaction as set out in the proposal and observe the final settlement cashflows for the parties with positions.  (<a name="0073-LIMN-050" href="#0073-LIMN-050">0073-LIMN-050</a>)
1. In Spot market, market can be closed after a restore. (<a name="0073-LIMN-090" href="#0073-LIMN-090">0073-LIMN-090</a>)
1. It's not possible to submit orders or LP provisions to this market.  (<a name="0073-LIMN-051" href="#0073-LIMN-051">0073-LIMN-051</a>) for product spot: (<a name="0073-LIMN-091" href="#0073-LIMN-091">0073-LIMN-091</a>)

### Test case 17: Markets with internal time trigger for trading terminated that rings between shutdown and restore

1. Propose, enact a market with some trading terminated given by internal time trigger. Trade in the market creating positions for at least 2 parties.
1. System saves LNL checkpoint before the trading terminated trigger rings.
1. Restart Vega, load LNL checkpoint at a time which is after trading terminated trigger should have rung.
1. The market is not restored (it doesn't exist in core i.e. it's not possible to submit orders or LP provisions to this market) (<a name="0073-LIMN-060" href="#0073-LIMN-060">0073-LIMN-060</a>) for product spot: (<a name="0073-LIMN-092" href="#0073-LIMN-092">0073-LIMN-092</a>); if it exists it in `cancelled` state.
1. If the market exists in the data node it is labelled as `cancelled` (<a name="0073-LIMN-061" href="#0073-LIMN-061">0073-LIMN-061</a>) for product spot: (<a name="0073-LIMN-093" href="#0073-LIMN-093">0073-LIMN-093</a>)
1. For parties that had margin balance position on the market this is now in their general account for the asset.  (<a name="0073-LIMN-062" href="#0073-LIMN-062">0073-LIMN-062</a>)
1. In Spot market, for parties that had holdings in their holding accounts on the market this is now in their general account for the asset. (<a name="0073-LIMN-094" href="#0073-LIMN-094">0073-LIMN-094</a>)
1. The LP fees that were not distributed have been transferred to the Vega treasury for the asset. (<a name="0073-LIMN-063" href="#0073-LIMN-063">0073-LIMN-063</a>) for product spot: (<a name="0073-LIMN-095" href="#0073-LIMN-095">0073-LIMN-095</a>)
1. The insurance pool balance has been transferred to the Vega treasury for the asset. (<a name="0073-LIMN-064" href="#0073-LIMN-064">0073-LIMN-064</a>)
1. The LP bond account balance has been transferred to the party's general account for the asset. (<a name="0073-LIMN-065" href="#0073-LIMN-065">0073-LIMN-065</a>) for product spot: (<a name="0073-LIMN-096" href="#0073-LIMN-096">0073-LIMN-096</a>)

### Test case 18: market definition is the same pre and post LNL restore

- Propose a market
- System saves LNL checkpoint.
- Restart Vega, load LNL checkpoint.
- The market has the same:
  - risk model and parameters (<a name="0073-LIMN-070" href="#0073-LIMN-070">0073-LIMN-070</a>) for product spot: (<a name="0073-LIMN-097" href="#0073-LIMN-097">0073-LIMN-097</a>)
  - price monitoring bounds (<a name="0073-LIMN-071" href="#0073-LIMN-071">0073-LIMN-071</a>) for product spot: (<a name="0073-LIMN-098" href="#0073-LIMN-098">0073-LIMN-098</a>)
  - oracle settings (<a name="0073-LIMN-072" href="#0073-LIMN-072">0073-LIMN-072</a>) for product spot: (<a name="0073-LIMN-099" href="#0073-LIMN-099">0073-LIMN-099</a>)
  - margin scaling factors (<a name="0073-LIMN-073" href="#0073-LIMN-073">0073-LIMN-073</a>)

### Test case 19: Deposit tokens during checkpoint restore

1. On a vega network which has some ERC20 tokens enabled.
1. Wait for a checkpoint to be available for checkpoint restart.
1. Stop the network.
1. Deposit tokens to a vega party via the ERC20 assert bridge.
1. Restart the vega network from the checkpoint created earlier.
1. There party's newly deposited assets are available. (<a name="0073-LIMN-074" href="#0073-LIMN-074">0073-LIMN-074</a>) for product spot: (<a name="0073-LIMN-100" href="#0073-LIMN-100">0073-LIMN-100</a>)

### Test case 20: Multisig updates during checkpoint restart

1. On a vega network where one validator has been promoted in favour of another (do not update multisig contract to reflect this), and there are tokens in reward accounts ready for distribution.
1. Wait for a checkpoint to be available for checkpoint restart.
1. Retrieve the signatures to update the multisig contract (do not update yet).
1. Stop the network.
1. Update the multisig contract.
1. Restart the vega network from the checkpoint created earlier.
1. Vega observes the multisig change and rewards are paid at the end of the current epoch. (<a name="0073-LIMN-075" href="#0073-LIMN-075">0073-LIMN-075</a>)

### Test case 21: Loading from checkpoint with invalid multisig

1. On a vega network where one validator has been promoted in favour of another (do not update multisig contract to reflect this), and there are tokens in reward accounts ready for distribution.
1. Wait for a checkpoint to be available for checkpoint restart.
1. Retrieve the signatures to update the multisig contract (do not update yet).
1. Stop the network.
1. Do not update the multisig contract.
1. Restart the vega network from the checkpoint created earlier.
1. Vega observes the incorrect multisig, and rewards are not paid at the end of the current epoch. (<a name="0073-LIMN-076" href="#0073-LIMN-076">0073-LIMN-076</a>)

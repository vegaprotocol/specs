# Event queue

## Summary

The vega network rely soleley on other network for issueing coin or token used for settlement. Because of this, bridges controlled by the vega network are created on these external chains (at the moment only ethereum ERC-20 are supported).
In order for these bridge to operate properly and for vega to reflect their activity, each validator node embed mecanisms to source, validated and monitor activity on these bridges.

## Guide-level explanation

At the time of writing 4 contracts are being monitored by the network:
- ERC-20 collateral bridge
- staking contract
- vesting contract
- multisig control contract

Every time a method is being called successfully on these contract (for example deposit on the collateral bridge) an `event` is emitted by the smart contract, the validators node will be monitoring all blocks created by ethereum, and be looking for this events, this is sourcing the events.

Once an events have been source by a validator, they will be forwarding it to the rest of the validator under the form of a vega transaction.

Upon reception of the event, and once confirmed it was sent by a legitimate validator node the other validators will then try to find back the transaction on the external chain.

Once all validator have confirmed the event happened on the external chain, the action will be executed on the network (in the case of the deposit, the funds will be deposited into an account).

## Reference-level explanation

### Smart contracts in use

All the smart contract monitored by the validator nodes are defined in the `ethereumConfig` network parameter. As well as the contract added, the creation time of the contract is required there for the very first launch of the network, this is required so the validator node can poll all blocks for active since the creation of the contract.

Later on these information are store in the snapshot state / checkpoint as well as the last sourced block on ethereum to avoid interpreting events twice.

Finally the amount of confirmation expected for ethereum is specified (50 confirmation as in mainnet).

### Event sourcing

Every validators node needs a constant connection to an ethereum archival node. This allow the node to poll for ethereum blocks as they are constructed, and scan for events emitted by the contracts it cares for.

The core node will look for new blocks on ethereum every 10 to 15 seconds. Once a relevant event is found, the block, log index, and transaction hash are extracted from it, and a ChainEvent transaction is contructed then forwarded to the rest of the node through the chain.


Simplified chain event transaction:
```proto
// An event being forwarded to the vega network
// providing information on things happening on other networks
message ChainEvent {
  // The ID of the transaction in which the things happened
  // usually a hash
  string txID = 1;

  oneof event {
    ERC20Event erc20 = 1002;
    ValidatorEvent validator = 1004;
    // more in the future
  }
}

// An event related to an erc20 token
message ERC20Event {
  // Index of the transaction
  uint64 index = 1;
  // The block in which the transaction was added
  uint64 block = 2;

  oneof action {
    ERC20AssetList assetList = 1001;
    ERC20AssetDelist assetDelist = 1002;
    ERC20Deposit deposit = 1003;
    ERC20Withdrawal withdrawal = 1004;
  }
}


// An asset whitelisting for a erc20 token
message ERC20AssetList {
  // The vega network internally ID of the asset
  string vegaAssetID = 1;
}

// An asset blacklisting for a erc20 token
message ERC20AssetDelist {
  // The vega network internally ID of the asset
  string vegaAssetID = 1;
}

// An asset deposit for an erc20 token
message ERC20Deposit {
  // The vega network internally ID of the asset
  string vegaAssetID = 1;
  // The ethereum wallet that initiated the deposit
  string sourceEthereumAddress = 2;
  // The Vega public key of the target vega user
  string targetPartyID = 3;
}

// An asset withdrawal for an erc20 token
message ERC20Withdrawal {
  // The vega network internally ID of the asset
  string vegaAssetID = 1;
  // The party inititing the withdrawal
  string sourcePartyId = 2;
  // The target Ethereum wallet address
  string targetEthereumAddress = 3;
  // The reference nonce used for the transaction
  string referenceNonce = 4;
}
```

### Event validation

Once the chain event is received by validator nodes, routine are started internaly to verify this events. Specifically what the node will do is:
- find the event for the contract address, transaction hash, block and event log.
- ensure this event has not been seen before
- ensure that the number of confirmation have been seen on the network

As soon as the validator nodes have been able to confirm the event, they will be emitting a new transaction in the network to confirm that this event is legitimate and it can be processed.

As soon as the protocol receive 2/3 of votes for the event, action related to this event will be executed (e.g: funding an account in the case of a deposit). The confirmation of each validators are weighted with the validator power.

Example of the node vote transaction:
```proto
// Used when a node votes for validating that a given resource exists or is valid,
// for example, an ERC20 deposit is valid and exists on ethereum.
message NodeVote {
  // Reference, required field.
  string reference = 2;
  // type of NodeVote, also required.
  Type type = 3;
  enum Type {
    // Represents an unspecified or missing value from the input
    TYPE_UNSPECIFIED = 0;
    // A node vote a new stake deposit
    TYPE_STAKE_DEPOSITED = 1;
    // A node vote for a new stake removed event
    TYPE_STAKE_REMOVED = 2;
    // A node vote for new collateral deposited
    TYPE_FUNDS_DEPOSITED = 3;
    // A node vote for a new signer added to the erc20 bridge
    TYPE_SIGNER_ADDED = 4;
    // A node vote for a signer removed from the erc20 bridge
	TYPE_SIGNER_REMOVED = 5;
    // A node vote for a bridge stopped event
    TYPE_BRIDGE_STOPPED = 6;
    // A node vote for a bridge resumed event
    TYPE_BRIDGE_RESUMED = 7;
    // A node vote for a newly listed asset
    TYPE_ASSET_LISTED = 8;
    // A node vote for an asset limits update
    TYPE_LIMITS_UPDATED = 9;
    // A node vote to share the total supply of the staking token
    TYPE_STAKE_TOTAL_SUPPLY = 10;
    // A node vote to update the threshold of the signer set for the multisig contract
    TYPE_SIGNER_THRESHOLD_SET = 11;
    // A node vote to validate a new assert governance proposal
    TYPE_GOVERNANCE_VALIDATE_ASSET = 12;
  }
}
```


## Acceptance Criteria

-- A valid event is processed by vega (<a name="0036-BRIE-001" href="#0036-BRIE-001">0036-BRIE-001</a>)
 - A transacton is successfully executed on the bridge (e.g deposit)
 - A validator node successfully source the event and emit a chain event transaction on the vega chain
 - The others validators successfully validates the event on the ethereum chain and send a node vote on chain
 - The required amount of node vodes, weighted by validator score is received
 - The processing of the event have effect on the network (e.g: for a deposit funds are deposited on an account)
-- A valid duplicated event is processed (<a name="0036-BRIE-002" href="#0036-BRIE-002">0036-BRIE-002</a>)
 - A transacton is successfully executed on the bridge (e.g deposit) and successfully processed by vega
 - A node sends again the chain event after sourcing it
 - The nodes reject this event as duplicated, nothing else happens
-- A invalid event is processed (<a name="0036-BRIE-002" href="#0036-BRIE-002">0036-BRIE-002</a>)
 - A malicious node sends a chain event for a non existing transaction on the bridge
 - The node start validating this event on chain, but cannot find it
 - After a given delay this chain event is rejected, no node votes are being sent by the validators
 - This event have no repercussion on the vega state.

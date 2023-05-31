# Event queue

## Summary

The vega network relies solely on other networks for issuing the of coins or tokens that are used for settlement. Because of this, bridges controlled by the Vega network are created on these external chains (as of the first Alpha Mainnet deployment only ERC-20 tokens are supported via a bridge to the Ethereum chain).

In order for these bridges to operate correctly and for Vega to reflect their activity, each validator node embeds mechanisms to source, validate and monitor activity on these bridges.

## Guide-level explanation

As of the first Alpha Mainnet deployment, four contracts are being monitored by the Vega network:

- ERC-20 collateral bridge
- staking contract
- vesting contract
- multisig control contract

Every time a method is being called successfully on these contracts (for example a deposit on the collateral bridge) an event is emitted by the smart contract. The validator nodes will be monitoring all blocks created by Ethereum, and be looking for this event. This process is the sourcing of events.

Once an event has been sourced by a validator, it will be forwarded to the other validators in the network under the form of a vega transaction.

Upon receipt of the event, and confirmation it was sent by a legitimate validator node, the other validators will then try to find and verify the same event on the external chain.

Once all validators have confirmed the event happened on the external chain, the action will be executed on the network (in the case of the deposit, the funds will be deposited into an account).

## Reference-level explanation

### Smart contracts in use

All the smart contracts monitored by the validator nodes are defined in the `ethereumConfig` network parameter. Along with the contract itself, the creation time of the contract is required for the very first launch of the network. This is required in order for the validator nodes to poll all blocks since the creation of the contract.

Later on in the life of the network, this information is stored in the snapshot state / checkpoint with last sourced block on Ethereum to avoid interpreting events twice.

Finally, the amount of confirmations expected for Ethereum is specified, this is set to 50 confirmation in mainnet.

### Event sourcing

Every validator node needs a constant connection to an Ethereum archival node. This allows the node to poll for Ethereum blocks as they are constructed, and scan for events emitted by the contracts related to the Vega network.

The core node will look for new blocks on Ethereum every 10 to 15 seconds. Once a relevant event is found, the block, log index and transaction hash are extracted from it. A `ChainEvent` transaction is constructed then forwarded to the rest of the nodes through the Vega chain.

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

Once the `ChainEvent` transaction is received by the other validator nodes a routine is started internally to verify the events.

Specifically the nodes will:

- Find the event for the contract address, transaction hash, block and event log.
- Ensure this event has not been seen before
- Ensure that the required number of confirmations has been seen on the network

As soon as the validator nodes confirm the event, they emit a new transaction in the Vega network to confirm the event is legitimate and it can be processed.

As soon as the protocol receive 2/3 of the votes for the event, the corresponding action related to this event will be executed (e.g., funding an account in the case of a deposit). The confirmation of each validator is weighted with the validator power.

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

- A valid event is processed by vega (<a name="0036-BRIE-001" href="#0036-BRIE-001">0036-BRIE-001</a>)
  - A transaction is successfully executed on the bridge (e.g deposit)
  - A validator node successfully source the event and emit a chain event transaction on the vega chain
  - The others validators successfully validates the event on the ethereum chain and send a node vote on chain
  - The required amount of node votes, weighted by validator score is received
  - The processing of the event have effect on the network (e.g: for a deposit funds are deposited on an account)
- A valid duplicated event is processed (<a name="0036-BRIE-002" href="#0036-BRIE-002">0036-BRIE-002</a>)
  - A transaction is successfully executed on the bridge (e.g deposit) and successfully processed by vega
  - A node sends again the chain event after sourcing it
  - The nodes reject this event as duplicated, nothing else happens
- A invalid event is processed (<a name="0036-BRIE-003" href="#0036-BRIE-003">0036-BRIE-003</a>)
  - A malicious node sends a chain event for a non existing transaction on the bridge
  - The node start validating this event on chain, but cannot find it
  - After a given delay this chain event is rejected, no node votes are being sent by the validators
  - This event has no repercussion on the vega state.

Feature name: Event Queue

Start date: 2020-04-09

Specification PR: https://github.com/vegaprotocol/product/pull/271


# Summary
Latency and throughput is of paramount importance to Vega validator nodes, so monitoring various 3rd party (and notably low transaction speed) blockchains and crypto-assets isn’t possible.
To counter this problem we have created an event queue management system.
This event queue allows the standardisation and propagation of transactions from 3rd party asset chains in the Vega event message format.

# Guide-level explanation
Events and transactions are gathered and processed by the Event Queue from a given 3rd party blockchain, and only the ones subscribed to by Vega nodes will be propagated through consensus and then validated by the validator nodes.
This makes the event queue works as a buffer between the slow/complicated world of various blockchains, and the high throughput, low latency of Vega Core.
This message queue will use gRPC to communicate with the Vega network via 3 main functions:
1. `GetSubscribedEventSources` returns a list of smart contract addresses and events that consensus has deemed as a valid source.
1. `PropagateEvent` allows an event queue to send events raised on 3rd party blockchains (deposits, withdrawals, etc) through Vega consensus to ensure an event has been seen by the network. This function must support multiple blockchains as sources of events and multiple sources on a single blockchain (such as multiple deployments of an ERC20 bridge).

   Each validator will individually process and validate the given transaction and process the specified event reported.
1. `GetEventAcceptanceStatus` returns the consensus acceptance status of a requested event. The event queue uses this function to determine if it should attempt to send the event again.

# Reference-level explanation
* The event queue calls `GetSubscribedEventSources` on a Vega node to get the list of subscribed smart contracts
* The event queue gets events from provided smart contract addresses via an Ethereum node
* Event queue filters for specific events it cares about (see `EventType`)
* For each event it calls `GetEventAcceptanceStatus` on a Vega node
* Event queue then creates an `PropagateEventRequest` for each applicable event that has yet to be accepted and submits them to `PropagateEvent` on a Vega validator node
* Vega validators each verify each event against a local (or trusted hosted(?)) Ethereum node
* Consensus agrees and writes event into the Vega chain

# Pseudo-code / Examples

The protobuf of the service:
```proto

service VegaChainEvent {
  rpc PropagateChainEvent(PropagateChainEventRequest) returns (PropagateChainEventResponse);
  rpc GetSubscribedEventSources() returns (GetSubscribedEventSourcesResponse);
  rpc GetEventAcceptanceStatus(GetEventAcceptanceStatusRequest) returns (GetEventAcceptanceStatusResponse);
}

message PropagateChainEventRequest {
  vega.ChainEvent evt = 1;
  string pubKey = 2;
  bytes signature = 3;
}

message PropagateChainEventResponse {
  // Did the event get accepted by the node successfully
  // and forwarded to the network
  bool success = 1;
}

message ChainEvent {
  string txID = 1;

  oneof event {
    ERC20Event erc20 = 1001;
	// etc to support more foregin chains
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

message ERC20AssetList {
  // The vega network internally ID of the asset
  string vegaAssetID = 1;
}

message ERC20AssetDelist {
  // The vega network internally ID of the asset
  string vegaAssetID = 1;
}

message ERC20Deposit {
  // The vega network internally ID of the asset
  string vegaAssetID = 1;
  // The ethereum wallet that initiated the deposit
  string sourceEthereumAddress = 2;
  // The Vega public key of the target vega user
  string targetPartyID = 3;
}

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

message GetSubscribedEventSourcesResponse {
  repeated string subscribed_event_source = 1;
}

message GetEventAcceptanceStatusRequest {
  string transaction_hash = 1;
  uint32 log_index = 2;
}

//can be expanded as needed
enum EventAcceptanceStatus {
  EVENT_ACCEPTANCE_STATUS_UNSPECIFIED = 0;
  EVENT_ACCEPTANCE_STATUS_ACCEPTED = 1;
  EVENT_ACCEPTANCE_STATUS_REJECTED = 2;
}

message GetEventAcceptanceStatusResponse {
  string transaction_hash = 1;
  uint32 log_index = 2;
  EventAcceptanceStatus acceptance_status = 3;
}
```

# Acceptance Criteria
## Event Queue
* Event Queue calls `GetSubscribedEventSources` and successfully parses the response
* Event Queue gathers and filters applicable events from Ethereum node
* Event Queue calls `GetEventAcceptanceStatus` and marks accepted events internally as complete
* Event Queue propagates unaccepted events to Vega node via `PropagateEvent`

## Vega Nodes
* Vega nodes respond to `GetSubscribedEventSources` with a list of valid smart contract events
* Vega nodes accept events submitted to `PropagateEvent` and verifies them against valid Ethereum node
* Vega nodes write events to chain once verified
* Vega nodes respond appropriately to `GetEventAcceptanceStatus`
* Vega nodes verify Event existance and outcomes using local Ethereum node
  * Verify balance changes
  * Verify account identities
  * Verify transaction hashes
* Vega nodes reject invalid events that fail verification in the previous step

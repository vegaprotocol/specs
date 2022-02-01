Feature name: Event Queue

Start date: 2020-04-09

Specification PR: https://github.com/vegaprotocol/product/pull/271


# Summary
Latency and throughput is of paramount importance to Vega validator nodes, so monitoring various 3rd party (and notably low transaction speed) blockchains and crypto-assets isn’t possible.
To counter this problem we have created an event queue management system.
This event queue allows the standardisation and propagation of transactions from 3rd party asset chains in the Vega event message format.

# Guide-level explanation
Events and transactions are gathered and processed by the Event Queue from a given 3rd party blockchain, and only the ones subscribed to by Vega nodes will be propagated through consensus and then validated by the validator nodes.
The Event Queue continually scans local or hosted external blockchain nodes to discover on-chain events that are applicable to Vega. 
Found external blockchain events are then sent to Vega validator nodes. 
This makes the event queue works as a buffer between the slow/complicated world of various blockchains, and the high throughput, low latency of Vega Core.
This message queue will use gRPC to communicate with the Vega network via 3 main functions:
1. `GetSubscribedEventSources` returns a list of smart contract addresses and events that consensus has deemed as a valid source.
1. `PropagateChainEvent` allows an event queue to send events raised on 3rd party blockchains (deposits, withdrawals, etc) through Vega consensus to ensure an event has been seen by the network. This function must support multiple blockchains as sources of events and multiple sources on a single blockchain (such as multiple deployments of an ERC20 bridge).

   Each validator will individually process and validate the given transaction and process the specified event reported using their local chain node (such as Ethereum). 
1. `GetEventAcceptanceStatus` returns the consensus acceptance status of a requested event. The event queue uses this function to determine if it should attempt to send the event again.

# Reference-level explanation
* The event queue calls `GetSubscribedEventSources` on a Vega node to get the list of subscribed smart contracts
* Using configured external blockchain nodes, the Event Queue filters for specific events provided in `GetSubscribedEventSourcesResponse`
* For each event it calls `GetEventAcceptanceStatus` on a Vega node
* Event Queue then creates an `PropagateChainEventRequest` for each applicable event that has yet to be accepted and submits them to `PropagateChainEvent` on a Vega validator node
* Vega validators each verify each event against local external blockchain nodes as the event is gossiped 
* Consensus agrees and writes event into the Vega chain

# Pseudo-code / Examples

The protobuf of the service:
```proto

service trading{
  /*....*/
  rpc PropagateChainEvent(PropagateChainEventRequest) returns (PropagateChainEventResponse);
  rpc GetSubscribedEventSources() returns (GetSubscribedEventSourcesResponse);
  rpc GetEventAcceptanceStatus(GetEventAcceptanceStatusRequest) returns (GetEventAcceptanceStatusResponse);
  /*....*/
}

message GetSubscribedEventSourcesResponse {
  repeated string subscribed_event_source = 1;
}


message PropagateChainEventRequest {
  // The event
  vega.ChainEvent evt = 1;
  string pubKey = 2;
  bytes signature = 3;
}

// The response for a new event sent to vega
message PropagateChainEventResponse {
  // Did the event get accepted by the node successfully
  bool success = 1;
}


// An event being forwarded to the vega network
// providing information on things happening on other networks
message ChainEvent {
  // The ID of the transaction in which the things happened
  // usually a hash
  string txID = 1;

  oneof event {
    BuiltinAssetEvent builtin = 1001;
    ERC20Event erc20 = 1002;
    BTCEvent btc = 1003;
    ValidatorEvent validator = 1004;
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
* Event Queue calls `GetSubscribedEventSources` and successfully parses the response (<a name="0036-BRIE-001" href="#0036-BRIE-001">0036-BRIE-001</a>)
* Event Queue connects to a configured local or hosted external blockchain node (<a name="0036-BRIE-002" href="#0036-BRIE-002">0036-BRIE-002</a>)
* Event Queue gathers and filters applicable events from configured external blockchain node (<a name="0036-BRIE-003" href="#0036-BRIE-003">0036-BRIE-003</a>)
* Event Queue calls `GetEventAcceptanceStatus` and marks accepted events internally as complete (<a name="0036-BRIE-004" href="#0036-BRIE-004">0036-BRIE-004</a>)
* Event Queue propagates unaccepted events to Vega node via `PropagateEvent` (<a name="0036-BRIE-005" href="#0036-BRIE-005">0036-BRIE-005</a>)
* Event Queue retries sending events that have gone too long without being accepted  (<a name="0036-BRIE-006" href="#0036-BRIE-006">0036-BRIE-006</a>)

## Vega Nodes
* Vega nodes respond to `GetSubscribedEventSources` with a list of valid smart contract events (<a name="0036-BRIE-007" href="#0036-BRIE-007">0036-BRIE-007</a>)
* Vega nodes accept events submitted to `PropagateEvent` and verifies them against configured external blockchain node (<a name="0036-BRIE-008" href="#0036-BRIE-008">0036-BRIE-008</a>)
* Vega nodes write events to chain once verified (<a name="0036-BRIE-009" href="#0036-BRIE-009">0036-BRIE-009</a>)
* Vega nodes respond appropriately to `GetEventAcceptanceStatus` (<a name="0036-BRIE-010" href="#0036-BRIE-010">0036-BRIE-010</a>)
* Vega nodes verify Event existence and outcomes using local Ethereum node
  * Verify balance changes (<a name="0036-BRIE-011" href="#0036-BRIE-011">0036-BRIE-011</a>)
  * Verify account identities (<a name="0036-BRIE-012" href="#0036-BRIE-012">0036-BRIE-012</a>)
  * Verify transaction hashes (<a name="0036-BRIE-013" href="#0036-BRIE-013">0036-BRIE-013</a>)
* Vega nodes reject invalid events that fail verification in the previous step (<a name="0036-BRIE-014" href="#0036-BRIE-014">0036-BRIE-014</a>)
* Vega nodes responds appropriately to event triggers
  * Users are credited on deposit (see also [0013-ACCT](./0013-ACCT-accounts.md))  (<a name="0036-BRIE-015" href="#0036-BRIE-015">0036-BRIE-015</a>)

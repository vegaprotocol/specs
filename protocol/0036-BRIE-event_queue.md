Feature name: Event Queue

Start date: 2020-04-09

Specification PR: https://github.com/vegaprotocol/specs-internal/pull/271


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

// An event related to an ERC20 token
message ERC20Event {
  // Index of the log in the transaction
  uint64 index = 1;
  // The block in which the transaction was added
  uint64 block = 2;
  // The action
  oneof action {
    // List an ERC20 asset
    ERC20AssetList asset_list = 1001;
    // De-list an ERC20 asset
    ERC20AssetDelist asset_delist = 1002;
    // Deposit ERC20 asset
    ERC20Deposit deposit = 1003;
    // Withdraw ERC20 asset
    ERC20Withdrawal withdrawal = 1004;
    // Update an ERC20 asset
    ERC20AssetLimitsUpdated asset_limits_updated = 1005;
    // Update withdraw delay
    ERC20BridgeWithdrawDelay withdraw_delay_set = 1006;
    // Erc20 Bridge has been stopped
    ERC20BridgeStopped = 1007;
    // ERC20 Bridge has been resumed
    ERC20BridgeResumed = 1008;
  }
}

// An asset allow-listing for an ERC20 token
message ERC20AssetList {
  // The Vega network internal identifier of the asset
  string vega_asset_id = 1;
  // The ethereum address of the asset
  string asset_source = 2;
}

// An asset deny-listing for an ERC20 token
message ERC20AssetDelist {
  // The Vega network internal identifier of the asset
  string vega_asset_id = 1;
}

message ERC20AssetLimitsUpdated {
  // The Vega network internal identifier of the asset
  string vega_asset_id = 1;
  // The Ethereum wallet that initiated the deposit
  string source_ethereum_address = 2;
  // The updated lifetime limits
  string lifetime_limits = 3;
  // The updated withdraw threshold
  string withdraw_threshold = 4;
}

// An asset deposit for an ERC20 token
message ERC20Deposit {
  // The vega network internal identifier of the asset
  string vega_asset_id = 1;
  // The Ethereum wallet that initiated the deposit
  string source_ethereum_address = 2;
  // The Vega party identifier (pub-key) which is the target of the deposit
  string target_party_id = 3;
  // The amount to be deposited
  string amount = 4;
}

// An asset withdrawal for an ERC20 token
message ERC20Withdrawal {
  // The Vega network internal identifier of the asset
  string vega_asset_id = 1;
  // The target Ethereum wallet address
  string target_ethereum_address = 2;
  // The reference nonce used for the transaction
  string reference_nonce = 3;
}

// The bridge delay was set
message ERC20BridgeWithdrawDelay {
  string withdraw_delay = 1
}

// The ERC20 bridge was stopped
message ERC20BridgeStopped {
}

// The ERC20 bridge was resumed
message ERC20BridgeResumed {
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

## Events
The Event Queue must recognize and propagate the following events emitted from the external blockchain node
```c  
    event Asset_Withdrawn(address indexed user_address, address indexed asset_source, uint256 amount, uint256 nonce);
    event Asset_Deposited(
        address indexed user_address,
        address indexed asset_source,
        uint256 amount,
        bytes32 vega_public_key
    );
    event Asset_Listed(address indexed asset_source, bytes32 indexed vega_asset_id, uint256 nonce);
    event Asset_Removed(address indexed asset_source, uint256 nonce);
    event Asset_Limits_Updated(address indexed asset_source, uint256 lifetime_limit, uint256 withdraw_threshold);
    event Bridge_Withdraw_Delay_Set(uint256 withdraw_delay);
    event Bridge_Stopped();
    event Bridge_Resumed();
```

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

Feature name: feature-name
Start date: YYYY-MM-DD
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests


# Summary
Latency and throughput is of paramount importance to Vega validator nodes, so monitoring various 3rd party (and notably low transaction speed) blockchains and crypto-assets isn’t possible. To counter this problem we have created an event queue management system. This event queue uses a set of asset busses that allow the standardization, storing and propagation of transactions from 3rd party asset chains into the Vega oracle format. Once the events and transactions are gathered and processed, only the ones important to our system will be propagated through consensus and thus need to be validated by the validator node. This makes the event queue work as a buffer between the slow/complicated world of various blockchains, and the high throughput, low latency of Vega Core.
This message queue will use grpc to communicate with the Vega network via 2 main functions: Propagate_Oracle_Event and Oracle_Event_Acceptance_Status. The first: Propagate_Oracle_Event  allows an event queue to send oracle events (events, transactions, setting changes, etc) through Vega consensus to ensure an event has been seen by the network. Each validator will individually process and validate the given transaction but only parse for the specified event reported.
The second function, Oracle_Event_Acceptance_Status, returns the consensus acceptance status of a given transaction/event. The event queue uses this function to determine if it should attempt to send the event again.

# Guide-level explanation
Explain the specification as if it was already included and you are explaining it to another developer working on Vega. This generally means:
- Introducing new named concepts
- Explaining the features, providing some simple high level examples
- If applicable, provide migration guidance

# Reference-level explanation
This is the main portion of the specification. Break it up as required.

# Pseudo-code / Examples
```go
enum Asset_Event_Types {
    UNKNOWN = 0;
    Asset_Deposited=1;
    Asset_Withdrawn=2;
    Asset_Listed=3;
    Asset_Delisted=4;
    Deposit_Minimum_Set=5;
}
```

```go
message Asset_Event_Propagation_Request {
        string oracle_source = 1; //address of asset
        string asset_source = 2; //asset source according to that oracle
        string asset_id = 3; //ID of asset specific to that asset_source
        Event_Types event_type = 4; // enumerated event type
        string source_party_id = 5; // source ethereum address 20 bytes hex preceded by 0x or other party ID of user/contract/system this pertains to
        string target_party_id = 6; // provided public key on party to target the event to
        string transaction_hash = 7; // tx hash in question that must lead us to parseable data based on 'event_type'
        uint32 log_index = 8; // if the transaction outputs multiple events to the log, this tells you which one
        string event_name = 9; // friendly name of event specific to bridge/source
        uint32 block_number = 10; // block number of source chain the event occurred 
}
```

# Acceptance Criteria
Check list of statements that need to met for the feature to be considered correctly implemented.
* 


# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.
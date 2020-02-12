Feature name: feature-name
Start date: YYYY-MM-DD
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Acceptance Criteria
Check list of statements that need to met for the feature to be considered correctly implemented.

# Summary
In order to integrate Vega with various external blockchains and oracles, we’ve determined that a set of “bridge” smart contracts along with an ‘event queue’ process to find and propagate applicable on-chain events is necessary for the deposit and withdrawal of funds/assets from Vega. This, collectively, is named the Vega Ramp as it is the on- and off-ramp of all assets regardless of chain of origin.


# Guide-level explanation
Explain the specification as if it was already included and you are explaining it to another developer working on Vega. This generally means:
- Introducing new named concepts
- Explaining the features, providing some simple high level examples
- If applicable, provide migration guidance

# Reference-level explanation
This is the main portion of the specification. Break it up as required.

# Pseudo-code / Examples
```
enum Event_Types {
    UNKNOWN = 0;
    Asset_Made_Available=1;
    Asset_Deposited=2;
    Asset_Withdrawn=3;
    Transaction=4;
    Settings_Change=5;
    Ballot_Proposed=7;
    Ballot_Cast=8;
    Price_Updated=9;
    Asset_Listed=10;
    Asset_Delisted=11;
    //TODO: add more
}
```

```
message Oracle_Event_Propagation_Request {
        string oracle_source = 1; //address of oracle
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

# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.
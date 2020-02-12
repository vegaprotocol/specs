Feature name: feature-name
Start date: YYYY-MM-DD
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Acceptance Criteria
Check list of statements that need to met for the feature to be considered correctly implemented.

# Summary
In order to integrate Vega with various external blockchains and oracles, we’ve determined that a set of “bridge” smart contracts along with an ‘event queue’ process to find and propagate applicable on-chain events is necessary for the deposit and withdrawal of funds/assets from Vega. This, collectively, is named the Vega Ramp as it is the on- and off-ramp of all assets regardless of chain of origin.


# Guide-level explanation
## On Chain Event Recording
In order to enable decentralized and secure depositing and withdrawal of funds, we have created a series of “bridge” smart contracts. These bridges each target a specific asset type, such as ETH or ERC20 tokens, and expose simple functionality to allow the Vega network to accept deposits, hold, and then release assets as needed. This immutably records all deposits and withdrawals for all of the assets that Vega markets use.
Each bridge contains 3 primary functions and emits 3 primary events, each tailored to the asset type. They are deposit, make available, and withdraw and the corresponding events of available, deposited, withdrawn. Deposit is run by a user or process and ensures that the asset is stored safely on-contract and then emits the deposited event. Make available is run by the Vega network and makes the given amount of the asset available to a user for withdrawal, this emits the available event. The withdrawal function is run by the user or process credited by “make available” to withdraw the asset from the contract.
Each bridge limits the ability to make more assets available to users than it has on-contract and has already promised. This means that even in the event of a compromise, the damage is limited.


## Off Chain Event Post Processing and Propagation
Latency and throughput is of paramount importance to Vega validator nodes, so monitoring various 3rd party (and notably low transaction speed) blockchains and crypto-assets isn’t possible. To counter this problem we have created an event queue management system. This event queue uses a set of asset busses that allow the standardization, storing and propagation of transactions from 3rd party asset chains into the Vega oracle format. Once the events and transactions are gathered and processed, only the ones important to our system will be propagated through consensus and thus need to be validated by the validator node. This makes the event queue work as a buffer between the slow/complicated world of various blockchains, and the high throughput, low latency of Vega Core.
This message queue will use grpc to communicate with the Vega network via 2 main functions: Propagate_Oracle_Event and Oracle_Event_Acceptance_Status. The first: Propagate_Oracle_Event  allows an event queue to send oracle events (events, transactions, setting changes, etc) through Vega consensus to ensure an event has been seen by the network. Each validator will individually process and validate the given transaction but only parse for the specified event reported.
The second function, Oracle_Event_Acceptance_Status, returns the consensus acceptance status of a given transaction/event. The event queue uses this function to determine if it should attempt to send the event again.


# Reference-level explanation
This is the main portion of the specification. Break it up as required.


[![](https://mermaid.ink/img/eyJjb2RlIjoiZ3JhcGggVERcbiAgQVtVc2VyXS0tPnxSdW5zIERlcG9zaXQgZnVuY3Rpb24gd2l0aCBWZWdhIHB1YmxpYyBrZXl8QlxuICBCW0JyaWRnZSBTbWFydCBDb250cmFjdF0gLS0-fEVtaXRzIERlcG9zaXQgZXZlbnR8Q1xuICBDW0V2ZW50IFF1ZXVlXS0tPnxGaWx0ZXJzIGFuZCBmb3J3YXJkcyBhcHBsaWNhYmxlIGV2ZW50fERcbiAgRFtWZWdhIENvbnNlbnN1c10tLT58Q2hlY2tzIGV2ZW50IGFjY2VwdGFuY2Ugc3RhdHVzfENcbiAgRC0tPnxSdW5zIE1ha2UgQXZhaWxhYmxlIGZ1bmN0aW9uIG9uIGFzc2V0IHdpdGhkcmF3YWx8QlxuICBBLS0-fFJ1bnMgV2l0aGRyYXdhbCBmdW5jdGlvbiB0byByZWNlaXZlIGF2YWlsYWJsZSBmdW5kc3xCXG4gIFxuXHRcdFx0XHRcdCIsIm1lcm1haWQiOnsidGhlbWUiOiJkZWZhdWx0In0sInVwZGF0ZUVkaXRvciI6ZmFsc2V9)](https://mermaid-js.github.io/mermaid-live-editor/#/edit/eyJjb2RlIjoiZ3JhcGggVERcbiAgQVtVc2VyXS0tPnxSdW5zIERlcG9zaXQgZnVuY3Rpb24gd2l0aCBWZWdhIHB1YmxpYyBrZXl8QlxuICBCW0JyaWRnZSBTbWFydCBDb250cmFjdF0gLS0-fEVtaXRzIERlcG9zaXQgZXZlbnR8Q1xuICBDW0V2ZW50IFF1ZXVlXS0tPnxGaWx0ZXJzIGFuZCBmb3J3YXJkcyBhcHBsaWNhYmxlIGV2ZW50fERcbiAgRFtWZWdhIENvbnNlbnN1c10tLT58Q2hlY2tzIGV2ZW50IGFjY2VwdGFuY2Ugc3RhdHVzfENcbiAgRC0tPnxSdW5zIE1ha2UgQXZhaWxhYmxlIGZ1bmN0aW9uIG9uIGFzc2V0IHdpdGhkcmF3YWx8QlxuICBBLS0-fFJ1bnMgV2l0aGRyYXdhbCBmdW5jdGlvbiB0byByZWNlaXZlIGF2YWlsYWJsZSBmdW5kc3xCXG4gIFxuXHRcdFx0XHRcdCIsIm1lcm1haWQiOnsidGhlbWUiOiJkZWZhdWx0In0sInVwZGF0ZUVkaXRvciI6ZmFsc2V9)

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

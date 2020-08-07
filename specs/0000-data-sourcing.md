NOTE: this is a draft/WIP from a file on my local machine for visibility

# Data sourcing (aka oracles)

## Principles and summary

The goals of Vega Protocol w.r.t. data sourcing are threefold:

1. To support a wide range of third party data sourcing solutions rather than to implement a complete solution in house.
2. To be a source of definitive and final data to Products and Risk Models that can be trusted by market participants.
3. To build simple, generic and anti-fragile data sourcing functionality, and not to introduce third party dependencies.

As a result: 

- Vega will not integrate directly with specific oracle/data providers at the protocol level. Rather, we provide APIs and protocol capabilities to support a wide range of data sourcing styles
- Data sources must be able to provide a measure of finality that is either definitive or a configurable threshold on a probabilistic measure (‘upstream finality’).
- Once upstream finality is achieved, Vega may provide optional mechanisms for querying, verification or dispute resolution that are independent of the source.
- Vega will allow composition of data sources, including those with disparate sources, and may provide a variety of methods to aggregate and filter/validate data provided by each.

In order to close a given market in Vega, an oracle must be queried to provide closing data for that market. 
Often this data looks like:
 ```json
{
    assetId:"0f234167a...", //target settlement instrument VegaID
    timestamp:1596761519, //timestamp of the report (must be within a specifid range as configured by a market) //<---  TODO SPEC THIS
    price:1234.2512,            
}
 ```
Sometimes however, the data required to settle an oracle is based on more complex information:
```json
{
    timestamp:1596761519, //timestamp of the report (must be within a specifid range as configured by a market) //<---  TODO SPEC THIS
    temperatures:[42, 38, 36]
}
``` 
 To accommodate the multitude of ways that markets can be settled, we've adopted a key value pair-based data sourcing system:
 
 ```proto

message KeyValuePair {
   string key = 1;
   string value = 2;
}

message OracleEvent {
    ...
    repeated KeyValuePair payload;
    ***
}
```
 So the above examples would be:
 ```proto
    payload [
        { key = "assetId", value = "0f234167a..." },
        { key = "timestamp", value = 1596761519 },
        { key = "price", value = 1234.2512 }
    ]
 ```
 and 
 ```proto
    payload [
        { key = "timestamp", value = 1596761519 },
        { key = "temperatures", value = [42, 38, 36] }
    ]
```
 
 [TODO fix that code ^]
 
 
 In all cases they will need to be signed by the designated signer, this signer can come in many forms:
 * Ethereum oracle (Chainlink, Band Protocol, etc) signed transaction
 * API signed by the SSL of 
 * Apointed Vega user
 * Etc
 


[TODO Add bit about how traditional markets settle things]


## Data sourcing functionality
We define several classes of data source with varying complexity of functionality. It is expected that the simplest will be implemented first.
[TODO, better intro]

### Native Data Source 

**NOTE: This is the only version available in testnet**

Given that there are a large number of possible products and markets on Vega that use non-crypto sources of pricing a given underlying, we offer a Native Data Source underlying. 
This Native Data Source (NDS) is typically a price submitted and attested to by a party in Vega. In initial markets on Vega (and beyond) this user submits the price at market expiry.
Data is supplied through a transaction being posted directly on the Vega network that is signed by one (or more) of the valid signers for that specific data source.

Note: With this type of oracle there’s no incentive in the Vega data source system, you’re trusting the keyholder(s) at settlement.

[TODO: review PROTO below]
```protobuf
message NativeDataSource {
    bytes32 NativeDataSourceId = 1;
    bytes32 underlyingId = 2;  
    bytes23 settlementAssetId = 3;   
    uint max_age =4; //max difference between report timestamp and market expiry (optional?)  
    uint reportSignerThreshold =5; // signers required 
    bytes[] signers = 5; //public keys of signers
    //TODO ?
} 

NativeDataSourceReportRequest {
    message NDSReport {
        bytes32 NativeDataSourceId = 1001;
        uint(float?) price = 1002;  //price in specified settlement asset
        uint timestamp = 1003; //timestamp of provided price
    }
    NDSReport report = 1;
    byte[] signature = 2; // the report, signed    
}
```

### API Data Source
A data payload that provably came from (and signed by) a "Trusted API".
[TODO: justification of why this would be acceptible: SSL and server reputation, see notes]


### External Blockchain Data Source
```proto

//TODO Jeremy Please Review

service trading {
    ...
  // chain events
  rpc PropagateChainEvent(PropagateChainEventRequest) returns (PropagateChainEventResponse);
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

message ChainEvent {
  // The ID of the transaction in which the things happened
  // usually a hash
  string txID = 1;
    
  oneof event {
    ...
    OracleEvent
  }
}

message KeyValuePair {
   string key = 1;
   string value = 2;
}

message OracleEvent {
    string[] signers;
    repeated KeyValuePair payload;
    uint timestamp;
    oneof oracleEventMetadata {
        BuiltinOracleEvent builtin;
        ChainlinkOracleEvent chainlink;
        BandProtocolEvent band;
        APIOracleEvent api;
    }
}

message BuiltinOracleEvent { 
}

message ChainlinkOracleEvent {
  // Index of the transaction
  uint64 index = 1;  

  // The block in which the transaction was added
  uint64 block = 2;
  string vegaOracleId = 3;
}

message BandProtocolEvent {
  // Index of the transaction
  uint64 index = 1;  

  // The block in which the transaction was added
  uint64 block = 2;  
}
message APIOracleEventSource {      
}


message Oracle {
    string[] expectedSigners;
    repeated KeyValuePair expectedPayload;
    uint targetTime;
    uint timeSlippage;//max time that timestamp can differ from targetTime and still be valid
    string vegaOracleId;   
    
    oneof oracleSource {
        BuiltinOracleEventSource builtin;
        ChainlinkOracleEventSource chainlink; //chain specific config TODO
        BandProtocolEventSource band;
        APIOracleEventSource api;
    }
}
```
Each Oracle Queue will connect to either hosted blockchain nodes or local blockchain nodes in order to find the subscribed [TODO] oracle events for a given blockchain.
Once propagated through the Vega API to a Vega validator node, the validator node will connect to its applicable local blockchain node to validate that the provided event did, in fact, happen as far as it can see locally. 
This message is then gossiped to other Vega validator nodes which will do the same validation process.

### Internal observation

A data source can be made of a given parameter from within Vega itself, be it number of validators, or the current price of a given market.

[TODO, is this true? Can we do this? ] 


### Composite data sources (Also not required for v1)

Vega will also provide a number of functions to compose together combinations of defined data sources of any type, or even other composed sources, such as:

- Average multiple sources (option to reject outliers)
- Subject a wrapped source to an on-chain vote
- Require precise agreement from m of n separate independent sources (different from m of n signers on a native source)
- ...other features that allow for higher robustness, etc....
[TODO, think up more]


## Oracle Failure Mitigation
To mitigate the risk of a given data source going rogue, Vega has developed a number of safeguards to ensure the greatest flexibility of the network to deal with threats as they occour.
[TODO blab about oracle problem]


### Changing oracle sources
[TODO: "if risk too high, need better oracles"]
See: [TODO Governance]

### Contesting Data Source Reports
Vega provides a mechanism to dispute reported oracle prices/results.

[TODO]


## Oracle Queue 
[TODO]

[TODO, maybe move Oracle Queue to own spec?]
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


Traditional futures markets are settled when the market expires by using trusted individuals as pricing oracles.
These individuals are responsible to report the prices accuratly and without conflict of interest.
$11.6 trillion anually is settled this way and there is an infrastructure of rules, regulations, and reputation to ensure it's accuracy.
Vega allows for the use of these same oracles and many others to ensure accuracy and manipulation resistance. 
Using Vega's composite oracles, products can be made by combining centralized authority and decentralized oracles to obtain the most accurate price for a given market. 


## Data sourcing functionality
In order to close a given market in Vega, an oracle must be queried to provide closing data for that market. 

Often this data looks like:
 ```proto
{
    assetId = "0f234167a...", //target settlement instrument VegaID
    timestamp = 1596761519, //timestamp of the report (must be within a specifid range as configured by a market)
    price = 1234.2512
}
 ```
Sometimes however, the data required to settle an oracle is based on more complex information:
```proto
{
    timestamp = 1596761519, //timestamp of the report (must be within a specifid range as configured by a market)
    temperatures = [42, 38, 36]
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
 
 ### Signers
 In all cases they will need to be signed by the designated signer, this signer can come in many forms:
 * Ethereum oracle (Chainlink, Band Protocol, etc) signed transaction
 * API signed by the SSL of 
 * Apointed Vega user
 * Etc
 
 In all cases, there will be 1 or more validated signers assigned to the data source/oracle. 
 When the number of signers is greater than 1, a threshold will be required to set the minimum number of signers required to submit a report.   
 
 ### Timestamps
 In all cases, Oracle reports will need to be timestamped and this timestamp must be within a specific time of the configured target time. This time slippage is also configurable as part of the oracle.
 
 
### General Pattern 
  
```proto
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
    uint signerThreshold;
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

## Data Source Types
We define several classes of data sources with varying complexity of functionality. It is expected that the simplest will be implemented first.

### Native Data Source 

**NOTE: This is the only version available in testnet**

Given that there are a large number of possible products and markets on Vega that use non-crypto sources of pricing a given underlying, we offer a Native Data Source underlying. 
This Native Data Source (NDS) is typically a price submitted and attested to by a party in Vega. In initial markets on Vega (and beyond) this user submits the price at market expiry.
Data is supplied through a transaction being posted directly on the Vega network that is signed by one (or more) of the valid signers for that specific data source.

Note: With this type of oracle there’s no incentive in the Vega data source system, you’re trusting the keyholder(s) at settlement.

[TODO: review PROTO below]
```protobuf

message BuiltinOracleEvent { 
}

 message BuiltinOracleEventSource {
  }

```

### API Data Source
A data payload that provably came from (and signed by) a "Trusted API".
[TODO: justification of why this would be acceptable: SSL and server reputation, see notes]



```protobuf
message APIOracleEvent { 
}
message APIOracleEventSource {
}
```


### External Blockchain Data Source

Each Oracle Queue will connect to either hosted blockchain nodes or local blockchain nodes in order to find the subscribed [TODO] oracle events for a given blockchain.
Once propagated through the Vega API to a Vega validator node, the validator node will connect to its applicable local blockchain node to validate that the provided event did, in fact, happen as far as it can see locally. 
This message is then gossiped to other Vega validator nodes which will do the same validation process.

```protobuf
message ExternalBlockchainOracleEvent { 
}
message ExternalBlockchainOracleEventSource {
}
```


### Internal observation
A data source can be made of a given parameter from within Vega itself, be it number of validators, or the current price of a given market.

* a futures market on the POS yield returned to validators
* derivatives on a market’s fee level
* derivatives on the network stats (tx per second, worst 1% block latency)

in fact, we could maybe structure some bug bounties by launching markets that pay off depending on number of x-level bugs found

Any data in the core that’s deterministic could be used directly as an oracle

[TODO clean that up ^]

```protobuf
message InternalOracleEvent { 
}
message InternalOracleEventSource {
}
```




### Composite data sources (Also not required for v1)

Vega will also provide a number of functions to compose together combinations of defined data sources of any type, or even other composed sources, such as:

- Average multiple sources (option to reject outliers)
- Subject a wrapped source to an on-chain vote
- Require precise agreement from m of n separate independent sources (different from m of n signers on a native source)
- ...other features that allow for higher robustness, etc....

mix across classes and platforms of oracles...

m of n: definition lists n oracle definitions, can each by any type of oracle (including other composites), incoming data must be supported (signed, emitted, whatever) by at least m out of the n. Could be as simple as same message has to be signed by at least say 4 of 7 keys, or used to combine other types or composites.
aggregations:  i.e. take n other oracles and discard outliers by some rule (e,g. further than x% from mean/median) than combine the rest (e.g. take the mean or median)
disputable: takes an input oracle (again can be any of the composite types, a delay time, and some rules (i.e. who can dispute, min participation and “win rate” for dispute votes - like governance now in Vega). When the oracle emits a value Vega waits the required time and if no valid dispute occurs the disputable oracle emits the value too but if the threshold for dispute is met a governance process of accepting proposals (can be any valid oracle including composites) and allowing them to be voted on occurs to decide the eventually emitted value

[TODO, clean this up ^]


## Oracle Failure Mitigation
To mitigate the risk of a given data source going rogue, Vega has developed a number of safeguards to ensure the greatest flexibility of the network to deal with threats as they occur.
[TODO blab about oracle problem]

### Changing oracle sources
Oracles may get compromised, shut down, change location/certificates, or otherwise become too risky to use alone before a market has expired. 
To mitigate these risks, a governance can change oracle parameters. To do this, see [TODO Governance]
 
This governance vote is open to all participants in the market, provided they have a balance above a threshold of value (configurable). 
These votes will be and weighted by value in the market and then weighted against market maker votes and network governance voters.  

### Contesting Data Source Reports
Vega provides a mechanism to dispute reported oracle prices/results.

Unlike the rest of Vega, to submit a complaint to contest a data source result a user must be involved in the market being contested.
Both market makers and market participants may contest the results of an oracle if they have more than a threshold of the market's value. 
This limitation is to cut down on spamming and sybil attacks.

To contest the process, a halt market vote will be submitted to governance. 
Provided the user has enough stake in the market, the vote will be put out to governance.
Once a halt market vote has been sucessful, the market is locked down and all assets frozen until a `release market` command is voted through governance.
While halted, the oracle can be changed by another governance vote. Other market parameters can be updated during this time as well.

The contest process will start automatically if, upon expiry, the oracle is unavailable. 
Again, during this time, oracle changes and other configuration governance will be available to Vega governance holders, Market Makers, and Participants in the given market.

## Oracle Queue 
[TODO]

[TODO, maybe move Oracle Queue to own spec?]

## External Vega Oracles
Any value that is within the Vega network and visible to all the validators can be submitted to external blockchain oracles as a price provider for the wider DeFi space.
These oracles often take the form of smart contracts on blockchains like Ethereum, but can also be made available on blockchains which allow key value pair storage such as bitcoin or stellar.

[TODO: external oracle spec]
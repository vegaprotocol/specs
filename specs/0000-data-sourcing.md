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


## Data sourcing functionality

We define several classes of data source with varying complexity of functionality. It is expected that the simplest will be implemented first.

### Native Data Source 

**NOTE: This is the only version available in testnet**

Given that there are a large number of possible products and markets on Vega that use non-crypto sources of pricing a given underlying, we offer a Native Data Source underlying. 
This Native Data Source (NDS) is typically a price submitted and attested to by a party in Vega. In initial markets on Vega (and beyond) this user submits the price at market expiry.
Data is supplied through a transaction being posted directly on the Vega network that is signed by one (or more) of the valid signers for that specific data source.

[TODO] how does incentivisation to be honest work?
[TODO] how does disagreement work?


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





### Remote simplex data sources 

Data sources in which Vega reads signed data from another source (i.e. transaction or event on Ethereum, etc.). Generally this would be another blockchain with which Vega has an integration, directly or through an inter-blockchain protocol.

From a technical perspective this could also include, for example, other sources to which nodes will have access, such as an HTTP resource, however it is suspected that supporting this might be a bad idea, or at least one requiring significant caution.

Specification: type (e.g. ‘Ethereum event’, ‘bitcoin transaction’, whatever), type specific details (e.g. contract address, method or event name, etc.), valid signers.

Data format: [TODO: design this more] <dependent on type> (data consumers will likely describe the subset of data they reference with a string/key selector)

Implementation: nodes will be running or have access to trusted source of the remote system (chain), they will post the signed (by the original creator) transaction data from the remote source in a transaction. 

NB: this may be a variant of the native data source type, or may even be able to be the same transaction if we’re lucky, in which case only reading the host chain is necessary.

NB2: Instead of the remote source, each Vega node can sign the data as a ‘witness’ in which case Vega requires a quorum (based on stake) of witnesses to accept the data. This would be true in the case of a source like an HTTP server, manual observation, or where the signer isn’t trusted. 


### Remote duplex data sources (FUTURE! Not required for v1)

[TODO: design and write this spec] 

This future spec will cover data sources that, for instance, apply a levy on fees in the market(s) they are used in in order to remunerate providers.

Good test case for the design of this might be UMA’s planned oracle.


### Composite data sources (Also not required for v1)

Vega will also provide a number of functions to compose together data sources of any type, or even other composed sources, such as:

- Average multiple sources (option to reject outliers)
- Subject a wrapped source to an on-chain vote
- Require precise agreement from m of n separate independent sources (different from m of n signers on a native source)
- ...other features that allow for higher robustness, etc....

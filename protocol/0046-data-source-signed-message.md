# [Data Source](./0045-data-sourcing.md): Signed message

Signed message data sources are the first external data source to be support by Vega. See the [Data Sourcing spec](./0045-data-sourcing.md) for more information on data sources in general and the data source framework.

Signed message data sources introduce a Vega transaction that represents a data result that is validated by ensuring it is signed by one of a set of public keys provided as part of the data source definition. Note the data supplied by can be used when [settling a market at expiry](./0002-settlement.md) and in the future for any other purpose that requires a data source (such as risk or mark to market functionality), and as inputs to compounds/aggregate data sources.

This spec adds:
- a transaction that allows arbitrary signed data to be submitted to the Vega blockchain (creating a stream of data that can be matched against a data source definition or discarded if not matched)
- a way to define a data source that that validates these messages against the predefined set of allowable public keys and emits the data received by such a stream 

Data can be submitted at any time. Not all data provided by the source needs to be used by a given consumer as the stream can be an input to a [filter data source definition](./0047-data-source-filter.md) that will emit only wanted values, allowing a single stream of data from a signer to supply, for example, many markets.

For instance, the Coinbase oracle API provides a stream of signed messages for many different crypto prices, so for one source we could be receiving many messages that aren't used by any given market, for instance if someone set a bot to submit the latest Coinbase oracle signed messages to the Vega chain once per hour. Note it is an explicit goal of this functionality that the signed data made available by the Coinbase oracle can be submitted as a data transaction and validated as a signed message data source *against Coinbase's public key* (rather than the pubkey of the submitter). That is, it should only be necessary to trust Coinbase.

Note: With this type of oracle there’s no incentive in the Vega data source system, you’re trusting the keyholder(s) and any modifiers or verification applied through the [data source framework](./0045-data-sourcing.md) at settlement.

*NOTE: This is the only external oracle available initially in Vega, and initially requires only one of the specified keys to sign and submit the data transaction. This means that initially it will only be possible to construct external oracles on Vega in which one or more third party entities/systems must be trusted. This will change with modifiers that allow combinations of data sources, verification of data stream via governance votes, and data sources that bridge to events included on other blockchains.*


## Defining the data source

### Parameters 

A data source must define:

- Public keys (and key algorithm to be used if required) that can sign and submit values for this oracle
- Type of data to be supplied in the transaction. Initially we should support the following types:
    - A simple native Vega transaction (i.e. protobuf message) containing one or more key/value pairs of data fields with values in the types allowable in the main oracle spec (keys are strings) 
    - ABI encoded encoded data. Specifically, we want to be able to support at least the OpenOracle standard by this method 

Note: that as a public key may provide many messages, a [filter](./0047-data-source-filter.md) is likely to be needed to extract the required message, and a field select would be used to extract the required field ('price' or 'temperature', etc.)


### Examples:

Data source for a public key that will only send one transaction containing a prices for several markets and therefore doesn't need to be filtered, but the correct value does need to be extracted:

```
// emits 1503.42 if 0xBLAHBLAH submits { ETHUSD: 1503.42, BTCUSD: 80123.45 } 
select { field: 'ETHUSD', data: signed_message: { pubkey=0xBLAHBLAH } }
```

Data source for a public key that will send multiple transactions containing prices for several markets and must be [filtered](./0047-data-source-filter.md):

```
// emits 80123.45 if 0xBLAHBLAH submits:
// { ticker='ETHUSD', price=1503.42 } 
// then { ticker='BTCUSD', price=80123.45 } 

select { 
  field: 'price', 
  data: filter {
    filters: [ equal { key: 'ticker', value: 'BTCUSD' } ]
    data: signed_message { 
    pubkey=0xBLAHBLAH 
  }, 
}
```


### Validation

The system must validate that the public key data is valid and well formed.


## Blockchain Transaction data submission

This data is submitted once the data is available, e.g. when a market has terminated trading and the expiry time is reached, or in the case of a stream supplying multiple use cases, at a regular cadence (in which case the stream can be filtered down by timestamp).

If the data payload is malformed or the transaction signature is invalid, the transaction should be rejected before inclusion in a block.

```
SubmitData {
    key1: value1
    key2: value2
    ...
}

// or

SubmitData {
   << ABI ENCODED DATA >>
}
```


## Accepting/rejecting the transaction

If data is supplied in a signed message but no active data source (see [data sourcing framework](./0045-data-sourcing.md) section on keeping track of data sources) matches the received message i.e. the pubkey does not exist on any defined data source or in all cases where it is referenced, the message is rejected by a filter, the transaction can be ignored.

Where possible, this should be done before the transaction is included in a block.


### Criteria

1. An [instrument can be created](./0028-governance.md) to rely on a signed message data source
    1. The instrument must specify a valid signed message data source
    1. A market proposal specifying an invalid data source will be rejected
        1. This rejection will happen at *the [creation of the proposal](./0028-governance.md#lifecycle-of-a-proposal)*
    1. Multiple instruments can rely on the same data source, 
        1. Multiple instruments can settle based on the same `SubmitData` message.
        1. Multiple products can [filtering](./0047-data-source-filter.md) the same data source differently and settle based on different `SubmitData` messages.
        1. Multiple products can [filtering](./0047-data-source-filter.md) the same data source differently and settle based on different fields from the same `SubmitData` message.
1. `SubmitData` transactions can be submitted by any public key included in a signed message data source definition
    1. `SubmitData` transactions by active ([see data sourcing framework](./0045-data-sourcing.md)) data sources will be accepted.
    1. `SubmitData` transactions by inactive sata sources will be rejected.
    1. `SubmitData` transactions that are invalid will be rejected.
1. To be valid, a `SubmitData` transaction must:
    1. Be from an active signed message data source,
    1. Invalid `SubmitData` transactions must be rejected.
1. Must work with Coinbase oracle
1. Reject any data source tx that is not explicitly required, so this would include a tx:
    - For a pubkey never used in a data source
    - For a data source where a filter rejects the message based on its contents
    - For a pubkey only used in data sources referenced by markets (or other things) that are no longer being managed by the core (i.e. once a marked is in Closed or Settled or Cancelled state according to the market framework) or before the enactment date of the market proposal


## Notes

- There are no [rewards](./0029-fees.md) associated with being a signed message data source
- There are no [fees](./0029-fees.md) associated with being/using a signed message data source
- There is no internal tracking of reliability of data provided by signed message data sources
- There is no explicit block list for unreliable signed message data sources or malicious public keys.
- There is no API required for signed message data sources except for the APIs defined for all data sources in the data sourcing frameowrk spec.
- There is no requirement for a party operating a signed message data source (i.e. the holder of the private key) to hold any collateral or any of the governance asset.
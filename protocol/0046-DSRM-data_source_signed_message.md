# [Data Source](./0045-DSRC-data_sourcing.md): Signed message

Signed messages are the first type of data from external data sources to be supported by Vega. See the [Data Sourcing spec](./0045-DSRC-data_sourcing.md) for more information on data sources in general and the data source framework.

Signed message data sources introduce a Vega transaction that represents a data result that is validated by ensuring it is signed by a set of signing keys/addresses (signers) provided as part of the _data source definition_. Note the data supplied by the data source can be used when [settling a market at expiry](./0002-STTL-settlement.md) and in the future for any other purpose that requires a data source (such as risk or mark to market functionality), and as inputs to compounds/aggregate data sources.

This spec adds:

- a transaction that allows arbitrary signed data to be submitted to the Vega blockchain (creating a stream of data that can be matched against a data source definition or discarded if not matched)
- a way to define a data source that validates these messages against the predefined set of allowable signers and emits the data received by such a stream

Data can be submitted at any time. Not all data provided by the source needs to be used by a given consumer as the stream can be an input to a [filter data source definition](./0047-DSRF-data_source_filter.md) that will emit only wanted values, allowing a single stream of data from a signer to supply, for example, many markets.

For instance, the Coinbase oracle API provides a stream of signed messages for many different crypto prices, so for one source we could be receiving many messages that aren't used by any given market, for instance if someone set a bot to submit the latest Coinbase oracle signed messages to the Vega chain once per hour. Note it is an explicit goal of this functionality that the signed data made available by the Coinbase oracle can be submitted as a data transaction and validated as a signed message data source _against Coinbase's public key_ (rather than the pubkey of the submitter). That is, it should only be necessary to trust Coinbase.

Note: With this type of oracle there’s no incentive in the Vega data source system, you’re trusting the keyholder(s) and any modifiers or verification applied through the [data source framework](./0045-DSRC-data_sourcing.md) at settlement.

_NOTE: This is the only external oracle available initially in Vega, and initially requires only one of the specified keys to sign and submit the data transaction. This means that initially it will only be possible to construct external oracles on Vega in which one or more third party entities/systems must be trusted. This will change with modifiers that allow combinations of data sources, verification of data stream via governance votes, and data sources that bridge to events included on other blockchains._

## Defining the data source

### Parameters

A data source must define:

- Signers that can sign and submit values for this (external or internal) source. Signers can be different types of keys/addresses that are used by the data source to sign the data. They have different encryption schemes and are treated differently in the DB settings and in codebase level. Examples are public keys used to sign the data, in case of an Open Oracle - Ethereum address.
- Type of data to be supplied in the transaction. Initially we should support the following types:
  - A simple native Vega transaction (i.e. protobuf message) containing one or more key/value pairs of data fields with values in the types allowable in the main data source spec (keys are strings)
  - ABI encoded encoded data. Specifically for oracles, we want to be able to support at least the OpenOracle standard by this method

Note: that as a public key may provide many messages, a [filter](./0047-DSRF-data_source_filter.md) is likely to be needed to extract the required message, and a field select would be used to extract the required field ('price' or 'temperature', etc.)

### Examples

Data source for a public key that will only send one transaction containing prices for several markets and therefore doesn't need to be filtered, but the correct value does need to be extracted:

```proto
// emits 1503.42 if 0xBLAHBLAH submits { ETHUSD: 1503.42, BTCUSD: 80123.45 }
select { field: 'ETHUSD', data: signed_message: { pubkey=0xBLAHBLAH } }
```

Data source for a public key that will send multiple transactions containing prices for several markets and must be [filtered](./0047-DSRF-data_source_filter.md):

```proto
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

```proto
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

If data is supplied in a signed message but no active data source (see [data sourcing framework](./0045-DSRC-data_sourcing.md) section on keeping track of data sources) matches the received message i.e. the pubkey does not exist on any defined data source or in all cases where it is referenced, the message is rejected by a filter, the transaction can be ignored.

Where possible, this should be done before the transaction is included in a block.

### Criteria

An [instrument can be created](./0028-GOVE-governance.md) to rely on a signed message data source:

- The instrument must specify a valid signed message data source (<a name="0046-DSRM-001" href="#0046-DSRM-001">0046-DSRM-001</a>)
- A market proposal specifying an invalid data source will be rejected (<a name="0046-DSRM-002" href="#0046-DSRM-002">0046-DSRM-002</a>)
  - This rejection will happen at _the [creation of the proposal](./0028-GOVE-governance.md)_  (<a name="0046-DSRM-003" href="#0046-DSRM-003">0046-DSRM-003</a>)

Multiple instruments can rely on the same data source:

- Multiple instruments can settle based on the same `SubmitData` message.  (<a name="0046-DSRM-004" href="#0046-DSRM-004">0046-DSRM-004</a>)
- Multiple products can [filter](./0047-DSRF-data_source_filter.md) the same data source differently and settle based on different `SubmitData` messages.  (<a name="0046-DSRM-005" href="#0046-DSRM-005">0046-DSRM-005</a>)
- Multiple products can [filter](./0047-DSRF-data_source_filter.md) the same data source differently and settle based on different fields from the same `SubmitData` message.  (<a name="0046-DSRM-006" href="#0046-DSRM-006">0046-DSRM-006</a>)

`SubmitData` transactions can be submitted by any public key as long as the data included in the transaction is signed by at least one of the keys included in an active signed message data source definition:

- `SubmitData` transactions for active ([see data sourcing framework](./0045-DSRC-data_sourcing.md)) data sources will be accepted regardless of the transaction signer.  (<a name="0046-DSRM-007" href="#0046-DSRM-007">0046-DSRM-007</a>)
- `SubmitData` transactions by inactive data sources will be rejected.  (<a name="0046-DSRM-008" href="#0046-DSRM-008">0046-DSRM-008</a>)
- `SubmitData` transactions that are invalid will be rejected.  (<a name="0046-DSRM-009" href="#0046-DSRM-009">0046-DSRM-009</a>)

To be valid, a `SubmitData` transaction must:

- Contain correctly signed data from an active signed message data source,  (<a name="0046-DSRM-010" href="#0046-DSRM-010">0046-DSRM-010</a>)
- Invalid `SubmitData` transactions must be rejected.  (<a name="0046-DSRM-011" href="#0046-DSRM-011">0046-DSRM-011</a>)

Ignore any data source tx that is not explicitly required, so this would include a tx:

- For a pubkey never used in a data source  (<a name="0046-DSRM-013" href="#0046-DSRM-013">0046-DSRM-013</a>)
- For a data source where a filter ignores the message based on its contents  (<a name="0046-DSRM-014" href="#0046-DSRM-014">0046-DSRM-014</a>)
- For a pubkey only used in data sources referenced by markets (or other things) that are no longer being managed by the core (i.e. once a marked is in Closed or Settled or Cancelled state according to the market framework) or before the enactment date of the market proposal (<a name="0046-DSRM-015" href="#0046-DSRM-015">0046-DSRM-015</a>)

Other acceptance:

- Must work with Coinbase oracle  (<a name="0046-DSRM-012" href="#0046-DSRM-012">0046-DSRM-012</a>)
- Ignore any `SubmitData` tx that is a duplicate (i.e. contains exactly the same data payload and is for the same data source), even if it is signed by a different signer (assuming the source has multiple configured signers) or was submitted by a different Vega key. (<a name="0046-DSRM-016" href="#0046-DSRM-016">0046-DSRM-016</a>)
- Messages are accepted that contain the data and the signature (conforming to the Open Oracle specification) Note: do not support (or need to) direct connections to REST APIs, Ethereum smart contracts, etc. conforming to the open oracle spec. (<a name="0046-DSRM-017" href="#0046-DSRM-017">0046-DSRM-017</a>)
- Set up a [builtin product futures](./0016-PFUT-product_builtin_future.md) market with vega (internal) time triggered trading terminated oracle and an settlement oracle with a with key `k1`. Wait for time to pass for the market to move to trading terminated. Now submit a market change proposal to change the oracle to key `k2`. Wait for the vote to pass and enact. Now settle the market and verify it settled at the correct price. (<a name="0046-DSRM-018" href="#0046-DSRM-018">0046-DSRM-018</a>).


## Notes

- There are no [rewards](./0056-REWA-rewards_overview.md) associated with being a signed message data source
- There are no [fees](./0029-FEES-fees.md) associated with being/using a signed message data source
- There is no internal tracking of reliability of data provided by signed message data sources
- There is no explicit block list for unreliable signed message data sources or malicious public keys or addresses (signers).
- There is no API required for signed message data sources except for the APIs defined for all data sources in the data sourcing framework spec.
- There is no requirement for a party operating a signed message data source (i.e. the holder of the private key) to hold any collateral or any of the governance asset.

# Trusted Party Oracles
Trusted Party Oracles are the name for the Minimum Viable Data Source. This is the first building block of implementing the [Data Sourcing spec](https://github.com/vegaprotocol/product/pull/289), and we are going to add a Vega transaction that represents a data result. Note the data supplied by a TPO can be used when [settling a market at expiry](./0004-settlement-at-instrument-expiry.md) and in the future for other purposes (such as risk or mark to market functionality).

This spec adds:
- a transaction that allows arbitrary signed data to be submitted to the Vega blockchain (creating a stream of data that can be identified by a data source definition)
- a way to define a data source that reads specific data from such a stream (and discards other data)
- the ability to define the settlement oracle for a market to use such data source definition (NB: there can and will be other places the EXACT SAME features described above will be used, but for now, it is just settlement data)


_Trusted Party Oracles_ refer to a type of oracle that may be specified on a market. This data source consists of nominating one or more Vega participants (pubKeys) who are permitted to submit and attest to the relevant data required by the market. TPOs can submit data at any time. Not all of it will be used, and a single stream of submissions could be used by many markets.

For example, the Coinbase oracle API provides a stream of signed messages for many different crypto prices, so for one source we could be receiving many messages that aren't used by any given market, for instance if someone set a bot to submit the latest Coinbase oracle signed messages to the Vega chain once per hour. (Hence the "filters" section in the definition to determine which messages to look at.)


Data is supplied through a transaction being posted directly on the Vega network that is signed by one of the valid signers for that specific data source.

Note: With this type of oracle there’s no incentive in the Vega data source system, you’re trusting the keyholder(s) at settlement.

*NOTE: This is the only version available in testnet, and initially will require only one of the specified keys to sign and submit the data transaction**

## Defining the data source
We should probably support this key/value IMO but I also want to make sure that we support the Open Oracle message format used by the messages in Coinbase oracle and others - I am not 100% sure of the encoding format, it may be JSON in which case we might need to flatten json keys/array indices to paths like key.1.subkey or it might be that it's encoding specifically to their kind, timestamp, key, value format in which case those become the keys.

INSERT SCHEMA HERE - THIS WILL BE DEFINED ON THE MARKET


## Specifying TPO on Products
When a market is proposed, the settlement data source is specified as part of specifying the instrument. This data source may be a TPO. Note, a TPO may submit data that is used by multiple markets. Each market may use a different field of the data or a differerent message, selected from the TOP in the stream of messages by the filters.
### Futures
A [Cash Settled Direct Futures](./xxxx) product requires specification of a settlementPriceSource for settlement of the product (at expiry). TODO: Move this to the WIP built in futures spec!!

```
Future {
    ... 
    settlementPriceSource:  { 
        signedMessage: {
	    sourcePubkeys: ["VEGA_PUBKEY_HERE"],
	    field: "price",
	    dataType: "decimal",
	    filters: [ 
	        { "field": "feed_id", "equals": "BTCUSD/EOD" },
	        { "field": "mark_time", "equals": "31/12/20" }
	    ]
        }
    } 
}
```


## Blockchain Transaction for Oracle Data Submission

This data is submitted at expiry of the market.

```
SubmitOracleData {
    key1: value1
    key2: value2
}
```

If any of filters do not match (or are of the wrong type) the message is ignored and not passed as a valid data point to whatever defined the source.

Also if the specified field is of the wrong type, the data is not passed as a valid data point, but this should create a warning event i.e. "data event passed filter but format of XX field doesn't match data soruce definition" as the format may have changed and it could be necessary for a [market, in the case of settlement] governance action to change the data source.

Need to specify what filters we'll allow and data types.

We support some ability to have arbitrary feeds.
We need to support selecting messages from a stream (e.g. by datetime or by field). Using comparisons (e.g. greater than or equal to a timestamp) and exact equals.
Don't allow nesting of filters
All filters are AND (so all filters must match for a message)


If any of filters do not match (or are of the wrong type) the message is ignored and not passed as a valid data point to whatever defined the source.

Also if the specified field is of the wrong type, the data is not passed as a valid data point, but this should create a warning event i.e. "data event passed filter but format of XX field doesn't match data soruce definition" as the format may have changed and it could be necessary for a [market, in the case of settlement] governance action to change the data source.

### Example
```
    feed_id: ZZZZ
    mark_time: 31/12/2020 23:59:59
    price: 100.2
    volume: 100,000
````


### Validation:
1. If the _mark_time_ of the transaction does not equal the _mark time_ specified on the Product (e.g. `settlementPriceSource.filters.field.mark_time` ) then this data is not valid for use in the settlement action.

## Proposing Changes to Oracle

A future feature requirement - any participant may propose a change to a market's oracle data source via on-chain governance. This includes:
1. Proposing a change in oracle type - e.g. a non TPO / NDS
1. Proposing a change to the oracle values, such as a change in the sourcePubkeys or filters.

Note..

This is not really part of this spec. The inclusion of a valid data source definition in the market proposal/market framework should be defined by the spec for the Futures product and normal rules apply re: governance actions.

So to be clear: this would be expected to be addressed as part of market change governance actions.

The entire data source definition should be replaceable in a change. Includes the above and any other valid changes.

## Contingencies

### What happens if Oracle Data doesn't arrive?
For the minimum requirement, a (network parameter) timeout should be implemented, whereby if the oracle price data doesn't arrive, the market is settled by another means. See [settlement at expiry spec](./0004-settlement-at-instrument-expiry.md).


## Network Parameters
1. Timeout, after which the oracle data source is considered undelivered and the Product will settle itself according to contingencies.
## Acceptance

### Trusted Party Oracle

- A trusted party oracle is a vega pubic/private keypair
    - Identified by its public key

#### Active Trusted Party Oracle
- A valid [Trusted Party Oracle](#trusted-party-oracle) that has an existing commitment to provide data is referred to in this section as an Active TPO
- An existing commitment is when a [Trusted Party Oracle](#trusted-party-oracle) is listed as a source on one or more [active markets](./0043-market-lifecycle.md#active-markets).
#### Inactive Trusted Party Oracle

- A valid [Trusted Party Oracle](#trusted-party-oracle) that has no existing commitments to provide data is referred to in this section as an Inactive TPO
    - Note: that most accounts on the network that have ever traded thus count as 'Inactive TPOs' 

### Invalid Trusted Party Oracle
A invalid Trusted Party Oracle (TPO) is:

- A non-public key string
- Non-string data
### Criteria

1. A [product can be specified](./0028-governance.md) to rely on a [valid Trusted Party Oracle](#trusted-party-oracle)
    1. The product must specify a [valid Trusted Party Oracle](#trusted-party-oracle)
    1. A market proposal specifying an [Invalid TPO](#invalid-trusted-party-oracle) will be rejected
        1. This rejection will happen at *the [creation of the proposal](./0028-governance.md#lifecycle-of-a-proposal)*
    1. Multiple products can rely on the same TPO, and can settle based on the same `SubmitOracleData`.
1. `SubmitOracleData` transactions can be submitted by any [Trusted Party Oracle](#trusted-party-oracle)
    1. `SubmitOracleData` transactions by [Active TPOs](#active-trusted-party-oracle) will be accepted.
    1. `SubmitOracleData` transactions by [Inactive TPOs](#inactive-trusted-party-oracle) will be rejected.
    1. `SubmitOracleData` transactions by [Invalid TPOs](#invalid-trusted-party-oracle) will be rejected.
1. To be valid, a `SubmitOracleData` transaction must:
    1. Be from an [Active TPO](#active-trusted-party-oracle),
    1. **Questionable**: Be from an [Active TPO](#active-trusted-party-oracle) and for a market that that TPO is a sourceKey for. (this would mean checking the filters for a data source for every active market for every SubmitOracleData)
    1. **Questionable:** Include a `mark_time` date format (this field probably isn't a hard requirement and thus this is probaby wrong),
    1. Invalid `SubmitOracleData` transactions must be rejected.
1. Must work with Coinbase oracle
### Notes
- There are no [rewards](./0029-fees.md) associated with being an [Active TPO](#active-trusted-party-oracle)
- There are no [fees](./0029-fees.md) associated with being an [Active TPO](#active-trusted-party-oracle)
- There is no internal tracking of reliability of data provided by [TPOs](#trusted-party-oracle)
- There is no explicit block list for unreliable [TPO](#trusted-party-oracle).
- There is no API required to list [Invalid](#invalid-trusted-party-oracle), [Active](#active-trusted-party-oracle) or [Inactive](#inactive-trusted-party-oracle) TPOs.
- There is no requirement for a [Trusted Party Oracle](#trusted-party-oracle) to have any [collateral](./0013-accounts.md) at any point in time.
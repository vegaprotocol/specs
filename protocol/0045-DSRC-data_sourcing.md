# Oracles (aka data sourcing)

## 1. Principles and summary

The Vega network runs on data. Market settlement, risk models, and other features require a supplied price (or other data), which must come from somewhere, often completely external to Vega. This necessitates the use of both internal and external data sources, called oracles, for a variety of purposes.

a) The goals of Vega Protocol with regard to oracles are:

1. To provide access to data internal to the Vega network in a standardised way, including data and triggers related to the "Vega Time" and market data (prices, etc.)
1. To support a wide range of third party data sourcing solutions for external data rather than to implement a complete solution in-house.
1. To be a source of definitive and final data to Products and Risk Models that can be trusted by market participants.
1. To build simple, generic and anti-fragile data sourcing functionality, and not to introduce third party dependencies.

b) Things that are explicitly NOT goals of the oracle framework at this time:

1. Calculations or processing of data other than selecting the value of a specific field and filtering events in the data stream are out of scope.
1. Processing arbitrary message formats is out-of-scope. Each required format should be specified explicitly. For instance, we may specify that "Vega native protobuf message of key/value pairs" or "ABI encoded data in the OpenOracle format" must be valid data (and there may be more than one required format), but do not require general consumption of arbitrary data.
1. Whilst we do need to build a framework that will be *extensible* with new sources and transformation/aggregation options, and *composable* by combining options, we are not aiming to build a large library of such features for unproven use cases initially. The MVP can be built and will be very useful with a small number of features.

Note that this approach means:

1. Vega will not integrate directly with specific oracle/data providers at the protocol level. Rather, we provide APIs and protocol capabilities to support a wide range of data sourcing styles and standards (so that oracles implementing these standards will hopefully be compatible with little or no work).
1. External oracles must be able to provide a measure of finality that is either definitive or a configurable threshold on a probabilistic measure (‘upstream finality’).
1. Once upstream finality is achieved, Vega may in future provide optional mechanisms for querying, verification or dispute resolution that are independent of the source. These would be composable steps that could be added to any source.
1. Vega will allow composition of data sources, including those with disparate sources, and may in future provide a variety of methods to aggregate and filter/validate data provided by each.

## 2. Terminology

**Oracle:** A provider of `Oracle Data`.

**Internal Oracle:** An `Oracle` that lives inside the node, and sends `Oracle Data` from the inside.

**External Oracle:** An `Oracle` that lives outside the node, and sends `Oracle Data` from the outside.

**Ethereum Oracle:** An `Oracle` that lives on the Ethereum blockchain as a bridge, and sends `Oracle Data` from the outside.

**Oracle Data:** All data emitted by an `Oracle`.

**Internal Oracle Data**: `Oracle Data` emitted by an `Internal Oracle`.

**External Oracle Data**: `Oracle Data` emitted by an `External Oracle`.

**Ethereum Oracle Data**: `Oracle Data` emitted by an `Ethereum Oracle`.

**Matched Oracle Data:** Label given to `Oracle Data` that matched at least one `Oracle Spec`.

**Unmatched Oracle Data:** Label given to `Oracle Data` that did not match any `Oracle Spec`.

**Oracle Spec:** The filter that defines what is expected from an `Oracle Data` to be considered of interest.

**Oracle Spec Binding:** When an `Oracle Data` is matched, the `Oracle Spec` extracts values out of it, and use them to set specific properties on the market. This is a role of the `Oracle Spec Binding` to know which `Oracle Data` properties are mapped onto the market properties.

## 3. Oracle framework

Any part of Vega requiring external data should be able to consume any type of `Oracle Data`. It uses a single common method to describe what it expects from them by defining an `Oracle Spec`. Coupled to the `Oracle Spec Binding`, it knows which properties to extract and pass down.

### Anatomy of `Oracle Data`

#### Definition of an `External Oracle Data`

```json
{
  "data": {
    "price.BTC.value": "3500",
    "price.BTC.updated_at": "123456790"
  },
  "signatures": [
    "0xdeadbeef"
  ],
  "pubkeys": [
    "0x1234567"
  ]
}
```

### Defining expectations with an `Oracle Spec`

A market is only interested in very specific `Oracle Data`. To determine which `Oracle Data` are of interest, it needs to define a filter, called `Oracle Spec`.

This filter defines a set of constraints the `Oracle Data` has to fulfil to be consumed. It's simply a way to express the following expectation:

> I am interested in integers named `price.BTC.value` whose value is greater than `0`, emitted by an external oracle signing with the public key `0xDEADBEEF`

An `Oracle Spec` defines:

1. The origin of the `Oracle Data`.

> * Where do they come from?
> * Has it been emitted by an `Internal Oracle`, an `External Oracle`, or and `Ethereum Oracle`?
> * If it comes from an `External Oracle`, which public key emitted it?
> * If it comes from an `Ethereum Oracle`, which contract address emitted it?

2. The properties of interest.

> * Do the `Oracle Data` include a property named `price.BTC.value`?
> * Do the `Oracle Data` include a property named `price.BTC.updated_at`?

3. The type of these properties.

> * Is the property `price.BTC.value` an integer?
> * Is the property `price.BTC.updated_at` a timestamp?

4. And optionally, the conditions the values may have to fulfil.

> * Is the `price.BTC.value` value greater than `0`?
> * Is the timestamp greater or equal to `123456789`?

If the `Oracle Data` passes the filter, it is labeled as a `Matched Oracle Data`, and is forwarded to the `Oracle Spec Binding` for properties extraction.

#### Definition of an `Oracle Spec`

```json
{
  "oracle_spec_for_settlement_price": {
    "filters": [
      {
        "key": {
          "name": "price.BTC.value",
          "type": "INTEGER"
        },
        "conditions": [
          {
            "operator": "GREATER_THAN",
            "value": "0"
          }
        ]
      },
      {
        "key": {
          "name": "price.BTC.updated_at",
          "type": "TIMESTAMP"
        },
        "conditions": [
          {
            "operator": "GREATER_THAN_OR_EQUAL",
            "value": "123456789"
          }
        ]
      }
    ]
  }
}
```

## Extracting properties with `Oracle Spec Binding`

Often, the `Matched Oracle Data` will provide multiple properties when what is needed is a single value. Therefore, we have to specify which property this value should come from. That's the role of the `Oracle Spec Binding` to define the properties to be extracted from the `Oracle Data` and the properties they should value on the market. These properties are called "bound properties".

Note that the type of the bound properties must be compatible. For a settlement price, a numeric value would be required; for a trading termination trigger which consumes no data then any data type, etc.

#### Definition of an `Oracle Spec Binding`

If we were to bind the `price.BTC.value` value to the settlement price of a market, we would declare the following configuration, with the `Oracle Spec` and `Oracle Spec Binding`:

```json
{
  "oracle_spec_for_settlement_price": {
    "filters": [
      {
        "key": {
          "name": "c",
          "type": "INTEGER"
        },
        "conditions": [
          {
            "operator": "GREATER_THAN",
            "value": "0"
          }
        ]
      }
    ]
  },
  "oracle_spec_binding": {
    "settlement_price": "price.BTC.value"
  }
}
```

```
TO REVIEW

I need a concrete example to fully understand the following specification

---------------------------------------------------------------------------

Data sources may refer to other data sources, for example:

1. A data source that takes a source of structured data records as input and emits only the value of a named field (e.g. to return "BTCUSD_PRICE" from a record containing many prices, for instance)
1. A data source that takes another data source as input and emits only data that matches a set of defined filters (e.g. to return only records with specific values in the timestamp and ticket symbol fields)

NB: the above could be composed, so filter the stream and then select a field.
```

## 5. Data types

### Allowable types

The oracle framework supports the following data types:

1. Number (for MVP these can be used for prices or in filter comparisons)
1. String (for MVP these would only be used to compare against in filters)
1. Date/Time (for MVP these would only be used to compare against in filters)
1. Structured data records i.e. a set of key value pairs (for MVP these would be inputs to filters)

Note that for number types the system should convert appropriately when these are used in a situation that requires Vega's internal price/quote type using the configured decimal places, etc. for the market.

Additionally, for number types where the data source value cannot be interpreted without decimal place conversion (e.g. it is a number from Ethereum represented as a very large integer, perhaps as a string, with 18 or some other number of implicit decimals), it must be possible to specify the number of implicit decimals, when specifying the oracle (e.g. in a market proposal or wherever the oracle is to be used). Strings and numbers with decimal points and numbers after them should be interpreted correctly.

For example, if an oracle with specified 18 decimal places is used to settle a market with 4 market decimals then:

* The `Oracle Data` with a value of `103500000000000000000` implies an actual value of `103.5`
* This value would end up being represented on Vega as `1035000`

For Vega to support sufficient number types to enable processing of any reasonably expected message for each format,all values of an `Oracle Data` are defined as strings, and, then, converted into the requested type. This allows complex or big numbers to be express without hitting programming language limits.

In future there will likely be other types.

### Type checking

```
TO REVIEW

Should we rethink the part in the light of the current wording and choosen components architecture ?

---------------------------------------------------------------------------

The context in which the data source is used can determine the type of data required to be received. Data sources that emit data of an incorrect type to a defined data source should trigger an event or log of some sort (the type may depend on if this is detected within processing of a block or before accepting a tx). If the error is detected synchronously on submission, the error message returned by the node should explicitly detail the issue (i.e. what mismatched, how, and in what part of what data source definition it occurred).

For [futures](./0016-PFUT-product_builtin_future.md), the data type expected will be a number ("price"/quote) for settlement, and any event for the trading terminated trigger. For filtered data, the input data source can be any type and the output must be the type required by the part of the system using the data source.
```

## 7. Types of data source

The following data sources have been defined:

1. [Internal basic data sources](./0048-DSRI-data_source_internal.md)
1. [signed message](./0046-DSRM-data_source_signed_message.md)
1. [Filters](./0047-DSRF-data_source_filter.md) (exclude certain events based on conditions and boolean logic against the fields on the data such as equals, simple comparisons). An MVP of this functionality is needed to allow signed message data sources to be practical, more complex filters are included in the "future work" section below.

Future (needed sooner than the others listed in 9 below)

1. Ethereum oracles (events, contract read methods)
1. Repeating time triggers
1. Vega market data (i.e. prices from other markets on Vega)

## 8. Tracking active data sources

Vega will need to keep track of all "active" defined data sources that are referenced either by markets that are still being managed by the core (i.e. excluding Closed/Settled/Cancelled/other "end state" markets) or by other data source definitions (see each individual data source definition spec, such as [signed message](./0046-DSRM-data_source_signed_message.md) for this specific information).

Vega should consider the specific definition including filters, combinations etc. not just the primary source. So, for example, if two markets use the same public key(s) but different filters or aggregations etc. then these constitute two different data sources and each transaction that arrives signed by these public keys should only be accepted if one or more of these specific active data sources "wants" the data.

Data sources that are no longer active as defined above can be discarded. Incoming data that is not emitted by an active data source (i.e. passes all filters etc. as well as matching the public key, event name, or whatever) can be ignored.

## 9. APIs

APIs should be available to:

1. List active data sources and their configuration
1. Emit an event on the event bus when a data source value is emitted.

## 10. Future work

The following are expected to be implemented in the future.

a) New base data source types:

1. Internal market parameters
1. Internal market data (prices)
1. Internal network parameters and metrics
1. Signed or validator verified HTTPS endpoints
1. Other blockchains that we bridge to
1. Other formats for messages received via, e.g. signed data sources/HTTPS/... (e.g. JSON)

b) Composable modifiers/combinators for data sources:

1. Repeating time triggers (every n hours, every dat at 14:00, etc.)
1. Aggregation (m of n and/or averaging, etc.) of multiple other data sources
1. Verification of outputs of another data source by governance vote
1. Calculations (i.e. simple maths/stats plus access to quant library functions, product valuation function, including reference to product parameters or arbitrary other data sources)
1. Additional filter conditions

In future, we would therefore expect arbitrary compositions of these features to allow market designers to design robust and useful data sources. An visual example of a data source "pipeline" / definition that might eventually be used is below:

![dta source pipeline example](./data-sources.png)

## Examples

Here are some examples of how a data source might be specified.

Note that these are examples *not actual specs*, please see specs for currently specified data types!

Signed message stream filtered to return a single value:

```
select: {
  field: 'price',
  data: {
    filteredData: {
      filters: [ 
    -   { 'field': 'feed_id', 'equals': 'BTCUSD/EOD' },
        { 'field': 'mark_time', 'equals': '31/12/20' }
      ],
      data: { 
        signedMessage: {
          sourcePubkeys: ['VEGA_PUBKEY_HERE', ...],
          dataType: { type: 'decimal', places: 5 }
        }
      }
    } 
  }
}
```

Simple value, emitted at a date/time:

```
on: { 
  timestamp: '2021-01-31T23:59:59Z', 
  data: { 
    value { value: 0.2, type: 'float', } 
  }
}
```

Empty value, trigger only, i.e. trigger trading terminated at a date/time for futures:

```
on: { timestamp: '2021-01-31T23:59:59Z' }
```

In future: value from a read only call on Ethereum

```
ethereumCall: {
  at: '2021-01-31T23:59:59Z',
  contractAddress: '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984',
  ABI: '...ABI...BLAH...'
  method: 'getPrice'
  params: []
}
```

# Acceptance criteria

Vega should reject any data source tx that is not explicitly required, so this would include a tx:

1. If a data source combines a primary source (like a signed message) with a filter (for instance saying we are only interested in messages where ticker = GBPUSD and timestamp = 20211231T23:59:00) then the complete data source definition defines the source and can be used to accept/reject transactions, so for an active data source is active, transactions from the same provider (pubkey, Ethereum contract/event, URL, etc.) do not form part of the defined data source. If submitted, they should be rejected where possible and must not supply data to the target for the data source if the metadata or data content itself is not selected by the source definition (e.g. because ticker and timestamp do not match a filter). (<a name="0045-DSRC-001" href="#0045-DSRC-001">0045-DSRC-001</a>)
1. When no reference to a data source remains in any active part of the system (for instance a non-cancelled/settled market), data source no longer needs to be tracked and can be discarded. Any transactions that would previously have matched and been selected by that data source would be rejected/ignored. (<a name="0045-DSRC-002" href="#0045-DSRC-002">0045-DSRC-002</a>)
1. If the same complete data source (provider and filters, etc.) is referenced in multiple places (e.g. two separate active markets) then it will remain acrtive if any subset of those references remain active. For example 2 markets reference the same data source (full definition must match exactly) and one of those markets is closed/cancelled/settled before the other, either because some other difference in their definition or because of governance action. (<a name="0045-DSRC-003" href="#0045-DSRC-003">0045-DSRC-003</a>)
1. If multiple data sources share common roots (e.g. the same provider - pubkey etc. but different filters) and at least one of those sources filters out a transaction but at least one other selects it (all filters match), the transaction data must still be supplied for the sources that match and must not be supplied for the sources that don't match. (<a name="0045-DSRC-004" href="#0045-DSRC-004">0045-DSRC-004</a>)
1. If multiple data sources share common roots (e.g. the same provider - pubkey etc. but different filters) and all of the sources select it (all filters match), the transaction data must be supplied for ALL of the sources that match. (<a name="0045-DSRC-005" href="#0045-DSRC-005">0045-DSRC-005</a>)
1. If a data source reference is changed (e.g. via governance vote), the old source must be dropped and data/transactions matching that source must not reach the target. (<a name="0045-DSRC-006" href="#0045-DSRC-006">0045-DSRC-006</a>)
1. If a data source reference is changed (e.g. via governance vote), the new source must become active and data/transactions matching that source must reach the target. (<a name="0045-DSRC-007" href="#0045-DSRC-007">0045-DSRC-007</a>)
1. Changes in data source references (e.g. via governance vote) must allow changing between any valid data source definitions, including to a data source of a different type of data source. (<a name="0045-DSRC-008" href="#0045-DSRC-008">0045-DSRC-008</a>)
1. Data is not applied retrospectively, i.e. if a previous historic data point or data transaction would have matched a newly created data source, it must not be identified and applied to the new data source (and therefore need not be stored by the core), only active data and new events created after the activation of the data source would be considered for the source. (<a name="0045-DSRC-009" href="#0045-DSRC-009">0045-DSRC-009</a>)
1. Two data sources with the same definition that are active at the same time must always select and receive exactly the same data, in the same order. (<a name="0045-DSRC-010" href="#0045-DSRC-010">0045-DSRC-010</a>)
1. Rejection of data sources either before submission/sequencing as transactions or when/if data is filtered/rejected after being sequenced on chain (if this happens - it should be avoided wherever possible to prevent spam attacks and reduce network load) must be accompanied by a message detailing the rejection reason (e.g. the filter, selector, or type check that failed). (<a name="0045-DSRC-011" href="#0045-DSRC-011">0045-DSRC-011</a>)
1. It's possible to query an API and see all active data sources. (<a name="0045-DSRC-012" href="#0045-DSRC-012">0045-DSRC-012</a>)
1. It's possible to listen to events or view logs and see all rejections and data source processing. (<a name="0045-DSRC-013" href="#0045-DSRC-013">0045-DSRC-013</a>)
1. It's possible to listen to events and see all data that is supplied across all data sources or for any specific source. (<a name="0045-DSRC-014" href="#0045-DSRC-014">0045-DSRC-014</a>)
1. Data node carries historic data of at least all valid data that was supplied for each data source. (<a name="0045-DSRC-015" href="#0045-DSRC-015">0045-DSRC-015</a>)
1. Data sources can be composed/nested arbitrarily (as long as the definition is valid), for example selecting a field on filtered data that itself was sourced by selecting a field on a message sent by a signed data source (for example this might be processing a complex object in the source data. (<a name="0045-DSRC-016" href="#0045-DSRC-016">0045-DSRC-016</a>)
1. A market proposal specifies data source where value used for settlement is integer with implied decimals; the implied decimals are included in the oracle spec; once trading terminated and settlement data is submitted the price is interpreted correctly for settlement purposes. E.g. market decimals `1`, market uses asset for settlement with `10` decimals, oracle implied decimals `5`, submitted value `10156789` interpreted as `101.56789`. In asset decimals this is `1015678900000` and this is used for settlement.  (<a name="0045-DSRC-017" href="#0045-DSRC-017">0045-DSRC-017</a>)

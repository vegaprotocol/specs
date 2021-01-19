# Data sourcing (aka oracles)

## 1. Principles and summary

The Vega network runs on data. Market settlement, risk models, and other features require a supplied price (or other data), which must come from somewhere, often completely external to Vega. This necessitates the use of both internal and external data sources for a variety of purposes.


b) The goals of Vega Protocol with regards to data sourcing are:

1. To provide access to data internal to the Vega network in a standardised way, including data and triggers related to the "Vega Time" and market data (prices, etc.)
1. To support a wide range of third party data sourcing solutions for external data rather than to implement a complete solution in-house.
1. To be a source of definitive and final data to Products and Risk Models that can be trusted by market participants.
1. To build simple, generic and anti-fragile data sourcing functionality, and not to introduce third party dependencies.


b) As a result: 

1. Vega will not integrate directly with specific oracle/data providers at the protocol level. Rather, we provide APIs and protocol capabilities to support a wide range of data sourcing styles
1. External data sources must be able to provide a measure of finality that is either definitive or a configurable threshold on a probabilistic measure (‘upstream finality’).
1. Once upstream finality is achieved, Vega may provide optional mechanisms for querying, verification or dispute resolution that are independent of the source.
1. Vega will allow composition of data sources, including those with disparate sources, and may provide a variety of methods to aggregate and filter/validate data provided by each. 


## 2. Data sourcing framework

Any part of Vega requiring a data source should be able to use any type of data source. This means that there is a single common schema for specifying a data source where one is required.

a) Data sources can differ in tThis forms only part of the Vega system which also includes a bridge contract to the Vega blockchain, which may also hold tokens. All token functionality exists on the Vega blockchain, except for the (disabled in locked tokens) ability to transfer tokens on Ethereume following ways:

1. Type of data source (signed message, internal data, date/time, Ethereum, etc.)
1. Data type (e.g. float for a price)
1. "Single shot", first n events, stream of any number of events

b) Additionally, for each type of data source there will be parameters that specify how to interpret the data source, such as:
1. Data source specifics (contract address, method name, public key of sender, etc.)
1. Fields of interest (i.e. if the source provides JSON, key/value pairs, etc.)
1. Filters (i.e. to restrict the data source to a subset of events)

c) Data sources may refer to other data sources, for example:
1. A governance approval data source might have a field for another data source and create a governance proposal to accept or reject the value received from that data source
1. Aggregation data sources may allow n data sources to be specified and average them or apply "m of n" logic before emitting one value
1. etc.


## 3. Defining a data source

When defining a data source, the specification for that data source must describe:
1. What parameters (input data) are required to create a data source of that type
1. How the data source interprets those parameters to emit one or more values
1. Any additional requirements needed for the data source to work (such as external "bridge" infrastrcuture to other blockchains)


## 4. Data types

a) Data sources must be able to emit the following data types:
1. Integer
1. Floating point
1. DecimalFromInteger (i.e. how Ethereum stores decimal places, need to specify number of decimal places with this type)
1. Integer/Floating/DecimalFromInteger from string (we need to support the cases where numbers come from APIs in string format / are too large for basic number types to represent)
1. Strings
1. Date/Time
1. Boolean
1. Empty (ignore all values, source is used as a trigger only)
1. Key value pairs (needed so we can have price(s) and timestamp, etc. for filtering)

Note that for number types the system should convert appropriately when these are used in a situation that requires Vega's internal price/quote type using the configured decimal places, etc. for the market.

Note that we should support all the number types as we want to enable the community to easily submit data from various sources and not worry about conversion, and different market types will have different data types for settlement, and different underlying source assumptions.


b) Future types (when we create new products and add calculation features we will need these):
1. List of items of any type (i.e. list of floats)


## 5. Tracking active data sources

Vega will need to keep track of all "active" defined data sources that are referenced either by markets that are still being managed by the core (i.e. excluding Closed/Settled/Cancelled/other "end state" markets) or by other data source definitions.

Data sources that are no longer active as defined above can be discarded.


## 6. Types of data source

The following data sources have been defined:
1. Internal basic data sources (Vega time, direct value) [TODO: link]
1. [signed message](./0046-data-source-signed-message.md)
1. Time triggered (at a certain date/time)
1. Filters (exclude certain events basd on conditions and boolean logic against the fields on the data such as equals, simple comparisons, is/is not in a predefined list, an MVP of this functionality is needed to allow TPOs to be practical)
1. Ethereum oracles (events, contract read methods)

## 7. APIs

APIs should be available to:
1. List active data sources and their configuration
1. Emit an event on the event bus when a data source value is emitted. For example a signed message data source would emit an event for EVERY signed message that matched on of the public keys for an active signed message data source definition (*even if these are later filtered out*). A filter data source defined on a signed message data source would therefore only emit an event bus message when data passes the filters, etc.


## 8. Future work

The following are expected to be implemented in future.

a) New base data source types:
1. Internal market parameters and data
1. Internal network parameters and metrics
1. Signed or validator verified HTTPS endpoints
1. Other blockchains that we bridge to

b) Composable modifiers/combinators for data sources:
1. Repeating time triggers
1. Aggregation (m of n and/or averaging, etc.) of multiple other data sources
1. Verification of outputs of another data source by governance vote
1. Calculations (i.e. simple maths/stats plus access to quant library functions, product valuation function, including reference to product parameters or arbitrary other data sources)


## Examples

Here are some examples of how a data source might be specified. 

Note that these are examples *not actual specs*, please see specs for currently specified data types! 

Simple value, emitted immediately:
```
value: { value: 0.2, type: 'float' }
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

Empty value, trigger only, i.e. trigger trading treminated at a date/time for futures:
```
on: { timestamp: '2021-01-31T23:59:59Z', data: Empty }
```

NB: it should be possible to avoid specifying the 'data' data source field if value = empty:
```
on: { timestamp: '2021-01-31T23:59:59Z' }
```


Trigger for settlement three times daily (used for instance to settle perpetuals):
```
repeating: { times: ['00:00', '08:00', '16:00'], days: '*', data: Empty }
```

Signed message stream filtered to return a single value:
```
filteredData: {
  onceOnly: true,
  filters: [ 
    { 'field': 'feed_id', 'equals': 'BTCUSD/EOD' },
    { 'field': 'mark_time', 'equals': '31/12/20' }
  ],
  data: { 
    signedMessage: {
      sourcePubkeys: ['VEGA_PUBKEY_HERE', ...],
      field: "price",
      dataType: { type: 'decimal', places: 5 }
    }
  }
} 
```

Value from a read only call on Ethereum
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

1. 
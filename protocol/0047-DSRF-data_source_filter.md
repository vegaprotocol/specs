# [Data Source](./0045-DSRC-data_sourcing.md): Filtered data

## Overview

Filtered data defines a type of data source that is a compound data source. That is, it includes another data source definition in its definition and outputs a modified stream of data. Specifically, a filtered data source contains one or more conditions that are applied to data from the input data source to determine whether that data is output by the compound (filtered) data source.

For example, a [signed message](./0046-DSRM-data_source_signed_message.md) data source may submit a stream of transactions providing hourly data for several tickers, like this:

```proto
DATA_SOURCE = SignedMessage{ pubkey=0xA45e...d6 }, gives:

	{ ticker: 'TSLA', timestamp: '2021-12-31T00:00:00Z', price: 420.69}
	{ ticker: 'BTCUSD', timestamp: '2021-12-31T00:00:00Z', price: 42069.303}
	{ ticker: 'ETHGAS', timestamp: '2021-12-31T00:00:00Z', price: 100.1}
	...
	{ ticker: 'TSLA', timestamp: '2021-12-31T01:00:00Z', price: 469.20}
	{ ticker: 'BTCUSD', timestamp: '2021-12-31T01:00:00Z', price: 52069.42}
	{ ticker: 'ETHGAS', timestamp: '2021-12-31T01:00:00Z', price: 101.0}
	...
	{ ticker: 'TSLA', timestamp: '2021-12-31T02:00:00Z', price: 440.20}
	{ ticker: 'BTCUSD', timestamp: '2021-12-31T02:00:00Z', price: 501.666}
	{ ticker: 'ETHGAS', timestamp: '2021-12-31T02:00:00Z', price: 90.92}
	... and so on ...
```

In order to use messages from this signer as, for example, the settlement trigger and data for a [futures](./0016-PFUT-product_builtin_future.md) market, Vega needs a way to define a data source that will trigger settlement when a price is received for the correct underlying and the right expiry timestamp. For example:

```proto
DATA_SOURCE = Filter { data=SignedMessage{ pubkey=0xA45e...d6 }, filters=[
	Equal { key='ticker', value='TSLA' },
	Equal { key='timestamp', value='2021-12-31T23:59:59Z' }
]}

gives:
	{ ticker: 'TSLA', timestamp: '2021-12-31T23:59:59Z', price: 694.20 }
```

Unlike the first example, this would be useful for trigger final settlement of a futures market.

Note that to extract the price value, this would need to be wrapped in a 'select' data source (see [Data Sourcing main spec](./0045-DSRC-data_sourcing.md)) that specifies the field of interest ('price', here), i.e.:

```proto
DATA_SOURCE = select {
	field: 'price'
	data: filter {
		data: SignedMessage{ pubkey=0xA45e...d6 },
		filters: [
	    equal { key: 'ticker', value: 'TSLA' },
	    equal { key: 'timestamp', value: '2021-12-31T23:59:59Z' }
		]
	}
}

gives: 694.20
```

## Specifying a filtered data source

To specify a filtered data source the following parameters can be specified:

- `data`: (required) another data source definition defining the input data
- `filters`: (required) a list of _at least one_ filter to apply to the data

### Parameter: data

This can be _any_ other data source within the data sourcing framework.

### Parameter: filters

These specify the condition to apply to the data. If ALL filters match the data is emitted (note that in future we may add things like 'or' filters that combine other filters but initially this is not required).

For each filter, a `key` parameter is required

Filter types:

- Equals: data must exactly match the filter, i.e. `Equals { key='ticker', value='TSLA' }`
- `Greater/GreaterOrEqual`: `GreaterOrEqual { key='timestamp', value='2021-12-31T23:59:59' }`
- `Less/LessOrEqual`: `GreaterOrEqual { key='timestamp', value='2021-12-31T23:59:59' }`

## Accepting/rejecting filtered data

Data that does not pass all filters can be ignored. Ideally this would be done before accepting the transaction into a block, this would mean that for a configured pubkey that may be submitting many transactions to a node, Vega would automatically choose to accept only the specific messages that will be processed by a product or some other part of the system.

To be clear, this also means that if the input data is the wrong "shape" or type to allow the defined filters to be applied to it, it will also be rejected. For instance if a ticker or timestamp field that is being filtered on is not present, the data does not pass the filter.

## Acceptance criteria

1. Filters can be used with any data source provider (internal, signed message, Ethereum etc.)
	1. Create a filter for each type of source provider and ensure that only data matching the filter gets through. (<a name="0047-DSRF-001" href="#0047-DSRF-001">0047-DSRF-001</a>)(<a name="0047-SP-DSRF-001" href="#0047-SP-DSRF-001">0047-SP-DSRF-001</a>)
	1. Create the same filter for multiple types of provider and ensure that with the same input data, the output is the same. (<a name="0047-DSRF-002" href="#0047-DSRF-002">0047-DSRF-002</a>)(<a name="0047-SP-DSRF-002" href="#0047-SP-DSRF-002">0047-SP-DSRF-002</a>)
1. All filter conditions are applied
	1. Create a filter with multiple "AND" conditions and ensure that data is only passed through if all conditions are met. (<a name="0047-DSRF-003" href="#0047-DSRF-003">0047-DSRF-003</a>)(<a name="0047-SP-DSRF-003" href="#0047-SP-DSRF-003">0047-SP-DSRF-003</a>)
	1. Create a filter using an "OR" sub-filter (if implemented) and ensure that data is passed through if any of the OR conditions are met. (<a name="0047-COSMICELEVATOR-004" href="#0047-COSMICELEVATOR-004">0047-COSMICELEVATOR-004</a>)(<a name="0047-SP-COSMICELEVATOR-004" href="#0047-SP-COSMICELEVATOR-004">0047-SP-OSMICELEVATOR-004</a>)
	1. Create a "greater than or equal" filter on the "timestamp" field of the signed message (_not_ on the timestamp when oracle transaction is  submitted) (e.g. greater than or equal "2022-04-01") _and_ on "equal" filter on the "asset" field (e.g. equals ETH) of the signed message from Coinbase oracle. Ensure these are applied correctly (<a name="0047-DSRF-0041" href="#0047-DSRF-0041">0047-DSRF-0041</a>)(<a name="0047-SP-DSRF-0041" href="#0047-SP-DSRF-0041">0047-SP-DSRF-0041</a>).
1. Data that is filtered out does not result in a data event but is recorded
	1. No data source event is emitted for a data source if the triggering event (`SubmitData` transaction, internal source, etc.) does not pass through the filter for that source. (<a name="0047-DSRF-005" href="#0047-DSRF-005">0047-DSRF-005</a>)(<a name="0047-SP-DSRF-005" href="#0047-SP-DSRF-005">0047-SP-DSRF-005</a>)
	1. No product/market processing is triggered by a data source when the event does not pass through the filters. (<a name="0047-DSRF-006" href="#0047-DSRF-006">0047-DSRF-006</a>)(<a name="0047-SP-DSRF-006" href="#0047-SP-DSRF-006">0047-SP-DSRF-006</a>)
	1. When data is filtered out and no event is emitted this is recorded either in logs or on the event bus (this may only happen on the receiving node if the event is a transaction that is rejected prior to being sequenced in a block). (<a name="0047-DSRF-007" href="#0047-DSRF-007">0047-DSRF-007</a>)(<a name="0047-SP-DSRF-007" href="#0047-SP-DSRF-007">0047-SP-DSRF-007</a>)
1. Data sources are defined by the FULL definition including filters
	1. If two data sources originate from the same data point (transaction, event, etc.) and provider (`SignedMessage` signer group, internal market/object, etc.) but have different filters then data filtered out by one source can still be received by another, and vice versa. (<a name="0047-DSRF-008" href="#0047-DSRF-008">0047-DSRF-008</a>)(<a name="0047-SP-DSRF-008" href="#0047-SP-DSRF-008">0047-SP-DSRF-008</a>)
	1. If two data sources originate from the same data point (transaction, event, etc.) and provider (`SignedMessage` signer group, internal market/object, etc.) but have different filters or other properties (i.e. they are not exactly the same definition) then any data that passes through and is emitted by both data sources results in a separate event/emission for each that references the appropriate source in each case. (<a name="0047-DSRF-009" href="#0047-DSRF-009">0047-DSRF-009</a>)(<a name="0047-SP-DSRF-009" href="#0047-SP-DSRF-009">0047-SP-DSRF-009</a>)
	1. If two data sources originate from the same data point (transaction, event, etc.) and provider (`SignedMessage` signer group, internal market/object, etc.) but have different filters or other properties (i.e. they are not exactly the same definition) then any data that is filtered out by both data sources results in a separate log/event for each that references the appropriate source in each case. (<a name="0047-DSRF-010" href="#0047-DSRF-010">0047-DSRF-010</a>)(<a name="0047-SP-DSRF-010" href="#0047-SP-DSRF-010">0047-SP-DSRF-010</a>)
	1. If two data sources originate from the same data point (transaction, event, etc.) and provider (`SignedMessage` signer group, internal market/object, etc.) but have different filters or other properties (i.e. they are not exactly the same definition) and the data is filtered out by one and emitted/passes through the other, then both the filtering out and the emission of the data are recorded in logs/events that reference the appropriate source. (<a name="0047-DSRF-011" href="#0047-DSRF-011">0047-DSRF-011</a>)(<a name="0047-SP-DSRF-011" href="#0047-SP-DSRF-011">0047-SP-DSRF-011</a>)
1. Data types and condition types
	1. Text fields can be filtered by equality (text matches filter data exactly). (<a name="0047-DSRF-012" href="#0047-DSRF-012">0047-DSRF-012</a>)(<a name="0047-SP-DSRF-012" href="#0047-SP-DSRF-012">0047-SP-DSRF-012</a>)
	1. Number fields can be filtered by equality (number matches filter data exactly). (<a name="0047-DSRF-013" href="#0047-DSRF-013">0047-DSRF-013</a>)(<a name="0047-SP-DSRF-013" href="#0047-SP-DSRF-013">0047-DSRF-013</a>)
	1. Date + time fields can be filtered by equality (datetime matches filter data exactly). (<a name="0047-DSRF-014" href="#0047-DSRF-014">0047-DSRF-014</a>)(<a name="0047-SP-DSRF-014" href="#0047-SP-DSRF-014">0047-SP-DSRF-014</a>)
	1. Number fields can be filtered by less than (number is less than filter data). (<a name="0047-DSRF-015" href="#0047-DSRF-015">0047-DSRF-015</a>)(<a name="0047-SP-DSRF-015" href="#0047-SP-DSRF-015">0047-SP-DSRF-015</a>)
	1. Date + time fields can be filtered by less than (datetime is less than filter data). (<a name="0047-DSRF-016" href="#0047-DSRF-016">0047-DSRF-016</a>)(<a name="0047-SP-DSRF-016" href="#0047-SP-DSRF-016">0047-SP-DSRF-016</a>)
	1. Number fields can be filtered by less than or equal (number is less than or equal to filter data). (<a name="0047-DSRF-017" href="#0047-DSRF-017">0047-DSRF-017</a>)(<a name="0047-SP-DSRF-017" href="#0047-SP-DSRF-017">0047-SP-DSRF-017</a>)
	1. Date + time fields can be filtered by less than or equal (datetime is less than or equal to filter data). (<a name="0047-DSRF-018" href="#0047-DSRF-018">0047-DSRF-018</a>)(<a name="0047-SP-DSRF-018" href="#0047-SP-DSRF-018">0047-SP-DSRF-018</a>)
	1. Number fields can be filtered by greater than (number is greater than filter data). (<a name="0047-DSRF-019" href="#0047-DSRF-019">0047-DSRF-019</a>)(<a name="0047-SP-DSRF-019" href="#0047-SP-DSRF-019">0047-SP-DSRF-019</a>)
	1. Date + time fields can be filtered by greater than (datetime is greater than filter data). (<a name="0047-DSRF-020" href="#0047-DSRF-020">0047-DSRF-020</a>)(<a name="0047-SP-DSRF-020" href="#0047-SP-DSRF-020">0047-SP-DSRF-020</a>)
	1. Number fields can be filtered by greater than or equal (number is greater than or equal to filter data). (<a name="0047-DSRF-021" href="#0047-DSRF-021">0047-DSRF-021</a>)(<a name="0047-SP-DSRF-021" href="#0047-SP-DSRF-021">0047-SP-DSRF-021</a>)
	1. Date + time fields can be filtered by greater than or equal (datetime is greater than or equal to filter data). (<a name="0047-DSRF-022" href="#0047-DSRF-022">0047-DSRF-022</a>)(<a name="0047-SP-DSRF-022" href="#0047-SP-DSRF-022">0047-SP-DSRF-022</a>)
	1. Oracle data filters can be combined together using AND operation (<a name="0047-DSRF-023" href="#0047-DSRF-023">0047-DSRF-023</a>)(<a name="0047-SP-DSRF-023" href="#0047-SP-DSRF-023">0047-SP-DSRF-023</a>)
	1. Filtering should cause the transaction containing the data source definition to be rejected when using filters which are deemed out scope (<a name="0047-DSRF-024" href="#0047-DSRF-024">0047-DSRF-024</a>)(<a name="0047-SP-DSRF-024" href="#0047-SP-DSRF-024">0047-SP-DSRF-024</a>)

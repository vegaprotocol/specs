# [Data Source](./0045-DSRC-data_sourcing.md): Filtered data


# Overview

Filtered data defines a type of data source that is a compound data source. That is, they include another data source definition in their definition and output a modified stream of data. Specifically, a filtered data source contains one or more conditions that are applied to data from the input data source to determine whether that data is output by the compound (filtered) data source.

For example, a [signed message](./0046-DSRM-data_source_signed_message.md) data source may submit a stream of transactions providing hourly data for several tickers, like this:

```
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

```
DATA_SOURCE = Filter { data=SignedMessage{ pubkey=0xA45e...d6 }, filters=[
	Equal { key='ticker', value='TSLA' },
	Equal { key='timestamp', value='2021-12-31T23:59:59Z' }
]}

gives:
	{ ticker: 'TSLA', timestamp: '2021-12-31T23:59:59Z', price: 694.20 }
```

Unlike the first example, this would be useful for trigger final settlement of a futures market. 

Note that to extract the price value, this would need to be wrapped in a 'select' data source (see [Data Sourcing main spec](./0045-DSRC-data_sourcing.md)) that specifies the field of interest ('price', here), i.e.:

```
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

This can be *any* other data source within the data sourcing framework.


### Parameter: filters

These specify the condition to apply to the data. If ALL filters match the data is emitted (note that in future we may add things like 'or' filters that combine other filters but initially this is not required).

For each filter, a `key` parameter is required 

Filter types:

- Equals: data must exactly match the filter, i.e. `Equals { key='ticker', value='TSLA' }`
- Greater/GreaterOrEqual: `GreaterOrEqual { key='timestamp', value='2021-12-31T23:59:59' }`
- Less/LessOrEqual: `GreaterOrEqual { key='timestamp', value='2021-12-31T23:59:59' }`


## Accepting/rejecting filtered data

Data that does not pass all filters can be ignored. Ideally this would be done before accepting the transaction into a block, this would mean that for a configured pubkey that may be submitting many transactions to a node, Vega would automatically choose to accept only the specific messages that will be processed by a product or some other part of the system.

To be clear, this also means that if the input data is the wrong "shape" or type to allow the defined filters to be applied to it, it will also be rejected. For instance if a ticker or timestamp field that is being filtered on is not present, the data does not pass the filter.


## Acceptance criteria

1. 

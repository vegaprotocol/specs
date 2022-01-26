# [Data Source](./0045-DSRC-data_sourcing.md): Internal data


# 0. Overview

Internal data sources provide data that comes from within Vega rather than an external source. They are defined and used in the same way as other data sources but are triggered by the relevant event in the Vega protocol rather than directly by an incoming transaction.

The internal data sources are defined below.


# 1. Data sources

## 1.1 Value

This data source provides an immediate value. It would be used either where a data source is required but the value may be known at the time of definition.

Any code expecting to be triggered when a value is received on a data source would be triggered immediately by a data source of this type, for instance as soon as a market parameter change is enacted, if it contained a value type data source for final settlement, final settlement would occur.

Initially the one use case of this is to submit a governance change proposal to update a futures market's settlement data source to a price value. This would happen if the defined data source fails and token holders choose to simply vote to accept a specific value to be used for settlement.

Example:
```rust
value { type: number, value: 1400.5 }
```


## 1.2 Time triggered

This data source would be used to emit an event/value at/after a given Vega time (i.e. the time printed on the block). This would be used to trigger "trading terminated" for futures, for example. 

This trigger will emit the contents of the specified data source (could be omitted if just triggering trading termination, or could be a value as described in 1.1, or another data source in order to implement a delay/ensure the value from the data source is not emitted before a certain time).

Note that trading terminated in the futures definition uses a data source as a trigger intentionally to (a) demonstrate that this is how time based product events would work; and (b) because although the trigger MAY be time based, it could also be another data source such as a signed message oracle, if the trading terminates at an unknown time.

In future, there will be a need to support repeating time based triggers, for example every 2 days or at 04:00, 12:00 and 20:00 every day, etc. (as some products will have triggers that happen regularly).

Example:
```
on: {
	timestamp: '20210401T09:00:00'
	data: value { type: number, value: 420.69 }
}

```

Example: (no data, just used to trigger event like trading terminated)
```
on: {
	timestamp: '202112311T23:59:59'
}

```
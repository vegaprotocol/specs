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

## Implementation

Usage of internal oracle data are specified using properties prefixed with `vegaprotocol.builtin`, on the oracle spec.

Today, only the time-triggered one is implemented through the property name `vegaprotocol.builtin.timestamp`.

### Example

```proto
{
  “key”:{
    “name”:“vegaprotocol.builtin.timestamp”,
    “type”:“TYPE_TIMESTAMP”
  },
  “conditions”:[{
    “operator”:“OPERATOR_GREATER_THAN_OR_EQUAL”,
    “value”:“1650447351"
  }]
}
```

## Acceptance criteria

1. A simple value data source can be provided
	1. Change a cash settled futures market that is already in Trading Terminated state so that the settlement data source is a Value source. The market settles immediately with the value provided as the settlement data. (<a name="0048-DSRI-001" href="#0048-DSRI-001">0048-DSRI-001</a>)
	1. Change a cash settled futures market's trading terminated trigger source with a market governance proposal to a blank Value data source (or one with any value, to be discarded) and ensure the market state changes to trading terminated. (<a name="0048-DSRI-002" href="#0048-DSRI-002">0048-DSRI-002</a>)
1. A time triggered value data source can be provided
	1. Use a market governance proposal to change a cash settled futures market that is already in Trading Terminated state and has a signed message data source configured for settlement data (where no signed message is ever received) so that the settlement data source is a time triggered Value source with the trigger time in the future after the proposal is enacted. The market settles at the trigger time with the value provided as the settlement data (this allows governance to settle a market with a dead oracle). (<a name="0048-DSRI-009" href="#0048-DSRI-009">0048-DSRI-009</a>)
	1. Create a cash settled futures market with a time triggered value data source for the settlement data. Trigger trading terminated before the time specified in the trigger for the settlement data source. The market settles at the time specified in the trigger. (<a name="0048-DSRI-003" href="#0048-DSRI-003">0048-DSRI-003</a>)
	1. Create a cash settled futures market with a time triggered value data source  for the settlement data. Trigger trading terminated after the time specified in the trigger for the settlement data source. The market settles immediately once trading terminated is triggered. (<a name="0048-DSRI-004" href="#0048-DSRI-004">0048-DSRI-004</a>)
	1. Create a cash settled futures market with the trading terminated trigger source being a time triggered blank Value data source (or one with any value, to be discarded) with the trigger time being in the future. The market state changes to trading terminated at the time of the trigger.  (<a name="0048-DSRI-005" href="#0048-DSRI-005">0048-DSRI-005</a>)
	1. Change a cash settled futures market so the trading terminated trigger source becomes a time triggered blank Value data source (or one with any value, to be discarded) with the trigger time being in the future. The market state changes to trading terminated at the time of the trigger. (<a name="0048-DSRI-006" href="#0048-DSRI-006">0048-DSRI-006</a>)
	1. Change a cash settled futures market so the trading terminated trigger source becomes a time triggered blank Value data source (or one with any value, to be discarded) with the trigger time being in the past. The market state changes to trading terminated immediately. (<a name="0048-DSRI-007" href="#0048-DSRI-007">0048-DSRI-007</a>)
	1. Change a cash settled futures market that is already in Trading Terminated state so that the settlement data source is a time triggered Value source with the trigger time in the past. The market settles immediately with the value provided as the settlement data. (<a name="0048-DSRI-008" href="#0048-DSRI-008">0048-DSRI-008</a>)

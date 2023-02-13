# [Data Source](./0045-DSRC-data_sourcing.md): Internal data

## 0. Overview

Internal data sources provide data that comes from within Vega rather than an external source. They are defined and used in the same way as other data sources but are triggered by the relevant event in the Vega protocol rather than directly by an incoming transaction.

The internal data sources are defined below.

## 1. Data sources

### 1.1 Value

This data source provides an immediate value. It would be used either where a data source is required but the value may be known at the time of definition.

Any code expecting to be triggered when a value is received on a data source would be triggered immediately by a data source of this type, for instance as soon as a market parameter change is enacted, if it contained a value type data source for final settlement, final settlement would occur.

Initially the one use case of this is to submit a governance change proposal to update a futures market's settlement data source to a price value. This would happen if the defined data source fails and token holders choose to simply vote to accept a specific value to be used for settlement.

Pseudocode example:

```rust
value { type: number, value: 1400.5 }
```

## 1.2 Time triggered

### 1.2.1 One-off

This data source would be used to emit a a single event/value at/after a given Vega time (i.e. the time printed on the block). This would be used to trigger "trading terminated" for futures, for example.

This trigger will emit the contents of the specified data source (could be omitted if just triggering trading termination, or could be a value as described in 1.1, or another data source in order to implement a delay/ensure the value from the data source is not emitted before a certain time).

Note that trading terminated in the futures definition uses a data source as a trigger intentionally to (a) demonstrate that this is how time based product events would work; and (b) because although the trigger MAY be time based, it could also be another data source such as a signed message oracle, if the trading terminates at an unknown time.

Once the data source emits the event it should become inactive.

Pseudocode example:

```rust
on: {
	timestamp: '20210401T09:00:00'
	data: value { type: number, value: 420.69 }
}

```

Pseudocode example: (no data, just used to trigger event like trading terminated)

```rust
on: {
	timestamp: '202112311T23:59:59'
}

```

### 1.2.2 Repeating

The repeating internal time triggered oracles will be used by the [perpetual futures](protocol/0053-PERP-product_builtin_perpetual_future.md) product, hence it must be possible to set them up to model a schedule like: every day at 04:00, 12:00 and 20:00. It should also be possible to model a completely arbitrary time schedule with a fixed number of events (e.g. 01/02/2023 08:52, 11/03/2023 15:45, 20/04/2023 21:37). Appropriate anti-spam measures should be considered to prevent the ability to specify an internal time triggered oracle that puts exceedingly high strain on the resources.

## 1.3 Vega time changed

This data source will emit the current Vega time *once* (and once only) whenever the Vega time changes.
This can be used directly as a data source supplying a time feed, or wrapped in a filter to trigger a simple event (i.e. one that does not need to consume a value from another data source, such as the trading terminated trigger for cash settled futures, as only the Vega time will be supplied).

Pseudocode example: (block time feed - not useful with Oregon Trail feature set)

```rust
vegaprotocol.builtin.timestamp

```

Pseudocode example: (with filter - i.e. for trading terminated trigger)

```rust
filter {
	data: vegaprotocol.builtin.timestamp,
	filters: [
		greaterOrEqual { key: 'timestamp', value: '2023-12-31T23:55:00Z' }
	]
}
```

## Implementation

Usage of internal oracle data are specified using properties prefixed with `vegaprotocol.builtin`, on the oracle spec.

Currently (as of Oregon Trail), only the *Vega time changed (1.3 above)* internal data source is implemented, through the property name `vegaprotocol.builtin.timestamp`.

### Example with current implementation

```proto
 “oracleSpecForTradingTermination”:{
    filters”:[
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
    ]
}
```

## Acceptance criteria

1. A simple value data source can be provided
	1. Change a cash settled futures market that is already in Trading Terminated state so that the settlement data source is a Value source. The market settles immediately with the value provided as the settlement data. (<a name="0048-COSMICELEVATOR-001" href="#0048-COSMICELEVATOR-001">0048-COSMICELEVATOR-001</a>)
	1. Change a cash settled futures market's trading terminated trigger source with a market governance proposal to a blank Value data source (or one with any value, to be discarded) and ensure the market state changes to trading terminated. (<a name="0048-COSMICELEVATOR-002" href="#0048-COSMICELEVATOR-002">0048-COSMICELEVATOR-002</a>)
1. A time triggered value data source can be provided
	1. Use a market governance proposal to change a cash settled futures market that is already in Trading Terminated state and has a signed message data source configured for settlement data (where no signed message is ever received) so that the settlement data source is a time triggered Value source with the trigger time in the future after the proposal is enacted. The market settles at the trigger time with the value provided as the settlement data (this allows governance to settle a market with a dead oracle). (<a name="0048-COSMICELEVATOR-009" href="#0048-COSMICELEVATOR-009">0048-COSMICELEVATOR-009</a>)
	1. Create a cash settled futures market with a time triggered value data source for the settlement data. Trigger trading terminated before the time specified in the trigger for the settlement data source. The market settles at the time specified in the trigger. (<a name="0048-COSMICELEVATOR-003" href="#0048-COSMICELEVATOR-003">0048-COSMICELEVATOR-003</a>)
	1. Create a cash settled futures market with a time triggered value data source  for the settlement data. Trigger trading terminated after the time specified in the trigger for the settlement data source. The market settles immediately once trading terminated is triggered. (<a name="0048-COSMICELEVATOR-004" href="#0048-COSMICELEVATOR-004">0048-COSMICELEVATOR-004</a>)
	1. Create a cash settled futures market with the trading terminated trigger source being a time triggered blank Value data source (or one with any value, to be discarded) with the trigger time being in the future. The market state changes to trading terminated at the time of the trigger.  (<a name="0048-COSMICELEVATOR-005" href="#0048-COSMICELEVATOR-005">0048-COSMICELEVATOR-005</a>)
	1. Change a cash settled futures market so the trading terminated trigger source becomes a time triggered blank Value data source (or one with any value, to be discarded) with the trigger time being in the future. The market state changes to trading terminated at the time of the trigger. (<a name="0048-COSMICELEVATOR-006" href="#0048-COSMICELEVATOR-006">0048-COSMICELEVATOR-006</a>)
	1. Change a cash settled futures market so the trading terminated trigger source becomes a time triggered blank Value data source (or one with any value, to be discarded) with the trigger time being in the past. The market state changes to trading terminated immediately. (<a name="0048-COSMICELEVATOR-007" href="#0048-COSMICELEVATOR-007">0048-COSMICELEVATOR-007</a>)
	1. Change a cash settled futures market that is already in Trading Terminated state so that the settlement data source is a time triggered Value source with the trigger time in the past. The market settles immediately with the value provided as the settlement data. (<a name="0048-COSMICELEVATOR-008" href="#0048-COSMICELEVATOR-008">0048-COSMICELEVATOR-008</a>)
1. A Vega time changed value data source can be provided
	1. Create a cash settled futures market with the trading terminated trigger source being a Vega time changed value data source with a greater than or greater than or equal filter against a time in the future. The market state changes to trading terminated at the time of the trigger.  (<a name="0048-DSRI-010" href="#0048-DSRI-010">0048-DSRI-010</a>)
	1. Change a cash settled futures market so the trading terminated trigger source becomes a Vega time changed value data source with a greater than or greater than or equal filter against a time in the future. The market state changes to trading terminated at the time of the trigger. (<a name="0048-DSRI-011" href="#0048-DSRI-011">0048-DSRI-011</a>)
	1. Change a cash settled futures market so the trading terminated trigger source becomes a Vega time changed value data source with a greater than or greater than or equal filter against a time in the past. The market state changes to trading terminated immediately. (<a name="0048-DSRI-012" href="#0048-DSRI-012">0048-DSRI-012</a>)
1. Termination oracle updated after market is terminated (<a name="0048-DSRI-015" href="#0048-DSRI-015">0048-DSRI-015</a>)
	- setup one market with a boolean termination
	- terminate the market (but do not settle it)
	- update the market to have a time based termination
	- update the market to have an earlier time based termination
	- wait until the first timer to tick
	- send through valid settlement data
	- assert the the market settles successfully
1. Time based termination across multiple markets (<a name="0048-DSRI-014" href="#0048-DSRI-014">0048-DSRI-014</a>)
	- setup 3 markets, all with time based termination with identical signer details, two with the same time, one with a later time
	- wait to all of them to terminate successfully
	- assert they all settle successfully
1. The repeating internal time triggered oracle can be used to model a time schedule of the form: every day at 12:00, 15:00 and 18:00. (<a name="0048-DSRI-015" href="#0048-DSRI-015">0048-DSRI-015</a>)
1. The repeating internal time triggered oracle can be used to model a time schedule of the form: 01/02/2023 08:52, 11/03/2023 15:45, 20/04/2023 21:37. (<a name="0048-DSRI-016" href="#0048-DSRI-016">0048-DSRI-016</a>)
1. The repeating internal time triggered oracle with a schedule of "every day at 12:00", always sends an event as soon as the block with a timestamp with time of 12:00 or higher is received (the time the oracle sends an event doesn't drift forward even after many days). (<a name="0048-DSRI-017" href="#0048-DSRI-017">0048-DSRI-017</a>)
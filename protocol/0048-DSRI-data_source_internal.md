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

## Acceptance criteria

1. A simple value data source can be provided
	1. Change a cash settled futures market that is already in Trading Terminated state so that the settlement data source is a Value source. The market settles immediately with the value provided as the settlement data. (<a name="0048-COSMICELEVATOR-001" href="#0048-COSMICELEVATOR-001">0048-COSMICELEVATOR-001</a>)
	1. Change a cash settled futures market's trading terminated trigger source with a market governance proposal to a blank Value data source (or one with any value, to be discarded) and ensure the market state changes to trading terminated. (<a name="0048-COSMICELEVATOR-002" href="#0048-COSMICELEVATOR-002">0048-COSMICELEVATOR-002</a>)
1. Testing the workaround while value data source is not implemented
	1. Equivalent to using a value source and the private key holder does not need to be trusted after step 1 is complete (<a name="0048-DSRI-002" href="#0048-DSRI-002">0048-DSRI-002</a>):
		1. Someone pre-signs a message `M` with the agreed price `P` in the data and publishes the message, signature `S`, and public key `K`.
		1. A proposal is made to set the oracle to a signed message oracle with:
			a. public key: `K`
			b. filter: `price == P`
		1. Assert that once the proposal passes, anyone can submit the message `M` and signature `S` to the Vega network in a transaction and the market will settle.
1. A time triggered value data source can be provided
	1. Use a market governance proposal to change a cash settled futures market that is already in Trading Terminated state and has a signed message data source configured for settlement data (where no signed message is ever received) so that the settlement data source is a time triggered Value source with the trigger time in the future after the proposal is enacted. The market settles at the trigger time with the value provided as the settlement data (this allows governance to settle a market with a dead oracle). (<a name="0048-COSMICELEVATOR-009" href="#0048-COSMICELEVATOR-009">0048-COSMICELEVATOR-009</a>)
	1. Create a cash settled futures market with a time triggered value data source for the settlement data. Trigger trading terminated before the time specified in the trigger for the settlement data source. The market settles at the time specified in the trigger. (<a name="0048-COSMICELEVATOR-003" href="#0048-COSMICELEVATOR-003">0048-COSMICELEVATOR-003</a>)
	1. Create a cash settled futures market with a time triggered value data source  for the settlement data. Trigger trading terminated after the time specified in the trigger for the settlement data source. The market settles immediately once trading terminated is triggered. (<a name="0048-COSMICELEVATOR-004" href="#0048-COSMICELEVATOR-004">0048-COSMICELEVATOR-004</a>)
	1. Create a cash settled futures market with the trading terminated trigger source being a time triggered blank Value data source (or one with any value, to be discarded) with the trigger time being in the future. The market state changes to trading terminated at the time of the trigger.  (<a name="0048-COSMICELEVATOR-005" href="#0048-COSMICELEVATOR-005">0048-COSMICELEVATOR-005</a>)
	1. Change a cash settled futures market so the trading terminated trigger source becomes a time triggered blank Value data source (or one with any value, to be discarded) with the trigger time being in the future. The market state changes to trading terminated at the time of the trigger. (<a name="0048-COSMICELEVATOR-006" href="#0048-COSMICELEVATOR-006">0048-COSMICELEVATOR-006</a>)
	1. Change a cash settled futures market so the trading terminated trigger source becomes a time triggered blank Value data source (or one with any value, to be discarded) with the trigger time being in the past. The market state changes to trading terminated immediately. (<a name="0048-COSMICELEVATOR-007" href="#0048-COSMICELEVATOR-007">0048-COSMICELEVATOR-007</a>)
	1. Change a cash settled futures market that is already in Trading Terminated state so that the settlement data source is a time triggered Value source with the trigger time in the past. The market settles immediately with the value provided as the settlement data. (<a name="0048-COSMICELEVATOR-008" href="#0048-COSMICELEVATOR-008">0048-COSMICELEVATOR-008</a>)
	1. Create a cash settled futures market with the trading terminated trigger source being a trading terminated trigger that uses the internal block timestamp data source and filters it >= some time, to test that the market settles at the first block with a timestamp on or after that time. The market state changes to trading terminated at the time of the trigger.  (<a name="0048-DSRI-009" href="#0048-DSRI-009">0048-DSRI-009</a>)
	1. Change a cash settled futures market so the trading terminated trigger source becomes a trading terminated trigger that uses the internal block timestamp data source and filters it >= some time, to test that the market settles at the first block with a timestamp on or after that time. The market state changes to trading terminated at the time of the trigger. (<a name="0048-DSRI-010" href="#0048-DSRI-010">0048-DSRI-010</a>)
	1. Change a cash settled futures market so the trading terminated trigger source becomes a trading terminated trigger that uses the internal block timestamp data source and filters it to a time in the past, to test that the market settles at the first block with a timestamp on or after that time. The market state changes to trading terminated immediately. (<a name="0048-DSRI-011" href="#0048-DSRI-011">0048-DSRI-011</a>)

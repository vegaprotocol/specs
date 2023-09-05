# Ethereum data source


## Summary

This specification adds a new way of sourcing data from the Ethereum blockchain to allow arbitrary data from the Ethereum blockchain to be ingested as a [data source](./0045-DSRC-data_sourcing.md).
This is in addition to the existing [Ethereum bridge](./0031-ETHB-ethereum_bridge_spec.md), which is unchanged by this spec.


## Description

Currently, data is sourced from Ethereum only as a result of watching for pre-defined events, on a specific contract, at a specific address.
Namely, the ERC20 bridge contract.
These events are picked up by the [event queue](./0036-BRIE-event_queue.md) processor and submitted by each node as transactions to the Vega chain.
Once a quorum of nodes have ratified the transaction, it is reflected in the Vega state.

Ethereum data sources extend this in three important ways:

1. In addition to listening for events defined on a contract, `read` methods can be called on a contract.

2. The event to listen for or function to be read (along with any parameters that must be passed) are specified as part of the data source, rather than being pre-defined across the whole system.

3. The address of the contract being observed is also specified as part of the data source.


Like all data sources, Ethereum oracles may be subject to filters or other processing or aggregation functions.
Once observed, the data is treated as any other data source and available to any part of the system that accepts a data source as input.
The event queue may evaluate filters before submitting the observation to the Vega chain, in order to avoid submitting transactions containing data that will be dropped due to filters in any case.


## Functional design

### Contracts and ABI

An Ethereum oracle has as its subject a smart contract that is deployed on the Ethereum blockchain.
All such contracts have an address, and an "ABI" that defines the methods an events exposed by the contract.
In order to interpret the oracle specification and interact with the smart contract, both the contract address and Ethereum ABI JSON for the contract (or a subset, covering the relevant parts) must therefore be included in the oracle specification.

Event data and data returned from functions will be emitted by the Ethereum node in an ABI-encoded format.
This data, including any structs should be decoded using the ABI into a JSON-like representation.

Note: as with any data source containing JSON formatted (or other arbitrary structured) data, the data required by the consumer of the data source may be a number of fields or sub-objects (including nested fields and objects).
The data sourcing framework therefore requires functionality to apply a query/selector extract the relevant subset of the observed data and pass it to the next consumer.
This would be expected to use `JSONPath`/`JSONPointer` or similar, and be applicable to any arbitrary JSON.
Regardless, the specification of this functionality is out of scope for this document and the approach must be standardised across the data sourcing framework (for example, specifying the target of filters must use the same format as selecting data to pass on).


### Ethereum chain data enrichment

All data sourced from Ethereum should be structured as an object containing both a payload and Ethereum chain metadata, namely:

- Ethereum block height at which the data was observed/event occurred

- Ethereum block timestamp at which the data was observed/event occurred


This data can be used as the subject of filters or even extracted as the oracle data of interest.
Filters on Ethereum block height, Ethereum timestamp, or Vega timestamp should be applied prior to submitting the data to the Vega chain, in addition to being re-applied when the data is confirmed on chain.
This would prevent spamming the Vega chain with event data that is not relevant.


### Events

When the data source is an event emitted by the Ethereum contract, the event name must be specified in the data source specification.
The specified event must be defined in the supplied ABI.


### Contract read

When the data source is a contract read, the method name and any arguments to be passed must be specified in the data source specification.
The specified method must be defined in the supplied ABI.


## Error checking and handling

Errors in the data source specification should be caught where possible during validation.
Errors that occur or are detected later (e.g. when data arrives) must not propagate to other parts of the system.
That is, they must be contained within the data sourcing subsystem.
It should be possible to determine if such errors have occurred by listening for events or querying the data source APIs.

- Attempts to select data from non-existent fields or structures in observed data should be recorded as errors on the event bus and in APIs, and the system must not emit data to the receiver.

- Incorrect ABI (where this cannot be validated at the time the ABI is submitted) and/or the inability to decode data with the provided ABI should be recorded as errors on the event bus and in APIs, and the system must not emit data to the receiver.

- A mismatch in data types between a data field and the data required by the receiver should be recorded as errors on the event bus and in APIs, and the system must not emit data to the receiver.


## Pseudocode examples

Event data source specification:

```json
Select {
	source: Filter {
		source: EthereumEvent {
			contract: 0xDEADBEEF
			ABI: "...JSON..."
			event: "StakeDeposited"
		}
		where: [
			{ selector: '$.ethereum_block_height, condition: '>69420' }
		]
	}
	selector: '$.amount_deposited'
}
```


## Acceptance criteria

### External Oracles - Creation

1. Using the existing ways to create or update a market via governance proposals, define data sources for settlement and termination as the result of calling a read method of a smart contract on ethereum network. (<a name="0082-ETHD-001" href="#0082-ETHD-001">0082-ETHD-001</a>)
2. Phase 2 of the above step would be defining an oracle that is based on listening for events on ethereum network) (<a name="0082-PLAZZO-001" href="#0082-PLAZZO-001">0082-PLAZZO-001</a>)

### External Oracles - Amendments

1. Update an existing market using the market update proposal to change the smart contract address and read method. The changes take effect after the market update proposal is enacted and data is sourced from the new smart contract. The old data source  will be deactivated when the proposal is enacted (<a name="0082-ETHD-002" href="#0082-ETHD-002">0082-ETHD-002</a>)
2. Using the market update proposal all data elements for the ethereum oracles can be updated. On successful enactment , a new oracle data source is created for the market. In case any existing data source matches the new data source , then a new data source is not created and the existing one is used (<a name="0082-ETHD-003" href="#0082-ETHD-003">0082-ETHD-003</a>)
3. Phase 2 - Update an existing market using the market update proposal to change the events that the market is listening to. The changes take effect after the market update proposal is enacted and data is sourced from the new events (<a name="0082-PLAZZO-002" href="#0082-PLAZZO-002">0082-PLAZZO-002</a>)
4. Ensure existing oracle data sources are deactivated when market data sources are amended on another market. Create 2 markets to use different ethereum oracles for termination and settlement. Two sets of ethereum oracles are created and are ACTIVE. Then amend Market 2 to use exactly the same ethereum oracles for termination and settlement as Market1. Now ,the ethereum oracles originally created for for Market2 should be set to DEACTIVATED. No new ethereum oracles should be created and the Market2 should use the existing ethereum oracles created for Market1 (<a name="0082-ETHD-005" href="#0082-ETHD-005">0082-ETHD-005</a>)
5. Ensure that when a market data source type is amended from internal, external, ethereum or open (coinbase) to an alternative for both termination and settlement we see that old data source is deactivated (if no other market is using) and we see the new data source created and it supports termination and settlement specific to its data source type (<a name="0082-ETHD-006" href="#0082-ETHD-006">0082-ETHD-006</a>)

### External Oracles - Deactivation

1. Aligned with the existing logic, when no market listens to a data source, whatever that source is, it is automatically disregarded by the engine and the status of the data source is set to DEACTIVATED. Same applies for ethereum oracles (<a name="0082-ETHD-007" href="#0082-ETHD-007">0082-ETHD-007</a>)

### External Oracles - Validations

1. Validate if the smart contract address is valid (<a name="0082-ETHD-010" href="#0082-ETHD-010">0082-ETHD-010</a>)
2. Validate if the data elements of the oracle data source is valid - e.g. call the smart contract and check if the types in the ABI match whats provided in the oracle spec (<a name="0082-ETHD-011" href="#0082-ETHD-011">0082-ETHD-011</a>)
3. Validations for min / max frequency of listening for events / read a smart contract (<a name="0082-ETHD-012" href="#0082-ETHD-012">0082-ETHD-012</a>)
4. When a proposal that uses ethereum oracles, defines incorrect data (contract address, ABI) the system should return an error and the proposal should not pass validation (<a name="0082-ETHD-013" href="#0082-ETHD-013">0082-ETHD-013</a>)
5. Any mismatch between expected fields/field types and received fields/field types should emit an error event (<a name="0082-ETHD-014" href="#0082-ETHD-014">0082-ETHD-014</a>)

### Usage

1. It should be possible to use only ethereum oracle data sources in a market proposal, or create any combination with any of the other types of currently existing external or internal data sources (<a name="0082-ETHD-015" href="#0082-ETHD-015">0082-ETHD-015</a>)
2. Create a market to use an internal data source to terminate a market and an ethereum oracle to settle the market (<a name="0082-ETHD-016" href="#0082-ETHD-016">0082-ETHD-016</a>)
3. Create a market to use an external data source to terminate a market and an ethereum oracle to settle the market (<a name="0082-ETHD-017" href="#0082-ETHD-017">0082-ETHD-017</a>)
4. Create a market to use an open oracle data source to settle a market and an ethereum oracle to terminate the market (<a name="0082-ETHD-018" href="#0082-ETHD-018">0082-ETHD-018</a>)
5. Chain events should only be sent when the filter is matched, this can be verified using an API and the core/data node events (BUS_EVENT_TYPE_ORACLE_DATA) (<a name="0082-ETHD-019" href="#0082-ETHD-019">0082-ETHD-019</a>)
6. Ethereum oracle data sources should only forward data after a configurable number of confirmations (<a name="0082-ETHD-020" href="#0082-ETHD-020">0082-ETHD-020</a>)
7. Create 2 markets to use the same ethereum oracle for termination say DS-T1 but two different ethereum oracles for settlement DS-S1 and DS-S2. Now trigger the termination ethereum oracle data source. Both markets should be terminated and the data source DS-T1 is set to DEACTIVATED and the data sources DS-S1 and DS-S2 are still ACTIVE. Now settle market1. DS-S1 is set to DEACTIVATED and DS-S2 is still active. (<a name="0082-ETHD-021" href="#0082-ETHD-021">0082-ETHD-021</a>)
8. Create a market to use an ethereum oracle for termination configured such that - it expects a boolean value True for termination and the contract supplying the termination value is polled every 5 seconds. Set the contract to return False for termination. The market is not terminated. The data source is still ACTIVE and no BUS_EVENT_TYPE_ORACLE_DATA events for that ethereum oracle spec are emitted. Then set the contract to return True for termination. The market is terminated and an event for BUS_EVENT_TYPE_ORACLE_DATA for the ethereum oracle data spec is received and the ethereum oracle is set to DEACTIVATED. (<a name="0082-ETHD-022" href="#0082-ETHD-022">0082-ETHD-022</a>)
9. Only one oracle data event is emitted for data that matches multiple data sources - Create 2 markets with ethereum oracle settlement specs that use the same settlement key such that - the first settlement spec expects settlement data to be greater than 100 and the second expects greater than 200. Now send it a settlement data of 300. One single event BUS_EVENT_TYPE_ORACLE_DATA for the settlement data is emitted with both matching ethereum oracle data sources listed within the event. Both markets are settled and both the data sources are DEACTIVATED. (<a name="0082-ETHD-023" href="#0082-ETHD-023">0082-ETHD-023</a>)
10. Different oracle data events for multiple spec id's with non matching filter values - Create 2 markets with ethereum oracle settlement specs that use the same settlement key such that - the first settlement spec expects settlement data to be greater than 100 and the second expects greater than 200. Now send it a settlement data of 50. NO data events for BUS_EVENT_TYPE_ORACLE_DATA. Send settlement data of 150. One single event BUS_EVENT_TYPE_ORACLE_DATA emitted for the settlement data is emitted with matching ethereum oracle data spec for Market1, market1 is settled and the data source is set to DEACTIVATED. Send settlement data of 250. One single event BUS_EVENT_TYPE_ORACLE_DATA emitted for the settlement data is emitted with matching ethereum oracle data spec for Market2, Market2 is settled and the data source is set to DEACTIVATED. (<a name="0082-ETHD-024" href="#0082-ETHD-024">0082-ETHD-024</a>)
11. Network wide contract error should be reported via oracle data events (<a name="0082-ETHD-025" href="#0082-ETHD-025">0082-ETHD-025</a>)
12. Different contracts on different markets - Create 2 markets with ethereum oracle settlement data sources containing different contract addresses and with *different* settlement keys, ut with all conditions and filters the same. Confirm that sending settlement value that passes the market spec filter only settles one market. (<a name="0082-ETHD-050" href="#0082-ETHD-050">0082-ETHD-050</a>)
13. Different contracts on different markets - Create 2 markets with ethereum oracle settlement data sources containing different contract addresses and with the *same* settlement keys, but with all conditions and filters the same. Confirm that sending settlement value that passes the market spec filter only settles one market. (<a name="0082-ETHD-051" href="#0082-ETHD-051">0082-ETHD-051</a>)
14. Phase 2 - System needs to emit an error via the TX RESULT event if the data source does NOT emit events in a timely fashion. e.g. if the data source is expected to emit events every 5 minutes and if we do not receive 3 consecutive events , then raise an error via the TX RESULT event (<a name="0082-PLAZZO-003" href="#0082-PLAZZO-003">0082-PLAZZO-003</a>)
15. Phase 2 - Define behaviour for missed events / missed scheduled smart contract calls - e.g. if an oracle data source is scheduled to emit events every 10 minutes and we miss 5 events because of protocol upgrade or some other outage - then do we catch up those events or skip those events ? Maybe this is defined in the oracle data source definition (<a name="0082-PLAZZO-004" href="#0082-PLAZZO-004">0082-PLAZZO-004</a>)

### New Network parameters

1. New network parameter - ethereum.oracles.enabled. Setting this to 0 should NOT allow market creation and market updates with ethereum oracles. (<a name="0082-ETHD-028" href="#0082-ETHD-028">0082-ETHD-028</a>)
2. New network parameter - ethereum.oracles.enabled. Setting this to 1 should allow market creation amd market updates with ethereum oracles. (<a name="0082-ETHD-029" href="#0082-ETHD-029">0082-ETHD-029</a>)

### Negative Tests

1. Set up a new data source with invalid contract address - should fail validations (Phase 2 - listening for invalid event ) (<a name="0082-ETHD-030" href="#0082-ETHD-030">0082-ETHD-030</a>)
2. Phase 2 - Set up a data source for listening to a particular event sent at a frequency of 2 secs. The oracle data source stops emitting events after emitting a couple of events. Raise and error via the TX RESULT event  if 5 consecutive events are missed - need to ratify / expand on this (<a name="0082-PLAZZO-005" href="#0082-PLAZZO-005">0082-PLAZZO-005</a>)
3. Phase 2 - Create an oracle source listening for a particular event and specify an incorrect ABI format for the event. Proposal should fail validation and should return an error (<a name="0082-PLAZZO-006" href="#0082-PLAZZO-006">0082-PLAZZO-006</a>)
4. Create an oracle that calls a read method of a smart contract and specify an incorrect ABI format for the event. Proposal should fail validation and should return an error (<a name="0082-ETHD-034" href="#0082-ETHD-034">0082-ETHD-034</a>)
5. Set up a network such that different vega nodes receive conflicting results from an identical ethereum contract call. Attempt to settle a market using that contract. Observe that if there are not enough nodes voting in agreement, the market is not settled (<a name="0082-ETHD-035" href="#0082-ETHD-035">0082-ETHD-035</a>)

### API

1. Ability to query oracle data sources via an API endpoint (REST, gRPC and graphQL) - filters should be available for data source - internal OR external, status - Active / Inactive / Expired (<a name="0082-ETHD-038" href="#0082-ETHD-038">0082-ETHD-038</a>)
2. Ability to query historic data sent by an oracle data source and processed by vega network (<a name="0082-ETHD-039" href="#0082-ETHD-039">0082-ETHD-039</a>)

### Checkpoints

1. Oracle data sources should be stored in checkpoints and should be restored when restarting a network from checkpoints. Therefore enacted markets with termination or settlement ethereum data sources are able to terminate and settle correctly post restart. (<a name="0082-ETHD-040" href="#0082-ETHD-040">0082-ETHD-040</a>)
2. Ensure that any ethereum oracle events that were generated during network downtime are correctly processed as soon as the network is restored and operational. This means that any termination or settlement actions that would of occurred during downtime are immediately actioned when network is up and we ensure they are processed in sequenced that they were received by the core polling. (<a name="0082-ETHD-041" href="#0082-ETHD-041">0082-ETHD-041</a>)

### Snapshots

1. Oracle data sources linked to markets should be stored on snapshots and should be able to be restored from snapshots. The states of the oracle data sources should be maintained across any markets where they are linked to ethereum data sources. (<a name="0082-ETHD-042" href="#0082-ETHD-042">0082-ETHD-042</a>)

### Protocol Upgrade

1. Have a network running with a couple of futures markets with a mix of internal, external, open and ethereum oracles. Perform a protocol upgrade. Once the network is up , the state of the various data sources should be the same as before the protocol upgrade (<a name="0082-ETHD-043" href="#0082-ETHD-043">0082-ETHD-043</a>)
2. Have a network running with a couple of perpetual markets with a mix of internal, external, open and ethereum oracles. Perform a protocol upgrade. Once the network is up , the state of the various data sources should be the same as before the protocol upgrade (<a name="0082-ETHD-044" href="#0082-ETHD-044">0082-ETHD-044</a>)
3. Create a futures market with an ethereum oracle for termination such that it polls at a specific time. Perform a protocol upgrade such that the termination triggers in the middle of the protocol upgrade. Once the network is up , the termination should be triggered and the market should be terminated. (<a name="0082-ETHD-045" href="#0082-ETHD-045">0082-ETHD-045</a>)
4. Create a futures market with an ethereum oracle for settlement such that it polls at a specific time. Perform a protocol upgrade such that the settlement price matching the filters is triggered in the middle of the protocol upgrade. Once the network is up , the settlement should be triggered and the market should be terminated. (<a name="0082-ETHD-047" href="#0082-ETHD-047">0082-ETHD-047</a>)
5. Create a perpetual market with an ethereum oracle for settlement such that it polls at a specific time. Perform a protocol upgrade such that the settlement price matching the filters is triggered in the middle of the protocol upgrade. Once the network is up , the settlement should be triggered and the market should be terminated. (<a name="0082-ETHD-048" href="#0082-ETHD-048">0082-ETHD-048</a>)
6. Ensure that markets with ethereum termination and settlement data sources continue to successfully terminate and settle markets after the protocol upgrade. (<a name="0082-ETHD-049" href="#0082-ETHD-049">0082-ETHD-049</a>)

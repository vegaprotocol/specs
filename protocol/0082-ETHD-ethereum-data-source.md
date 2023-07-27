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

1. Using the existing ways to create or update a market via governance proposals, define data sources for settlement and termination as the result of calling a read method of a smart contract on ethereum network. (Phase 2 of this step would be defining an oracle that is based on listening for events on ethereum network) (<a name="0082-ETHD-001" href="#0082-ETHD-001">0082-ETHD-001</a>)
2. All current governance rules that apply to propose / submit / vote on a proposal should be applicable for the ethereum oracle data source creation / amendment  (<a name="0082-ETHD-002" href="#0082-ETHD-002">0082-ETHD-002</a>)
3. Create more than spam.protection.max.proposals oracle data source proposals in an epoch - proposal rejected with error message (<a name="0082-ETHD-003" href="#0082-ETHD-003">0082-ETHD-003</a>)
4. Create ethereum oracles based on calling a read method of a smart contract by supplying incorrect ABI (Phase 2 - oracle based on listening for events) (<a name="0082-ETHD-004" href="#0082-ETHD-004">0082-ETHD-004</a>)

### External Oracles - Amendments

1. Amend the oracle data source via governance proposals. Amendments should take effect as soon as the proposal is enacted (<a name="0082-ETHD-005" href="#0082-ETHD-005">0082-ETHD-005</a>)
2. Amend an existing ethereum data source and change the contract address and enact the proposal. Once enacted, the data should be sourced from the new smart contract. Try amending the other fields in the oracle data source and the changes should take effect after the proposals are enacted (<a name="0082-ETHD-006" href="#0082-ETHD-006">0082-ETHD-006</a>)
3. Phase 2 - Amend an existing ethereum data source and change the events that we are listening to and enact the proposal. Once enacted , the data should be sourced from the amended events. Try amending the other fields in the oracle data source and the changes should take effect after the proposals are enacted (<a name="0082-ETHD-007" href="#0082-ETHD-007">0082-ETHD-007</a>)

### External Oracles - Deletions

1. Aligned with the existing logic, when no market listens to a data source, whatever that source is, it is automatically disregarded / deleted from the engine. Same applies for ethereum oracles (<a name="0082-ETHD-008" href="#0082-ETHD-008">0082-ETHD-008</a>)
2. When ethereum oracle is referenced / used by an existing market, it should not be deleted (<a name="0082-ETHD-009" href="#0082-ETHD-009">0082-ETHD-009</a>)
3. If a single data source is used by multiple markets, then should NOT be able to delete the data source even if one of those markets is actively using the data source (<a name="0082-ETHD-010" href="#0082-ETHD-010">0082-ETHD-010</a>)

### External Oracles - Validations

1. Validate if the smart contract address is valid (<a name="0082-ETHD-011" href="#0082-ETHD-011">0082-ETHD-011</a>)
2. Validate if the data elements of the oracle data source is valid - e.g. source for a value that's returned as boolean but have a filter / condition for greater than 0 (<a name="0082-ETHD-012" href="#0082-ETHD-012">0082-ETHD-012</a>)
3. Validations for min / max frequency of listening for events / read a smart contract (<a name="0082-ETHD-013" href="#0082-ETHD-013">0082-ETHD-013</a>)
4. When a proposal that uses ethereum oracles, defines incorrect data (contract address, ABI) the system should throw an error and the proposal should not pass validation (<a name="0082-ETHD-014" href="#0082-ETHD-014">0082-ETHD-014</a>)
5. Any mismatch between expected fields and received fields should emit an error via the TX RESULT event (<a name="0082-ETHD-016" href="#0082-ETHD-016">0082-ETHD-016</a>)

### New Network parameters

1. Test min / max values / validations for any new network parameters that are added (<a name="0082-ETHD-017" href="#0082-ETHD-017">0082-ETHD-017</a>)
2. Test the successful disabling / enabling of ethereum oracles when the new network parameter "ethereum.oracles.enabled" is set to false or true respectively (<a name="0082-ETHD-018" href="#0082-ETHD-018">0082-ETHD-018</a>)

### Negative Tests

1. Set up a new data source with invalid contract address - should fail validations (Phase 2 - listening for invalid event ) (<a name="0082-ETHD-019" href="#0082-ETHD-019">0082-ETHD-019</a>)
2. Data source returns incorrect data - raise an error via the TX RESULT event. The data source is expected to send a positive price for an asset BUT sends a negative value (<a name="0082-ETHD-020" href="#0082-ETHD-020">0082-ETHD-020</a>)
3. Phase 2 - Set up a data source for listening to a particular event sent at a frequency of 2 secs. The oracle data source stops emitting events after emitting a couple of events. Raise and error via the TX RESULT event  if 5 consecutive events are missed - need to ratify / expand on this (<a name="0082-ETHD-021" href="#0082-ETHD-021">0082-ETHD-021</a>)
4. Phase 2 - Create an oracle source listening for a particular event and specify an incorrect ABI format for the event. Proposal should fail validation and should throw an error (<a name="0082-ETHD-022" href="#0082-ETHD-022">0082-ETHD-022</a>)
5. Create an oracle that calls a read method of a smart contract and specify an incorrect ABI format for the event. Proposal should fail validation and should throw an error (<a name="0082-ETHD-023" href="#0082-ETHD-023">0082-ETHD-023</a>)
6. Will need some tests around consensus, will require setting up a network and having some nodes receive different values for the same oracle data point and testing that the oracle data point is/is not published depending on voting (<a name="0082-ETHD-024" href="#0082-ETHD-024">0082-ETHD-024</a>)

### API

1. Ability to query oracle data sources via an API endpoint - filters should be available for data source - internal OR external, status - Active / Inactive / Expired (<a name="0082-ETHD-025" href="#0082-ETHD-025">0082-ETHD-025</a>)
2. Ability to query historic data sent by an oracle data source (<a name="0082-ETHD-026" href="#0082-ETHD-026">0082-ETHD-026</a>)

### Non Functional

1. System needs to emit an error via the TX RESULT event if the data source does NOT return data in a timely fashion - e.g. the read method of the smart contract take too long to return data OR times out (<a name="0082-ETHD-027" href="#0082-ETHD-027">0082-ETHD-027</a>)
2. Phase 2 - System needs to emit an error via the TX RESULT event if the data source does NOT emit events in a timely fashion. e.g. if the data source is expected to emit events every 5 minutes and if we do not receive 3 consecutive events , then raise an error via the TX RESULT event (<a name="0082-ETHD-028" href="#0082-ETHD-028">0082-ETHD-028</a>)
3. Phase 2 - Define behaviour for missed events / missed scheduled smart contract calls - e.g. if an oracle data source is scheduled to emit events every 10 minutes and we miss 5 events because of protocol upgrade or some other outage - then do we catch up those events or skip those events ? Maybe this is defined in the oracle data source definition (<a name="0082-ETHD-029" href="#0082-ETHD-029">0082-ETHD-029</a>)
4. If an oracle data source is inactive - then any events / any data received from that oracle data source is NOT processed (<a name="0082-ETHD-030" href="#0082-ETHD-030">0082-ETHD-030</a>)
5. SPAM rules if any defined should be tested for (<a name="0082-ETHD-031" href="#0082-ETHD-031">0082-ETHD-031</a>)
6. NOT all data sourced should be stored on chain - invalid / incorrect data is filtered out and is NOT processed / stored on chain - understand what the rules are and design the AC's / test accordingly (<a name="0082-ETHD-032" href="#0082-ETHD-032">0082-ETHD-032</a>)

### Usage

1. It should be possible to use only ethereum oracle data sources in a market proposal, or create any combination with any of the other types of currently existing external or internal data sources (<a name="0082-ETHD-034" href="#0082-ETHD-034">0082-ETHD-034</a>)
2. Create a market to use an internal data source to terminate a market and an ethereum oracle to settle the market (<a name="0082-ETHD-035" href="#0082-ETHD-035">0082-ETHD-035</a>)
3. Create a market to use an external data source to terminate a market and a manual oracle to settle the market (<a name="0082-ETHD-036" href="#0082-ETHD-036">0082-ETHD-036</a>)
4. Data sourcing should be completely decoupled from data filtering (<a name="0082-ETHD-037" href="#0082-ETHD-037">0082-ETHD-037</a>)
4. Ethereum oracle data sources should only forward data after a configurable number of confirmations (<a name="0082-ETHD-046" href="#0082-ETHD-046">0082-ETHD-046</a>)

### Checkpoints

1. Oracle data sources should be stored in checkpoints and should be restored when restarting a network from checkpoints (<a name="0082-ETHD-038" href="#0082-ETHD-038">0082-ETHD-038</a>)
2. Restart a network with an active external data source from checkpoint. Ensure the data source is active and either catches up all missed events or starts processing new events based on config (<a name="0082-ETHD-039" href="#0082-ETHD-039">0082-ETHD-039</a>)

### Snapshots

1. Oracle data sources should be stored on snapshots and should be able to be restored from snapshots (<a name="0082-ETHD-040" href="#0082-ETHD-040">0082-ETHD-040</a>)
2. Restart a network with an active external data source from snapshot. Ensure the data source is active and either catches up all missed events or starts processing new events based on config (<a name="0082-ETHD-041" href="#0082-ETHD-041">0082-ETHD-041</a>)

### Protocol Upgrade

1. Create / amend an external oracle data source and before it is enacted perform a protocol upgrade. The oracle data source should be enacted at the correct time after the upgrade (<a name="0082-ETHD-042" href="#0082-ETHD-042">0082-ETHD-042</a>)
2. Create / amend an external oracle data source with enactment time that falls during a protocol upgrade. The oracle data source should be enacted immediately after the network is up after the protocol upgrade (<a name="0082-ETHD-043" href="#0082-ETHD-043">0082-ETHD-043</a>)
3. Phase 2 - Have a network running g with a mix of internal and external active and inactive oracles. Perform a protocol upgrade. Once the network is up , the state of the various oracles should be the same as before the protocol upgrade and either catch up all missed events or start processing new events based on config (<a name="0082-ETHD-044" href="#0082-ETHD-044">0082-ETHD-044</a>)

### Regression

1. The ethereum oracles feature ONLY changes the way we source the data BUT does not change the way the sourced data is filtered / processed / used by the system . So in theory all existing oracle data sourcing tests should pass. In addition , it should be possible to run the existing tests by swapping the interval oracle data source for an external one (<a name="0082-ETHD-045" href="#0082-ETHD-045">0082-ETHD-045</a>)

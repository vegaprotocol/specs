# Ethereum data source


## Summary

This specification adds a new way of sourcing data from the Ethereum blokchain to allow arbitrary data from the Ethereum blockchain to be ingested as a [data source](./0045-DSRC-data_sourcing.md). 
This is in addition to the existing [Ethereum bridge](./0031-ETHB-ethereum_bridge_spec.md), which is unchanged by this spec.


## Description

Currently, data is sourced from Ethereum only as a result of watching for pre-defined events, on a specific contract, at a specific address. 
Namely, the ERC20 bridge contract.
These events are picked up by the [event queue](./0036-BRIE-event_queue.md) processor and submitted by each node as transactions to the Vega chain.
Once a quroum of nodes have ratified the transaction, it is reflected in the Vega state.

Ethereum data sources extend this in three important ways:

1. In addition to listening for events defined on a contract, `read` methods can be called on a contract.

2. The event to listen for or function to be read (along with any parameters that must be passed) are specified as part of the data source, rather than being pre-defined across the whole system.

3. The address of the contract being observed is also specified as part of the data source.


Like all data sources, Ethereum oracles may be subject to filters or other processing or aggregation functions. 
Once observed, the data is treated as any other data source and available to any part of the system that accepts a data source as input.
The event queue may evaluate filters before submitting the observation to the Vega chain, in order to avoid submitting transactions containing data that will be dropped due to filters in any case.
Particularly, if the 


## Functional design

### Contracts and ABI

An Ethereum oracle has as its subject a smart contract that is deployed on the Ethereum blockchain.
All such contracts have an address, and an "ABI" that defines the methods an events exposed by the contract.
In order interpret the oracle specification and interact with the smart contract, both the contract address and Ethereum ABI JSON for the contract (or a subset, covering the relevant parts) must therefore be included in the oracle specification.

Event data and data returned from functions will be emitted by the Ethereum node in an ABI-encoded format.
This data, including any structs should be decoded using the ABI into a JSON-like representation.

Note: as with any data source containing JSON formatted (or other arbitrary structured) data, the data required by the consumer of the data source may be a fields or sub-objects (including nested fields and objects).
The data sourcing framework therefore requires functionality to apply a query/selector extract the relevant subset of the observed data and pass it to the next consumer.
This would be expected to use JSONPath/JSONPointer or similar, and be applicable to any arbitrary JSON.
Regardless, the specification of this functionaltiy is out of scope for this document and the approach must be standardised across the data sourcing framework (for example, specifiyng the target of filters must use the same format as selecting data to pass on).


### Ethereum chain data enrichment

All data sourced from Ethereum should be structured as an object containing both a payload and Ethereum chain metadata, namely:

- Ethereum block height at which the data was observed/event ocurred

- Ethereum block timestamp at which the data was observed/event ocurred


These data can be used as the subject of filters or even extracted as the oracle data of interest.
Filters on Ethreum block height, Ethereum timestamp, or Vega timestamp should be applied prior to submitting the data to the Vega chain, in addition to being re-applied when the data is confirmed on chain. 
This would prevent spamming the Vega chain with event data that is not relevant.


### Events

When the data source is an event emitted by the Ethereum contract, the event name must be specified in the data source specification.
The specified event must be defined in the supplied ABI.


### Contract read

When the data source is a contract read, the method name and any arguments to be passed must be specified in the data source specification.
The specified method must be defined in the supplied ABI.


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


## Assessment criteria

TBD

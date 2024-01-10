# Ethereum RPC and EVM based data sources

## Summary

This specification adds a new way of sourcing data from any chain or Ethereum Layer 2 blockchain (L2) that supports Ethereum RPC calls and runs an EVM.

> [!TIP]
> A Layer 2 blockchain refers to network protocols that are layered on top of a Layer 1 solution. Layer 2 protocols use the Layer 1 blockchain for network and security infrastructure.

The data is to be ingested as an Ethereum [data source](./0045-DSRC-data_sourcing.md) but pointing at a different RPC endpoint.
Hence this is in addition to and building upon [Ethereum data source](./0082-ETHD-ethereum-data-source.md).

## Description

In addition to listening to Ethereum events and reading from Ethereum contracts as described in [Ethereum data source](./0082-ETHD-ethereum-data-source.md) it will be possible for Vega nodes to listen to events from and read from other chains that implement Ethereum RPC and run EVM, in particular Ethereum L2s.

The overarching principle is that the chain provides ethereum RPC / EVMs and thus contracts and ABIs are assumed to be functionally the same as on Ethereum itself.

## Registration / removal

A new network parameter, a JSON list of network id / chain id / name one per Ethereum RPC and EVM chain will be used for setting supported L2. This is set via [governance](./0028-GOVE-governance.md).
Name `blockchains.ethereumRpcAndEvmCompatDataSourcesConfig`.
Example value:

```json
{"configs": [{"network_id": 10, "chain_id": 10, "confirmations": 3, "name":"optimism"}]}
```

Duplicate values of `network_id`, `chain_id` or  `name` are not allowed (an update will be rejected at validation stage).
Any update must always change the entire JSON (it's not possible to change individual entries).
In current minimal scope, at proposal validation, check that only change is

1. changing number of confirmation or
1. adding another source.

For later release: A proposal to *remove* a registered Ethereum RPC+EVM compatible chain / L2 must fail at enactment stage if a market is referencing an `EthRpcEvmCompatible` data source.

A proposal for a new market will fail at enactment stage if it's referencing an `EthRpcEvmCompatible` that's not registered.


## Acceptance criteria

### External Oracles - Creation

- It is possible to add `EthRpcEvmCompatible` via governance (<a name="0087-EVMD-001" href="#0087-EVMD-001">0087-EVMD-001</a>).

### External Oracles - External Chain Config Changes

- At network proposal validation step we check that the only change to `blockchains.ethereumRpcAndEvmCompatDataSourcesConfig` is to either change number of confirmations or add another external chain. (<a name="0087-EVMD-043" href="#0087-EVMD-043">0087-EVMD-043</a>)

### External Oracles - Deactivation (not scoped in Palazzo milestone)

- It is possible to remove an `EthRpcEvmCompatible` via governance. The proposal will fail at enactment stage if there is any market that's not settled / closed that reference the `EthRpcEvmCompatible`.  This is a future requirement and does not have an AC code.


### External Oracles - Market Amendments

- It may happen that an `EthRpcEvmCompatible` that cannot be read from is proposed (because not enough validator nodes have it configured etc.). In that case a proposed / enacted market will not see the oracle inputs but it must be possible to change the said market via on-chain governance (<a name="0087-EVMD-003" href="#0087-EVMD-003">0087-EVMD-003</a>).
- Update an existing futures market using the market update proposal to change the `EthRpcEvmCompatible` chain referenced, smart contract address and read method. The changes take effect after the market update proposal is enacted and data is sourced from the new smart contract. The old data source  will be deactivated when the proposal is enacted (<a name="0087-EVMD-004" href="#0087-EVMD-004">0087-EVMD-004</a>)
- Using the market update proposal all data elements for the ethereum oracles can be updated. On successful enactment, a new oracle data source is created for the market. In case any existing data source matches the new data source, then a new data source is not created and the existing one is used (<a name="0087-EVMD-005" href="#0087-EVMD-005">0087-EVMD-005</a>)
- Ensure existing oracle data sources are deactivated when market data sources are amended on another market. Create 2 markets to use different ethereum oracles for termination and settlement. Two sets of ethereum oracles are created and are ACTIVE. Then amend Market 2 to use exactly the same ethereum oracles for termination and settlement as Market1. Now ,the ethereum oracles originally created for for Market2 should be set to DEACTIVATED. No new ethereum oracles should be created and the Market2 should use the existing ethereum oracles created for Market1 (<a name="0087-EVMD-006" href="#0087-EVMD-006">0087-EVMD-006</a>)
- Ensure that when a market data source type is amended from internal, external, ethereum or open (coinbase) to an alternative for both termination and settlement we see that old data source is deactivated (if no other market is using) and we see the new data source created and it supports termination and settlement specific to its data source type (<a name="0087-EVMD-007" href="#0087-EVMD-007">0087-EVMD-007</a>)


### External Oracles - Validations

- A market proposal that reference an `EthRpcEvmCompatible` that's not active will fail at enactment stage (<a name="0087-EVMD-008" href="#0087-EVMD-008">0087-EVMD-008</a>).
- Validate if the smart contract address is valid (<a name="0087-EVMD-009" href="#0087-EVMD-009">0087-EVMD-009</a>)
- Validate if the data elements of the oracle data source is valid - e.g. call the smart contract and check if the types in the ABI match whats provided in the oracle spec (<a name="0087-EVMD-010" href="#0087-EVMD-010">0087-EVMD-010</a>)
- Validations for min / max frequency of listening for events / read a smart contract (<a name="0087-EVMD-011" href="#0087-EVMD-011">0087-EVMD-011</a>)
- When a proposal that uses ethereum oracles, defines incorrect data (contract address, ABI) the system should return an error and the proposal should not pass validation (<a name="0087-EVMD-012" href="#0087-EVMD-012">0087-EVMD-012</a>)
- Any mismatch between expected fields/field types and received fields/field types should emit an error event (<a name="0087-EVMD-013" href="#0087-EVMD-013">0087-EVMD-013</a>)


### Usage

- Two different markets may reference two identical `EthRpcEvmCompatible` contracts and ABIs, even with same contract address *but* on two different Ethereum L2s and they each get the correct values i.e. if we have market 1 with

```yaml
source: EthereumEvent {
            source_chain_id: 0x123
            contract: 0xDEADBEEF
            ABI: "...JSON..."
            event: "MyFaveEvent"
```

and market 2 with

```yaml
source: EthereumEvent {
            source_chain_id: 0x789
            contract: 0xDEADBEEF
            ABI: "...JSON..."
            event: "MyFaveEvent"
```

Then market 1 only sees events of that type from `EthRpcEvmCompatible` 0x123 while market 2 only sees events of that type from `EthRpcEvmCompatible` 0x789 (<a name="0087-EVMD-014" href="#0087-EVMD-014">0087-EVMD-014</a>).

- It should be possible to use only `EthRpcEvmCompatible` data sources in a market proposal, or create any combination with any of the other types of currently existing external or internal data sources (<a name="0087-EVMD-015" href="#0087-EVMD-015">0087-EVMD-015</a>)
- Create a market to use an internal data source to terminate a market and an `EthRpcEvmCompatible` to settle the market (<a name="0087-EVMD-016" href="#0087-EVMD-016">0087-EVMD-016</a>)
- Create a market to use an external data source to terminate a market and an `EthRpcEvmCompatible` to settle the market (<a name="0087-EVMD-017" href="#0087-EVMD-017">0087-EVMD-017</a>)
- Create a market to use an open oracle data source to settle a market and an `EthRpcEvmCompatible` to terminate the market (<a name="0087-EVMD-018" href="#0087-EVMD-018">0087-EVMD-018</a>)
- `EthRpcEvmCompatible` events should only be sent when the filter is matched, this can be verified using an API and the core/data node events (BUS_EVENT_TYPE_ORACLE_DATA) (<a name="0087-EVMD-019" href="#0087-EVMD-019">0087-EVMD-019</a>)
- `EthRpcEvmCompatible` data sources should only forward data after a configurable number of confirmations (<a name="0087-EVMD-020" href="#0087-EVMD-020">0087-EVMD-020</a>)
- Create 2 markets to use the same `EthRpcEvmCompatible` data source for termination say DS-T1 but two different `EthRpcEvmCompatible` data sources for settlement DS-S1 and DS-S2. Now trigger the termination ethereum oracle data source. Both markets should be terminated and the data source DS-T1 is set to DEACTIVATED and the data sources DS-S1 and DS-S2 are still ACTIVE. Now settle market1. DS-S1 is set to DEACTIVATED and DS-S2 is still active. (<a name="0087-EVMD-021" href="#0087-EVMD-021">0087-EVMD-021</a>)
- Create a market to use an `EthRpcEvmCompatible` data source for termination configured such that - it expects a boolean value True for termination and the contract supplying the termination value is polled every 5 seconds. Set the contract to return False for termination. The market is not terminated. The data source is still ACTIVE and no BUS_EVENT_TYPE_ORACLE_DATA events for that ethereum oracle spec are emitted. Then set the contract to return True for termination. The market is terminated and an event for BUS_EVENT_TYPE_ORACLE_DATA for the ethereum oracle data spec is received and the ethereum oracle is set to DEACTIVATED. (<a name="0087-EVMD-022" href="#0087-EVMD-022">0087-EVMD-022</a>)
- One oracle data event is emitted for data that matches each data source - Create 2 markets with ethereum oracle settlement specs that use the same settlement key such that - the first settlement spec expects settlement data to be greater than 100 and the second expects greater than 200. Now send it a settlement data of 300. One single event BUS_EVENT_TYPE_ORACLE_DATA for the settlement data is emitted for each matching `EthRpcEvmCompatible` data source i.e. in this case, two oracle data events will be emitted - one for each settlement data source. Both markets are settled and both the data sources are DEACTIVATED. (<a name="0087-EVMD-023" href="#0087-EVMD-023">0087-EVMD-023</a>)
- Different oracle data events for multiple spec id's with non matching filter values - Create 2 markets with ethereum oracle settlement specs that use the same settlement key such that - the first settlement spec expects settlement data to be greater than 100 and the second expects greater than 200. Now send it a settlement data of 50. NO data events for BUS_EVENT_TYPE_ORACLE_DATA. Send settlement data of 150. One single event BUS_EVENT_TYPE_ORACLE_DATA emitted for the settlement data is emitted with matching ethereum oracle data spec for Market1, market1 is settled and the data source is set to DEACTIVATED. Send settlement data of 250. One single event BUS_EVENT_TYPE_ORACLE_DATA emitted for the settlement data is emitted with matching ethereum oracle data spec for Market2, Market2 is settled and the data source is set to DEACTIVATED. (<a name="0087-EVMD-024" href="#0087-EVMD-024">0087-EVMD-024</a>)
- Network wide contract error should be reported via oracle data events (<a name="0087-EVMD-025" href="#0087-EVMD-025">0087-EVMD-025</a>)
- Different contracts on different markets - Create 2 markets with `EthRpcEvmCompatible` settlement data sources containing different contract addresses and with *different* settlement keys, but with all conditions and filters the same. Confirm that sending settlement value that passes the market spec filter only settles one market. (<a name="0087-EVMD-026" href="#0087-EVMD-026">0087-EVMD-026</a>)
- Different contracts on different markets - Create 2 markets with `EthRpcEvmCompatible` settlement data sources containing different contract addresses and with the *same* settlement keys, but with all conditions and filters the same. Confirm that sending settlement value that passes the market spec filter only settles one market. (<a name="0087-EVMD-027" href="#0087-EVMD-027">0087-EVMD-027</a>)


### Negative Tests

- Set up a new data source with invalid contract address - should fail validations (<a name="0087-EVMD-028" href="#0087-EVMD-028">0087-EVMD-028</a>).
- Create an oracle that calls a read method of a smart contract and specify an incorrect ABI format for the event. Proposal should fail validation and should return an error (<a name="0087-EVMD-029" href="#0087-EVMD-029">0087-EVMD-029</a>)
- Set up a network such that different vega nodes receive conflicting results from an identical `EthRpcEvmCompatible` contract call. Attempt to settle a market using that contract. Observe that if there are not enough nodes voting in agreement, the market is not settled (<a name="0087-EVMD-030" href="#0087-EVMD-030">0087-EVMD-030</a>)

### API

- Ability to query data source specs defined for ethereum oracle sources, for settlement and termination, via an API endpoint (REST, gRPC and graphQL) - filters should be available for data source - internal OR external, status - Active / Inactive / Expired (<a name="0087-EVMD-031" href="#0087-EVMD-031">0087-EVMD-031</a>)
- Ability to query historic data sent by an ethereum oracle source, for settlement and termination, and processed by a market in vega network (<a name="0087-EVMD-032" href="#0087-EVMD-032">0087-EVMD-032</a>)


### Snapshots

- Oracle data sources linked to markets should be stored on snapshots and should be able to be restored from snapshots. The states of the oracle data sources should be maintained across any markets where they are linked to `EthRpcEvmCompatible` data sources. (<a name="0087-EVMD-033" href="#0087-EVMD-033">0087-EVMD-033</a>)

### Protocol Upgrade

- Have a network running with a couple of futures markets with a mix of internal, external, open ethereum and `EthRpcEvmCompatible` oracles . Perform a protocol upgrade. Once the network is up , the state of the various data sources should be the same as before the protocol upgrade (<a name="0087-EVMD-034" href="#0087-EVMD-034">0087-EVMD-034</a>)
- Have a network running with a couple of perpetual markets with a mix of internal, external, open, ethereum and `EthRpcEvmCompatible` oracles . Perform a protocol upgrade. Once the network is up , the state of the various data sources should be the same as before the protocol upgrade (<a name="0087-EVMD-035" href="#0087-EVMD-035">0087-EVMD-035</a>)
- Create a futures market with an `EthRpcEvmCompatible` for termination such that it polls at a specific time. Perform a protocol upgrade such that the termination triggers in the middle of the protocol upgrade. Once the network is up , the termination should be triggered and the market should be terminated. (<a name="0087-EVMD-036" href="#0087-EVMD-036">0087-EVMD-036</a>)
- Create a futures market with an `EthRpcEvmCompatible` for settlement such that it polls at a specific time. Perform a protocol upgrade such that the settlement price matching the filters is triggered in the middle of the protocol upgrade. Once the network is up , the settlement should be triggered and the market should be terminated. (<a name="0087-EVMD-037" href="#0087-EVMD-037">0087-EVMD-037</a>)
- Create a perpetual market with an `EthRpcEvmCompatible` for settlement such that it polls at a specific time. Perform a protocol upgrade such that the settlement price matching the filters is triggered in the middle of the protocol upgrade. Once the network is up , the settlement should be triggered and the market should be terminated. (<a name="0087-EVMD-038" href="#0087-EVMD-038">0087-EVMD-038</a>)
- Ensure that markets with `EthRpcEvmCompatible` termination and settlement data sources continue to successfully terminate and settle markets after the protocol upgrade. (<a name="0087-EVMD-039" href="#0087-EVMD-039">0087-EVMD-039</a>)

### Perpetual futures focused tests

- Update an existing perpetuals market using the market update proposal to change from Ethereum to `EthRpcEvmCompatible` chain referenced, smart contract address and read method. The changes take effect after the market update proposal is enacted and data is sourced from the new smart contract. The old data source  will be deactivated when the proposal is enacted (<a name="0087-EVMD-040" href="#0087-EVMD-040">0087-EVMD-040</a>).
- Create a perpetual futures market which uses an `EthRpcEvmCompatible` chain reads/events contract data for settlement payment schedule from chain `A` and `EthRpcEvmCompatible` chain reads/events contract data for the index price from chain `B` (<a name="0087-EVMD-041" href="#0087-EVMD-041">0087-EVMD-041</a>).
- Create a perpetual futures market which uses an `EthRpcEvmCompatible` chain reads/events contract data for settlement payment schedule from; the trigger for the countdown to the first funding payment being publication of a valid value for the index price. The index price must not be available at the time the market is created and leaves opening auction; it must only become available sometime after. The aim is to test futures markets for underlyings that don't trade *yet* be where there is an agreed oracle source that will start publishing the price *once* they begin trading. (<a name="0087-EVMD-042" href="#0087-EVMD-042">0087-EVMD-042</a>).

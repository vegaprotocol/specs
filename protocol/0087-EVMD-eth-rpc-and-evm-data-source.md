# Ethereum RPC and EVM based data sources

## Summary

This specification adds a new way of sourcing data from any chain or Ethereum L2 that supports Ethereum RPC calls and runs an EVM.
The data is to be ingested as an Ethereum [data source](./0045-DSRC-data_sourcing.md) but pointing at a different RPC endpoint.
Hence this is in addition to and building upon [Ethereum data source](./0082-ETHD-ethereum-data-source.md).

## Description

In addition to listening to Ethereum events and reading from Ethereum contracts as described in [Ethereum data source](./0082-ETHD-ethereum-data-source.md) it will be possible for Vega nodes to listen to events from and read from other chains that implement Ethereum RPC and run EVM, in particular Ethereum L2.

The overarching principle is that the chain provides ethereum RPC / EVMs and thus contracts and ABIs are assumed to be functionally the same as on Ethereum itself.

## Registration / removal

A new network parameter, a JSON list of network id / chain id / name one per Ethereum RPC and EVM chain will be used for setting supported L2. This is set via [governance](./0028-GOVE-governance.md).
Name `blockchains.ethereumL2Configs`.
Example value:

```json
{"configs": [{"network_id": 10, "chain_id": 10, "confirmations": 3, "name":"optimism"}]}
```

Duplicate values of "network_id": 10, "chain_id" or  "name":"optimism" are not allowed (an update will be rejected at validation stage).
Any update must always change the entire JSON (it's not possible to change individual entries).
A proposal to *remove* a registered Ethereum RPC+EVM compatible chain / L2 must fail at enactment stage if a market is referencing an `EthRpcEvmCompatible` data source.
A proposal for a new market will fail at enactment stage if it's referencing an `EthRpcEvmCompatible` that's not registered.


## Acceptance criteria

- It is possible to add `EthRpcEvmCompatible` via governance (<a name="0087-EVMD-001" href="#0087-EVMD-001">0087-EVMD-001</a>).

- It is possible to remove an `EthRpcEvmCompatible` via governance. The proposal will fail at enactment stage if there is any market that's not settled / closed that reference the `EthRpcEvmCompatible` (<a name="0087-EVMD-002" href="#0087-EVMD-002">0087-EVMD-002</a>).

- A market proposal that reference an `EthRpcEvmCompatible` that's not active will fail at enactment stage (<a name="0087-EVMD-003" href="#0087-EVMD-003">0087-EVMD-003</a>).

- It may happen that an `EthRpcEvmCompatible` that cannot be read from is proposed (because not enough validator nodes have it configured etc.). In that case a proposed / enacted market will not see the oracle inputs but it must be possible to change the said market via on-chain governance (<a name="0087-EVMD-004" href="#0087-EVMD-004">0087-EVMD-004</a>).

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

Then market 1 only sees events of that type from `EthRpcEvmCompatible` 0x123 while market 2 only sees events of that type from `EthRpcEvmCompatible` 0x789 (<a name="0087-EVMD-005" href="#0087-EVMD-005">0087-EVMD-005</a>).

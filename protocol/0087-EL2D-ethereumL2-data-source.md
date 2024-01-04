# Ethereum L2s data sources

## Summary 

This specification adds a new way of sourcing data from the Ethereum L2s to allow arbitrary data from the Ethereum L2s running EVM to be ingested as a [data source](./0045-DSRC-data_sourcing.md). 
This is in addition to and building upon [Ethereum data source](./0082-ETHD-ethereum-data-source.md).

## Decription 

In addition to listening to Ethereum events and reading from Ethereum contrants as described in [Ethereum data source](./0082-ETHD-ethereum-data-source.md) it will be possible for Vega nodes to listen to events from and read from other Ethereum L2s. 

The overarching principle is that the L2s incorporate the ethereum EVMs and thus contracts and ABIs are assumed to be functionally the same as on Ethereum itself. 

## Registration / removal

A new network parameter, a JSDON list of network id / chain id / name one per L2 will be used for setting supported L2. This is set via [governance](./0028-GOVE-governance.md). 
Name `blockchains.ethereumL2Configs`.
Example value: 
```
{"configs": [{"network_id": 10, "chain_id": 10, "confirmations": 3, "name":"optimism"}]}
```
Duplicate values of "network_id": 10, "chain_id" or  "name":"optimism" or not allowed (an update will be rejected at validation stage).
Any updat emust always change the entire JSON (it's not possible to change individual entries).
A proposal to *remove* a registered L2 must fail at enactment stage if a market is referencing an EthL2 data source. 
A proposal for a new market will fail at enactment stage if it's referencing an EthL2 that's not registered. 


## Acceptance criteria

- It is possible to add EthL2 via governance. 

- It is possible to remove an EthL2 via governance. The proposal will fail at enactment stage if there is any market that's not settled / closed that reference the EthL2. 

- A market proposal that reference an EthL2 that's not active will fail at enactment stage.

- It may happen that an EthL2 that cannot be read from is proposed (because not enough validator nodes have it configured etc.). In that case a proposed / enacted market will not see the oracle inputs but it must be possible to change the said market via on-chain governance. 

- Two different markets may reference two identical EthL2 contracts and ABIs, even with same contract address *but* on two different EthL2 and they each get the correct values i.e. if we have market 1 with
```
source: EthereumEvent {
			source_chain_id: 0x123
            contract: 0xDEADBEEF
			ABI: "...JSON..."
			event: "MyFaveEvent"
```
and market 2 with
```
source: EthereumEvent {
			source_chain_id: 0x789
            contract: 0xDEADBEEF
			ABI: "...JSON..."
			event: "MyFaveEvent"
```
Then market 1 only sees events of that type from EthL2 0x123 while market 2 only sees events of that type from EthL2 0x789. 


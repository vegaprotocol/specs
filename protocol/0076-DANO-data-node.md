# Data Node Spec

Vega core node (consensus and non-consensus) nodes run the core protocol and only keep information required to do so. 

Users of the protocol often need various data (price history / delegation history / transfers etc.). The core node doesn't store these but only *emits events* when things change.

The job of the data node is to collect and store the events and make those available. Since storing "everything forever" will take up too much data it must be possible to configure (and change at runtime) what the data node stores and for how long (retention policy). 


## Working with events
Each chunk of data should contain the eventID that created it and the block from which the event was created.

Event is emitted on each occasion the blockchain time updates. For each chunk of data stored, label it with this time stamp. When a new timestamp event comes, start using that one. 

*Never* use the wall time for anything.

## Retention policies

It should be possible to configure to store only "current state" and no history of anything (in particular the order book). 

It should be possible to configure the data node so that all data older than any time period (e.g. `1m`, `1h`, `1h:22m:32s`, `1 months`) is deleted. 

It should be possible to configure the data node so that all data of certain type is deleted upon an event (and configurable with a delay) e.g. event: MarketID `xyz` settled + `1 week`. 

There will be a "default" configuration for what's considered "minimal useful" data node. 

## Balances and transfers

Store all
```
LedgerEntry {
  // One or more accounts to transfer from
  string from_account = 1;
  // One or more accounts to transfer to
  string to_account = 2;
  // An amount to transfer
  string amount = 3;
  // A reference for auditing purposes
  string reference = 4;
  // Type of ledger entry
  string type = 5;
  // Timestamp for the time the ledger entry was created, in nanoseconds since the epoch
  // - See [`VegaTimeResponse`](#api.VegaTimeResponse).`timestamp`
  int64 timestamp = 6;
}
```

and all
```
TransferBalance {
  // The account relating to the transfer
  Account account = 1;
  // The balance relating to the transfer
  string balance = 2;
}

TransferResponse {
  // One or more ledger entries representing the transfers
  repeated LedgerEntry transfers = 1;
  // One or more account balances
  repeated TransferBalance balances = 2;
}
```

Note that withdrawals and deposits (to / from other chains) are visible from the transfer and balance data. 


## Stake / Delegations / Validator Score history

All changes to staking and delegation must be stored. From this, the state at any time can be provided. 

Validator score changes and state at any time (validatorID, epoch, score, normalised score).

Validator performance metrics. 

Rewards per epoch per Vega ID (party, epoch, asset, amount, percentage of total, timestamp). 


## Governance proposal history

All proposals ever submitted + votes (asset, network parameter change, market).


## Trading Related Data

### Market Data
- as [specified in](./0021-market-data-spec.md). This is emitted once per block. This is kept for backward compatibility. Note that below we may duplicate some of this. 

### Market lifecycle events

- Market proposal enacted (this is a governance event). 
- Auction start, end, reason for entering, type. 
- Settlement / price data received event. 
- Trading terminated event.

### Prices History

All of these should be available at various time resolutions: on every change, on every blockchain time change, every minute, hour, 6 hours, day. Of course it's a design decision how to achieve this (if you store every change then you can build up the lower resolution series from that when the data is requested.)

- Best static bid, best static ask, static mid,
- Best bid, best ask, mid,
- Mark price
- If in auction, indicative uncrossing price and volume 
- Open interest 

### Liquidity provision data

- LP order submissions
- Equity-like share changes
- Market value proxy 
- Target stake
- Supplied stake

### Risk data

- Margin level events
- Model parameter changes
- Risk factor changes
- Price monitoring bound setting changes
- Price monitoring bounds

### Trade data

- Trade price, trade volume
- Closeout trades
- Loss socialisation event
- Position mark-to-market events

### Candle data

Whatever the candle data are, store them at the resolution of every blockchain time change and build up lower resolution series from that as you see fit. 

### Orders

Store the orders at the configured resolution. 

### APIs for historical data in a shape that is suitable for clients

It must be possible to augment APIs so data returned is in a shape and size that is appropriate for clients. The exact changes to APIs to be worked out as part of an on going process, and it wont be specified here.

### APIs for server side calculations

It must be possible to add to the data node APIs that return the result of calculations on the data node (in addition ot historical data). These calculations may use historical or real time core data but are not available in the core API as they would hinder performance. e.g. Estimates / Margin / risk calculations

# Acceptance criteria
1. Market depth state must be processed and built in a timely manner so that the correct real time information is available to the users without unnecessary delays. Using the recommended hardware specs for validators, the data node should be able to handle a continuous order events rate of 500 per second without falling behind. (<a name="0076-DANO-002" href="#0076-DANO-002">0076-DANO-002</a>)

## Data synchronisation
1. To ensure no loss of historical data access; data nodes must be able to have access to and synchronise all historical data since genesis block or LNL restart (<a name="0076-COSMICELEVATOR-001" href="#0076-COSMICELEVATOR-001">0076-COSMICELEVATOR-001</a>)
1. To ensure that new nodes joining the network have access to all historical data; nodes must be able to have access to and synchronise all historical data across the network without having to replay the full chain (<a name="0076-DANO-003" href="#0076-DANO-003">0076-DANO-003</a>)

### Data integrity
1. Data produced in the core snapshots aligns with the data-node data proving that what is returned by data-node matches core state at any given block height (<a name="0076-DANO-004" href="#0076-DANO-004">0076-DANO-004</a>)

### Data-node restoring:
1. Data loaded into the database from a data-node snapshot must match that of the snapshot. For example: Start a data-node from a data-node snapshot and compare the data in the database to that in the data-node snapshot. (<a name="0076-DANO-005" href="#0076-DANO-005">0076-DANO-005</a>)
1. Data loaded into the database from a data-node snapshot must match that of the snapshot when queried via the APIs. For example: Start a data-node from a data-node snapshot and compare the data exposed on the APIs to that in the data-node snapshot. Test using REST, gRPC and GraphQL (GraphQL should cover at least those used in the [project front end dApps](https://github.com/vegaprotocol/frontend-monorepo/actions/workflows/generate-queries.yml). (<a name="0076-COSMICELEVATOR-006" href="#0076-COSMICELEVATOR-006">0076-COSMICELEVATOR-006</a>)
1. As the network produces more blocks the data should be stored correctly in the data-node after a data-node snapshot restore. For example: Start a data-node from a data-node snapshot at a known block height, ensure the datanode continues to update from that block onwards. (<a name="0076-DANO-007" href="#0076-DANO-007">0076-DANO-007</a>)
1. No data is duplicated as the core emits events when catching up to the later block height. For example: Starting a core node at block height less than the data-node block height must result in no duplicated data (<a name="0076-DANO-008" href="#0076-DANO-008">0076-DANO-008</a>)
1. Starting a core node at block height more than the data-node block height must result in and error and a refusal to start (<a name="0076-DANO-014" href="#0076-DANO-014">0076-DANO-014</a>)
1. If a data-node snapshot fails during the restore the process, it should error and the node(s) wont start (<a name="0076-DANO-009" href="#0076-DANO-009">0076-DANO-009</a>)

### Data-node network determinism:
1. Data-node snapshots should be deterministic across all data-nodes on the network, using the recommended hardware and OS versions (<a name="0076-DANO-010" href="#0076-DANO-010">0076-DANO-010</a>)
1. Data-node databases should be the same across all data-nodes on the network when a data-node has been restored, or joined, using a data-node snapshot. For example: A network has one datanode (A) running, restore a new datanode (B) from a snapshot from node A, then take a snapshot immediately after on node B (assert A and Bs snapshots match) (<a name="0076-DANO-011" href="#0076-DANO-011">0076-DANO-011</a>)
1. Data-node API responses should be the same across all data-nodes on the network when a data-node has been restored, or joined, using a data-node snapshot. For example: A network has one datanode (A) running, restore a new datanode (B) from a snapshot from node A, then take a snapshot immediately after on node B (assert A and Bs APIs return the same data) (<a name="0076-COSMICELEVATOR-012" href="#0076-COSMICELEVATOR-012">0076-COSMICELEVATOR-012</a>)

### Schema compatibility:
1. It is possible to identify if schema versions are NOT backwards compatible. Pull existing network snapshots start network, run a protocol upgrade to at later version and ensure both the core state and data-node data is correct (<a name="0076-COSMICELEVATOR-013" href="#0076-COSMICELEVATOR-013">0076-COSMICELEVATOR-013</a>)

### General Acceptance
* The DataNode must be able to handle brief network outages and disconnects from the vega node (<a name="0076-DANO-015" href="#0076-DANO-015">0076-DANO-015</a>) 
* The validator node will only accept requests for event bus subscriptions. All other API subscription requests will be invalid. (<a name="0076-DANO-016" href="#0076-DANO-016">0076-DANO-016</a>)  
* The event bus stream is available from validators, non validators and the DataNode (<a name="0076-DANO-017" href="#0076-DANO-017">0076-DANO-017</a>)  
* All events that are emitted on the full unfiltered event stream are processed by the DataNode (no data is lost) (<a name="0076-DANO-018" href="#0076-DANO-018">0076-DANO-018</a>)  
* If a DataNode loses connection to a Vega node if will attempt to reconnect and if the cached data received from the Vega node is enough to continue working it can resume being a DataNode. (<a name="0076-DANO-019" href="#0076-DANO-019">0076-DANO-019</a>)  
* If the DataNode loses connection to a Vega node and it is unable to reconnect in time to see all the missing data, it will shutdown. (<a name="0076-DANO-020" href="#0076-DANO-020">0076-DANO-020</a>)  
* A DataNode will be able to detect a frozen event stream by the lack of block time updates and will shutdown. (<a name="0076-DANO-021" href="#0076-DANO-021">0076-DANO-021</a>)  

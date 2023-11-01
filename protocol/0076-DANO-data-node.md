# Data node

Vega core node (consensus and non-consensus) nodes run the core protocol and only keep information required to do so.

Users of the protocol often need various data (price history / delegation history / transfers etc.). The core node doesn't store these but only *emits events* when things change.

The job of the data node is to collect and store the events and make those available. Since storing "everything forever" will take up too much data it must be possible to configure (and change at runtime) what the data node stores and for how long (retention policy).

## Working with events

Each chunk of data should contain the `eventID` that created it and the block from which the event was created.

Event is emitted on each occasion the blockchain time updates. For each chunk of data stored, label it with this time stamp. When a new timestamp event comes, start using that one.

*Never* use the wall time for anything.

## Datanode Retention Modes

When initialising a datanode it should be possible to select one of the following data retention modes:

- Lite - the node retains sufficient data to be able to provide that latest state to clients and produce network history segments
- Standard (the default) - retains data according to the default retention policies of the datanode, these should be optionally configurable.
- Archive - retains all data.

It should be possible to configure the data node so that all data of certain type is deleted upon an event (and configurable with a delay) e.g. event: `MarketID` `xyz` settled + `1 week`.

## Balances and transfers

Store all

```proto
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

```proto
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

Validator score changes and state at any time (`validatorID`, epoch, score, normalised score).

Validator performance metrics.

Rewards per epoch per Vega ID (party, epoch, asset, amount, percentage of total, timestamp).

## Governance proposal history

All proposals ever submitted + votes (asset, network parameter change, market).

## Trading Related Data

### Market Data

- as [specified in](./0021-MDAT-market_data_spec.md). This is emitted once per block. This is kept for backward compatibility. Note that below we may duplicate some of this.

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

## Acceptance criteria

### Data synchronisation

1. To ensure no loss of historical data access; data nodes must be able to have access to and synchronise all historical data since genesis block or LNL restart (<a name="0076-DANO-001" href="#0076-DANO-001">0076-DANO-001</a>)
1. To ensure that new nodes joining the network have access to all historical data; nodes must be able to have access to and synchronise all historical data across the network without having to replay the full chain (<a name="0076-DANO-003" href="#0076-DANO-003">0076-DANO-003</a>)
1. Nodes must be able to start processing new blocks having loaded the only the most recent history  (<a name="0076-DANO-023" href="#0076-DANO-023">0076-DANO-023</a>)
1. Nodes that have been temporarily disconnected from the network should be able to load the missed history to get back up to the current network height (or most recently produced history) and then be able to start processing new blocks  (<a name="0076-DANO-024" href="#0076-DANO-024">0076-DANO-024</a>)
1. It must be possible to fetch history from the network whilst the node processes new blocks.  So for example, if setting up a new Archive node, the node can keep up to date with the network whilst retrieving history all the way back to the first block.  Once this is done the node should be able to reconcile the fetched history with that produced whilst the history was being retrieved such that the node will have a full history from the first block all the way to the networks current height.  (<a name="0076-DANO-025" href="#0076-DANO-025">0076-DANO-025</a>)
1. It must be possible to rollback the data-node to a previous block height and have it process events from this height onwards.  The state of the datanode at the rollback height must match exactly the state of the node as it was when it originally reached the given height. (<a name="0076-DANO-039" href="#0076-DANO-039">0076-DANO-039</a>)

### Data integrity

1. Data produced in the core snapshots aligns with the data-node data proving that what is returned by data-node matches core state at any given block height (<a name="0076-DANO-004" href="#0076-DANO-004">0076-DANO-004</a>)

### Data-node decentralised history

1. Historical data must be available to load into the datanode and must not be dependent on any centralised entity. (<a name="0076-DANO-005" href="#0076-DANO-005">0076-DANO-005</a>)
1. A datanode restored from decentralised history for a given block span must match exactly the state of a datanode that has the same block span of data created by consuming events. (<a name="0076-DANO-012" href="#0076-DANO-012">0076-DANO-012</a>)
1. As the network produces more blocks the data should be stored correctly in the data-node after a data-node is restored from decentralised history. For example: Start a data-node from a given history segment for a known block height, ensure the datanode continues to update from that block onwards. (<a name="0076-DANO-007" href="#0076-DANO-007">0076-DANO-007</a>).
1. It should not be necessary to restore the full history (i.e. from genesis block) to be able to process new blocks.  Restoring just the most recent history segment should be sufficient for the node to process new blocks. (<a name="0076-DANO-006" href="#0076-DANO-006">0076-DANO-006</a>)
1. No data is duplicated as the core emits events when catching up to the later block height. For example: Starting a core node at block height less than the data-node block height must result in no duplicated data (<a name="0076-DANO-008" href="#0076-DANO-008">0076-DANO-008</a>)
1. Starting a core node at block height greater than the data-nodes block height must result in an error and a refusal to start (<a name="0076-DANO-014" href="#0076-DANO-014">0076-DANO-014</a>)
1. If a data-node snapshot fails during the restore the process, it should error and the node(s) won't start (<a name="0076-DANO-009" href="#0076-DANO-009">0076-DANO-009</a>)
1. When queried via the APIs a node restored from decentralised history should return identical results to a node with the same block span which has been populated by event consumption.  [project front end dApps](https://github.com/vegaprotocol/frontend-monorepo/actions/workflows/generate-queries.yml). (<a name="0076-DANO-022" href="#0076-DANO-022">0076-DANO-022</a>)
1. All network history retained by a node for a given block span and type must be downloadable in CSV format. (<a name="0076-DANO-040" href="#0076-DANO-040">0076-DANO-040</a>)

### Data-node network determinism

1. For a given block span, a datanode history segment must be identical across all dat-nodes in the network that are using the recommended hardware and OS versions (<a name="0076-DANO-010" href="#0076-DANO-010">0076-DANO-010</a>)
1. History segments for the same block span must always match across the network, regardless of whether the producing node was itself restored from decentralised history or not. (<a name="0076-DANO-011" href="#0076-DANO-011">0076-DANO-011</a>)

### Schema compatibility

1. It is possible to identify if schema versions are NOT backwards compatible. Pull existing network snapshots start network, run a protocol upgrade to at later version and ensure both the core state and data-node data is correct (<a name="0076-DANO-041" href="#0076-DANO-041">0076-DANO-041</a>)
1. Restoring a node from decentralised history should work across schema upgrade boundaries and the state of the datanode should match that of a datanode populated purely by event consumption (<a name="0076-DANO-042" href="#0076-DANO-042">0076-DANO-042</a>)

### Data Retention

1. Lite nodes should have enough state to provide the current state of:  Assets, Parties, Accounts, Balances, Live Orders, Network Limits, Nodes, Delegations, Markets, Margin Levels, Network Parameters, Positions, Liquidity Provisions (<a name="0076-DANO-026" href="#0076-DANO-026">0076-DANO-026</a>)
2. Standard nodes should retain data in accordance with the configured data retention policy (<a name="0076-DANO-027" href="#0076-DANO-027">0076-DANO-027</a>)
3. Archival nodes should retain all data from the height at which they joined the network (<a name="0076-DANO-028" href="#0076-DANO-028">0076-DANO-028</a>)

### API Request Rate Limiting

1. Datanode should provide an optional mechanism for limiting the average number of requests per second over on its API
2. That rate should be specified in the datanode configuration file
3. A client may, over a short period of time, make requests at a greater frequency than the limit as long as the average rate over a longer period of time is not exceeded. (<a name="0076-DANO-029" href="#0076-DANO-029">0076-DANO-029</a>)
4. The extent to which clients may of 'burst' requests should also be capped and specified in the datanode configuration file (<a name="0076-DANO-030" href="#0076-DANO-030">0076-DANO-030</a>)
5. Limits should be enforced on a per-client basis. Source IP address is a sufficient discriminator (<a name="0076-DANO-031" href="#0076-DANO-031">0076-DANO-031</a>)
6. Headers or metadata should be included in each API response indicating to the client what the limits are, and how close they currently are to exceeding them (<a name="0076-DANO-032" href="#0076-DANO-032">0076-DANO-032</a>)
7. If limits are exceeded an API appropriate error response should be returned, containing similar headers or metadata (<a name="0076-DANO-033" href="#0076-DANO-033">0076-DANO-033</a>)
8. If the rate of denied (due to rate limiting) requests subsequently exceed the same maximum rate/burst parameters the client should be banned (<a name="0076-DANO-034" href="#0076-DANO-034">0076-DANO-034</a>)
9. The ban denies all access to the API for a configurable length of time (<a name="0076-DANO-035" href="#0076-DANO-035">0076-DANO-035</a>)
10. For that time, any requests will receive an API appropriate error response indicating that they are banned (<a name="0076-DANO-036" href="#0076-DANO-036">0076-DANO-036</a>)
11. The rate limit for the GraphQL API should be configurable separately from the gRPC API and it's REST wrapper since a single GraphQL request can trigger many internal gRPC requests (<a name="0076-DANO-037" href="#0076-DANO-037">0076-DANO-037</a>)
12. Where one API makes use of another (e.g. GraphQL making use of gRPC), rate limits should be enforced only once, on the side that faces the client (<a name="0076-DANO-038" href="#0076-DANO-038">0076-DANO-038</a>)

### General Acceptance

1. The DataNode must be able to handle brief network outages and disconnects from the vega node (<a name="0076-DANO-015" href="#0076-DANO-015">0076-DANO-015</a>)
1. The validator node will only accept requests for event bus subscriptions. All other API subscription requests will be invalid. (<a name="0076-DANO-016" href="#0076-DANO-016">0076-DANO-016</a>)
1. The event bus stream is available from validators, non validators and the DataNode (<a name="0076-DANO-017" href="#0076-DANO-017">0076-DANO-017</a>)
1. If a DataNode loses connection to a Vega node if will attempt to reconnect and if the cached data received from the Vega node is enough to continue working it can resume being a DataNode. (<a name="0076-DANO-019" href="#0076-DANO-019">0076-DANO-019</a>)
1. The DataNode must provide its current block height and vega time on responses to client requests so the client can determine whether or not the data is stale. (<a name="0076-DANO-021" href="#0076-DANO-021">0076-DANO-021</a>)


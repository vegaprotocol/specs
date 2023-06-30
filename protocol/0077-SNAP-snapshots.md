# Snapshots

This spec describes how Vega will produce the snapshots. Tendermint handles the process of triggering a snapshot's creation and broadcasting snapshots to new nodes. For more information see the [Tendermint state sync documentation](https://docs.tendermint.com/master/spec/abci/apps.html#state-sync)

A network parameter `snapshot.interval.length` sets how many blocks pass between snapshot creation. The value must be integer representing number of block strictly greater than `0`. Default can be `300`. For example with the default value of `300` all the nodes will create a snapshot at block height `300`, `600`, `900`, ... .

To allow a Vega node to be restarted without the need to replay the whole blockchain, a Vega node can load an existing snapshot created by a different node. This snapshot we enable the starting node to populate all the state inside the core as if the core had processed the historic blockchain. The node can then resume listening to blocks after the snapshot until it gets to the live block height where it will be classed as a normal contributing node.

Every node in a network is able to produce snapshots, the configuration values needed for each node include

1. Are snapshots enabled (true or false, default is true)
1. The number of blocks between snapshots (default 1000 blocks)
1. The number of snapshots to keep (default is 10 snapshots)
1. The storage config for the DB which will store the snapshot data (most likely GoLevelDB)

## Snapshot Generation

A snapshot is generated when the current block height MOD blocks_between_snapshots gives us zero. This makes sure that it does not matter when a node is started it will always generate snapshots at the same block heights. A snapshot can only be created once the block has been completed and the call to commit has finished. At which point we can generate a snapshot of the core state and persist it to file storage. If there is not enough space on the file system to store the snapshot we log an error and remove any partial write that has occurred. We could support removal of the oldest snapshots in an attempt to create free space but for this version we will leave all spring cleaning decisions to the app owner. Assuming no space issues the node will generate as many snapshots as the configured amount allows. Once we hit this limit we will remove the oldest snapshot before creating any further snapshots.

### The contents of a snapshot

A snapshot should contain the full state of the core (collateral, markets and their orderbooks, etc...), in such a way so a node can be loaded into the exact same state the node that created the snapshot was in. After loading a snapshot, any subsequent transactions that node processes _has_ to produce the exact same result as if that node had replayed the entire chain. Compared to checkpoints, for example, where collateral aggregates the balances per party, per asset, a snapshot ought to contain every account a party has, and what its balance is.

The snapshot type in tendermint itself does not contain any state data, but rather identifying information and metadata. The data is sent out in chunks. Our snapshot metadata should contain hashes for all the chunks, so that the node can verify each chunk as it receives it from another node. If a node provides a chunk with a different hash, either the snapshot data we are trying to load is corrupt (unlikely), or a malicious node is providing bad data, in which case we can, and should, reject the chunk (and fetch it again), and perhaps ban that node so as to not receive any more potentially corrupt data.

The snapshot chunks will reflect the core's internal structure quite a lot. Tendermint snapshot chunks are size restricted to 16MB, so we'll have to deal with chunks regardless. The entire app state will be stored in an AVL tree, so we can add each engine as a separate node (or set of nodes) to that tree, and update nodes as we go (this avoids us having to serialise the entire app state each time). This also facilitates the validation of each chunk we're trying to load. Roughly speaking, this is what a snapshot would look like:

```json
snapshot{
    Height: 123,
    Hash: "0xDEADBEEF", // hash of the entire snapshot
    Chunks: 14, // this checkpoint comes in 14 chunks
    Metadata: {
        Assets: {
            Chunk: 0, // which chunk is expected to contain this data
            Active: "0xabc123", // hash of active asset serialised data
            Pending: "0xdef456", // hash for assets awaiting validation
        },
        Collateral: {
            Chunk: 1,
            Accounts: "hash for account data",
            Assets: "enabled assets hash",
        },
    }
}
```

The chunks themselves are just of type `[]byte`. When receiving a chunk, we know its _"id"_ (the Nth chunk, its offset), so we can use the snapshot metadata to verify the data we received. Hashing the chunk should match the hashes contained within the metadata. Once the hashes match, we should be able to unmarshal the data, and restore the app state.

## Snapshot Consumption

When a node wants to start up via the snapshot system, we have to pass the required block height to the node during the start up process. The node will then send a tendermint request out asking for a snapshot matching that block using a predefined protocol type and version (we will only be using a single protocol type and version so these filters can be set to 0). Tendermint will then gather the available snapshots information from the network and then propose each one to the node for it to consider as a candidate to initialise from. Once the node is happy with the snapshot information it can accept the snapshot and tendermint to start to send the snapshot data in chunks to the node. The node should store these chunks of data locally until it has the full state saved. Depending on what data has already been received, the node can start loading its engines (e.g. After having received both Assets and Collateral, we should be able to restore the collateral and assets engines). Once all data has been received, the node can finalise loading the state, and run like any other node that just started by replaying the chain.

## Spam Protection

A bad node can swamp the network by requesting snapshots from other nodes which will force them to send large chunks of data around the network. This might have a negative effect on the Vega network as CPU and network resources will be consumed for no good reason. Further work needs to be done to reduce the possible impact of such an attack.

## Acceptance Criteria

- A node can be started up so that it generates snapshots at given block intervals (<a name="0077-SNAP-001" href="#0077-SNAP-001">0077-SNAP-001</a>)(<a name="0077-SP-SNAP-001" href="#0077-SP-SNAP-001">0077-SP-SNAP-001</a>)
- A node will generate snapshots files on the local filesystem (most likely using GOLevelDB) (<a name="0077-SNAP-002" href="#0077-SNAP-002">0077-SNAP-002</a>)(<a name="0077-SP-SNAP-002" href="#0077-SP-SNAP-002">0077-SSP-NAP-002</a>)
- A node will have a maximum amount of snapshots file on the filesystem. Older ones will be to be removed before a new one can be created. How many snapshots we keep may be something that can be configured. (<a name="0077-SNAP-003" href="#0077-SNAP-003">0077-SNAP-003</a>)(<a name="0077-SP-SNAP-003" href="#0077-SP-SNAP-003">0077-SP-SNAP-003</a>)
- The state of a node that is started from a snapshot should be identical to a node that had reached the same block height via replay. (<a name="0077-SNAP-004" href="#0077-SNAP-004">0077-SNAP-004</a>)(<a name="0077-SP-SNAP-004" href="#0077-SP-SNAP-004">0077-SP-SNAP-004</a>)
- Post a checkpoint restore we see snapshots continuing to be produced as before and can be used to add a node to the network (<a name="0077-SNAP-005" href="#0077-SNAP-005">0077-SNAP-005</a>)(<a name="0077-SP-SNAP-005" href="#0077-SP-SNAP-005">0077-SP-SNAP-005</a>)
- With  `snapshot.interval.length` set to `k` all the nodes in a network will create a snapshot at block height `k`, `2k`, `3k`, ... (<a name="0077-SNAP-006" href="#0077-SNAP-006">0077-SNAP-006</a>)(<a name="0077-SP-SNAP-006" href="#0077-SP-SNAP-006">0077-SP-SNAP-006</a>)

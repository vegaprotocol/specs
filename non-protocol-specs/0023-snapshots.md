# Snapshots

To allow a Vega node to be restarted without the need to replay the whole blockchain, a Vega node can load an existing snapshot created by a different node. This snapshot we enable the starting node to populate all the state inside the core as if the core had processed the historic blockchain. The node can then resume listening to blocks after the snapshot until it gets to the live block height where it will be classed as a normal contributing node.

Every node in a network is able to produce snapshots, the configuration values needed for each node include

1. Are snapshots enabled (true or false, default is true)
1. The number of blocks between snapshots (default 1000 blocks)
1. The number of snapshots to keep (default is 10 snapshots)
1. The file system directory where the snapshots should be saved (default to `/tmp/snapshots`)

## Snapshot Generation
A snapshot is generated when the current block height MOD blocks_between_snapshots gives us zero. This makes sure that it does not matter when a node is started it will always generate snapshots at the same block heights. A snapshot can only be created once the block has been completed and the call to commit has finished. At which point we can generate a snapshot of the core state and persist it to file storage. If there is not enough space on the file system to store the snapshot we log an error and remove any partial write that has occurred. We could support removal of the oldest snapshots in an attempt to create free space but for this version we will leave all spring cleaning decisions to the app owner. Assuming no space issues the node will generate as many snapshots as the configured amount allows. Once we hit this limit we will remove the oldest snapshot before creating any further snapshots.

### The contents of a snapshot
***Please fill in Elias***

## Snapshot Consumption
When a node wants to start up via the snapshot system, we have to pass the required block height to the node during the start up process. The node will then send a tendermint request out asking for a snapshot matching that block using a predefined protocol type and version (we will only be using a single protocol type and version so these filters can be set to 0). Tendermint will then gather the available snapshots information from the network and then propose each one to the node for it to consider as a candidate to initialise from. Once the node is happy with the snapshot information it can accept the snapshot and tendermint to start to send teh snapshot data in checks to the node. The node should store these blocks of data locally until it had the full file saved. Then it can use that file to start up and initialise it's internal structures.


## Spam Protection
A bad node can swamp the network by requesting snapshots from other nodes which will force them to send large chunks of data around the network. This might have a negative effect on the Vega network as CPU and network resources will be consumed for no good reason. Further work needs to be done to reduce the possible impact of such an attack.


## Acceptance Criteria
* A node can be started up so that it generates snapshots at given block intervals
* A node will generate snapshots files on the local filesystem
* A node will have a maximum amount of snapshots file on the filesystem. Older ones will be to be removed before a new one can be created.
* The state of a node that is started from a snapshot should be identical to a node that had reached the same block height via replay.

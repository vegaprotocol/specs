# Snapshot testing
The current state of the snapshot implementation is that a running node will generate a snapshot every block and store that information in a GoLevelDB file on the local filesystem. By default a node will always start up in normal mode in which it connects to tendermint and replays any historic blocks before catching up and running at the same pace as the existing nodes on the network. The snapshot system will keep by default 10 versions of the snapshots, when it has created 10 it will remove the oldest each time it creates a new snapshot. A new config section has been added to the vega config file so that we can change some of the default values and to allow a node to start up in a snapshot-reading mode in which it will attempt to load a snapshot from local storage and then join an existing network. The variables in the snapshot config section are:

``` code
type Config struct {
	Level       encoding.LogLevel  // Debug level
	Versions    int                // How many versions should we keep before deleting (10)
	RetryLimit  int                // How many times should we try to load a snapshot when we get block checksum errors
	Storage     string             // What type of storage are we using (GoLevelDB)
	DBPath      string             // Where do the database files live
  StartHeight int                // What block height do we want to load a snapshot for (0 by default, -1 means the latest)
}
```

If we want to start the node up in snapshot loading mode we have to set the StartHeight value to something other than 0. If we know the exact block height we can enter it here or we can use the value -1 to indicate we should load the latest available snapshot.

## Testing Process

We can divide the testing into two sections, one for creating snapshots and the other for loading snapshots

### Creating Snapshots
Dockerisedvega.sh can be used to start up a system to test the creation of snapshots.

`vegatools snapshotdb -d<snapshot folder>` will display all the currently held snapshots in the goleveldb database. This tool can be used to verify that new snapshots are being created and that old ones are being deleted to stay within the versions limit.

```
vegatools snapshotdb -d=<snapshot folder>
{ Snapshots: {
  { Version: 402, Height: 6, Size: 32 },
  { Version: 403, Height: 6, Size: 32 },
  { Version: 404, Height: 6, Size: 32 },
  { Version: 405, Height: 6, Size: 32 },
  { Version: 406, Height: 6, Size: 32 },
  { Version: 407, Height: 6, Size: 32 },
  { Version: 408, Height: 6, Size: 32 },
  { Version: 409, Height: 6, Size: 32 },
  { Version: 410, Height: 6, Size: 32 },
  { Version: 411, Height: 6, Size: 32 },
 }
}
```

Adding the command line option `-v` will cause the tool to only output the 

```
vegatools snapshotdb -d=<snapshot folder> -v
{ Versions: 10 }
```

We need to be able to stop and restart nodes as part of DV so we can test it.

Naughty-Node to send corrupt blocks for network testing.








# Data Node Spec

Vega core node (consensus and non-consensus) nodes run the core protocol and only keep information required to do so. 

Users of the protcol often need various data (price history / delegation history / transfers etc.). The core node doesn't store these but only *emits events* when things change.

The job of the data node is to collect and store the events and make those available. Since storing "everything forever" will take up too much data it must be possible to configure (and change at runtime) what the data node stores and for how long (retention policy). 


## Working with events
Each chunk of data should contain the eventID that created it and the block from which the event was created.

Event is emitted on each occasion the blockchain time updates. For each chunk of data stored, label it with this time stamp. When a new timestamp event comes, start using that one. 

*Never* use the wall time for anything.

## Retention policies

It should be possible to configure to store only "current state" and no history of anything (in particular the order book). 

It should be possible to configure the data node so that all data older than any time period (e.g. `1m`, `1h`, `1h:22m:32s`, `1 months`) is deleted. 

It should be possible to configure the data node so that all data of certain type is deleted upon an event (and configurably with a delay) e.g. event: MarketID `xyz` settled + `1 week`. 

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
- as [specified in](0021-market-data-spec.md). This is emitted once per block. This is kept for backward compatibility. Note that below we may duplicate some of this. 

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
- Equity like share changes
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

It must be possible to augment APIs so data returned is in a shape and size that is approapriate for clients. The exact changes to APIs to be worked out as part of an on going process, and it wont be specified here.

### APIs for server side calculations

It must be possible to add to the data node APIs that return the result of calculations on the data node (in addition ot historical data). These calculations may use historical or real time core data but are not avalilble in the core API as they would hinder performance. e.g. Estimates / Margin / risk caclulations

# Acceptance criteria

## Data syncronisation

1. To ensure no loss of historical data access; data nodes must be able to have access to and syncronise all historical data after a restart (<a name="0011-NP-DANO-001" href="#0011-NP-DANO-001">0011-NP-DANO-001</a>)
1. To ensure no loss of historical data access; data nodes must be able to have access to and syncronise all historical data after a software upgrade  (<a name="0011-NP-DANO-002" href="#0011-NP-DANO-002">0011-NP-DANO-002</a>)
1. To ensure that new nodes joining the network have access to all historical data; nodes must be able to have access to and syncronise all historical data across the network  (<a name="0011-NP-COSMICELEVATOR-003" href="#0011-NP-COSMICELEVATOR-003">0011-NP-COSMICELEVATOR-003</a>)
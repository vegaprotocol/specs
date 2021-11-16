# Vega with null blockchain

This allows user to run a single Vega node with the consensus layer (Tendermint currently) replaced by something, which we call "null blockchain" that reduces overhead. 
This is effectively first step towards a "minimal" scenario runner but it may also be useful for QA to allow them to run tests faster (no need to wait for time to pass).

It must have the following features:

## Time forwarding commands / transactions

The blockchain can be started with time set (different from wall time) so e.g. `1st January 2010 00:00:00`. 
User can submit a transaction saying: move time forward by `1h:10m` or move time to `1st January 2010 01:10:00`. 
The user can submit a command to start a new block and end a current block.
Alternatively the user can set the block time length and move forward by a fixed number of blocks. 
Upon receiving this transaction Vega must carry out all the protocol actions that happen with passage of time (e.g. ending auctions, closing / enacting governance proposals, updating price monitoring bounds changing due to passage of time, etc.). 

## Parties and balances

User can create parties and add / remove balances, mocking withdrawals without having to connect to any Ethereum chain. User can register "associated" staking / governance tokens for purposes of staking and delegation and voting on governance without having to connect any Ethereum chain. 

## Submitting transactions

Transactions are submitted in the same way as for a normal live system, i.e. messages must be signed as usual.
(This is required to prevent too many changes being made to the current system to avoid the signing and validation process)

## Data node and events

It must be possible to launch a data node alongside this and record everything that data node is normally able to record. 
It must be possible to record event bus events.


## API Support

Null blockchain Vega must support all the APIs that Vega core supports with all the standard language bindings plus the additional ones outlined above. 
An extra API is added to allow the user to control the time and block start/end times without changing the standard API endpoints.

## Acceptance criteria

- It is possible to take a functioning sample API script, change the config so it points at a null blockchain vega node, add some time passage commands and run it.

- There is golang example which creates three parties, gives them assets, one party proposes a market and acts as LP, the remaining two parties trade, placing one trade per day for "365 days".  The LP party submits a trading terminated transaction after "365 days" and a subsequent settlement price transaction and the market settles. All of this executes within 0.1 second on a Raspberry PI.

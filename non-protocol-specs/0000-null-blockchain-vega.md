# Vega with null blockchain

This allows user to run a single Vega node with the consensus layer (Tendermint currently) replaced by something, which we call "null blockchain" that reduces overhead. 
This is effectively first step towards a "minimal" scenario runner but it may also be useful for QA to allow them to run tests faster (no need to wait for time to pass).

It must have the following features:

## Time forwarding commands / transactions

The blockchain can be started with time set (different from wall time) so e.g. `1st January 2010 00:00:00`. 
User can submit a transaction saying: move time forward by `1h:10m` or move time to `1st January 2010 01:10:00`. 
Alternatively the user can set the blocktime length and move forward by a fixed number of blocks. 
Upon receiving this transaction Vega must carry out all the protocol actions that happen with passage of time (e.g. ending auctions, closing / enacting governance proposals, updating price monitoring bounds changing due to passage of time, etc.). 

## Parties and balances

User can create parties and add / remove balances, mocking withdrawals without having to connect to any Ethereum chain. User can register "associated" staking / governance tokens for purposes of staking and delegation and voting on governance without having to connect any Ethereum chain. 

## Submitting transactions

User can submit transactions without signing or alternatively padding with possibly invalid signature and Vega will assume the transaction signature is valid. 
Basically, we don't want core to waste CPU cycles on signature verification in case the user wants to run many scenarios fast.

## Data node and events

It must be possible to launch a data node alongside this and record everything that data node is normally able to record. 
It must be possible to record event bus events.

## CLI support

There is a command line tool to launch vega with null blockchain, data node and any other processes needed for this functioning. 
It will should have the following command line options:

- genesis config file
- current time (optional, if wanted to be different from wall time)
- event bus output file

## API Support

Null blockchain Vega must support all the APIs that Vega core supports with all the standard language bindings plus the additional ones outlined above. 

## Acceptance criteria

- It is possible to take a functioning sample API script, change the config so it points at a null blockchain vega node, add some time passege commands and run it.

- There is golang example which creates three parties, gives them assets, one party proposes a market and acts as LP, the remaining two parties trade, placing one trade per day for "365 days".  The LP party submits a trading terminated transaction after "365 days" and a subseqeunt settlement price transaction and the market settles. All of this executes within 0.1 second on a Raspberry PI.

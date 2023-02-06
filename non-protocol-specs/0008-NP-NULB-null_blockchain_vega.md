# Vega with null blockchain

This allows user to run a single Vega node with the consensus layer (Tendermint currently) replaced by something, which we call "null blockchain" that reduces overhead.
This is effectively first step towards a "minimal" scenario runner but it may also be useful for QA to allow them to run tests faster (no need to wait for time to pass).

It must have the following features:

## Time forwarding commands / transactions

The blockchain can be started with time set (different from wall time) so e.g. `1st January 2010 00:00:00`.
The length in time of each block is defined at startup (default is 1 second).
The maximum number of transactions in a block is defined at startup (default 10). The null blockchain system will automatically end a block and create a new one if the transaction count is met/exceeded.
User can submit a transaction saying: move time forward by at least `1h:10m` or move time beyond `1st January 2010 01:10:00`. Moving time will automatically end the current block if it contains transactions and will create all the required empty blocks needed to get us to the new time.
User can move time forward by a fixed number of blocks.
Upon receiving this transaction Vega must carry out all the protocol actions that happen with passage of time (e.g. ending auctions, closing / enacting governance proposals, updating price monitoring bounds changing due to passage of time, etc.).

## Parties and balances

User can create parties and add / remove balances, mocking withdrawals without having to connect to any Ethereum chain. User can register "associated" staking / governance tokens for purposes of staking and delegation and voting on governance without having to connect any Ethereum chain.

## Submitting transactions

Transactions are submitted in the same way as for a normal live system, i.e. messages must be signed as usual.
(This is required to prevent too many changes being made to the current system to avoid the signing and validation process)

## Data node and events

It must be possible to launch a data node alongside this and record everything that data node is normally able to record.
Event bus data can be recorded either in the test app via a subscription to the event stream or using externals tools such as `vegatools stream`

## API Support

Null blockchain Vega must support all the APIs that Vega core supports with all the standard language bindings plus the additional ones outlined above.
An extra API is added to allow the user to control the time and block start/end times without changing the standard API endpoints.

## Acceptance criteria

- Time can only move forward
  - I submit `{ forward: "-10s" }` to the time fast forward endpoint. Time does not move and I receive an error. (<a name="0008-NP-NULB-001" href="#0008-NP-NULB-001">0008-NP-NULB-001</a>)
  - I submit `{ forward: "<a date in the past>" }` to the time fast forward endpoint. Time does not move and I receive an error. (<a name="0008-NP-NULB-002" href="#0008-NP-NULB-002">0008-NP-NULB-002</a>)
- The null blockchain block time does not control the automatic creation of blocks
  - With the block time set to `1 second`, if at block height 1 I perform no actions for 5 seconds, the block height will still be 1 (<a name="0008-NP-NULB-003" href="#0008-NP-NULB-003">0008-NP-NULB-003</a>)
  - With the transactions-per-block configuration set to `2`
    - If at block height 1 I submit 3 transactions, the block height will have increased to 2 (<a name="0008-NP-NULB-004" href="#0008-NP-NULB-004">0008-NP-NULB-004</a>)
    - If at block height 1 I submit 1 transaction, the block height will still be 1 (<a name="0008-NP-NULB-005" href="#0008-NP-NULB-005">0008-NP-NULB-005</a>)
  - If at block height 1 I move time forward by 1s, the block height will have increased to 2 (<a name="0008-NP-NULB-006" href="#0008-NP-NULB-006">0008-NP-NULB-006</a>)
- There is golang example which creates three parties, gives them assets, one party proposes a market and acts as LP, the remaining two parties trade, placing one trade per day for "365 days".  The LP party submits a trading terminated transaction after "365 days" and a subsequent settlement price transaction and the market settles. (<a name="0008-NP-NULB-007" href="#0008-NP-NULB-007">0008-NP-NULB-007</a>)

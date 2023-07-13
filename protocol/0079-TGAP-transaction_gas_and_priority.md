# Vega transaction gas costs and priorities

Vega doesn't charge users gas costs per transaction.
However, the system processing capacity is still limited and in order to ensure liveness each transaction will have associated gas cost.
Each block will contain only transactions up to a certain block gas limit.
Transactions with higher priorities will get scheduled first.

## Network parameters

- `network.transactions.maxgasperblock` is a network parameter with type unsigned integer with a minimum value of `100`, maximum value `10 000 000` and a recommended default of `10 000`. If the parameter is changed through governance then the next block after enactment will respect the new `maxgasperblock`.
- `network.transaction.defaultgas` is a network parameter with type unsigned integer with a minimum value of `1` and maximum value of `99` and default value of `1`. If the parameter is changed through governance then the next block after enactment will respect the new `defaultgas`.
- `network.transactions.minBlockCapacity` is a network parameter with type unsigned integer with a minimum value of `1`, maximum `10000` and default `32` setting the minimum number of transactions that will fit into a block due to their gas costs.

We must have `network.transactions.maxgasperblock >= 2 x network.transactions.minBlockCapacity`.

## Including transactions

Each transaction will have a gas cost assigned to it. Any transaction not specifically named below has gas cost of `network.transaction.defaultgas`.
The consensus layer (Tendermint) will choose transactions from the proposer's mempool to include into a block with a maximum total cost of `network.transactions.maxgasperblock`.
It must *not* try to include the transactions with the highest gas; in fact it should include transactions in the sequence it's seen them until the block gas limit is reached.

## Default transactions cost

Every transaction not listed below will have gas cost `network.transaction.defaultgas`.

## Dynamic transactions costs

Cost of transaction depends mainly on the state of underlying market and below we set out costs of transactions based on market state.
Vega will capture the needed statistical variables (see below) on a per-market basis (or per-whatever if other dynamically costed transactions are added, for now per-market is sufficient) from the previous block so that they don't need to be looked up dynamically during block creation.

Variables needed:

- `network.transactions.maxgasperblock` - `maxGas`
- number of price levels on the order book taken, this can count just static volume or static plus dynamic(*) - `levels`
- number of pegged orders - `pegs`
- number of stop orders on the market - `stops`
- number of positions on the market - `positions`

(*) update after implementation

Constants needed:

- `peg cost factor = 50` non-negative decimal
- `stop cost factor = 0.2` non-negative decimal
- `position factor = 1` non-negative decimal
- `level factor = 0.1` non-negative decimal
- `batchFactor = 0.5` decimal between `0.1 and 0.9`.

### Any type of limit or market order, or liquidity provision transaction

```go
gasOrder = network.transaction.defaultgas + peg cost factor x pegs
                                        + stop cost factor x stops
                                        + position factor x positions
                                        + level factor x levels
gas = min((maxGas/minBlockCapacity)-1,gasOrder)
```

### Cancellation of any single order or liquidity provision transaction

```go
gasCancel = network.transaction.defaultgas + peg cost factor x pegs
                                        + stop cost factor x stops
                                        + level factor x levels
gas = min((maxGas/minBlockCapacity)-1,gasCancel)
```

### Batch orders

Define `batchFactor` (a hard coded parameter) set to something between `0.0 and 1.0`.
Say `batchFactor = 0.5` for now.

Here `gasBatch` is

1. the full cost of the first cancellation (i.e. `gasCancel`)
1. plus `batchFactor` times sum of all subsequent cancellations added together (each costing `gasOrder`)
1. plus the full cost of the first amendment at `gasOrder`
1. plus `batchFactor` sum of all subsequent amendments added together (each costing `gasOrder`)
1. plus the full cost of the first limit order at `gasOrder`
1. plus `batchFactor` sum of all subsequent submissions added together (each costing `gasOrder`)

```go
gas = min((maxGas/minBlockCapacity)-1,batchGas)
```

## Transaction priorities

Transactions with higher priorities that are present in the mempool will get placed into a block before transactions with lower priority are considered.
Transactions with the same priority are placed into a block in the default sequencing order (up to maximum gas cost above).

There are three priority categories:

1. "high" which constitutes all "protocol transactions" i.e. state variable updates [(floating point consensus)](./0065-FTCO-floating_point_consensus.md), [ethereum events](./0036-BRIE-event_queue.md) , withdrawals, heartbeats (for candidate and ersatz validator performance measurement), see [validators](./0069-VCBS-validators_chosen_by_stake.md) and transactions the protocol uses internally to run.
1. "medium" which includes all [governance](./0028-GOVE-governance.md) transactions (market proposals, parameter change proposals, votes).
1. "low" which includes all other transactions.

## Acceptance criteria

### Basic happy path test (<a name="0079-TGAP-001" href="#0079-TGAP-001">0079-TGAP-001</a>)

1. Set `network.transactions.maxgasperblock = 100` and `network.transaction.defaultgas = 20`.
1. Send `100` transactions with default gas cost to a node (e.g. votes on a proposal) and observe that most block have 5 of these transactions each.


### Test max with a market (<a name="0079-TGAP-004" href="#0079-TGAP-004">0079-TGAP-004</a>)

for product spot: (<a name="0079-TGAP-006" href="#0079-TGAP-006">0079-TGAP-006</a>)

1. Set `network.transactions.maxgasperblock = 100` and `network.transaction.defaultgas = 1`.
1. Create a market with 1 LP
1. Place 2 matching orders, 1 buy order below the matching price and 1 sell order above the matching price. Uncross the opening auction.
1. Place 3 pegged orders with different non-zero offsets.
1. Another party submits a transaction to place a limit order. A block will be created containing the transaction (even though the gas cost of a limit order is `1 + 50 x 3 + 2 x 1 + 0.1 x 5` which is well over `100`.)


### Test we don't overfill a block with a market (<a name="0079-TGAP-005" href="#0079-TGAP-005">0079-TGAP-005</a>)

for product spot: (<a name="0079-TGAP-007" href="#0079-TGAP-007">0079-TGAP-007</a>)

1. Set `network.transactions.maxgasperblock = 500` and `network.transaction.defaultgas = 1`.
1. Place 2 matching orders, 1 buy order below the matching price and 1 sell order above the matching price. Uncross the opening auction.
1. Place 3 pegged orders with different non-zero offsets.
1. Another party submits 10 transaction to place 10 limit order. A separate party submits `100` transactions with default gas cost. Blocks will be created but each only containing one limit order placement transaction and including some number of vote transactions.

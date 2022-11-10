# Vega transaction gas costs 

Vega doesn't charge users gas costs per transaction. 
However, the system processing capacity is still limited and in order to ensure liveness each transaction will have associated gas cost.
Each block will contain only transactions up to a certain block gas limit. 

## Network parameters

- `network.transactions.maxgasperblock` is a network parameter with type unsigned integer with a minimum value of `100`, maximum value `10 000 000` and a recommended default of `10 000`. If the parameter is changed through governance then the next block after enactment will respect the new `maxgasperblock`. 
- `network.transaction.defaultgas` is a network parameter with type unsigned integer with a minimum value of `1` and maximum value of `99` and default value of `1`. If the parameter is changed through governance then the next block after enactment will respect the new `defaultgas`. 

Note that the min / max values set above are deliberate: as we'll see below we can fit at least one transaction with default gas into a block. 

## Including transactions 

Each transaction will have a gas cost assigned to it. Any transaction not specifically named below has gas cost of `network.transaction.defaultgas`. 
The consensus layer (Tendermint) will choose transactions from the proposer's mempool to include into a block with a maximum total cost of `network.transactions.maxgasperblock`. 
It must *not* try to include the transactions with the highest gas; in fact it should include transactions in the sequence it's seen them until the block gas limit is reached. 

## Default transactions cost

Every transaction not listed below will have gas cost `network.transaction.defaultgas`. 


## Dynamic transactions costs

Cost of transaction depends mainly on the state of underlying market and below we set out costs of transactions based on market state. 

Variables needed:
- `network.transactions.maxgasperblock` - `maxGas`
- number of price levels on the order book taken, this can count just static volume or static plus dynamic(*) - `levels`
- number of pegged orders - `pegs`
- number of LP shape levels on the market - `shapes` 
- number of positions on the market - `positions`

(*) update after implementation

### Any type of limit or market order

```
gasOrder = network.transaction.defaultgas + 100 x pegs + 100 x shapes + 1 x positions + 0.1 x levels
gasOrder = min(maxGas-1,gasOrder)
```

### Cancellation of an order

```
gasCancel = network.transaction.defaultgas + 100 x pegs + 100 x shapes + 0.1 x levels
gasCancel = min(maxGas-1,gasCancel)
```

### Batch orders 

Define `batchFactor` (a hard coded parameter) set to something between `0.1 and 0.9`.
Say `batchFactor = 0.5` for now.

Here `gasBatch` is
1. the full cost of the first cancellation (i.e. `gasCancel`) 
1. plus `batchFactor` times sum of all subsequent cancellations added together (each costing `gasOrder`)
1. plus the full cost of the first amendment at `gasOrder`
1. plus `batchFactor` sum of all subsequent amendments added together (each costing `gasOrder`)
1. plus the full cost of the first limit order at `gasOrder` 
1. plus `batchFactor` sum of all subsequent limit orders added together (each costing `gasOrder`)

```
gas = min(maxGas-1,batchFactor)
```


### LP provision, new or amendment

```
gasOliq = network.transaction.defaultgas + 100 x pegs + 100 x shapes + 1 x positions + 0.1 x levels
gas = min(maxGas-1,gasOliq)
```



## Acceptance criteria

### Basic happy path test (<a name="0079-TGAS-001" href="#0079-TGAS-001">0079-TGAS-001</a>) 

1. Set `network.transactions.maxgasperblock = 100` and `network.transaction.defaultgas = 20`.
1. Send `100` transactions with default gas cost to a node (e.g. votes on a proposal) and observe that most block have 5 of these transactions each. 

### Test max with a market (<a name="0079-TGAS-001" href="#0079-TGAS-001">0079-TGAS-001</a>) 

1. Set `network.transactions.maxgasperblock = 100` and `network.transaction.defaultgas = 1`.
1. Create a market with 1 LP using 2 shape offsets on each side, just best static bid / ask on the book and 2 parties with a position. 
1. Another party submits a transaction to place a limit order. A block will be created containing the transaction (even though the gas cost of a limit order is `1 + 100 x 4 + 2 + 0.1 x 6` which is well over `100`.)

### Test we don't overfill a block with a market (<a name="0079-TGAS-001" href="#0079-TGAS-001">0079-TGAS-001</a>) 

1. Set `network.transactions.maxgasperblock = 500` and `network.transaction.defaultgas = 1`.
1. Create a market with 1 LP using 2 shape offsets on each side, just best static bid / ask on the book and 2 parties with a position. 
1. Another party submits 10 transaction to place 10 limit order. A separate party submits `100` transactions with default gas cost. Block will be created but each only containing one limit order placement transaction and including some number of vote transactions. 
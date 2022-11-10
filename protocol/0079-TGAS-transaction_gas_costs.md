# Vega transaction gas costs 

Vega doesn't charge users gas costs per transaction. 
However, the system processing capacity is still limited and in order to ensure liveness each transaction will have associated gas cost.
Each block will contain only transactions up to a certain block gas limit. 

## Network parameters

- `network.transactions.maxgasperblock` is a network parameter with type unsigned integer with a minimum value of `100`, maximum value `10 000 000` and a recommended default of `10 000`. If the parameter is changed through governance then the next block after enactment will respect the new `maxgasperblock`. 
- `network.transaction.defaultgas` is a network parameter with type unsigned integer with a minimum value of `1` and maximum value of `99` and default value of `1`.

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
- number of price levels on the order book taken - `levels`
- number of pegged orders - `pegs`
- number of LP shape levels on the market - `shapes` 
- number of positions on the market - `positions`


### Any type of limit or market order

```
gas = network.transaction.defaultgas + 100 x pegs 100 x shapes + 1 x positions + 0.1 x levels
gas = min(maxGas-1,gas)
```

### LP provision, new or amendment

```
gas = network.transaction.defaultgas + 100 x pegs 100 x shapes + 1 x positions + 0.1 x levels
gas = min(maxGas-1,gas)
```




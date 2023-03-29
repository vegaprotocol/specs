# Time based pruning of the mempool

Transactions currently can stay in the mempool indefinitely. For non-validator commands, we want to be able to limit the time they are considered valid, once a certain amount of time has passed, the transaction should be rejected and removed from the mempool.

## Network parameters

- `network.transactions.maxttl` is a network parameter with type unsigned integer with the minimum value of `10` and a maximum value of `50`. This value determines the max number of blocks a given transaction is valid for. A transaction that specifies the `TTL`, this value *must* be less than, or equal to this parameter. If no `TTL` is specified, the transaction `TTL` will be set to this value.

Part of the transaction data is the block height at which the transaction was created. Transactions will remain current until this block height + the `TTL`.

## Including transactions

This `TTL` is applied to all transactions, except for validator commands. Users have the ability to set the `TTL` manually, using transaction version 4, previous versions use the network parameter mentioned above as the `TTL`.

## Validation

For commands using the V4 transaction, the wallet will ensure the `TTL` does not exceed the maximum as specified by the network parameter. Vega/core will additionally validate the `TTL` on `CheckTx`. Should the `TTL` be greater than the network parameter, the network parameter will override the `TTL` specified in the transaction, both in the wallet and the core.

## Acceptance criteria

### Basic network parameter test (<a name="0080-TBPM-001" href="#0080-TBPM-001">0080-TBPM-001</a>)

1. Set `network.transactions.maxttl = 1`
2. Create a non-validator transaction V4 setting the `TTL` to a value > 1.
3. The transaction should have a max `TTL` of 1 (network parameter overrides a user-specified value > network parameter)

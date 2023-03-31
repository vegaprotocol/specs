# Time based pruning of the mempool

Transactions currently can stay in the mempool indefinitely. For non-validator commands, we want to be able to limit the time they are considered valid, once a certain amount of time has passed, the transaction should be rejected and removed from the mempool.

## Network parameters

- `network.transactions.maxttl` is a network parameter with type unsigned integer with the minimum value of `10` and a maximum value of `50`. This value determines the max number of blocks a given transaction is valid for. A transaction that specifies the `TTL`, this value *must* be less than, or equal to this parameter. If no `TTL` is specified, the transaction `TTL` will be set to this value.

Part of the transaction data is the block height and block hash at which the transaction was created. Transactions will remain current until this block height + the `TTL`.

## Including transactions

This `TTL` is applied to all transactions, except for validator commands. Users have the ability to set the `TTL` manually, by specifying a `transaction-ttl` flag with vegawallet. This value cannot be greater than the `netork.transactions.maxttl`, if it is, or no `TTL` is specified, the transaction will be considered current for the number of blocks specified by `network.transactions.maxttl`.

## Validation

For commands using the V4 transaction, the wallet will ensure the `TTL` does not exceed the maximum as specified by the network parameter. Vega/core will additionally validate the `TTL` on `CheckTx`. Should the `TTL` be greater than the network parameter, the network parameter will override the `TTL` specified in the transaction, both in the wallet and the core.

## Acceptance criteria

### Basic network parameter test (<a name="0080-TBPM-001" href="#0080-TBPM-001">0080-TBPM-001</a>)

1. Set `network.transactions.maxttl = 10`
2. Create a non-validator transaction V4 setting the `TTL` to a value > 10.
3. The transaction should have a max `TTL` of 10 (network parameter overrides a user-specified value > network parameter)

### Default network parameter test (<a name="0080-TBPM-002" href="#0080-TBPM-002">0080-TBPM-002</a>)

1. Create a transaction with vegawallet without specifying a `TTL`.
2. The output should be a transaction that has a `TTL` that equals the `network.transactions.maxttl`.

### Validator commands (<a name="0080-TBPM-003" href="#0080-TBPM-003">0080-TBPM-003</a>)

1. As stated above, validator commands do not expire. The transaction can have a `TTL` value set, it is ignored.

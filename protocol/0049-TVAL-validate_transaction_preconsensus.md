# `0049` Validate transaction pre-consensus

There are a number of validations that can be performed on every transaction to determine whether it can be included in a valid block. Doing validation at this stage is advantageous because the validation can done synchronously on receipt of the transaction and occurs before the transaction is included in a block. This:

* Reduces the size the block and the overall chain
* Can therefore be used to mitigate certain types of spam, liveness and other attacks
* Provides immediate feedback on errors to users

## `1` Validations

### `1.1` Valid signing key

#### `1.1.1` Description

All valid transactions in the Vega protocol meet at least one of the following conditions:

* Signed with a key with as positive balance of some asset
* Signed with a key with >0 voting eight in the governance protocol. Currently this always also means a positive balance of some asset, namely the governance asset, but this is not guaranteed to be true forever, though this condition should remain easy to verify.
* Signed with a validator's key

Therefore a node should not accept or include a transaction in a block that's signed with a key that is not known to meet one or more of these conditions.

Note that this means that a transaction cannot share a block with the transaction that would add its signer to the valid keys list, but due to short block times and the rarity of these events, this is acceptable.

Future enhancements: for each root transaction message type (e.g. `SubmitOrder`, `AmendOrder`, `ProposeMarket`, ...) it is possible to define which of these conditions is required. For instance, all trading transactions require a non-zero balance. Initially we can apply the union of the key sets meeting each of the conditions to all transactions.

#### `1.1.2` Acceptance criteria

Note that separate pre-consensus validation is carried out as part of PoW anti-spam checks, see the acceptance criteria in [PoW spec](./0072-SPPW-spam-protection-PoW.md).

1. Transaction is included in the block if signed with a non-validator's key, includes [correct PoW data](./0072-SPPW-spam-protection-PoW.md) and is not a governance transaction. (<a name="0049-TVAL-001" href="#0049-TVAL-001">0049-TVAL-001</a>) for product spot: (<a name="0049-TVAL-007" href="#0049-TVAL-007">0049-TVAL-007</a>)
1. Transaction is with wrong / missing key is rejected. (<a name="0049-TVAL-002" href="#0049-TVAL-002">0049-TVAL-002</a>) for product spot: (<a name="0049-TVAL-008" href="#0049-TVAL-008">0049-TVAL-008</a>)
1. Transaction is rejected (never included in a block) if it is a transfer and is from a party with less than the [quantum](./0041-TSTK-target_stake.md)  balance of the source asset (<a name="0049-TVAL-003" href="#0049-TVAL-003">0049-TVAL-003</a>) for product spot: (<a name="0049-TVAL-009" href="#0049-TVAL-003">0049TVAL-009</a>)
1. Transaction is rejected (never included in a block) if a party has strictly less than the [quantum](./0041-TSTK-target_stake.md)  balance in the settlement asset of the market and it is submitting any kind of orders (limit, market, LP provision)  (<a name="0049-TVAL-004" href="#0049-TVAL-004">0049-TVAL-004</a>) for product spot: (<a name="0049-TVAL-010" href="#0049-TVAL-010">0049-TVAL-010</a>)
1. Transaction interacting in a market is included in a block if signed with a key from a non-validator party with a balance >= [quantum](./0041-TSTK-target_stake.md) of the settlement asset for the market, where an identical (apart from PoW proof and block data details) transaction was rejected from a previous block when the party had relevant balance < less than relevant [quantum](./0041-TSTK-target_stake.md) (<a name="0049-TVAL-005" href="#0049-TVAL-005">0049-TVAL-005</a>) for product spot: (<a name="0049-TVAL-011" href="#0049-TVAL-011">0049-TVAL-011</a>)
1. Transaction sent to a non-validator node is propagated to validator and included in a block. (<a name="0049-TVAL-006" href="#0049-TVAL-006">0049-TVAL-006</a>) for product spot: (<a name="0049-TVAL-012" href="#0049-TVAL-012">0049-TVAL-012</a>)

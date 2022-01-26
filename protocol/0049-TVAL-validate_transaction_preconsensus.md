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

Future enhancemments: for each root transaction message type (e.g. SubmitOrder, AmendOrder, ProposeMarket, ...) it is possible to define which of these conditions is required. For instance, all trading transactions require a non-zero balance. Initially we can apply the union of the key sets meeting each of the conditions to all transactions.

#### `1.1.2` Acceptance criteria 

1. [ ] Transaction is included in the block if signed with a validator's key (<a name="0049-TVAL-001" href="#0049-TVAL-001">0049-TVAL-001</a>)
1. [ ] Transaction is included in the block if signed with a key from a non-validator party with a balance > 0 of some asset (<a name="0049-TVAL-002" href="#0049-TVAL-002">0049-TVAL-002</a>)
1. [ ] Transaction is not included in the block if signed with a key from a non-validator party with no balance of any asset, that has never had a balance (<a name="0049-TVAL-003" href="#0049-TVAL-003">0049-TVAL-003</a>)
1. [ ] Transaction is not included in the block if signed with a key from a non-validator party with no balance of any asset, that previously had a balance `> 0` (<a name="0049-TVAL-004" href="#0049-TVAL-004">0049-TVAL-004</a>)
1. [ ] Transaction is included in the block if signed with a key from a non-validator party with a balance > 0 of some asset, where the transaction was rejected from a previous block where the party had no balance (<a name="0049-TVAL-005" href="#0049-TVAL-005">0049-TVAL-005</a>)
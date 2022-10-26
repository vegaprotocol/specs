# Master Keys for Validators

This is a safety related feature specifically for validators. To run the Vega network validators need three keys: Ethereum, Tendermint and Vega. This spec is about the Vega key. 

The vega wallet is derived from a master key (bip39 and slip-10 are used), from this master key, new keys are derived deterministicaly. As of now the master key is used only for deriving new keys, and is never used to prove identity or signing anything except the new hot keys.
For the validator we set their identity, for the purposes of staking and delegation, to their public master key. The hot key controls the general account balances and is used to emit transactions to the network.

To this end, other validators need access to the public part of the master key for all other validators.

## Transaction to change the key
When a validator wishes to change the private key used to sign vega transaction emitted by the node (the hot key), they then generate a new hot key pair from the master key and send a transaction to notify the network of the change of public hot key. This transaction includes the hash of the new public key, signed by the master key:
```    
    hash(HOT_PK),sign_MK('vega_val_key_rotate', key_number, target_block, hash(HOT_PK)),
```
where `key_number` is the sequence number of the derived key to prevent replay attacks, and `target_block` is the block number from which on the chage should be valid.

## When does this change take effect
1. The node operator sends a transaction to the network saying they’re changing their hot key.
1. From `target_block` onwards the other validators no longer recognise the *old* hot key as valid.
1. The node operator restarts the node and catches up by replaying the chain or using a full checkpoint (when checkpoints become available). Or the whole network is restarted but due to the transaction other validators have the new hot key. 
1. The hot key switch is complete. 

## Ethereum side for staking bridge purposes
Validators to use their public master key as the "destination" when they associate ERC20 Vega token the their Vega identity.   

## Genesis
The public master key has to be added to validators' identities in the genesis configuration.



## Acceptance Criteria:

- There is a function (not necessarily inside core) that takes the master key and an index and computes the corresponding hot key  (<a name="0063-VALK-001" href="#0063-VALK-001">0063-VALK-001</a>)
- A transaction can be submitted to the network to initiate a Vega key rotation (<a name="0063-VALK-002" href="#0063-VALK-002">0063-VALK-002</a>)
- A transaction submitted by an old hot-key after `target_block` is not associated by the network as being from a Validator (<a name="0063-VALK-003" href="#0063-VALK-003">0063-VALK-003</a>) 
- Once `target_block` has been reached the network reports the new key as the validators hot-key (<a name="0063-VALK-004" href="#0063-VALK-004">0063-VALK-004</a>)
- A key rotation submission which is not signed by the master key is rejected causing a transaction-error event that is visible by the whole network.  (<a name="0063-VALK-005" href="#0063-VALK-005">0063-VALK-005</a>)
- It is possible to perform parallel key rotations rotations succesfully in the same block. (<a name="0063-VALK-006" href="#0063-VALK-006">0063-VALK-006</a>)
- Once a validator hot key has been rotated all applicable rewards are correctly received. (<a name="0063-VALK-007" href="#0063-VALK-007">0063-VALK-007</a>)
- Once a validator master key has been rotated staking and delegation to the validator works as before. (<a name="0063-VALK-008" href="#0063-VALK-008">0063-VALK-008</a>)
- - Once a validator master key has been rotated self-staking and self-delegation for the validator works as before. (<a name="0063-VALK-009" href="#0063-VALK-009">0063-VALK-009</a>)











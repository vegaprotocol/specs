# Master Keys for Validators

This is a safety related feature specifically for validators. To run the Vega network validators need three keys: Ethereum, Tendermint and Vega. This spec is about the Vega key. 

The vega wallet is derived from a master key (bip39 and slip-10 are used), from this master key, new keys are derived deterministicaly. As of now the master key is used only for deriving new keys, and is never used to prove identity or signing anything.

In regards to validators, their identity should become the public key of this master key used to derive wallets.
When a validator wishes to change the private key used to sign vega transaction emitted by the node (the hot key), they then generate a new hot key pair from the master key and send a transaction to notify the network of the change of public hot key. 

For the validator we set their identity, for the purposes of staking and delegation, to their public master key. The hot key controls the general account balances and is used to emit transactions to the network.

What happens on the Ethereum side? Validators to use their public master key as the "destination" when they associate ERC20 Vega token the their Vega identity.   

What happens at startup? The public master key has to be added to validators' identities in the genesis configuration.













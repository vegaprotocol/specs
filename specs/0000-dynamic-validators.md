Feature name: Dynamic Validator Set

# Acceptance Criteria

* A new validator joins the set with a given power.
* A validator leaves the set.
* Each time the validator set changes, the power is redistributed based on the
validator the validators stake proportion.
* Validator set should be reflected by the [Tendermint Validators API](http://localhost:26657/validators).
* Validator set should be stored in the persistent storage so that it can be restored upon a node recovery.

# Summary

The current network considers a fix number of validators and signers (see
[Multisig Control]()?), meaning that the initial validator set (defined in the
Genesis Block) is immutable. However, since there is an economic incentive for
being a validator, new participants will join and old participants will leave.

# Guide-Level Explanation

As stated in the [summary](#summary) the Genesis block contains an initial set
of validators which (may) vary over time. Since these changes are part of the
consensus, and they change the `AppState`, they are ultimately triggered by a
`DeliverTx` Transaction. The effect of such transaction might not happen
immediately, but recorded and executed after a new [`epoch`](TODO: More on this)
happens.

## Adding a new Validator

The process starts with an event from the Bridge which atests that a the
contract (TODO: Add Reference) has been executed. Once this reaches Vega
network the event is included in a block (via `DeliverTx`).

## Removing a Validator

In this case the process starts with a Vega transaction sent by the validator
who wants to leave the network and unstake its tokens.

# Reference-Level Explanation
The application may set the validator set during `InitChain`, and update it
during
[`EndBlock`](https://docs.tendermint.com/master/spec/abci/abci.html#endblock)
method. Updates to the Tendermint validator set can be made by returning
`ValidatorUpdate` objects in the [`ResponseEndBlock`](https://docs.tendermint.com/master/spec/abci/apps.html#validator-updates).

The application object will contain a `validator.Set` object which handles the validator set. The object is constructed by the Application constructor.
Adding and Removing a validator should invoke `Add` and `Remove` methods in the `processor.Processor` module.
To update the set `Iterate` will be executed by the `ABCI` application inside the `EndBlock` method to construct a new validator Set.

# Pseudo-code / Examples
```go
package validator

// Set 
type Set interface {
   // Add adds a new validator to the set and recomputes the remaining
   // validators power.
   Add(id Pubkey, stake Decimal)

   // Remove removes a validator from the set and recomputes the remaining
   // validators power.
   Remove(id Pubkey)

   // Iterate calls fn for each validator on the Set.
   Iterate(fn func(id Pubkey, power Decimal))
}

// Store is a generic storage interface. It's designed to integrate well with
// the current storage interfaces defined by the persistance layer.
type Store interface {
   Set(key []byte, value []byte)
   Get(key []byte) []byte)
}

// NewSet returns a Set given a store using MaxTotalVotingPower defined by Tendermint.
func NewSet(s Store) Set {
   return NewSetWithMaxVotingPower(s, abci.MaxTotalVotingPower)
}

// NewSetWithMaxVotingPower manages validators distributing power based on max.
func NewSetWithMaxVotingPower(s Store, max uint64) Set {
}
```

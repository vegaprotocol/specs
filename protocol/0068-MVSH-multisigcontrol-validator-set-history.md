# Multisigcontrol validator set history

This document cover an extension of the 0030-multisig_control_spec.md specification.

## Actual problem

As of now the multisig control contract store at all time a single set of validators authorised to sign for withdrawal bundles.
This set of validator is updated as soon as the function `add_signer` or `remove_signer` are called.

Because of this behaviour and the lack of knowledge for the passed signers, withdrawal bundle produced with a validators set which is too different,
effectively a bundle of signature where less than the required `threshold` of signature from the current set of validator
is not reach anymore would become invalid.

## Introducing a validator set history

### Smart contract

In order to address this issue we propose to keep the history of every validator set which have since the deployment of the contract.
Each validators set will get a sequence number assigned, and increment everytinme the `add_signer` or `remove_signer` functions are called.
All withdraw bundle shall not require as well the sequence number of the validator set which signed the bundle.
The sequence number shall also be added to the message to be signed by the validators.
The threshold should be stored with the current validator set, and should not be able to be update for an old validator set.

In order to prevent any malicious withdrawal from a previous validator set, we also introduce a new function to the contract so the current
validator set can disallow processing withdrawal with a given sequence number.

The multisig control shall emit an event when the new validator set has been update with the new sequence number and the list of new validators.

### Vega network

The vega network will need to add as part of the payload of every withdrawals the new sequence number, and sign it as part of the signed message.
The network will also need to listen to event emitted by the contract in order to ensure that the validator set recognized by the contract is the one
that the network has been acknowledging, If those where to differ too much, then the network should prevent any new withdrawals through some mecanism
that I haven't though of(@Barney, @David I most likely inventing some stupid things here, please correct me).

### Pseudo code implementation

We add a new mapping of validators history a new event and a new way of validating signatures, updating the threshold and setting a sequence number to disallow:
```
struct ValidatorsSet {
	validators set<address>
	valid bool
	threshold uint16
}

var validators := map<SequenceNumber, ValidatorSet>
var lastSequnce uint256

event ValidatorSetUpdate {
	validators set<address>
	sequenceNumber int
	threshold uint16
}

func disallow_validator_set(sequenceNumber uint256, validatorsSignatures []signatures) {
	if sequence_number => lastSequence { // strictly superior or equal so we avoid setting ourself as disallowed
		panic
	}

	if validatorsSignature != true { // with validators[lastSequence]
		panic
	}

	validators[sequenceNumber].valid = false
}

func add_signer(newValidator address, validatorsSignatures []signatures) {
	if validatorsSignature != true { // with validators[lastSequence]
		panic
	}
	currentSet = validators[lastSequence]
	newSet = currentSet.copy()
	newSet.add(newValidator)
	lastSequence++
	validators[lastSequence] = ValidatorSet{newSet, true}
	// send ValidatorSetUpdate
}

func remove_signer(oldValidator address, validatorsSignatures []signatures) {
	if validatorsSignature != true { // with validators[lastSequence]
		panic
	}
	currentSet = validators[lastSequence]
	newSet = currentSet.copy()
	newSet.delete(oldValidator)
	lastSequence++
	validators[lastSequence] = ValidatorSet{newSet, true}
	// send ValidatorSetUpdate
}

func verify_signatures(signatures []signatures, message bytes, nonce uint56, sequence unt256) {
	if sequence > lastSequence {
		panic
	}

	validatorsSet = validators[sequence]
	if validatorSet.valid != true {
		panic
	}

	// verify as usual
}

func set_threshold(threshold uint16, signatures []signatures) {
	if validatorsSignature != true { // with validators[lastSequence]
		panic
	}

	validatorsSet[lastSequence].treshold = treshold
}

```

### Acceptance criteria

- [ ] As a user I submit a withdrawal bundle without a sequence number, withdrawal fail
- [ ] As a user I submit a withdrawal bundle with a sequence bigger than lastSequence, withdrawal fail
- [ ] As a user I submit a withdrawal bundle with a sequence which have been disallowed, withdrawal fail
- [ ] As a user I can submit a valid withdrawal with a correct sequence number
- [ ] As a validator I submit a payload to remove a validator from the set, the sequence number increase and the event is emitted
- [ ] As a validator I submit a payload to add a validator from the set, the sequence number increase and the event is emitted
- [ ] As a validator I can submit a transaction to disallow the usage of a bundle used for a given sequence number
- [ ] As a validator submitting a transaction to disallow the usage of a bundle used for a given sequence number which is >= to lastSequence will fail

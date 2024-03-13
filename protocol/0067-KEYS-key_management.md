# Key Management

## Definitions

The term "key loss" usually refers to both the key becoming unavailable, and the key being obtained
by a non-authorised party. To distinguish these two cases, we will use the term 'key loss' for the former
(the validator looses access to the key), and 'key compromise' for the later.

For all thresholds, we assume n validators, up to t of them may be malicious. At this point, we do not
take into account validator weights; this will change eventually for the Tendermint key, at which
point we will have a total weight of n with up to t weight being tolerated to be corrupted.

## Keys

### Ethereum Key [Staking]

The staking Ethereum Key is the key to which the Vega ERC-20 tokens are tied. This key is no different
to the key held by any other tokenholder or indeed any participant on the Ethereum blockchain.
It is only required to move the vega tokens to another Ethereum address (public key) or to associate the tokens
to a Vega key.

Once the association to a Vega key is finished this key is not required and thus can be kept in cold storage.
"Changing" this key would require the holder to move the Vega tokes to another public key they control.
This is not possible for Vega tokens held by the vesting contract. If this key
gets lost, the the Vega tokens become unmovable. If they have previously been associated to a Vega key
then they keep generating staking income. The Vega key can be used on the Vega network to withdraw staking rewards
from the Vega general account to any Ethereum address (specified during submission of the withdrawal transaction).

### Ethereum Key [multisig]

The Ethereum key is the key used to communicate with the [multisig contract](0030-ETHM-multisig_control_spec.md).
This is *the most critical key*, as a compromise of n-t keys allows full access to the ERC-20 tokens
held by the Vega multisig contract (network treasury, all parties staking rewards, all collateral assets).
The loss of t+1 keys stops the ability of the validators (multisig signers) to use the smart contract (add / remove signers, approve withdrawals).

For this key, it is thus most important the HSM support is enabled. Signing latency here is a non-issue issue,
as this key is used on Ethereum speed, and thus added latency is easily tolerable.

Note that this key has nothing to do with the "Ethereum Key [staking]" that holds a validator's
Vega ERC-20 tokens they use for staking and self-delegation.

As the verification of signatures done with this key is happening on the Ethereum MultiSig smart
contract, in the current implementation it is also required to communicate
with the smart contract to deactivate or change this key; this is done
through the add/remove calls to the multisig contract, so a validator cannot do this alone at this point.

Signatures issued by the ETH key currently have no expiration for signatures. Thus a possible attack could run as follows:

1. an attacker compromises one validator, asks the HSM to sign a transaction that
transfers all assets to an address of their choice, leaves that validator.
Of course one signature isn't enough to transfer the assets.
1. Repeat the same over time with other validators.
1. Now they have n-t signatures and at this point they can withdraw all Ethereum assets controlled by the `MultiSig` contract.

Hence, a reasonably frequent key update would constitute good practice.

The local management of the ETH key is done using CLEF. Details of this are specified elsewhere.

There will be a transaction whereby a vega node can let the vega chain know that they wish to use a new Ethereum multisig key.
This transaction should make available a [multisig contract](0030-ETHM-multisig_control_spec.md) signature bundle that anyone can submit (but it should be the party changing their key really should) to update the keys held by multisig.
After this signature bundle has been issued Vega should start using the new ethereum key for issuing all future signature bundles and multisig update bundles.

## Future Features [Identity]

Better disaster management procedures in case this key gets lost are currently in the works. Especially, we're
currently looking into integrating threshold signatures, which can allow Validators to be removed, added
or change their keys without any interaction with the smart contract - the main issue here is the asynchrony
and assuring we generate a Ethereum native signature.

### Vega Key [Identity]

This key is split into master and hot key as specified in [0063-VALK](./0063-VALK-validator_vega_master_keys.md) .

It is possible to update the hot key at network restarts. The master key can be kept in cold storage
and only used to sign the update transaction.

The master Vega key is the identity of the validator, which other parties use to delegate.
Staking rewards go to the general account on Vega controlled by a hot key generated from the
master key. The Vega identity hot key is needed to retrieve the rewards.

The hot key needs to be signing many transactions with low latency. Hence storing it on a hardware security module and/or on a remote site is problematic; the exact implementation of this is out of scope for this.

## Future Features [Event-Forwarder]

We expect that a key change can be done through a transaction on the chain and a form of restarting a single validator.

### Vega Key [Event-Forwarder]

This key (which may be the same of the above one) is used by the event forwarder to authorise events seen on  Vega bridge contracts (at this
point, only Ethereum, ERC20, staking and vesting contracts).
This key is a hot key, and is constantly used in operations, though in a not very exposed way.
As events signed with this key come in at Ethereum speed, the latency in accessing this key is of little relevance, and it can easily stay in a remote signer or an HSM.

Compromise of this key is only critical if a significant number of keys are compromised (i.e., 2/3); in this case, it is possible to authorise non-existing events on the Vega chain.

## Future Features [Tendermint]

Though is not done yet, the authorisation on non-events is easy to detect, and validators are recommended to stop the chain to recover if that happens.
In the future (i.e., before serious trading happens), this key should be stored in an HSM, and it should be a good policy to frequently update it. The mechanism to this end is the same as for the other vega key specified in the document above.

Loss of this key is (in principle) easy to mitigate, though this functionality is not implemented yet; the same master key that is used for the Vega Identity key could also authorise a new event forwarder key.

Eventually, the event forwarder will be reimplemented in a way that this key will not be required anymore.

### Tendermint Key

The Tendermint key is used to sign block and Tendermint internal messages. This is thus
the key that protects the consensus layer, and a compromise might compromise the
consensus itself. The primary way that would happen is through "double signing", i.e.,
validators sign contradicting messages with the intent to create a fork.

Each compromised key (or double signing through misconfiguration) lowers the fault
tolerance of the protocol. This is, if x parties double sign, t+1-x parties are
required to halt or to create a fork. The latter is still non trivial though, as
it requires a level of control on what honest parties communicate with each other,
i.e., compromise of either the routing or some manipulation on the level of the gossip protocol.

One additional risk (which holds for all keys) is that an attacker compromises a validator, obtains a copy of the key, and then silently goes after other validators until they get a critical number of keys. Thus, the lifetime of the key should be limited.

As a single double-signing validator is of limited impact (since it requires t+1 to
pose a meaningful attack), we do not penalise or ban validators for such; thus, if
a misconfiguration in some parallelisation causes a single missing, the damage is
limited (if the validator in question is the leader, we lose one block; this will be counted against that validator in the performance measurements). This allows validators to have a less strict double signing protection (and as seen in the testnet, too strict double-signing protection can cause a validator failure due to wrongly blocking key access).

## Future Features

An alarm should be raised if:

- a validator frequently double-signs (this is likely not malicious behaviour
 of
   that validator, but a misconfiguration or a leaked key; in either case, it is something
   the validator needs to fix
- several validators double sign on the same block (especially on the same values). This
   is either a systemic bug, or a cross-validator attack (though of little use to the
   attacker if the number is < `t+1`
- more than `t+1` validators double sign. This is either a critical attack or a critical bug.
   As the base assumption for the consensus is that less than t+1 parties act malicious,
   this should prompt drastic measures, potentially even stopping the chain for an investigation,
   and at the minimum closing down the `MultiSig` bridge until the cause is known.

The exact measures and meaning of 'frequently' are still to be done.

The Tendermint key is the only performance critical signing key in the Vega system. This is because the key needs to be used several times per block, and a slow access to the key - for example through remote signing or a slow HSM - can thus become the dominant performance factor for a validator.

Though direct HSM support for this key is envisioned, we want to offer an alternative for validators that do not have access to a fast HSM (e.g., the IBM 4768), but use a slow one (such as the Yubikey HSM).

The proposed model here is that the HSM offers certificates for
the actual Tendermint key, which can then have a very short lifetime (e.g., 2 blocks); the certificates can then be signed in parallel to the running blockchain, and thus do not add to latency.
As opposed to the other keys, these certificates have an expiry time, and keys are not retired once replaced; this prevents an attacker who compromised a validator to try prevent the validator from performing a key renewal and thus keep the old key valid.

This means that an attacker who compromises a validator will be able to double-sign
messages for at most two blocks longer than it could with direct HSM usage.

- If `t+1` validators are outright malicious, they control access to their HSM, and nothing
  changes
- If some validators are compromised, the best case scenario is that they detect this latest on the first double signed message and then cut access to the HSM. If the threshold of `malicious+compromised` validators is smaller than `t+1`, this will not lead to a fork; other wise, this could lead to a fork of length 2 blocks (with above parameter).
Given the severity of that situation (more than a third of the validators compromised),

As the certification key is 'hot', i.e., needs to be reachable at any time, we also
use another key that can be used to change the tendermint certification key
[Note: We could reuse a key for different keys here]. This key also can be used
to change configuration data, such as the maximum lifetime of a certificate.

The Key certificate looks as follows: Key Certificate

`sign(
	"Vega_validator_tendermint_key",
	Validator_identity,
	Chain_restart_version,
	sequence number
	hash(block 0),
	New Key Start Time
	New Key End Time,
	New Key Start Block,
	New Key End Block,
	hash(current_block)
)`

Zero Values indicate that this parameter isn't used. This allows a validator to make a certificate either for a given time (in which case it expires with the first block that has a larger blocktime) or for a block height.
Each validator can define a maximum certificate lifetime, which is authenticated by
a separate key.

The certificate key can also be renewed (in case of a compromise, as this key is semi-hot and an attacker could sign itself future certificates, or one with an infinite running time.
Current_block is used to prevent signing of too future certificates; a certificate with a start time more than 1 hour or 3600 blocks in the future will be rejected.)
If two periods overlap, the newer one counts.

### More Future Features: Key Abuse Monitoring

A number of events that involve bad keys are easy to detect and can be mitigated with limited damage if this is done so in an early stage. To this end, a monitoring functionality is required.

Stopping the chain primarily means to (ideally physically) stop all access to the ETH multisig key, and to stop the Tendermint protocol.

In case of a malicious intrusion, it is (in theory) possible that an attacker can keep the
chain going; the damage caused by this can be limited though as long as the attacker has no access to the multisig keys.

Double Signing:

- Every double signing with a Tendermint key should be logged. If a validator repeatedly double signs, this indicates a misconfiguration, and the validator in question should raise an alarm (as should the others to make sure the affected party is motivated to resolve their issues).
- Coordinated double signing by more than one party indicated either a structural issue or an attack. If more than 1/3 of the validators double-sign the same block, it is possible to create a fork. In this case, the chain should be stopped and a thorough investigation should be done.
- Intermediate issues (such as two parties double-signing a block) should trigger an investigation, but at this point does not require any immediate action.

False Event Forwarding:

- If a non-existing Ethereum event is signed by 2/3 of the validators, the chain should be stopped immediately, and all validators should change all keys and assume a full compromise of their systems.
- A single wrong signature on an event should trigger an investigation, as this is a rather unlikely bug to happen, but also a pretty ineffective attack.

Wrong `Multisigs`

- If is possible to detect (some) wrong interactions with the smart contract, e.g., giving a party more assets than they own, or failing to reduce the vega assets according to the vega chain. If this happens, the chain should be stopped immediately.
- A single validator issuing a wrong signature on the multisig contract indicates a serious bug or malice. This should trigger an immediate investigation, but not a stop of the chain right away (as that would be an efficient DoS). It might be a consideration to temporarily suspend payouts in such a case until the cause of the issue is identified.

#### Footnotes

(*) We could time-limit the signatures, but that'd mean that if a user gets a withdrawal signed,
they have to submit it fairly quickly; this is not wanted (though I don't see a big issue with a time
limit of a week).
The alternative is that the individual signatures have a timestamp using the hash of
the last ETH block, and the block number used for the different components of the multisig
must be 'close to each other'; this would also prevent a pre-singing attack. This, however,
would add $10+ of gas cost for each validator, as now each signature would be different and
need to be hashed individually).

## Acceptance Criteria

### Generic

1. After both a Vega and Ethereum key rotation, rewards are still produced (<a name="0067-KEYS-006" href="#0067-KEYS-006">0067-KEYS-006</a>)
2. After both a Vega and Ethereum key rotation the node still has the ability to self stake/delegate and delegate to other validator nodes (<a name="0067-KEYS-007" href="#0067-KEYS-007">0067-KEYS-007</a>)
3. After both a Vega and Ethereum key rotation the node still can generate snapshots and these can successfully be used for node restarts (<a name="0067-KEYS-008" href="#0067-KEYS-008">0067-KEYS-008</a>)
4. After both a Vega and Ethereum key rotation ensure there is no impact on node validator scores; meaning that if - the validator has been proposing blocks as expected and thus has a score close to `1` then after key rotation there is no sudden change in score. (<a name="0067-KEYS-009" href="#0067-KEYS-009">0067-KEYS-009</a>)
    - If the validator has not been proposing blocks as expected and their score is close to `0` then after the rotation there is no sudden jump in score towards `1`.  (<a name="0067-KEYS-010" href="#0067-KEYS-010">0067-KEYS-010</a>)

### Ethereum key

1. multisig interaction (<a name="0067-KEYS-001" href="#0067-KEYS-001">0067-KEYS-001</a>):
    - A Vega network is running with 3 validators, `v1,v2,v3` with Ethereum keys `k1, k2, k3_old`; each with equal tendermint and multisig weight.
    - Validator `v3` has Ethereum multisig public key `k3_old`. They submit a transaction to replace by Ethereum multisig public key `k3_new`.
    - The network issues a signature bundle to update that can be submitted to the Ethereum multisig contract to update the key there.
    - This is submitted to Ethereum; the multisig contract is updated.
    - Vega nodes receive the event confirming the key has been updated.
    - Party `p` now issues a withdrawal transaction. A withdrawal bundle is created utilising `k1,k2,k3_new`.
    - Party `p` submits the withdrawal bundle to Ethereum; multisig contract accepts it and transfers the funds on the Ethereum chain.
1. Non-tendermint validators rotating keys does not generate signatures (<a name="0067-KEYS-003" href="#0067-KEYS-003">0067-KEYS-003</a>):
    - A Vega network is running such there is at least 1 ersatz
    - Submit a transaction to rotate their Ethereum keys.
    - Verify that once `target_block` is reached, the data-node reports that the rotation occurred.
    - Verify that no signatures bundles are emitted from core to add/remove either the new key or the old key.
    - Repeat the above steps for a pending validator
1. Subsequent rotations cannot be submitted until the previous rotation is resolved on the contract (<a name="0067-KEYS-004" href="#0067-KEYS-004">0067-KEYS-004</a>):
    - Start a Vega network and pick a tendermint validator.
    - Submit a transaction to rotate their Ethereum key.
    - Verify that signatures bundles are emitted from core, but do not submit them to the multisig contract.
    - Submit another transactions to their rotate Ethereum keys.
    - Verify that the transaction fails. This is to prevent multiple valid add-signer bundles for the same validator.
1. Transaction with no proof of ownership of the new Ethereum key fails (<a name="0067-KEYS-005" href="#0067-KEYS-005">0067-KEYS-005</a>):
    - Start a Vega network and pick a tendermint validator.
    - Submit a transaction to rotate their Ethereum keys which contains an invalid Ethereum signature.
    - Verify that the transaction fails.
1. Vega hot key (<a name="0067-KEYS-002" href="#0067-KEYS-002">0067-KEYS-002</a>):
    - There is a vega validator `v3` with master key `M` and hot key `h3_old`. See [master and hot vega keys](0063-VALK-validator_vega_master_keys.md).
    - A Vega network is running with 3 validators, `v1,v2,v3` using Vega hot keys `h1,h2,h3_old`.
    - Validator `v3` generates a new hot key `h3_new` using the master key `M`.
    - Validator `v3` submits a transaction to vega chain announcing that they'll be using `h3_new` instead of `h3_old`.
    - Validator `v3` stops their node, restarts with the new key and replays the chain or restore from snapshot.

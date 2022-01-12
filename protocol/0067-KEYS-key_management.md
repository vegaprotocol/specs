# Key Management

## Definitions:
The term "key loss" usually refers to both the key becomming unavailable, and the key being obtained
by a non-authorized party. To distinguish these two cases, we will use the term 'key loss' for the former
(the validator looses access to the key), and 'key compromise' for the later.

For all thresholds, we assume n validators, up to t of them may be malicious. At this point, we do not
take into account validator weights; this will change eventually for the Tendermint key, at which 
point we will have a total weight of n with up to t weight being tolerated to be corrupted.

## Keys

### Ethereum Key [Staking]
The staking Ethereum Key is the key to which the Vega ERC20 tokens are tied. This key is no different
to the key held by any other tokenholder or indeed any participant on the Ethereum blockchain. 
It is only required to move the vega tokens to another Ethereum address (public key) or to assiciate the tokens 
to a Vega key. 

Once the association to a Vega key is finished this key is not required and thus can be kept in cold storage. 
"Changing" this key would require the holder to move the Vega tokes to another public key they control. 
This is not possible for Vega tokens held by the vesting contract. If this key
gets lost, the the Vegsa tokens become unmovable. If they have previously been associated to a Vega key 
then they keep generating staking income. The Vega key can be used on the Vega network to withdraw staking rewards
from the Vega general account to any Ethereum address (specified during submission of the withdrawal transaction). 

### Ethereum Key [MultiSig]
The Ethereum key is the key used to communicate with the multisig contract. 
This is *the most critical key*, as a compromise of n-t keys allows full access to the ERC20 tokens 
held by the Vega multisig contract (network treasury, all parties staking rewards, all collateral assets). 
The loss of t+1 keys stops the ability of the validators (multisig signers) to use the smart contract (add / remove signers, approve withdrawals). 

For this key, it is thus most important the HSM support is enabled. Signing latency here is a non-issue issue,
as this key is used on Ethereum speed, and thus added latency is easily tolerable.

Note that this key has nothing to do with the "Ethereum Key [staking]" that holds a validator's
Vega ERC20 tokens they use for staking and self-delegation. 

As the verification of signatures done with this key is happening on the Ethereum MultiSig smart
contract, in the current implementation it is also required to communicate 
with the smart contract to deactivate or change this key; this is done
through the add/remove calls to the multisig contract, so a validator cannot do this alone at this point.

Signatures issued by the ETH key currently have no expiration for signatures. Thus a possible attack could run as follows: 
1) an attacker compromises one validator, asks the HSM to sign a transaction that
transfers all assets to an address of their choice, leaves that validator. 
Of course one signature isn't enough to transfer the assets. 
2) Repeat the same over time with other validators. 
3) Now they have n-t signatures and at this point they can withdraw all Ethereum assets controlled by the 
MultiSig contract.

Hence, a resonably frequent key update would constitute good practice.  

The local management of the ETH key is done using CLEF. Details of this are specified elsewhere.

## Future Features
Better disaster management procedures in case this key gets lost are currently in the works. Especially, we're
currently looking into integrating threshold signatures, which can allow Validators to be removed, added
or change their keys without any interaction with the smart contract - the main issue here is the asynchrony
and assuring we generate a Ethereum native signature.



### Vega Key [Identity]

This key is split into master and hot key as specified in https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0063-validator-vega-master-keys.md . 

It is possible to update the hot key at network restarts. The master key can be kept in cold storage
and only used to sign the update transaction. 

The master Vega key is the identity of the validator, which other parties use to delegate. 
Staking rewards go to the general account on Vega controlled by a hot key generated from the 
master key. The Vega identity hot key is needed to retrieve the rewards. 

The hot key needs to be signing many transactions with low latency. Hence storing it on a hardware security module and/or on a remote site is problematic; the exact implementation of this is out of scope for this. 

##Future Features
We expect that a key change can be done through a transaction on the chain and a form of restarting a single validator once ceckpoints
are fully implemented.

### Vega Key [Event-Forwarder]
This key (which may be the same of the above one) is used by the event forwarder to authorize events seen on  Vega bridge contracts (at this 
point, only Ethereum, ERC20, staking and vesting contracts). 
This key is a hot key, and is constantly used in operations, though in a not very esposed way. 
As events signed with this key come in at Ethereum speed, the latency in accessing this key is of little relevance, and it can easily stay in a remote signer or an HSM.



Compromise of this key is only critical if a significant number of keys are compromised (i.e., 2/3); in this case, it is possible to authorize non-existing events on the Vega chain. 

## Future Features
Though is not done yet, the authorisation on non-events is easy to detect, and validators are recommended to stop the chain to recover if that happens. 
In the future (i.e., before serious trading happens), this key should be stored in an HSM, and it should be a good policy to frequently update it. The mechanism to this end is the same as for the other vega key specified in the document above.

Loss of this key is (in principle) easy to mitigate, though this functionality is not implemented yet; the same master key that is used for the Vega Identity key could also authorize a new event forwarder key.

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
i.e., compromise of either the routing or some manipulation on the level of the gossip
protocol.

One additional risk (which holds for all keys) is that an attacker compromises a validator,
obtains a copy of the key, and then silently goes after other validators until they get
a critical number of keys. Thus, the lifetime of the key should be limited.

As a single double-signing validator is of limited impact (since it requires t+1 to 
pose a meaningful attack), we do not penalize or ban validators for such; thus, if
a missconfiguration in some parallelization causes a single missigning, the damage is
limited (if the validator in question is the leader, we lose one block; this will be
counted against that validator in the performance measurements). This allows validators
to have a less strict double signing protection (and as seen in the testnet, too strict
double-signing protection can cause a validator failure due to wrongly blocking key access). 

##Future Features
An alarm should be raised if
- a validator frequently double-signs (this is likely not malicious behehaviour of 
   that validator, but a misconfiguratio or a leaked key; in either case, it is something
   the validator needs to fix
- several validators double sign on the same block (especially on the same values). This
   is either a systemic bug, or a cross-validator attack (though of little use to the 
   attacker if the number is < t+1
- more than t+1 validators double sign. This is either a critical attack or a critical bug.
   As the base assumption for the consensus is that less than t+1 parties act malicious, 
   this should prompt drastic measures, potentially even stopping the chain for an investigation,
   and at the minimum closing down the MultiSig bridge until the cause is known.

The exact measures and meaning of 'frequently' are still to be done.

The Tendermint key is the only performance critical signing key in the Vega system. This is
because the key needs to be used several times per block, and a slow access to the key -
for example through remote signing or a slow HSM - can thus become the dominant perfomance
factor for a validator. 

Though direct HSM support for this key is envisioned, we want to offer an alternative for
validators that do not have access to a fast HSM (e.g., the IBM 4768), but use a slow one
(such as the Yubikey HSM). 

The proposed model here is that the HSM offers certificates for
the actual Tendermint key, which can then have a very short lifetime (e.g., 2 blocks);
the certificates can then be signed in parallel to the running blockchain, and thus 
do not add to latency. 
As opposed to the other keys, these certificates have an expiry time, and keys are not 
retired once replaced; this prevents an attacker who compromised a validator to try 
prevent the validator from performing a key reneval and thus keep the old key valid.

This means that an attacker who compromises a validator will be able to double-sign 
messages for at most two blocks longer than it could with direct HSM usage. 

- If t+1 validators are outright malicious, they control access to their HSM, and nothing 
  changes
- If some validators are compromised, the best case scenario is that they detect this latest
  on the first double signed message and then cut access to the HSM. If the threshold of
  malicious+compromised validators is smaller than t+1, this will not lead to a fork; other
  wise, this could lead to a fork of lenght 2 blocks (with above parameter).
  Given the severity of that situation (more than a third of the validators compromised), 

As the certitifacion key is 'hot', i.e., needs to be reachable at any time, we also
use another key that can be used to change the tendermint certification key 
[Note: We could reuse a key for different keys here]. This key also can be used
to change configuration data, such as the maximum lifetime of a certificate.

The Key certificate looks as follows: Key Certificate
sign(
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
)

Zero Values indicate that this parameter isn't used. This allows a validator to make
a certificate either for a given time (in which case it expires with the first block
that has a larger blocktime) or for a block height.
Each validator can define a maximum cerfiticate lifetime, which is authenticated by
a separate key.

The certificate key can also be renewed (in case of a compromise, as this key is semi-hot
and an attacker could sign itselfs future certificates, or one with an infinite running time.
Current_block is used to prevent signing of too future certificates; a certificate with a start time
more than 1 hour or 3600 blocks in the future will be rejected.)
If two periods overlap, the newer one counts.


### More Future Features: Key Abuse Monitoring
A number of events that involve bad keys are easy to detect and can be mitigated with limited damage if this is done so in an early stage. To this end, a monitoring functionallity is required. 

Stopping the chain primarily means to (idealy physically) stop all access to the ETH multisig key, and to stop the Tendermint protocol. 

In case of a malicious intrusion, it is (in theory) possible that an attacker can keep the
chain going; the damage caused by this can be limited though as long as the attacker has no access to the multisig keys.

- Double Signing
	Every double signing with a Tendermint key should be logged. If a validator repeatedly double signs, this indicates
	a misconfiguration, and the validator in question should rais an alarm (as should the others to make sure the
	affected party is motivated to resolve their issues).
	Coordinated double signing by more than one party indicated either a structural issue or an attack. If more than 1/3
	of the validators double-sign the same block, it is possible to crearte a fork. In this case, the chain should be stopped
	and a thorough investigation should be done. 
	Intermediate issues (such as two parties double-signing a block) should trigger an investigation, but at this point does
	not require any immediate action.
- False Event Forwarding
	If a non-existing Ethereum event is signed by 2/3 of the validators, the chain should be stopped immediatelly, and all
	validators should change all keys and assume a full compromise of their systems.
	A single wrong signature on an event should trigger an investigation, as this is a rather unlikely bug to happen, but
	also a pretty ineffective attack.
- Wrong Multisigs
	If is possible to detect (some) wrong interactins with the smart contract, e.g., giving a party more assets than they own, or
	failing to reduce the vega assets according to the vega chain. If this happens, the chain should be stopped immediatelly.
	A single validator issuing a wrong signature on the multisig contract indicates a serious bug or malice. This should trigger
	an immediate investigation, but not a stopp of the chain right away (as that would be an efficient DoS). It might be a consideration
	to temporarily suspend payouts in such a case until the cause of the issue is identified.


#### Footnotes

(*) We could time-limit the signatures, but that'd mean that if a user gets a withdrawal signed, 
they have to submit it fast-ish; this is not wanted (though I don't see a big issue with a time
limit of a week).
The alternative is that the individual signatures have a timestamp using the hash of
the last ETH block, and the block number used for the different components of the multisig
must be 'close to each other'; this would also prevent a pre-singing attack. This, however,
would add $10+ of gas cost for each validator, as now each singature would be different and
need to be hashed individually).

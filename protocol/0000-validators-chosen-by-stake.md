# Validators chosen by stake

New network parameter `network.numberOfTendermintValidators`. 
New network parameter `network.validatorIncumbentBonus`.
New network parameter `network.numberEthMultisigSigners`

At a high level a participant that wishes to become a validator will:
1) start a Vega node as non-validating node + associated infra 
1) submit a transaction, see below for details, with their keys, saying they want to validate.
1) self-stake to their validator Vega key at least `reward.staking.delegation.minimumValidatorStake`. 
1) wait for others to delegate to them. 

Note that to be eligible as a potential validator certain criteria need to be met: 
1) Own stake >= `reward.staking.delegation.minimumValidatorStake`. 
1) Network has verified key ownership (see below).


At the end of each epoch Vega will calculate the unnormalised `validator_score`, see [rewards spec](0061-simple-POS-rewards-SweetWater.md). 
For validators currently in the Vega validator set it will scale the `validator_score` by `(1+network.validatorIncumbentBonus)`. 
Note that this number combines own + delegated stake together with `performance_score` which measures basic node performance together whether the multisig contract carries the correct information [multisig](0030-multisig_control_spec.md); more on this later.

Vega will sort all current Tendermint validators as `[v_1, ..., v_n]` with `v_1` with the highest and `v_n` with the lowest score. 
If `v_l = v_m` then we place higher the one who's been validator for longer.
Vega will sort all those who submitted a transaction wishing to be validators using `validator_score` as `[w_1, ..., w_k]`. 
These may be ersatz validators (ie getting rewards) or others who just submitted the transaction to join.
If `empty_slots := network.numberOfTendermintValidators - n > 0` (we have empty tendermint validator slots) then the top `empty_slots` from `[w_1, ..., w_k]` are promoted to tendermint validators. 
If `w_1>v_n` (i.e. the highest scored potential validator has more than the lowest score incumbent validator) then in the new epoch `w_1` becomes a Tendermint validator, and the lowest scoring incubent becomes an ersatz validator. If `w_l = w_m` then we resolve this by giving priority to the one who submitted the transaction to become validator earlier.  Note that we only do this check once per epoch so at most one validator can be changed per epoch in case `empty_slots == 0`.
A completely dead node that's proposing to become a validator will have `performance_score = 0` and will thus get automaticaly excluded, regardless of their stake.

The same way, if there are free slots for ersatz validators and nodes that have submitted the transaction to join and satisfy all joining conditions, they are added as ersatzvalidators in the next round.
If a node that submitted the transaction to join and satisfies all other conditions and there and has a higher score than the lowest scoring ersatz validator (scaled up by the incubent factor), then (assuming it did not just become a Tendermint validator), it becomes an ersatz validator and the lowest scoring ersatz validator is kicked out. The 'transaction to join' of a validator kicked out this way remains active until the delegated stake drops below the required minimum. As the nodes have not have the opportunity to get a performance record, their performance valued as the average of the performance scores of all ersatzvalidators.
[Comment (kku): I'm not happy with this, as it meansthat someone with a near zero performance can make the request to join, get in, perform poorly, be kicked out, wait an epoch, get in again etc. This still seems a better way than doing something really complicated here. One other scenario is that a validator stops operating, but keeps having some stake; this one would then linger around as a zombie (and potentially be promoted from time to time) forever. Thus, it might be better to expire the 'transaction to join' at some point (?)]
[Comment (kku): Didn't we want the optional mechanism that one can become ersatzvalidator based on a minimum amount of stake and have an open number ?]

As both these checks are done between epochs, it is possible for a validator to be demoted first from tendermint validator to ersatzvalidator, and then from ersatzvalidator to nothing.
## Becoming validator transaction 
All keys mentioned here are understood to match the node configuration.

This will include (all as strings):
- node id (which is the master key) `id`
- Vega public key `vega_pub_key` 
- Tendermint key `tm_pub_key`
- Ethereum address `ethereum_address`
- `name`, `info_url`, `avatar_url`, 
- starting epoch number: number of epoch from start of which they are expected to perform

for example:
```
        "id": "126751c5830b50d39eb85412fb2964f46338cce6946ff455b73f1b1be3f5e8cc",
        "vega_pub_key": "a6e6f7daf8610f9242ab6ab46b394f6fb79cf9533d48051ca7a2f142b8b700a8",
        "ethereum_address": "0x14174f3c9443EdC12685578FE4d165be5f57fBd3",
        "tm_pub_key": "0ShTSZ9Ss8AFHuDz1nIGMrGucjXhFdJyUTT7Eqibjq8=",
        "info_url": "https://www.greenfield.one",
        "country": "Germany",
        "name": "Greenfield One",
        "avatar_url": "https://www.greenfield.one/avatar.png"
```

[Comment (kku): What would happen if I send a different id with an existing public key, or resubmit the same id & public key with a different ethereum adress ?  ? Do we need to catch this, and should we add proof of knowledge of the private key ? ]

## Running a candidate non-validator node
Start [node as a validator node](https://github.com/vegaprotocol/networks/blob/master/README.md).

From now we assume that the transaction has been submitted and the node started. 

## Minimum performance criteria

Basic vega chain liveness criteria is covered in their [performance score](0064-validator-performance-based-rewards.md). 

## Verifying Ethereum (and later other chain) integration
1) They will be the first node to forward a subsequently accepted ethereum event at least `validator.minimumEthereumEventsForNewValidator` with a default of `3`. 
1) They are the first one to vote for any ethereum event at least `validator.minimumEthereumEventsForNewValidator` times. 

## Multisig updates (and multisig weight updates if those are used)

Vega will know initial multisig signer list (and weights) and watch for `signer added` and `signer removed` events to track which ethereum keys are present on multisig.
Once (if) the ethereum multisig contract supports validator weights the vega node will watch for Ethereum events announcing the weight changing. 
Thus for each validator that is on the multisig contract it will know the validator score (weight) the ethereum multisig is using. 

We will have `network.numberEthMultisigSigners` represented on the multisig (currently `13`) but this could change. 

In the reward calculation for the top `network.numberMultisigSigners` by `validator_score` (as seen on VEGA) use `min(validator_score, ethereum_multisig_weight)` when calculating the final reward with `0` for those who are in the top `network.numberMultisigSigners` by score but *not* on the multisig contract. 

Thus a validator who is not there but should be has incentive to pay gas to update the multisig. Moreover a validator who's score has gone up substantially will want to do so as well. 

As a consequence, if a potential validator joined the Vega chain validators but has *not* updated the Multisig members (and/or weights) then at the end of the epoch their score will be `0`. 
They will not get any rewards and at the start of the next epoch they will be removed from the validator set. 

Note that this could become obsolete if a future version of the protocol implements threshold signatures or another method that allows all validators to approve Ethereum actions. 


## Ersatz validators
New Network Parameter: `MultipleOfTendermintValidatorsForEtsatzSet`
In addition to the normal validators, there is an additional set of Ersatz validators as defined by
the corresponding network parameter. 
These are validators that do not contribute to the chain, but are on standby to jump in if a normal validator drops off. 
The network will reward 
```
n' := ceil(MultipleOfTendermintValidatorsForEtsatzSet x NumberOfTendermintValidators)
```
ersatz validators. 
The value range for this decimal is `0.0` to `infinity`. 
Reasonable values may be e.g. `0.5`, `1.0` or `2.0`.

As the other validators, Ersatz validators are defined through own + delegated stake, being the validators
with the scores below the tendermint ones; is `NumberOfTendermintValidators` is `n` and NumberOfErsatzValdators is `n'`, 
then these are the validators with scores `n+1` to `n+n'`.


### Performance of Ersatz validators
Ersatz validators are required non-validator Vega node with all the related infrastructure (etheremum forwarder, data node etc.) at all times, see [the section on performance for non-validator nodes in](0064-validator-performance-based-rewards).

### Rewards for Ersatz validators
In terms of rewards, Ersatz validators are treated in line with Tendermint validators see details in [validator rewards spec](0064-validator-performance-based-rewards) and [perfomance measurement](0064-validator-performance-based-rewards).

### Multisig for Ersatz validators
At this point, Ersatz validators are not part of the Multisig.


## Restarts from LNL checkpoint:

See [limited network life spec](../non-protocol-specs/0005-limited-network-life.md).
1. At each checkpoint we include node IDs of validators and their scores (meaning all the ones participating in consensus and those who submitted a transaction to become a validator and thus are eligible to be a validator or ersatz validator).
1. When initiating the restart all the nodes participating have the same Tendermint weight in genesis (or whatever they set / agree). This is used until the LNL file has finished processing. 
1. When loading LNL file we have to run the same algorithm that selects the "correct" validators; after this is done Tendermint weights are updated.
1. If the validators arising from LNL weight updates are missing from the chain because they haven't started nodes then the chain will stop. The restart needs better coordination so the relevant nodes are present. 


# Acceptance criteria

## Joining / leaving VEGA chain
1) A running non-validator node can submit a transaction to become a validator. 
2) Their perfomance score will be calculated. See [performance score](0064-validator-performance-based-rewards.md).
3) If they meet the Ethereum verification criteria and have enough stake they will become part of the validator set at the start of next epoch. See about [verifying ethereum integration](#VerifyingEthereum).
4) Hence after the end of the current epoch the node that got "pushed out" will no longer be a validator node for Tendermint. 

## Multisig update
1) Vega network receives the ethereum events updating the weights and stores them (`key`,`value`). 
2) For validators up to `number_multig_signers` the `validator_score` is capped by the value on `ethereum`, if available and it's `0` for those who should have value on Ethereum but don't (they are one of the top `number_multig_signers` by `validator_score` on VEGA). 
3) It is possible to submit a transaction to update the weights. 


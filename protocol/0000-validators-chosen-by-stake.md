# Validators chosen by stake

New network parameter `network.numberOfValidators`. 
New network parameter `network.validatorIncumbentBonus`.
New network parameter `network.numberMultisigSigners`

At a high level a participant that wishes to become a validator will:
1) start a Vega node as non-validating node + associated infra 
1) submit a transaction, see below for details, with their keys, saying they want to validate.
1) self-stake to their validator Vega key at least `reward.staking.delegation.minimumValidatorStake`. 
1) wait for others to delegate to them. 

Note that to be eligible as a potential validator certain criteria need to be met: 
1) Own stake >= `reward.staking.delegation.minimumValidatorStake`. 
1) Network has verified key ownership (see below).


At the end of each epoch Vega will calculate `validator_score`, see [rewards spec]. 
For validators currently in the Vega validator set it will scale the `validator_score` by `(1+see [rewards spec])`. 
Note that this number combines own + delegated stake together with `performance_score` which measures basic node performance togther whether the multisig contract carries the correct information [multisig](0030-multisig_control_spec.md); more on this later.

Vega will sort all current validators as `[v_1, ..., v_n]` with `v_1` with the highest and `v_n` with the lowest score. 
If `v_l = v_m` then we place higher the one who's been validator for longer.
Vega will sort all those who submitted a transaction wishing to be validators using `validator_score` as `[w_1, ..., w_k]`. 
If `w_1>v_n` (i.e. the highest scored potential validator has more than the lowest score incumbent validator) then in the new epoch `w_1` becomes a Tendermint validator. If `w_l = w_m` then we resolve this by giving priority to the one who submitted the transaction to become validator earlier.  
A completely dead node that's proposing to become a validator will have `performance_score = 0` and will thus get automaticaly excluded, regardless of their stake.


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

## Running a candidate non-validator node
Start [node as a validator node](https://github.com/vegaprotocol/networks/blob/master/README.md).

From now we assume that the transaction has been submitted and the node started. 

## Minimum performance criteria

Basic vega chain liveness criteria is covered in their [performance score](0064-validator-performance-based-rewards.md). 

## Verifying Ethereum (and later other chain) integration
1) They will be the first node to forward a subsequently accepted ethereum event at least `validator.minimumEthereumEventsForNewValidator` with a default of `3`. 
1) They are the first one to vote for any ethereum event at least `validator.minimumEthereumEventsForNewValidator` times. 

## Multisig updates (and multisig weight updates if those are used)

Once (if) the ethereum multisig contract supports validator weights the vega node will watch for Ethereum events announcing the weight changing. 
Thus for each validator that is on the multisig contract it will know the validator score (weight) the ethereum multisig is using. 
Vega node will watch for multisig signer changes. 

We will have `network.numberMultisigSigners` represented on the multisig (currently `13`) but this could change. 

In the reward calculation for the top `network.numberMultisigSigners` by `validator_score` (as seen on VEGA) use `min(validator_score, ethereum_multisig_val_score)` when calculating the final reward with `0` for those who are in the top `network.numberMultisigSigners` by score but *not* on the multisig contract. 

Thus a validator who is not there but should be has incentive to pay gas to update the multisig. Moreover a validator who's score has gone up substantially will want to do so as well. 

As a consequence, if a potential validator joined the Vega chain validators but has *not* updated the Multisig members (and/or weights) then at the end of the epoch their score will be `0`. 
They will not get any rewards and at the start of the next epoch they will be removed from the validator set. 

Note that this could become obsolete if a future version of the protocol implements threshold signatures or another method that allows all validators to approve Ethereum actions. 


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

## Ersatzvalidators
New Network Parameter: NumberOfErsatzValidators
New Network Parameter: MinmumStakeForErsatzValidator
In addition to the normal validators, theres an additional set of Ersatzvalidators as defined by
the corresponding network parameter. These are vlidators that do not contribute to the 
chain, but are on standby to jump in if normal validator drops off. 

As the other validators, Ersatzvalidators are defined through delegated stake, being the validators
with the scores below the normal ones; is NumberOfValidators ia n and NumberOfErsatzValdators is n', 
then these are the validators with scores n+1 to n+n'.

If n'=0, then all Validators that have more than MinimumStakeForErsatzValidator are treated
as Ersatzvalidators. 

#Performance
Ersatzvalidators are required to monitor the primary chain and keep an upded state of
Vega at all times. Any performance measurements that relate to Validators
being required to keep an accurate stake also apply to Ersatzvalidators.

As Ersatzvalidators are not part of the Tendermint chain, their network performance
on that chain cannot be measured. For this reason, Ersatzvalidators are supposed to
participate in a separate chain (an exact copy of Vega with run only by the Ersatzvalidators
that does not contain any trading), which generates the applicable performance
numbers.

#Payment
Ersatzvalidators are paied through the same formulars as normal validators.

#Multisig
At this point, Ersatzvalidators are not part of the Multisig.

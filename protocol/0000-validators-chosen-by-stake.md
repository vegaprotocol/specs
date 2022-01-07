# Validators chosen by stake

New network parameter `network.numberOfValidators`. 

At a high level a participant that wishes to become a validator will:
1) start a Vega node as non-validating node + associated infra 
1) submit a transaction, see below for details, with their keys, saying they want to validate.
1) self-stake to their validator Vega key at least `reward.staking.delegation.minimumValidatorStake`. 
1) wait for others to delegate to them. 

At the end of each epoch Vega will choose the validators with the `validator_score`, see [rewards spec](0061-simple-POS-rewards-SweetWater.md) up to `network.numberOfValidators`. Note that this number combines own + delegated stake together with `performance_score` which measures basic node performance. A completely dead node will have `performance_score = 0` and will thus get automaticaly excluded, regardless of their stake.

These will be the validating nodes for the next epoch. Note that to be eligible certain criteria need to be met: 
1) Own stake >= `reward.staking.delegation.minimumValidatorStake`. 
1) Network has verified key ownership (see below).

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

## Multisig weight updates WIP

This section might make more sense in 0061-simple-POS-rewards-SweetWater.md - TBD.

Once (if) the ethereum multisig contract supports validator weights the vega node will watch for Ethereum events announcing the weight changing. Thus for each validator that is on the multisig contract it will know the validator score (weight) the ethereum multisig is using. 

We will have `number_multisig_signers` represented on the multisig (currently `13`) but this could change. 

In the reward calculation for the top `number_multisig_signers` by `validator_score` (as seen on VEGA) use `min(validator_score, ethereum_multisig_val_score)` when calculating the final reward with `0` for those who are in the top `number_multisig_signers` by score but *not* on the multisig contract. 

Thus a validator who is not there but should be has incentive to pay gas to update the multisig. Moreover a validator who's score has gone up substantially will want to do so as well. 

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

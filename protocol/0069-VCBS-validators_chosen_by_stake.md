# Validators chosen by stake
At a high level a participant that wishes to become a validator will:
1) start a Vega node as non-validating node + associated infra 
1) submit a transaction, see below for details, with their keys, saying they want to validate.
1) self-stake to their validator Vega key at least `reward.staking.delegation.minimumValidatorStake`. 
1) wait for others to delegate to them. 

Note that to be eligible as a potential validator certain criteria need to be met: 
1) Own stake >= `reward.staking.delegation.minimumValidatorStake`. 
1) Network has verified key ownership (see below).


At the end of each epoch Vega will calculate the unnormalised `validator_score`, see [rewards spec](./0061-REWP-simple_pos_rewards_sweetwater.md). 
For validators currently in the Vega validator set it will scale the `validator_score` by `(1+network.validators.incumbentBonus)`. 
Note that this number combines own + delegated stake together with `performance_score` which measures basic node performance together whether the multisig contract carries the correct information [multisig](./0030-ETHM-multisig_control_spec.md); more on this later.

Vega will sort all current Tendermint validators as `[v_1, ..., v_n]` with `v_1` with the highest and `v_n` with the lowest score. 
If for any `l,m=1,...,n` we have  `v_l == v_m` then we place higher the one who's been validator for longer (so this is a mechanism for resolving ties).
Vega will sort all those who submitted a transaction wishing to be validators using `validator_score` as `[w_1, ..., w_k]`. 
These may be ersatz validators (ie getting rewards) or others who just submitted the transaction to join.
If `empty_slots := network.validators.tendermint.number - n > 0` (we have empty Tendermint validator slots) then the top `empty_slots` from `[w_1, ..., w_k]` are promoted to Tendermint validators. 
If `w_1>v_n` (i.e. the highest scored potential validator has more than the lowest score incumbent validator) then in the new epoch `w_1` becomes a Tendermint validator, and the lowest scoring incumbent becomes an ersatz validator. 
If for any `l,m=1,...,k` we have `w_l == w_m` then we resolve this by giving priority to the one who submitted the transaction to become validator earlier (so this is a mechanism for resolving ties).  
Note that we only do this check once per epoch so at most one validator can be changed per epoch in the case `empty_slots == 0`.
A completely dead node that's proposing to become a validator will have `performance_score = 0` and will thus get automatically excluded, regardless of their stake.

The same way, if there are free slots for ersatz validators and nodes that have submitted the transaction to join and satisfy all joining conditions, they are added as ersatz validators in the next round.
If a node that submitted the transaction to join and satisfies all other conditions and there and has a higher score than the lowest scoring ersatz validator (scaled up by the incumbent factor), then (assuming it did not just become a Tendermint validator), it becomes an ersatz validator and the lowest scoring ersatz validator is kicked out. The 'transaction to join' of a validator kicked out this way remains active until the delegated stake drops below the required minimum. As the nodes have not have the opportunity to get a performance record, their performance valued as the average of the performance scores of all ersatz validators.

As both these checks are done between epochs, it is possible for a validator to be demoted first from Tendermint validator to ersatz validator, and then from ersatz validator to nothing.

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
```javascript
{
        "id": "126751c5830b50d39eb85412fb2964f46338cce6946ff455b73f1b1be3f5e8cc",
        "vega_pub_key": "a6e6f7daf8610f9242ab6ab46b394f6fb79cf9533d48051ca7a2f142b8b700a8",
        "ethereum_address": "0x14174f3c9443EdC12685578FE4d165be5f57fBd3",
        "tm_pub_key": "0ShTSZ9Ss8AFHuDz1nIGMrGucjXhFdJyUTT7Eqibjq8=",
        "info_url": "https://www.greenfield.one",
        "country": "Germany",
        "name": "Greenfield One",
        "avatar_url": "https://www.greenfield.one/avatar.png"
}
```
## Removing non-performing candidate validators

- Any party with fewer than `reward.staking.delegation.minimumValidatorStake` at the start of an epoch is removed. (the aim is to remove parties who don't delegate to self, however we achieve it is not too important)
- Any party with performance score == `0` at the end of an epoch is removed. 



## Running a candidate non-validator node
Start [node as a validator node](https://github.com/vegaprotocol/networks/blob/master/README.md).

From now we assume that the transaction has been submitted and the node started. 

## Minimum performance criteria

Basic vega chain liveness criteria is covered in their [performance score](./0064-VALP-validator_performance_based_rewards.md). 

## Verifying Ethereum (and later other chain) integration
In order to be considered for promotion from ersatz validator to Tendermint validator, an ersatz validator must prove itself to be reliable. This is measured by ensuring their
reliability in forwarding [Ethereum events](./0036-BRIE-event_queue.md). A new network parameter, `network.validators.minimumEthereumEventsForNewValidator`, is used to 
set the acceptable minimum count of times that an ersatz validator has either:

1) They will be the first node to forward a subsequently accepted Ethereum event at least `network.validators.minimumEthereumEventsForNewValidator` times, or
1) They are the first one to vote for any ethereum event at least `network.validators.minimumEthereumEventsForNewValidator` times. 

## Multisig updates (and multisig weight updates if those are used)

Vega will know initial multisig signer list (and weights) and watch for `signer added` and `signer removed` events to track which ethereum keys are present on multisig.
Once (if) the ethereum multisig contract supports validator weights the vega node will watch for Ethereum events announcing the weight changing. 
Thus for each validator that is on the multisig contract it will know the validator score (weight) the ethereum multisig is using. 

We will have `network.validators.multisig.numberOfSigners` represented on the multisig (currently `13`) but this could change. 

In the reward calculation for the top `network.validators.multisig.numberOfSigners` by `validator_score` (as seen on VEGA) use `min(validator_score, ethereum_multisig_weight)` when calculating the final reward with `0` for those who are in the top `network.validators.multisig.numberOfSigners` by score but *not* on the multisig contract. 

Thus a validator who is not there but should be has incentive to pay gas to update the multisig. Moreover a validator who's score has gone up substantially will want to do so as well. 

As a consequence, if a potential validator joined the Vega chain validators but has *not* updated the Multisig members (and/or weights) then at the end of the epoch their score will be `0`. 
They will not get any rewards and at the start of the next epoch they will be removed from the validator set. 

Note that this could become obsolete if a future version of the protocol implements threshold signatures or another method that allows all validators to approve Ethereum actions. 


## Ersatz validators
In addition to the normal validators, there is an additional set of Ersatz validators as defined by
the corresponding network parameter. These are validators that do not contribute to the chain, but are on standby to jump in if a normal validator drops off. The network will reward:
```
n' := ceil(network.validators.multipleOfTendermintValidators x network.validators.tendermint.number)
```

ersatz validators. 
The value range for this decimal is `0.0` to `infinity`. 
Reasonable values may be e.g. `0.5`, `1.0` or `2.0`.

As the other validators, Ersatz validators are defined through own + delegated stake, being the validators
with the scores below the Tendermint ones; is `NumberOfTendermintValidators` is `n` and NumberOfErsatzValidators is `n'`, 
then these are the validators with scores `n+1` to `n+n'`.


### Performance of Ersatz validators
Ersatz validators are required to run a non-validator Vega node with all the related infrastructure (Ethereum forwarder, data node etc.) at all times, see [the section on performance for non-validator nodes in 0064-VALP](./0064-VALP-validator_performance_based_rewards.md).

### Rewards for Ersatz validators
In terms of rewards, Ersatz validators are treated in line with Tendermint validators, see details in [validator rewards spec](./0064-VALP-validator_performance_based_rewards.md) and [performance measurement](./0064-VALP-validator_performance_based_rewards.md).
However `network.validators.ersatz.rewardFactor` in `[0,1]` is taken into account to scale their rewards.

### Multisig for Ersatz validators
At this point, Ersatz validators are not part of the Multisig.


## Restarts from LNL checkpoint:

See [limited network life spec](../non-protocol-specs/0005-limited-network-life.md).
1. At each checkpoint we include node IDs of validators and their scores (meaning all the ones participating in consensus and those who submitted a transaction to become a validator and thus are eligible to be a validator or ersatz validator).
1. When initiating the restart all the nodes participating have the same Tendermint weight in genesis (or whatever they set / agree). This is used until the LNL file has finished processing. 
1. When loading LNL file we have to run the same algorithm that selects the "correct" validators; after this is done Tendermint weights are updated.
1. If the validators arising from LNL weight updates are missing from the chain because they haven't started nodes then the chain will stop. The restart needs better coordination so the relevant nodes are present. 

# Network Parameters

| Property                                                  | Type             | Example value | Description |
|-----------------------------------------------------------|------------------|:-------------:|-------------|
|`network.validators.tendermint.number`                     | String (integer) |       13      | The optimal number of validators that should be in the Tendermint validator set    |
|`network.validators.incumbentBonus`                        | String (float)   |      0.1      | When comparing the stake of existing validators to ersatz validators, this is the bonus that existing validators earn   |
|`network.validators.miniumEthereumEventsForNewValidator`   | String (integer) |      100      | Ersatz validators must have reported or confirmed this many Ethereum events to be considered for promotion  |
|`network.validators.multisig.numberOfSigners`              | String (integer) |       9       | Currently set to the number of validators on the network. In future will be used to scale multisig Validator participation.  |
|`network.validators.ersatz.rewardFactor`                   | String (float)   |      0.2      | Scales down [the rewards](./0069-VCBS-validators_chosen_by_stake.md#ersatz-validators) of ersatz validators relative to actual validators  |
|`network.validators.ersatz.multipleOfTendermintValidators` | String (integer) |       2       | Used to [calculate the number](./0069-VCBS-validators_chosen_by_stake.md#ersatz-validators) of ersatz Validators that will earn rewards |

# Acceptance criteria

## Joining / leaving VEGA chain (<a name="0069-VCBS-001" href="#0069-VCBS-001">0069-VCBS-001</a>)
1. A running non-validator node can submit a transaction to become a validator. 
2. Their perfomance score will be calculated. See [performance score](./0064-VALP-validator_performance_based_rewards.md).
3. If they meet the Ethereum verification criteria and have enough stake they will become part of the validator set at the start of next epoch. See about [verifying ethereum integration](#verifying-ethereum-and-later-other-chain-integration).
4. Hence after the end of the current epoch the node that got "pushed out" will no longer be a validator node for Tendermint. 

## Multisig update 
1. Vega network receives the ethereum events updating the weights and stores them (`key`,`value`). (<a name="0069-VCBS-002" href="#0069-VCBS-002">0069-VCBS-002</a>)
2. For validators up to `network.validators.multisig.numberOfSigners` the `validator_score` is capped by the value on `Ethereum`, if available and it's `0` for those who should have value on Ethereum but don't (they are one of the top `network.validators.multisig.numberOfSigners` by `validator_score` on VEGA). (<a name="0069-VCBS-003" href="#0069-VCBS-003">0069-VCBS-003</a>)
3. It is possible to submit a transaction to update the weights. (<a name="0069-VCBS-004" href="#0069-VCBS-004">0069-VCBS-004</a>)
 


# Validators chosen by stake

## Summary

At a high level a participant that wishes to become a validator will:

1. start a Vega node as validating node + associated infra
1. submit a transaction, see below for details, with their keys, saying they want to validate.
1. self-stake to their validator Vega key at least `reward.staking.delegation.minimumValidatorStake`.
1. wait for others to delegate to them.

Note that to be eligible as a potential validator certain criteria need to be met:

1. Own stake >= `reward.staking.delegation.minimumValidatorStake`.
1. Network has verified key ownership (see below).

At the end of each epoch Vega will calculate the unnormalised `validator_score`, see [rewards spec](./0061-REWP-simple_pos_rewards_sweetwater.md).
For validators currently in the Vega validator set it will scale the `validator_score` by `(1+network.validators.incumbentBonus)`.
Note that this number combines own + delegated stake together with `performance_score` which measures basic node performance.


Vega will sort all current consensus forming (also called Tendermint) validators as `[v_1, ..., v_n]` with `v_1` with the highest and `v_n` with the lowest score. 
If for any `l,m=1,...,n` we have  `v_l == v_m` then we place higher the one who's been validator for longer (so this is a mechanism for resolving ties).
Vega will sort all those who submitted a transaction wishing to be validators using `validator_score` as `[w_1, ..., w_k]`.
These may be ersatz validators (ie getting rewards) or others who just submitted the transaction to join.

If `empty_slots := network.validators.tendermint.number - n > 0` (we have empty consensus (Tendermint) validator slots) then the top `empty_slots` from `[w_1, ..., w_k]` are promoted to consensus (Tendermint) validators. 
If `w_1>v_n` (i.e. the highest scored potential validator has more than the lowest score incumbent validator) then in the new epoch `w_1` becomes a consensus forming (Tendermint) validator, and the lowest scoring incumbent becomes an ersatz validator. 
The exception to that rule is if one or more incumbent validators drop below the required ownstake (ownstake < reward.staking.delegation.minimumValidatorStake), either through changing their self-delegation or due to a change of the network parameter. 
In that case, the validators that have less than the required own stake get a ranking score is 0. If you have two validators with equal ranking score, the one that's been a consensus validator longer will be first in the sorting order (so will be swapped last).

If for any `l,m=1,...,k` we have `w_l == w_m` then we resolve this by giving priority to the one who submitted the transaction to become validator earlier (so this is a mechanism for resolving ties).
Note that we only do this check once per epoch so at most one validator can be changed per epoch in the case `empty_slots == 0`.

The same way, if there are free slots for ersatz validators and nodes that have submitted the transaction to join and satisfy all joining conditions, they are added as ersatz validators in the next round.

If a node that submitted the transaction to join and satisfies all other conditions and has a higher score than the lowest scoring ersatz validator (scaled up by the incumbent factor), then (assuming it did not just become a Tendermint validator), it becomes an ersatz validator and the lowest scoring ersatz validator is demoted to pending validator. The 'transaction to join' of a validator demoted this way remains active until the delegated stake drops below the required minimum

As both these checks are done between epochs, it is possible for a validator to be demoted first from a consensus forming (Tendermint) validator to an ersatz validator, and then from an ersatz validator to a pending validator.

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

## Removing non-performing pending validators

Nodes that submitted the transaction to become "pending" nodes (with the aim of joining the ersatz or even the validator set) will be removed from the pending set if either:

- They have fewer self-owned governance tokens than `reward.staking.delegation.minimumValidatorStake` at the start of an epoch
- The node has performance performance score == `0` at the end of an epoch.

## Running a pending validator node

Start [node as a validator node](https://github.com/vegaprotocol/networks/blob/master/README.md).

From now we assume that the transaction has been submitted and the node started.

## Minimum performance criteria

Basic vega chain liveness criteria is covered in their [performance score](./0064-VALP-validator_performance_based_rewards.md).

## Verifying Ethereum (and later other chain) integration

In order to be considered for promotion from ersatz validator to Tendermint validator, an ersatz validator must prove itself to be reliable. This is measured by ensuring their reliability in forwarding [Ethereum events](./0036-BRIE-event_queue.md).
A network parameter, `network.validators.minimumEthereumEventsForNewValidator`, is used to set the acceptable minimum count of times that an ersatz validator was the first to forward a subsequently accepted Ethereum event at least `network.validators.minimumEthereumEventsForNewValidator` times.

## Multisig updates (and multisig weight updates if those are used)

Vega will know the initial multisig signer list (and weights) and watch for `signer added` and `signer removed` events to track which ethereum keys are present on multisig.

Once (if) the ethereum multisig contract supports validator weights the vega node will watch for Ethereum events announcing the weight changing.
Thus for each validator that is on the multisig contract it will know the validator score (weight) the ethereum multisig is using.


We will have `network.validators.multisig.numberOfSigners` represented on the multisig (currently `13`) but this could change. 
Note that `network.validators.multisig.numberOfSigners` must always be less than or equal to `network.validators.tendermint.number`.

In the reward calculation for the top `network.validators.multisig.numberOfSigners` by `validator_score` (as seen on VEGA) use `min(validator_score, ethereum_multisig_weight)` when calculating the final reward with `0` for those who are in the top `network.validators.multisig.numberOfSigners` by score but *not* on the multisig contract.

Thus a validator who is not there but should be has incentive to pay gas to update the multisig. Moreover a validator who's score has gone up substantially will want to do so as well.

As a consequence, if a potential validator joined the Vega chain validators but has *not* updated the Multisig members (and/or weights) then at the end of the epoch their score will be `0`. They will not get any rewards.

In the case where a node is removed due reduced delegation, or due to not meeting self-delegation criteria, or due to lack of performance, or due to a reduction in the value of `network.validators.tendermint.number`, the onus is on all of the remaining validators to remove the demoted member from the Multisig contract. They are incentivised to do so by all receiving a `validator_score` of `0` *in the reward calculation* until the excess member is removed.

Note that this could become obsolete if a future version of the protocol implements threshold signatures or another method that allows all validators to approve Ethereum actions.

## Ersatz validators

In addition to the normal validators, there is an additional set of Ersatz validators as defined by the corresponding network parameter. These are validators that do not contribute to the chain, but are on standby to jump in if a normal validator drops off. The network will have
```
n' := ceil(network.validators.multipleOfTendermintValidators x network.validators.tendermint.number)
```
ersatz validators. 
The value range for the decimal `network.validators.multipleOfTendermintValidators` is `0.0` to `infinity`. 
Reasonable values may be e.g. `0.5`, `1.0` or `2.0`.

Like the other validators, Ersatz validators are defined through own + delegated stake, being the validators with the scores below the Tendermint ones; is `NumberOfTendermintValidators` is `n` and `NumberOfErsatzValidators` is `n'`,
then these are the validators with scores `n+1` to `n+n'`.

### Performance of Ersatz validators

Ersatz validators are required to run a validator Vega node with all the related infrastructure (Ethereum forwarder, data node etc.) at all times, see [the section on performance for validator nodes in 0064-VALP](./0064-VALP-validator_performance_based_rewards.md).

Their performance is also defined by the number of heartbeats they sent out of the last 10 expected heartbeats.

### Rewards for Ersatz validators

In terms of rewards, Ersatz validators are treated in line with Tendermint validators, see details in [validator rewards spec](./0064-VALP-validator_performance_based_rewards.md) and [performance measurement](./0064-VALP-validator_performance_based_rewards.md).
However `network.validators.ersatz.rewardFactor` in `[0,1]` is taken into account to scale their rewards. Also, the same scoring
function is applied as for the normal validators, so anti-whaling rules apply for Ersatz validators as well.
An Ersatz validator being affected by the whaling rule (i.e., getting sufficient stake to have their reward lowered by the anti-whaling rule)
is a out-of-the ordinary event and should be logged.

### Multisig for Ersatz validators

At this point, Ersatz validators are not part of the Multisig.

## Restarts from LNL checkpoint

See [limited network life spec](./0073-LIMN-limited_network_life.md).

1. At each checkpoint we include node IDs of validators and their scores (meaning all the ones participating in consensus and those who submitted a transaction to become a validator and thus are eligible to be a validator or ersatz validator).
1. When initiating the restart all the nodes participating have the same Tendermint weight in genesis (or whatever they set / agree). This is used until the LNL file has finished processing.
1. When loading LNL file we have to run the same algorithm that selects the "correct" validators; after this is done Tendermint weights are updated.
1. If the validators arising from LNL weight updates are missing from the chain because they haven't started nodes then the chain will stop. The restart needs better coordination so the relevant nodes are present.

## Network Parameters

| Property                                                  | Type             | Example value | Description |
|-----------------------------------------------------------|------------------|:-------------:|-------------|
|`network.validators.tendermint.number`                     | String (integer) |       13      | The optimal number of validators that should be in the Tendermint validator set    |
|`network.validators.incumbentBonus`                        | String (float)   |      0.1      | When comparing the stake of existing validators to ersatz validators, this is the bonus that existing validators earn   |
|`network.validators.miniumEthereumEventsForNewValidator`   | String (integer) |      100      | Ersatz validators must have reported or confirmed this many Ethereum events to be considered for promotion  |
|`network.validators.multisig.numberOfSigners`              | String (integer) |       9       | Currently set to the number of validators on the network. In future will be used to scale multisig Validator participation.  |
|`network.validators.ersatz.rewardFactor`                   | String (float)   |      0.2      | Scales down [the rewards](./0069-VCBS-validators_chosen_by_stake.md#ersatz-validators) of ersatz validators relative to actual validators  |
|`network.validators.ersatz.multipleOfTendermintValidators` | String (integer) |       2       | Used to [calculate the number](./0069-VCBS-validators_chosen_by_stake.md#ersatz-validators) of ersatz Validators that will earn rewards |

## Acceptance criteria

### Joining / leaving VEGA chain (<a name="0069-VCBS-001" href="#0069-VCBS-001">0069-VCBS-001</a>)

1. A running Vega node which isn't a "pending" or "ersatz" or "validator" node already can submit a transaction to become a validator.
2. Their performance score will be calculated. See [performance score](./0064-VALP-validator_performance_based_rewards.md).
3. If they meet the Ethereum verification criteria and have enough stake they will become part of the validator set at the start of next epoch. See about [verifying ethereum integration](#verifying-ethereum-and-later-other-chain-integration).
4. Hence after the end of the current epoch the node that got "pushed out" will no longer be a validator node for Tendermint.

### Reward scores for validators joining and leaving

#### Stake score

**Setup a network for each test** with 5 Tendermint validators and 2 ersatz validators. Verify the value of the min.validators network parameter is 5. Delegate 1000 tokens to each Tendermint validator and 500 to each ersatz validator (where minimum is defined as 500). Transfer 1000 tokens to the reward account. The test assumes that the validators are already in their state (i.e. 5 are Tendermint, 2 are ersatz).

1. Base case for Tendermint validators (<a name="0069-VCBS-005" href="#0069-VCBS-005">0069-VCBS-005</a>):
    - Verify that the `stakeScore` for each of the Tendermint validators is 0.2
1. Base case for ersatz validators (<a name="0069-VCBS-006" href="#0069-VCBS-006">0069-VCBS-006</a>):
    - Verify that the `stakeScore` for each of the ersatz validator is 0.5
1. No antiwhaling for ersatz `stakeScore` (<a name="0069-VCBS-007" href="#0069-VCBS-007">0069-VCBS-007</a>):
    - Delegate to one of the ersatz validators 4000 more tokens.
    - Run for an epoch with the new delegation (i.e. one ersatz with 500 one with 4500) and transfer 1000 tokens to the reward account.
    - Verify that at the end of the epoch the stake score of the validator with 4500 tokens is 0.9 and the one with 500 tokens is 0.1
1. Antiwhaling for Tendermint validators (<a name="0069-VCBS-008" href="#0069-VCBS-008">0069-VCBS-008</a>):
    - **Additional setup:** in addition to the 1000 delegated for each node, delegate 500 more to node 1.
    - **Additional setup:** ensure that the network parameter for `reward.staking.delegation.competitionLevel` is set to 1
    - Once it becomes active let it run for a full epoch during which transfer 1000 tokens to the reward account.
    - Verify that at the end of the epoch node 1 should have a stake score of 0.2 where all other nodes get stake score of 0.1818181818
1. Full antiwhaling for Tendermint validators (<a name="0069-VCBS-009" href="#0069-VCBS-009">0069-VCBS-009</a>):
    - **Additional setup:** ensure that the network parameter for `reward.staking.delegation.optimalStakeMultiplier` is set to 3
    - **Additional setup:** ensure that the network parameter for `reward.staking.delegation.competitionLevel` is set to 1
    - **Additional setup:** in addition to the 1000 tokens delegated to each node, delegate 10000 tokens to node1 to get a total delegation of 11000 to it.
    - Once it becomes active let it run for a full epoch during which transfer 1000 tokens to the reward account.
    - Verify that at the end of the epoch all nodes should have a stake score of 0.066666666

#### Multisig score

1. Verify that for all ersatz validators their multisig score is 1 (<a name="0069-VCBS-010" href="#0069-VCBS-010">0069-VCBS-010</a>)
1. Tendermint validators excess signature (<a name="0069-VCBS-011" href="#0069-VCBS-011">0069-VCBS-011</a>):
    - Setup a network with 5 Tendermint validators but with only 4 validators that have sufficient self-delegation. Call the one without enough self-delegation Bob.
    - Announce a new node (Alice) and self-delegate to them, allow some time to replace the validator with no self-delegation (Bob) as a Tendermint validator by Alice. Note: At this point the signature of Bob IS still on the multisig contract.
    - Transfer 1000 tokens to the VEGA reward account.
    - Verify that at the end of the epoch all of the Tendermint validators should have a multisig score = 0 since Bob is still on the contract.
1. Tendermint validators missing signature test 1 (<a name="0069-VCBS-012" href="#0069-VCBS-012">0069-VCBS-012</a>):
    - Setup a network with 4 Tendermint validators with self-delegation and number of Tendermint validators network parameter set to 5.
    - **Additional setup:** ensure that the network parameter `network.validators.multisig.numberOfSigners` is set to **5**.
    - Announce a new node and self-delegate to it 1000 tokens.
    - Allow some time for the performance score to be greater than 0. Note: When this happens the validator will be promoted to Tendermint validator at the beginning of the following epoch.
    - When the validator has been promoted to a Tendermint validator, transfer 1000 tokens to the reward account.
    - Verify that the joining validator has a multisig score of 0 and therefore would not get a reward.
1. Tendermint validators missing signature test 2 (<a name="0069-VCBS-013" href="#0069-VCBS-013">0069-VCBS-013</a>):
    - Setup a network with 4 Tendermint validators with self-delegation and number of Tendermint validators network parameter set to 5.
    - **Additional setup:** ensure that the network parameter `network.validators.multisig.numberOfSigners` is set to 4.
    - Announce a new node and self-delegate to it 10000 tokens.
    - Allow some time for the performance score to become 1. Note: When this happens the validator will be promoted to Tendermint validator at the beginning of the following epoch.
    - When the validator has been promoted to a Tendermint validator, transfer 1000 tokens to the reward account.
    - Assert that the new validator has a score (stake score x performance score) in the top 4 - this can be verified in data node with: `rewardScore.stakeScore` x `rewardScore.performanceScore`.
    - Verify that the joining validator would have a multisig score of 0 and therefore would not get a reward.
1. Tendermint validators missing signature test 3 (<a name="0069-VCBS-050" href="#0069-VCBS-050">0069-VCBS-050</a>):
    - Setup a network with 4 Tendermint validators with self-delegation and number of Tendermint validators network parameter set to 5.
    - **Additional setup:** ensure that the network parameter `network.validators.multisig.numberOfSigners`is set to 4.
    - Delegate 10000 to the existing validators (can be self or party delegation)
    - Announce a new node and self-delegate to it 1000 tokens.
    - Do not wait for the performance of the node to improve, we actually want for this test the performance score to be as low as possible.
    - When the validator has the delegation set up it will be promoted to tendermint status.
    - When the validator has been promoted to a Tendermint validator, transfer 1000 tokens to the reward account.
    - Assert that the new validator has a score (stake score x performance score) **NOT** in the top 4 - this can be verified in data node with: `rewardScore.stakeScore` x `rewardScore.performanceScore`.
    - Verify that the joining validator would have a multisig score of 1 and therefore gets a reward.
1. One of the top validators is not registered with the multisig contract (<a name="0069-VCBS-051" href="#0069-VCBS-051">0069-VCBS-051</a>):
    - Run a Vega network where a validator joins and gets a lot delegated in order for it to become one of the top `network.validators.multisig.numberOfSigners`
    - Ensure its ethereum key is **NOT** put on the multisig contract.
    - Verify the validator has 0 for their multisig score and receives no staking reward.

#### Validator Score

1. Verify that the validator score is always equal to the `stakeScore` x `perfScore` x `multisigScore` when the validator is a Tendermint validator (<a name="0069-VCBS-014" href="#0069-VCBS-014">0069-VCBS-014</a>)
2. Verify that the validator score is always equal to the `stakeScore` x `perfScore` when the validator is an ersatz validator (<a name="0069-VCBS-015" href="#0069-VCBS-015">0069-VCBS-015</a>)

#### Normalised Score

1. The sum of normalised scores must always equal 1 (<a name="0069-VCBS-016" href="#0069-VCBS-016">0069-VCBS-016</a>)
2. The normalised score for validator i must equal `validatorScore_{i}` / `total_validator_score`. Note: the total validator score is calculated over the relevant set separately (i.e. Tendermint and ersatz) (<a name="0069-VCBS-017" href="#0069-VCBS-017">0069-VCBS-017</a>)

### Rewards split between tendermint and ersatz validators

1. Base scenario (<a name="0069-VCBS-018" href="#0069-VCBS-018">0069-VCBS-018</a>):
    - There are no ersatz validators in the network.
    - Verify that, regardless of `ersatzRewardFactor` value, all rewards are being paid out to the validators as expected given the reward scores.
1. Ersatz validators where ersatz reward factor equals 0 (<a name="0069-VCBS-019" href="#0069-VCBS-019">0069-VCBS-019</a>):
    - Ensure that the `ersatzRewardFactor` is set to 0
    - Setup an ersatz validator with delegation greater than the minimum. The delegation can be equal to the delegation of the other Tendermint validators
    - Verify the ersatz validators and their delegators get no rewards.
1. Ersatz validators where reward factor equals 1 (<a name="0069-VCBS-020" href="#0069-VCBS-020">0069-VCBS-020</a>):
    - Setup an ersatz validator with self and party delegation making them eligible for reward for a whole epoch. For example, such that the total delegation to each node is 1000 Vega. (3 Tendermint validators, 1 ersatz validator all having a delegation of 1000 Vega).
    - Make sure there is balance of 1000 Vega in the reward pool account for the epoch.
    - Verify the reward pool is distributed equally between the validators.
1. Ersatz validators where reward factor equals 0.5 (<a name="0069-VCBS-021" href="#0069-VCBS-021">0069-VCBS-021</a>):
    - Setup an ersatz validator with self and party delegation making them eligible for reward for a whole epoch. For example, such that the total delegation to each node is 1000 Vega. (3 tendermint validators, 1 ersatz validator all having a delegation of 1000 Vega).
    - Make sure there is balance of 3500 Vega in the reward account for the epoch.
    - Verify that 3000 is distributed between the Tendermint validators and 500 is rewarded to the ersatz validator.
1. Multiple ersatz validators, reward factor equals 0.5 (<a name="0069-VCBS-022" href="#0069-VCBS-022">0069-VCBS-022</a>):
    - Setup a network with 3 ersatz validators, 3 Tendermint validators with arbitrary delegation, but ensuring the total delegation for each validator is greater than the minimum self-delegation.
    - With `total_delegations_from_all_validators = (0.5 * total_delegation_from_ersatz_validators) + total_delegation_from_tendermint_validators`
    - Verify the total reward given to Tendermint validators is equal to the `total_delegation_from_tendermint_validators * reward_balance` / `total_delegation_from_all_validators`.
    - Verify the total reward given to ersatz validators is equal to the `total_delegation_from_ersatz_validators * 0.5 * reward_balance / total_delegation_from_all_validators`.
1. Pending validators get nothing (<a name="0069-VCBS-023" href="#0069-VCBS-023">0069-VCBS-023</a>):
    - Setup a network with 5 tendermint validators, set number of ersatz validators (through network parameter) to 0.
    - Delegate to each node 1000 tokens (including self-delegation).
    - Announce 2 new nodes, verify that they are in pending state, delegate to them 1000 tokens each.
    - Run the network for a full epoch with the delegation, during which transfer 1000 tokens to the reward account.
    - Verify that, at the end of the epoch, none of the pending validators receive a reward.
1. Pending validators do not get promoted (<a name="0069-VCBS-024" href="#0069-VCBS-024">0069-VCBS-024</a>):
    - Setup a network with 5 tendermint validators, 2 ersatz validators and set number of ersatz validators (through factor) to 2.
    - Delegate to each node 1000 tokens (including self-delegation).
    - Announce 2 new nodes, verify that they are in pending state, delegate to them 1000 tokens each.
    - Run the network for a full epoch with the delegation, during which transfer 1000 tokens to the reward account.
    - Verify that, at the end of the epoch, none of the pending validators are promoted.

### Ranking scores

#### General

1. Verify that at the beginning of epoch an event is emitted for every validator known to Vega with their respective ranking scores. (<a name="0069-VCBS-025" href="#0069-VCBS-025">0069-VCBS-025</a>)
1. Verify the ranking score is available through the epoch/validator/`rankingScore` API in the data-node. (<a name="0069-VCBS-026" href="#0069-VCBS-026">0069-VCBS-026</a>)
1. Verify that the `rankingScore` is always equal to `performanceScore` x `stakeScore` x `incumbentBonus` (for tendermint validators and ersatz validators) Note: `network.validators.incumbentBonus` is a network parameter that is applied as a factor (1 + `incumbentBonus` network parameter) on `performanceScore` x `stakeScore`. (<a name="0069-VCBS-027" href="#0069-VCBS-027">0069-VCBS-027</a>)
1. Verify that if a node has a 0 `rankingScore` for 1e6 blocks (corresponding to around 11.5 days) it gets removed from the network and will have to be re-announced. (<a name="0069-VCBS-028" href="#0069-VCBS-028">0069-VCBS-028</a>)

### Stake scores

1. No stake (<a name="0069-VCBS-029" href="#0069-VCBS-029">0069-VCBS-029</a>):
  * Setup a network with 5 validators with no delegation 
  * Verify that the `stakeScore` for all of validators is 0
2. Equal stake (<a name="0069-VCBS-030" href="#0069-VCBS-030">0069-VCBS-030</a>):
  * Setup a network with 5 validators, delegate to each of validator an equal stake
  * Verify that the `stakeScore` of each of them is 0.2. 
3. Stake change (<a name="0069-VCBS-031" href="#0069-VCBS-031">0069-VCBS-031</a>):
  * Setup a network with 5 validators with 1000 tokens delegated to each. 
  * Verify `stakeScore` at the end of the epoch is 0.2. 
  * Change the stake of each validator by adding 100 * the index of the validator (i=1..5). 
  * Verify that at the end of the epoch the `stakeScore` of each validator equals (1000 + i * 100)/5500
4. Stake change 2 (<a name="0069-VCBS-032" href="#0069-VCBS-032">0069-VCBS-032</a>):
  * Setup a network with 5 validators with 1000 tokens delegated to each
  * Undelegate from one validator 1000 tokens. 
  * Verify that, at the end of the epoch, each of the 4 validators with tokens still delegated has a `stakeScore` of 0.25 and the validator with no tokens delegated has a 0 `stakeScore`. 
5. Node joining (<a name="0069-VCBS-033" href="#0069-VCBS-033">0069-VCBS-033</a>):
  * Setup a network with 4 validators, each with 1000 tokens delegated. 
  * Announce a new node and delegate it 1000 tokens
  * Verify that the `stakeScore` of all nodes is 0.2 at the beginning of the next epoch. Note: for the first 4 validators this is changing from 0.25 in the previous epoch to 0.2 in the next. 


## Promotions/Demotions
1. Announce node (<a name="0069-VCBS-034" href="#0069-VCBS-034">0069-VCBS-034</a>):
  * Verify that a node node, once added successfully to the topology, is shown on data-node API with the status pending
2. Promote a node to become an ersatz validator (<a name="0069-VCBS-035" href="#0069-VCBS-035">0069-VCBS-035</a>):
  * Set up a network with no existing ersatz validators
  * Ensure that the number of ersatz validators allowed in the network is is greater than 0 using the network parameter `network.validators.ersatz.multipleOfTendermintValidators`
  * Announce a new node on the network
  * Verify the new node gets promoted to an ersatz validator Note: ensure there are no available slots for Tendermint validators so the new node doesn’t get promoted directly to become a Tendermint validator.
3. Demote a Tendermint validator due to lack of slots (<a name="0069-VCBS-036" href="#0069-VCBS-036">0069-VCBS-036</a>):
  * Setup a network with 4 Tendermint validators
  * Change the network parameter `network.validators.tendermint.number` to 3 Tendermint validators
  * Verify that the Tendermint validator with the lowest score is demoted to an ersatz validator at the beginning of the next epoch

3.b Demote a number of consensus forming (Tendermint) validators due to lack of slots (<a name="0069-VCBS-062" href="#0069-VCBS-062">0069-VCBS-062</a>):
  * Run with `network.validators.ersatz.multipleOfTendermintValidators = 1`
  * Setup a network with 6 consensus forming (Tendermint) validators
  * Ensure that the multisig is updated to those 6 validators.
  * Ensure that the threshold on the multisig is set to `666`.
  * Change the network parameter `network.validators.tendermint.number` to 3 Tendermint validators.
  * Verify that exactly one consensus forming validator with the lowest score is demoted to an ersatz validator at the beginning of the next epoch and we are running with 5 consensus (Tendermint) validators. 
  * Ensure that the multisig is updated to those 5 validators.
  * Verify that exactly one consensus forming validator with the lowest score is demoted to an ersatz validator at the beginning of the following epoch and we are running with 4 consensus (Tendermint) validators.
  * Ensure that the multisig is updated to those 4 validators.
  * Finally verify that exactly one consensus forming validator with the lowest score is demoted to an ersatz validator at the beginning of the following epoch and we are running with 3 consensus (Tendermint) validators.

3.c Try to demote a number of consensus forming (Tendermint) validators due to lack of slots (<a name="0069-VCBS-063" href="#0069-VCBS-063">0069-VCBS-063</a>):
  * Run with `network.validators.ersatz.multipleOfTendermintValidators = 1`
  * Setup a network with 6 consensus forming (Tendermint) validators
  * Ensure that the multisig is updated to those 6 validators.
  * Ensure that the threshold on the multisig is set to `900`.   
  * Change the network parameter `network.validators.tendermint.number` to 3 Tendermint validators.
  * Verify that no consensus forming validator is removed at the start of the next epoch and we are running with 6 consensus (Tendermint) validators. 

3.d Demote a number of consensus forming (Tendermint) validators due to lack of slots (<a name="0069-VCBS-064" href="#0069-VCBS-064">0069-VCBS-064</a>):
  * Setup a network with 3 consensus forming (Tendermint) validators
  * Ensure that the multisig is updated to those 3 validators.
  * Ensure that the threshold on the multisig is set to `666`. 
  * Change the network parameter `network.validators.tendermint.number` to 2 Tendermint validators.
  * Verify that no consensus forming validator is removed at the start of the next epoch and we are running with 3 consensus (Tendermint) validators.   
  
3.e Demote a number of consensus forming (Tendermint) validators due to lack of slots (<a name="0069-VCBS-065" href="#0069-VCBS-065">0069-VCBS-065</a>):
  * Run with `network.validators.ersatz.multipleOfTendermintValidators = 1`
  * Setup a network with 6 consensus forming (Tendermint) validators
  * Ensure that the multisig is updated to those 6 validators.
  * Ensure that the threshold on the multisig is set to `666`.
  * Change the network parameter `network.validators.tendermint.number` to 3 Tendermint validators.
  * Verify that exactly one consensus forming validator with the lowest score is demoted to an ersatz validator at the beginning of the next epoch and we are running with 5 consensus (Tendermint) validators. 
  * Ensure that the multisig is updated to those 5 validators.
  * Verify that exactly one consensus forming validator with the lowest score is demoted to an ersatz validator at the beginning of the following epoch and we are running with 4 consensus (Tendermint) validators.
  * Ensure that the multisig is *not* updated to those 4 validators, but we have the 5 validators from previous step.
  * Verify that no consensus forming validator is removed at the start of the next epoch and we are running with 4 consensus (Tendermint) validators. 

4. Demote an ersatz validator due to lack of slots (<a name="0069-VCBS-037" href="#0069-VCBS-037">0069-VCBS-037</a>):
  * Setup a network with 4 tendermint validators, and 2 ersatz validators.
  * Change the ersatz network parameter `network.validators.ersatz.multipleOfTendermintValidators` to 0.25 of the Tendermint validators 
  * Verify that the ersatz validator with the lowest score is demoted to pending at the beginning of the next epoch
5. Promotion a node to become a Tendermint validator (<a name="0069-VCBS-038" href="#0069-VCBS-038">0069-VCBS-038</a>):
  * Setup a network with 5 validators (and 5 slots for tendermint validators).
  * Do not self-delegate to them. 
  * Announce a new node and self-delegate to them. 
  * Verify that at the beginning of the next epoch one of the validators which were Tendermint validators before is chosen at random and is demoted to ersatz validator.
  * Verify the announced validator is promoted to be Tendermint validator with voting power = 10000.
6. Promotion + swap (<a name="0069-VCBS-039" href="#0069-VCBS-039">0069-VCBS-039</a>):
  * Setup a network with 4 validators with self-delegation such that the number of Tendermint nodes (with the `network.validators.tendermint.number` parameter set to 5). 
  * In the following epoch, remove the self-delegation from node 1, and announce 2 nodes.
  * During the epoch self-delegate to the two nodes. 
  * Wait for 3 epochs to allow performance of the new nodes to be greater than 0. 
  * Verify that, once the performance is greater than zero, the two nodes should be promoted to Tendermint validators and their voting power should be equal to their relative stake x their performance score x 10000.
7. Swap last due to performance (<a name="0069-VCBS-040" href="#0069-VCBS-040">0069-VCBS-040</a>):
  * Setup a network with 5 validators with self-delegation. 
  * Announce a new node and self-delegate to it. 
  * Once it gets to a performance score of 0.2, shut down two of the 5 Tendermint validators after 0.1 of the duration of the epoch, e.g. if the epoch is 5 minutes, that means after 30 seconds of the epoch they should be stopped. 
  * Verify that at the beginning of the next epoch, expect the performance score of the two stopped validators is <= 0.1, and one of them chosen at random is demoted to ersatz validator and is replaced by the announced nodes as a Tendermint validator with voting power =~ 0.2 * `stake_of_validator` / `total_stake_network`
8. Number of slots increased (<a name="0069-VCBS-041" href="#0069-VCBS-041">0069-VCBS-041</a>):
  * Setup a network with 5 Tendermint validators, self-delegate to them (set the parameter `network.validators.tendermint.number` to 5, set the `network.validators.ersatz.multipleOfTendermintValidators` parameter to 0 so there are no ersatz validators allowed). 
  * Announce a new node, DO NOT self-delegate to it. 
  * Run for an epoch and assert the validator is shown as pending. 
  * Increase the number of tendermint validators to 6. 
  * Verify that at the beginning of the next epoch the pending validator is still pending as their performance score is 0 (no self-stake). 
  * Self-delegate to the pending validator
  * Verify that at the end of the epoch they are promoted to Tendermint validator.
9. Swap due to better score (<a name="0069-VCBS-042" href="#0069-VCBS-042">0069-VCBS-042</a>):
  * Setup a network with 5 Tendermint validators and self-delegate 1000 tokens to each of them. 
  * Announce a new node at the beginning of the epoch, self-delegate to them a total that is 10000 tokens. 
  * At the beginning of the next epoch the new validator should have ranking score *equal or lower* to all of the Tendermint validators so it doesn’t get promoted. The parameter <incubent_factor> is set sufficiently high to assure this (e.g., 1.1).
  * In the middle of the epoch, shut node 1 down. 
  * Verify that at the beginning of the next epoch the announced node replaced node 1 as a Tendermint validator. 
  * Restart node 1 again from a snapshot
  * Verify that node 1 is in a pending state and it’s ranking score is ~ 0.006666666667.
10. 2 empty spots, only one available to replace (<a name="0069-VCBS-043" href="#0069-VCBS-043">0069-VCBS-043</a>):
  * Setup a network with 5 slots for Tendermint validators and 3 actual Tendermint validators. 
  * Self-delegate to all of them. 
  * Announce 2 new nodes but self-delegate only to one of them. 
  * Verify that, after 1000 blocks and on the following epoch, only the validator to which we self-delegated got promoted and we now have 4 Tendermint validators and 1 pending validator. 

11. Change ownstake requirement (<a name="0069-VCBS-053" href="#0069-VCBS-053">0069-VCBS-053</a>)
  * Network with 5 tendermint validators and 7 ersatzvalidators
  * In the same epoch, change the network parameter `reward.staking.delegation.minimumValidatorStake` in a way that 3 tendermint validators and 3 ersatzvalidators drop below the ownstake requirement, and change the delegation so that 4 (not affected) Ersatzvalidators have a higher score than two (not affected) Validators. Also, give one of the Ersatzvalidators with insufficient ownstake the highest stake (delegated) of all Ersatzvalidators. 

 * At the end of the epoch all validators with insufficient own stake will get a ranking score of 0.
 * No ersatz validator with insufficient stake will get unlisted as ersatzvalidator
 * The 3 tendermint validators would be swapped with the top 3 ersatzvalidators over the following 3 epochs
 * Also verify that the ersatz validator with the insufficient own but the most delegated stake has a ranking score of 0 and doesn't get promoted. 
 * No validator with stake attached to them is ever completely removed 
  
 12. (Alternative until we can build a large enough network for above AC ) (<a name="0069-VCBS-059" href="#0069-VCBS-059">0069-VCBS-059</a>)
 12.a Setup a network with 5 nodes (3 validators, 2 ersatzvalidators). In one epoch,

- one ersatzvalidator gets the highest delegated stake, but insufficient ownstake (delegates: 10000)
- 2 validators drop below ownstake, but have relative high delegated stake (7000)
- 1 validator drops to the lowest delegated stake (1000)
- 1 ersatzvalidator has 6000 stake and sufficient ownstake

Verify that the the first ersatzvalidator is removed (marked as pending in the epoch change and then removed due to continous insufficient ownstake), and one validator with insufficient ownstake is replaced by the other ersatzvalidator.

12.b Setup a network with 5 nodes (3 validators, 2 ersatzvalidators). In one epoch,

- 1 validator drops below ownstake, but has relative high delegated stake (7000)
- 2 validators drop to the lowest delegated stake (1000 and 1500, respectively)
- 2 ersatzvalidators have 6000 stake and sufficient ownstake

Verify that at the epoch change,  the validator with insufficient ownstake is replaced; in 
the next epoch, the second validator with the lowest score is replaced, and the validator that was demoted to ersatzvalidator due to insufficient ownstake is removed (stops being listed as an ersatzvalidator).
Verify that the validator that dropped below ownstake is not demoted and removed at the same epoch change.

12.c Setup a network with 5 nodes (3 validators, 2 ersatzvalidators). In one epoch,

- All validators drop below ownstake
- All erstazvalidators have sufficient ownstake, but lower stake than the validators

Verify that 2 validators are replaced, one in each epoch

12.d Setup a network with 5 nodes (3 validators, 2 ersatzvalidators). In one epoch,

- All validators drop below ownstake
- All erstazvalidators have sufficient ownstake, and higher stake than the validators

Verify that one validator is replaced the following epoch, one in the epoch after

13. Ersatzvalidator reward (<a name="0069-VCBS-061" href="#0069-VCBS-061">0069-VCBS-061</a>)    
    Setup a network with 5 validators with the following distribution of delegation:
10%, 10%, 10%, 10%. 60% of the total delegation of tendermint validators

- Setup 5 ersatz validators each with the minimum delegation at the end of the epoch verify that the stake score of the validator with 60% of the delegation (under reward) is anti-whaled
- Shutdown the validator with 60% of the delegation
- Run for an epoch with it down
- At the end of the epoch expect the validator with 60% of the stake to be swapped as a tendermint validator for one of the ersatz validators.
- Restart the validator, run until the end of the epoch

Verify that this validator is paid reward as ersatz validator and that their stake score under reward is anti-whaled

14.  Number of slots decreased (<a name="0069-VCBS-052" href="#0069-VCBS-052">0069-VCBS-052</a>):
  * Setup a network with 7 Tendermint validators, self-delegate to them (set the parameter `network.validators.tendermint.number` to 5, set the `network.validators.ersatz.multipleOfTendermintValidators` parameter to 0 so there are no ersatz validators allowed).
  * Decrease the number of tendermint validators to 5.
  * Verify that in each of the following two epochs, the validator with the lowest score is demoted to Ersatzvalidator and an Ersatzvalidator is demoted to pending


15. Number of Ersatzvalidators increased (<a name="0069-VCBS-058" href="#0069-VCBS-058">0069-VCBS-058</a>):
  * Setup a network with 4 Tendermint validators, 2 ErsatzValidators (network.validators.ersatz.multipleOfTendermintValidators = 0.5), and 2 pending validators
  * Change the parameter network.validators.ersatz.multipleOfTendermintValidators to 0.9
  * Verify that in the following epoch, the ErsatzValidator with the highest score is promoted to Validator

16. Number of Ersatzvalidators decreased (<a name="0069-VCBS-054" href="#0069-VCBS-054">0069-VCBS-054</a>):
  * Setup a network with 5 Tendermint validators, 3 ErsatzValidators (network.validators.ersatz.multipleOfTendermintValidators = 0.5)
  * Change the parameter network.validators.ersatz.multipleOfTendermintValidators to 0.1
  * Verify that in the following to epoch, all the ErsatzValidators are demoted to pending 

17. Number of Ersatzvalidators Erratic (<a name="0069-VCBS-055" href="#0069-VCBS-055">0069-VCBS-055</a>):
  * Setup a network with 5 Tendermint validators, 2 ErsatzValidators (network.validators.ersatz.multipleOfTendermintValidators = 0.5), and 2 pending validators
  * Change the parameter network.validators.ersatz.multipleOfTendermintValidators to 0.9
  * Verify that in the next epoch the 2 pending validators are promoted to ersatz
  * Change network.validators.ersatz.multipleOfTendermintValidators to 0.1
  * Verify that in the next epoch the 4 ersatz validators are demoted to pending
  * Two epochs later, change network.validators.ersatz.multipleOfTendermintValidators to 0.5
  * Verify that in the next epoch the 2 pending validators are promoted to ersatz
  * Verify that in the last epoch, no demotions/promotions happen and the number of Ertsatzvalidators stays at 2

18. Number of ErsatzValidators oddly defined (<a name="0069-VCBS-056" href="#0069-VCBS-056">0069-VCBS-056</a>)d
  * Set the factor to 0.00000000000000000000000000000000000000001
  * Verify that all Validators round it the same way, and that there are no Ersatzvalidators

  * Set the factor to 3.00000000000000000000000000000000000000001 and run the network with just one tendermint (consensus) validator.
  * Verify that all Validators round it the same way, and that there are three Ersatzvalidators

19. Change network.validators.ersatz.rewardFactor (<a name="0069-VCBS-057" href="#0069-VCBS-057">0069-VCBS-057</a>)
  * Setup a network with 5 Tendermint validators, 3 ErsatzValidators,  network.validators.ersatz.rewardfactor = 0 
  * Verify that at the end of the Epoch, the ErsatzValidators get no reward
  * Increase the rewardFactor to 0.5
  * Verify that at the end of ther Epoch, the Ersatzvarlidators get half the reward that the validators get (in total)
  * Decrease the rewardFactor to 0.4 
  * Verify that at the end of ther Epoch, the Ersatzvarlidators get 40% of thethe reward that the validators get (in total)
  * Set the rewardFactor to 0.32832979375934745648654893643856748734895749785943759843759437549837534987593483498
  * Verify that all validators round the value of reward for the Ersatzvalidators to the same value.

1. Announce node (<a name="0069-VCBS-034" href="#0069-VCBS-034">0069-VCBS-034</a>):
    - Verify that a node node, once added successfully to the topology, is shown on data-node API with the status pending
1. Promote a node to become an ersatz validator (<a name="0069-VCBS-035" href="#0069-VCBS-035">0069-VCBS-035</a>):
    - Set up a network with no existing ersatz validators
    - Ensure that the number of ersatz validators allowed in the network is is greater than 0 using the network parameter `network.validators.ersatz.multipleOfTendermintValidators`
    - Announce a new node on the network
    - Verify the new node gets promoted to an ersatz validator Note: ensure there are no available slots for Tendermint validators so the new node doesn’t get promoted directly to become a Tendermint validator.
1. Demote a Tendermint validator due to lack of slots (<a name="0069-VCBS-036" href="#0069-VCBS-036">0069-VCBS-036</a>):
    - Setup a network with 4 Tendermint validators
    - Change the network parameter `network.validators.tendermint.number` to 3 Tendermint validators
    - Verify that the Tendermint validator with the lowest score is demoted to an ersatz validator at the beginning of the next epoch
    1. Demote an ersatz validator due to lack of slots (<a name="0069-VCBS-037" href="#0069-VCBS-037">0069-VCBS-037</a>):
    - Setup a network with 4 tendermint validators, and 2 ersatz validators.
    - Change the ersatz network parameter `network.validators.ersatz.multipleOfTendermintValidators` to 0.25 of the Tendermint validators
    - Verify that the ersatz validator with the lowest score is demoted to pending at the beginning of the next epoch
1. Promotion a node to become a Tendermint validator (<a name="0069-VCBS-038" href="#0069-VCBS-038">0069-VCBS-038</a>):
    - Setup a network with 5 validators (and 5 slots for tendermint validators).
    - Do not self-delegate to them.
    - Announce a new node and self-delegate to them.
    - Verify that at the beginning of the next epoch one of the validators which were Tendermint validators before is chosen at random and is demoted to ersatz validator.
    - Verify the announced validator is promoted to be Tendermint validator with voting power = 10000.
1. Promotion + swap (<a name="0069-VCBS-039" href="#0069-VCBS-039">0069-VCBS-039</a>):
    - Setup a network with 4 validators with self-delegation such that the number of Tendermint nodes (with the `network.validators.tendermint.number` parameter set to 5).
    - In the following epoch, remove the self-delegation from node 1, and announce 2 nodes.
    - During the epoch self-delegate to the two nodes.
    - Wait for 3 epochs to allow performance of the new nodes to be greater than 0.
    - Verify that, once the performance is greater than zero, the two nodes should be promoted to Tendermint validators and their voting power should be equal to their relative stake x their performance score x 10000.
1. Swap last due to performance (<a name="0069-VCBS-040" href="#0069-VCBS-040">0069-VCBS-040</a>):
    - Setup a network with 5 validators with self-delegation.
    - Announce a new node and self-delegate to it.
    - Once it gets to a performance score of 0.2, shut down two of the 5 Tendermint validators after 0.1 of the duration of the epoch, e.g. if the epoch is 5 minutes, that means after 30 seconds of the epoch they should be stopped.
    - Verify that at the beginning of the next epoch, expect the performance score of the two stopped validators is <= 0.1, and one of them chosen at random is demoted to ersatz validator and is replaced by the announced nodes as a Tendermint validator with voting power =~ 0.2 * `stake_of_validator` / `total_stake_network`
1. Number of slots increased (<a name="0069-VCBS-041" href="#0069-VCBS-041">0069-VCBS-041</a>):
    - Setup a network with 5 Tendermint validators, self-delegate to them (set the parameter `network.validators.tendermint.number` to 5, set the `network.validators.ersatz.multipleOfTendermintValidators` parameter to 0 so there are no ersatz validators allowed).
    - Announce a new node, DO NOT self-delegate to it.
    - Run for an epoch and assert the validator is shown as pending.
    - Increase the number of tendermint validators to 6.
    - Verify that at the beginning of the next epoch the pending validator is still pending as their performance score is 0 (no self-stake).
    - Self-delegate to the pending validator
    - Verify that at the end of the epoch they are promoted to Tendermint validator.
1. Swap due to better score (<a name="0069-VCBS-042" href="#0069-VCBS-042">0069-VCBS-042</a>):
    - Setup a network with 5 Tendermint validators and self-delegate 1000 tokens to each of them.
    - Announce a new node at the beginning of the epoch, self-delegate to them a total that is 10000 tokens.
    - At the beginning of the next epoch the new validator should have ranking score *equal or lower* to all of the Tendermint validators so it doesn’t get promoted. The parameter <incubent_factor> is set sufficiently high to assure this (e.g., 1.1).
    - In the middle of the epoch, shut node 1 down.
    - Verify that at the beginning of the next epoch the announced node replaced node 1 as a Tendermint validator.
    - Restart node 1 again from a snapshot
    - Verify that node 1 is in a pending state and it’s ranking score is ~ 0.006666666667.
1. 2 empty spots, only one available to replace (<a name="0069-VCBS-043" href="#0069-VCBS-043">0069-VCBS-043</a>):
    - Setup a network with 5 slots for
    - Tendermint validators and 3 actual Tendermint validators.
    - Self-delegate to all of them.
    - Announce 2 new nodes but self-delegate only to one of them.
    - Verify that, after 1000 blocks and on the following epoch, only the validator to which we self-delegated got promoted and we now have 4 Tendermint validators and 1 pending validator.
1. Change `ownstake` requirement (<a name="0069-VCBS-053" href="#0069-VCBS-053">0069-VCBS-053</a>):
    - Network with 5 tendermint validators and 7 ersatz validators
    - In the same epoch, change the network parameter `reward.staking.delegation.minimumValidatorStake` in a way that 3 tendermint validators and 3 ersatz validators drop below the `ownstake` requirement, and change the delegation so that 4 (not affected) Ersatz validators have a higher score than two (not affected) Validators. Also, give one of the Ersatz validators with insufficient `ownstake` the highest stake (delegated) of all Ersatz validators.
    - At the end of the epoch all validators with insufficient own stake will get a ranking score of 0.
    - No ersatz validator with insufficient stake will get unlisted as ersatz validator
    - The 3 tendermint validators would be swapped with the top 3 ersatz validators over the following 3 epochs
    - Also verify that the ersatz validator with the insufficient own but the most delegated stake has a ranking score of 0 and doesn't get promoted.
    - No validator with stake attached to them is ever completely removed
1. (Alternative until we can build a large enough network for above AC ) (<a name="0069-VCBS-059" href="#0069-VCBS-059">0069-VCBS-059</a>):
    1. Setup a network with 5 nodes (3 validators, 2 ersatz validators). In one epoch,
        - one ersatz validator gets the highest delegated stake, but insufficient `ownstake` (delegates: 10000)
        - 2 validators drop below `ownstake`, but have relative high delegated stake (7000)
        - 1 validator drops to the lowest delegated stake (1000)
        - 1 ersatz validator has 6000 stake and sufficient `ownstake`
        - Verify that the the first ersatz validator is removed (marked as pending in the epoch change and then removed due to continuous insufficient `ownstake`), and one validator with insufficient `ownstake` is replaced by the other ersatz validator.
    1. Setup a network with 5 nodes (3 validators, 2 ersatz validators). In one epoch,
        - 1 validator drops below `ownstake`, but has relative high delegated stake (7000)
        - 2 validators drop to the lowest delegated stake (1000 and 1500, respectively)
        - 2 ersatz validators have 6000 stake and sufficient `ownstake`
        - Verify that at the epoch change,  the validator with insufficient `ownstake` is replaced; in the next epoch, the second validator with the lowest score is replaced, and the validator that was demoted to ersatz validator due to insufficient `ownstake` is removed (stops being listed as an ersatz validator).
        - Verify that the validator that dropped below `ownstake` is not demoted and removed at the same epoch change.
    1. Setup a network with 5 nodes (3 validators, 2 ersatz validators). In one epoch,
        - All validators drop below `ownstake`
        - All ersatz validators have sufficient `ownstake`, but lower stake than the validators
        - Verify that 2 validators are replaced, one in each epoch
    1. Setup a network with 5 nodes (3 validators, 2 ersatz validators). In one epoch,
        - All validators drop below `ownstake`
        - All ersatz validators have sufficient `ownstake`, and higher stake than the validators
        - Verify that one validator is replaced the following epoch, one in the epoch after
1. Ersatz validator reward (<a name="0069-VCBS-061" href="#0069-VCBS-061">0069-VCBS-061</a>) Setup a network with 5 validators with the following distribution of delegation: 10%, 10%, 10%, 10%. 60% of the total delegation of tendermint validators
    - Setup 5 ersatz validators each with the minimum delegation at the end of the epoch verify that the stake score of the validator with 60% of the delegation (under reward) is anti-whaled
    - Shutdown the validator with 60% of the delegation
    - Run for an epoch with it down
    - At the end of the epoch expect the validator with 60% of the stake to be swapped as a tendermint validator for one of the ersatz validators.
    - Restart the validator, run until the end of the epoch
    - Verify that this validator is paid reward as ersatz validator and that their stake score under reward is anti-whaled
1. Number of slots decreased (<a name="0069-VCBS-052" href="#0069-VCBS-052">0069-VCBS-052</a>):
    - Setup a network with 7 Tendermint validators, self-delegate to them (set the parameter `network.validators.tendermint.number` to 5, set the `network.validators.ersatz.multipleOfTendermintValidators` parameter to 0 so there are no ersatz validators allowed).
    - Decrease the number of tendermint validators to 5.
    - Verify that in each of the following two epochs, the validator with the lowest score is demoted to Ersatz validator and an Ersatz validator is demoted to pending
1. Number of Ersatz validators increased (<a name="0069-VCBS-058" href="#0069-VCBS-058">0069-VCBS-058</a>):
    - Setup a network with 6 Tendermint validators, 3 Ersatz Validators (`network.validators.ersatz.multipleOfTendermintValidators` = 0.5), and 4 pending validators
    - Change the parameter `network.validators.ersatz.multipleOfTendermintValidators` to 0.9
    - Verify that in the following two epochs, in each epoch the Ersatz Validator with the highest score is promoted to Validator
    - Verify that the third Ersatz validator is not promoted in the third epoch
1. Number of Ersatz validators decreased (<a name="0069-VCBS-054" href="#0069-VCBS-054">0069-VCBS-054</a>):
    - Setup a network with 6 Tendermint validators, 3 Ersatz Validators (`network.validators.ersatz.multipleOfTendermintValidators` = 0.5)
    - Change the parameter `network.validators.ersatz.multipleOfTendermintValidators` to 0.1
    - Verify that in the following to epochs, in each epoch the Ersatz Validator with the lowest score is demoted to pending
    - Verify that the third Ersatz validator is not promoted in the third epoch
1. Number of Ersatz validators Erratic (<a name="0069-VCBS-055" href="#0069-VCBS-055">0069-VCBS-055</a>):
    - Setup a network with 6 Tendermint validators, 3 Ersatz Validators (`network.validators.ersatz.multipleOfTendermintValidators` = 0.5), and 4 pending validators
    - Change the parameter `network.validators.ersatz.multipleOfTendermintValidators` to 0.9
    - In the next epoch, change `network.validators.ersatz.multipleOfTendermintValidators` to 0.1
    - Two epochs later, change `network.validators.ersatz.multipleOfTendermintValidators` to 0.5
    - Verify that in the following four epochs, first a pending validator is promoted, then two pending validators are demoted, then one is promoted again (with the highest/lowest scores respectively)
    - Verify that in the fifth epoch, no demotions/promotions happen and the number of Ersatz validators stays at 3
1. Number of Ersatz Validators oddly defined (<a name="0069-VCBS-056" href="#0069-VCBS-056">0069-VCBS-056</a>):
    - Set the factor to 0.00000000000000000000000000000000000000001
    - Verify that all Validators round it the same way, and that there are no Ersatz validators
    - Set the factor to 3.00000000000000000000000000000000000000001 and run the network with just one tendermint (consensus) validator.
    - Verify that all Validators round it the same way, and that there are three Ersatz validators
1. Change `network.validators.ersatz.rewardFactor` (<a name="0069-VCBS-057" href="#0069-VCBS-057">0069-VCBS-057</a>):
    - Setup a network with 5 Tendermint validators, 3 Ersatz Validators,  `network.validators.ersatz.rewardfactor` = 0
    - Verify that at the end of the Epoch, the Ersatz Validators get no reward
    - Increase the `rewardFactor` to 0.5
    - Verify that at the end of the Epoch, the Ersatz validators get half the reward that the validators get (in total)
    - Decrease the `rewardFactor` to 0.4
    - Verify that at the end of the Epoch, the Ersatz validators get 40% of the reward that the validators get (in total)
    - Set the `rewardFactor` to 0.32832979375934745648654893643856748734895749785943759843759437549837534987593483498
    - Verify that all validators round the value of reward for the Ersatz validators to the same value.

### Announce Node

1. Invalid announce node command (<a name="0069-VCBS-044" href="#0069-VCBS-044">0069-VCBS-044</a>):
    - Send an announce node command from a non validator node should fail
1. Valid announce node command (<a name="0069-VCBS-045" href="#0069-VCBS-045">0069-VCBS-045</a>):
    - Send a valid announce node from a validator node should result in a validator update event with the details of the validator and a validator ranking event.
1. Node announces using same keys as existing node via announce node command (<a name="0069-VCBS-060" href="#0069-VCBS-060">0069-VCBS-060</a>):
    - Should be rejected

### Checkpoints

1. Base case (<a name="0069-VCBS-046" href="#0069-VCBS-046">0069-VCBS-046</a>):
    - Setup a network with 5 Tendermint validators
    - Take a checkpoint
    - Restore from checkpoint with the 5 same validators, which should pass.
    - Verify that after the network is restarted, the validators have voting power as per the checkpoint until the end of the epoch.
1. Base + ersatz (<a name="0069-VCBS-047" href="#0069-VCBS-047">0069-VCBS-047</a>):
    - Setup a network with 5 Tendermint validators (where 5 is also the number of allowed Tendermint validators)
    - Announce 2 new nodes and wait for them to become ersatz validators (set the network parameter `network.validators.minimumEthereumEventsForNewValidator` to 0).
    - Take a checkpoint and verify it includes the ersatz validators.
    - Restore from the checkpoint (all nodes are running)
    - Verify that the validators have the voting power as per the checkpoint and that the ersatz validators are shown on data node having status ersatz.
1. Missing validators (<a name="0069-VCBS-048" href="#0069-VCBS-048">0069-VCBS-048</a>):
    - Setup a network with 5 validators such that 3 of them have 70% of the voting power. Note: this is done by delegating 70% of the total stake to them.
    - Take a checkpoint
    - Restore from the checkpoint – starting only the 3 nodes with the 70% stake.
    - Verify that after the restore the network should be able to proceed generating blocks although with slower pace.
1. Missing validators stop the network (<a name="0069-VCBS-049" href="#0069-VCBS-049">0069-VCBS-049</a>):
    - Setup a network with 5 validators with equal delegation to them.
    - Verify before the checkpoint that the voting power of all of them is equal.
    - Take a checkpoint.
    - Restart the network starting only 3 of the validators.
    - Restore from the checkpoint.
    - Verify the network is not able to produce blocks.

### Multisig update

1. Vega network receives the ethereum events updating the weights and stores them (`key`,`value`). (<a name="0069-COSMICELEVATOR-002" href="#0069-COSMICELEVATOR-002">0069-COSMICELEVATOR-002</a>)
1. For validators up to `network.validators.multisig.numberOfSigners` the `validator_score` is capped by the value on `Ethereum`, if available and it's `0` for those who should have value on Ethereum but don't (they are one of the top `network.validators.multisig.numberOfSigners` by `validator_score` on VEGA). (<a name="0069-COSMICELEVATOR-003" href="#0069-COSMICELEVATOR-003">0069-COSMICELEVATOR-003</a>)
1. It is possible to submit a transaction to update the weights. (<a name="0069-COSMICELEVATOR-004" href="#0069-COSMICELEVATOR-004">0069-COSMICELEVATOR-004</a>)

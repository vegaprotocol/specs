# Validator and Staking POS Rewards
This describes the SweetWater requirements for calculation and distribution of rewards to delegators and validators. For more information on the overall approach, please see the relevant research document.

This applies both the rewards coming from the [on-chain-treasury](./0055-TREA-on_chain_treasury.md) as well rewards resulting from trading via [infrastructure fees](./0029-FEES-fees.md). 

### Network parameters used for `score_val` calculation:
1. `min_val`: minimum validators we need (for now, 5). This is a network parameter that can be changed through a governance vote. Full name: `reward.staking.delegation.minValidators`.
1. `numberOfValidators` - the actual number of validators running the consensus (derived from running chain)
1. `totalStake` - the total number of units of the staking and governance asset (VEGA) associated to the Vega chain (but not necessarily delegated to a specific validator).
1. `compLevel` - This is a Network parameter that can be changed through a governance vote. Valid values are in the range 1 to infinity i.e. (including 1 but excluding infinity) i.e. `1 <= compLevel < infinity`. Full name: `reward.staking.delegation.competitionLevel`. Default `1.1`.
1. `reward.staking.delegation.optimalStakeMultiplier` - another network parameter which together with `compLevel` control how much the validators "compete" for delegated stake. 
1. `network.ersatzvalidators.reward.factor` - a decimal in `[0,1]` with default of `1`. It controls how much the ersatz validator own + delegated stake counts for reward purposes. 

### Other network parameters: 
- `delegator_share`: proportion of the validator reward that goes to the delegators. The initial value is 0.883. This is a network parameter that can be changed through a governance vote. Valid values are in the range 0 to 1 (inclusive) i.e. `0 <= delegator_share <= 1`. Full name: `reward.staking.delegation.delegatorShare`.
- `min_own_stake`: the minimum number of staking and governance asset (VEGA) that a validator needs to self-delegate to be eligible for rewards. Full name: `reward.staking.delegation.minimumValidatorStake`. Can be set to any number greater than or equal `0`. Default `3000`.   


**Note**: changes of any network parameters affecting these calculations will take an immediate effect (they aren't delayed until next epoch).

# Calculation
This applies to the on-chain-treasury for each asset as well as network infrastructure fee pool for each asset. 
At the end of an [epoch](./0050-EPOC-epochs.md), payments are calculated. 

As step *zero*: Vega keeps track of validators currently on the Ethereum multisig contract by knowing the initial state and by observing `validator added` and `validator removed` events emitted by the contract, see [multisig ethereum contract](./0033-OCAN-cancel_orders.md).
If there are ethereum public keys on the multisig that do not belong to any of the current Tendermint validator nodes then the reward is zero. 
The obverse case where a Tendermint validator doesn't have their signature on the multisig is dealt with in [validators joining and leaving](./0069-VCBS-validators_chosen_by_stake.md).
The reason for this drastic reduction to rewards is that if there are signatures the multisig is expecting that Vega chain isn't providing there is a danger that control of the multisig is lost. 
This is to ensure that validators (all validators) have incentive to pay Ethereum gas to update the multisig signer list.  

## Tendermint Validators and ersatz validators
 In Vega, we have two sets of Validators, the primary validators (which run Tendermint) and the [ersatz validators](./0069-VCBS-validators_chosen_by_stake.md) (which are running a non-validator node and can be promoted to a validator node by the protocol if they meet the right criteria). 
 Both Tendermint validators and ersatz validators get rewards (both from fees and additional from on chain treasury) following the method above:
 1. The reward pool is split into two parts, proportional to the total own+delegated stake the primary- and ersatz validators have. 
 Thus, if `s_t = network.ersatzvalidators.reward.factor x s_e + s_p` is the total amount of own+delegated stake to both sets (with ersatz scaling taken into account), `s_p` the total stake delegated to the primary / Tendermint validators and `s_e x network.ersatzvalidators.reward.factor` the total stake delegated to the ersatz validators (scaled appropriately), then the primary / Tendermint pool has a fraction of `s_p/s_t` of the total reward, while the ersatz pool has `network.ersatzvalidators.reward.factor x s_e / s_t` (both rounded down appropriately).

 The following formulas then apply to both primary and ersatz validators, where 'total available reward' and 'total delegation', total_stake and 'number_of_validators' or `s_total` refer to the corresponding reward pool and the total own+delegated corresponding set of validators (i.e., `s_p` or `s_e`, respectively).  


## For each validator we then do:
1. First, `validatorScore` is calculated to obtain the relative weight of the validator given `stake_val` is  both own and delegated tokens, that is `stake_val = allDelegatedTokens + validatorsOwnTokens`. 
Here `allDelegatedTokens` is the count of the tokes delegated to this validator. 
Note `validatorScore` also depends on the other network parameters, see below where the exact `validatorScore` function is defined.  
1. Obtain the performance score as per [validator performance specification](./0064-VALP-validator_performance_based_rewards.md). Update `validatorScore <- validatorScore x performance_score`. 
1. The fraction of the total available reward that goes to a node (some of this will be for the validator , some is for their delegators) is then `nodeAmount := stakingRewardAmtForEpoch x validatorScore / sumAllValidatorScores` where `sumAllValidatorScores` is the sum of all scores achieved by the validators. Note that this is subject to `min_own_stake` criteria being met. (see below).
1. The amount that is for the validator to keep (subject to delay and max payout per participant) is
`valAmt = nodeAmount x (1 - delegatorShare)`. 
1. The amount to be distributed among all the parties that delegated to this validator is `allDelegatorsAmt := nodeAmount x delegatorShare x score_val / total_score`.  

### For each delegator that delegated to this validator
Each delegator should now receive `delegatorTokens / (allDelegatedTokens + validatorsOwnTokens)`. 

### Minimum validator stake 
If the validator (i.e. the associated key) does not have sufficient stake self-delegated (at least the network parameter `min_own_stake`), then the reward for the validator is set to zero. The corresponding amount is kept by the network, not distributed among the other validators. Note this only applies to the part of the reward attributable directly to such a validator, its delegators should still receive their rewards. If a Vega key which defines a validator delegates any amount to a different validator then the reward associated with that delegation will be paid out just like for any other delegator.



## validatorScore functions:

This is defined as follows: 
```javascript
function validatorScore(valStake) { 
  a = Math.max(s_minVal, s_numVal/s_compLevel)
  optStake = s_total / a
  
  penaltyFlatAmt = Math.max(0.0, valStake - optStake)
  penaltyDownAmt = Math.max(0.0, valStake - optimalStakeMultiplier*optStake)
  linearScore = (valStake - penaltyFlatAmt - penaltyDownAmt)/s_total

  // make sure we're between 0 and 1.
  linearScore = Math.min(1.0, Math.max(0.0,linearScore))
  return linearScore
}
```

For ersatz validators, the formula changes slightly:
```go
 linearScore = (valStake)/s_total
 linearScore = Math.min(1.0, Math.max(0.0,linearScore))
```
i.e., there is no anti-whaling function applied here (the penalties are removed)


# Acceptance criteria

## Spare key on multisig (<a name="0061-REWP-001" href="#0061-REWP-001">0061-REWP-001</a>) 
1. Four or more Tendermint validators with equal own+delegated stake and some ersatz validators are running.
1. Reward pool is funded.
1. There is a one-to-one correspondence between Tendermint validators' ethereum keys and keys on multisig.
1. One of the Tendermint validators goes offline forever and is removed from the set of Tendermint validators but their key still stays on multisig (no-one updated).
1. Epoch ends and multisig hasn't been updated.
1. No validators get any rewards.


- A validator with less than `minOwnStake` tokens staked to themselves will earn 0 rewards at the end of an epoch (<a name="0061-REWP-002" href="#0061-REWP-002">0061-REWP-002</a>)
- With `delegator_share` set to `0`, a validator keeps 100% of their own rewards, and a delegator receives no reward (<a name="0061-REWP-003" href="#0061-REWP-003">0061-REWP-003</a>) 
- With `delegator_share` set to `1`, a validator receives no reward, and their delegators receive a proprotional amount of 100% (<a name="0061-REWP-004" href="#0061-REWP-004">0061-REWP-004</a>) 
- With `delegator_share` set to `0.5`, a validator keeps 50% of their own reward, and their delegators receives a proprotional amount of the remaining 50% (<a name="0061-REWP-006" href="#0061-REWP-006">0061-REWP-006</a>) 

## Rewards distribution corresponds to the signers on the multisig contract in the case that it hasn’t been updated after a validator set change (<a name="0061-REWP-007" href="#0061-REWP-007">0061-REWP-007</a>) 
1. Four or more Tendermint validators with equal own+delegated stake and some ersatz validators are running.
1. There is a one-to-one correspondence between Tendermint validators' ethereum keys and keys on multisig.
1. Reward pool is funded.
1. A validator called Bob leaves the set of tendermint validators (for example, reduce own plus delegated tokens so that their score is pushed down). A validator called Alice is promoted to tendermint validator set. 
1. No-one updated multisig validators so we still have Bob's key on the list of multisig signer. 
1. Epoch ends and multisig hasn't been updated.
1. All validators and ersatz validators, apart from Alice get rewards.


## Rewards from trading fees are calculated and distributed (<a name="0061-REWP-008" href="#0061-REWP-008">0061-REWP-008</a>) 
1. Run Vega with at least 3 tendermint validator nodes and at least 5 ersatz validator nodes each with different self-stake and delegation.
1. A market is launched with settlement asset A, infrastructure fee of `0.01 = 1%`. Market leaves opening auction and at least 10 trades occur with a total traded notial for fee purposes of at least 10000000 A. 
1. Epoch ends. 
1. The reward pool from trading in asset A is at least `0.01 x 10000000 = 100000`. 
1. Each validator and delegator receives appropriate share of the `100000`. 
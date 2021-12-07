# Validator and Staking POS Rewards
This describes the SweetWater requirements for calculation and distribution of rewards to delegators and validators. For more information on the overall approach, please see the relevant research document.

This applies both the rewards coming from the [on-chain-treasury](0055-on-chain-treasury.md) as well rewards resulting from trading via [infrastructure fees](0029-fees.md). 

### Network parameters used for `score_val` calculation:
1. `min_val`: minimum validators we need (for now, 5). This is a network parameter that can be changed through a governance vote. Full name: `reward.staking.delegation.minValidators`.
1. `numberOfValidators` - the actual number of validators running the consensus (derived from running chain)
1. `totalStake` - the total number of units of the staking and governance asset (VEGA) associated to the Vega chain (but not necessarily delegated to a specific validator).
1. `compLevel` - This is a Network parameter that can be changed through a governance vote. Valid values are in the range 1 to infinity i.e. (including 1 but excluding infinity) i.e. `1 <= compLevel < infinity`. Full name: `reward.staking.delegation.competitionLevel`. Default `1.1`.
1. `reward.staking.delegation.optimalStakeMultiplier` - another network parameter which together with `compLevel` control how much the validators "compete" for delegated stake. 

### Other network parameters: 
- `delegator_share`: propotion of the validator reward that goes to the delegators. The initial value is 0.883. This is a network parameter that can be changed through a governance vote. Valid values are in the range 0 to 1 (inclusive) i.e. `0 <= delegator_share <= 1`. Full name: `reward.staking.delegation.delegatorShare`.
- `min_own_stake`: the minimum number of staking and governance asset (VEGA) that a validator needs to self-delegate to be eligible for rewards. Full name: `reward.staking.delegation.minimumValidatorStake`. Can be set to any number greater than or equal `0`. Default `3000`.   
- `reward.staking.delegation.payoutDelay` - the time betweeen the end of epoch (when the rewards are calculated)  
- `reward.staking.delegation.payoutFraction` - the fraction of a reward pool / infrastructure fee pool (in any asset) that is to be used for rewards for a single epoch.
- `reward.staking.delegation.maxPayoutPerParticipant` - the maximum (applies only to on-chain tresaury rewards in the form of thestaking and governance asset) that each participant may receive as a payout from single epoch. 
- `reward.staking.delegation.maxPayoutPerEpoch` - the maximum (applies only to on-chain tresaury rewards in the form of thestaking and governance asset) that may be paid out for a given epoch.

**Note**: changes of any network parameters affecting these calculations will take an immediate effect (they aren't delayed until next epoch).

# Calculation
This applies to the on-chain-treasury for each asset as well as network infrastructure fee pool for each asset. 

At the end of an [epoch](./0050-epochs.md), payments are calculated. First we determine the amount to pay out during that epoch: 
1. multiply the amount in the reward pool by `reward.staking.delegation.payoutFraction`; this is the amount going into next step, call it `stakingRewardAmtForEpoch`.
1. If the reward pool in question is the on-chain treasury for the staking and governance asset then `stakingRewardAmtForEpoch` is updated to `min(stakingRewardAmtForEpoch, reward.staking.delegation.maxPayoutPerEpoch)`. 

## For each validator we then do:
1. First, `validatorScore` is calculated to obtain the relative weight of the validator given `stake_val` is  both own and delegated tokens, that is `stake_val = allDelegatedTokens + validatorsOwnTokens`. 
Here `allDelegatedTokens` is the count of the tokes delegated to this validator. 
Note `validatorScore` also depends on the other network parameters, see below where the exact `validatorScore` function is defined.  
1. Obtain the performance score as per [validator performance specification](0064-validator-performance-based-rewards.md). Update `validatorScore <- validatorScore x performance_score`. 
1. The fraction of the total available reward that goes to a node (some of this will be for the validator , some is for their delegators) is then `nodeAmount := stakingRewardAmtForEpoch x validatorScore / sumAllValidatorScores` where `sumAllValidatorScores` is the sum of all scores achieved by the validators. Note that this is subject to `min_own_stake` and to `reward.staking.delegation.maxPayoutPerParticipant` (see below).
1. The amount that is for the validator to keep (subject to delay and max payout per participant) is
`valAmt = nodeAmount x (1 - delegatorShare)`. 
1. The amount to be distributed among all the parties that delegated to this validator is `allDelegatorsAmt := nodeAmount x delegatorShare x score_val / total_score`.  

### For each delegator that delegated to this validator
Each delegator should now recieve `delegatorTokens / (allDelegatedTokens + validatorsOwnTokens)`. 
Note that this is subject to `reward.staking.delegation.maxPayoutPerParticipant`, see below. 

### Minimum validator stake 
If the validator (i.e. the associated key) does not have sufficient stake self-delegated (at least the network parameter `min_own_stake`), then the reward for the validator is set to zero. The corresponding amount is kept by the network, not distributed among the other validators. Note this only applies to the part of the reward attributable directly to such a validator, its delegators should still receive their rewards. If a Vega key which defines a validator delegates any amount to a different validator then the reward associated with that delegation will be paid out just like for any other delegator.

### Maximum payout per participant
If the reward pool in question is the on-chain treasury for the staking and governance asset then payments are subject to `reward.staking.delegation.maxPayoutPerParticipant`. 
The maximum per participant is the maximum a single party (public key) on Vega can receive as a staking and delegation reward for one epoch. Each participant recieves their due, capped by the max. The unpaid amount remain in the treasury.
Setting this to `0` means no cap.

### Payout delay
Rewards are distributed after the end of an epoch with a delay set by `reward.staking.delegation.payoutDelay` 

## validatorScore functions:

This is defined as follows: 
```
function validatorScore(valStake) { 
  a = Math.max(s_minVal, s_numVal/s_compLevel)
  optStake = s_total / a
  
  penaltyFlatAmt = Math.max(0.0, valStake - optStake)
  penaltyDownAmt = Math.max(0.0, valStake - optimalStakeMultiplier*optStake)
  linearScore = (valStake - penaltyFlatAmt - penaltyDownAmt)/s_total

  // make sure we're between 0 and 1.
  linearScore = Math.min(1.0, Math.max(0.0,linearScore))
  return linearScore
```



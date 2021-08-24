# Validator and Staking POS Rewards
This describes the SweetWater requirements for calculation and distribution of rewards to delegators and validators. For more information on the overall approach, please see the relevant research document.

## Calculation

At the end of an [epoch](./0050-epochs.md), payments are calculated. This is done per active validator:

* First, `score_val(stake_val)` calculates the relative weight of the validator given the stake it represents.
* For each delegator that delegated to that validator, `score_del` is computed: `score_del(stake_del, stake_val)` where `stake_del` is the stake of that delegator, delegated to the validator, and `stake_val` is the stake that validator represents.
* The fraction of the total available reward a validator gets is then `score_val(stake_val) / total_score` where `total_score` is the sum of all scores achieved by the validators. The fraction a delegator gets is calculated accordingly.
* Finally, the total reward for a validator is computed, and their delegator fee subtracted and divided among the delegators.
* If the validator (or, the associated key) does not have sufficient stake (at least the network parameter min_own_take), 
  then the reward is set to zero. The corresponding money is kept by the network, not distributed among the other validators.


Variables used:

- `min_val`: minimum validators we need (for now, 5)
- `compLevel`: competitition level we want between validators (1.1)
- `num_val`: actual number of active validators
- `a`: The scaling factor; which will be `max(min_val, num_val/compLevel)`. So with `min_val` being 5, if we have 6 validators, `a` will be `max(5, 5.4545...)` or `5.4545...`
- `delegator_share`: propotion of the validator reward that goes to the delegators.

Functions:

- `score_val(stake_val)`: `min(stake_val, 1/a), where totalstake is the total number of staked tokens. This function assumes that the stake is normalized, i.e., the sum of stake_val for all validators equals 1. If this is not the case, 
  stake_val needs to be replaced by stake_val/total_stake, where total_stake is the sum of stake_val over all validators.
- `score_del(stake_del, stake_val)`: for now, this will just return `stake_del`, but will be replaced with a more complex formula later on, which deserves independent testing.
- `delegator_reward(stake_val)`: `stake_val * delegator_share`. Long term, there will be bonuses in addition to the reward.



## Distribution of Rewards
We assume a function total_payment() which computes the total payment for a given epoch, as well as some ressource pool 
from which the resources are taken; if the total_payment for a given epoch exceeds the size of the pool, then the 
entire pool is paid out. 


The total payment will then be distributed among validators and delegators following above formulars.


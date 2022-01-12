# Validator and Staking POS Rewards
This describes the Alpha Mainnet requirements for calculation and distribution of rewards to delegators and validators. For more information on the overall approach, please see the relevant research document.

## Calculation

At the end of an [epoch](./0050-epochs.md), payments are calculated. This is done per active validator:

* First, `score_val(stake_val)` calculates the relative weight of the validator given the stake it represents.
* For each delegator that delegated to that validator, `score_del` is computed: `score_del(stake_del, stake_val)` where `stake_del` is the stake of that delegator, delegated to the validator, and `stake_val` is the stake that validator represents.
* The fraction of the total available reward a validator gets is then `score_val(stake_val) / total_score` where `total_score` is the sum of all scores achieved by the validators. The fraction a delegator gets is calculated accordingly.
* Finally, the total reward for a validator is computed, and their delegator fee subtracted and divided among the delegators


Variables used:

- `min_val`: minimum validators we need (for now, 5)
- `compLevel`: competitition level we want between validators (1.1)
- `num_val`: actual number of active validators
- `a`: The scaling factor; which will be `max(min_val, num_val/compLevel)`. So with `min_val` being 5, if we have 6 validators, `a` will be `max(5, 5.4545...)` or `5.4545...`
- `delegator_share`: propotion of the validator reward that goes to the delegators.

Functions:

- `score_val(stake_val)`: `sqrt(a*stake_val/3)-(sqrt(a*stake_val/3)^3)`. To avoid issues with floating point computation, the sqrt function is
  computed to exactly four digits after the point. An example how this can be done using only integer calculations is in the example code.
  Also, this function assumes that the stake is normalized, i.e., the sum of stake_val for all validators equals 1. If this is not the case, 
  stake_val needs to be replaced by stake_val/total_stake, where total_stake is the sum of stake_val over all validators.
- `score_del(stake_del, stake_val)`: for now, this will just return `stake_del`, but will be replaced with a more complex formula later on, which deserves independent testing.
- The scoring function can give negative values if a validator has too much stake, which can upset subsequent computations. Thus, an additional
  correction is required: if (score_val) < 0 then score_val = 0. This point should never be reached in a real run though, as validators should to be able to 
  obtain enough delegation.
- `delegator_reward(stake_val)`: `stake_val * delegator_share`. Long term, there will be bonuses in addition to the reward.



## Distribution of Rewards

A component of the trading fees that are collected from price takers of a market are reserved for rewarding validators and stakers. These fees are denominated in the settlement currencies of the markets and are collected into an [infrastructure fee](./0029-feeds.md) [account](./0013-accounts.md) for that asset. These fees are "held" in this pool account for a length of time, determined by a network parameter (`infra-fee-hold-time`). 

They are then distributed to the general accounts of eligible recipients; that is, the validators and delegators, in amounts as per above calculation.

Once the reward for all delegators has been calculated, we end up with a slice of `Transfer`'s, transferring an amount from the infrastructure fee account (see [fees](./0029-fees.md)) into the corresponding general balances for all of the delegators. For example:

```go
rewards := make([]*types.Transfer, 0, len(delegators))
for _, d := range delegators {
	rewards = append(rewards, &types.Transfer{
		Owner: d.PartyID,
		TransferType: types.TransferType_TRANSFER_TYPE_STAKE_REWARD,
		Amount: &types.FinancialAmount{
			Amount: reward,
			Asset:  market.Asset,
		},
		MinAmount: reward,
	})
}

```

Sample code for the full distribution (slightly unclean, but fully functional) [here](0060-simple-POS-rewards.samplecode.go).



The transfer type informs the collateral engine that the `FromAccount` ought to be the infrastructure fee account, and the `ToAccount` is the general account for the party for the given asset. The delegator can then withdraw the amount much like they would any other asset/balance. Note, the transfers should only be made when the `infra-fee-hold-time` has elapsed. 


## Network Parameters

`infra-fee-hold-time` - the length of time between when a price taker infrastructure fee is incurred and when it is paid out to validators.
`delegator_share` - The proportion of the total validator reward that go to its delegators. Likely to be lower than 0.1.

## Payment of rewards
- [Infrastructure fees](./0029-fees.md) are collected into an infrastructure fee account for the asset
- These fees are distributed to the general accounts of the validators and delegators after `infra-fee-hold-time` in amounts calculated according to the above calculation.
- There may also be additional rewards for participating in stake delegation from the rewards function. These are accumulated and distributed separately.

# Validator and Staking POS Rewards
This describes the Alpha Mainnet requirements for calculation and distribution of rewards to delegators and validators. For more information on the overall approach, please see the relevant research document.

## Calculation

At the end of an epoch, payments are calculated. This is done per active validator:

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

- `score_val(stake_val)`: `sqrt(a*stake_val/3)-(sqrt(a*stake_val/3)^3)`
- `score_del(stake_del, stake_val)`: for now, this will just return `stake_del`, but will be replaced with a more complex formula later on, which deserves independent testing.
- `delegator_reward(stake_val)`: `stake_val * delegator_share`. Long term, there will be bonuses in addition to the reward.



## Distribution of Rewards

A component of the trading fees that are collected from price takers of a market are reserved for rewarding validators and stakers . These fees are denominated in the settlement currencies of the markets and are collected into an infrastructure fee account for that asset.These fees are "held" in this pool account for a length of time, determined by a network parameter (`infra-fee-hold-time`). 

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

The transfer type informs the collateral engine that the `FromAccount` ought to be the infrastructure fee account, and the `ToAccount` is the general account for the party for the given asset. The delegator can then withdraw the amount much like they would any other asset/balance. Note, the transfers should only be made when the `infra-fee-hold-time` has elapsed. 


## Network Parameters

`infra-fee-hold-time` - the length of time between when a price taker infrastructure fee is incurred and when it is paid out to validators.
`delegator_share` - The proportion of the total validator reward that go to its validators. Likely to be lower than 0.1.

## Payment of rewards
- [Infrastructure fees](./0029-fees.md) are collected into an infrastructure fee account for the asset
- These fees are distributed to the general accounts of the validators and delegators after `infra-fee-hold-time` in amounts calculated according to the above calculation.
- There may also be additional rewards for participating in stake delegation from the rewards function. These are accumulated and distributed separately.

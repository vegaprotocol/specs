# Reward framework

Vega core will initially specify a number of Reward Functions. In the future there will be an interace for code / bytecode / WASM to implement arbitrary reward function. 

Rewards are deployed using the Reward Functions. Individual Reward Pools are automatically created when an asset is transferred to the Reward.

Components of the rewards framework:
- Reward Policies
- Reward Pool Accounts
- Reward execution engine

Recipients of a reward can be Vega party general account and markets' insurance pool.

## Reward Policies

- Reward Policy Type:
  - Reward Function
  - Reward Function inputs
  - Reward Pool
- Reward Policy parameters


### Reward Functions

A Reward Function consists of: A reward calculation and its parameters. 
Its outputs are:
A table with one account per row and a proportion of a pool balance to be transferred to this account. 
The proportions must sum up to `<= 1.0`.

See [here](./0000) for a specified list of built in Reward Functions.

## Reward Scheme

Reward Schemes are deployed using a governance proposal which will specify the RewardFunction, its parameters and its recalculation period (currently time ticks over at the start of the block). 
Once the governance proposal to create a reward is enacted the reward is assigned a reward ID. 
TODO: create this governance proposal type as well as one for deactivating rewards, perhaps in [governance spec](0028-governance.md).

A Reward Scheme:

- May have an asset "sent" to it. This triggers:
  - if a Reward Pool exists for this Reward and Asset, the asset is transferred to that Reward Pool Account
  - otherwise, a new Reward Pool Account is created for this Reward, Asset.

```
Reward Scheme {
  name: taker_rewards(asset = "DAI"),
  period: weekly,
}
```

A Reward Scheme may be deactivated by governance. If there are no assets submitted to the Reward, or if the assets that have previously been submitted have been distributed, the Reward may be inactive.

Acceptance Criteria:
- [ ] Reward Schemes proposed by governance transaction but not yet enacted cannot receive asset transfers
- [ ] If there is no Reward, no Reward Pools exist that reference that Reward.



## Reward Pool Accounts

A Reward Pool is account is created as specified in above section. 
Reward Pool Accounts: 
- can be from core when the account balance is zero.
- a governance proposal to deactivate a Reward, which has been passed, will automatically transfer all assets in Reward Pool accounts for the deactivated reward to the appropriate (for the asset) on-chain treasury account.

```
RewardPool {
  type: "ACCOUNT_TYPE_REWARD_POOL"
  rewardId: // created when reward proposal passes governance and is enacted. 
  asset: "xlkjsdfkjssdfk", # rewards paid in - i.e. VEGA
}
```

## Reward Execution:
The execution engine will track all reward pools in the Vega network. 
At the appropriate times - as specified by the period in the reward definition - it will run the reward function with the asset corresponding to the asset the RewardPool is denominated in (not the asset in which the rewards are paid) as well as optionally the marketID. 
The reward function will return parties general account IDs and proportions. 
The execution engine will calculate the amounts to be transferred by multiplying the proportion by the pool balance. 
It will the execute the transfers. 


## Assumptions:

- Rewards are calculated deterministically at a point in time for all eligible participants
- Rewards are allocated at a point in time based on the activity by a participant since the last time this reward was calculated. 
- Each reward will have an allocation of tokens that is split between eligible participants according to defined rules
- Each of the reward specifications may be active or not; set by network parameter
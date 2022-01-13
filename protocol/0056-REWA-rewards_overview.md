# Reward framework

The reward framework provides for a standardised transaction API, funding approach, and execution methodology through which to calculate and distribute financial rewards to participants in the network based on performance in a number of metrics.

These rewards operate in addition to the main protocol economic incentives as they can be created and funded arbitrarily by users of the network and will be used by the project team, token holders (via governance), and individual traders and market makers to incentivise mutually beneficial behaviour.

Terminology:
- **Reward Type**: a reward type is a class of reward, for instance "simple staking rewards". This specifies:
  - the parameters that control reward calculation and dissemination including the applicable scope(s) of the reward type (i.e. network wide, per asset, per market)
  - the logic that defines how to calculate and distribute the reward
- **Reward Scheme**: a reward scheme is an instance of a reward type that includes all the parameters needed to calculate the reward. Multiple reward schemes may instantiated for each reward type, even with duplicate parameters.
- **Reward Pool Accounts**: each active reward scheme has one reward pool account for each asset that has been transferred to it (these would be created as needed)

Vega will initially provide built-in reward types for key types of incentives related to staking/delegation, liquidity provision, and trading (note: only a single staking/delegation reward type is required for Sweetwater).

💧 see section at bottom of file on Sweetwater scope
🤠 see section at bottom on Oregon Train scope

## Reward Types

Reward types will be specified in separate spec files, with each reward type specifying its applicable scope requirements, parameters, and calculation method.

### Applicable scope

Scope defines the constraints on a reward calculation. For example, a reward type that looks at total governance token holdings may always apply network-wide (i.e. to all participants), whereas a reward looking at traded notional might be restricted to trading in a single asset (because values in two or more assets are not comparable/convertable), but could also operate on narrower scopes, for instance trades on a specific market.

When defining a reward type, the specification should state the allowable scopes for rewards schemes of that type.

### Paraemters

A reward type may have one or more parameters that can be defined for each reward scheme of that type. These parameters may be used by the calculation logic to control how the split of rewards is decided between eligible participants.


### Calculation method

The calculation method defines the logic that is used to determine which participants are eligible for a reward and how to calculate the relative amount distributed to each participant.

The calculation method should provide a list of parties and scaling relative amounts. The relative amounts will be used to calculate the amount actually distributed as a share of the available pot for each reward scheme, taking into account the parameters.

For example, if the parties and relative amounts are: Party A, 60; Party B, 100; Party C, 40 (total=200). And if the rewards to be distributed are 500 VEGA. Then the amounts distributed will be:
- Party A = (60 / 200) * 500 = 150 VEGA
- Party B = (100 / 200) * 500 = 250 VEGA
- Party C = (40 / 200) * 500 = 100 VEGA

Care must be taken when defining calculation methods to create reward calculations that can be efficiently calculated taking into account both storage and computational resources. Principles for good reward calculations include:
- Should calculate, store and maintain single values rather than arbitrarily long lists (i.e. a reward calculation that maintains a running total traded volume by asset for each party over a period, rather than one that requires a list of all of a party's trades)
- Should only need to store a maximum of one set of metrics for the reward type, as opposed to needing to store separate running metrics for each instance (therefore, differences in parameterisation or scope should take effect when using the metrics in the calculation of the rewards at period end)
- Should try to use simple logic and maths and avoid complex calculations and logic involving looping, etc.
- All calculations must work in the decimal data type (no floats allowed)
- Should reuse data and metrics that are already known to the core protocol due to being used elsewhere, examples of [nearly] "free" data like this include:
  - fees collected or paid
  - cumulative order book or trading volumes
  - liquidity provider data including LP shares, market value proxy, etc.
  - balances of accounts
  - staking and delegation information


## Reward Schemes

A reward scheme is defined as a reward type plus parameters. Each reward scheme that is created can have up to one reward pool account per asset (see below). 


### Creating reward schemes

Reward schemes are created by a transaction that specifies the information described below:
- Reward type
- Scope of reward scheme, e.g. a specific market, asset, or network wide (must be a scope compatible with the reward type)
- Reward scheme parameters (as required for the reward type)
- Frequency of calculation (specified as interval between payouts)
- Reward scheme start date/time
- Reward scheme end date/time (blank for never)
- Payout type and parameters, either:
  - Fractional: try to pay a specified fraction of reward pool account balance(s) each period expressed as a decimal (`0.0 < fraction <= 1.0`).
  - Balanced: pay `X/n` out each period where `X` is the balance of the reward pool account and `n` is the number of period remaining until the end date, including the current period (only valid where the scheme has an end date)
- Max payout per asset per recipient: optionally a list of `{asset, max_amount}` pairs. Where provided, `max_amount` limits the amount of `asset` that will be paid out to any one account during a period.
- Payout delay: time period between reward calculation and payout (may be zero)

The transaction to create a reward scheme must either be:
- a governance proposal including the above information; OR
- a standard transaction accompanied by a transfer of initial funds to the reward pool subject to per-asset minimum (based off minimum LP stake amount)

Once reward is created it is assigned a reward ID, which is also used to identify the reward pool account(s) for the scheme in transfers.


### Spam protection

Creating a reward scheme outside of governance must be accompanied by an amount of funding for the reward pool in at least one asset. At least one asset included in this funding must have an amount included greater than or equal to `reward_funding_multiple * asset.min_lp_stake` where `reward_funding_multiple` is a network parameter and `asset.min_lp_stake` is the minimum LP stake amount configured for the asset.


### Updating reward scheme parameters

A Reward Scheme may only be updated by governance proposal. Updates work like network parameter changes where the parameter name is an identifier and the reward scheme ID (i.e. something like `rewards.<SCHEME_ID>`) and the values are stored as a single structured network parameter. The following may be changed: 
- scheme parameters
- scheme end date/time
- payout type and parameters
- max payout per asset per recipient
- payout delay


### Cancelling reward schemes

A Reward Scheme may only be cancelled by a governance proposal. On cancellation, any undistributed funds in the reward pool account will be transferred to the network treasury for the asset.


## Reward Pool Accounts

A Reward Pool is account created for a `{reward scheme, asset}` combination when funds are transferred to the reward scheme ID. 

## Reward Execution:

For each active reward scheme, the reward calculation will be run at the end of each period. This calculation will create a list of account IDs (generally party IDs) and `scaling_factors` (implying an `account_scaling_factor` for each eligible account) — see calculation method above.

For each reward pool account for the reward scheme with a non-zero balance:

1. Calculate the `total_payout` either as a fixed fraction of the balance (if payout type = fraction) or as the fraction of the balance resulting from dividing the balance equally by the number of remaining periods (if payout type = balanced).
1. Calculate the payout per eligible account by: `account_payout = total_payout * (account_scaling_factor / sum(scaling_factors)`
1. If a per asset max amount per recipient is specified for the asset, then cap each eligible account's payout to the `max_amount` specified. The remaining funds will not be distributed and so remain in reward scheme account.
1. If a non-zero payout delay is specified, wait for the required time before continuing to the next step
1. Transfer the capped `account_payout` amounts calculated in the previous step to each eligible account.


## Sweetwater

Sweetwater scope only requires that a single instance of the single reward function for staking and delegation is active and can accept and payout funds from [the on-chain treasury](./0058-on-chain-treasury.md).
It is therefore not necessary to build any of the transactions or control logic that will be needed for the reward framework once trading and liquidity provision rewards exist (required for Oregon Trail). Max payout per recipient and payout delay are required for 💧.


## Acceptance criteria


### 💧 Sweetwater

- There is a single reward scheme of type [staking and delegation rewards](./0057-REWF-reward_functions.md)
  - It has a reward scheme ID
  - Its parameters can be updated by governance vote
  - It cannot be cancelled entirely (though the payout amount can be set to 0)
  - Rewards are paid out correctly at the frequency specified by the current parameters
  - Rewards are capped to the max payout per recipient correctly
  - Payout is delayed by the correct amount of time if a payout delay is specified
  - The reward scheme doesn't and cannot have an end time specified (as we do not allow creation of new schemes, this one cannot end)
  - Fractional payout type is available
  - The reward scheme scope is network-wide
- When funds in a given asset are allocated to the reward scheme ID (for 💧 this only needs to be via automated allocation controlled by governance) a reward pool account is created for the asset:
  - Funds in all reward pool accounts for the scheme are paid out when rewards are paid
  - Each account's balance is used when calculating the amount based on the configured payout fraction
  - Funds cannot be transferred out of the reward pool accounts other than when they are paid out as rewards
  - Funds cannot be transferred directly to a reward pool account
- APIs allow the reward scheme and its parameters to be queried
- APIs allow a party to see how much was paid out to them (ideally this would just use the generalised transfers API filtered by type, but that may not exist for 💧 and this is needed)
- Updated to the reward scheme parameters are applied correctly for all future distributions
- No reward schemes can be created
- Only staking and delegation reward types are available


### 🤠 Oregon Trail (WIP)

- The are more reward types: staking and delegation, liquidity provision, trading, market creation TODO: individual specs 
- New reward scehemes can be created, including multiple of the same type
- Reward schemes owned and controlled by individual parties can be created as well as network owned ones created through governance
- Funds can be sent directly to a reward pool account
- Funds cannot be allocated to a party controlled reward scheme via periodic allocation from [the on-chain treasury](./0058-REWS-simple_pos_rewards.md).

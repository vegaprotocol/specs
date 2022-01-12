# Reward Types

Below is a list of reward types that will be built in to Vega and available when proposing or creating a new [Reward](0056-rewards-overview.md).



## Trading


### T.1 - Fees based reward (for 🤠)

Principle: reward certain activities measured by the fee amount they pay or receive. The more of certain fee they pay relative to others the more of the reward they get. 

Scope: This reward type can be scoped either to all trading settled in an asset, or to trading in one or more markets which must all settle in the same asset (so we don't need to covert values to compare).

Parameters: A Vega asset or a list of markets to define scope. A string specifying a fee type to be one of: `taker fee paid`, `maker fee received`, `liquidity provision fees received`.

### T.2 - Good risk citizen  (not for 🤠, later)

Principle: anyone who's got a position but hasn't been closed out is rewarded. 

Scope: This reward type can be scoped either to all trading settled in an asset, or to trading in one or more markets which must all settle in the same asset.

Calculation: From the start of a payout interval collect all parties that have position open during the entire period but haven't had their position closed out. The scaling factor for a party is `1` divided by the total number of parties that qualify within the scope for the period. 


## Liquidity Provision 

### L.1 - Providing LP stake in a market (for 🤠)

Principle: anyone who's got LP stake within scope is rewarded proportionally to stake size

Scope: This reward type can be scoped either to all trading settled in an asset, or to trading in one or more markets which must all settle in the same asset.

Calculation: From the start of a payout interval collect all parties that have LP stake during the entire period. Track the minimum LP stake for the period. The scaling factor for a party is the minimum LP stake the party had for the period divided by the total of all the mininmum LP stakes this and other parties maintained. 

## Market Creation (for 🤠)

### M.1 Get a market proposal accepted (for 🤠)

Principle: anyone whose market proposal gets accepted and the market meets criteria is eligible for reward.

Scope: A specific asset. 

Parameters: 
- `market_size` a monetary value to be compared against the total `value for fee purposes` traded on the market since enactment. 
- `size_eval_period`  a time period added on top of market enactment time for when the the evaluation is made. 

Calculation: From the start of the payout period collect all parties that proposed a market that's enacted during the period and are eligible according to the criteria: at `enactment time + size_eval_period` we have total `value for fee purposes` traded on the market >= to `market_size`. If either `market_size` or `size_eval_period` are set to `0` then any market that's enacted is eligible.
The party's scaling factor is `1` divided by the total number of markets meeting the criteria in that period. 


## Staking and delegation (required for 💧)

### S.1 - Rewarding getting started with delegation

Principle: reward staking and delegation with additional incentives, particularly to allow the network to be bootstrapped and create attractive early rewards.

Scope: this reward type is always scoped as network-wide

Parameters: none 

Reward calculation: the total payout amount for the period is treated in the same way as the infrastructure fee pool, and the relative payout scaling factors are calculated as per the staking and delegation specification for distributing infrastructure fees to token holders and validators, currently [simple POS rewards](0058-simple-POS-rewards.md). (Payout delay and max amount per recipient are still respected).

## Acceptance criteria


### 💧 Sweetwater


- There is a network parameter specifying the maximum balance to be payed out by "simple-POS-reward" per epoch. 
- Staking and delegation reward type is available and used for the single, "hard coded" (i.e. not changeable through transactions on chain in this release) reward scheme
- The reward amounts are calculated using the same formula and code as the staking and delegation reward calculation described in that spec, subject to the application of the max payout amount per participant (public key) if one is specified in the reward parameters (which are controllable by governance)
- Both stakers (identified by being self-delegators AND being in the active validator set) and delegators are rewarded, as per the calculation
- The calculation respects the rules around epochs and timing of delegation and undelegation when calculating rewards for a period


### 🤠 Oregon Trail

- [ ] Built in Reward Functions are discoverable to participants 
- [ ] For each reward function create scenario where the reward is created, funded, pays out rewards to eligible participants during the correct period and doesn't outside...  
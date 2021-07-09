# Reward Types

Below is a list of reward types that will be built in to Vega and available when proposing or creating a new [Reward]().

## Acceptance Criteria
- [ ] Built in Reward Functions are discoverable to participants 


## Trading

### T.1 - Taker fees paid (not 💧)

Principle: the more someone has been a price-taker, the greater share of rewards they receive through this mechanism.

Scope: This reward type can be scoped either to all trading settled in an asset, or to trading in one or more markets which must all settle in the same asset.

Calculation: the scaling factor for a party's rewards is simply the sum of all *taker fees* the party has paid within the defined scope (asset or market(s)) during the period.


### Placeholder future reward (revisit for Oregon Trail)

- Day Trader (the more frequently a participant is active, the greater share of rewards they receive through this mechanism)
- Good risk citizen


## Liquidity Provision (placeholder for future)

- Reward proportionate to LP fees received (i.e. liquidity scaled by LP shares)
- Reward proportionate to liquidity committed and provided NOT scaled by LP shares
- Reward proportionate to maker fees recevied (i.e. reward casual liquidity provision)


## Staking and delegation (required for 💧)

### S.1 - Rewarding getting started with delegation

Principle: reward staking and delegation with additional incentives, particularly to allow the network to be bootstrapped and create attractive early rewards.

Scope: this reward type is always scoped as network-wide

Parameters: none 

Reward calculation: the total payout amount for the period is treated in the same way as the infrastructure fee pool, and the relative payout scaling factors are calculated as per the staking and delegation specification for distributing infrastructure fees to token holders and validators. (Payout delay and max amount per recipient are still respected).


## Acceptance criteria


### 💧 Sweetwater

- Staking and delegation reward type is available and used for the single, "hard coded" (i.e. not changeable through transactions on chain in this release) reward scheme
- The reward amounts are calculated using the same formula and code as the staking and delegation reward calculation described in that spec, subject to the application of the max payout amount per participant (public key) if one is specified in the reward parameters (which are controllable by governance)
- Both stakers (identified by being self-delegators AND being in the active validator set) and delegators are rewarded, as per the calculation
- The calculation respects the rules around epochs and timing of delegation and undelegation when calculating rewards for a period


### 🤠 Oregon Trail

- TBC
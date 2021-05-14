# On-chain treasury - trading rewards

## Reward framework

Components of the rewards framework:
- Onchain treasury per asset
- Reward pools:
  - asset
  - reward-calculation
  - eligible recipients
- Recipients
  - Vega party general
  - market insurance pool
- Transfer type




## Behaviour we want to incentivise:

NOTE: trading activity for the purposes of these rewards can mean one or more of:
1. Price taking
1. Price making that results in a trade (seperate to liquidity commitments)
1. Trades resulting from auctions


### Behaviours:

A participant's:
1. total trading activity on the network
1. contribution to bootstrapping trading activity in new markets (separate to liquidity provision)
1. trading activity when markets are in protective auctions

[Are these useful?] A participant's:
1. use of special orders to create trading (e.g. pegged orders)
1. contribution to increasing or decreasing open interest
1. supplying of the orders that get filled for liquidations
1. good behaviour - never used or "donated to" insurance pool 

Network's (could give extra boost/bonus the prize pool?):
1. total traded notional
1. breadth of trading across markets


## Assumptions:

[note, I can't recall if these are general principles that we will build into the on-chain treasury reward spec]
- Rewards are calculated deterministically at a point in time for all eligible participants
- Rewards are allocated at a point in time based on the amount of fees paid by a participant since the last time this reward was calculated. 
- Each reward will have an allocation of tokens that is split between eligible participants according to defined rules
- Each of the reward specifications may be active or not; set by network parameter


## Reward specifications

Rewards may be distributed according to any or all of the following.

### X.1 - Total fees paid

Principle: the more someone has been a price-taker, the greater share of rewards they receive through this mechanism.

Proportion_Per_Participant = taker-fees-paid-by-participant-since-last-reward-calc / total-taker-fees-paid-in-the-system-since-last-reward-calc


### X.2 - Tenure

Principle: the more frequently a participant is active, the greater share of rewards they receive through this mechanism.

## 2 - Reward distributions

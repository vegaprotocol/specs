# Reward Functions

Below is a list of reward functions that will be built in to Vega and available when proposing or creating a new [Reward]().

## Acceptance Criteria
- [ ] Built in Reward Functions are discoverable to participants 


## Trading

### T.1 - Total fees paid

Principle: the more someone has been a price-taker, the greater share of rewards they receive through this mechanism.

```
RewardFunction: {
  taker_rewards(asset, Optional[Market]):
		reward_proportions(eligible_accounts, triggerAmt):
			for acc in eligible_accounts 
			if(totalAmtTraded > triggerAmt):
                Proportions[acc] = taker-fees-paid-by-participant-since-last-reward-calc / total-taker-fees-paid-with-this-reward-since-last-reward-calc
            else:
                Proportions[acc] = 0
            return Proportions
		}
    return [eligible_accounts, proportions]
  }
}
```


### T.2 - Day Trader

Principle: the more frequently a participant is active, the greater share of rewards they receive through this mechanism.



### T.3 - Good risk citizen



## Staking

### S.1 - Rewarding getting started with delegation

_Eligible recipients:_ anyone who delegates at least once during the period.

_Reward Pot:_ Fixed total pot amount (N), all distributed at the reward distribution point

_Reward Calculation:_ between the reward commencement time and the reward distribution time, any party who has made a deleegation at least once will receive N/(total count of eligible participants) tokens. Everyone receives the same amount of tokens.

_Acceptance Criteria:_

- [ ] a party that locks money on the bridge but does not delegate it, will not receive any reward
- [ ] a party that delegates and then undelegates during the period is considered an eligible participant
- [ ] all eligible participants receive the same size reward
- [ ] the reward pot is empty at the conclusion of the reward distribution

### S.2 - Rewarding consistent delegation

_Eligible recipients:_ anyone who delegates at least once during the period.

_Reward Pot:_ Fixed total pot amount (N), all distributed at the reward distribution point

_Reward Calculation:_ between the reward commencement time and the reward distribution time, any party who has delegated for [90% of the time] will receive N/(total count of eligible participants) tokens. Everyone receives the same amount of tokens.

_Acceptance Criteria:_

- [ ] a party that locks money on the bridge but does not delegate it, will not receive any reward
- [ ] a party that delegates for [10 x 1%] lengths of the total time is eligible participant
- [ ] all eligible participants receive the same size reward
- [ ] the reward pot is empty at the conclusion of the reward distribution

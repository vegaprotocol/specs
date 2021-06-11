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

### S.1 - Rewarding consistent delegation



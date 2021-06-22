## Delegation:

### Smart Contract Interaction

In order to delegate, users require tokens that will be locked in a smart contract. Vega will be made aware of how many tokens a given party has locked through bridge events. When the same tokens are unlocked, a corresponding event will be emitted:

```
  event Stake_Deposited(address indexed user, uint256 amount, bytes32 vega_public_key);
  event Stake_Removed(address indexed user, uint256 amount);
```

This provides the information the core needs to keep track of:

	* Total Delegatable Stake
	* Undelegated Stake
	* [n] Stake delegated per validator
	* [n] Stake marked for delegation per validator in the next epoch
	* Total stake (should be the summ of all the others)

There is no interaction with the smart contract that is initiated by Vega.

Once Vega is aware of locked tokens, the users will have an account with the balance reflecting how many tokens were locked. At this point, the user can submit a transaction to stake (delegate) their tokens. The amount they stake must be `<= balance`, naturally. Users can remove stake by submitting an `Undelegate` transaction. The tokens will then be restored back to their token balance. How users can delegate/undelegate is discussed below.

### Mechanics of locking/unlocking stake

At the top level, `Stake_Deposited` simply adds `amount` of tokens to the account of the user associated with the `user`. Likewise, the `Stake_Removed` event subtracts the `amount` of tokens from their account.

- If the `Stake_Removed` amount of tokens is higher than the balance of said user, something went seriously wrong somewhere. This is a good time to panic.
- If the amount is higher than the amound of undelegated stake, the missing amount must be freed using the undelegate function. There is currently no rule how to choose this; a first heuristic would be to take from the highest delegation first and then go down, e.g.
	* If the delegation is 100, 90, 80, 70, and we need to free 30 stake, we first take from the richest ones until they are no longer the richest:
	* Free 10, delegation is 90, 90, 80, 70
	* Free 30, delegation is 80, 80, 80, 70

### Delegating and Undelegating

```proto
message Delegate {
	uint256   Amount = 1;
	Validator Val = 2;
}

message Undelegate {
	uint256   Amount = 1;
	Validator Val = 2;
}
```

Where `Delegate` adds the `Amount` to the delegation of validator `Val` at the biginning of the next epoch (if still available to them), and `Undelegate` subtracts the amount from the delegation of `Val` by the next epoch if available.

_optional (not needed now, but later)_

`UndelegateNow`:
The user is marked to not receive any reward from the validator in that epoch. The reward should instead go into the insurance pool. The stake is marked as free for the delegator, but is not yet removed from the validator stake (this happens at the end of the epoch).

`UndelegateInAnger`:
To unlock any stake fast, this has the same effect as `UndelegateNow`, but the stake is removed from the validator right away (at least as far as voting rights are concerned).


### Payment calculation

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

Functions:

- `score_val(stake_val)`: `sqrt(a*stake_val/3)-(sqrt(a*stake_val/3)^3)`
- `score_del(stake_del, stake_val)`: for now, this will just return `stake_del`, but will be replaced with a more complex formula later on, which deserves independent testing.
- `delegator_reward(stake_val)`: `stake_val*.1`. Long term, there will be bonuses in addition to the reward.

Once the reward for all delegators has been calculated, we end up with a slice of `Transfer`'s, transferring an amount from the infrastructure fee account into the corresponding general balances for all of the delegators. For example:

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

The transfer type informs the collateral engine that the `FromAccount` ought to be the infrastructure fee account, and the `ToAccount` is the general account for the party for the given asset. The delegator can then withdraw the amount much like they would any other asset/balance.

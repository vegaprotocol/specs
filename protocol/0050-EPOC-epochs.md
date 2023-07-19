# Epochs

To implement more stability in parameter changes (especially around staking), Vega uses
the concepts of epochs. An epoch is a time period (initially 24 hours, but changeable
via governance vote) during which changes can be announced, but will not be executed
until the next epoch (with some rare exceptions).

## Epoch Transition

The trigger to start a new epoch is blocktime. To this end, there is a
defined time when an epoch ends; the *first block after the block that
exceeds this time is the last block of its epoch*.

The length of an epoch is a [network parameter](#network-parameters). To make the chain understandable
without having to trace all system parameters, the time an epoch ends is added
to its first block. This also means that the block validity check needs to verify
that deadline.

Every epoch also has a unique identifier (i.e., a sequential number), which is also
added to the first block of the new epoch.

Rationale: Using the blocks after the deadline makes it easy to have a common agreement
on which block starts a new epoch without any guesswork on network performance. Using
the block one after means that every epoch has a defined last block, and it is possible
to put some information needed to terminate an epoch cleanly/prepare the
next epoch into that block.

Correction: As we cannot (at this point) control the block into which a particular transaction
goes, for Sweetwater the epoch changes will be done as described in the
beginning without a synchronising block: There is a time (determined by the
[network parameter](#network-parameters) `epoch_length`), when a new epoch starts. The last block in every epoch is the
first block that has a blocktime exceeding the length of its epoch, i.e., the later blocks
then go into the next epoch. In a later version we will have better control of the mempool,
and then can add a synchronising block.

## Fringe cases

 If the epoch-time is too short, then it is possible to have several epochs starting
 at the same time (say, we have 5 second epochs, and one block takes 20 seconds, thus  pushing the
 blocktime past several deadlines. While this really shouldn't happen, it can be resolved by the
 last epoch winning. This would cause issues with delay factors (e.g., a validator staying on for
 another 5 epochs after losing delegation), but as it indicates that something already is very
 wrong this should not be an issue.

 If we have an integer overflow of the epoch number, nothing overly bad should happen; even
 if we'd use normal unsigned int, with an expected epoch duration of 24h, we're all dead when
 this happens. It also shouldn't have any real effect, though (eventually) it may make sense
 to catch the overflow in the code.

 While hopefully not an issue with Golang anymore, one thing to watch out for is
 the year 2038 problem; this is a bit unrelated, but can easily hit anything that
 works on a second-basis.

## (Un)delegation

A delegator can lock a token in the smart contract, which is then available for
staking. To this end, an Vega token (or a fraction thereof) can be:

- Unlocked: The tokenholder is free to do with the token as they
	want, but cannot delegate it
- Locked: The token is locked in the smart contract, and can be used
	inside the delegation system
- Delegated: The (locked) token is delegated to a validator
- Undelegated: The token is not delegated to a validator, and can be either
	delegated or unlocked.

Any locked and undelegated stake can be delegated at any time by putting a
delegation-message on the chain. However, the delegation only becomes valid
towards the next epoch, though it can be undone through undelegate.

> **Note:** To avoid fragmentation or spam, there is a network parameter "Minimum delegateable stake"
that defines the smallest unit of (fractions of) tokens that can be used for delegation - see [Simple staking & delegating](./0059-STKG-simple_staking_and_delegating.md#network-parameters).

To delegate stake, a delegator simply puts a command "delegate x stake to y" on
the chain. It is verified at the beginning (when the command is issued and before
it is put on the chain) that the delegator has sufficient unlocked stake, as
well as in the beginning of the next epoch just before the command takes effect.
The amount of delegateable stake is reduced right away once the command is put into
a block.

As validators (will) have an optimum amount of stake they don't want to exceed,
There are three ways a delegator can undelegate:

## Undelegate towards the end of the episode

The action is announced in the next available block, but the delegator keeps
the delegation alive till the last block of the epoch. The delegator can then
re-delegate the stake, which then be valid once the next epoch starts.
The delegator cannot move the tokens before the epoch ends, they remain locked.

## Undelegate now

The action can be announced at any time and is executed immediately following the block
it is announced in. However, the stake is still counted as delegated to the validator until
the last block of the epoch, though the delegator rewards are not paid to the delegator, but
into an appropriate vega pool (the insurance pool, for example). The tokens are
released though, and the delegator can transfer their tokens in the smart contract.

Rationale: This allows a delegator to sell their tokens in a rush, without requiring
any interaction between the smart contract and the details of the delegation system.
This also allows the delegator to change their mind about a delegation before it is
activated.

## Undelegate in anger

This action is announced at any time and is executed immediately following the block it
is announced in. The delegator loses the delegated stake and the income with it, as well
as their voting weight. As this is not required for first mainnet, and involves more subtleties
(weights need to be recalculated on the fly, there may be a mixture of normal undelegated
and undelegate in anger, ...), this feature does not need to be implemented right away for
Mainnet alpha.

Rationale: A validator is found to have done something outrageous, and needs to be removed
right away.

## Undelegation of locked stake

Furthermore, the validators watch the smart contract, and observe the following actions:

- A token gets locked: This token is now available for delegation
- A token gets unlocked: If the token holder has sufficient undelegated tokens, this stake is
	used to cover the now unlocked tokens (i.e., the available amount of delegateable
	tokens is reduced to match the locking status. This could mean that the token-
	holder has a delegation-command scheduled that is no longer executable; this
	command will then be ignored at the start of the next epoch.

	If the token holder does not have sufficient undelegated stake, at first
	the validators verify if tokens are in the process of being delegated
	(i.e., the delegation command has been issued, but not yet executed), and
	uses those tokens to cover the unlocking. If this is insufficient, the
	Undelegate-now command is automatically triggered, undelegating evenly from
	all validators to cover the needs.

## Validator commands

Change wanted stake: Define a new parameter of `wanted_stake[validator]`, valid at the epoch
following the one in which the command is put into a block.

## Fringe Cases

A delegator can delegate some stake, and immediately undelegate it before the next
epoch starts. This is fine with us.

If the value of `minimum_delegateable_stake` changes in a bad way, stakers might be stuck with
some fraction they can't modify anymore. To this end, the undelegate commands also should
support a parameter "all".

With this setup, a delegator can use a constant delegation/undelegate-now to spam the network.

If several delegators change the delegation within the same block, some of them may not be allowed to
execute (as this would exceed the maximum stake the validator wants). To save resources, the
block creator has the responsibility to filter out these transactions.

## Commands

```javascript
delegate(delegator_ID, validator_ID, amount/'all')
      // delegate amount(all) undelegated stake form delegator_ID to validator_ID,
      // provided there is sufficient undelegated stake available and the value would
      // not exceed max_wanted_stake.

undelegate(delegator_ID, validator_ID, amount/'all')

undelegate_now(delegator_ID, validator_ID, amount/'all')
```

## General Fringe Cases

Due to the various parameters, we have a setting where an inconsistent view of the settings
can cause trouble - if one validator things a transaction is valid and another one does not,
this disagreement could stop the entire blockchain.
While this should not happen, it can. One example would be that different implementations use
slightly different rounding rules, or even processors with different float units coming to
different results.
My proposal here is a bit of a hack; if t+1 (or f+1 in tendermint speak) blocks in a row get
rejected due to invalid proposals with anything that could be explained through parameter
inconsistencies, the chain goes into a backup mode where parameter changes are only allowed
every n-1 th block, where n is the number of validators (thus, every delegation-related
transaction needs ot wait in mempool until the next block-number is divisible by n-1; using n-1
assures that the responsibility for these blocks still rotates between the validators).
Thus, even if the inconsistency blocks delegation related commands, the primary operation of
the chain can still go on.

In mainnet alpha this is sufficient as the chain dies relatively quickly anyhow. In later versions, we'd need a simple resync protocol (e.g., all validators put on the block what they think the parameters are; the majority of the first n-t blocks wins).

## Network Parameters

| Property         | Type   | Example value | Description |
|------------------|--------| ------------|--------------|
| `validators.epoch.length`       | String (period) |  `"1h"` | The length of each Epoch. The block after this time will be the first block of the next epoch  |

See the [network parameters spec](./0054-NETP-network_parameters.md#current-network-parameters) for a full list of parameters.

## Parameter changes

All parameters that are changed through a governance vote are valid starting the epoch following the one the block is in that finalised the vote.

## Acceptance Criteria

Epochs change at the end of the first block that is after the epoch expiry has passed:

- Given an epoch length of `x`, with a block time arbitrary but `<x`, at block 1 the current epoch is `1` (<a name="0050-EPOC-001" href="#0050-EPOC-001">0050-EPOC-001</a>)
- Given an epoch length of `x`, with a block time `x/y`, at end of block `y-1` the current epoch is `1` (<a name="0050-EPOC-002" href="#0050-EPOC-002">0050-EPOC-002</a>)
- Given an epoch length of `x`, with a block time of `x/y`, at end of block `y` the current epoch is `2` (<a name="0050-EPOC-003" href="#0050-EPOC-003">0050-EPOC-003</a>)
  
Edge case: Multiple epochs can pass within the same block (<a name="0050-EPOC-004" href="#0050-EPOC-004">0050-EPOC-004</a>):

- Given an epoch length of `x`, with a block time of `x*y`, at end of block 1 the current epoch is `1`
- Given an epoch length of `x`, with a block time of `x*y`, at end of block `y+1` the current epoch is `y+1`

Nomination takes effect at epoch changeover:

- During epoch 1, `party 1` nominates any valid amount to `validator 1`
  - `party 1`s staking balanced is reduced immediately upon execution of the transaction (<a name="0050-EPOC-005" href="#0050-EPOC-005">0050-EPOC-005</a>)(note: this can be tested by trying to delegate again, which will be rejected)
  - `validator 1`s nominated balance is not increased in epoch 1 (<a name="0050-EPOC-006" href="#0050-EPOC-006">0050-EPOC-006</a>)
  - `validator 1`s nominated balance is increased in the first block of epoch 2 (<a name="0050-EPOC-007" href="#0050-EPOC-007">0050-EPOC-007</a>)

## See also

- [0059 - STKG - Simple staking and delegating](./0059-STKG-simple_staking_and_delegating.md) - staking and delegation are both calculated in terms of epochs.

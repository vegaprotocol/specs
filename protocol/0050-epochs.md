
To implement more stability in parameter changes (especially around staking), Vega uses
the concepts of epochs. An epoch is a time period (initially 24 hours, but changeable
via governance vote) during which changes can be announced, but will not be executed
until the next epoch (with some rare exceptions).

# Episode Transition

The trigger to start a new episode is blocktime. To this end, there is a
defined time when an epoch ends; the first block after the block that
exceeds this time is the last block of its epoch.

The length of an epoch is a system parameter. To make the chain understandable
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

Options: We could make it a system parameter how many blocks after the deadline the epoch starts
 if we need more space to reconfigure/close an epoch. This can be added through a software update
 at a later point if needed.

## Fringe cases
 If the epoch-time is too short, then it is possible to have several epochs starting
 at the same time (say, we have 5 second epochs, and one block takes 20 seconds, thus  pushing the
 blocktime past several deadlines. While this really shouldn't happen, it can be resolved by the 
 last epoch winning. This would cause issues with delay factors (e.g., a validator staying on for
 another 5 epochs after loosing delegation), but as it indicates that something already is very
 wrong this should not be an issue. 

 If we have an integer overflow of the epoch number, nothing overly bad should happen; even
 if we'd use normal unsigned int, with an expected epoch duration of 24h, we're all dead when 
 this happens. It also shouldn't have any real effect, though (eventually) it may make sense 
 to catch the overflow in the code.
 
 While hopefully not an issue with golang anymore, one thing to watch out for is
 the year 2038 problem; this is a bit unrelated, but can easily hit anything that
 works on a second-basis.

## Parameter changes
 All parameters that are changed through a governance vote are valid starting the 
 episode following the one the block is in that finalized the vote.

## Parameters 
	Epoch length (in seconds)

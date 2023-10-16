# Validator performance based rewards

## Network Parameters
1. `ethereum_heartbeat_period`: This parameter defines how many ethereum events need to pass (in average) for a validator to have to forward a heartbeat event. If it is set to 0, heartbeats are deactivated.
Valid range is any integer >= 0
The initial value is 128.

1. `performance_weights` is a vector containing three integer values w0,w1,w2; this parameter defines the weights of the different performance measurements that impact the reward. The weight formular (given performance valuies p1 and p2) is w0*p1*p2 + w1*p1+w2*p2). 
If more performance measurements are added later, this vector is expanded correspondingy.

Legal values are all floats that sum up to 1. The initial value is (0,0.8,0.2)

## Adjusting Validator Rewards Based on Performance

The Vega chain is a delegated proof-of-stake based chain where validators are rewarded from fees generated or from on-chain treasury.

The rewards are based on their own stake and the amount of stake delegated to them,
see [validator rewards](./0061-REWP-pos_rewards.md), as well as their performance score.

The purpose of the specification is to define how the validator rewards will be additionally scaled based on their performance.

## Performance Measurement 1 (`PM1`): Offline Validator (sufficient for Oregon Trail)

### Tendermint validators

Goal 1: Detect how long a validator is offline and punish them
Detection: Validator does not act as a leader

For each block tendermint provides information about who is the proposer. The selection of the proposer is deterministic and is proportional roughly to the voting power of the validator. Therefore we can calculate the performance of a validator in the following way:

let `p` be the number of times the validator proposed blocks in the previous epoch
let `b` be the number of blocks in the previous epoch
let `v` be the voting power of the validator in the previous epoch
let `t` be the total voting power in the previous epoch

let `expected_p = v*b/t` the number of blocks we expected the validator to propose. This
is the number of blocks in which the validator can be expected to be chosen as a leader

The number of blocks a validators is considered to have succeeded in proposing is scaled to allow for
easier testing using the network parameters `minBlocksTolerance` and `validators.performance.scalingfactor`, i.e.,
`p' = p + max(minBlocksTolerance, p * validators.performance.scalingfactor`)

This function is primarily for testing purposes to allow for very short epochs without triggering
odd effects due to lack of time for performances to average out; for mainnet, the parameters should not
be modified and set to neutral defaults (i.e., 0)

The calculation only based on this would be `validator_performance = max(0.05, min((p'/expected_p, 1))`; however
another factor is added:

Goal 2: Detect unforwarded Ethereum events and punish the validator that does not forward them
Detection: Events forwarded by some validators are not forwarded by others.

#### Ethereum Heartbeat
For the Ethereum Heartbeat, we use the network parameter `ethereum_heartbeat_period`. This parameter should be either 0 or a value bigger than the number of validators; the recommended initial value is 128, which would create a hearbeat per validator about every 20 minutes (i.e., about 120 heartbeats per validator per epoch). Legal values are all integers larger or equal to 0.

For every Ethereum block, if the hash of this block mod `ethereum_heartbeat_period` equals the identity of the a validator (taken mod ethereum_heartbeat_period)+1, then this validator has to forward this as an Ethereum event. This event is confirmed by other validators just like any other Ethereum event, but then ignored. If that block also contains a valid Vega event that requires an action, this is forwarded independently by the normal event forwarding mechanisms.
If the parameter is set to 0, the heartbeats are effectively turned off.

#### Ethereum Read Access Heartbeat
For every Ethereum block, if the hash of [The balance of the key that initiated the first transaction on the block / the randao value of that block] mod `ethereum_heartbeat_period` equals the identity of the a validator (taken mod ethereum_heartbeat_period)+1, then this validator has to forward this as an Ethereum event. This event is confirmed by other validators just like any other Ethereum event, but then ignored. If that block also contains a valid Vega event that requires an action, this is forwarded independently by the normal event forwarding mechanisms.


#### Performance Measurements
At the end of each epoch, it is counted how many Ethereum events have been forwarded by each validator; this is (number_of_ethereum_blocks_per_epoch)/`ethereum_heartbeat_period`)+number_of_ethereum_events_per_validator

Let `expected_f` be the maximum number of Ethereum events forwarded by any Validator given above conditions, and `f` be the number of blocks a given validator has forwarded. If `expected_f` equals zero, then all scores are set to 1. 
Let `low_volume_correction` be `abs(3-expected_f)`.

Else, validator_ethereum_performance = `(min((f+low_volume_correction)/(expected_f)*1.1, 1)))`,

Explanation: low_volume_correction handle the case that the number of events is very low, and a validator might just by bad luck never get anything to forward (which also would only happen if the heartbeat is deactivated). Thus, if a validator is expected to forward 2 or less events, it is not penalised if it didn't forward any.
The multiplication with 1.1 is adding preventing a validator to get penalised if they got slightly less than others (which always can happen due to the random distribution). Thus, a validator that forwards 95% of the events that others do is not penalised. We could get more precision here (differentiating between the heartbeat and the expected real events etc), but that'd be overthinking. 
In the end, we make sure no score is bigger than 1 (which might happen due to the multiplicative bonus).

### Total Performance
As we have several performance measurements, they need to be combined to a total score. To this end, we have a system variable `performance_weights`, 
which has n+1 parameters (weight_0,.. weight_n) for n measurements (currently 2, the tendermint-performance and the ethereum-performance. Weights are normalised, so the sum of all weights needs to be 1. Also, all individual performance measurements are normalised to be between 0 and 1.

The total performance then is
`weight_0*(validator_ethereum_performance*validator_tendermint_performance)+weight_1*(validator_tendermint_performance)+weight_2*(validator_ethereum_performance)`

The initial values for the weights are {0,0.8,0.2}.

### Ersatz and pending validators

For validators who [have submitted a transaction to become validators](./0069-VCBS-validators_chosen_by_stake.md) the `performance_score` is defined as follows: during each epoch
Let `numBlocks = max(min(50, epochDurationSeconds), epochDurationSeconds x 0.01)`.
Every `numBlocks` blocks the candidate validator node is to send a hash of block number `b` separately signed by all the three keys and submitted; the network will verify this to confirm that the validator owns the keys.
Here `b` is defined as:
First time it is the block number in which the joining transaction was included. Then it's incremented by `numBlocks`.
The network will keep track of the last `10` times this was supposed to happen and the `performance_score` is the number of times this has been verified divided by `10`.
The message with the signed block hash must be in blocks `b + numBlocks` to `b + numBlocks + 10` to count as successfully delivered.
Initially the performance score is set to `0`.
Both Tendermint validators and pending validators should be signing and sending these messages but only for the pending validators does this impact their score.

The performance score should be available on all the same API endpoints as the `validatorScore` from [validator rewards](./0061-REWP-pos_rewards.md).

## Acceptance criteria

### Performance score

1. Tendermint validator with insufficient self-delegation (<a name="0064-VALP-001" href="#0064-VALP-001">0064-VALP-001</a>):
    - Set up a network with 5 validators
    - Self-delegate to 4 of the nodes **more** than the minimum amount set in `reward.staking.delegation.minimumValidatorStake`.
    - Self-delegate to the 5th node **less** than the minimum amount.
    - Verify that at the beginning of the next epoch the performance score of the 5th validator is 0.
1. Tendermint validator with sufficient self-delegation (<a name="0064-VALP-002" href="#0064-VALP-002">0064-VALP-002</a>):
    - Setup a network with 5 validators.
    - Self-delegate to all of them more than the minimum required.
    - Verify that after an epoch has passed, the performance score of all of them is close to 1.
1. Tendermint validator down (<a name="0064-VALP-003" href="#0064-VALP-003">0064-VALP-003</a>):
    - Setup a network with 5 validators.
    - Self-delegate to all of them more than the minimum required in `reward.staking.delegation.minimumValidatorStake` and ensure the validators self-stake is an equal amount across all.
    - Run the network for one epoch.
    - Verify the performance score is close to 1 for all validators.
    - Run the network for half an epoch then shut down validator 5.
    - Verify that at the beginning of the next epoch the performance score for validator 5 is close to 0.5.
    - Verify that, with validator 5 still down for the next epoch, at the beginning of the following epoch the performance score for validator 5 is 0.
1. Non Tendermint validator (<a name="0064-VALP-004" href="#0064-VALP-004">0064-VALP-004</a>):
    - Set the network parameter `network.validators.minimumEthereumEventsForNewValidator` to 0.
    - Setup a network with 5 validators and self-delegate to them.
    - Announce a new node to the network and self-delegate to them.
    - Every `numBlocks` blocks (*where `numBlocks = max(min(50, epochDurationSeconds), epochDurationSeconds x 0.01)`*) the performance score of the new validator should go up by 0.1 until it reaches the maximum of 1.
    - Verify that after enough epochs to represent at least 1000 blocks, the performance score of the joining validator is 0.1.
    - Let the network run for `numBlocks` blocks (*where `numBlocks = max(min(50, epochDurationSeconds), epochDurationSeconds x 0.01)`*) more and at the following epoch check that score is up to 0.2. Keep it running until its performance score of the joining validator reaches 1, then stop it.
    - Verify that for every `numBlocks` blocks (*where `numBlocks = max(min(50, epochDurationSeconds), epochDurationSeconds x 0.01)`*), the performance score should go down by 0.1 until it reaches zero.
    - **Note:** Every `numBlocks`  the performance score should go up by 0.1. Now the performance score is only visible every epoch so depending on the ratio between `numBlocks`  and epoch duration it may tick once or more per epoch. Guidance is that this test should either be parameterised or, preferably, written with a given epoch duration
1. Insufficient stake (<a name="0064-VALP-005" href="#0064-VALP-005">0064-VALP-005</a>):
    - Setup a network with 5 validators, self-delegate to each more than the required minimum as set out in `reward.staking.delegation.minimumValidatorStake`.
    - Verify that at the beginning of the next epoch the validator has non 0 performance score, and voting power is greater than 10.
    - Update the network parameter `reward.staking.delegation.minimumValidatorStake` for minimum self-stake to be more than is self-delegated.
    - Verify that, at the beginning of the next epoch, all performance scores are 0 and voting power for all is 1 but the network keeps producing blocks and no nodes were removed from Tendermint.
1. Scores are restored after a snapshot restart (<a name="0064-VALP-006" href="#0064-VALP-006">0064-VALP-006</a>):
    - With a snapshot that was taken at a block-height that falls in the middle of an epoch, restart a node from that snapshot. Ensure that at the end of the epoch the node remains in consensus and has produced the correct performance scores.

## Future Stuff (in here for discussion purposes, not yet to be implemented)

### Non Linear punishment

Currently, `PM1` does a linear reduction of payment - maybe an s-curve would be better so that small violations are punished less,
while a validator that is offline half the time gets more than 50% subtraction. For example, 1/(1+2^((3*x-1)*10)) would punish
small failures less, and bigger failures pretty radically.

### Weight reduction

In addition, for every epoch for which a node was offline, we can decrease its tendermint weight by 10%. Permanently absent nodes thus are
automatically reduced in influence, even if they have a lot of delegation. Note that this may increase the discrepancy between the voting weight on
tendermint and the voting weight on the multisig contract.

Acceptance Criteria:

Set up a network with 4 validators, an <ethereum _heartbeat_period> of 0.  Run the network for 2 epochs and test that no events are
Forwarded by any validator. (<a name="0064-COSMICELEVATOR-001” href="#0064-COSMICELEVATOR-001”>0064-COSMICELEVATOR-001</a>)

Set up a network with 4 validators, an <ethereum_heartbeat_period> of 13. Run the network for 2 epochs and verify that each validator
forwards roughly 1 event for each two minutes of epoch length. (<a name="0064-COSMICELEVATOR-002” href="#0064-COSMICELEVATOR-002”>0064-COSMICELEVATOR-002</a>)


Set up a network with 4 validators, and deactivate ethereal event forwarding for one of them.  Set the < ethereum_heartbeat_periood> to 13.
Set <performance_weights> to <0.0, 0.8, 0.2>. Verify that the non-performing validator gets 20% less reward than the others. (<a name="0064-COSMICELEVATOR-003” href="#0064-COSMICELEVATOR-003”>0064-COSMICELEVATOR-003</a>)


Set up a network with 4 validators, and deactivate ethereal event forwarding for one of them.  Set the < ethereum_heartbeat_periood> to 13.
Set <performance_weights> to <0.4, 0.4, 0.2>. Verify that the non-performing validator gets 40% of the reward of the others. (<a name="0064-COSMICELEVATOR-004” href="#0064-COSMICELEVATOR-004”>0064-COSMICELEVATOR-004</a>)


Set up a network with 4 validators, and deactivate ethereal event forwarding for one of in the middle of an epoch.  Set the 
<ethereum_heartbeat_periood> to 13. Set <performance_weights> to <0.4, 0.4, 0.2>. Verify that the non-performing validator 
gets 30% less reward than the others. (<a name="0064-COSMICELEVATOR-005” href="#0064-COSMICELEVATOR-005”>0064-COSMICELEVATOR-005</a>)

## `PM2`: Validator does not verify signatures

To detect this, validators need to issue tagged signatures from time to time.
The tagged signature is the original signed message with the tag [TAGGED] associated to it. Thus, the normal signature verification for message m will fail, and the verifier is supposed to verify m|”TAGGED”. The verifier is then required  (if using this signature to validate anything) to flag that the signature pool contains a tagged signature and which one it is. Failure to do so provably shows that the signature was not verified properly.

## `PM3`: Validator does not run event forwarder

This is difficult to detect, as a validator may legitimately see Ethereum events a few seconds after other validators and thus never get an event to forward. Also, eventually EEF will be integrated into core, and thus it will be more effort to not run that part of the code.
Idea: A validator that forwarded less than 50% of the events of the other validators gets malus on the reward, provided the median validator forwarded at least 100 events in that epoch.
A validator that forwards no event in an epoch gets a bigger punishment, given the same constraint.

Median is chosen so that a single validator can’t frame the others by shortening the Ethereum
Block confirmation times.

Should we instead have additional rewards for forwarding events from Ethereum? For each validator we could keep a count of how many events they forwarded first (and that got approved by the others), call this `f` and we also know the total number `n` for an epoch.
If we had another reward pool we could share it according to `f/n`.

## `PM5`: Validator only acts as a Tendermint leader

Finding this requires a statistic we don't have at this point (as we would like to also include messages that were sent but don't contribute to consensus anymore to avoid discriminating against geographically far away servers. Once we figured out how to do this, we can build a formula for the reward.

## `PM6`: Validator doesn't run the Vega app, just signs everything the others do

This needs further investigation; it is probably possible to solve this either the
same way we detect signature verification, or along the lines of the data-node
(i.e., Validators are required to post some internal state information from time to
time that they only have if they run the protocol)



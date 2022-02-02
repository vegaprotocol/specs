# Adjusting Validator Rewards Based on Performance

The Vega chain is a delegated proof-of-stake based chain where validators are rewarded from fees generated or from on-chain treasury. 
The rewards are based on their own stake and the amount of stake delegated to them, 
see [validator rewards](./0061-REWP-simple_pos_rewards_sweetwater.md).
The purpose of the specification is to define how will the validator rewards will be additionally scaled based on their performance. 

## Performance Measurement 1 (PM1): Offline Validator (sufficient for Oregon Trail)
Goal: Detect how long a validator is offline and punish them 
Detection: Validator does not act as a leader

Tendermint provides a statistic on failed blocks, i.e., validators that did not act properly as a leader.
Over an epoch, the number of such failures `f` is counted, as well as the number of times the validator 
was elected leader `l` and carried out the job.

To be more precise: Tendermint emits an event for every round of proposal at a given height, so we know who the proposer should have been. It also emits an event with a timeout for the height of the round so we can tell that the node wasn't available. 
This counts need to be stored, per validator node, in vega core. 

For validators participating in consensus (Tendermint validators) define the performance score to be `performance_score := max[(l-f)/l, 0.05]` if `l > 0` and `performance_score = 1` if `l = 0`. 
Flooring the score at `0.05` is there to make sure that every validator with non-zero own+delegated gets a chance to be a leader at least occasionally, even if they were poorly performing recently. 

For validators who [have submitted a transaction to become validators](./0069-VCBS-validators_chosen_by_stake.md) the `performance_score` is defined as follows: during each epoch
Every `1000` blocks the candidate validator node is to send a hash of block number `b` separetely signed by all the three keys and submitted; the network will verify this to confirm that the validator owns the keys. 
Here `b` is defined as:
First time it is the the block number in which the joining transaction was included. Then it's incremented by `1000`. 
The network will keep track of the last `10` times this was supposed to happen and the `performance_score` is the number of times this has been verified divided by `10`.  
The message with the signed block hash must be in blocks `b+1000` to `b+1010` to count as successfully delivered.  
Initially the performance score is set to `0`.
Both Tendermint validators and candidate validators should be signing and sending these messages but only for the candidate validators does this impact their score.


The performance score should be available on all the same API enpoints as the `validatorScore` from [validator rewards](./0061-REWP-simple_pos_rewards_sweetwater.md).

### Acceptance criteria 

# Scenario 1: (<a name="0064-VALP-001" href="#0064-VALP-001">0064-VALP-001</a>)
1. Configure and launch a network with 5 validators
1. Give each validator self-stake of 10 000 VEGA. Set epoch length to 10 minutes.
1. Deposit a 1000 VEGA into the validator reward pool.
1. After epoch ends (epoch 0), observe that the 1000 VEGA are split accordingly to the `performance_score` reported (should be roughly 200 VEGA each but not necessarily exactly). Anything between 180 and 220 per validator would be considered acceptable. 
1. Bring one node down.
1. Wait for another epoch to end (epoch 1).
1. Deposit another 1000 VEGA into the validator reward pool.
1. After epoch ends (epoch 2), observe that the 1000 VEGA are split accordingly to the `performance_score` reported. This should be roughly 250 VEGA for each of the running validators, anything between 225 and 275 VEGA is acceptable. It should be exactly 0 for the validator that was brought down.




































# Future Stuff (in here for discussion purposes, not yet to be implemented)

# Non Linear punishment
Currently, PM1 does a linear reduction of payment - maybe an s-curve would be better so that small violations are punished less, 
while a validator that is offline half the time gets more than 50% substraction. For example, 1/(1+2^((3*x-1)*10)) would punish
small failures less, and bigger failures pretty radically.

#Weight reduction
In addition, for every epoch for which a node was offline, we can decrease its tendermint weight by 10%. Permanently absent nodes thus are
automatically reduced in influence, even if they have a lot of delegation. Note that this may increase the discrepancy between the voting weight on 
tendermint and the voting weight on the multisig contract.

# PM2: Validator does not verify signatures
To detect this, validators need to issue tagged signatures from time to time.
     The tagged signature is the original signed message with the tag [TAGGED] associated to it.
     Thus, the normal signature verification for message m will fail, and the verifier is supposed
     to verify m|”TAGGED”
     The verifier is then required  (if using this signature to validate anything) to flag that
      The signature pool contains a tagged signature and which one it is.
      Failure to do so provably shows that the signature was not verified properly.
      
 # PM3: Validator does not run event forwarder
 This is difficult to detect, as a validator may legitimatelly see Ethereum events a few seconds after other validators
 and thus never get an event to forward. Also, eventually EEF will be integrated into core, and thus it will be more
 effort to not run that part of the code.
Idea: A validator that forwarded less than 50% of the events of the other validators
   gets malus on the reward, provided the median validator forwarded at least 100 events
   in that epoch.
A validator that forwards no event in an epoch gets a bigger punishment, given the same constraint.

Median is chosen so that a single validator can’t frame the others by shortening the Ethereum
Block confirmation times.

Should we instead have additional rewards for forwarding events from Ethereum? For each validator we could keep a count of how many events they forwarded first (and that got approved by the others), call this `f` and we also know the total number `n` for an epoch. 
If we had another reward pool we could share it according to `f/n`. 


# PM5: Validator only acts as a Tenderint leader.
Finding this requires a statistic we don't have at this point (as we would like to also include messages that were sent but don't contribute to consensus anymore to avoid discriminating against geographically far away servers. Once we figured out how to do
this, we can build a formula for the reward. 

# PM6: Validator doesn't run the Vega app, just signs everything the others do.
This needs further investigation; it is probably possible to solve this either the
same way we detect signature verification, or along the lines of the data-node 
(i.e., Validators are required to post some internal state information from time to
time that they only have if they run the protocol)


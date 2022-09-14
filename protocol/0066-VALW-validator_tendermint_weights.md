# Validator Tendermint Weights

Vega is running a delegated proof of stake blockchain based on Tendermint. 

For each validator node Tendermint keeps the "weight" of the node for consensus purposes. This spec clarifies how such weight is calculated on Vega. 

On Vega the voting power is calcualted as follows: `stakeScore x performanceScore` normalised by the sum of those scores. Where `stakeScore` is defined as the anti-whaling stake score of tendermint validators and performance score is the proportion of successful proposals of the validator normalised to their voting power. 

The weights should be updated every epoch.

The minimum voting power for a non-empty network is 1 (0 implies that the validator is removed from the network).

If the network has no stake at all, then all validators would have equal voting power of 10. 
## Acceptance criteria 

### Basic sanity check (<a name="0066-VALW-001" href="#0066-VALW-001">0066-VALW-001</a>)
1. set up a network with 5 validators 
2. give each of the validators the following number of self-staked tokens: `2000`
3. wait for the delegation to become active in the next epoch
4. when the epoch begins verify that the delegation went through


### Non-uniform stake check (<a name="0066-VALW-002" href="#0066-VALW-002">0066-VALW-002</a>)
1. set up a network with 5 validators
2. give the first `4` validators `1000` of self-stake each. Give the last validator `500`. 
3. wait for the delegation to become active in the next epoch


### Zero stake check  (<a name="0066-VALW-003" href="#0066-VALW-003">0066-VALW-003</a>)
1. set up a network with 5 validators
2. give the first `4` validators `1000` of self-stake each. Give the last validator `0`. 
3. wait for the delegation to become active in the next epoch


### Changes to delegation during the epoch are reflected in the next epoch’s voting power (<a name="0066-VALW-004" href="#0066-VALW-004">0066-VALW-004</a>)
1. set up a network with 5 validators
2. give the first `4` validators `1000` of self-stake each. Give the last validator `0`. 
3. wait for the delegation to become active in the next epoch
5. check that Tendermint weights
6. just before epoch 0 ends the last validator self-stakes `500`. 
7. epoch 1 starts 
5. check that Tendermint weights

### Sanity check if everyone unstakes and undelegates (<a name="0066-VALW-005" href="#0066-VALW-005">0066-VALW-005</a>)
1. set up a network with 5 validators
2. give each of the validators the following number of self-staked tokens: `2000`
3. wait for the delegation to become active in the next epoch
4. check that Tendermint weights for the validators are `2000`
5. now every validator removes (via undelegate now) their stake and there are no delegations from other parties
6. wait for 1000 blocks to pass
7. the Tendermint weights for each validator are `10` each as there is no stake in the network. 

### Validator has 1000 stake but 500 delegated (<a name="0066-VALW-006" href="#0066-VALW-006">0066-VALW-006</a>)
1. set up a network with 5 validators
2. give each of the validators the following number of self-staked tokens: `1000`
3. delegate to all validators `500` tokens`
4. wait for the delegation to become active in the next epoch
5. check that Tendermint weights 

### Validators without self-delegated, check  (<a name="0066-VALW-007" href="#0066-VALW-007">0066-VALW-007</a>)
1. set up a network with 5 validators
2. give each of the validators the following number of self-staked tokens: `0`
3. For several parties create stake and delegate to validators
4. wait for the delegation to become active in the next epoch
5. check the Tendermint weights 

### Validators delegating to other validators (<a name="0066-VALW-008" href="#0066-VALW-008">0066-VALW-008</a>)
1. set up a network with 5 validators
2. give each of the validators the following number of self-staked tokens: `1000`
3. delegate for the first `4` validators `1000` and from the 5th validator delegate `1000` to the 1st validator
4. wait for the delegations to become active in the next epoch
5. check the Tendermint weights across all validators

### Validator delegate and undelegate in the same epoch (<a name="0066-VALW-009" href="#0066-VALW-009">0066-VALW-009</a>)
1. set up a network with 5 validators
2. give each of the validators the following number of self-staked tokens: `1000`
3. delegate in the same epoch
4. undelegate all in the same epoch
6. wait for the next epoch
7. Check that Tendermint weights whereby validators would have equal voting power of 10


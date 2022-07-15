# Validator Tendermint Weights

Vega is running a delegated proof of stake blockchain based on Tendermint. 

For each validator node Tendermint keeps the "weight" of the node for consensus purposes. This spec clarifies how such weight is calculated on Vega. 

On Vega the voting power is calcualted as follows: `stakeScore x performanceScore` normalised by the sum of those scores. Where `stakeScore` is defined as the anti-whaling stake score of tendermint validators and performance score is the proportion of successful proposals of the validator normalised to their voting power. 

There is a parameter <TENDERMINT_META_WEIGHT>) which is between 1 and 0; The actual voting weight passed to Tendermint is 
 max (<TENDERMINT_META_WEIGHT>*voting_power), 1).

If <Tendermint_META_WEIGHT> is set to 0, then the weights are effectively turned of.


The weights should be updated every `1000` blocks and every epoch (whichever passes first).

The minimum voting power for a non-empty network is 1 (0 implies that the validator is removed from the network).

If the network has no stake at all, then all validators would have equal voting power of 10. 
## Acceptance criteria 

### Basic sanity check (<a name="0066-VALW-001" href="#0066-VALW-001">0066-VALW-001</a>)
1. set up a network with 5 validators 
1. give each of the validators the following number of self-staked tokens: `2000`
1. wait for the delegation to become active in the next epoch
1. when the epoch begins verify that the delegation went through
1. check that Tendermint weights for the validators are `2000`

### Non-uniform stake check (<a name="0066-VALW-002" href="#0066-VALW-002">0066-VALW-002</a>)
1. set up a network with 5 validators
1. give the first `4` validators `1000` of self-stake each. Give the last validator `500`. 
1. wait for the delegation to become active in the next epoch
1. check that Tendermint weights for the first `4` validators are `2222` and the last validator `1111`. 

### Zero stake check  (<a name="0066-VALW-003" href="#0066-VALW-003">0066-VALW-003</a>)
1. set up a network with 5 validators
1. give the first `4` validators `1000` of self-stake each. Give the last validator `0`. 
1. wait for the delegation to become active in the next epoch
1. check that Tendermint weights for the first `4` validators are `2500` and the last validator `1`. 

### Update at the start of epoch check (<a name="0066-VALW-004" href="#0066-VALW-004">0066-VALW-004</a>)
1. set up a network with 5 validators
1. give the first `4` validators `1000` of self-stake each. Give the last validator `0`. 
1. wait for the delegation to become active in the next epoch
1. wait for 1000 blocks to pass
1. check that Tendermint weights for the first `4` validators are `2500` and the last validator `1`. 
1. just before epoch 0 ends the last validator self-stakes `500`. 
1. epoch 1 starts 
1. it's not yet been 1000 blocks from when the last validator self-staked but we see that Tendermint weights for the first `4` validators are `2222` and the last validator `1111`. 

### Sanity check if everyone unstakes and undelegates (<a name="0066-VALW-005" href="#0066-VALW-005">0066-VALW-005</a>)
1. set up a network with 5 validators
1. give each of the validators the following number of self-staked tokens: `2000`
1. wait for the delegation to become active in the next epoch
1. check that Tendermint weights for the validators are `2000`
1. now every validator removes (via undelegate now) their stake and there are no delegations from other parties
1. wait for 1000 blocks to pass
1. the Tendermint weights for each validator are `10` each as there is no stake in the network. 

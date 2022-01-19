# Validator Tendermint Weights

Vega is running a delegated proof of stake blockchain based on Tendermint. 

For each validator node Tendermint keeps the "weight" of the node for consensus purposes. This spec clarifies how such weight is calculated on Vega. 

On Vega the weight should be the `validatorScore` defined in the  [validator reward calculation](./0061-REWP-simple_pos_rewards_sweetwater.md).

The weights should be updated every `1000` blocks and every epoch (whichever passes first).

## Acceptance criteria 

### Basic sanity check (<a name="0066-VALW-001" href="#0066-VALW-001">0066-VALW-001</a>)
1. set up a network with 5 validators 
1. give each of the validators the following number of self-staked tokens: `2000`
1. wait for 1000 blocks to pass
1. check that Tendermint weights for the validators are `2000`

### Non-uniform stake check (<a name="0066-VALW-002" href="#0066-VALW-002">0066-VALW-002</a>)
1. set up a network with 5 validators
1. give the first `4` validators `1000` of self-stake each. Give the last validator `500`. 
1. wait for 1000 blocks to pass
1. check that Tendermint weights for the first `4` validators are `2222` and the last validator `1111`. 

### Zero stake check  (<a name="0066-VALW-003" href="#0066-VALW-003">0066-VALW-003</a>)
1. set up a network with 5 validators
1. give the first `4` validators `1000` of self-stake each. Give the last validator `0`. 
1. wait for 1000 blocks to pass
1. check that Tendermint weights for the first `4` validators are `2500` and the last validator `0`. 

### Update at the start of epoch check (<a name="0066-VALW-004" href="#0066-VALW-004">0066-VALW-004</a>)
1. set up a network with 5 validators
1. give the first `4` validators `1000` of self-stake each. Give the last validator `0`. 
1. wait for 1000 blocks to pass
1. check that Tendermint weights for the first `4` validators are `2500` and the last validator `0`. 
1. just before epoch 0 ends the last validator self-stakes `500`. 
1. epoch 1 starts 
1. it's not yet been 1000 blocks from when the last validator self-staked but we see that Tendermint weights for the first `4` validators are `2222` and the last validator `1111`. 

### Sanity check if everyone unstakes and undelegates (<a name="0066-VALW-005" href="#0066-VALW-005">0066-VALW-005</a>)
1. set up a network with 5 validators
1. give each of the validators the following number of self-staked tokens: `2000`
1. wait for 1000 blocks to pass
1. check that Tendermint weights for the validators are `2000`
1. now every validator removes (via undelegate now) their stake and there are no delegations from other parties
1. wait for 1000 blocks to pass
1. the Tendermint weights for each validator are `10` each. 



# Validator Tendermint Weights

Vega is running a delegated proof of stake blockchain based on Tendermint.

For each validator node Tendermint keeps the "weight" of the node for consensus purposes. This spec clarifies how such weight is calculated on Vega.

On Vega the voting power is calculated as follows: `stakeScore x performanceScore` normalised by the sum of those scores. Where `stakeScore` is defined as the anti-whaling stake score of tendermint validators and performance score is the proportion of successful proposals of the validator normalised to their voting power.

The weights should be updated every epoch.

The minimum voting power for a non-empty network is 1 (0 implies that the validator is removed from the network).

If the network has no stake at all, then all validators would have equal voting power of 10.

## Acceptance criteria

### Basic sanity check (<a name="0066-VALW-001" href="#0066-VALW-001">0066-VALW-001</a>)

1. set up a network with 5 validators
1. give each of the validators the following number of self-staked tokens: `2000`
1. wait for the delegation to become active in the next epoch
1. when the epoch begins verify that the delegation went through
1. check that Tendermint weights as follows:
    - Node 1 n[`stakedByOperator`]='2000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2066\
    - Node 2 n[`stakedByOperator`]='2000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2066\
    - Node 3 n[`stakedByOperator`]='2000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2066\
    - Node 4 n[`stakedByOperator`]='2000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2066\
    - Node 5 n[`stakedByOperator`]='2000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=1735

### Non-uniform stake check (<a name="0066-VALW-002" href="#0066-VALW-002">0066-VALW-002</a>)

1. set up a network with 5 validators
1. give the first `4` validators `1000` of self-stake each. Give the last validator `500`.
1. wait for the delegation to become active in the next epoch
1. check that Tendermint weights as follows:
    - Node 1 n[`stakedByOperator`]='500000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=1047\
    - Node 2 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2092\
    - Node 3 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2383\
    - Node 4 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2092\
    - Node 5 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2383

### Zero stake check  (<a name="0066-VALW-003" href="#0066-VALW-003">0066-VALW-003</a>)

1. set up a network with 5 validators
1. give the first `4` validators `1000` of self-stake each. Give the last validator `0`.
1. wait for the delegation to become active in the next epoch
1. check that Tendermint weights as follows:
    - Node 1 n[`stakedByOperator`]='0' n[`stakedByDelegates`]='0' `n_voting_power`=1\
    - Node 2 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2419\
    - Node 3 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2419\
    - Node 4 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2419\
    - Node 5 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' ``n_voting_power``=2741

### Changes to delegation during the epoch are reflected in the next epoch’s voting power (<a name="0066-SP-VALW-004" href="#0066-SP-VALW-004">0066-SP-VALW-004</a>)

1. set up a network with 5 validators
1. give the first `4` validators `1000` of self-stake each. Give the last validator `0`.
1. wait for the delegation to become active in the next epoch
 check that Tendermint weights
    - Node 1 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2606\
    - Node 2 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2393\
    - Node 3 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2606\
    - Node 4 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2393\
    - Node 5 n[`stakedByOperator`]='0' n[`stakedByDelegates`]='0' `n_voting_power`=1
1. just before epoch 0 ends the last validator self-stakes `500`.
1. epoch 1 starts
1. check that Tendermint weights as follows:
    - Node 1 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2556\
    - Node 2 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2248\
    - Node 3 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2564\
    - Node 4 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2564\
    - Node 5 n[`stakedByOperator`]='500000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=64

### Sanity check if everyone unstakes and undelegates (<a name="0066-VALW-005" href="#0066-SP-VALW-005">0066-SP-VALW-005</a>)

1. set up a network with 5 validators
1. give each of the validators the following number of self-staked tokens: `2000`
1. wait for the delegation to become active in the next epoch
1. check that Tendermint weights for the validators are s follows:
    - Node 1 n[`stakedByOperator`]='2000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2030\
    - Node 2 n[`stakedByOperator`]='2000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=1879\
    - Node 3 n[`stakedByOperator`]='2000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2030\
    - Node 4 n[`stakedByOperator`]='2000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2030\
    - Node 5 n[`stakedByOperator`]='2000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2030
1. now every validator removes (via undelegate now) their stake and there are no delegations from other parties
1. wait for 1000 blocks to pass
1. the Tendermint weights for each validator are `10` each as there is no stake in the network.

### Validator has 1000 stake but 500 delegated (<a name="0066-VALW-006" href="#0066-VALW-006">0066-VALW-006</a>)

1. set up a network with 5 validators
1. give each of the validators the following number of self-staked tokens: `1000`
1. delegate to all validators `500` tokens`
1. wait for the delegation to become active in the next epoch
1. check that Tendermint weights as follows:
    - Node 1 n[`stakedByOperator`]='500000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2033\
    - Node 2 n[`stakedByOperator`]='500000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2069\
    - Node 3 n[`stakedByOperator`]='500000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2033\
    - Node 4 n[`stakedByOperator`]='500000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2033\
    - Node 5 n[`stakedByOperator`]='500000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=1830

### Validators without self-delegated, check  (<a name="0066-VALW-007" href="#0066-VALW-007">0066-VALW-007</a>)

1. set up a network with 5 validators
1. give each of the validators the following number of self-staked tokens: `0`
1. For several parties create stake and delegate to validators
1. wait for the delegation to become active in the next epoch
1. check the Tendermint weights as follows:
    - Node 1 n[`stakedByOperator`]='0' n[`stakedByDelegates`]='1000000000000000000' `n_voting_power`=1415\
    - Node 2 n[`stakedByOperator`]='0' n[`stakedByDelegates`]='2000000000000000000' `n_voting_power`=2358\
    - Node 3 n[`stakedByOperator`]='0' n[`stakedByDelegates`]='3000000000000000000' `n_voting_power`=3113\
    - Node 4 n[`stakedByOperator`]='0' n[`stakedByDelegates`]='4000000000000000000' `n_voting_power`=3113\
    - Node 5 n[`stakedByOperator`]='0' n[`stakedByDelegates`]='0' `n_voting_power`=1

### Validators delegating to other validators (<a name="0066-VALW-008" href="#0066-VALW-008">0066-VALW-008</a>)

1. set up a network with 5 validators
1. give each of the validators the following number of self-staked tokens: `1000`
1. delegate for the first `4` validators `1000` and from the 5th validator delegate `1000` to the 1st validator
1. wait for the delegations to become active in the next epoch
1. check the Tendermint weights across all validators are as follows:
    - Node 1 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='1000000000000000000000' `n_voting_power`=2806\
    - Node 2 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2089\
    - Node 3 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2551\
    - Node 4 n[`stakedByOperator`]='1000000000000000000000' n[`stakedByDelegates`]='0' `n_voting_power`=2551\
    - Node 5 n[`stakedByOperator`]='0' n[`stakedByDelegates`]='0' `n_voting_power`=1

### Validator delegate and undelegate in the same epoch (<a name="0066-VALW-009" href="#0066-VALW-009">0066-VALW-009</a>)

1. set up a network with 5 validators
1. give each of the validators the following number of self-staked tokens: `1000`
1. delegate in the same epoch
1. undelegate all in the same epoch
1. wait for the next epoch
1. Check that Tendermint weights whereby validators would have equal voting power of 10

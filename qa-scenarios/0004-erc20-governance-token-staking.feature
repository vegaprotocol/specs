# Scenario: An ethereum key with a non-zero balance of vested Vega tokens deposits via the staking bridge, and receives the stake on Vega 💧
    # a stake_deposited event is emitted by the staking bridge contract
    # and the vega key has a staking account for the VEGA asset
    # and the vega key's staking account has increased by the appropriate amount
# Scenario: An ethereum key with a zero balance of vested Vega tokens deposits via the staking bridge, the transaction is rejected 💧
    # No stake_deposited event is emitted by the staking bridge contract
# Scenario: An ethereum key with a non-zero balance of unvested Vega tokens deposits via the vesting contract, and receives the stake on Vega 💧
    # A stake_deposited event is emitted by the vesting contract
    # and the vega key has a staking account for the VEGA asset
    # and the vega key's staking account has increased by the appropriate amount
## Scenario: An ethereum key with a zero balance of unvested Vega tokens deposits via the vesting contract, and the transaction is rejected 💧
    # No stake_deposited event is emitted by the vesting contract
## Scenario: An ethereum key deposits unvested via the vesting contract, and vested tokens via the staking bridge 💧
    # A stake_deposited event is emitted by the vesting contract
    # And a stake_deposited event is emitted by the staking bridge contract
    # and the vega key has a staking account for the VEGA asset
    # and the vega key's staking account has increased by the sum of the vested and unvested tokens deposited
## Scenario: When staking vested tokens with the staking bridge, the staked tokens are removed from the Ethereum key's balance💧
    # Note: This is an entirely Ethereum side test
## Scenario: When staking vested tokens with the vesting bridge, balance of staked tokens cannot be removed 💧
    # Note: This is an entirely Ethereum side test

## Scenario: An ethereum key unstakes unvested tokens via the vesting contract💧
    # Given an ethereum key has staked 100 tokens in the vesting contract
    # and that key calls unstake on the vesting contract with an amount of 100
    # A stake_removed event is emitted by the vesting contract
    # and the vega key has a staking account for the VEGA asset
    # and the vega key's staking account has decreased by 100
## Scenario: An ethereum key unstakes vested tokens via the staking bridge 💧
    # Given an ethereum key has staked 100 tokens in the staking bridge
    # and that key calls unstake on the staking bridge with an amount of 100
    # A stake_removed event is emitted by the staking bridge
    # and the vega key has a staking account for the VEGA asset
    # and the vega key's staking account has decreased by 100
### Scenario: An ethereum key that has staked unvested tokens via the vesting contract cannot unstake them from the staking bridge 💧
    # Given an ethereum key has staked 100 tokens in the vesting contract
    # and that key calls unstake on the staking bridge with an amount of 100
    # No stake_removed event is emitted by the vesting contract
    # and no stake_removed event is emitted by the staking bridge contract
    # and the vega key's staking account balance is unchanged
## Scenario: An ethereum key that has staked vested tokens via the staking bridge cannot unstake them from the vesting contract 💧
    # Given an ethereum key has staked 100 tokens in the staking bridge
    # and that key calls unstake on the vesting contrract with an amount of 100
    # No stake_removed event is emitted by the vesting contract
    # and no stake_removed event is emitted by the staking bridge contract
    # and the vega key's staking account balance is unchanged
## Scenario: An ethereum key that has staked tokens cannot unstake more than it has 💧
    # Given an ethereum key has staked 100 tokens in the staking bridge
    # and that key calls unstake on the vesting contrract with an amount of 110
    # No stake_removed event is emitted by the vesting contract
## Scenario: An ethereum key deposits unvested via the vesting contract, and vested tokens via the staking bridge, then tries to withdraw them via the wrong contract 💧
    # Given an ethereum key has called stake on the vesting contract with a balance of 200 
    # and an ethereum key has called stake on the staking bridge with a balance of 100 
    # and an ethereum key calls unstake on the staking bridge with a balance of 200 
    # and no stake_removed event is emitted by the staking bridge contract
## Scenario: An ethereum key deposits unvested via the vesting contract, and vested tokens via the staking bridge, then tries to withdraw them via the right contract 💧
    # Given an ethereum key has called stake on the vesting contract with a balance of 200 
    # and an ethereum key has called stake on the staking bridge with a balance of 100 
    # and an ethereum key calls unstake on the staking bridge with a balance of 200 
    # A stake_removed event is emitted by the staking bridge

## Scenario: A vega party that has VEGA tokens in a Vega general account cannot withdraw them via the vesting contract 💧
    # Given a Vega party has a General account for the VEGA asset with a balance of 100
    # and that key calls unstake on the vesting contract with an amount of 100
    # No stake_removed event is emitted by the vesting contract
## Scenario: A vega party that has VEGA tokens in a Vega general account cannot withdraw them via the staking bridge 💧
    # Given a Vega party has a General account for the VEGA asset with a balance of 100
    # and that key calls unstake on the staking bridge with an amount of 100
    # No stake_removed event is emitted by the vesting contract
### Scenario: A vega party that has VEGA tokens in a Vega general account can withdraw them via the ERC20 bridge, then stake them via the staking bridge💧
    # Given a Vega party has a General account for the VEGA asset with a balance of 100
    # and that key withdraws the asset balance via the ERC20 bridge
    # And that key receives the VEGA balance in their wallet
    # And that key calls stake on the staking bridge with a balance of 100
    # a stake_deposited event is emitted by the staking bridge contract
    # and the vega key has a staking account for the VEGA asset
    # and the vega key's staking account will have a balance of 100
    # and the vega key's general account will have a balance of 0

# Scenario: An ethereum key with staked, ested assets in the staking bridge can transfer the ownership to another ethereum key 💧 
    # Note: This means that that key can no longer unstake those tokens
    #       But the on-vega balance remains untouched 

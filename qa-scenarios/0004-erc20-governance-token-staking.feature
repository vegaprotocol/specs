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

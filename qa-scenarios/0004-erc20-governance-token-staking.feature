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

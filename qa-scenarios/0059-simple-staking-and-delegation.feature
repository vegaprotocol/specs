# Scenario: A Vega party with a staking account balance and no existing delegations can delegate all of that staking account balance to a single validator
# Scenario: A Vega party with a staking account balance can delegate a portion of that stakiing account balance to a single validator
# Scenario: A Vega party with a staking account balance can delegate a portion of that stakiing account balance to a single validator, and another portion to a different validator
# Scenario: A Vega party with no staking account balance cannot delegate any stake to any validator
# Scenario: A Vega party with a staking account balance cannot delegate more undelegated stake than they have to any validator
# Scenario: A Vega party with a staking account balance cannot delegate more stake than they have to any validator

# Scenario: A delegators staking account balance does not change when delegating
  # Given I am a party with a staking account balance of 100
  # When I delegate 10 to a validator
  # and a new epoch begins
  # and I have staking account balance of 100

# Scenario: A validators  staking account balance does not change when delegated tp
  # Given I am a validator with a staking account balance of 100
  # When a party delegates 10 to my Vega public key
  # and a new epoch begins
  # and I have staking account balance of 100

# Scenario: The delegatable amount is the sum of staked, minus delegated
  # Given I am a party with a staking account balance of 100
  # and I have a delegatable amount of 100
  # and I have a delegated amount of 0
  # When I delegate 10 to a validator
  # and a new epoch begins
  # then I have a delegatable amount of 90
  # and I have a delegated amount of 10
  # and I have staking account balance of 100


# Scenario: A delegation transaction does not reduce the delegated amount from the party's delegatable amount until the start of the next epoch
# Scenario: At the start of the next epoch after the delegation transaction, a party has the stake they have delegated removed from their delegatable amount
# Scenario: After delegating, a party's delegatable balance decreases below the amount they delegated. In the next epoch, all available delegatable balance is delegated.
# Scenario: After delegating, a party's delegatable amount decreases to 0. In the next epoch, no action is taken.
#
# Scenario: A delegation transaction does not increase the delegated amount off a validator until the start of the next epoch
# Scenario: At the start of the next epoch after the delegation transaction, a party that has been delegated to has the stake they have been delegated added to their delegated amount

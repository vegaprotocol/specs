Feature: Staking and Delegation

Background:
    Given the following network parameters are set:
      | name                                                | value |
      | validators.epoch.length                             | 10m   |
      | validators_minimum_number                           | 1     |
      | epoch                                               | 20s   |
      | minimum_delegateable_stake                          | 2000  |
      | max_stake_per_validator                             | 300000 |

    And the average block duration is "1"
    And a period equal to "1" epochs.

Scenario: A party can delegate to a validator
Desciption: A party with a balance in the staking account can delegate to a validator

    Given the parties deposit the following token amount:
    | party      | asset | stake available | 
    | delegator1 | VEGA  |     100000      |
    When the party requests to lock the following tokens:
    | party      | asset | stake deposited | 
    | delegator1 | VEGA  |     100000      |
    And the following tokens transfer should be executed:
    | party      | asset | stake deposited | locked | 
    | delegator1 | VEGA  |     100000      | 100000 | 
    Then the party requests following delegation:
    | from       | to         | asset | delegate amount | 
    | delegator1 | validator1 | VEGA  |  100000         |
    And the parties should have following token amount balances:
    | from       | to         | asset | delegated amount | 
    | delegator1 | validator1 | VEGA  |  100000          |

Scenario:  A party can undelegate from a validator
Description: A party can undelegate i.e. remove stake from a validator
 
    Given the parties should have following token amount balances:
    | from       | to         | asset | amount delegated | 
    | delegator1 | validator1 | VEGA  |  100000          |
    When the parties requests following undelegation:
    | from       | to         | asset | undelegate amount | 
    | delegator1 | validator1 | VEGA  |  100000           |
    Then following tokens are unlocked:
    | from       | to         | asset | stake removed | 
    | validator1 | delegator1 | VEGA  |  100000       |
    Then the following tokens transfer should be executed:
    | from       | to         | asset | undelegated stake | locked |
    | validator1 | delegator1 | VEGA  |     100000        | 100000 |
    Then the parties should have following token amount balances:
    | from       | to         | asset | delegated amount | 
    | delegator1 | validator1 | VEGA  |       0          |

Scenario: A party can delegate to multiple validators
Desciption: A party with a balance in the staking account can delegate to multiple validator
   
    Given the following tokens transfer should be executed:
    | party      | asset | stake deposited | locked | 
    | delegator1 | VEGA  |     200000      | 200000 | 
    When the party requests following delegation:
    | from       | to         | asset | delegate amount | 
    | delegator1 | validator1 | VEGA  |  100000         |
    | delegator1 | validator2 | VEGA  |  100000         |
    And the parties should have following token amount balances:
    | from       | to         | asset | delegated amount | 
    | delegator1 | validator1 | VEGA  |  100000          |
    | delegator1 | validator2 | VEGA  |  100000          |
    
Scenario: A party can undelegate from multiple validators 
Description: A party can undelegate i.e. remove stake from multiple validators

    Given the parties should have following token amount balances:
    | from       | to         | asset | delegated amount | 
    | delegator1 | validator1 | VEGA  |  100000          |
    | delegator1 | validator2 | VEGA  |  100000          |
    When the parties requests following undelegation:
    | from       | to         | asset | undelegate amount | 
    | delegator1 | validator1 | VEGA  |  100000           |
    | delegator1 | validator2 | VEGA  |  100000           |
    Then following tokens are unlocked:
    | from       | to         | asset | stake removed | 
    | validator1 | delegator1 | VEGA  |  100000       |
    | validator2 | delegator1 | VEGA  |  100000       |
    # No rule in place currently to chose how much gets deducted from each validator
    Then the following tokens transfer should be executed:
    | from       | to         | asset | undelegated stake | locked |
    | validator1 | delegator1 | VEGA  |     100000        | 100000 | 
    | validator2 | delegator1 | VEGA  |     100000        | 100000 |
    Then the parties should have following token amount balances:
    | from       | to         | asset | delegated amount | 
    | delegator1 | validator1 | VEGA  |       0          |
    | delegator1 | validator2 | VEGA  |       0          |

Scenario: A party cannot delegate less than minimum delegateable stake
Desciption: A party attempts to delegate less than minimum delegateable stake from its staking account to a validator  
minimum delegateable stake
    Given the parties deposit the following token amount:
    | party      | asset | stake available | 
    | delegator1 | VEGA  |     100000      |
    When the party requests following delegation:
    | from       | to         | asset | delegate amount | 
    | delegator1 | validator1 | VEGA  |    2000         |
    Then the parties should have following token amount balances:
    | from       | to         | asset | delegated amount | 
    | delegator1 | validator1 | VEGA  |       0          |

Scenario: A party cannot delegate more than it has in staking account
Desciption: A party attempts to delegate more than it has in its staking account to a validator  

    Given the parties deposit the following token amount:
    | party      | asset | stake available | 
    | delegator1 | VEGA  |     100000      |
    When the party requests following delegation:
    | from       | to         | asset | delegate amount | 
    | delegator1 | validator1 | VEGA  |    200000       |
    Then the parties should have following token amount balances:
    | from       | to         | asset | delegated amount | 
    | delegator1 | validator1 | VEGA  |       0          |

Scenario: A party cannot delegate more than maximum amount of stake for a validator in one transaction
Desciption: A party attempts to delegate more than maximum stake for a validator

    Given the parties deposit the following token amount:
    | party      | asset | stake available | 
    | delegator1 | VEGA  |     400000      |
    When the party requests following delegation:
    | from       | to         | asset | delegate amount | 
    | delegator1 | validator1 | VEGA  |    400000       |
    Then the parties should have following token amount balances:
    | from       | to         | asset | delegated amount | 
    | delegator1 | validator1 | VEGA  |    300000        |
    | delegator1 | validator2 | VEGA  |    100000        |

Scenario: A party cannot delegate stake size such that it exceeds maximum amount of stake for a validator
Desciption: A party attempts to delegate token stake which exceed maximum stake for a validator

    Given the parties deposit the following token amount:
    | party      | asset | stake available | 
    | delegator1 | VEGA  |     400000      |
    And the parties should have following token amount balances:
    | from       | to         | asset | delegated amount | 
    | delegator2 | validator1 | VEGA  |  200000          |
    When the party requests following delegation:
    | from       | to         | asset | delegate amount | 
    | delegator1 | validator1 | VEGA  |    400000       |
    Then the parties should have following token amount balances:
    | from       | to         | asset | delegated amount | 
    | delegator2 | validator1 | VEGA  |    200000        |
    | delegator1 | validator1 | VEGA  |    100000        |
    | delegator1 | validator2 | VEGA  |    300000        |

Scenario: A party changes delegation from one validator another in the same epoch
Desciption: A party can change delegatation from one Validator to another

    Given the party requests following delegation:
    | from       | to         | asset | delegate amount | 
    | delegator1 | validator1 | VEGA  |    100000       |
    # Change dleegation in the same epoch / period
    And the network moves ahead "5" blocks
    When the parties requests following undelegation:
    | from       | to         | asset | undelegate amount | 
    | delegator1 | validator1 | VEGA  |  100000           |
    Then following tokens are unlocked:
    | from       | to         | asset | stake removed | 
    | validator1 | delegator1 | VEGA  |  100000       |
    And the following tokens transfer should be executed:
    | from       | to         | asset | undelegated stake | locked |
    | validator1 | delegator1 | VEGA  |     100000        | 100000 |
    And the parties should have following token amount balances:
    | from       | to         | asset | delegated amount | 
    | delegator1 | validator1 | VEGA  |       0          |
    When the party requests following delegation:
    | from       | to         | asset | delegate amount | 
    | delegator1 | validator2 | VEGA  |    100000       |
    Then the parties should have following token amount balances:
    | from       | to         | asset | delegated amount | 
    | delegator1 | validator2 | VEGA  |  100000          |
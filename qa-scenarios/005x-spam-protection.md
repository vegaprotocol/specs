Feature: Test liquidity provider reward distribution 

# Spec file: ../spec/005x-spam-protection.md
# This file may not be valid. I'm learnding.

  Background:
    Given time is updated to "2020-10-16T00:00:00Z"
   
    And the execution engine have these markets:
      | name      | quote name | asset | mark price | risk model | lamd/long | tau/short | mu/max move up | r/min move down | sigma | release factor | initial factor | search factor | auction duration | maker fee | infrastructure fee | liquidity fee | p. m. update freq. | p. m. horizons | p. m. probs | p. m. durations | prob. of trading | oracle spec pub. keys | oracle spec property | oracle spec property type | oracle spec binding |
      | ETH/DEC20 | ETH        | ETH   | 100        | simple     |       0.1 | 0.1       | 500            | -500            | -1    | 1.4            | 1.2            | 1.1           | 2                | 0.004     | 0.001              | 0.3           | 0                  |              1 |       0.99  |               3 | 0.1              | 0xDEADBEEF,0xCAFEDOOD | prices.ETH.value     | TYPE_INTEGER              | prices.ETH.value    |
    And the traders make the following deposits on asset's general account:
      | trader  | asset | amount     |
      | trader1 | ETH   |  100000000 |
      | trader2 | VOTE   |  1 |

  Scenario: trader 1 places a valid order and it is not rejected

    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader1 | ETH/DEC20 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC |
    Then the order should be on the book

  Scenario: trader 2 places an invalid order and it is not rejected as spam

    Then traders place following orders:
      | trader2 | ETH/DEC20 | sell | 90     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |

    Then the order will exist
    And the status will be rejected

  Scenario: A trader who has no accounts with a balance has their order rejected as spam

    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader3 | ETH/DEC20 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC |

    Then the order is rejected as spam
    And the order will not exist

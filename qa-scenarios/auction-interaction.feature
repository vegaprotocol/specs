Feature: Test interactions between different auction types

  # Related spec files:
  #  ../spec/0026-auctions.md
  #  ../spec/0032-price-monitoring.md
  #  ../spec/0035-liquidity-monitoring.md

  Background:
    Given the network parameter target_stake_time_window is 1 day
    And the network parameter target_stake_scaling_factor is 1
    And the execution engine have these markets:
      | name      | quote name | asset | mark price | risk model | lamd/long | tau/short | mu/max move up | r/min move down | sigma | release factor | initial factor | search factor | auction duration | maker fee | infrastructure fee | liquidity fee | p. m. update freq. | p. m. horizons | p. m. probs | p. m. durations | prob. of trading | oracle spec pub. keys | oracle spec property | oracle spec property type | oracle spec binding |
      | ETH/DEC20 | ETH        | ETH   | 100        | simple     |       0.1 | 0.1       | 10             | -10             | -1    | 1.4            | 1.2            | 1.1           | 1                | 0.004     | 0.001              | 0.3           | 0                  |              1 |       0.99  |               3 | 0.1              | 0xDEADBEEF,0xCAFEDOOD | prices.ETH.value     | TYPE_INTEGER              | prices.ETH.value    |
    And oracles broadcast data signed with "0xDEADBEEF":
      | name             | value |
      | prices.ETH.value | 100   |
    And the liquidity order collection object with reference "buy_shape":
      | reference | offet | proportion |
      | BEST_BID  |    -2 |          1 |
      | MID       |    -1 |          2 |
    And the liquidity order collection object with reference "sell_shape":
      | reference | offet | proportion |
      | BEST_ASK  |     2 |          1 |
      | MID       |     1 |          2 |
    And the traders make the following deposits on asset's general account:
      | trader  | asset | amount     |
      | lp1     | ETH   | 1000000000 |
      | trader1 | ETH   |  100000000 |
      | trader2 | ETH   |  100000000 |

  Scenario: When trying to exit opening auction liquidity monitoring doesn't get triggered, hence the opening auction uncrosses and market goes into continuous trading mode.

    Given the network parameter "MarketLiquidityTargetStakeTriggeringRatio" is "0"

    Then traders place following liquidity provisions:
      | trader  | market id | commitment amount | fee bid | buy shape object | sell shape object |
      | lp1     | ETH/DEC19 |             10000 | 0.001   | "buy_shape"      | "sell_shape"      |
     
    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader1 | ETH/DEC19 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC |
      | trader1 | ETH/DEC19 | buy  | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 1      | 1100  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |

    And the price monitoring bounds are []

    Then the opening auction period for market "ETH/DEC19" ends
    And the trading mode for the market "ETH/DEC19" is "TRADING_MODE_CONTINUOUS"
    And the max_oi for the market "ETH/DEC21" is "10"
    And the mark price is "1000"
    And the price monitoring bounds are [[990,1010]]
    And the target stake is 1000 
    And the supplied stake is 10000

  Scenario: When trying to exit opening auction liquidity monitoring is triggered due to missing best bid, hence the opening auction gets extended, the markets trading mode is TRADING_MODE_MONITORING_AUCTION and the trigger is AUCTION_TRIGGER_LIQUIDITY.
    Given the network parameter "MarketLiquidityTargetStakeTriggeringRatio" is "0"

    Then traders place following liquidity provisions:
      | trader  | market id | commitment amount | fee bid | buy shape object | sell shape object |
      | lp1     | ETH/DEC19 |             10000 | 0.001   | "buy_shape"      | "sell_shape"      |

    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader1 | ETH/DEC19 | buy  | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 1      | 1100  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |

    And the price monitoring bounds are []

    Then the opening auction period for market "ETH/DEC19" ends
    And the auction for market "ETH/DEC19" gets extended with the "AUCTION_TRIGGER_LIQUIDITY" trigger
    And the trading mode for the market "ETH/DEC19" is "TRADING_MODE_MONITORING_AUCTION"

    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader1 | ETH/DEC19 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC |
    
    And the auction ends
    And the trading mode for the market "ETH/DEC19" is "TRADING_MODE_CONTINUOUS"
    And the max_oi for the market "ETH/DEC21" is "10"
    And the mark price is "1000"
    And the price monitoring bounds are [[990,1010]]
    And the target stake is 1000 
    And the supplied stake is 10000

  Scenario: When trying to exit opening auction liquidity monitoring is triggered due to insufficient supplied stake, hence the opening auction gets extended, the markets trading mode is TRADING_MODE_MONITORING_AUCTION and the trigger is AUCTION_TRIGGER_LIQUIDITY.

    Given the network parameter "MarketLiquidityTargetStakeTriggeringRatio" is "0.8"

    Then traders place following liquidity provisions:
      | trader  | market id | commitment amount | fee bid | buy shape object | sell shape object |
      | lp1     | ETH/DEC19 |              700  | 0.001   | "buy_shape"      | "sell_shape"      |

    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader1 | ETH/DEC19 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC |
      | trader1 | ETH/DEC19 | buy  | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 1      | 1100  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |

    And the price monitoring bounds are []

    Then the opening auction period for market "ETH/DEC19" ends
    And the auction for market "ETH/DEC19" gets extended with the "AUCTION_TRIGGER_LIQUIDITY" trigger
    And the trading mode for the market "ETH/DEC19" is "TRADING_MODE_MONITORING_AUCTION"

    Then traders place following liquidity provisions:
      | trader  | market id | commitment amount | fee bid | buy shape object | sell shape object |
      | lp1     | ETH/DEC19 |              800  | 0.001   | "buy_shape"      | "sell_shape"      |
    
    And the trading mode for the market "ETH/DEC19" is "TRADING_MODE_MONITORING_AUCTION"

    Then traders place following liquidity provisions:
      | trader  | market id | commitment amount | fee bid | buy shape object | sell shape object |
      | lp1     | ETH/DEC19 |              801  | 0.001   | "buy_shape"      | "sell_shape"      |

    And the trading mode for the market "ETH/DEC19" is "TRADING_MODE_MONITORING_AUCTION"

    Then traders place following liquidity provisions:
      | trader  | market id | commitment amount | fee bid | buy shape object | sell shape object |
      | lp1     | ETH/DEC19 |             1000  | 0.001   | "buy_shape"      | "sell_shape"      |

    And the auction ends
    And the trading mode for the market "ETH/DEC19" is "TRADING_MODE_CONTINUOUS"
    And the max_oi for the market "ETH/DEC21" is "10"
    And the mark price is "1000"
    And the price monitoring bounds are [[990,1010]]
    And the target stake is 1000 
    And the supplied stake is 10000

  Scenario: Once market is in continuous trading mode: enter liquidity monitoring auction -> extend with price monitoring auction -> leave auction mode
      
  Scenario: Once market is in continuous trading mode: enter liquidity monitoring auction -> extend with price monitoring auction -> extend with liquidity monitoring -> leave auction mode  

  Scenario: Once market is in continuous trading mode: enter price monitoring auction -> extend with liquidity monitoring auction -> leave auction mode

  Scenario: Once market is in continuous trading mode: enter price monitoring auction -> extend with liquidity monitoring auction -> extend with price monitoring -> leave auction mode  
  
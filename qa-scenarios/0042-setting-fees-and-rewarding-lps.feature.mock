Feature: Test liquidity provider reward distribution 

# Spec file: 0042-setting-fees-and-rewarding-lps.md

  Background:
    Given time is updated to "2020-10-16T00:00:00Z"
    And the network parameter "market.value.windowLength"" is "1 hour"
    And the network parameter "market.stake.target.timeWindow" is "1 day"
    And the network parameter "market.stake.target.scalingFactor" is "1"
    And the network parameter "market.liquidity.targetstake.triggering.ratio" is "0"
    And the network parameter "market.liquidity.providers.fee.distributionTimeStep" is "10 minutes"
   
    And the execution engine have these markets:
      | name      | quote name | asset | mark price | risk model | lamd/long | tau/short | mu/max move up | r/min move down | sigma | release factor | initial factor | search factor | auction duration | maker fee | infrastructure fee | liquidity fee | p. m. update freq. | p. m. horizons | p. m. probs | p. m. durations | prob. of trading | oracle spec pub. keys | oracle spec property | oracle spec property type | oracle spec binding |
      | ETH/DEC20 | ETH        | ETH   | 100        | simple     |       0.1 | 0.1       | 500            | -500            | -1    | 1.4            | 1.2            | 1.1           | 2                | 0.004     | 0.001              | 0.3           | 0                  |              1 |       0.99  |               3 | 0.1              | 0xDEADBEEF,0xCAFEDOOD | prices.ETH.value     | TYPE_INTEGER              | prices.ETH.value    |
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

  Scenario: 1 LP joining at start, checking liquidity rewards over 3 periods, 1 period with no trades

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
    And the auction ends resulting in traded volume of "10" at a price of "1000"
    And the trading mode for the market "ETH/DEC19" is "TRADING_MODE_CONTINUOUS"
    And the max_oi for the market "ETH/DEC21" is "10"
    And the mark price is "1000"
    And the price monitoring bounds are "[[990,1010]]"
    And the target stake is "1000" 
    And the supplied stake is "10000"

    And the liquidity provider fee share is:
    | party | equity like share | average entry valuation |
    | lp1   |                 1 |                   10000 |

    And the liquidity fee factor is "0.001"
    
    # trade_value_for_fee_purposes  = size_of_trade * price_of_trade
    And the accumulated liquidity fees are "10" 
    
    Then traders place following orders:
    | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
    | trader1 | ETH/DEC19 | sell | 20     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |
    | trader2 | ETH/DEC19 | buy  | 20     | 1000  | 1                | TYPE_LIMIT | TIF_GTC |

    And the accumulated liquidity fees are "30" 

    # Opening auction duration is 2s, fees are distributed very 10 minutes
    Then time is updated to "2020-10-16T00:10:03Z"

    And the liquidity fees are distributed:
    | party | liquidity fee transfer |
    | lp1   |                     30 |

    Then time is updated to "2020-10-16T00:20:03Z"

    And the liquidity fees are distributed:
    | party | liquidity fee transfer |
    | lp1   |                      0 |

    Then time is updated to "2020-10-16T00:20:05Z"

    Then traders place following orders:
    | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
    | trader1 | ETH/DEC19 | buy  | 40     | 1100  | 0                | TYPE_LIMIT | TIF_GTC |
    | trader2 | ETH/DEC19 | sell | 40     | 1100  | 1                | TYPE_LIMIT | TIF_GTC |

    And the accumulated liquidity fees are "44" 

    Then time is updated to "2020-10-16T00:30:03Z"

    And the liquidity fees are distributed:
    | party | liquidity fee transfer |
    | lp1   |                     44 |

  Scenario: 2 LPs joining at start, equal commitments

    Then traders place following liquidity provisions:
      | trader  | market id | commitment amount | fee bid | buy shape object | sell shape object |
      | lp1     | ETH/DEC19 |              5000 | 0.001   | "buy_shape"      | "sell_shape"      |
      | lp2     | ETH/DEC19 |              5000 | 0.002   | "buy_shape"      | "sell_shape"      |
     
    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader1 | ETH/DEC19 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC |
      | trader1 | ETH/DEC19 | buy  | 90     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 1      | 1100  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 90     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |

    And the price monitoring bounds are []

    Then the opening auction period for market "ETH/DEC19" ends
    And the auction ends resulting in traded volume of "10" at a price of "1000"
    And the trading mode for the market "ETH/DEC19" is "TRADING_MODE_CONTINUOUS"
    And the max_oi for the market "ETH/DEC21" is "10"
    And the mark price is "1000"
    And the price monitoring bounds are "[[990,1010]]"
    And the target stake is "9000" 
    And the supplied stake is "10000"

    And the liquidity provider fee share is:
    | party | equity like share | average entry valuation |
    | lp1   |               0.5 |                   10000 |
    | lp2   |               0.5 |                   10000 |

    And the liquidity fee factor is "0.002"
    
    # trade_value_for_fee_purposes  = size_of_trade * price_of_trade
    And the accumulated liquidity fees are "180" 
    
    Then traders place following orders:
    | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
    | trader1 | ETH/DEC19 | sell | 20     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |
    | trader2 | ETH/DEC19 | buy  | 20     | 1000  | 1                | TYPE_LIMIT | TIF_GTC |

    And the accumulated liquidity fees are "200" 

    # Opening auction duration is 2s, fees are distributed very 10 minutes
    Then time is updated to "2020-10-16T00:10:03Z"

    And the liquidity fees are distributed:
    | party | liquidity fee transfer |
    | lp1   |                    100 |
    | lp2   |                    100 |

    Then time is updated to "2020-10-16T00:10:05Z"

    Then traders place following orders:
    | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
    | trader1 | ETH/DEC19 | buy  | 40     | 1100  | 0                | TYPE_LIMIT | TIF_GTC |
    | trader2 | ETH/DEC19 | sell | 40     | 1100  | 1                | TYPE_LIMIT | TIF_GTC |

    And the accumulated liquidity fees are "44" 

    Then time is updated to "2020-10-16T00:20:03Z"

    And the liquidity fees are distributed:
    | party | liquidity fee transfer |
    | lp1   |                     44 |
    | lp2   |                     22 |

  Scenario: 2 LPs joining at start, unequal commitments

    Then traders place following liquidity provisions:
      | trader  | market id | commitment amount | fee bid | buy shape object | sell shape object |
      | lp1     | ETH/DEC19 |              8000 | 0.001   | "buy_shape"      | "sell_shape"      |
      | lp2     | ETH/DEC19 |              2000 | 0.002   | "buy_shape"      | "sell_shape"      |
     
    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader1 | ETH/DEC19 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC |
      | trader1 | ETH/DEC19 | buy  | 60     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 1      | 1100  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 60     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |

    And the price monitoring bounds are []

    Then the opening auction period for market "ETH/DEC19" ends
    And the auction ends resulting in traded volume of "10" at a price of "1000"
    And the trading mode for the market "ETH/DEC19" is "TRADING_MODE_CONTINUOUS"
    And the max_oi for the market "ETH/DEC21" is "10"
    And the mark price is "1000"
    And the price monitoring bounds are "[[990,1010]]"
    And the target stake is "6000" 
    And the supplied stake is "10000"

    And the liquidity provider fee share is:
    | party | equity like share | average entry valuation |
    | lp1   |               0.8 |                   10000 |
    | lp2   |               0.2 |                   10000 |

    And the liquidity fee factor is "0.001"
    
    # trade_value_for_fee_purposes  = size_of_trade * price_of_trade
    And the accumulated liquidity fees are "60" 
    
    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader1 | ETH/DEC19 | sell | 20     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | buy  | 20     | 1000  | 1                | TYPE_LIMIT | TIF_GTC |

    And the accumulated liquidity fees are "80" 

    # Opening auction duration is 2s, fees are distributed very 10 minutes
    Then time is updated to "2020-10-16T00:10:03Z"

    And the liquidity fees are distributed:
      | party | liquidity fee transfer |
      | lp1   |                     64 |
      | lp2   |                     16 |

    Then time is updated to "2020-10-16T00:10:05Z"

    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader1 | ETH/DEC19 | buy  | 40     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 40     | 1000  | 1                | TYPE_LIMIT | TIF_GTC |

    And the accumulated liquidity fees are "40" 

    Then time is updated to "2020-10-16T00:20:03Z"

    And the liquidity fees are distributed:
      | party | liquidity fee transfer |
      | lp1   |                     32 |
      | lp2   |                      8 |

  Scenario: 2 LPs joining at start, unequal commitments, 1 LP joining later

    Then traders place following liquidity provisions:
      | trader  | market id | commitment amount | fee bid | buy shape object | sell shape object |
      | lp1     | ETH/DEC19 |              8000 | 0.001   | "buy_shape"      | "sell_shape"      |
      | lp2     | ETH/DEC19 |              2000 | 0.002   | "buy_shape"      | "sell_shape"      |
    
    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader1 | ETH/DEC19 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC |
      | trader1 | ETH/DEC19 | buy  | 60     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 1      | 1100  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 60     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |

    And the price monitoring bounds are []

    Then the opening auction period for market "ETH/DEC19" ends
    And the auction ends resulting in traded volume of "10" at a price of "1000"
    And the trading mode for the market "ETH/DEC19" is "TRADING_MODE_CONTINUOUS"
    And the max_oi for the market "ETH/DEC21" is "10"
    And the mark price is "1000"
    And the price monitoring bounds are "[[990,1010]]"
    And the target stake is "6000" 
    And the supplied stake is "10000"
    And the traded value in the current window is "0"

    And the liquidity provider fee share is:
      | party | equity like share | average entry valuation |
      | lp1   |               0.8 |                   10000 |
      | lp2   |               0.2 |                   10000 |

    And the liquidity fee factor is "0.001"
    
    # trade_value_for_fee_purposes  = size_of_trade * price_of_trade
    And the accumulated liquidity fees are "60" 
    
    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader1 | ETH/DEC19 | sell | 20     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | buy  | 20     | 1000  | 1                | TYPE_LIMIT | TIF_GTC |

    And the accumulated liquidity fees are "80" 
    And the traded value in the current window is "20000"

    # Opening auction duration is 2s, fees are distributed very 10 minutes
    Then time is updated to "2020-10-16T00:10:03Z"

    And the liquidity fees are distributed:
      | party | liquidity fee transfer |
      | lp1   |                     64 |
      | lp2   |                     16 |

    Then time is updated to "2020-10-16T00:10:05Z"
    
    And the traded value in the current window is "20000"
    Then traders place following liquidity provisions:
      | trader  | market id | commitment amount | fee bid | buy shape object | sell shape object |
      | lp3     | ETH/DEC19 |             10000 | 0.001   | "buy_shape"      | "sell_shape"      |
    #factor=3600s/605s=5.950413223, traded value over window = 20000, lp3 entry valuation = 119008.2645
    And the liquidity provider fee share is:
      | party | average entry valuation |
      | lp1   |                   10000 |
      | lp2   |                   10000 |
      | lp3   |                  119008 |

    Then traders place following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | 
      | trader1 | ETH/DEC19 | buy  | 40     | 1000  | 0                | TYPE_LIMIT | TIF_GTC |
      | trader2 | ETH/DEC19 | sell | 40     | 1000  | 1                | TYPE_LIMIT | TIF_GTC |

    And the accumulated liquidity fees are "40" 
    And the traded value in the current window is "60000"

    Then time is updated to "2020-10-16T00:20:03Z"
    
    #factor=3600s/1203s=2.992518703, traded value over window = 60000, current market valuation = 179551.1222
    And the liquidity provider fee share is:
      | party | equity like share | average entry valuation |
      | lp1   |       0.737988469 |                   10000 |
      | lp2   |       0.184497117 |                   10000 |
      | lp3   |       0.077514414 |                  119008 |

    And the liquidity fees are distributed:
      | party | liquidity fee transfer |
      | lp1   |                     30 |
      | lp2   |                      7 |
      | lp2   |                      3 |

Feature: Test liquidity provider bond slashing 

# Spec file: ../specs-internal/protocol/0044-lp-mechanics.md

# Test structure	
# Set up a BTCUSD direct futures market	
# LP1 has 1500 USD collateral	
# LP1 commits 1000 USD with some shape	
# Check this is in their bond account	
# Margin for LP1 costs xxx (assume < 500)	
# Empty their general account somehow (use or withdraw)	

# Should get slashed correctly (check bond penalty param) if …		
# 	they don't have a position and they can't maintain their margin for orders	
# how to test?
#     Empty their general account somehow (use or withdraw) then architect a price move up so that their mark to market and margin requirements increase

# Should get slashed correctly (check bond penalty param) if …		
    # they have a position and market moves against them enough	
# how to test?
    # Open a big enough position and make a big enough move

# Should not get slashed if …	
# 	all other things being equal they increase their margin requirement by submitting an amend on the shape

# If they have previously been slashed	
# 	If there is a MTM move in their favour, bond account is topped up first

# EDIT BELOW !!
  Background:
    Given 
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


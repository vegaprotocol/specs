Feature: Test closeout type 1: margin >= cost of closeout

#   Scenario: case 1 (using simple risk model) from https://docs.google.com/spreadsheets/d/1CIPH0aQmIKj6YeFW9ApP_l-jwB4OcsNQ/edit#gid=1555964910
#   Background:

#     And the simple risk model named "simple-risk-model-1":
#       | long | short | max move up | min move down | probability of trading |
#       | 1    | 2     | 100         | -100          | 0.1                    |

#     And the margin calculator named "margin-calculator-1":
#       | search factor | initial factor | release factor | 
#       | 2             | 3              | 5              | 

#     And the markets:
#       | id        | quote name | asset | risk model          | margin calculator   | auction duration | fees         | price monitoring | oracle config          |
#       | ETH/DEC19 | USD        | USD   | simple-risk-model-1 | margin-calculator-1 | 1                | default-none | default-none     | default-eth-for-future |
#     And the following network parameters are set:
#       | name                           | value |
#       | market.auction.minimumDuration | 1     |

# # setup accounts
#     Given the initial insurance pool balance is "15000" for the markets:
#     Given the parties deposit on asset's general account the following amount:
#       | party            | asset | amount     |
#       | sellSideProvider | USD   | 1000000000 |
#       | buySideProvider  | USD   | 1000000000 |
#       | party1           | USD   | 30000      |
#       | party2           | USD   | 50000000   |
#       | party3           | USD   | 30000      |
#       | aux1             | USD   | 1000000000 |
#       | aux2             | USD   | 1000000000 |

#     # And the cumulated balance for all accounts should be worth "4050060000"
#     # Then "party1" should have general account balance of "30000" for asset "USD"  
#     # setup order book
#     When the parties place the following orders:
#       | party            | market id | side | volume | price | resulting trades | type       | tif     | reference       |
#       | sellSideProvider | ETH/DEC19 | sell | 1000   | 150   | 0                | TYPE_LIMIT | TIF_GTC | sell-provider-1 |
#       | aux1             | ETH/DEC19 | sell | 1      | 300   | 0                | TYPE_LIMIT | TIF_GTC | aux-s-1         |
#       | aux1             | ETH/DEC19 | sell | 1      | 100   | 0                | TYPE_LIMIT | TIF_GTC | aux-s-2         |
#       | aux2             | ETH/DEC19 | buy  | 1      | 100   | 0                | TYPE_LIMIT | TIF_GTC | aux-b-2         |
#       | buySideProvider  | ETH/DEC19 | buy  | 1000   | 80    | 0                | TYPE_LIMIT | TIF_GTC | buy-provider-1  |
#       | aux2             | ETH/DEC19 | buy  | 1      | 20    | 0                | TYPE_LIMIT | TIF_GTC | aux-b-1         |
#     Then the parties should have the following account balances:
#       | party            | asset | market id | margin    | general     |
#       | aux1             | USD   | ETH/DEC19 | 3600      |  999996400  |
#       | aux2             | USD   | ETH/DEC19 | 960       |  999999040  |
#       | sellSideProvider | USD   | ETH/DEC19 | 2700000   |  997300000  |
#       | buySideProvider  | USD   | ETH/DEC19 | 540000    |  999460000  |
      
#     Then the opening auction period ends for market "ETH/DEC19"
#     #And the mark price should be "100" for the market "ETH/DEC19"
#     And the trading mode should be "TRADING_MODE_CONTINUOUS" for the market "ETH/DEC19"

#     # party 1 place an order + we check margins
#     When the parties place the following orders:
#       | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
#       | party1 | ETH/DEC19 | sell | 100    | 100   | 0                | TYPE_LIMIT | TIF_GTC | ref-1     |
    
#     # all general acc balance goes to margin account for the order, 'party1' should have 100*100*3 
#     # in the margin account as its Position*Markprice*Initialfactor

#      # then party2 places an order, this trades with party1 and we calculate the margins again
#      When the parties place the following orders:
#        | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
#        | party2 | ETH/DEC19 | buy  | 100    | 100   | 1                | TYPE_LIMIT | TIF_GTC | ref-1     |
    
#     And the mark price should be "100" for the market "ETH/DEC19"
#     And the insurance pool balance should be "15000" for the market "ETH/DEC19" 

#     #check margin account and margin level
#     And the parties should have the following account balances:
#       | party  | asset | market id | margin   | general   |
#       | party1 | USD   | ETH/DEC19 | 30000    |  0        |
#       | party2 | USD   | ETH/DEC19 | 30000    |  49970000 |

#     Then the parties should have the following margin levels:
#       | party  | market id | maintenance | search | initial | release  |
#       | party1 | ETH/DEC19 | 25000       | 50000  | 75000   | 125000   |
#       | party2 | ETH/DEC19 | 12000       | 24000  | 36000   | 60000    |

#     When the parties place the following orders:
#       | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
#       | party2 | ETH/DEC19 | buy  | 1      | 126   | 0                | TYPE_LIMIT | TIF_GTC | ref-1-xxx |
  
#     # New margin level calculated after placing an order
#     Then the parties should have the following margin levels:
#       | party  | market id | maintenance | search | initial | release  |
#       | party2 | ETH/DEC19 | 12100       | 24200  | 36300   | 60500    |

#     # Margin account balance brought up to new initial level as order is placed (despite all balance being above search level)
#     And the parties should have the following account balances:
#       | party  | asset | market id | margin | general   |
#       | party2 | USD   | ETH/DEC19 | 36300  |  49963700 |
  
#     When the parties place the following orders:
#      | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
#      | party3 | ETH/DEC19 | sell | 1      | 126   | 1                | TYPE_LIMIT | TIF_GTC | ref-1-xxx |
#     Then the mark price should be "126" for the market "ETH/DEC19"    
#     And the insurance pool balance should be "40000" for the market "ETH/DEC19" 

#     # Margin account balance not updated following a trade (above search)
#     Then the parties should have the following margin levels:
#       | party  | market id | maintenance | search | initial | release  |
#       | party2 | ETH/DEC19 | 17372       | 34744  | 52116   | 86860    |

#     # MTM win transfer
#     Then the following transfers should happen:
#       | from   | to     | from account            | to account          | market id | amount | asset |
#       | market | party2 | ACCOUNT_TYPE_SETTLEMENT | ACCOUNT_TYPE_MARGIN | ETH/DEC19 | 2600   | USD   |
 
#     And the parties should have the following account balances:
#       | party  | asset | market id | margin | general   |
#       | party2 | USD   | ETH/DEC19 | 38900  |  49963700 |

#     Then the parties should have the following margin levels:
#     #check margin account and margin level
#       | party  | market id | maintenance | search | initial | release  |
#       | party1 | ETH/DEC19 | 0           | 0      | 0       | 0        |
#       | party2 | ETH/DEC19 | 17372       | 34744  | 52116   | 86860    |
#       | party3 | ETH/DEC19 | 276         | 552    | 828     | 1380     |


#     Then the order book should have the following volumes for market "ETH/DEC19":
#       | side | price    | volume |
#       | sell | 150      | 900   |
#       | sell | 300      | 1      |
#       | buy  | 80       | 1000   |
#       | buy  | 20       | 1      |

#     Then the mark price should be "126" for the market "ETH/DEC19"   
#     And the insurance pool balance should be "40000" for the market "ETH/DEC19" 

#     Then the parties should have the following account balances:
#       | party            | asset | market id | margin    | general     |
#       | party1           | USD   | ETH/DEC19 | 0         |  0          |
#       | party2           | USD   | ETH/DEC19 | 38900     |  49963700   |
#       | party3           | USD   | ETH/DEC19 | 600       |  29400      |
#       | aux1             | USD   | ETH/DEC19 | 1324      |  999998650  |
#       | aux2             | USD   | ETH/DEC19 | 986       |  999999040  |
#       | sellSideProvider | USD   | ETH/DEC19 | 758400    |  999244000  |
#       | buySideProvider  | USD   | ETH/DEC19 | 540000    |  999460000  |

#    And the cumulated balance for all accounts should be worth "4050075000" 
#    And the insurance pool balance should be "40000" for the market "ETH/DEC19" 

#     # order book volume change
#     Then the parties cancel the following orders:
#       | party           | reference        |
#       | sellSideProvider|  sell-provider-1 |
#       | buySideProvider | buy-provider-1   |

#     When the parties place the following orders:
#       | party            | market id | side | volume | price | resulting trades | type       | tif     | reference |
#       | sellSideProvider | ETH/DEC19 | sell | 1000   | 500   | 0                | TYPE_LIMIT | TIF_GTC | sell-provider-2 |
#       | buySideProvider  | ETH/DEC19 | buy  | 1000   | 20    | 0                | TYPE_LIMIT | TIF_GTC | buy-provider-2  |

#     And the trading mode should be "TRADING_MODE_CONTINUOUS" for the market "ETH/DEC19"

#     #check margin account and margin level
#     And the parties should have the following account balances:
#       | party  | asset | market id | margin   | general   |
#       | party2 | USD   | ETH/DEC19 | 38900    |  49963700 |
#       | party3 | USD   | ETH/DEC19 | 600      |  29400    |

#      Then the parties should have the following margin levels:
#       | party  | market id | maintenance | search | initial | release |
#       | party2 | ETH/DEC19 | 17372       | 34744  | 52116   | 86860   |
#       | party3 | ETH/DEC19 | 276         | 552    | 828     | 1380    |

#     When the parties place the following orders:
#       | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
#       | party2 | ETH/DEC19 | buy  | 50     | 30    | 0                | TYPE_LIMIT | TIF_GTC | ref-2-xxx |

#      Then the parties should have the following margin levels:
#       | party  | market id | maintenance | search | initial | release |
#       | party2 | ETH/DEC19 | 29732       | 59464  | 89196   | 148660  |

#     #check margin account and margin level
#     And the parties should have the following account balances:
#       | party  | asset | market id | margin   | general   |
#       | party2 | USD   | ETH/DEC19 | 89196    |  49913404 |
#       | party3 | USD   | ETH/DEC19 | 600      |  29400    |

#     Then the parties should have the following margin levels:
#       | party  | market id | maintenance | search | initial | release  |
#       | party2 | ETH/DEC19 | 29732       | 59464  | 89196   | 148660   |
#       | party3 | ETH/DEC19  | 276        | 552    | 828     | 1380     |

#     When the parties place the following orders:
#       | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
#       | party3 | ETH/DEC19 | sell | 50     | 30    | 1                | TYPE_LIMIT | TIF_GTC | ref-3-xxx |
#     And the insurance pool balance should be "40000" for the market "ETH/DEC19" 
#     Then the mark price should be "30" for the market "ETH/DEC19"  
#     # Then the order book should have the following volumes for market "ETH/DEC19":
#       | side | price    | volume |
#       | sell | 500      | 1000   |
#       | sell | 300      | 1      |
#       | buy  | 20       | 1001   |

#     Then the parties should have the following profit and loss:
#       | party  | volume | unrealised pnl | realised pnl |
#       | party3 | -51    | 96             | 0            |

#     #check margin account and margin level
#     And the parties should have the following account balances:
#       | party  | asset | market id | margin   | general   |
#       | party2 | USD   | ETH/DEC19 | 18120    | 49974784  |
#       | party3 | USD   | ETH/DEC19 | 30096    |  0        |

#     # party3 maintenance margin: position*(mark_price*risk_factor_short+slippage_per_unit) + mark_price*risk_factor_short=51*(30*2+466)+0=26826
#     # (slippage calulated as follows) slippager_per_unit=exit_price-mark_price=(300*1+500*50)/51-30=496-30=466
#     Then the parties should have the following margin levels:
#       | party  | market id | maintenance | search | initial | release  |
#       | party2 | ETH/DEC19 | 6040        | 12080  | 18120   | 30200    |
#       | party3 | ETH/DEC19 | 26826       | 53652  | 80478   | 134130   |

#     Then the order book should have the following volumes for market "ETH/DEC19":
#       | side | price    | volume |
#       | sell | 500      | 1000   |
#       | sell | 300      | 1      |

#     When the parties place the following orders:
#       | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
#       | party3 | ETH/DEC19 | sell | 50     | 30    | 0                | TYPE_LIMIT | TIF_GTC | ref-3-xxx |

#     # party3 maintenance margin: position*(mark_price*risk_factor_short+slippage_per_unit) + open_order*mark_price*risk_factor_short=51*(30*2+466) + 50 * 30 * 2 = 26826 + 3000 = 29826
#     # (slippage calulated as follows) slippager_per_unit=exit_price-mark_price=(300*1+500*50)/51-30=496-30=466

#     # party3 has put the order twice 
#     Then the parties should have the following margin levels:
#       | party  | market id | maintenance | search | initial | release  |
#       | party3 | ETH/DEC19 | 29826       | 59652  | 89478   | 149130   |

#     Then the order book should have the following volumes for market "ETH/DEC19":
#       | side | price    | volume |
#       | sell | 500      | 1000   |
#       | sell | 300      | 1      |
#       | sell | 30       | 50     |
#       | buy  | 20       | 1001   |
  
#     And the insurance pool balance should be "40000" for the market "ETH/DEC19" 

#     #check margin account and margin level
#     And the parties should have the following account balances:
#       | party  | asset | market id | margin   | general   |
#       | party2 | USD   | ETH/DEC19 | 18120    | 49974784  |
#       | party3 | USD   | ETH/DEC19 | 30096    |  0        |

#     Then the parties should have the following margin levels:
#       | party  | market id | maintenance | search | initial | release  |
#       | party2 | ETH/DEC19 | 6040        | 12080  | 18120   | 30200    |
#       | party3 | ETH/DEC19 | 29826       | 59652  | 89478   | 149130   |

#     When the parties place the following orders:
#       | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
#       | party2 | ETH/DEC19 | buy  | 50     | 30    | 1                | TYPE_LIMIT | TIF_GTC | ref-2-xxx |

#     And the insurance pool balance should be "22826" for the market "ETH/DEC19" 

#      #party3 gets closeout with MTM 
#     And the parties should have the following account balances:
#         | party  | asset | market id | margin   | general   |
#         | party1 | USD   | ETH/DEC19 | 0        |  0        |
#         | party2 | USD   | ETH/DEC19 | 22620   |  49970284 |
#         | party3 | USD   | ETH/DEC19 | 0        |  0        |

#     Then the parties should have the following profit and loss:
#        | party  | volume | unrealised pnl | realised pnl |
#        | party1 | 0      | 0              | -30000       |
#        | party2 | 201    | -7096          | 0            |
#        | party3 | 0      | 0              | -30000       |

Scenario: case 2 using lognomal risk model
  Background:

    And the log normal risk model named "lognormal-risk-model-fish":
      | risk aversion | tau  | mu | r     | sigma |
      | 0.001         | 0.01 | 0  | 0.0   | 1.2   |
      #calculated risk factor long: 0.336895684; risk factor short: 0.4878731

    And the price monitoring updated every "1" seconds named "price-monitoring-1":
      | horizon | probability | auction extension |
      | 1       | 0.99999999  | 300               |

    And the margin calculator named "margin-calculator-1":
      | search factor | initial factor | release factor | 
      | 1.2           | 1.5            | 2              | 

    And the markets:
      | id        | quote name | asset | risk model                | margin calculator   | auction duration | fees         | price monitoring  | oracle config          |
      | ETH/DEC19 | ETH        | USD   | lognormal-risk-model-fish | margin-calculator-1 | 1                | default-none | price-monitoring-1| default-eth-for-future |

    And the following network parameters are set:
      | name                           | value |
      | market.auction.minimumDuration | 1     |

# setup accounts
    Given the initial insurance pool balance is "15000" for the markets:
    Given the parties deposit on asset's general account the following amount:
      | party            | asset | amount     |
      | sellSideProvider | USD   | 1000000000 |
      | buySideProvider  | USD   | 1000000000 |
      | party1           | USD   | 30000      |
      | party2           | USD   | 50000000   |
      | party3           | USD   | 30000      |
      | aux1             | USD   | 1000000000 |
      | aux2             | USD   | 1000000000 |
     And the cumulated balance for all accounts should be worth "4050075000"
# setup order book
    When the parties place the following orders:
      | party            | market id | side | volume | price | resulting trades | type       | tif     | reference       |
      | sellSideProvider | ETH/DEC19 | sell | 1000   | 150   | 0                | TYPE_LIMIT | TIF_GTC | sell-provider-1 |
      | party1           | ETH/DEC19 | sell | 100    | 120   | 0                | TYPE_LIMIT | TIF_GTC | party1-s-1      |
      | aux1             | ETH/DEC19 | sell | 1      | 100   | 0                | TYPE_LIMIT | TIF_GTC | aux-s-2         |
      | aux2             | ETH/DEC19 | buy  | 1      | 100   | 0                | TYPE_LIMIT | TIF_GTC | aux-b-2         |
      | party2           | ETH/DEC19 | buy  | 100    | 80    | 0                | TYPE_LIMIT | TIF_GTC | party2-b-1      |
      | buySideProvider  | ETH/DEC19 | buy  | 1000   | 70    | 0                | TYPE_LIMIT | TIF_GTC | buy-provider-1  |
      
    Then the opening auction period ends for market "ETH/DEC19"
    And the mark price should be "100" for the market "ETH/DEC19"
    And the trading mode should be "TRADING_MODE_CONTINUOUS" for the market "ETH/DEC19"

   # party1 maintenance margin: position*(mark_price*risk_factor_short+slippage_per_unit) + OrderVolume x Order_price x risk_factor_short = 100 x 120 x 0.4878731 is about 6000

    Then debug transfers  
    Then debug orders

    Then the parties should have the following account balances:
      | party   | asset | market id | margin | general  |
      | party1  | USD   | ETH/DEC19 | 17564  |  12436   |

    Then the parties should have the following margin levels:
      | party  | market id | maintenance | search | initial | release  |
      | party1 | ETH/DEC19 | 10734       | 12880  | 16100   | 39032    |

    # When the parties place the following orders:
    #   | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
    #   | aux2   | ETH/DEC19 | buy  | 50     | 120   | 1                | TYPE_LIMIT | TIF_GTC | ref-2     |

    # Then the parties should have the following margin levels:
    #   | party  | market id | maintenance | search | initial | release  |
    #   | party1 | ETH/DEC19 | 5855        | 7026   | 8782    | 11710    |

    # # party 1 place an order + we check margins
    # When the parties place the following orders:
    #   | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
    #   | party1 | ETH/DEC19 | sell | 400    | 100   | 0                | TYPE_LIMIT | TIF_GTC | ref-1     |
    
    # # all general acc balance goes to margin account for the order, 'party1' should have 100*100*3 
    # #in the margin account as its Position*Markprice*Initialfactor
    # And the parties should have the following account balances:
    #   | party  | asset | market id | margin   | general   |
    #   | party1 | USD   | ETH/DEC19 | 30000    |  0    |
    # Then the parties should have the following margin levels:
    #   | party  | market id | maintenance | search | initial | release  |
    #   | party1 | ETH/DEC19 | 29273       | 35127  | 43909   | 58546    |
    
    #  # then party2 places an order, this trades with party1 and we calculate the margins again
    #  When the parties place the following orders:
    #    | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
    #    | party2 | ETH/DEC19 | buy  | 500    | 100   | 1                | TYPE_LIMIT | TIF_GTC | ref-1     | 
    
    # And the mark price should be "100" for the market "ETH/DEC19"
    # And the insurance pool balance should be "23500" for the market "ETH/DEC19" 

   

    
  
   

   
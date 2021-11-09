Feature: Test closeout type 1: margin >= cost of closeout

  Background:

    And the simple risk model named "simple-risk-model-1":
      | long | short | max move up | min move down | probability of trading |
      | 1    | 2     | 100         | -100          | 0.1                    |

    And the margin calculator named "margin-calculator-1":
      | search factor | initial factor | release factor | 
      | 2             | 3              | 5              | 

    And the markets:
      | id        | quote name | asset | risk model                  | margin calculator   | auction duration | fees         | price monitoring | oracle config          |
      | ETH/DEC19 | USD        | USD   | simple-risk-model-1 | margin-calculator-1 | 1                | default-none | default-none     | default-eth-for-future |
    And the following network parameters are set:
      | name                           | value |
      | market.auction.minimumDuration | 1     |

  Scenario: case 1 from https://docs.google.com/spreadsheets/d/1CIPH0aQmIKj6YeFW9ApP_l-jwB4OcsNQ/edit#gid=1555964910
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

    # And the cumulated balance for all accounts should be worth "4100045000"
    # Then "party1" should have general account balance of "30000" for asset "USD"  
# setup order book
    When the parties place the following orders:
      | party            | market id | side | volume | price | resulting trades | type       | tif     | reference       |
      | sellSideProvider | ETH/DEC19 | sell | 1000   | 150   | 0                | TYPE_LIMIT | TIF_GTC | sell-provider-1 |
      | aux1             | ETH/DEC19 | sell | 1      | 300   | 0                | TYPE_LIMIT | TIF_GTC | aux-s-1         |
      | aux1             | ETH/DEC19 | sell | 1      | 100   | 0                | TYPE_LIMIT | TIF_GTC | aux-s-2         |
      | aux2             | ETH/DEC19 | buy  | 1      | 100   | 0                | TYPE_LIMIT | TIF_GTC | aux-b-2         |
      | buySideProvider  | ETH/DEC19 | buy  | 1000   | 80    | 0                | TYPE_LIMIT | TIF_GTC | buy-provider-1  |
      | aux2             | ETH/DEC19 | buy  | 1      | 20    | 0                | TYPE_LIMIT | TIF_GTC | aux-b-1         |
      
    Then the opening auction period ends for market "ETH/DEC19"
    And the mark price should be "100" for the market "ETH/DEC19"
    And the trading mode should be "TRADING_MODE_CONTINUOUS" for the market "ETH/DEC19"

    # party 1 place an order + we check margins
    When the parties place the following orders:
      | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
      | party1 | ETH/DEC19 | sell | 100    | 100   | 0                | TYPE_LIMIT | TIF_GTC | ref-1     |
    
    # all general acc balance goes to margin account for the order, 'party1' should have 100*100*3 
    # in the margin account as its Position*Markprice*Initialfactor
    And the parties should have the following account balances:
      | party  | asset | market id | margin   | general   |
      | party1 | USD   | ETH/DEC19 | 30000    |  0        |
    
     # then party2 places an order, this trades with party1 and we calculate the margins again
     When the parties place the following orders:
       | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
       | party2 | ETH/DEC19 | buy  | 100    | 100   | 1                | TYPE_LIMIT | TIF_GTC | ref-1     |
    
    And the mark price should be "100" for the market "ETH/DEC19"
    And the insurance pool balance should be "15000" for the market "ETH/DEC19" 
    And the parties should have the following account balances:
      | party  | asset | market id | margin   | general   |
      | party1 | USD   | ETH/DEC19 | 30000    |  0        |
      | party2 | USD   | ETH/DEC19 | 30000    |  49970000 |

    When the parties place the following orders:
      | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
      | party2 | ETH/DEC19 | buy  | 1      | 126   | 0                | TYPE_LIMIT | TIF_GTC | ref-1-xxx |
      | party3 | ETH/DEC19 | sell | 1      | 126   | 1                | TYPE_LIMIT | TIF_GTC | ref-1-xxx |
    Then the mark price should be "126" for the market "ETH/DEC19"    
    And the insurance pool balance should be "40000" for the market "ETH/DEC19" 

    #party1 gets closeout with MTM 
    And the following trades should be executed:
      | buyer   | price  | size | seller           | 
      | party1  |  150   | 100  | network          | 
      | network |  150   | 100  | sellSideProvider |

    Then the mark price should be "126" for the market "ETH/DEC19"   

    Then the parties should have the following margin levels:
      | party  | market id | maintenance | search | initial | release  |
      | party3 | ETH/DEC19 | 276         | 552    | 828     | 1380     |

   # how to explain the margin acc for party3?????????????????
    Then the parties should have the following account balances:
      | party            | asset | market id | margin    | general     |
      | party1           | USD   | ETH/DEC19 | 0         |  0          |
      | party2           | USD   | ETH/DEC19 | 38900     |  49963700   |
      | party3           | USD   | ETH/DEC19 | 600       |  29400      |
      | aux1             | USD   | ETH/DEC19 | 1324      |  999998650  |
      | aux2             | USD   | ETH/DEC19 | 986       |  999999040  |
      | sellSideProvider | USD   | ETH/DEC19 | 758400    |  999244000  |
      | buySideProvider  | USD   | ETH/DEC19 | 540000    |  999460000  |

   # And the cumulated balance for all accounts should be worth "4050075000" 
    # And the insurance pool balance should be "40000" for the market "ETH/DEC19" 

    # # order book volume change
    # Then the parties cancel the following orders:
    #   | party           | reference        |
    #   | sellSideProvider|  sell-provider-1 |
    #   | buySideProvider | buy-provider-1   |

    # When the parties place the following orders:
    #   | party            | market id | side | volume | price | resulting trades | type       | tif     | reference |
    #   | sellSideProvider | ETH/DEC19 | sell | 1000   | 500   | 0                | TYPE_LIMIT | TIF_GTC | sell-provider-2 |
    #   | buySideProvider  | ETH/DEC19 | buy  | 1000   | 20    | 0                | TYPE_LIMIT | TIF_GTC | buy-provider-2  |
    
    # And the parties should have the following account balances:
    #   | party  | asset | market id | margin   | general   |
    #   | party2 | USD   | ETH/DEC19 | 38900    |  49963700 |
    #   | party3 | USD   | ETH/DEC19 | 600      |  29400    |

    # When the parties place the following orders:
    #   | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
    #   | party2 | ETH/DEC19 | buy  | 50     | 30    | 0                | TYPE_LIMIT | TIF_GTC | ref-2-xxx |
    #   | party3 | ETH/DEC19 | sell | 50     | 30    | 1                | TYPE_LIMIT | TIF_GTC | ref-3-xxx |

    # And the parties should have the following account balances:
    #   | party  | asset | market id | margin   | general   |
    #   | party2 | USD   | ETH/DEC19 | 18120    | 49974784  |
    #   | party3 | USD   | ETH/DEC19 | 30096    |  0        |

    # When the parties place the following orders:
    #   | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
    #   | party2 | ETH/DEC19 | buy  | 50     | 30    | 0                | TYPE_LIMIT | TIF_GTC | ref-2-xxx |
    #   | party3 | ETH/DEC19 | sell | 50     | 30    | 1                | TYPE_LIMIT | TIF_GTC | ref-3-xxx |

    # And the following trades should be executed:
    #   | buyer   | price  | size | seller           | 
    #   | party3  |  500   | 50   | network          | 
    #   #| network |  500   | 50  | sellSideProvider |
    #   | network |  500   | 50  | aux1 |

    # And the insurance pool balance should be "22826" for the market "ETH/DEC19" 

    # # When the parties place the following orders:
    # #   | party            | market id | side | volume  | price | resulting trades | type       | tif     | reference |
    # #   | sellSideProvider | ETH/DEC19 | sell | 1       | 150   | 0                | TYPE_LIMIT | TIF_GTC | sell-provider-2 |
    # #   | buySideProvider  | ETH/DEC19 | buy  | 1       | 150   | 1                | TYPE_LIMIT | TIF_GTC | buy-provider-2  |

    #   #party3 gets closeout with MTM 
    #   And the parties should have the following account balances:
    #     | party  | asset | market id | margin   | general   |
    #     | party1 | USD   | ETH/DEC19 | 0        |  0        |
    #     | party2 | USD   | ETH/DEC19 | 22620   |  49970284 |
    #     | party3 | USD   | ETH/DEC19 | 0        |  0        |

    # And the insurance pool balance should be "22826" for the market "ETH/DEC19" 

    # Then the parties should have the following profit and loss:
    #    | party  | volume | unrealised pnl | realised pnl |
    #    | party1 | 0      | 0              | -30000       |
    #    | party2 | 201    | -7096          | 0            |
    #    | party3 | 0      | 0              | -30000       |

  
Feature: Replicate LP getting distressed during continuous trading, and after leaving an auction

  Background:
    Given the following network parameters are set:
      | name                                          | value |
      | market.stake.target.timeWindow                | 24h   |
      | market.stake.target.scalingFactor             | 1     |
      | market.liquidity.bondPenaltyParameter         | 0     |
      | market.liquidity.targetstake.triggering.ratio | 0.1   |
    And the average block duration is "1"
    # And the simple risk model named "simple-risk-model-1":
    #   | long | short | max move up | min move down | probability of trading |
    #   | 0.1  | 0.1   | 10          | 10           | 0.2                    |
    And the log normal risk model named "log-normal-risk-model-1":
      | risk aversion | tau | mu | r   | sigma |
      | 0.000001      | 0.1 | 0  | 0. | 1.0    |
    And the fees configuration named "fees-config-1":
      | maker fee | infrastructure fee |
      | 0.004     | 0.001              |
    And the price monitoring updated every "1" seconds named "price-monitoring-1":
      | horizon | probability | auction extension |
      | 1       | 0.99        | 300               |
    And the markets:
      | id        | quote name | asset | risk model          | margin calculator         | auction duration | fees          | price monitoring   | oracle config          | maturity date        |
      | ETH/MAR22 | ETH        | USD   | log-normal-risk-model-1 | default-margin-calculator | 1                | fees-config-1 | price-monitoring-1 | default-eth-for-future | 2021-12-31T23:59:59Z |
    And the parties deposit on asset's general account the following amount:
      | party  | asset | amount     |
      | party0 | USD   | 500000     |
      | party1 | USD   | 100000000  |
      | party2 | USD   | 100000000  |
      | party3 | USD   | 100000000  |
      | party4 | USD   | 1000000000 |
      | party5 | USD   | 1000000000 |

  Scenario: LP gets distressed during continuous trading

    Given the parties submit the following liquidity provision:
      | id  | party   | market id | commitment amount | fee   | side | pegged reference | proportion | offset |
      | lp1 | party0 | ETH/MAR22 | 50000              | 0.001 | sell | ASK              | 500        | 10      |
      | lp1 | party0 | ETH/MAR22 | 50000              | 0.001 | buy  | BID              | 500        | -10     |
      
    And the parties place the following orders:
      | party  | market id | side | volume | price | resulting trades | type       | tif     | reference  |
      | party1 | ETH/MAR22 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-1  |
      | party1 | ETH/MAR22 | buy  | 1      | 990   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-1  |
      | party1 | ETH/MAR22 | buy  | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-2  |
      | party2 | ETH/MAR22 | sell | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-3 |
      | party2 | ETH/MAR22 | sell | 1      | 1010  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-1 |
      | party2 | ETH/MAR22 | sell | 1      | 1100  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-2 |

    When the opening auction period ends for market "ETH/MAR22"
    Then the auction ends with a traded volume of "10" at a price of "1000"
    # target_stake = mark_price x max_oi x target_stake_scaling_factor x rf = 1000 x 10 x 1 x 0.1
    And the insurance pool balance should be "0" for the market "ETH/MAR22"
    And the market data for the market "ETH/MAR22" should be:
      | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
      | 1000       | TRADING_MODE_CONTINUOUS | 1      | 1000      | 1000      | 35569        | 50000         | 10            |

    # #check the volume on the order book
    Then the order book should have the following volumes for market "ETH/MAR22":
      | side | price    | volume |
      | sell | 1100     | 1      |
      | sell | 1010     | 101    |
      | buy  | 990      | 103    |
      | buy  | 900      | 1      |
      
    # check the requried balances 
    And the parties should have the following account balances:
      | party  | asset | market id | margin | general  | bond |
      | party0 | USD   | ETH/MAR22 | 426829 | 23171    | 50000|
      | party1 | USD   | ETH/MAR22 | 12190  | 99987810 |  0   |
      | party2 | USD   | ETH/MAR22 | 51879  | 99948121 |  0   |
    #check the margin levels   
    Then the parties should have the following margin levels: 
      | party  | market id | maintenance | search | initial | release  |
      | party0 | ETH/MAR22 | 355691      | 391260 | 426829  | 497967   |
      | party1 | ETH/MAR22 | 10159       | 11174  | 12190   | 14222    |
      | party2 | ETH/MAR22 | 43233       | 47556  | 51879   | 60526    |
    #check position (party0 has no position)
    Then the parties should have the following profit and loss:
      | party  | volume | unrealised pnl | realised pnl |
      #| party0 | 10     | 0              | 0            |
      | party1 | 10     | 0              | 0            |
      | party2 |-10     | 0              | 0            |

    # # Now let's trigger price monitoring 
    # When the parties place the following orders:
    #   | party  | market id | side | volume | price | resulting trades | type       | tif     | reference      |
    #   | party3 | ETH/MAR22 | buy  | 30     | 1010  | 0                | TYPE_LIMIT | TIF_GTC | party3-buy-1   |
    #   | party2 | ETH/MAR22 | sell | 50     | 1010  | 0                | TYPE_LIMIT | TIF_GTC | party2-sell-4  |
    # And the trading mode should be "TRADING_MODE_MONITORING_AUCTION" for the market "ETH/MAR22"

    When the parties place the following orders:
      | party  | market id | side | volume | price | resulting trades | type       | tif     | reference      |
      | party3 | ETH/MAR22 | buy  | 30     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | party3-buy-1   |
      #| party2 | ETH/MAR22 | sell | 50     | 1000  | 2                | TYPE_LIMIT | TIF_GTC | party2-sell-4  |

    And the trading mode should be "TRADING_MODE_CONTINUOUS" for the market "ETH/MAR22"

    # #check the volume on the order book
    Then the order book should have the following volumes for market "ETH/MAR22":
      | side | price    | volume |
      | sell | 1100     | 1      |
      | sell | 1010     | 101    |
      | buy  | 1000     | 130    |
      | buy  | 990      | 1      |
      | buy  | 900      | 1      |
    When the parties place the following orders:
      | party  | market id | side | volume | price | resulting trades | type       | tif     | reference      |
      #| party3 | ETH/MAR22 | buy  | 30     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | party3-buy-1   |
      | party2 | ETH/MAR22 | sell | 50     | 1000  | 2                | TYPE_LIMIT | TIF_GTC | party2-sell-4  |

    And the market data for the market "ETH/MAR22" should be:
      | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
      | 1010       | TRADING_MODE_CONTINUOUS | 1       | 1000       | 1000      | 213414         | 50000           | 60            |
    # target_stake = mark_price x max_oi x target_stake_scaling_factor x rf = 1010 x 13 x 1 x 0.1
    # target stake 1313 with target trigger on 0.6 -> ~788 triggers liquidity auction

    And the parties should have the following account balances:
      | party  | asset | market id | margin | general  | bond |
      | party0 | USD   | ETH/MAR22 | 426829 | 23251    | 50000|
      | party1 | USD   | ETH/MAR22 | 12190  | 99987810 |  0   |
      | party2 | USD   | ETH/MAR22 | 264754 | 99734946 |  0   |

   Scenario: LP gets distressed after auction

    Given the parties submit the following liquidity provision:
      | id  | party   | market id | commitment amount | fee   | side | pegged reference | proportion | offset |
      | lp1 | party0 | ETH/MAR22  | 5000              | 0.001 | buy  | BID              | 500        | -10    |
      | lp1 | party0 | ETH/MAR22  | 5000              | 0.001 | sell | ASK              | 500        | 10     |
     # | lp2 | party5 | ETH/MAR22 | 5000              | 0.001 | buy  | BID              | 500        | -10    |
     # | lp2 | party5 | ETH/MAR22 | 5000              | 0.001 | sell | ASK              | 500        | 10     |

       And the parties should have the following account balances:
      | party  | asset | market id | margin | general  | bond |
      | party0 | USD   | ETH/MAR22 | 0      | 495000   | 5000|
      #| party1 | USD   | ETH/MAR22 | 12190  | 99987810 |  0   |
     # | party2 | USD   | ETH/MAR22 | 264754 | 99734946 |  0   |

    # And the parties place the following orders:
    #   | party  | market id | side | volume | price | resulting trades | type       | tif     | reference  |
    #   | party1 | ETH/DEC21 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-1  |
    #   | party1 | ETH/DEC21 | buy  | 1      | 990   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-2  |
    #   | party1 | ETH/DEC21 | buy  | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-3  |
    #   | party2 | ETH/DEC21 | sell | 1      | 1010  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-1 |
    #   | party2 | ETH/DEC21 | sell | 1      | 1100  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-2 |
    #   | party2 | ETH/DEC21 | sell | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-3 |

 
  #   #check the volume on the order book
  #   Then the order book should have the following volumes for market "ETH/MAR22":
  #     | side | price    | volume |∑∑
  #     | sell | 1010     | 5      |
  #     | sell | 1100     | 1      |
  #     | buy  | 900      | 1      |
  #     | buy  | 990      | 12     |
    
  #   And the parties should have the following account balances:
  #     | party  | asset | market id | margin | general | bond |
  #     | party0 | USD   | ETH/MAR22 | 1670   | 0       | 4217 |
  #   Then the parties should have the following margin levels: 
  #     | party  | market id | maintenance | search | initial | release  |
  #     | party0 | ETH/MAR22 | 1111        | 1222   | 1333    | 1555     |
  #     | party1 | ETH/MAR22 | 1412        | 1553   | 1694    | 1976     |
  #   #check position
  #   Then the parties should have the following profit and loss:
  #     | party  | volume | unrealised pnl | realised pnl |
  #     | party0 | -2     |  0             | 0            |
  #     | party1 | 10     |  100           | 0            |
  #     | party2 | -11    | -100           | 0            |

  #   # LP margin requirement increased, had to dip in to bond account to top up the margin

  #     #when penalty parameter is 1.5
  #     #| party0 | USD   | ETH/MAR22 | 1670   | 0       | 4348 | 
  #     #when penalty parameter is 2
  #     #| party0 | USD   | ETH/MAR22 | 1670   | 0       | 4217 | 
  #     #when penalty parameter is 3
  #     #| party0 | USD   | ETH/MAR22 | 1670   | 0       | 3956 | 
  #     #when penalty parameter is 4
  #     #| party0 | USD   | ETH/MAR22 | 1670   | 0       | 3695 | 









  #   # progress time a bit, so the price bounds get updated
  #   When the network moves ahead "2" blocks„
  #   And the parties should have the following account balances:
  #     | party  | asset | market id | margin | general | bond |
  #     | party0 | USD   | ETH/MAR22 | 1670   | 5       | 4217 |
  #   #check the margin levels
  #   Then the parties should have the following margin levels:
  #     | party  | market id | maintenance | search | initial | release  |
  #     | party0 | ETH/MAR22 | 1111        | 1222   | 1333    | 1555     |
  #     | party1 | ETH/MAR22 | 1412        | 1553   | 1694    | 1976     |
  #     #check position
  #   Then the parties should have the following profit and loss:
  #     | party  | volume | unrealised pnl | realised pnl |
  #     | party0 | -2     |  0             | 0            |
  #     | party1 | 10     |  100           | 0            |
  #     | party2 | -11    | -100           | 0            |
  #   And the parties place the following orders:
  #     | party  | market id | side | volume | price | resulting trades | type       | tif     | reference     |
  #     | party2 | ETH/MAR22 | sell | 15     | 1030  | 0                | TYPE_LIMIT | TIF_GTC | party2-sell-1 |
  #     | party3 | ETH/MAR22 | buy  | 10     | 1022  | 2                | TYPE_LIMIT | TIF_GTC | party3-buy-1  |
  #     | party3 | ETH/MAR22 | buy  | 3      | 1020  | 0                | TYPE_LIMIT | TIF_GTC | party3-buy-2  |
  #     | party2 | ETH/MAR22 | sell | 5      | 1030  | 0                | TYPE_LIMIT | TIF_GTC | party2-sell-2 |

  #   Then the order book should have the following volumes for market "ETH/MAR22":
  #     | side | price    | volume |
  #     | sell | 1100     | 1      |
  #     | sell | 1030     | 20     |
  #     | buy  | 900      | 1      |
  #     | buy  | 990      | 1      |
  #    Then the parties should have the following profit and loss:
  #     | party  | volume | unrealised pnl | realised pnl |
  #     | party0 | -7      |  0            | 0            |
  #     | party1 | 10     |  100           | 0            |
  #     | party2 | -16    | -100           | 0            |

  #   #Supplied Stake is 0 after LP is closedout
  #   #party0 is closed out
  #   And the insurance pool balance should be "4207" for the market "ETH/MAR22"

  #   Then the market data for the market "ETH/MAR22" should be:
  #     | mark price | trading mode                    | horizon | min bound | max bound | target stake | supplied stake | open interest |
  #     | 1010       | TRADING_MODE_MONITORING_AUCTION | 1       | 993       | 1012      | 2323         | 0              | 23            |
  #   # getting closer to distressed LP, still in continuous trading

  # #   # When the network moves ahead "2" blocks
  # #   # And the parties place the following orders:
  # #   #   | party  | market id | side | volume | price | resulting trades | type       | tif     | reference      |
  # #   #   | party3 | ETH/MAR22 | buy  | 3      | 1012  | 0                | TYPE_LIMIT | TIF_GTC | party3-buy-3  |
  # #   #   | party2 | ETH/MAR22 | sell | 5      | 1012  | 2                | TYPE_LIMIT | TIF_GTC | party2-sell-3 |
  # #   # Then the market data for the market "ETH/MAR22" should be:
  # #   #   | mark price | trading mode                    | horizon | min bound | max bound | target stake | supplied stake | open interest |
  # #   #   | 1012       | TRADING_MODE_MONITORING_AUCTION | 1       | 1000      | 1020      | 2834         | 0              | 28            |
  # #   # And the parties should have the following account balances:
  # #   #   | party  | asset | market id | margin | general | bond |
  # #   #   | party0 | ETH   | ETH/MAR22 | 1787   | 0       | 0    |
  # #   # # make sure bond slashing moved money to insurance pool
  # #   # And the insurance pool balance should be "4646" for the market "ETH/MAR22"


  # Scenario: LP gets distressed after auction

  #   Given the parties submit the following liquidity provision:
  #     | id  | party   | market id | commitment amount | fee   | side | pegged reference | proportion | offset |
  #     | lp1 | party0 | ETH/MAR22 | 5000              | 0.001 | buy  | BID              | 500        | -10    |
  #     | lp1 | party0 | ETH/MAR22 | 5000              | 0.001 | sell | ASK              | 500        | 10     |
  #     | lp2 | party5 | ETH/MAR22 | 5000              | 0.001 | buy  | BID              | 500        | -10    |
  #     | lp2 | party5 | ETH/MAR22 | 5000              | 0.001 | sell | ASK              | 500        | 10     |

  #   And the parties place the following orders:
  #     | party  | market id | side | volume | price | resulting trades | type       | tif     | reference  |
  #     | party1 | ETH/MAR22 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-1  |
  #     | party1 | ETH/MAR22 | buy  | 1      | 990   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-2  |
  #     | party1 | ETH/MAR22 | buy  | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-3  |
  #     | party2 | ETH/MAR22 | sell | 1      | 1010  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-1 |
  #     | party2 | ETH/MAR22 | sell | 1      | 1100  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-2 |
  #     | party2 | ETH/MAR22 | sell | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-3 |

  #   # this is a bit pointless, we're still in auction, price bounds aren't checked
  #   # And the price monitoring bounds are []

  #   When the opening auction period ends for market "ETH/MAR22"
  #   Then the auction ends with a traded volume of "10" at a price of "1000"
  #   # target_stake = mark_price x max_oi x target_stake_scaling_factor x rf = 1000 x 10 x 1 x 0.1
  #   And the market data for the market "ETH/MAR22" should be:
  #     | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
  #     | 1000       | TRADING_MODE_CONTINUOUS | 1       | 990       | 1010      | 1000         | 10000          | 10            |
  #   # check the requried balances
  #   And the parties should have the following account balances:
  #     | party  | asset | market id | margin | general | bond |
  #     | party0 | USD   | ETH/MAR22 | 1320   | 80      | 5000 |

  #   # Now let's make some trades happen to increase the margin for LP
  #   When the parties place the following orders:
  #     | party  | market id | side | volume | price | resulting trades | type       | tif     | reference      |
  #     | party3 | ETH/MAR22 | buy  | 3      | 1010  | 2                | TYPE_LIMIT | TIF_GTC | party3-buy-4  |
  #     | party2 | ETH/MAR22 | sell | 5      | 1010  | 0                | TYPE_LIMIT | TIF_GTC | party2-sell-4 |
  #   # target stake 1313 with target trigger on 0.6 -> ~788 triggers liquidity auction
  #   Then the market data for the market "ETH/MAR22" should be:
  #     | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
  #     | 1010       | TRADING_MODE_CONTINUOUS | 1       | 990       | 1010      | 1313         | 10000          | 13            |
  #   # LP margin requirement increased, had to dip in to bond account to top up the margin
  #   And the parties should have the following account balances:
  #     | party  | asset | market id | margin | general | bond |
  #     | party0 | USD   | ETH/MAR22 | 1670   | 0       | 4217 |

  #   # progress time a bit, so the price bounds get updated
  #   When the network moves ahead "2" blocks
  #   And the parties place the following orders:
  #     | party  | market id | side | volume | price | resulting trades | type       | tif     | reference      |
  #     | party3 | ETH/MAR22 | buy  | 10     | 1022  | 2                | TYPE_LIMIT | TIF_GTC | party3-buy-5  |
  #     | party2 | ETH/MAR22 | sell | 75     | 1050  | 0                | TYPE_LIMIT | TIF_GTC | party2-sell-5 |
  #     | party3 | ETH/MAR22 | buy  | 3      | 1020  | 0                | TYPE_LIMIT | TIF_GTC | party2-sell-6 |
  #   Then the market data for the market "ETH/MAR22" should be:
  #     | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
  #     | 1010       | TRADING_MODE_CONTINUOUS | 1       | 993       | 1012      | 2323         | 5000           | 23            |
  #   # getting closer to distressed LP, still in continuous trading
  #   And the parties should have the following account balances:
  #     | party  | asset | market id | margin | general | bond |
  #     | party0 | USD   | ETH/MAR22 | 0      | 0       | 0    |
  #   And the insurance pool balance should be "6331" for the market "ETH/MAR22"

  #   # Move price out of bounds
  #   When the network moves ahead "2" blocks
  #   And the parties place the following orders:
  #     | party  | market id | side | volume | price | resulting trades | type       | tif     |
  #     | party3 | ETH/MAR22 | buy  | 10     | 1060  | 0                | TYPE_LIMIT | TIF_GTC |
  #   Then the market data for the market "ETH/MAR22" should be:
  #     | mark price | trading mode                    | auction trigger       | target stake | supplied stake | open interest |
  #     | 1010       | TRADING_MODE_MONITORING_AUCTION | AUCTION_TRIGGER_PRICE | 2323         | 5000           | 23            |
  #   And the parties should have the following account balances:
  #     | party  | asset | market id | margin | general | bond |
  #     | party0 | USD   | ETH/MAR22 | 0   | 0       | 0    |

  #   # end price auction
  #   When the network moves ahead "301" blocks
  #   Then the market data for the market "ETH/MAR22" should be:
  #     | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
  #     | 1055       | TRADING_MODE_CONTINUOUS | 1       | 1045      | 1065      | 3481         | 5000           | 33            |
  #   And the parties should have the following account balances:
  #     | party  | asset | market id | margin | general | bond |
  #     | party0 | USD   | ETH/MAR22 | 0      | 0       | 0    |
  #     # values before uint stuff
  #     # | party0 | ETH   | ETH/MAR22 | 253    | 1419    | 0    |
  #   And the insurance pool balance should be "6331" for the market "ETH/MAR22"

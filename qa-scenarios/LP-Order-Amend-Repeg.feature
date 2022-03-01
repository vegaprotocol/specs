Feature: Replicate LP getting distressed during continuous trading, check if penalty is implemented correctly

  Background:
    Given the following network parameters are set:
      | name                                          | value |
      | market.stake.target.timeWindow                | 24h   |
      | market.stake.target.scalingFactor             | 1     |
      | market.liquidity.bondPenaltyParameter         | 0     |
      | market.liquidity.targetstake.triggering.ratio | 0.1   |
    And the average block duration is "1"
    And the log normal risk model named "log-normal-risk-model-1":
      | risk aversion | tau | mu | r   | sigma |
      | 0.000001      | 0.1 | 0  | 0  | 1.0    |
      #risk factor short 3.5569036
      #risk factor long 0.801225765
    And the fees configuration named "fees-config-1":
      | maker fee | infrastructure fee |
      | 0.004     | 0.001              |
    # horizon is in seconds
    And the price monitoring updated every "1" seconds named "price-monitoring-1":
      | horizon | probability | auction extension |
      | 2000000 | 0.99        | 300               |
    And the markets:
      | id        | quote name | asset | risk model              | margin calculator         | auction duration | fees          | price monitoring   | oracle config          | maturity date        |
      | ETH/MAR22 | ETH        | USD   | log-normal-risk-model-1 | default-margin-calculator | 1                | fees-config-1 | price-monitoring-1 | default-eth-for-future | 2021-12-31T23:59:59Z |
    And the parties deposit on asset's general account the following amount:
      | party  | asset | amount     |
      | party0 | USD   | 500000     |
      | party1 | USD   | 100000000  |
      | party2 | USD   | 100000000  |
      | party3 | USD   | 100000000  |

  Scenario: LP gets distressed during continuous trading

    Given the parties submit the following liquidity provision:
      | id  | party   | market id | commitment amount | fee   | side | pegged reference | proportion | offset | lp type   | 
      | lp1 | party0 | ETH/MAR22 | 50000              | 0.001 | sell | ASK              | 500        | 20     | submission|
      | lp1 | party0 | ETH/MAR22 | 50000              | 0.001 | buy  | BID              | 500        | 20     | amendment |
      
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
      | 1000       | TRADING_MODE_CONTINUOUS | 2000000 | 507       | 1852      | 35569        | 50000          | 10            |

    # margin maintenance level for party1: 10*(1000*0.801225765+55)+2*1000*0.801225765=10165

    #check the volume on the order book
    Then the order book should have the following volumes for market "ETH/MAR22":
      | side | price    | volume |
      | sell | 1100     | 1      |
      | sell | 1030     | 105    |
      | sell | 1020     | 0      |
      | sell | 1010     | 1      |
      | sell | 1000     | 0      |
      | buy  | 1000     | 0      |
      | buy  | 990      | 1      |
      | buy  | 970      | 109    |
      | buy  | 980      | 0      |
      | buy  | 900      | 1      |

     #party0 has lp short order vol 105 in price 1030, and long order vol 109 at price 970
     #maintenance_margin_short = 105*1000*3.5569036=373475
     #maintenance_margin_long =109*1000*0.801225765=87334
     #maintenance_margin = max ( maintenance_margin_long, maintenance_margin_short)=373475

    # check the requried balances 
    And the parties should have the following account balances:
      | party  | asset | market id | margin | general  | bond |
      | party0 | USD   | ETH/MAR22 | 448170 | 1830     | 50000|
      | party1 | USD   | ETH/MAR22 | 12190  | 99987810 |  0   |
      | party2 | USD   | ETH/MAR22 | 51879  | 99948121 |  0   |
    #check the margin levels   
    Then the parties should have the following margin levels: 
      | party  | market id | maintenance | search | initial | release  |
      | party0 | ETH/MAR22 | 373475      | 410822 | 448170  | 522865   |
      | party1 | ETH/MAR22 | 10159       | 11174  | 12190   | 14222    |
      | party2 | ETH/MAR22 | 43233       | 47556  | 51879   | 60526    |
    #check position (party0 has no position)
    Then the parties should have the following profit and loss:
      | party  | volume | unrealised pnl | realised pnl |
      | party1 | 10     | 0              | 0            |
      | party2 |-10     | 0              | 0            |

       Given the parties submit the following liquidity provision:
      | id  | party   | market id | commitment amount | fee   | side | pegged reference | proportion | offset | lp type   | 
      | lp1 | party0 | ETH/MAR22 | 50000              | 0.001 | sell | ASK              | 500        | 10     | amendment|
      | lp1 | party0 | ETH/MAR22 | 50000              | 0.001 | buy  | BID              | 500        | 10     | amendment |

  #check the volume on the order book
    Then the order book should have the following volumes for market "ETH/MAR22":
      | side | price    | volume |
      | sell | 1100     | 1      |
      | sell | 1020     | 102    |
      | sell | 1010     | 1      |
      | sell | 1000     | 0      |
      | buy  | 1000     | 0      |
      | buy  | 990      | 1      |
      | buy  | 980      | 105    |
      | buy  | 900      | 1      |
   
    #party0 has lp short order vol 102 in price 1020, and long order vol 105 at price 980
     #maintenance_margin_short = 102*1000*3.5569036=362804
     #maintenance_margin_long =105*1000*0.801225765=84129
     #maintenance_margin = max ( maintenance_margin_long, maintenance_margin_short)=362804
   # check the requried balances 
    And the parties should have the following account balances:
      | party  | asset | market id | margin | general  | bond |
      | party0 | USD   | ETH/MAR22 | 435366 | 14634    | 50000|
      | party1 | USD   | ETH/MAR22 | 12190  | 99987810 |  0   |
      | party2 | USD   | ETH/MAR22 | 51879  | 99948121 |  0   |
    #check the margin levels   
    Then the parties should have the following margin levels: 
      | party  | market id | maintenance | search | initial | release  |
      | party0 | ETH/MAR22 | 362805      | 399085 | 435366  | 507927   |
      | party1 | ETH/MAR22 | 10159       | 11174  | 12190   | 14222    |
      | party2 | ETH/MAR22 | 43233       | 47556  | 51879   | 60526    |

    When the parties place the following orders:
      | party  | market id | side | volume | price | resulting trades | type       | tif     | reference      |
      | party0 | ETH/MAR22 | sell | 15     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | party0-sell-3  |

   And the market data for the market "ETH/MAR22" should be:
      | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
      | 1000       | TRADING_MODE_CONTINUOUS | 2000000 | 507       | 1852      | 35569       | 50000          | 10            |

  And the insurance pool balance should be "0" for the market "ETH/MAR22"
    #check the volume on the order book
    Then the order book should have the following volumes for market "ETH/MAR22":
      | side | price    | volume |
      | sell | 1100     | 1      |
      | sell | 1010     | 89     |
      | sell | 1000     | 15     |
      | sell | 1020     | 0      |
      | buy  | 1000     | 0      |
      | buy  | 990      | 1      |
      | buy  | 980      | 105    |
      | buy  | 900      | 1      |

     #party0 has reeged lp short order, vol 88 in price 1010, vol 15 at price 1000; and long order vol 105 at price 980
     #maintenance_margin_short = (88+15)*1000*3.5569036=366361
     #maintenance_margin_long =105*1000*0.801225765=84129
     #maintenance_margin = max ( maintenance_margin_long, maintenance_margin_short)=362804
   
     # margin initial level is 366361*1.2 = 439633, hence margin account should be 439633, general account should be 450000-439633 = 10367, and bond account should be 50000
    And the parties should have the following account balances:
      | party  | asset | market id | margin | general  | bond |
      | party0 | USD   | ETH/MAR22 | 499389 | 0        | 611  |
      | party1 | USD   | ETH/MAR22 | 12190  | 99987810 |  0   |
      | party2 | USD   | ETH/MAR22 | 51879  | 99948121 |  0   |
    #check the margin levels   
    Then the parties should have the following margin levels: 
      | party  | market id | maintenance | search | initial | release  |
      | party0 | ETH/MAR22 | 366362      | 402998 | 439634  | 512906   |
      | party1 | ETH/MAR22 | 10159       | 11174  | 12190   | 14222    |
      | party2 | ETH/MAR22 | 43233       | 47556  | 51879   | 60526    |
# Test LP bond slashing
# We will work with ETHUSD with two dps so current ETHUSD of 2.270k is 227000
Feature: Test margin for lp near price monitoring boundaries
  Background:
    Given the following network parameters are set:
      | name                                                | value |
      | market.value.windowLength                           | 1h    |
      | market.stake.target.timeWindow                      | 24h   |
      | market.stake.target.scalingFactor                   | 1     |
      | market.liquidity.targetstake.triggering.ratio       | 0     |
      | market.liquidity.providers.fee.distributionTimeStep | 10m   |
      | market.liquidity.bondPenaltyParameter               | 0.1   |
    
    And the average block duration is "1"

  Scenario: first bond slashing test

    And the log normal risk model named "log-normal-risk-model-zz":
      | risk aversion | tau     | mu | r   | sigma  |
      | 0.000001      | 0.00273 | 0  | 0   |  1.2   |
    And the fees configuration named "fees-config-1":
      | maker fee | infrastructure fee |
      | 0.004     | 0.001              |
    And the price monitoring updated every "1" seconds named "price-monitoring-2":
      | horizon | probability  | auction extension |
      | 43200   | 0.9999       | 300                 |
    And the markets:
      | id         | quote name | asset | risk model               | margin calculator         | auction duration | fees          | price monitoring   | oracle config          | maturity date        |
      | ETH/MAR22  | ETHUSD     | USD   | log-normal-risk-model-zz | default-margin-calculator | 1                | fees-config-1 | price-monitoring-2 | default-eth-for-future | 2022-03-31T23:59:59Z |
    And the oracles broadcast data signed with "0xDEADBEEF":
      | name                | value    |
      | prices.ETHUSD.value | 227000   |
    And the traders deposit on asset's general account the following amount:
      | trader  | asset | amount       |
      | lp1     | USD   | 53940000     |
      | trader1 | USD   | 10000000     |
      | trader2 | USD   | 10000000     |
    
    Given the traders submit the following liquidity provision:
      | id          | party   | market id | commitment amount | fee   | side       | pegged reference | proportion       | offset       |
      | commitment1 | lp1     | ETH/MAR22 | 20000000          | 0.001 | buy        | BID              | 500              | 0            |
      | commitment1 | lp1     | ETH/MAR22 | 20000000          | 0.001 | sell       | ASK              | 500              | 0            |
 
    And the traders place the following orders:
      | trader  | market id | side | volume | price     | resulting trades | type       | tif     | reference  |
      | lp1     | ETH/MAR22 | buy  | 191    | 210000    | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-1  |
      | trader1 | ETH/MAR22 | buy  | 10     | 220000    | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-2  |
      | trader2 | ETH/MAR22 | sell | 10     | 220000    | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-2 |
      | lp1     | ETH/MAR22 | sell | 174    | 230000    | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-1 |
      
    When the opening auction period ends for market "ETH/MAR22"
    Then the auction ends with a traded volume of "10" at a price of "220000"

    And the traders should have the following profit and loss:
      | trader           | volume | unrealised pnl | realised pnl |
      | trader1          |  10    | 0              | 0            |
      | trader2          | -10    | 0              | 0            |

    And the market data for the market "ETH/MAR22" should be:
       | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
       | 220000     | TRADING_MODE_CONTINUOUS | 43200   | 184917    | 261224    | 794625       | 20000000       | 10            |
    
    And the traders should have the following margin levels:
       | trader    | market id  | maintenance | search   | initial  | release  |
       | lp1       | ETH/MAR22  | 27652950    | 30418245 | 33183540 | 38714130 |
       | trader1   | ETH/MAR22  | 689888      | 758876   | 827865   | 965843   |
       | trader2   | ETH/MAR22  | 894625      | 984087   | 1073550  | 1252475  |

    And the traders should have the following account balances:
      | trader    | asset | market id | margin      | general    | bond     |
      | lp1       | USD   | ETH/MAR22 | 33937710    | 2290       | 20000000 |


    And the order book should have the following volumes for market "ETH/MAR22":
       | side | price      | volume |
       | buy  | 209900     | 0      |
       | buy  | 210000     | 191    |
       | sell | 230000     | 174    |
       | sell | 230100     | 0      |

    # # The initial setup is done. 
    
    # Then the traders place the following orders:
    #     | trader  | market id | side | volume | price    | resulting trades | type       | tif     | 
    #     | trader1 | ETH/MAR22 | buy  | 1      | 230000   | 1                | TYPE_LIMIT | TIF_GTC | 
        
    # And the traders should have the following profit and loss:
    #     | trader           | volume | unrealised pnl | realised pnl |
    #     | trader1          |  11    | 100000         | 0            |
    #     | trader2          | -10    | -100000        | 0            |

    # And the market data for the market "ETH/MAR22" should be:
    #      | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
    #      | 230000     | TRADING_MODE_CONTINUOUS | 43200   | 184917    | 261224    | 913819       | 20000000       | 11            |

    # And the traders should have the following account balances:
    #     | trader    | asset | market id | margin      | general    | bond     |
    #     | lp1       | USD   | ETH/MAR22 | 17445631    | 16495289   | 20000000 |

    # Then the traders place the following orders:
    #   | trader  | market id | side | volume | price     | resulting trades | type       | tif     | reference  |
    #   | lp1     | ETH/MAR22 | buy  | 165     | 200000    | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-1  |
    #   | lp1     | ETH/MAR22 | sell | 165     | 240000    | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-1 |
    
    # And the traders should have the following account balances:
    #     | trader    | asset | market id | margin      | general    | bond     |
    #     | lp1       | USD   | ETH/MAR22 | 33894368    | 46552      | 20000000 |
    
    # And the insurance pool balance should be "0" for the market "ETH/MAR22"

    # This is where we place the volume that pushes us over the line

    # Then the traders place the following orders:
    #   | trader  | market id | side | volume | price     | resulting trades | type       | tif     | 
    #   | lp1     | ETH/MAR22 | buy  | 10     | 200000    | 0                 | TYPE_LIMIT | TIF_GTC | 
    #   | lp1     | ETH/MAR22 | sell | 10     | 240000    | 0                 | TYPE_LIMIT | TIF_GTC | 
    
    # And the traders should have the following account balances:
    #   | trader    | asset | market id | margin      | general    | bond     |
    #   | lp1       | USD   | ETH/MAR22 | 34791572    | 0          | 19064283 |
    
    # And the insurance pool balance should be "85065" for the market "ETH/MAR22"

    # Once the above works we will make trader1 and trader2 make a trade which will shift the mark 
    # price in such a way that lp1 is getting a positive mark-to-market cash flow and we'll check it
    # goes into the bond account first.
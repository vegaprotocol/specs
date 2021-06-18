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
    
    And the average block duration is "1"

  Scenario: first bond slashing test

    And the log normal risk model named "log-normal-risk-model-1":
      | risk aversion | tau     | mu | r   | sigma  |
      | 0.000001      | 0.00273 | 0  | 0   |  1.2   |
    And the fees configuration named "fees-config-1":
      | maker fee | infrastructure fee | liquidity fee |
      | 0.004     | 0.001              | 0.003           |
    And the price monitoring updated every "1" seconds named "price-monitoring-2":
      | horizon | probability  | auction extension |
      | 43200   | 0.9999       | 300                 |
    And the markets:
      | id         | quote name | asset | risk model              | margin calculator         | auction duration | fees          | price monitoring   | oracle config          | maturity date        |
      | ETH/MAR22  | ETHUSD     | USD   | log-normal-risk-model-1 | default-margin-calculator | 1                | fees-config-1 | price-monitoring-2 | default-eth-for-future | 2022-03-31T23:59:59Z |
    And the oracles broadcast data signed with "0xDEADBEEF":
      | name                | value    |
      | prices.ETHUSD.value | 227000   |
    And the traders deposit on asset's general account the following amount:
      | trader  | asset | amount       |
      | lp1     | USD   | 36700000     |
      | trader1 | USD   | 10000000     |
      | trader2 | USD   | 10000000     |
    
    Given the traders submit the following liquidity provision:
      | id          | party   | market id | commitment amount | fee   | order side | order reference | order proportion | order offset |
      | commitment1 | lp1     | ETH/MAR22 | 20000000          | 0.001 | buy        | BID             | 500              | 0            |
      | commitment1 | lp1     | ETH/MAR22 | 20000000          | 0.001 | sell       | ASK             | 500              | 0            |
 
    And the traders place the following orders:
      | trader  | market id | side | volume | price     | resulting trades | type       | tif     | reference  |
      | lp1     | ETH/MAR22 | buy  | 1      | 210000    | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-1  |
      | trader1 | ETH/MAR22 | buy  | 10     | 220000    | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-2  |
      | trader2 | ETH/MAR22 | sell | 10     | 220000    | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-2 |
      | lp1     | ETH/MAR22 | sell | 1      | 230000    | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-1 |
      
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
       | lp1       | ETH/MAR22  | 13826475    | 15209122 | 16591770 | 19357065 |
       | trader1   | ETH/MAR22  | 689888      | 758876   | 827865   | 965843   |
       | trader2   | ETH/MAR22  | 894625      | 984087   | 1073550  | 1252475  |

    And the traders should have the following account balances:
      | trader    | asset | market id | margin      | general    | bond     |
      | lp1       | USD   | ETH/MAR22 | 16591770    | 108230     | 20000000 |


    And the order book should have the following volumes for market "ETH/MAR22":
       | side | price      | volume |
       | buy  | 209900     | 0      |
       | buy  | 210000     | 191    |
       | sell | 230000     | 174    |
       | sell | 230100     | 0      |

    # The initial setup is done. We will now make trader1 buy progressively more until we empty the lp1 general balance
    # we also always want to shift the mark price back to 2.2k

    Then debug trades
    Then debug market data for "ETH/MAR22"

    Then the traders place the following orders:
       | trader  | market id | side | volume | price    | resulting trades | type       | tif     | 
       | trader1 | ETH/MAR22 | buy  | 173    | 230000   | 173              | TYPE_LIMIT | TIF_GTC | 
    #   | trader2 | ETH/MAR22 | sell | 1      | 220000   | 0                | TYPE_LIMIT | TIF_GTC |            |
    #   | trader1 | ETH/MAR22 | buy  | 1      | 220000   | 1                | TYPE_LIMIT | TIF_GTC |            |
    
    And the trading mode should be "TRADING_MODE_CONTINUOUS" for the market "ETH/MAR22"
    
    Then the traders should have the following profit and loss:
      | trader           | volume | unrealised pnl | realised pnl |
      | trader1          |  10    | 0              | 0            |
      | trader2          | -10    | 0              | 0            |

    And the market data for the market "ETH/MAR22" should be:
       | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
       | 220000     | TRADING_MODE_CONTINUOUS | 43200   | 184917    | 261224    | 794625       | 20000000       | 10            |

    And the traders should have the following account balances:
      | trader    | asset | market id | margin      | general    | bond     |
      | lp1       | USD   | ETH/MAR22 | 16591770    | 108230     | 20000000 |
      | trader1   | USD   | ETH/MAR22 | 827865      | 9172135    | 0        |



    Then the traders place the following orders:
       | trader  | market id | side | volume | price   | resulting trades | type       | tif     | reference  |
       | trader1 | ETH/MAR22 | buy  | 10     | 230000  | 10              | TYPE_LIMIT | TIF_GTC |            |
    

    # And the traders should have the following margin levels:
    #   | trader    | market id  | maintenance | search   | initial  | release  |
    #   | lp1       | ETH2/MAR22 | 1986563     | 2185219  | 2383875  | 2781188  |

    # # # now we place an order which makes the best bid 89943. 
    # Then the traders place the following orders:
    #     | trader  | market id  | side  | volume | price   | resulting trades   | type       | tif     | reference  |
    #     | trader1 | ETH2/MAR22 | buy   | 1      | 89943   | 0                 | TYPE_LIMIT | TIF_GTC | buy-ref-4  |
    
    # And the market data for the market "ETH2/MAR22" should be:
    #    | mark price   | trading mode            | horizon | min bound   | max bound   | target stake   | supplied stake | open interest  |
    #    | 100000       | TRADING_MODE_CONTINUOUS | 43200   | 89942       | 110965      | 361194         | 3000000        | 10             |
    

    # # # the lp1 one volume on this side should go to 89843 but because price monitoring bound is still 89942 it gets pushed to 89942.
    # # # but 89942 is no longer the best bid, so the risk model is used to get prob of trading. This now given by the log-normal model
    # # # Hence a bit volume is required to meet commitment and thus the margin requirement moves but not much.

    # And the order book should have the following volumes for market "ETH2/MAR22":
    #   | side | price    | volume |
    #   | sell | 110965   | 56     |
    #   | buy  | 89943    | 1      |
    #   | buy  | 89942    | 136    |


    # And the traders should have the following margin levels:
    #   | trader    | market id  | maintenance | search   | initial  | release |
    #   | lp1       | ETH2/MAR22 | 3592950     | 3952245  | 4311540  | 5030130 |


    

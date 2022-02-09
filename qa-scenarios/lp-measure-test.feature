Feature: Verify the order size is correctly cumulated.

  Background:

    Given the following network parameters are set:
      | name                                                | value |
      | market.value.windowLength                           | 1h    |
      | market.stake.target.timeWindow                      | 24h   |
      | market.stake.target.scalingFactor                   | 1     |
      | market.liquidity.targetstake.triggering.ratio       | 0     |
      | market.liquidity.providers.fee.distributionTimeStep | 10m   |

  Scenario: Order from liquidity provision and from normal order submission are correctly cumulated in order book's total size.

    And the log normal risk model named "my-log-normal-risk-model":
      | risk aversion | tau                    | mu | r     | sigma |
      | 0.001         | 0.00000190128526884174 | 0  | 0.016 | 2.5   |

    And the price monitoring updated every "1" seconds named "price-monitoring-1":
      | horizon | probability | auction extension |
      | 1       | 0.99        | 300               |

    And the markets:
      | id        | quote name | asset | risk model               | margin calculator         | auction duration | fees         | price monitoring | oracle config          |
      | ETH/DEC19 | ETH        | ETH   | my-log-normal-risk-model | default-margin-calculator | 1                | default-none | price-monitoring-1    | default-eth-for-future |

    Given the parties deposit on asset's general account the following amount:
      | party      | asset | amount       |
      | party1     | ETH   | 10000000     |
      | party2     | ETH   | 10000000     |
      | party-lp-1 | ETH   | 100000000000 |
      | party3     | ETH   | 1000000000   |

    # Trigger an auction to set the mark price
    When the parties place the following orders:
      | party  | market id | side | volume | price    | resulting trades | type       | tif     | reference|
      | party1 | ETH/DEC19 | buy  | 1      | 12000007 | 0                | TYPE_LIMIT | TIF_GTC | party1-1 |
      | party2 | ETH/DEC19 | sell | 1      | 12000020 | 0                | TYPE_LIMIT | TIF_GTC | party2-1 |
      | party1 | ETH/DEC19 | buy  | 1      | 12000010 | 0                | TYPE_LIMIT | TIF_GFA | party1-2 |
      | party2 | ETH/DEC19 | sell | 1      | 12000010 | 0                | TYPE_LIMIT | TIF_GFA | party2-2 |
    Then the opening auction period ends for market "ETH/DEC19"
    And the mark price should be "12000010" for the market "ETH/DEC19"

    When the parties place the following orders:
      | party      | market id | side | volume | price    | resulting trades | type       | tif     | reference |
      | party-lp-1 | ETH/DEC19 | sell | 50     | 12000013 | 0                | TYPE_LIMIT | TIF_GTC | party2-1 |
    And the parties submit the following liquidity provision:
      | id  | party       | market id | commitment amount| fee | side | pegged reference | proportion | offset | reference | lp type |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | buy  | MID              | 1          | 10     | lp-1-ref  | submission |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | buy  | MID              | 1          | 9      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | buy  | MID              | 1          | 8      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | buy  | MID              | 1          | 7      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | buy  | MID              | 1          | 6      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | buy  | MID              | 1          | 5      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | buy  | MID              | 1          | 4      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | buy  | MID              | 1          | 3      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | buy  | MID              | 1          | 2      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | sell | MID              | 1          | 4      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | sell | MID              | 1          | 5      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | sell | MID              | 1          | 6      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | sell | MID              | 1          | 7      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | sell | MID              | 1          | 8      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | sell | MID              | 1          | 9      | lp-1-ref  | amendment |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | 0.1 | sell | MID              | 1          | 10     | lp-1-ref  | amendment |

    Then the liquidity provisions should have the following states:
      | id  | party       | market    | commitment amount | status       |
      | lp1 | party-lp-1 | ETH/DEC19 | 1000000000        | STATUS_ACTIVE |

    And the trading mode should be "TRADING_MODE_CONTINUOUS" for the market "ETH/DEC19"

    And the orders should have the following states:
      | party      | market id | side | volume | price    | status        |
      | party-lp-1 | ETH/DEC19 | sell | 17     | 12000014 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | sell | 17     | 12000015 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | sell | 17     | 12000016 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | sell | 17     | 12000017 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | sell | 17     | 12000018 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | sell | 17     | 12000019 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | sell | 17     | 12000020 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | buy  | 19     | 12000008 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | buy  | 19     | 12000007 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | buy  | 19     | 12000006 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | buy  | 19     | 12000005 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | buy  | 19     | 12000004 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | buy  | 19     | 12000003 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | buy  | 19     | 12000002 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | buy  | 19     | 12000001 | STATUS_ACTIVE |
      | party-lp-1 | ETH/DEC19 | buy  | 19     | 12000000 | STATUS_ACTIVE |

    When the parties place the following orders:
      | party  | market id | side | volume | price    | resulting trades | type       | tif     | reference |
      | party3 | ETH/DEC19 | sell | 167    | 12000020 | 0                | TYPE_LIMIT | TIF_GTC | party3-1  |
      | party3 | ETH/DEC19 | sell | 50     | 12000019 | 0                | TYPE_LIMIT | TIF_GTC | party3-2  |
      | party3 | ETH/DEC19 | sell | 50     | 12000018 | 0                | TYPE_LIMIT | TIF_GTC | party3-3  |
      | party3 | ETH/DEC19 | sell | 50     | 12000017 | 0                | TYPE_LIMIT | TIF_GTC | party3-4  |
      | party3 | ETH/DEC19 | sell | 50     | 12000016 | 0                | TYPE_LIMIT | TIF_GTC | party3-5  |
      | party3 | ETH/DEC19 | sell | 50     | 12000015 | 0                | TYPE_LIMIT | TIF_GTC | party3-6  |
      | party3 | ETH/DEC19 | sell | 10     | 12000014 | 0                | TYPE_LIMIT | TIF_GTC | party3-7  |
      | party3 | ETH/DEC19 | buy  | 1      | 12000006 | 0                | TYPE_LIMIT | TIF_GTC | party3-8  |
      | party3 | ETH/DEC19 | buy  | 50     | 12000005 | 0                | TYPE_LIMIT | TIF_GTC | party3-9  |
      | party3 | ETH/DEC19 | buy  | 50     | 12000004 | 0                | TYPE_LIMIT | TIF_GTC | party3-10 |
      | party3 | ETH/DEC19 | buy  | 50     | 12000003 | 0                | TYPE_LIMIT | TIF_GTC | party3-11 |
      | party3 | ETH/DEC19 | buy  | 50     | 12000002 | 0                | TYPE_LIMIT | TIF_GTC | party3-12 |
      | party3 | ETH/DEC19 | buy  | 50     | 12000001 | 0                | TYPE_LIMIT | TIF_GTC | party3-13 |
      | party3 | ETH/DEC19 | buy  | 167    | 12000000 | 0                | TYPE_LIMIT | TIF_GTC | party3-14 |

    Then the order book should have the following volumes for market "ETH/DEC19":
      | side | price    | volume |
      | sell | 12000020 | 185    |
      | sell | 12000019 | 67     |
      | sell | 12000018 | 67     |
      | sell | 12000017 | 67     |
      | sell | 12000016 | 67     |
      | sell | 12000015 | 67     |
      | sell | 12000014 | 27     |
      | sell | 12000013 | 50     |
      | buy  | 12000008 | 19     |
      | buy  | 12000007 | 20     | # +1 here for the order used to set the midprice
      | buy  | 12000006 | 20     |
      | buy  | 12000005 | 69     |
      | buy  | 12000004 | 69     |
      | buy  | 12000003 | 69     |
      | buy  | 12000002 | 69     |
      | buy  | 12000001 | 69     |
      | buy  | 12000000 | 186    |

 Scenario:  Test volume when LP volume is pushed inside price monitoring bounds

  Given the log normal risk model named "log-normal-risk-model-1":
      | risk aversion | tau     | mu | r | sigma |
      | 0.000001      | 0.00273 | 0  | 0 | 1.2   |
    And the fees configuration named "fees-config-1":
      | maker fee | infrastructure fee |
      | 0.004     | 0.001              |
    And the price monitoring updated every "1" seconds named "price-monitoring-2":
      | horizon | probability | auction extension |
      | 43200   | 0.982       | 300               |
    And the markets:
      | id         | quote name | asset | risk model              | margin calculator         | auction duration | fees          | price monitoring   | oracle config          | maturity date        |
      | ETH2/MAR22 | ETH2       | ETH2  | log-normal-risk-model-1 | default-margin-calculator | 1                | fees-config-1 | price-monitoring-2 | default-eth-for-future | 2022-03-31T23:59:59Z |
    And the parties deposit on asset's general account the following amount:
      | party  | asset | amount    |
      | lp1    | ETH2  | 100000000 |
      | party1 | ETH2  | 10000000  |
      | party2 | ETH2  | 10000000  |

    And the parties submit the following liquidity provision:
       | id          | party | market id  | commitment amount | fee   | side | pegged reference | proportion | offset | lp type   |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | buy  | BID              | 500        | 100    | submission|
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | buy  | BID              | 500        | 90     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | buy  | BID              | 500        | 80     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | buy  | BID              | 500        | 70     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | buy  | BID              | 500        | 60     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | buy  | BID              | 500        | 50     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | buy  | BID              | 500        | 40     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | buy  | BID              | 500        | 30     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | sell | ASK              | 500        | 20     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | sell | ASK              | 500        | 40     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | sell | ASK              | 500        | 50     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | sell | ASK              | 500        | 60     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | sell | ASK              | 500        | 70     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | sell | ASK              | 500        | 80     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | sell | ASK              | 500        | 90     | amendment |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | sell | ASK              | 500        | 100    | amendment |

    And the parties place the following orders:
      | party  | market id  | side | volume | price | resulting trades | type       | tif     | reference  |
      | party1 | ETH2/MAR22 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-1  |
      | party1 | ETH2/MAR22 | buy  | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-2  |
      | party2 | ETH2/MAR22 | sell | 1      | 1109  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-1 |
      | party2 | ETH2/MAR22 | sell | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-2 |

    When the opening auction period ends for market "ETH2/MAR22"
    Then the auction ends with a traded volume of "10" at a price of "1000"

    And the parties should have the following profit and loss:
      | party  | volume | unrealised pnl | realised pnl |
      | party1 | 10     | 0              | 0            |
      | party2 | -10    | 0              | 0            |

    And the market data for the market "ETH2/MAR22" should be:
      | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
      | 1000       | TRADING_MODE_CONTINUOUS | 43200   | 900       | 1109      | 3611         | 50000000       | 10            |

    And the order book should have the following volumes for market "ETH2/MAR22":
      | side | price | volume |
      | sell | 1109  | 90177  |
      | sell | 1099  | 0  |
      | sell | 1089  | 0  |
      | sell | 1079  | 0  |
      | sell | 1069  | 0  |
      | sell | 1059  | 0  |
      | sell | 1049  | 0  |
      | sell | 1049  | 0  |
      | sell | 1029  | 0  |
      | sell | 1019  | 0  |
      | buy  | 1000  | 0  |
      | buy  | 990   | 0  |
      | buy  | 920   | 0  |
      | buy  | 900   | 111113 |
      | buy  | 920   | 0 |
      | buy  | 880   | 0 |

    # at this point what's left on the book is the buy @ 900 and sell @ 1109
    # so the best bid/ask coincides with the price monitoring bounds.
    # Since the lp1 offset is +/- 100 (depending on side) the lp1 volume "should" go to 800 and 1209
    # but because the price monitoring bounds are 900 and 1109 the volume gets pushed to these
    # i.e. it's placed at 900 / 1109.

    And the parties should have the following margin levels:
       | party | market id  | maintenance | search   | initial  | release  |
       | lp1    | ETH2/MAR22 | 32570956    | 35828051 | 39085147 | 45599338 |

    And the parties should have the following account balances:
      | party  | asset | market id  | margin   | general  | bond     |
      | lp1    | ETH2  | ETH2/MAR22 | 39085147 | 10914853 | 50000000 |

    Then the parties place the following orders:
      | party  | market id  | side | volume | price | resulting trades | type       | tif     | reference |
      | party1 | ETH2/MAR22 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-3 |

    And the market data for the market "ETH2/MAR22" should be:
      | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
      | 1000       | TRADING_MODE_CONTINUOUS | 43200   | 900       | 1109      | 3611         | 50000000       | 10            |
    And the order book should have the following volumes for market "ETH2/MAR22":
      | side | price | volume |
      | sell | 1109  | 90177  |
      | buy  | 901   | 0      |
      | buy  | 900   | 111114 |

    And the parties should have the following margin levels:
      | party | market id  | maintenance | search   | initial  | release  |
      | lp1    | ETH2/MAR22 | 32570956    | 35828051 | 39085147 | 45599338 |

    # now we place an order which makes the best bid 901.
    Then the parties place the following orders:
      | party  | market id  | side | volume | price | resulting trades | type       | tif     | reference |
      | party1 | ETH2/MAR22 | buy  | 1      | 901   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-4 |

    And the market data for the market "ETH2/MAR22" should be:
      | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
      | 1000       | TRADING_MODE_CONTINUOUS | 43200   | 900       | 1109      | 3611         | 50000000       | 10            |

    # the lp1 one volume on this side should go to 801 but because price monitoring bound is still 900 it gets pushed to 900.
    # but 900 is no longer the best bid, so the risk model is used to get prob of trading. This now given by the log-normal model
    # Hence a bit volume is required to meet commitment and thus the margin requirement moves but not much.

    Then the order book should have the following volumes for market "ETH2/MAR22":
      | side | price    | volume |
      | sell | 1109     | 90177  |
      | buy  | 901      | 1      |
      | buy  | 900      | 112674 |
      | buy  | 899      | 0      |

    And the parties should have the following margin levels:
      | party | market id  | maintenance | search   | initial  | release  |
      | lp1   | ETH2/MAR22 | 32570956    | 35828051 | 39085147 | 45599338 |

  Scenario:  Test Price Monitoring is pushing LP peged at lower bound  

  Given the log normal risk model named "log-normal-risk-model-1":
      | risk aversion | tau     | mu | r | sigma |
      | 0.000001      | 0.00273 | 0  | 0 | 1.2   |
    And the fees configuration named "fees-config-1":
      | maker fee | infrastructure fee |
      | 0.004     | 0.001              |
    And the price monitoring updated every "1" seconds named "price-monitoring-2":
      | horizon | probability | auction extension |
      | 43200   | 0.999999999999       | 300               |
    And the markets:
      | id         | quote name | asset | risk model              | margin calculator         | auction duration | fees          | price monitoring   | oracle config          | maturity date        |
      | ETH2/MAR22 | ETH2       | ETH2  | log-normal-risk-model-1 | default-margin-calculator | 1                | fees-config-1 | price-monitoring-2 | default-eth-for-future | 2022-03-31T23:59:59Z |
    And the parties deposit on asset's general account the following amount:
      | party  | asset | amount    |
      | lp1    | ETH2  | 100000000000000 |
      | party1 | ETH2  | 10000000  |
      | party2 | ETH2  | 10000000  |

    And the parties submit the following liquidity provision:
       | id          | party | market id  | commitment amount | fee   | side | pegged reference | proportion | offset | lp type   |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | buy  | BID              | 500        | 250     | submission|
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | sell | ASK              | 500        | 250     | amendment |

       And the parties place the following orders:
      | party  | market id  | side | volume | price | resulting trades | type       | tif     | reference  |
      | party1 | ETH2/MAR22 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-1  |
      | party1 | ETH2/MAR22 | buy  | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-2  |
      | party2 | ETH2/MAR22 | sell | 1      | 1109  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-1 |
      | party2 | ETH2/MAR22 | sell | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-2 |

    When the opening auction period ends for market "ETH2/MAR22"
    Then the auction ends with a traded volume of "10" at a price of "1000"

    And the parties should have the following profit and loss:
      | party  | volume | unrealised pnl | realised pnl |
      | party1 | 10     | 0              | 0            |
      | party2 | -10    | 0              | 0            |

    And the market data for the market "ETH2/MAR22" should be:
      | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest |
      | 1000       | TRADING_MODE_CONTINUOUS | 43200   | 728       | 1371      | 3611         | 50000000              | 10            |

    And the order book should have the following volumes for market "ETH2/MAR22":
      | side | price | volume |
      | sell | 1359  | 217206866  |
      | sell | 1109  | 1  |
      | sell | 909   | 0  |
      | buy  | 1000  | 0  |
      | buy  | 728   | 48675135  |
      | buy  | 900   | 1  |

Scenario:  Test LP Volume being pushed by limit of Probability of Trading (floored at 1e-8); 
#Price Monitoring has been removed as Prob in Price Monitoring only take up to 15 decimal places which will prevent scenatio which will trigger the ProbOfTrading cap at 1e-8

  Given the log normal risk model named "log-normal-risk-model-1":
      | risk aversion | tau     | mu | r | sigma |
      | 0.000001      | 0.00273 | 0  | 0 | 1.2   |
    And the fees configuration named "fees-config-1":
      | maker fee | infrastructure fee |
      | 0.004     | 0.001              |

    And the markets:
      | id         | quote name | asset | risk model              | margin calculator         | auction duration | fees          | price monitoring   | oracle config          | maturity date        |
      | ETH2/MAR22 | ETH2       | ETH2  | log-normal-risk-model-1 | default-margin-calculator | 1                | fees-config-1 | default-none       | default-eth-for-future | 2022-03-31T23:59:59Z |
    And the parties deposit on asset's general account the following amount:
      | party  | asset | amount    |
      | lp1    | ETH2  | 1000000000000000000 |
      | party1 | ETH2  | 10000000  |
      | party2 | ETH2  | 10000000  |

    And the parties submit the following liquidity provision:
       | id          | party | market id  | commitment amount | fee   | side | pegged reference | proportion | offset | lp type   |
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | buy  | BID              | 600        | 600     | submission|
       | commitment1 | lp1   | ETH2/MAR22 | 50000000          | 0.001 | sell | ASK              | 600        | 600     | amendment |

       And the parties place the following orders:
      | party  | market id  | side | volume | price | resulting trades | type       | tif     | reference  |
      | party1 | ETH2/MAR22 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-1  |
      | party1 | ETH2/MAR22 | buy  | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-2  |
      | party2 | ETH2/MAR22 | sell | 1      | 1109  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-1 |
      | party2 | ETH2/MAR22 | sell | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-2 |

    When the opening auction period ends for market "ETH2/MAR22"
    Then the auction ends with a traded volume of "10" at a price of "1000"

    And the parties should have the following profit and loss:
      | party  | volume | unrealised pnl | realised pnl |
      | party1 | 10     | 0              | 0            |
      | party2 | -10    | 0              | 0            |

  # ProbOfTrading is floored at 1e-8 when LP pegged ref offset from 500 onward, we use 600 in this test case

    And the order book should have the following volumes for market "ETH2/MAR22":
      | side | price | volume         |
      | sell | 1709  | 2925687536572  |
      | sell | 1109  | 1              |
      | buy  | 300   | 16666666666667 |
      | buy  | 900   | 1              |
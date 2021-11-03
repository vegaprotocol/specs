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
      | party3           | USD   | 50000000   |
      | aux1             | USD   | 1000000000 |
      | aux2             | USD   | 1000000000 |

    And the cumulated balance for all accounts should be worth "4100045000"

    Then "party1" should have general account balance of "30000" for asset "USD"  
# setup order book
    When the parties place the following orders:
      | party            | market id | side | volume | price | resulting trades | type       | tif     | reference       |
      | sellSideProvider | ETH/DEC19 | sell | 1000   | 150   | 0                | TYPE_LIMIT | TIF_GTC | sell-provider-1 |
      | aux1             | ETH/DEC19 | sell | 1      | 150   | 0                | TYPE_LIMIT | TIF_GTC | aux-s-1         |
      | aux1             | ETH/DEC19 | sell | 1      | 100   | 0                | TYPE_LIMIT | TIF_GTC | aux-s-2         |
      | aux2             | ETH/DEC19 | buy  | 1      | 100   | 0                | TYPE_LIMIT | TIF_GTC | aux-b-2         |
      | buySideProvider  | ETH/DEC19 | buy  | 1000   | 80    | 0                | TYPE_LIMIT | TIF_GTC | buy-provider-1  |
      | aux2             | ETH/DEC19 | buy  | 1      | 80    | 0                | TYPE_LIMIT | TIF_GTC | aux-b-1         |
      
      
    Then the opening auction period ends for market "ETH/DEC19"
    And the mark price should be "100" for the market "ETH/DEC19"

    And the trading mode should be "TRADING_MODE_CONTINUOUS" for the market "ETH/DEC19"

    # party 1 place an order + we check margins
    When the parties place the following orders:
      | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
      | party1 | ETH/DEC19 | sell | 100    | 100   | 0                | TYPE_LIMIT | TIF_GTC | ref-1     |
    
    # all general acc balance goes to margin account for the order
    Then "party1" should have general account balance of "0" for asset "USD"  
    
    # then party2 places an order, this trades with party1 and we calculate the margins again
    When the parties place the following orders:
      | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
      | party2 | ETH/DEC19 | buy  | 100    | 100   | 1                | TYPE_LIMIT | TIF_GTC | ref-1     |
    
    Then the trading mode should be "TRADING_MODE_CONTINUOUS" for the market "ETH/DEC19"
    And the mark price should be "100" for the market "ETH/DEC19"
    And the parties should have the following account balances:
      | party  | asset | market id | margin   | general  |
      | party1 | USD   | ETH/DEC19 | 30000    |  0       |
    
    Then the trading mode should be "TRADING_MODE_CONTINUOUS" for the market "ETH/DEC19"

    When the parties place the following orders:
      | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
      | party2 | ETH/DEC19 | buy  | 1      | 126   | 0                | TYPE_LIMIT | TIF_GTC | ref-1-xxx |
      | party3 | ETH/DEC19 | sell | 1      | 126   | 0                | TYPE_LIMIT | TIF_GTC | ref-1-xxx |
    Then the mark price should be "126" for the market "ETH/DEC19"    

    Then the parties should have the following account balances:
      | party            | asset | market id | margin    | general     |
      | party1           | USD   | ETH/DEC19 | 0         |  0          |
      | party2           | USD   | ETH/DEC19 | 38900     |  49963700   |
      | party3           | USD   | ETH/DEC19 | 600       |  49999400   |
      | aux1             | USD   | ETH/DEC19 | 1324      |  999998650  |
      | aux2             | USD   | ETH/DEC19 | 686       |  999999340  |
      | sellSideProvider | USD   | ETH/DEC19 | 758400    |  999244000  |
      | buySideProvider  | USD   | ETH/DEC19 | 540000    |  999460000  |
    
    And the cumulated balance for all accounts should be worth "4100045000" 
    And the insurance pool balance should be "25000" for the market "ETH/DEC19"   

  #   When the parties place the following orders:
  #     | party            | market id | side | volume | price | resulting trades | type       | tif     | reference       |
  #     | sellSideProvider | ETH/DEC19 | sell | 1000   | 200   | 0                | TYPE_LIMIT | TIF_GTC | sell-provider-2 |
  #     | buySideProvider  | ETH/DEC19 | buy  | 1000   | 80    | 0                | TYPE_LIMIT | TIF_GTC | buy-provider-2  |
  #   Then the parties cancel the following orders:
  #     | party  | reference |
  #     | aux1   | aux-s-1   |
  #     | aux2   | aux-b-1   |
  #   Then the trading mode should be "TRADING_MODE_CONTINUOUS" for the market "ETH/DEC19"
  #   And the insurance pool balance should be "15000" for the market "ETH/DEC19"
  #   When the parties place the following orders:
  #     | party  | market id | side | volume | price | resulting trades | type       | tif     | reference |
  #     | party2 | ETH/DEC19 | buy  | 100    | 160   | 0                | TYPE_LIMIT | TIF_GTC | ref-1     |
  #     | party3 | ETH/DEC19 | sell | 100    | 160   | 1                | TYPE_LIMIT | TIF_GTC | ref-2     |

  # #check margin/general account 
  #   Then the parties should have the following account balances:
  #     | party  | asset | market id | margin   | general |
  #     | party1 | USD   | ETH/DEC19 | 0        | 0       |
  #     | party2 | USD   | ETH/DEC19 | 56000    | 0       |

  #   Then the trading mode should be "TRADING_MODE_CONTINUOUS" for the market "ETH/DEC19"
  #   Then the parties should have the following profit and loss:
  #     | party  | volume | unrealised pnl | realised pnl |
  #     | party1 | 0      | 0              | -6000        |
  #     | party2 | 200    | 6000           | 0            |
  #     | party3 | -100   | 0              | 0            |
  #   And the insurance pool balance should be "10000" for the market "ETH/DEC19"
  #   And the cumulated balance for all accounts should be worth "400120000"

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
Feature: Test liquidity provider bond slashing 
  Background:

    Given the following network parameters are set:
      | name                                                | value |
      | market.value.windowLength                           | 1h    |
      | market.stake.target.timeWindow                      | 24h   |
      | market.stake.target.scalingFactor                   | 1     |
      | market.liquidity.targetstake.triggering.ratio       | 0     |
      | market.liquidity.providers.fee.distributionTimeStep | 10m   |
    
    And the average block duration is "1"
    And the simple risk model named "simple-risk-model-1":
      | long | short | max move up | min move down | probability of trading |
      | 0.1  | 0.1   | 100         | -100           | 0.1                    |
    And the log normal risk model named "log-normal-risk-model-1":
      | risk aversion | tau | mu | r   | sigma |
      | 0.000001      | 0.1 | 0  | 1.4 | -1    |
    And the fees configuration named "fees-config-1":
      | maker fee | infrastructure fee | liquidity fee |
      | 0.004     | 0.001              | 0.3           |
    And the price monitoring updated every "1" seconds named "price-monitoring-1":
      | horizon | probability | auction extension |
      | 1       | 0.99        | 300               |
    And the markets:
      | id        | quote name | asset | risk model          | margin calculator         | auction duration | fees          | price monitoring   | oracle config          | maturity date        |
      | ETH/DEC21 | ETH        | ETH   | simple-risk-model-1 | default-margin-calculator | 1                | fees-config-1 | price-monitoring-1 | default-eth-for-future | 2021-12-31T23:59:59Z |
    And the oracles broadcast data signed with "0xDEADBEEF":
      | name             | value |
      | prices.ETH.value | 100   |
    And the traders deposit on asset's general account the following amount:
      | trader  | asset | amount     |
      | lp1     | ETH   | 100000000   |
      | trader1 | ETH   |  10000000   |
      | trader2 | ETH   |  10000000   |
  Scenario: first slashing scenario 
    Given the traders submit the following liquidity provision:
      | id          | party   | market id | commitment amount | fee   | order side | order reference | order proportion | order offset |
      | commitment1 | lp1     | ETH/DEC21 | 78000000             | 0.001 | buy        | BID             | 500              | -100         |
      | commitment1 | lp1     | ETH/DEC21 | 78000000             | 0.001 | sell       | ASK             | 500              | 100          |
 
    And the traders place the following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | reference  |
      | trader1 | ETH/DEC21 | buy  | 1      | 900   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-1  |
      | trader1 | ETH/DEC21 | buy  | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-2  |
      | trader2 | ETH/DEC21 | sell | 1      | 1100  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-1 |
      | trader2 | ETH/DEC21 | sell | 10     | 1000  | 0                | TYPE_LIMIT | TIF_GTC | sell-ref-2 |
      
    When the opening auction period ends for market "ETH/DEC21"
    Then the auction ends with a traded volume of "10" at a price of "1000"

    And the traders should have the following profit and loss:
      | trader           | volume | unrealised pnl | realised pnl |
      | trader1          |  10    | 0              | 0            |
      | trader2          | -10    | 0              | 0            |

    And the traders should have the following account balances:
      | trader    | asset | market id | margin     | general   | bond    |
      | lp1       | ETH   | ETH/DEC21 | 20800080    | 1199920    | 78000000 |

    
    And the market data for the market "ETH/DEC21" should be:
      | mark price | trading mode            | horizon | min bound | max bound | target stake | supplied stake | open interest   |
      | 1000       | TRADING_MODE_CONTINUOUS | 1       | 900       | 1100      | 1000         | 78000000        | 10            |


    And the traders place the following orders:
      | trader  | market id | side | volume | price | resulting trades | type       | tif     | reference  |
      | trader1 | ETH/DEC21 | buy  | 1      | 1000   | 0                | TYPE_LIMIT | TIF_GTC | buy-ref-3  |
    
    And the mark price should be "1000" for the market "ETH/DEC21"
    
    # Now the following step fails claiming that there should be 10000000 in the margin account and 0 in the others. 
    # What am I missing?
    And the traders should have the following account balances:
       | trader    | asset | market id | margin     | general   | bond    |
       | lp1       | ETH   | ETH/DEC21 | 20800080    | 1199920    | 78000000 |


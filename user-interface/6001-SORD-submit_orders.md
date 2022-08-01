# Submit order
As a user I want change my exposure on a market (e.g. open a position, increase or decrease open volume), I want to submit an order with instructions for how my order should be executed so that I can control the price that I get and whether my order should remain on the order book (e.g. wait to be filled, or canceled if not filled immediately).

When populating a deal ticket I...

- Can see/select the market (**name**, code or ID) they are submitting the order on 
- Can see the current market **status** (Continuous, Auction etc) 

- If you do not have any of the settlement asset the deal ticket prompts to get some (but also allow you to pupulate ticekt becase I might wnat to try before I deposit)

- Select a **side/direction** (note: some implementations may do this with two submit buttons long/short)(

## Order size
When selecting a size for my order, I...

- can input an order size (aka amount or contracts) 
- am warned (pre-submit) if input has too many decimal places for the market's "position" decimal places 
- can, if the field is empty, hit up/down to populate the input with the current mark price (if there is one) 
- get (pre-populated) the previously used value (Last submitted or last changed) if there is one 
- Hitting up/down on the keyboard should increase the size by the markets' min-contract size 
- can select a size in a order book to populate the size 
- can select open volume in a positions table to populate the size 
- can use a leverage slider to determine a size based on how much leverage I wish to use (given general balance, order type or price input) 

... so that I get the size of exposure (open volume that I want)

## Limit order
- enter a price 
- See the price unit (as defined in market)
- select a time in force
    - GTC
    - GTT
    - FOC
    - GFN
    - GFA

## Market order
- TODO: no price input (can see and indication of fill price + slippage)

## Auto Populating a deal ticket non-manual menthods
- TODO Populate by clicking on a size/price in the order book
- TODO Populate by clicking on a size/price in the chart
- `NOTYET` Input price as a % of account, given the current price field

## Submit an order
* Submit the populated order
* see a prompt to approve transaction in Wallet (if manual approval required)
* The ticket will warn if a users selections are invalid
 - Market orders are not acceptable if market is in auction
 - limit orders can not have the following TIF: IOC FOC (GFN if the market trading mode is currently an auction)
* Gets feedback on their order's status (see 06001-Show order)
 - Shows the values that were submitted (order type and all fields)
 - Shows A hash/Id transaction ID so that a user can follow up
 - Shows the status on the order they have submitted (filled, partially filled, active ETC)
 - If the order is rejected: display the regected reason

 ## See the potential consequences of an order before it is submit
 - liquidation level
 - notional value
 - leverage
 - estimated fees
 - new position
 - change in margin requirements
 - PnL 
 - new VWAP


After submitting orders I'll want to [manage them](6002-MORD-manage_orders.md).

## Typical ordering scenarios
- Limit order GTC, with a price that is lower than the current price
- Limit order that crosses the book but only gets a partial fill
- Market order
- Attempted Market order in Auction mode
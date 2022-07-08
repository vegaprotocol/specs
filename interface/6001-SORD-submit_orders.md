# Submit order
As a user I want change my exposure on a market (e.g. open a position, increase or decrease open volume), I want to submit an order with instructions for how my order should be executed so that I can control the price that I get and whether my order should remain on the order book (e.g. wait to be filled, or canceled if not filled immediately).

When populating a deal ticket I...

- Can see/select the market (**name**, code or ID) they are submitting the order on(<a name="000-XXX-0000" href="#000-XXX-0000">000-XXX-0000</a>) 
- Can see the current market **status** (Continuous, Auction etc) (<a name="000-XXX-0000" href="#000-XXX-0000">000-XXX-0000</a>) 



- Select a **side/direction** (note: some implementations may do this with two submit buttons long/short)(<a name="000-XXX-0000" href="#000-XXX-0000">000-XXX-0000</a>) 

## Order size
- Enter an **order size** (aka amount or contracts)(<a name="000-XXX-0000" href="#000-XXX-0000">000-XXX-0000</a>) 
    - is warned if input has too many decimal places for the market's "position" decimal places(<a name="000-XXX-0000" href="#000-XXX-0000">000-XXX-0000</a>) 
    - `NOTYET` If the field is empty hitting/up down should populate the input with the current mark price (if there is one)
    - `NOTYET` The price input should be pre-poulated with a saved previous value (Last submitted or last changed) if there is one
    - `NOTYET` Hitting up/down on the keyboard should increase the size by the markets' min-contract size
    

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
* Gets feedback on their order's status (see 0000-Show order)
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
# Submit order
As a user I want change my exposure on a market (e.g. open a position, increase or decrease exposure), I want to submit an order with instructions for how my order should be executed so that I can control the price that I get and whether my order should remain on the order book (e.g. wait to be filled, or canceled if not filled immediately).

When populating a deal ticket I...

- Can see/select the market (name, code or ID) they are submitting the order on(<a name="000-XXX-0000" href="#000-XXX-0000">000-XXX-0000</a>) 
----
- Select a side/direction (note: some implementations may do this with two submit buttons long/short)(<a name="000-XXX-0000" href="#000-XXX-0000">000-XXX-0000</a>) 
    - Long
    - Short
----
- Enter an order size (aka amount or contracts)
    - is warned if input has too many decimal places for the market's "position" decimal places
    - `TODO` On load, if the user has traded before: should be populated with the same value as the last one the user attempted to submit (for this market)
    - `TODO` Hitting up/down on the keyboard should increase the size by the markets' min-contract size
    - `TODO` If the field is empty hitting/up down should populate the input with the current mark price (if there is one)
    - `TODO` input price as a % of X, given the current price field
----
## Limit order
- enter a price 
- See the price unit (as defined in market)
- select a time in force
    - GTC
    - GTT
    - FOC
    - GFN
    - GFA
----
## Market order
- TODO: no price input (can see and indication of fill price + slippage)
----
## Populating a deal ticket with other data
- TODO Populate by clicking on a size/price in the order book
- TODO Populate by clicking on a size/price in the chart

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


 keep track of my order in the book...
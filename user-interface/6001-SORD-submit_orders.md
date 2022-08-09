# Submit order
As a user I want change my exposure on a market (e.g. open a position, increase or decrease my open volume), I want to submit an order with instructions for how my order should be executed so that I can have some control over the price that I get and how my order should remain on the order book (e.g. wait to be filled, or canceled if not filled immediately). See various [specs to do with submitting orders](../protocol#orders).

When populating a deal ticket I...

- **must** see/select the [Market](./7001-DATA-data_display.md#market) I am are submitting the order for 
  - **must** see the current market status (Continuous, Auction etc)

- If I have 0 of the settlement asset in any account AND do not have orders/position on the market: **must** see a warning on the deal ticket telling me I have insufficient collateral (but also allow you to populate ticket because I might want to try before I deposit)

- **must** select a **side/direction** (note: some implementations may do this with two submit buttons long/short rather than a toggle)

- **must** be able to select the [order type](../protocol/0014-ORDT-order_types.md) that I wish to submit
  - **must** see limit order
  - **must** see market order
  - **should** see pegged order
  - **should** see liquidity provision

## Order size

...need to select a size, when selecting a size for my order, I...

- **must** input an order [size](7001-DATA-data_display.md#size) (aka amount or contracts)
  - if the input field is empty: with the input focused: **should** be able to hit up/down to populate the input with the current mark price (if there is one) 
  - **should** have the previous value pre-populated (last submitted or last changed) 
  - **should** be able to hit up/down on the keyboard to increase the size by the markets' min-contract size
  - **should** be able to select a open volume in a positions table to populate the size 
  - **could** be able to use use a leverage slider to determine a size based on how much leverage I wish to use (given general balance, order type or price input)
- **must** be warned (pre-submit) if input has too many decimal places for the market's "position" decimal places 

... so I get the size of exposure (open volume that I want)

## Price - Limit order

... if wanting to place a limit on the price that I trade at, I...

- **must** enter a [price](7001-DATA-data_display.md#quote-price) 
- **must** see the price unit (as defined in market)

... so that my order only trades at up/down to a particular price

## Market order

... if wanting to trade regardless of price (or in the assumption that the market is liquid enough that the current best prices are enough of an indication of the price I'll get)...

- **must not** see a price input
- **should** see an indication of the slippage I might experience
  - **should** see an indication of the average price I might get
  - **should** see an indication of the amount I'll move the market in percentage terms

... so I cen quickly submit an order without populating the ticket with elements I don't care about

## Pegged

... submit an order where the price is offset from a price in system (best bid etc)

- TODO

... so I have some control over the price my order trades at

## Time in force

... should to select a time in force, when selecting a time in force, I...

- **must** select a time in force
  - Good till canceled `GTC` - not applicable to Market orders
  - Good till time `GTT` - not applicable to Market orders
  - Fill or kill `FOC`
  - Immediate Or Cancel `IOC`
  - Good for normal trading only `GFN` - not applicable to Market orders
  - Good for auction only `GFA` - not applicable to Market orders
- **should** only be warned if the time in force is not applicable to the order type I have selected
- if the user has not set a preference: market orders **should** default to `IOC` 
- if the user has not set a preference: limit orders **should** default to `GTC` 

... so I can control if and how my order stays on the order book

## Auto Populating a deal ticket non-manual methods

- TODO Populate by selecting a size/price in the order book
- TODO Populate by selecting a size/price in the chart
- TODO Populate by selecting a size/price in the depth chart
- TODO Input price as a % of account, given the current price field

## See the potential consequences of an order before it is submit
... based on the current inputs i'd like indication of the consequences of what might happen based on my position and the state of the market, I...

- **could** see my new open volume
- **could** see new volume weighted average entry price
- **could** see a new liquidation level
- **could** see an estimate of the fees that will be paid (if any)
- **could** see my "position leverage" TODO - define this
- **could** see my "account leverage" TODO - define this
- **could** see an amount of realized Profit / Loss
- **could** see any change in margin requirements (if more or less margin will be required)

- **could** see the notional value of my order

... so that I can adjust my inputs before submitting

## Submit an order

... need to submit my order, when submitting my order, I... 

- **must** submit the [Vega create order transaction](0003-WTXN-submit_vega_transaction.md)

- **must** see feedback on their order's [status](https://docs.vega.xyz/docs/mainnet/grpc/vega/vega.proto#orderstatus) (not just transaction status above)
  - Active (aka Open)
  - Expired
  - Cancelled
  - Stopped. **should** see an explanation of why stopped
  - Partially filled. **should** see how much of the [size](7001-DATA-data_display.md#size) if filled/remaining (Subscription)
  - Filled
  - Rejected: **must** see the reason it was rejected
  - Parked: **should** see an explanation of why parked orders happen
 - **could** repeat the values that were submitted (order type + all fields)

... so that I am aware of the status of my order before seeing it in the [orders table](6002-MORD-manage_orders.md).

... so I get the sort of order, and consistently price, I wish.

## Manage positions and order
After submitting orders I'll want to [manage orders](6002-MORD-manage_orders.md). If my my orders resulted in a position I may wish to [manage positions](6003-POSI-positions.md).

_____

# Typical order scenarios to design/test for

Market in continuous trading:
- Limit order, GTC, with a price that is lower than the current price
- Limit order, GFN, that crosses the book but only gets a partial fill when order is processed
- Market order, IOC, that increases open volume (aka size of position)
- a limit order GFA when market is in Auction
- an limit that reduces exposure from something to 0
- a limit order, FOK, that squares and reverses e.g. I'm long 10, I short 20 to end short 10

Market in auction:
- Attempt Market order in Auction mode: should warn order is invalid
- Attempt limit order GFN when market is normally Continuos, should warn
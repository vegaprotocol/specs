# Manage orders

Users place orders to describe the trades they would like to make: buy or sell, at what price, how long it is valid for etc. In many cases they can [ammend](#amend-order---price) or [cancel](#cancel-orders) these orders while they are still active, for example: changing price.

Once a user has placed an order they may wish to confirm it's [status](https://docs.vega.xyz/docs/mainnet/graphql/enums/order-status) in a [list](#orders-list) of other orders. e.g. whether it has been accepted, filled, how close it is to being filled etc. Users may be interested in the price of their orders relative to the price of the market and how much of the order's size has been filled.

Orders can also be placed on behalf of a user/party via [liquidity](#liquidity-order-shapes) or [pegged](#pegged-order-shapes) order shapes. These order cannot be amended on canceled in the same way as other orders.

Markets also have [statuses](https://docs.vega.xyz/docs/mainnet/graphql/enums/market-state) that may affect how a user perceives the state of an order, e.g if the order was placed while in "normal" continuous trading, but the market is now in auction. 

## Orders list

User will have differing needs/preferences in terms of what they want to see about an order and how orders are grouped and listed. It is common for interfaces to allow users to customize how orders are displayed.

### Field customization

- **should** have the ability to select what [fields/data](#fields) are shown for each order in the list
- **should** have the ability to change the order of fields (e.g. table columns)
- **should** have the ability to give each column in the list more or less space

### Fields

- **must** see [status](https://docs.vega.xyz/docs/mainnet/graphql/enums/order-status) of the order
  - `Active​`
    - How much of the order is filled / remains unfilled
    - How close the mark price is to my order
    - If this order is filled at the limit price what would my what effect would it have on realized PnL 
    - I may want to amend or cancel this order
  - `Expired​`
    - When did it expire
    - How much was filled / remaining
  - `Cancelled​`
    - What canceled it? When did I cancel it TODO double check that "cancelled" only comes from user action 
  - `Stopped​`
    - What stopped it (e.g. was it because an [FOC](9001-DATA-data_display.md#time-in-force) that was not filled, or because of margin availability)
  - `Filled​`
    - What was the average fill price I got for this order
  - `Rejected​`
    - Why was this order rejected (show `rejectedReason`)
  - `PartiallyFilled​`
    - How much was filled before the order was canceled
    - What was the average fill price I got for this order
  - `Parked​`
    - Why is the market currently in auction
    - Link to pegged shape (see bellow) TODO find out what happens to the limit orders in the orders API when market is in auction

- **must** see what [market](9001-DATA-data_display.md#market) an order is related to (either code, ID or name, preferable name)
  - **should** see what the status is of the market (particularly if it is not "normal")
- **must** see the [size](9001-DATA-data_display.md#size) of the order
- **must** see the [direction/side](9001-DATA-data_display.md#direction--side) (Long or Short) of the order (this can be implied with a + or negative suffix on the size, + for Long, - for short)
- **must** see [order type](9001-DATA-data_display.md#order-type)
- if order created by [pegged or liquidity provision shape](9001-DATA-data_display.md#order-origin): **should** see order origin
  - **could** see what part of the liquidity shape or pegged order shape this relates to. See [pegged orders](#pegged-order-shapes) and [liquidity provisions](#liquidity-order-shapes) shapes below.
  - **could** see link to my full shape

- **should** see how much of the order's [size](9001-DATA-data_display.md#size) has been filled e.g. if the order was for `50` but so far only 10 have traded I should see Filled = `10`. Note: this is marked as a should because in the case of Rejected order and some other scenarios it isn't relevant.
- **should** see how much of the order's [size](9001-DATA-data_display.md#size) remains. Note: this does not go to zero if the order status goes to a closed state. TODO double check what the API does in a situation where I got 50% fill then canceled an order 

- if order type = `Limit`: **must** see the Limit [price](9001-DATA-data_display.md#quote-price) that was set on the order
- if order type = `Market`: **must** not see a price for active or parked orders, a `-`, `Market` or `n/a` is more appropriate (API may return 0).

- **must** see the [time in force](9001-DATA-data_display.md#time-in-force) applied to the order (can be abbreviated here)
- **should** see created At time stamp. TODO check what happens to this in the context of Pegged and LP orders.
- **could** see updated at (this is used by the system when an order is amended, or repriced (in pegged and LP) not sure this in needed) TODO check behavior 

- **should** see time/order priority (how many orders are before mine at this price)
  
- if the order is `Active` &amp; **not** part of a liquidity or peg shape: **must** see an option to [amend](#amend-order---price) the individual order
- if the order is `Active` &amp; is part of a liquidity or peg shape: **must** **not** see an option to amend the individual order
  - **could** see a link to amend shape
- if the order is `Active` &amp; **not** part of a liquidity or peg shape: **must** see an option to [cancel](#cancel-orders) the individual order
- if the order is `Active` &amp; is part of a liquidity or peg shape: **must** **not** see an option to cancel the individual order
  - **could** see a link to cancel shape

### Filters

- **should** have the ability to see all orders regardless of status in one list
- **should** have the ability to see only active &amp; parked orders TODO update this based on what happens to parked orders
- **should** have the ability to see only non-active &amp; parked order (i.e. all orders that do not have the status of Active &amp; Parked)
- **could** have the ability to filter by any field(s)
  - where a field is an enum: **should** be able to select one on or more values for a field that should be included

### Sorting

- **should** be able to sort the list (both directions) by any field in the order list
  - **should** be able to add a secondary sort. e.g. by market then by date  
- **should** have the default sorted by created time (or updated time if newer), with newest at the top
- **should** retain sorting preferences between switching views / browser reload

### Grouping

- **should** be able to group orders by any field e.g. by market, lp etc
- **should** have default grouping by market

## Cancel orders

- **must** select weather to cancel an individual order or all orders on a market
- **must** be able to submit the [Vega transaction](0003-WTXN-submit_vega_transaction.md) to cancel order(s)
  - **could** show the margin requirement reduction/increase that will take place before submitting
- **must** see feedback on my order status after the transaction

## Amend order - price

Read more about [order amends](../protocol/0004-AMND-amends.md).

When looking to amend an order, I...

- **must** be able to amend the price of an order
  - **could** be warned if the price change will, given the current market, fill the order right away
  - **must** be warned (pre-submit) if the input price has too many digits after the decimal place for the market ["quote"](DATA-data_display.md#quote-price)
- must submit the Amend order [Vega transaction](0003-WTXN-submit_vega_transaction.md)
- must see the status after the transaction (see [submit order](7002-SORD-submit_orders.md#submit-an-order))

... so the order is more likely to get filled or will be filled at a more competitive price

## Amend order - other types

`TBD` -  Acceptance criteria for other types of order amend 
## On a price history chart

when looking at a price history chart, I...

- **would** like to see all my active orders shown on the vertical axis
- **would** like to drag orders to change their price

... so I can see my orders in context of price history
## On a depth chart

when looking at a depth chart, I...

- **would** like to see all my active orders shown on the horizontal axis
- **would** like to drag orders to change their price

... so I can see my orders in context of price history

## In order book

when looking at an order book, I...

- **would** like to see all my active orders shown next to the prices they have

... so I can see my orders in context of price history

## Pegged order shapes

When looking to understand the state of a pegged order shape...

- **would** like to see the pegged order status (e.g. active, parked, canceled etc)
- **would** like to see the shape I submitted
  - **would** like to see each buy/sell order with it's reference and offset
  - **would** like to see the current price for each buy/sell
- **would** like to see what parts of this shape have been filled and what remains

... so I can decide if I wish to amend or cancel my order
## Liquidity order shapes

When looking to understand the state of a liquidity provision... 

- **would** like to see the liquidity commitment order status (e.g. pending, active, parked, canceled etc)
- **would** like to see the shape I submitted
  - **would** like to see each buy/sell order with it's reference and offset
  - **would** like to see the current price for each buy/sell
- **would** like to see the fee bid
- **would** like to see the date submitted/updated

... so I can decide if I wish to amend or cancel my shape
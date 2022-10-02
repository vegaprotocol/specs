# Manage orders
User place orders as a way of expressing the trades they would like to make. 
Once a user has placed an order they may wish to confirm its state e.g. whether it has been filled or not.
They may also wish to make amendments to that order.

Orders have different [Order statuses](https://docs.vega.xyz/docs/mainnet/graphql/enums/order-status). These statuses have consequences on the way you can manage an order.

Markets also have statuses [market statuses](https://docs.vega.xyz/docs/mainnet/graphql/enums/market-state)
These also have consequences on what you can do with an order
- parked pegged orders
- editing orders during auction?
  Generally when looking at an order a user will want to know what status the market it is in particularly if the market is not in it's "normal" trading mode.

Orders are typically the result of placing a limit, stop, market order etc, But some order will be there as the result of placing a pegged order or liquidity order shape which is an instruction to the network to place limit orders on your behalf and move them when market prices change.

## Open (aka active) orders
When reviewing the orders I have placed and their status, I...

Customization
- **should** have the ability to view all data that is available on a given order or view of orders

Filters
- **should** have the ability to see all orders (active and non-active))
- should have the ability to see only active + Parked orders TODO update this based on what happens to parked orders
- should hte ability to see only non-active + Parked orders (i.e. all orders that do not have the status of )
- should have the ability to see only 

Sorting TODO

Grouping TODO



- **must** see [Status](TODO-Do-we-need-this?) of the order

- Depending on the order, I...
  - Active​ - Remaining, how close the market is my order, (I may want to edit or cancel this order)
  - Expired​ - when did it expire, how much was filled remaining
  - Cancelled​ - What canceled it. This generally means that it was canceled by the user but there may be exceptions (TODO Documentation needed)  
  - Stopped​ - What stopped it (e.g. was it because an [FOC](9001-DATA-data_display.md#time-in-force) that was not filled)
  - Filled​ - What was the fill price I got for this order
  - Rejected​ - Why was this order rejected
  - PartiallyFilled​ - how much was filled before the order was canceled)
  - Parked​ - Why is the market currently in auction TODO find out what happens to the limit orders in the orders API when market is in auction

For each order:
- **must** see what [market](9001-DATA-data_display.md#market) an order is related to (either code, ID or name, preferable name)
  - **should** see what the status is of the market (particularly if it is not "normal")
- **must** see the [Size](9001-DATA-data_display.md#size) of the order
- **must** see the [direction](9001-DATA-data_display.md#direction--side) (Long or Short) of the order (this can be implied with a + or negative suffix on the size, + for Long, - for short)
- **must** see [Order type](9001-DATA-data_display.md#order-type)
- **should** see order origin (pegged and liquidity orders)
  - if origin is [pegged or liquidity provision shape](9001-DATA-data_display.md#order-origin): order **could** see what part of the liquidity shape or pegged order shape this relates to. See [pegged orders](#pegged-order-shapes) and [liquidity provisions](#liquidity-order-shapes) shapes below.

- **should** see how much has been Filled [size](9001-DATA-data_display.md#size) e.g. if the order was for `50` but so far only 10 have traded I should see Filled = `10`. Note: this is marked as a should because in the case of Rejected order and some other scenarios it isn't relevant.
- **should** see how much of the orders [size](9001-DATA-data_display.md#size) remains. Note: this does not go to zero if the order status goes to a closed state. TODO double check what the API does in a situation where I got 50% fill then canceled an order 

- if order type = `Limit`: **must** see the Limit [price](9001-DATA-data_display.md#quote-price) that was set on the order
- if order type = `Market`: **must** not see a price for active or parked orders, a `-`, `Market` or `n/a` is more appropriate (API may return 0). 

- **must** see the [time in force](9001-DATA-data_display.md#time-in-force) applied to the order (can be abbreviated here)
- **should** see Created At time stamp. TODO check what happens to this in the context of Pegged and LP orders.
- **could** see Updated at (this is used by the system when an order is edited, or repriced (in pegged and LP) not sure this in needed) TODO check behavior 
  
- if the order is `Active` or `Parked`: **must** see an option to [Edit/amend](#amend-orders) the individual order
  - if order origin is pegged or Liquidity: 
    - **must** not see edit a [pegged or liquidity shape](9001-DATA-data_display.md#order-origin)
    - **should** see ability to edit [liquidity](#liquidity-order-shapes) or [peg](#pegged-order-shapes) shape below
- if the order is `Active` or `Parked`: **must** see an option to [Cancel](#cancel-orders) the individual order

... so I can decide what I want to do (if anything) and find the actions to do it.
## Cancel orders

- **must** see ability to cancel the order
- submit the cancel transaction
- see feedback on the transaction
## Amend orders

- **must** be able to edit the price of an order
- if the market status make the editing not possible TBD (e.g. edit order while in auction) TODO check what needs to be done
- if the type of change is not possible
- Other amends to an order TBD

- must submit or cancel the order
- must see the status of the order once confirmed on block

## On a chart

TBD
## Pegged order shapes

TBD
## Liquidity order shapes

TBD
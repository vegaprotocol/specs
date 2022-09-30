# Manage orders
User place orders as a way of expressing the trades they would like to make. 
Once a user has placed an order they may wish to confim its state e.g. whether it has been filled or not.
They may also wish to make amendments to that order.

Orders have different [Order statuses](https://docs.vega.xyz/docs/mainnet/graphql/enums/order-status). These statuses have consequences on the way you can manage an order.
- can't not edit/cancel a liquidity provision order
- can not edit/cancel a pegged order

Markets also have statuses [market statuses](https://docs.vega.xyz/docs/mainnet/graphql/enums/market-state)
These also have consequences on what you can do with an order
- parked pegged orders
- editing orders during auction?
  Generally when looking at an order a user will want to know what status the market it is in particularly if the market is not in it's "normal" trading mode.

Orders are typically the result of placing a limit, stop, market order etc, But some order will be there as the result of placing a pegged order or liquidity order shape which is an instruction to the network to place limit orders on your behalf and move them when market prices change.

Active​
Expired​
Cancelled​
Stopped​
Filled​
Rejected​
PartiallyFilled​
Parked​



## Open (aka active) orders
When reviewing the orders I have placed and their status, I...

- choose what to see from the APi in a table but default...
- Market
- amount
- type
- Status
- Filled
- remaining
- price
- time in force
- Created At
- Updated at (not sure this in needed)
- CTA Edit
  - if LP order
- CTA cancel

... so I can decide if i wish to cancel, edit, or create new orders

## non-open orders
When reviewing order that are no-longer open to being filled, canceled etc

## Cancel orders

## Amend orders

## On a chart

## Liquidity order shapes

## Pegged order shapes
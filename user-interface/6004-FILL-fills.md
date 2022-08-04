# My fills (aka my trades)

When looking to see exactly how my order was filled, I...

- **should** be able to filter the fills list/table
  - **should** filter by market
  - **should** filter by maker / taker / auction
  - **should** filter by the order created by 

for each "fill"", for that fill I see...
- **must** see the market name 
- **must** the amount traded [size or amount of contracts](./7001-DATA-data_display.md#Size) of the fill. 
- **must** see the [price](7001-DATA-data_display.md#quote-price) of the fill
- **could** show the [realized profit and loss(PNL)](./7001-DATA-data_display.md#asset-balances) for a fill that reduced exposure. This is the amount that will have been returned to the general account after the trade (after fees loss socialization etc).
- **must** see total [fees paid/received](7001-DATA-data_display.md#asset-balances) (if any on the fill)
  - **should** see a breakdown of this fee by infrastructure, liquidity and maker fee
- **should** see if I was a maker or taker or if the fill happened in auction uncrossing
- **must** see the date and time the fill took place

... so I can see what exactly how and when an order was filled.
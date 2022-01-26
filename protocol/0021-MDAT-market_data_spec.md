Feature name: market-data

# Acceptance Criteria
- [ ] If there are no buy orders on the order book, the best bid price is empty / nothing. (<a name="0021-MDAT-001" href="#0021-MDAT-001">0021-MDAT-001</a>)
- [ ] If there are no sell orders on the order book, the best offer price is empty / nothing. (<a name="0021-MDAT-002" href="#0021-MDAT-002">0021-MDAT-002</a>)
- [ ] If there are multiple buy orders on the order book with a price equal to the best bid price, the best bid volume equals the sum of the sizes of these orders. (<a name="0021-MDAT-003" href="#0021-MDAT-003">0021-MDAT-003</a>)
- [ ] If there are multiple sell orders on the order book with a price equal to the best bid price, the best offer volume equals the sum of the sizes of these orders. (<a name="0021-MDAT-004" href="#0021-MDAT-004">0021-MDAT-004</a>)
- [ ] The mid price is empty / nothing if there is either no buy order or no sell orders. (<a name="0021-MDAT-005" href="#0021-MDAT-005">0021-MDAT-005</a>)
- [ ] The mid price is the arithmetic average of the best bid price and best offer price. (<a name="0021-MDAT-006" href="#0021-MDAT-006">0021-MDAT-006</a>)
- [ ] The mark price calculation uses the methodology specified in the market framework. (<a name="0021-MDAT-007" href="#0021-MDAT-007">0021-MDAT-007</a>)
- [ ] The Open interest returns the sum of the size for all open positions where positions size is greater than 0. (<a name="0021-MDAT-008" href="#0021-MDAT-008">0021-MDAT-008</a>) 
- [ ] The Open interest returns 0 if there are no positions on the market (<a name="0021-MDAT-009" href="#0021-MDAT-009">0021-MDAT-009</a>)
- [ ] Pegged orders are excluded from the best price and volume calculations. (<a name="0021-MDAT-010" href="#0021-MDAT-010">0021-MDAT-010</a>)
- [ ] Dynamic orders should be ignored when calculating the static values (<a name="0021-MDAT-011" href="#0021-MDAT-011">0021-MDAT-011</a>)

# Summary
This data is a snapshot of the state of the market at a point in time.

# Guide-level explanation
Due to supporting dynamic orders such as pegged orders the main market data fields are split up into two parts. Normal values and static values. Normal values for **Mid price**, **Best bid price** and **Best offer price** take into account all orders on the book (both normal and dynamic). Static values are calculated using only non-dynamic orders and so will not count any pegged orders in the calculation.

# Reference-level explanation

## Market data

List of market data fields to be available via the API. All these values can be empty/nothing if there is insufficient relevant data.

  - **Market** market ID.
  - **Timestamp** current time used by the market in nanoseconds since the epoch.
  - **Market trading mode** the current trading mode of the market.
  - **Best bid price:** the highest bid price level on the order book.
  - **Best bid volume:** the aggregated volume being bid at the _best bid price_.
  - **Best offer price:** the lowest offer price level on the order book.
  - **Best offer volume:** the aggregated volume being offered at the _best offer price_.
  - **Mid price:** the arithmetic average of the _best bid price_ and _best offer price_.
  - **Mark price:** the current mark price as calculated by the selected mark price methodology.
  - **Open interest:** the sum of the size of all positions greater than 0. This needs take into account Position Decimal Places, unless raw ints are being used as for prices, in which case, clients will need to take into account the position d.p.s.
  - **Best static bid price:** the highest bid price level on an order book for persistent, non pegged buy orders.
  - **Best static bid volume:** the aggregate volume at the _best static bid price_ excluding pegged orders
  - **Best static offer price:** the lowest offer price level on an order book for persistent, non pegged sell orders.
  - **Best static offer volume:** the aggregate volume at the _best static offer price_ excluding pegged orders.
  - **Static mid price:** the arithmetic average of the _best static bid price_ and _best static offer price_.
  - **Indicative price** indicative auction uncrossing price.
  - **Indicative volume** indicative auction uncrossing volume.
  - **Auction start** start time of the current auction.
  - **Auction end** end time of the current auction (if auction exit trigger is time-based).
  - **Auction trigger** trigger of the current auction.
  - **Auction extension trigger** trigger of the extension of the current auction.
  - **Target stake** market's target stake based on current open interest when market is in default trading mode and a theoretical value based on auction's indicative volume when market is in auction mode.
  - **Supplied stake** market's supplied stake.
  - **Price monitoring bounds** one or more price monitoring bounds for the current timestamp.
  - **Market value proxy** market value proxy for liquidity provision reward calculation purposes.
  - **Liquidity provider fee share** share of the accrued fees each liquidity provider is eligible to.

# Pseudo-code / Examples

See Test cases

# Test cases

https://docs.google.com/spreadsheets/d/19_WPOQrTs6AsFfCaRjh8nXJF6B0IDHuP/edit#gid=128551767



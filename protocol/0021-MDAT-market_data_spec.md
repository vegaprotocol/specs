# Market data

## Acceptance Criteria

- If there are no buy orders on the order book, the best bid price is empty / nothing. (<a name="0021-MDAT-001" href="#0021-MDAT-001">0021-MDAT-001</a>). For product spot: (<a name="0021-MDAT-013" href="#0021-MDAT-013">0021-MDAT-013</a>)
- If there are no sell orders on the order book, the best offer price is empty / nothing. (<a name="0021-MDAT-002" href="#0021-MDAT-002">0021-MDAT-002</a>). For product spot: (<a name="0021-MDAT-014" href="#0021-MDAT-014">0021-MDAT-014</a>)
- If there are multiple buy orders on the order book with a price equal to the best bid price, the best bid volume equals the sum of the sizes of these orders. (<a name="0021-MDAT-003" href="#0021-MDAT-003">0021-MDAT-003</a>). For product spot: (<a name="0021-MDAT-015" href="#0021-MDAT-015">0021-MDAT-015</a>)
- If there are multiple sell orders on the order book with a price equal to the best bid price, the best offer volume equals the sum of the sizes of these orders. (<a name="0021-MDAT-004" href="#0021-MDAT-004">0021-MDAT-004</a>). For product spot: (<a name="0021-MDAT-016" href="#0021-MDAT-016">0021-MDAT-016</a>)
- The mid price is empty / nothing if there is either no buy order or no sell orders. (<a name="0021-MDAT-005" href="#0021-MDAT-005">0021-MDAT-005</a>). For product spot: (<a name="0021-MDAT-017" href="#0021-MDAT-017">0021-MDAT-017</a>)
- The mid price is the arithmetic average of the best bid price and best offer price. (<a name="0021-MDAT-006" href="#0021-MDAT-006">0021-MDAT-006</a>). For product spot: (<a name="0021-MDAT-018" href="#0021-MDAT-018">0021-MDAT-018</a>)
- The mark price, if it has been set in the market, is available on APIs returning market data. The returned object makes clear if the mark price has not yet been set (for example market in opening auction that's not seen any trades yet). (<a name="0021-MDAT-007" href="#0021-MDAT-007">0021-MDAT-007</a>). For product spot: (<a name="0021-MDAT-019" href="#0021-MDAT-019">0021-MDAT-019</a>)
- The Open interest returns the sum of the size for all open positions where positions size is greater than 0. (<a name="0021-MDAT-008" href="#0021-MDAT-008">0021-MDAT-008</a>)
- The Open interest returns 0 if there are no positions on the market (<a name="0021-MDAT-009" href="#0021-MDAT-009">0021-MDAT-009</a>)
- Pegged orders are excluded from the best static price and best static volume calculations. (<a name="0021-MDAT-010" href="#0021-MDAT-010">0021-MDAT-010</a>)
- Dynamic orders should be ignored when calculating the static values (<a name="0021-MDAT-011" href="#0021-MDAT-011">0021-MDAT-011</a>)
- The auction uncrossing price, if it has been set in the market, is available on APIs returning market data. The returned object makes clear if the auction uncrossing price has not been set (for example in continuous trading or auction with no bids / offers). (<a name="0021-MDAT-012" href="#0021-MDAT-012">0021-MDAT-012</a>). For product spot: (<a name="0021-MDAT-020" href="#0021-MDAT-020">0021-MDAT-020</a>)

## Summary

This data is a snapshot of the state of the market at a point in time.

## Guide-level explanation

Due to supporting dynamic orders such as [pegged orders](0037-OPEG-pegged_orders.md), the main market data fields are split up into two parts. Normal values and static values. Normal values for **Mid price**, **Best bid price** and **Best offer price** take into account all orders on the book (both normal and dynamic). Static values are calculated using only non-dynamic orders and so will not count any pegged orders in the calculation.

## Reference-level explanation

### Definition of dynamic orders

A "dynamic" order is a [pegged order](0037-OPEG-pegged_orders.md).

### Market data fields

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
- **Open interest:** the sum of the size of all positions greater than 0. This needs take into account Position Decimal Places, unless raw integers are being used as for prices, in which case, clients will need to take into account the position d.p.s.
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
- **Liquidity provider fee share** share of the accrued fees each liquidity provider is eligible to.

### Market data events

Market data events should be emitted with sufficient frequency so that each mark price change happening in the market can be captured by just observing the market data events.

## Pseudo-code / Examples

See Test cases

## Test cases

[Test cases](https://docs.google.com/spreadsheets/d/19_WPOQrTs6AsFfCaRjh8nXJF6B0IDHuP/edit#gid=128551767)

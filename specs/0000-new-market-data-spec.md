Feature name: market-data
Start date: 2019-10-11
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests/22

# Acceptance Criteria
- [ ] If there are no buy orders on the order book, the best bid price is empty / nothing.
- [ ] If there are no sell orders on the order book, the best offer price is empty / nothing.
- [ ] If there are multiple buy orders on the order book with a price equal to the best bid price, the best bid volume equals the sum of the sizes of these orders.
- [ ] If there are multiple sell orders on the order book with a price equal to the best bid price, the best offer volume equals the sum of the sizes of these orders.
- [ ] The mid price is empty / nothing if there is either no buy order or no sell orders.
- [ ] The mid price is the arithmetic average of the best bid price and best offer price.
- [ ] The mark price calculation uses the methodology specified in the market framework.


# Summary
This data is a snapshot of the state of the market at a point in time.

# Guide-level explanation

# Reference-level explanation

## Market data

### Continuous trading (order book)

All these values can be empty/nothing if there is insufficient relevant data.

  - **Best bid price:** the highest price level on an order book for buy orders.
  - **Best bid volume:** the aggregated volume being bid at the _best bid price_.
  - **Best offer price:** the lowest price level on an order book for offer orders.
  - **Best offer volume:** the aggregated volume being offered at the _best offer price_.
  - **Mid price:** the arithmetic average of the _best bid price_ and _best offer price_.
  - **Mark price:** the current mark price as calculated by the selected mark price methodology.

# Pseudo-code / Examples

See Test cases

# Test cases

https://docs.google.com/spreadsheets/d/19_WPOQrTs6AsFfCaRjh8nXJF6B0IDHuP/edit#gid=128551767



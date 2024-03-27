# Market decimal places

This document aims to outline how we are to handle the decimal places of a given market, if said market is configured with fewer decimal places than its settlement asset. For example: a market settling in ETH can be configured to use only 9 decimal places (Gwei) compared to ETH's 18. A market cannot specify _more_ decimal places than its settlement asset supports.

## Terminology

- Settlement asset: the asset in which transactions for a given market are made (margin balances, fees, settlements, etc...).
- Market decimal palces: the number of decimal places a market uses (as mentioned previously, a market where the smallest unit of ETH is a Gwei has a 9 decimal places, so the market decimal is 9). Synonymous with _market tick_.
- Asset decimal places: the number of decimal places for a given asset. Again, a market with decimal 9 that settles in ETH will have a market decimal of 9, whereas the asset decimal is 18.

## Mechanics

It is possible to configure a market where orders can only be priced in increments of a specific size. This is done by specifying a different (smaller) number of decimal places than its settlement asset supports. Simply put: a market that settles in GBP can be configured to have 0 decimal places, in which case the price levels on the orderbook will be at least separated by £1, rather than the default penny.

In cash settled futures market and perpetual market, in order to ensure that the smallest mark-to-market cashflow caused by the smallest price change on the smallest position is addressed, we need:

```go
market decimal places + position decimal places <= asset decimal places
position decimal palces <= asset decimal places
```

In spot market, in order to ensure we are able to represent the smallest trade at the smallest price in quote asset decimals, we need

```go
market decimal places + position decimal places <= quote asset decimal places
position decimal palces <= base asset decimal places
```

This effectively means that prices of submitted orders should be treated as a value that is an order of magnitude greater than what the user will submit. This is trivial to calculate, and is done when the market is created by passing in the asset details (which specify how many decimal places any given asset supports):

```go
priceExponent = 10**(asset_decimal - market_decimal)
// for GBP markets with 0 decimal places this is:
priceExponent = 10 ** (2 - 0) == 100
// for ETH markets with 9 decimal places, this is:
priceExponent = 10 ** (18 -9) == 1,000,000,000
```

When an order is submitted, amended, or otherwise updated, the core emits an event for the data-node (and any other interested parties). The price in this order event should still be represented as a value in market decimal places. Updating the price on the order internally, for reasons we shall elaborate on later, should not effect the market data on the event bus. To clarify:

```go
// given market decimal places == 0, settlement decimal == 2
SubmitOrder(Order{
    Size: 10,
    Price: 1,
})
// internally:

order.Price *= market.priceExponent // ie multiply by 100
broker.Send(events.NewOrderEvent(ctx, order)) // should still emit the event where the order is priced at 1
```

In short, market related events should specify prices in the _"unit"_ the market uses.

### Benefits

By allowing markets to specify their own decimal places, the price levels can be more closely controlled, and any changes in the mark price could be made as _"significant"_ as we want. By converting the prices internally to asset decimal places, we are able to accurately calculate fees and margin levels based on the asset decimal. By operating a market with a lower decimal than the asset itself, fees and margin requirements can be calculated with a higher level of decimal.

## Changes required

This change has an impact throughout the system, but it can broadly be broken down in the following parts

### Orders

Order submissions and amendments are received, the submitted price (aka market or original price) is copied to a private field, so the events can be constructed in an accurate way. Before submitting the order to the book, or amending it, the price we received from the chain is multiplied by the price exponent. From that point on, the core will operate on the value that has the asset decimal. Calculating fees and margin requirements, updating/creating the price levels, etc... all happens in asset decimal places. Any order events the core sends out will look exactly the same as before.

### Pegged orders

When (re-)pricing pegged orders, the offset values are multiplied by the same price factor before we add/subtract them from the reference price. The offsets themselves (as in: the field on the order object) is not updated. Events that contain this data, therefore, will still look exactly the same as they do now.

### Liquidity provisions

Orders created for an LP work pretty much exactly the same as pegged orders. The offsets will, again, be multiplied by the price exponent when the price is calculated, but the LP shape object is not updated.
When repricing LP orders, we ensure the price of the orders fall inside the upper and lower price bounds. These values are going to be calculated based on the prices used internally (in asset decimal). So as to not create orders at a price point that is more precise than the market is configured to support, we floor the max price bound, and ceil the minimum price, as those values will effectively be the max and min prices that are allowed without trades resulting in an auction being triggered.

### Market data

The market data returns the same min/max prices mentioned above. As the name implies, _`MarketData`_ is clearly market related data... The min/max price values we return from this call should therefore be floored (max) and ceiled (min) in the same way.

### Trades

Trades of course result in transfers. The amounts transferred (for the trade as well as the MTM) happen at asset decimal. The trade events the core sends out, however, are once again market related data. The prices on these trade events will be represented as a value in market decimal.

## Acceptance criteria

- As a user, I can propose a market with a different decimal places than its settlement asset
  - This proposal is valid if the market decimal is NOT greater than the settlement asset decimal - position decimal (<a name="0070-MKTD-021" href="#0070-MKTD-021">0070-MKTD-021</a>). For product spot, the market decimal should be NOT greater than the quote asset decimal - position decimal (<a name="0070-MKTD-022" href="#0070-MKTD-022">0070-MKTD-022</a>)
  - This proposal is NOT valid if the market decimal is greater than the settlement asset decimal - position decimal (<a name="0070-MKTD-023" href="#0070-MKTD-023">0070-MKTD-023</a>). For product spot this proposal is NOT valid if the market decimal is greater than the quote asset decimal - position decimal (<a name="0070-MKTD-024" href="#0070-MKTD-024">0070-MKTD-024</a>).
  - For product spot, position decimal should be NOT greater than base asset decimal (<a name="0070-MKTD-025" href="#0070-MKTD-025">0070-MKTD-025</a>)
  - For product spot, the market proposal is NOT valid if the position decimal is greater than base asset decimal (<a name="0070-MKTD-026" href="#0070-MKTD-026">0070-MKTD-026</a>)
- Assert that the settlement calculation can be correctly calculated when:
  - settlement data decimal is > than the settlement asset decimal (i.e. settlement data has more decimal places than the settlement asset and precision will be lost) (<a name="0070-MKTD-018" href="#0070-MKTD-018">0070-MKTD-018</a>)
  - settlement data decimal is < than the settlement asset deciaml (i.e. settlement data has less decimal places than the settlement asset and no precision will be lost) (<a name="0070-MKTD-019" href="#0070-MKTD-019">0070-MKTD-019</a>)
  - settlement data decimal is equal to the settlement asset decimaln (i.e. settlement data has less decimal places than the settlement asset and no precision will be lost) (<a name="0070-MKTD-020" href="#0070-MKTD-020">0070-MKTD-020</a>)
- As a user all orders placed (either directly or through LP) are shown in events with prices in market decimal places (<a name="0070-MKTD-003" href="#0070-MKTD-003">0070-MKTD-003</a>). For product spot: (<a name="0070-MKTD-010" href="#0070-MKTD-010">0070-MKTD-010</a>)
- As a user all transfers (margin top-up, release, MTM settlement) are calculated and communicated (via events) in asset decimal places (<a name="0070-MKTD-004" href="#0070-MKTD-004">0070-MKTD-004</a>). For product spot: (<a name="0070-MKTD-011" href="#0070-MKTD-011">0070-MKTD-011</a>)
- As a user I should see the market data prices using market decimal places. (<a name="0070-MKTD-005" href="#0070-MKTD-005">0070-MKTD-005</a>). For product spot: (<a name="0070-MKTD-012" href="#0070-MKTD-012">0070-MKTD-012</a>)
- Price bounds are calculated in asset decimal places, but enforced rounded to the closest value in market decimal places in range (<a name="0070-MKTD-006" href="#0070-MKTD-006">0070-MKTD-006</a>). For product spot: (<a name="0070-MKTD-013" href="#0070-MKTD-013">0070-MKTD-013</a>)
- As a user, offsets specified in pegged orders represent the smallest incremental value to tick away from the pegged price of a pegged order according to the market decimal places (<a name="0070-MKTD-007" href="#0070-MKTD-007">0070-MKTD-007</a>). For product spot: (<a name="0070-MKTD-014" href="#0070-MKTD-014">0070-MKTD-014</a>)
- Trades prices, like orders, are shown in market decimal places. The transfers and margin requirements are in asset decimal places. ( <a name="0070-MKTD-008" href="#0070-MKTD-008">0070-MKTD-008</a>). For product spot: ( <a name="0070-MKTD-015" href="#0070-MKTD-015">0070-MKTD-015</a>)
- Settlement data received during trading on a perpetuals market is correctly handled according to the specified decimal places (<a name="0070-MKTD-017" href="#0070-MKTD-017">0070-MKTD-017</a>)


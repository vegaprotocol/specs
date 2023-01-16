# Built-in [Product](./0051-PROD-product.md): Cash Settled Perpetual Futures (CSF)

This built-in product provides perpetual futures that are cash-settled, i.e. they are margined and settled in a single asset.

[Background reading](https://www.paradigm.xyz/2021/05/everlasting-options/#Perpetual_Futures)

Perpetual futures are a simple "delta one" product. Mark-to-market settlement occurs with a predefined frequency as per [0003-MTMK-mark_to_market_settlement](0003-MTMK-mark_to_market_settlement.md).  Additionally, a settlement using external data is carried out whenever `settlement_cue` is triggered AND the `settlement_data` is received. A number of protective measures can be specified for a market to deal with data scarcity in a predefined way.

## 1. Product parameters

1. `settlement_asset (Settlement Asset)`: this is used to specify the single asset that an instrument using this product settles in.
1. `settlement_cue (Data Source)`: this data is used to indicate that next periodic settlement should happen imminently.
1. `settlement_data (Data Source: number)`: this data is used by the product to calculate periodic settlement cashflows. The receipt of this data triggers this calculation and the transfers between parties to "true up" to the external reference price.
1. `settlement_cue_auction_duration`: a time interval which specifies the duration of an auction started once settlement cue is received. The auction ends when the specified time elapses or when the settlement data is received. A value of `0s` indicates no auction.
1. `max_settlement_gap`: a time interval which specifies the amount of time without periodic settlement after which the market will go into protective auction and remain in that mode until settlement data is received.
1. `settlement_price_monitoring`: a boolean flag indicating if periodic settlement price should go through the [price monitoring](0032-PRIM-price_monitoring.md) logic. If set to `true` any valid `settlement_data` ingested by the market will go through the price monitoring engine and contribute to its price history as well as trigger a price monitoring auction if it falls outside the current valid price bounds.

Validation: none required as these are validated by the asset and data source frameworks.

## 2. Settlement assets

1. Returns `[cash_settled_perpetual_future.settlement_asset]`

## 3. Valuation function

```javascript
// Futures are quoted in directly terms of price
cash_settled_perpetual_future.value(quote) {
	return quote
}
```

## 4. Lifecycle triggers

### 4.1 Periodic settlement cue

```javascript
cash_settled_perpetual_future.settlement_cue(event) {
	setWaitingForSettlementDataSince(vega.time)
}
```

### 4.2 Periodic settlement data received

```javascript
cash_settled_perpetual_future.settlement_data(event) {
	cashflow = cash_settled_perpetual_future.value(event.data) - cash_settled_perpetual_future.value(market.mark_price))
	settle(cash_settled_perpetual_future.settlement_asset, cashflow)
	setMarkPrice(event.data)
}
```

### 4.2.1 Periodic settlement during auction

TODO: How do we want to handle settlement event occurring during auction? Same for all auctions?
Do we just wait until the end of auction and try to use the settlement data then? If it's stale we just don't use it, uncross and carry on and count on max settlement gap logic to force the market to eventually have a periodic settlement using fresh data?

### 4.3 Protective auctions

In additional to protective auctions available for any market on Vega this product has protective auctions that are specific to it.

### 4.3.1 Awaiting periodic settlement data

An optional auction of predetermined maximum duration which gets triggered when the [settlement cue](#41-periodic-settlement-cue) data arrives and ends either upon receiving the settlement data or when the auction duration elapses.

### 4.3.2 Max settlement gap exceeded

If the amount of time since last [periodic settlement](#41-periodic-settlement-cue) exceeds `max_settlement_gap` set for the market then the market goes into auction mode and remains in it until new settlement data is received. Upon receiving the settlement data the auction uncrosses, positions are updated and then settled using the newly arrived data. It is possible to update the market's data source when it is in protective auction.

## Acceptance Criteria

1. Create a Cash Settled Perpetual Future with the settlement data provided by an external data source (<a name="0053-COSMICELEVATOR-001" href="#0053-COSMICELEVATOR-001">0053-COSMICELEVATOR-001</a>)
1. Create a Cash Settled Perpetual Future for any settlement asset that's configured in Vega (<a name="0053-COSMICELEVATOR-002" href="#0053-COSMICELEVATOR-002">0053-COSMICELEVATOR-002</a>)
1. The data source can be changed via governance (<a name="0053-COSMICELEVATOR-003" href="#0053-COSMICELEVATOR-003">0053-COSMICELEVATOR-003</a>)
1. It is not possible to change settlement asset via governance (<a name="0053-COSMICELEVATOR-004" href="#0053-COSMICELEVATOR-004">0053-COSMICELEVATOR-004</a>)
1. Mark to [market settlement](./0003-MTMK-mark_to_market_settlement.md) works correctly (<a name="0053-COSMICELEVATOR-005" href="#0053-COSMICELEVATOR-005">0053-COSMICELEVATOR-005</a>)
1. Periodic settlement at each oracle event works correctly (<a name="0053-COSMICELEVATOR-006" href="#0053-COSMICELEVATOR-006">0053-COSMICELEVATOR-006</a>)
1. Every valid lifecycle event (i.e. every oracle price update matching the data source specified) triggers a periodic settlement and causes settlement cashflows to be created and funds to be transferred. (<a name="0053-COSMICELEVATOR-007" href="#0053-COSMICELEVATOR-007">0053-COSMICELEVATOR-007</a>)
1. Directly after receipt of oracle data for periodic settlement, the mark price is equal to the settlement data price provided and this is exposed on event bus and market data APIs (<a name="0053-COSMICELEVATOR-008" href="#0053-COSMICELEVATOR-008">0053-COSMICELEVATOR-008</a>)

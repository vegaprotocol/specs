# Built-in [Product](./0051-PROD-product.md): Cash Settled Perpetual Futures (CSF)

This built-in product provides perpetual futures that are cash-settled, i.e. they are margined and settled in a single asset.

[Background reading](https://www.paradigm.xyz/2021/05/everlasting-options/#Perpetual_Futures)

Perpetual futures are a simple "delta one" product.

## 1. Product parameters

1. `settlement_data (Data Source: number)`: this data is used by the product to calculate periodic settlement cashflows. The receipt of this data triggers this calculation and the transfers between parties to "true up" to the external reference price.
1. `settlement_asset (Settlement Asset)`: this is used to specify the single asset that an instrument using this product settles in.
1. ` data_source_spec_binding`: The binding between the data source spec and the settlement data.
1. `max_settlement_gap`: value expressed in seconds which specifies the amount of time without settlement ("periodic funding") after which the market will go into protective auction and remain in that mode until settlement data is received.

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

### 4.1 Settlement ("periodic funding")

```javascript
cash_settled_perpetual_future.settlement_data(event) {
	cashflow = cash_settled_perpetual_future.value(event.data) - cash_settled_perpetual_future.value(market.mark_price))
	settle(cash_settled_perpetual_future.settlement_asset, cashflow)
	setMarkPrice(event.data)
}
```

### 4.2 Protective auction

If the amount of time in seconds since last [settlement](#41-settlement-periodic-funding) exceeds `max_settlement_gap` set for the market then the market goes into auction mode and remains in it until new settlement data is received. Upon receiving the settlement data the auction uncrosses, positions are updated and then settled using the newly arrived data. It is possible to update the market's data source when it is in protective auction.

## Acceptance Criteria

1. Create a Cash Settled Perpetual Future with the settlement data provided by an external data source (<a name="0053-COSMICELEVATOR-001" href="#0053-COSMICELEVATOR-001">0053-COSMICELEVATOR-001</a>)
1. Create a Cash Settled Perpetual Future for any settlement asset that's configured in Vega (<a name="0053-COSMICELEVATOR-002" href="#0053-COSMICELEVATOR-002">0053-COSMICELEVATOR-002</a>)
1. The data source can be changed via governance (<a name="0053-COSMICELEVATOR-003" href="#0053-COSMICELEVATOR-003">0053-COSMICELEVATOR-003</a>)
1. It is not possible to change settlement asset via governance (<a name="0053-COSMICELEVATOR-004" href="#0053-COSMICELEVATOR-004">0053-COSMICELEVATOR-004</a>)
1. Mark to [market settlement](./0003-MTMK-mark_to_market_settlement.md) works correctly (<a name="0053-COSMICELEVATOR-005" href="#0053-COSMICELEVATOR-005">0053-COSMICELEVATOR-005</a>)
1. Settlement at each oracle event (periodic funding) works correctly (<a name="0053-COSMICELEVATOR-006" href="#0053-COSMICELEVATOR-006">0053-COSMICELEVATOR-006</a>)
1. Every valid lifecycle event (i.e. every oracle price update matching the data source specified) triggers a periodic funding settlement and causes settlement cashflows to be created and funds to be transferred. (<a name="0053-COSMICELEVATOR-007" href="#0053-COSMICELEVATOR-007">0053-COSMICELEVATOR-007</a>)
1. Directly after receipt of oracle data for periodic funding, the mark price is equal to the settlement data price provided and this is exposed on event bus and market data APIs (<a name="0053-COSMICELEVATOR-008" href="#0053-COSMICELEVATOR-008">0053-COSMICELEVATOR-008</a>)

# Built-in [Product](./0051-PROD-product.md): Cash Settled Perpetual Futures (CSF)

This built-in product provides perpetual futures contracts that are cash-settled, i.e. they are margined and settled in a single asset, and they never expire.

[Background reading](https://www.paradigm.xyz/2021/05/everlasting-options/#Perpetual_Futures)

Perpetual futures are a simple "delta one" product. Mark-to-market settlement occurs with a predefined frequency as per [0003-MTMK-mark_to_market_settlement](0003-MTMK-mark_to_market_settlement.md).  Additionally, a settlement using external data is carried out whenever `settlement_cue` is triggered AND the `settlement_data` is received within the specified `data_ingestion_period` and has a timestamp that lies within that time window. A number of protective measures can be specified for a market to deal with data scarcity in a predefined way.

## 1. Product parameters

1. `settlement_asset (Settlement Asset)`: this is used to specify the single asset that an instrument using this product settles in.
1. `settlement_cue (Data Source: datetime)`: this data is used to indicate that next periodic settlement should happen imminently and specify the start of the data ingestion time window.
1. `settlement_data (Data Source: number)`: this data is used by the product to calculate periodic settlement cashflows. The receipt of this data triggers this calculation and the transfers between parties to "true up" to the external reference price.
1. `settlement_cue_auction_duration`: a time interval which specifies the duration of an auction started once settlement cue is received. The auction ends when the specified time elapses or when the settlement data is received. A value of `0s` indicates no auction.
1. `data_ingestion_period`: specifies the length of time window since `settlement_cue` event during which data from `settlement_data` data source will be accepted by the market. Once the first value is received no further data is accepted.
1. `max_settlement_gap`: a time interval which specifies the amount of time without periodic settlement after which the market will go into protective auction and remain in that mode until settlement data is received.
1. `settlement_data_monitoring`: if set to `true` any valid `settlement_data` ingested by the market will be checked against the market's [price monitoring](0032-PRIM-price_monitoring.md) engine. Specifically, the incoming settlement data will be checked against market's active [price monitoring bounds](0021-MDAT-market_data_spec.md#market-data-fields), if it falls within the market the periodic settlement proceeds, otherwise the system behaves as if the data was never received. This implies that if the oracle serves another datapoint within the `data_ingestion_period` which falls within the price monitoring bounds it will be used the periodic settlement.

Validation: none required as these are validated by the asset and data source frameworks.

### Example specification

The pseudocode below specifies a possible configuration of the built-in perpetual futures contract product. The emphasis is on modelling required properties of this product, not the exact semantics used as these will most likely differ in the implementation.

```yaml
	product: built-in perpetual futures contract
		settlement_asset: XYZ
		settlement_cue:
			internal_time_oracle:
				repeating:
					- every 24h from 20230201T09:30:00
					- every 168h from 20230203T12:00:00
		settlement_data:
			data_source: SignedMessage{ pubkey=0xA45e...d6 }
			field: 'price'
			filters: 
				- ticker: 'TSLA'
				- timestamp: 'time >= 09:25:00'
				- timestamp: 'time <= 10:05:00'
				- timestamp: 'time >= 11:55:00'
				- timestamp: 'time <= 12:35:00'
		settlement_cue_auction_duration: "1h"
		data_ingestion_period: "30min"
		max_settlement_gap: "48h"
		settlement_data_monitoring: true
```

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

Whenever an appropriate event is received the settlement cue returns the current `vega.time` to indicate the time at which the next periodic settlement should happen if other conditions for it are met:

```javascript
cash_settled_perpetual_future.settlement_cue(event) {
	return vega.time
}
```

### 4.2 Periodic settlement data received

Once the [periodic settlement cue](#41-periodic-settlement-cue) time is received the specified settlement data oracle gets monitored for incoming data. If the periodic settlement data gets received within specified `data_ingestion_period` from the periodic settlement cue AND its timestamp falls within that time window AND its value falls within all of market's active [price monitoring bounds](0021-MDAT-market_data_spec.md#market-data-fields), then:

```javascript
cash_settled_perpetual_future.settlement_data(event) {
	cashflow = cash_settled_perpetual_future.value(event.data) - cash_settled_perpetual_future.value(market.mark_price))
	settle(cash_settled_perpetual_future.settlement_asset, cashflow)
	setMarkPrice(event.data)
}
```

### 4.2.1 Periodic settlement during [auction](0026-AUCT-auctions.md)

Periodic settlement is not allowed during the opening auction and it's extensions.
If periodic settlement data happens whilst market is in auction of any other type then:

* uncross the auction at the received settlement price without leaving the auction mode,
* generate the trades implied by the above and update the positions,
* carry out settlement based on the updated positions,
* let the market carry on in the same auction mode it was it before the settlement data was received until relevant auction exit conditions are met and the market returns to its default trading mode.

### 4.3 Protective auctions

In additional to protective auctions available for any market on Vega this product has protective auctions that are specific to it.

### 4.3.1 Awaiting periodic settlement data

An optional auction of predetermined maximum duration which gets triggered when the [settlement cue](#41-periodic-settlement-cue) data arrives and ends either upon receiving the settlement data or when the auction duration elapses.

### 4.3.2 Max settlement gap exceeded

If the amount of time since last [periodic settlement](#41-periodic-settlement-cue) exceeds `max_settlement_gap` set for the market then the market goes into auction mode and remains in it until new settlement data is received. Upon receiving the settlement data the auction uncrosses, positions are updated and then settled using the newly arrived data. It is possible to update the market's data source when it is in protective auction.

## Acceptance Criteria

1. Create a Cash Settled Perpetual Future with the settlement data provided by an external data source. (<a name="0053-COSMICELEVATOR-001" href="#0053-COSMICELEVATOR-001">0053-COSMICELEVATOR-001</a>)
1. Create a Cash Settled Perpetual Future for any settlement asset that's configured in Vega. (<a name="0053-COSMICELEVATOR-002" href="#0053-COSMICELEVATOR-002">0053-COSMICELEVATOR-002</a>)
1. The data source can be changed via governance. (<a name="0053-COSMICELEVATOR-003" href="#0053-COSMICELEVATOR-003">0053-COSMICELEVATOR-003</a>)
1. It is not possible to change settlement asset via governance. (<a name="0053-COSMICELEVATOR-004" href="#0053-COSMICELEVATOR-004">0053-COSMICELEVATOR-004</a>)
1. [Mark to market settlement](./0003-MTMK-mark_to_market_settlement.md) works correctly with a predefined frequency irrespective of periodic settlement driven by the oracle data. (<a name="0053-COSMICELEVATOR-005" href="#0053-COSMICELEVATOR-005">0053-COSMICELEVATOR-005</a>)
1. Receiving correctly formatted data from the settlement cue and settlement data oracles (no more than `data_ingestion_period` apart) during the opening auction does not cause settlement. (<a name="0053-COSMICELEVATOR-006" href="#0053-COSMICELEVATOR-006">0053-COSMICELEVATOR-006</a>)
1. Receiving correctly formatted data from the settlement cue and settlement data oracles (no more than `data_ingestion_period` apart) during continuous trading results in periodic settlement. (<a name="0053-COSMICELEVATOR-007" href="#0053-COSMICELEVATOR-007">0053-COSMICELEVATOR-007</a>)
1. Receiving correctly formatted data from the settlement cue and settlement data oracles (no more than `data_ingestion_period` apart) during liquidity monitoring auction results in partial uncrossing of the auction at received price and periodic settlement. Market remains in liquidity monitoring auction until enough additional liquidity gets committed to the market. (<a name="0053-COSMICELEVATOR-008" href="#0053-COSMICELEVATOR-008">0053-COSMICELEVATOR-008</a>)
1. Receiving correctly formatted data from the settlement cue and settlement data oracles (no more than `data_ingestion_period` apart) during price monitoring auction results in partial uncrossing of the auction at received price and periodic settlement. Market remains in price monitoring auction until its original duration elapses, uncrosses the auction and goes back to continuous trading mode. (<a name="0053-COSMICELEVATOR-009" href="#0053-COSMICELEVATOR-009">0053-COSMICELEVATOR-009</a>)
1. Receiving correctly formatted data from the settlement cue and settlement data oracles (no more than `data_ingestion_period` apart) with settlement price violating a price monitoring bound does not cause periodic settlement and the market remains in the awaiting periodic settlement data auction until the end (TODO: Do we want to end the auction at this point? If not do we want to allow the possibility of other settlement data coming it?). (<a name="0053-COSMICELEVATOR-010" href="#0053-COSMICELEVATOR-010">0053-COSMICELEVATOR-010</a>)
1. Periodic settlement causes settlement cashflows to be created, funds to be transferred and the [mark price](0021-MDAT-market_data_spec.md#market-data-fields) to be updated. (<a name="0053-COSMICELEVATOR-011" href="#0053-COSMICELEVATOR-011">0053-COSMICELEVATOR-011</a>)
1. Once the max settlement gap gets exceeded the market goes into auction with no fixed duration. It is possible to change the settlement cue and settlement data oracles during that auction and once the new, correctly formatted, data from both oracles is received (no more than `data_ingestion_period` apart) periodic settlement is carried out and the market goes out of auction (<a name="0053-COSMICELEVATOR-012" href="#0053-COSMICELEVATOR-012">0053-COSMICELEVATOR-012</a>)

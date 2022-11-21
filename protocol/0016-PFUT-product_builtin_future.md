# Built-in [Product](./0051-PROD-product.md): Cash Settled Futures (CSF)

This built-in product provides "direct" futures (i.e. opposite of inverse futures) that are cash-settled, i.e. they are margined and settled in a single asset.

Background reading: https://www.cmegroup.com/education/courses/introduction-to-futures.html

Futures are a simple "delta one" product and the first product supported by Vega. Note that in future (hah) there will likely be a number of other products (synthetics, contracts for difference).

## 1. Product parameters

1. `trading_termination_trigger (Data Source)`: triggers the market to move to `trading terminated` status ahead of settlement at expiry (required to ensure no trading can occur after the settlement result may be known by participants). (This would usually be a date/time based trigger but may also use an oracle.) This will move market to `cancelled` state if market never left `pending state` (opening auction).
1. `settlement_data (Data Source: number)`: this data is used by the product to calculate the final settlement cashflows. The receipt of this data triggers this calculation and therefore also moving the product to the `settled` status.
1. `settlement_asset (Settlement Asset)`: this is used to specify the single asset that an instrument using this product settles in.

Validation: none required as these are validated by the asset and data source frameworks.


## 2. Settlement assets

1. Returns `[cash_settled_future.settlement_asset]`.\
1. It is not possible to change settlement asset via governance.


## 3. Valuation function

```javascript
// Futures are quoted in directly terms of price 
cash_settled_future.value(quote) {
	return quote
}
```


## 4. Lifecycle triggers

### 4.1 Termination of trading

```javascript
cash_settled_future.trading_termination_trigger(event) {
	setMarketStatus(TRADING_TERMINATED)
}
```


### 4.2 Final settlement ("expiry")

```javascript
cash_settled_future.settlement_data(event) {

	// If settlement data was received prior to trading termination use the last value received, otherwise use the first value received after trading is terminated 
	while market.status != TRADING_TERMINATED {
		waitForMarketStatus(TRADING_TERMINATED)
	}

	final_cashflow = cash_settled_future.value(event.data) - cash_settled_future.value(market.mark_price)
	settle(cash_settled_future.settlement_asset, final_cashflow)
	setMarkPrice(event.data)
	setMarketStatus(SETTLED)
}
```


# Acceptance Criteria

1. Create a Cash Settled Future with trading termination triggered by a date/time based data source (<a name="0016-PFUT-001" href="#0016-PFUT-001">0016-PFUT-001</a>)
2. Create a Cash Settled Future with trading termination triggered by an external data source (<a name="0016-PFUT-002" href="#0016-PFUT-002">0016-PFUT-002</a>)
3. Create a Cash Settled Future with the settlement data provided by an external data source (<a name="0016-PFUT-003" href="#0016-PFUT-003">0016-PFUT-003</a>)
4. Create a Cash Settled Future for any settlement asset that's configured in Vega
  1. Either data source can be changed via governance (<a name="0016-PFUT-004" href="#0016-PFUT-004">0016-PFUT-004</a>)
  2. Mark to market settlement works correctly (<a name="0016-PFUT-006" href="#0016-PFUT-006">0016-PFUT-006</a>)
  3. Settlement at expiry works correctly (<a name="0016-PFUT-007" href="#0016-PFUT-007">0016-PFUT-007</a>)
1. A market that receives settlement data before trading termination always stores the newest one and upon receiving the trading termination trigger settles the market (<a name="0016-PFUT-008" href="#0016-PFUT-008">0016-PFUT-008</a>)
1. A market that has already settled and is in trading terminated status never processes any more lifecycle events even if the data source sends more valid data (<a name="0016-PFUT-012" href="#0016-PFUT-009">0016-PFUT-009</a>)
1. Lifecycle events are processed atomically as soon as they are triggered, i.e. the above condition always holds even for two or more transactions arriving at effectively the same time - only the transaction that is sequenced first triggers final settlement (<a name="0016-PFUT-010" href="#0016-PFUT-010">0016-PFUT-010</a>)
1. Once a market is finally settled, the mark price is equal to the settlement data and this is exposed on event bus and market data APIs (<a name="0016-PFUT-011" href="#0016-PFUT-011">0016-PFUT-011</a>)
1. Assure [settment-at-expiry.feature](https://github.com/vegaprotocol/vega/blob/develop/core/integration/features/verified/0002-STTL-settlement_at_expiry.feature) executes correctly (<a name="0016-PFUT-012" href="#0016-PFUT-012">0016-PFUT-012</a>)

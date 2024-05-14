# Built-in [Product](./0051-PROD-product.md): Cash Settled Futures (CSF)

This built-in product provides "direct" futures (i.e. opposite of inverse futures) that are cash-settled, i.e. they are margined and settled in a single asset.

[Background reading](https://www.cmegroup.com/education/courses/introduction-to-futures.html)

Futures are a simple "delta one" product and the first product supported by Vega. Note that in future there will likely be a number of other products (synthetics, contracts for difference).

## 1. Product parameters

1. `trading_termination_trigger (Data Source)`: triggers the market to move to `trading terminated` status ahead of settlement at expiry (required to ensure no trading can occur after the settlement result may be known by participants). (This would usually be a date/time based trigger but may also use an oracle.) This will move market to `cancelled` state if market never left `pending state` (opening auction).
1. `settlement_data (Data Source: number)`: this data is used by the product to calculate the final settlement cashflows. The receipt of this data triggers this calculation and therefore also moving the product to the `settled` status.
1. `settlement_asset (Settlement Asset)`: this is used to specify the single asset that an instrument using this product settles in.

Validation: none required as these are validated by the asset and data source frameworks.

Optional parameters:

1. `max_price`: specifies the price cap for the market, an integer understood in the context of market decimal places,
1. `binary_settlement`: if set to `true` settlement price other than `0` or `max_price` will be ignored.

Validation: `max_price` > 0.

## 2. Settlement assets

1. Returns `[cash_settled_future.settlement_asset]`.
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

## 2. Additional considerations around optional parameters

Optional parameters allow creating capped futures (all prices including settlement price must be in the range `[0, max_price]`) or binary options (all intermediate prices must be in the range `[0, max_price]`, settlement price bust be either `0` or `max_price`) markets.

### 2.1 Order price validation

If `max_price` is specified the order prices should be validated so that the maximum price of any order is `max_price`. Peg orders should be validated so that if the resulting price would be higher at any point it gets temporarily capped at `max_price`.

### 2.2 Mark price validation

If `max_price` is specified, mark price candidates greater than `max_price` should be ignored and [mark-to-market settlement](./0003-MTMK-mark_to_market_settlement.md) should not be carried out until a mark price within the `[0, max_price]` range arrives.

### 2.3 Settlement price validation

If `max_price` is specified:

- When `binary_settlement` parameter is set to `false` any value `0 <= settlement_price <= max_price` should be accepted as a settlement price.
- When `binary_settlement` parameter is set to `true` only `settlement_price=0` or `settlement_price=max_price` should be accepted.
- Any other values get ignored and market does not settle, instead it still waits for subsequent values from the settlement oracle until a value which passes the above conditions arrives.

## 3. Binary options

Please note that selecting a future product with `max_price` specified and `binary_settlement` flag set to `true` allows representing binary options markets.

## Acceptance Criteria

1. Create a Cash Settled Future with trading termination triggered by a date/time based data source (<a name="0016-PFUT-001" href="#0016-PFUT-001">0016-PFUT-001</a>)
1. Create a Cash Settled Future with trading termination triggered by an external data source (<a name="0016-PFUT-002" href="#0016-PFUT-002">0016-PFUT-002</a>)
1. Create a Cash Settled Future with the settlement data provided by an external data source (<a name="0016-PFUT-003" href="#0016-PFUT-003">0016-PFUT-003</a>)
1. Create a Cash Settled Future for any settlement asset that's configured in Vega
    1. Either data source can be changed via governance (<a name="0016-PFUT-004" href="#0016-PFUT-004">0016-PFUT-004</a>)
    1. Mark to market settlement works correctly (<a name="0016-PFUT-006" href="#0016-PFUT-006">0016-PFUT-006</a>)
    1. Settlement at expiry works correctly (<a name="0016-PFUT-007" href="#0016-PFUT-007">0016-PFUT-007</a>)
1. A market that receives settlement data before trading termination always stores the newest one and upon receiving the trading termination trigger settles the market (<a name="0016-PFUT-008" href="#0016-PFUT-008">0016-PFUT-008</a>)
1. A market that has already settled and is in trading terminated status never processes any more lifecycle events even if the data source sends more valid data (<a name="0016-PFUT-009" href="#0016-PFUT-009">0016-PFUT-009</a>)
1. Lifecycle events are processed atomically as soon as they are triggered, i.e. the above condition always holds even for two or more transactions arriving at effectively the same time - only the transaction that is sequenced first triggers final settlement (<a name="0016-PFUT-010" href="#0016-PFUT-010">0016-PFUT-010</a>)
1. Once a market is finally settled, the mark price is equal to the settlement data and this is exposed on event bus and market data APIs (<a name="0016-PFUT-011" href="#0016-PFUT-011">0016-PFUT-011</a>)
1. Assure [settment-at-expiry.feature](https://github.com/vegaprotocol/vega/blob/develop/core/integration/features/verified/0002-STTL-settlement_at_expiry.feature) executes correctly (<a name="0016-PFUT-012" href="#0016-PFUT-012">0016-PFUT-012</a>)

Optional parameters:

1. Attempt to specify a `max_price` of `0` fails. (<a name="0016-PFUT-013" href="#0016-PFUT-013">0016-PFUT-013</a>)
1. When `max_price` is specified, an order with a `price > max_price` gets rejected. (<a name="0016-PFUT-014" href="#0016-PFUT-014">0016-PFUT-014</a>)
1. When `max_price` is specified and the reference of a pegged sell order moves so that the implied order price is higher than `max_price` the implied order price gets capped at. `max_price` (<a name="0016-PFUT-015" href="#0016-PFUT-015">0016-PFUT-015</a>)
1. When `max_price` is specified and market is setup to use oracle based mark price and the value received from oracle is less than `max_price` then it gets used as is and mark-to-market flows are calculated according to that price. (<a name="0016-PFUT-016" href="#0016-PFUT-016">0016-PFUT-016</a>)
1. When `max_price` is specified and the market is setup to use oracle based mark price and the value received from oracle is greater than `max_price` then it gets ignored and mark-to-market settlement doesn't occur until a mark price candidate within the `[0, max_price]` range arrives. (<a name="0016-PFUT-017" href="#0016-PFUT-017">0016-PFUT-017</a>)
1. When `max_price` is specified and `binary_settlement` flag is set to `false`, and the final settlement price candidate received from the oracle is less than or equal to `max_price` then it gets used as is and the final cashflows are calculated according to that price. (<a name="0016-PFUT-018" href="#0016-PFUT-018">0016-PFUT-018</a>)
1. When `max_price` is specified and the final settlement price candidate received from the oracle is greater than  `max_price` the value gets ignored, next a value equal to `max_price` comes in from the settlement oracle and market settles correctly. The market behaves in this way irrespective of how `binary_settlement` flag is set. (<a name="0016-PFUT-019" href="#0016-PFUT-019">0016-PFUT-019</a>)
1. When `max_price` is specified, the `binary_settlement` flag is set to `true` and the final settlement price candidate received from the oracle is greater than `0` and less than  `max_price` the value gets ignored, next a value of `0` comes in from the settlement oracle and market settles correctly. (<a name="0016-PFUT-020" href="#0016-PFUT-020">0016-PFUT-020</a>)
1. When `max_price` is specified and the market is ran in a [fully-collateralised mode](./0019-MCAL-margin_calculator.md#fully-collateralised) and it has parties with open positions settling it at a price of `max_price` works correctly and the sum of all final settlement cashflows equals 0 (loss socialisation does not happen). Assuming general account balances of all parties were `0` after opening the positions and all of their funds were in the margin accounts: long parties end up with balances equal to `position size * max_price` and short parties end up with `0` balances. (<a name="0016-PFUT-021" href="#0016-PFUT-021">0016-PFUT-021</a>)
1. When `max_price` is specified and the market is ran in a [fully-collateralised mode](./0019-MCAL-margin_calculator.md#fully-collateralised) and it has parties with open positions settling it at a price of `0` works correctly and the sum of all final settlement cashflows equals 0 (loss socialisation does not happen). Assuming general account balances of all parties were `0` after opening the positions and all of their funds were in the margin accounts: short parties end up with balances equal to `abs(position size) * max_price` and long parties end up with `0` balances. (<a name="0016-PFUT-022" href="#0016-PFUT-022">0016-PFUT-022</a>)
1. When `max_price` is specified and the market is ran in a [fully-collateralised mode](./0019-MCAL-margin_calculator.md#fully-collateralised)  and a party opens a long position at a `max_price`, no closeout happens when mark to market settlement is carried out at a price of `0`. (<a name="0016-PFUT-023" href="#0016-PFUT-023">0016-PFUT-023</a>)
1. When `max_price` is specified and the market is ran in a [fully-collateralised mode](./0019-MCAL-margin_calculator.md#fully-collateralised)  and a party opens a short position at a price of `0`, no closeout happens when mark to market settlement is carried out at a `max_price`. (<a name="0016-PFUT-024" href="#0016-PFUT-024">0016-PFUT-024</a>)
1. Futures market can be created without specifying any of the [optional paramters](#1-product-parameters). (<a name="0016-PFUT-025" href="#0016-PFUT-025">0016-PFUT-025</a>)

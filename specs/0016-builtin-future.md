# Built-in [Product](./0045-product.md): Cash Settled Futures (CSF)

This built-in product provides "direct" futures (i.e. opposite of inverse futures) that are cash-settled, i.e. they are margined and settled in a single asset.

Background reading: https://www.cmegroup.com/education/courses/introduction-to-futures.html

Futures are a simple "delta one" product and the first product supported by Vega. Note that in future (hah) there will likely be a number of other products (synthetics, contracts for difference).


## 1. Product parameters

1. `trading_termination_trigger (Data Source)`: triggers the market to move to `trading terminated` status ahead of settlement at expiry (required to ensure no trading can occur after the settlement result may be known by participants). (This would usally be a date/time based trigger but may also use an oracle.)
1. `settlement_data (Data Source: number)`: this data is used by the product to calculate the final settlement cashflows. The receipt of this data triggers this calculation and therefore also moving the product to the `settled` status.
1. `settlement_asset (Settlement Asset)`: this is used to specify the single asset that an instrument using this product settles in.

Validation: none required as these are validated by the asset and data source frameworks.


## 2. Settlement assets

1. Returns `[cash_settled_future.settlement_asset]`


## 3. Valuation function

```javascript
cash_settled_future.value(price) {
	return price
}
```


## 4. Lifecycle triggers

### 4.1 Termination of trading

```javascript
cash_settled_future.trading_termination_trigger(event) {
	market.status = TRADING_TERMINATED
}
```


### 4.2 Final settlement ("expiry")

```javascript
cash_settled_future.settlement_data(event) {

	// Suspend the market if we receive settlement data before trading termination
	// this would require investigation and governance action
	if market.status != TRADING_TERMINATED {
		market.status = SUSPENDED
		return
	}

	final_cashflow = cash_settled_future.value(event.data) - cash_settled_future.value(market.mark_price)) 
	settle(cash_settled_future.settlement_asset, final_cashflow)
	market.status = SETTLED
}
```


# Acceptance Criteria

1. Create a CSF with trading termination triggered by a date/time based data source
1. Create a CSF with trading termination triggered by an external data source
1. Create a CSF with the settlement data provided by an external data source
1. Create a CSF for any settlement asset that's configureed in Vega
1. Either data source can be changed via governance
1. It is not possible to change settlement asset via governance
1. Mark to market settlement works correctly
1. Settlement at expiry works correctly
1. A market that receives settlement data before trading termination is suspended
1. A market that was suspended for receiving settlement data before trading termination remains suspended until a governance vote changes the status
1. A market that was suspended for receiving settlement data before trading termination can be closed by governance vote
1. A market that was suspended for receiving settlement data before trading termination can be settled by governance vote if the trading_termination_trigger and settlement_data source are changed and the status is set to ACTIVE by governance vote


## Final Settlement

- [ ] check it can't happen on invalid / other data from the data source (i.e. a price with the wrong timestamp)
- [ ] check it happens with the first and only the first price that is valid per the data source definition
- [ ] check mark price is updated
- [ ] settlement at expiry only ever happens once
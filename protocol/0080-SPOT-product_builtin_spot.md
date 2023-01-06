# Built-in [Product](./0051-PROD-product.md): Spot

This built-in product provides spot contracts which allow the buying and selling of a "base" asset with a "quote" asset with immediate delivery (settlement).

When trading with Spot products, parties can only use assets they own - there is no leverage or margin. As such, target stake is to be calculated from volume over a period defined by the liquidity monitoring parameter `target_stake_parameter.time_window` rather than open interest.


## 1. Product parameters

1. `trading_termination_trigger (Data Source)`: triggers the market to move to `trading terminated` status. (This would usually be a date/time based trigger but may also use an oracle.) This will move market to `cancelled` state if market never left `pending state` (opening auction).
1. `base_quote_pair (Explicit Value)`: human readable name/abbreviation of the base/quote pair.
1. `base_asset (Settlement Asset)`: this is used to specify the asset to be purchased or sold on the market.
1. `quote_asset (Settlement Asset)`: this is used to specify the asset which can be exchanged for the base asset.


## 2. Settlement assets

1. Returns `[spot.base_asset, spot.quote_asset]`

## 3. Valuation function
```javascript

```


## 4. Lifecycle triggers

### 4.1 Termination of trading

```javascript
spot.trading_termination_trigger(event) {
	setMarketStatus(TRADING_TERMINATED)
}
```


# Acceptance Criteria

1. Settlement assets
    1. A product of any type cannot be created without specifying an enabled settlement asset for the base asset (<a name="0080-SPOT-001" href="#0080-SPOT-001">0080-SPOT-001</a>)
    1. A product of any type cannot be created without specifying an enabled settlement asset for the quote asset (<a name="0080-SPOT-002" href="#0080-SPOT-002">0080-SPOT-002</a>)
    1. A Spot product can be created for any pair or enabled assets that are configured in Vega (<a name="0080-SPOT-003" href="#0080-SPOT-003">0080-SPOT-003</a>)
1. Lifecycle triggers
    1. A Spot product can be created with trading termination triggered by a date/time based data source (<a name="0080-SPOT-004" href="#0080-SPOT-004">0080-SPOT-004</a>)
    2. A Spot product can be created with trading termination triggered by an external data source (<a name="0080-SPOT-005" href="#0080-SPOT-005">0080-SPOT-005</a>)
1. Governance
    1. Settlement assets cannot be changed through governance (<a name="0080-SPOT-007" href="#0080-SPOT-007">0080-SPOT-006</a>)
    1. Either data-source can be changed through governance (<a name="0080-SPOT-008" href="#0080-SPOT-008">0080-SPOT-007</a>)
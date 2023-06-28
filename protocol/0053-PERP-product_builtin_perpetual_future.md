# Built-in [Product](./0051-PROD-product.md): Cash Settled Perpetual Futures

This built-in product provides perpetual futures contracts that are cash-settled, i.e. they are margined and settled in a single asset, and they never expire.

Background reading: [1](https://www.paradigm.xyz/2021/05/everlasting-options/#Perpetual_Futures), [2](https://arxiv.org/pdf/2212.06888.pdf).

Perpetual futures are a simple "delta one" product. Mark-to-market settlement occurs with a predefined frequency as per [0003-MTMK-mark_to_market_settlement](0003-MTMK-mark_to_market_settlement.md).  Additionally, a settlement using external data is carried out whenever `settlement_schedule` is triggered. Data obtained from the `settlement_data_cue` and `settlement_data` oracles between to consecutive `settlement_schedule` events is used to calculate the funding payment and exchange cashflows between parties with open positions in the market. A number of protective measures are defined to deal with data availability issues in a predefined way.

Unlike traditional futures contracts, the perpetual futures never expire. Without the settlement at expiry there would be nothing in the fixed-expiry futures to tether the contract price to the underlying spot market it's based on. To assure that the perpetuals market tracks the underlying spot market sufficiently well a periodic cashflow is exchanged based on the relative prices in the two markets. Such payment covering the time period $t_{i-1}$ to $t_i$ takes the form $G_i = frac{1}{t_i-t_{i-1}} \int_{t_{i-1}}^{t_i}(F_u-S_u)du$, where $F_u$ and $S_u$ are respectively: the perpetual futures price and the spot price at time $u$. We choose to use the mark price to approximate $F_u$ and oracle to approximate $S_u$, so this is effectively the difference between the time-weighted average prices (TWAP) of the two.

## 1. Product parameters

1. `settlement_asset (Settlement Asset)`: this is used to specify the single asset that an instrument using this product settles in.
1. `settlement_schedule (Data Source: datetime)`: this data is used to indicate when the next periodic settlement should be carried out.
1. `settlement_data_cue (Data Source: datetime)` (optional): if specified, this data is used to indicate the earliest time at which the next `settlement_data` should be expected.
1. `settlement_data (Data Source: number)`: this data is used by the product to calculate periodic settlement cashflows.
1. `margin_funding_factor`: a parameter in the range $[0, 1]$ controlling how much the upcoming funding rate liability contributes to party's margin.

Validation: none required as these are validated by the asset and data source frameworks.

### Example specification

The pseudocode below specifies a possible configuration of the built-in perpetual futures product. The emphasis is on modelling required properties of this product, not the exact semantics used as these will most likely differ in the implementation.

```yaml
    product: built-in perpetual futures contract
        settlement_asset: XYZ
        settlement_schedule:
            internal_time_oracle:
                repeating:
                    - every 8h from 20230201T09:30:00
                    - every 168h from 20230203T12:00:00
        settlement_cue:
            internal_time_oracle:
                repeating:
                    - every 1min from 20230201T09:30:00
       settlement_data:
            data_source: SignedMessage{ pubkey=0xA45e...d6 }
            field: 'price'
            filters: 
                - vegaprotocol.builtin.timestamp: >= 'settlement_cue.time'
                - vegaprotocol.builtin.timestamp: <= 'settlement_cue.time' + "15s"
                - 'timestamp': >= 'settlement_cue.time'
                - 'timestamp': <= 'settlement_cue.time' + "10s"
                - 'ticker': 'TSLA'
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

### 4.1. Periodic settlement cue

Whenever an appropriate event is received the settlement cue returns the current `vegaprotocol.builtin.timestamp` to indicate the time around which the next periodic settlement data point is expected:

```javascript
cash_settled_perpetual_future.settlement_cue(event) {
	return vegaprotocol.builtin.timestamp
}
```

### 4.2. Periodic settlement data point received

If settlement cue is not specified then all the coming from the settlement data oracle gets ingested. If settlement cue is specified, then once the [settlement cue](#41-periodic-settlement-cue) time is received the specified settlement data oracle gets monitored for incoming data. It must be possible to filter the data by the time it was received at (see [0048-DSRI-data_source_internal](./0048-DSRI-data_source_internal.md#13-vega-time-changed)) and to use the time provided by the settlement cue as a variable in such filter.

If the periodic settlement data received satisfies all the filters that have been specified for it then that data point (`y`) along with the current `mark_price` (`x`) for the market and the current `vegaprotocol.builtin.timestamp` (`t`) gets stored as the funding payment data point.

### 4.3. Mark to market settlement

Every time a [mark to market settlement](./0003-MTMK-mark_to_market_settlement.md) is carried out the value of the last periodic settlement data point received along with the price used for MTM settlement and the current `vegaprotocol.builtin.timestamp` gets stored as the funding payment data point. If no periodic settlement data has been received yet then the funding payment data point should not be created.

### 4.4. Periodic settlement

When the `settlement_schedule` event is received the latest funding payment data point gets repeated with the timestamp set to the current value of `vegaprotocol.builtin.timestamp`.

The next step is to calculate the periodic settlement funding payment. If there are no periodic settlement data points then the periodic settlement is skipped. Otherwise, consider all the periodic settlement data points and calculate the time-weighted average price difference as:

```go
sd := 0
st := 0
for i := 0; i < len(data_points) - 1; i++ {
    t := data_points[i+1].t-data_points[i].t
    d := data_points[i].x - data_points[i].y     // recall that x stands for mark price and y for the external price source input
    sd += d * t
    st += t
}
funding_payment = sd / st
```

All the funding payment data points except for the last one (it should get carried over as the first data point for the next period) can then be deleted.

Last step is to calculate each party's cash flows as $-\text{open volume} * \text{funding payment}$ where cashflows are first collected from parties that are making the payment (negative value of the cashflow, i.e. longs when the funding payment is positive) and distributed to those receiving it. Any shortfall should be made-up from the insurance pool and if that's not possible loss socialisation should be applied (exactly as per mark-to-market settlement methodology).

### 4.4.1. Periodic settlement during [auction](0026-AUCT-auctions.md)

Periodic settlement is not allowed during the opening auction and it's extensions.
If periodic settlement data happens whilst market is in auction of any other type then periodic settlement should be carried out as per above methodology and the market should remain in auction until it's allowed to move back into market's default trading mode.

### 5. Margin considerations

To assure adequate solvency we need to include the estimate of the upcoming funding payment in maintenance margin estimate for the party. Let $t_{k-1}$ be the time of the last funding payment. Let $t$ be current time ($t < t_k$).
Calculate $G_t$ as the [funding payment](#44-periodic-settlement) between $t_k$ and $t$.
For perpetual futures markets set the maintenance margin as:

```math
m^{\text{maint (perps)}}_t = m^{\text{maint}}_t + \text{margin funding factor} \cdot \max(0,G_t),
```

where $m^{\text{maint}}_t$ is the current maintenance margin as per the [margin spec](./0019-MCAL-margin_calculator.md)

### API considerations

It should be possible to query the market for the list of current funding payment data points as well as history of calculated funding payment values.

## Acceptance Criteria

1. Create a Cash Settled Perpetual Future with the settlement data provided by an external data source. (<a name="0053-PERP-001" href="#0053-PERP-001">0053-PERP-001</a>)
1. Create a Cash Settled Perpetual Future for any settlement asset that's configured in Vega. (<a name="0053-PERP-002" href="#0053-PERP-002">0053-PERP-002</a>)
1. Any of the data sources used by the product can be changed via governance. (<a name="0053-PERP-003" href="#0053-PERP-003">0053-PERP-003</a>)
1. It is not possible to change settlement asset via governance. (<a name="0053-PERP-004" href="#0053-PERP-004">0053-PERP-004</a>)
1. [Mark to market settlement](./0003-MTMK-mark_to_market_settlement.md) works correctly with a predefined frequency irrespective of the behaviour of any of the oracles specified for the market. (<a name="0053-PERP-005" href="#0053-PERP-005">0053-PERP-005</a>)
1. Receiving an event from the settlement schedule oracle during the opening auction does not cause settlement. (<a name="0053-PERP-006" href="#0053-PERP-006">0053-PERP-006</a>)
1. Receiving correctly formatted data from the settlement cue, settlement data oracles and settlement schedule oracles during continuous trading results in periodic settlement. (<a name="0053-PERP-007" href="#0053-PERP-007">0053-PERP-007</a>)
1. Receiving correctly formatted data from the settlement cue, settlement data and settlement schedule oracles during liquidity monitoring auction results in the exchange of periodic settlement cashflows. Market remains in liquidity monitoring auction until enough additional liquidity gets committed to the market. (<a name="0053-PERP-008" href="#0053-PERP-008">0053-PERP-008</a>)
1. Receiving correctly formatted data from the settlement cue, settlement data and settlement schedule oracles during price monitoring auction results in the exchange of periodic settlement cashflows. Market remains in price monitoring auction until its original duration elapses, uncrosses the auction and goes back to continuous trading mode. (<a name="0053-PERP-009" href="#0053-PERP-009">0053-PERP-009</a>)
1. When the funding rate is positive the margin levels of parties with long positions are larger than what the basic margin calculations imply. Moreover, the additional amount grows as the funding payment nears and drops right after the payment. Parties with short positions are not impacted. (<a name="0053-PERP-015" href="#0053-PERP-015">0053-PERP-015</a>)
1. When the funding rate is negative the margin levels of parties with short positions are larger than what the basic margin calculations imply. Moreover, the additional amount grows as the funding payment nears and drops right after the payment. Parties with long positions are not impacted. (<a name="0053-PERP-016" href="#0053-PERP-016">0053-PERP-016</a>)
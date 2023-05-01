# Built-in [Product](./0051-PROD-product.md): Cash Settled Perpetual Futures (CSF)

This built-in product provides perpetual futures contracts that are cash-settled, i.e. they are margined and settled in a single asset, and they never expire.

Background reading: [1](https://www.paradigm.xyz/2021/05/everlasting-options/#Perpetual_Futures), [2](https://arxiv.org/pdf/2212.06888.pdf).

Perpetual futures are a simple "delta one" product. Mark-to-market settlement occurs with a predefined frequency as per [0003-MTMK-mark_to_market_settlement](0003-MTMK-mark_to_market_settlement.md).  Additionally, a settlement using external data is carried out whenever `settlement_schedule` is triggered and data obtained from the `settlement_data_cue` and `settlement_data` oracles is used to calcualte the funding rate.

## 1. Product parameters

1. `settlement_asset (Settlement Asset)`: this is used to specify the single asset that an instrument using this product settles in.
1. `settlement_schedule (Data Source: datetime)`: this data is used to indicate when the next periodic settlement should be carried out.
1. `settlement_data_cue (Data Source: datetime)`: this data is used to indicate the earliest time at which the next `settlement_data` should be expected.
1. `settlement_data (Data Source: number)`: this data is used by the product to calculate periodic settlement cashflows.
1. `max_settlement_schedule_gap`: a time interval which specifies the amount of time without the receipt of a valid `settlement_schedule` oracle event after which the market will go into protective auction and remain in that mode until `settlement_schedule` data is received.
1. `max_settlement_data_gap`:a time interval which specifies the amount of time without the receipt of a valid `settlement_data` oracle event after which the market will go into protective auction and remain in that mode until `settlement_data` data is received.

Validation: none required as these are validated by the asset and data source frameworks.

### Example specification

The pseudocode below specifies a possible configuration of the built-in perpetual futures contract product. The emphasis is on modelling required properties of this product, not the exact semantics used as these will most likely differ in the implementation.

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
        max_settlement_schedule_gap:  "17h"
        max_settlement_data_gap: "1h"
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

Whenever an appropriate event is received the settlement cue returns the current `vegaprotocol.builtin.timestamp` to indicate the time around which the next periodic settlement data point is expected:

```javascript
cash_settled_perpetual_future.settlement_cue(event) {
	return vegaprotocol.builtin.timestamp
}
```

### 4.2 Periodic settlement data point received

Once the [periodic settlement cue](#41-periodic-settlement-cue) time is received the specified settlement data oracle gets monitored for incoming data. It must be possible to filter the data by the time it was received (see [0048-DSRI-data_source_internal](./0048-DSRI-data_source_internal.md#13-vega-time-changed)) at and to use the time provided by the settlement cue as a variable in such filter. If the periodic settlement data received satisfies all the filters that have been specified for it then that data point (`y`) along with the current `mark_price` (`x`) for the market and the current `vegaprotocol.builtin.timestamp` (`t`) gets stored as the funding rate data point.

### 4.3 Mark to market settlement

Every time a [mark to market settlement](./0003-MTMK-mark_to_market_settlement.md) is carried out the value of the last periodic settlement data point received along the mark price used for MTM settlement and the current `vegaprotocol.builtin.timestamp` gets stored as the funding rate data point. If no periodic settlement data has been received yet then the funding rate data point should not be created.

### 4.4 Periodic settlement

When the `settlement_schedule` event is received additional funding data point gets stored using the last received periodic settlement cue, current `mark_price` and the current `vegaprotocol.builtin.timestamp`.

The next step is to calculate the periodic settlement funding rate. If there are no periodic settlement data points then the periodic settlement is skipped. Otherwise, consider all the periodic settlement data points and calculate the time-weighted average price difference as:

```go
sd := 0
st := 0
for i := 0; i < len(data_points) - 1; i++ {
    t := data_points[i+1].t-data_points[i].t
    d := data_points[i].x - data_points[i].y
    sd += d * t
    st += t
}
funding_rate = sd / st
```

All the funding rate data points except for the last one (it should get carried over as the first data point for the next period) can then be deleted.

Last step is to calculate each party's cash flows as $-\text{open volume} * \text{funding rate}$ where cashflows are first collected from parties that are making the payment (negative value of the cashflow, i.e. longs when the funding rate is positive) and distributed to those receiving it. Any shortfall should be made-up from the insurance pool and if that's not possible loss socialisation should be applied (exactly as per mark-to-market settlement methodology).

### 4.4.1 Periodic settlement during [auction](0026-AUCT-auctions.md)

Periodic settlement is not allowed during the opening auction and it's extensions.
If periodic settlement data happens whilst market is in auction of any other type then periodic settlement should be carried out as per above methodology and the market should remain in auction until it's allowed to move back into market's default trading mode.

### 4.5 Protective auctions

In additional to protective auctions available for any market on Vega this product has protective auctions that are specific to it.

### 4.5.1 `max_settlement_schedule_gap` breached

If the amount of time since last receipt of an event from the `settlement_schedule` oracle  exceeds `max_settlement_schedule_gap` set for the market then the market goes into auction mode and remains in it until new `settlement_schedule` event is received. The process resumes as per the opening auction uncrossing once data is received (which may first require a governance vote changing the oracle for the market).
The timer should be started when market leaves the opening auction and reset each time a valid event from `settlement_schedule` oracle is received.

### 4.5.2 `max_settlement_data_gap` breached

Likewise, of the amount of time since last receipt of a valid event from the `settlement_data` oracle exceeds `max_settlement_data_gap` set for the market then the market goes into auction mode and remains in it until a valid `settlement_data` event is received. No further periodic settlements are carried out even if `settlement_schedule` events get received, the process resumes as per the opening auction uncrossing once data is received (which may first require a governance vote changing the oracle for the market).
The timer should be started when market leaves the opening auction and reset each time a valid event from `settlement_data` oracle is received.

Note that there are two separate timers, one for `max_settlement_schedule_gap` and one for  `max_settlement_data_gap`.

### API considerations

It should be possible to query the market for the list of current funding rate data points as well as history of calculated funding rate values.

## Acceptance Criteria

1. Create a Cash Settled Perpetual Future with the settlement data provided by an external data source. (<a name="0053-COSMICELEVATOR-001" href="#0053-COSMICELEVATOR-001">0053-COSMICELEVATOR-001</a>)
1. Create a Cash Settled Perpetual Future for any settlement asset that's configured in Vega. (<a name="0053-COSMICELEVATOR-002" href="#0053-COSMICELEVATOR-002">0053-COSMICELEVATOR-002</a>)
1. Any of the data sources used by the product can be changed via governance. (<a name="0053-COSMICELEVATOR-003" href="#0053-COSMICELEVATOR-003">0053-COSMICELEVATOR-003</a>)
1. It is not possible to change settlement asset via governance. (<a name="0053-COSMICELEVATOR-004" href="#0053-COSMICELEVATOR-004">0053-COSMICELEVATOR-004</a>)
1. [Mark to market settlement](./0003-MTMK-mark_to_market_settlement.md) works correctly with a predefined frequency irrespective of periodic settlement driven by the oracle data. (<a name="0053-COSMICELEVATOR-005" href="#0053-COSMICELEVATOR-005">0053-COSMICELEVATOR-005</a>)
1. Receiving an event from the `settlement_schedule` oracle during the opening auction does not cause settlement. (<a name="0053-COSMICELEVATOR-006" href="#0053-COSMICELEVATOR-006">0053-COSMICELEVATOR-006</a>)
1. Receiving correctly formatted data from the settlement cue, settlement data oracles and `settlement_schedule` oracles during continuous trading results in periodic settlement. (<a name="0053-COSMICELEVATOR-007" href="#0053-COSMICELEVATOR-007">0053-COSMICELEVATOR-007</a>)
1. Receiving correctly formatted data from the settlement cue, settlement data and `settlement_schedule` oracles during liquidity monitoring auction results in the exchange of periodic settlement cashflows. Market remains in liquidity monitoring auction until enough additional liquidity gets committed to the market. (<a name="0053-COSMICELEVATOR-008" href="#0053-COSMICELEVATOR-008">0053-COSMICELEVATOR-008</a>)
1. Receiving correctly formatted data from the settlement cue, settlement data and `settlement_schedule` oracles during price monitoring auction results in the exchange of periodic settlement cashflows. Market remains in price monitoring auction until its original duration elapses, uncrosses the auction and goes back to continuous trading mode. (<a name="0053-COSMICELEVATOR-009" href="#0053-COSMICELEVATOR-009">0053-COSMICELEVATOR-009</a>)
1. Once the `max_settlement_schedule_gap` gets exceeded the market goes into auction with no fixed duration. It is possible to change the settlement schedule oracle during that auction and once the new data is received periodic settlement is carried out and the market goes out of auction (assuming `max_settlement_data_gap` was not triggered in the interim)  (<a name="0053-COSMICELEVATOR-012" href="#0053-COSMICELEVATOR-012">0053-COSMICELEVATOR-012</a>)
1. Once the `max_settlement_data_gap` gets exceeded the market goes into auction with no fixed duration. It is possible to change the settlement cue and settlement data oracles during that auction and once the new, correctly formatted, data from both oracles is received periodic settlement is carried out and the market goes out of auction (assuming `max_settlement_schedule_gap` was not triggered in the interim) (<a name="0053-COSMICELEVATOR-013" href="#0053-COSMICELEVATOR-013">0053-COSMICELEVATOR-013</a>)
1. Once the `max_settlement_data_gap` gets exceeded the market goes into auction with no fixed duration. It is possible to change the settlement cue and settlement data oracles during that auction. Before the arrival of correctly formatted data from the settlement cue and settlement data oracles `max_settlement_schedule_gap` gets triggered. Market only out of auction once correctly formatted data from all 3 oracles (in any valid order) arrives. (<a name="0053-COSMICELEVATOR-014" href="#0053-COSMICELEVATOR-014">0053-COSMICELEVATOR-014</a>)
1. Receiving correctly formatted data from the settlement cue and settlement data oracles, but at time that violates the `vegaprotocol.builtin.timestamp` filter of the settlement data oracle does NOT result in periodic settlement. The market remains in auction mode for the entire `settlement_cue_auction_duration`, uncrosses, returns to continuous trading and does not attempt another periodic settlement until the next data is received by the settlement cue oracle (<a name="0053-COSMICELEVATOR-015" href="#0053-COSMICELEVATOR-015">0053-COSMICELEVATOR-015</a>)

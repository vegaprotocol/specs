# Built-in [Product](./0051-PROD-product.md): Cash Settled Perpetual Futures

This built-in product provides perpetual futures contracts that are cash-settled, i.e. they are margined and settled in a single asset, and they never expire.

Background reading: [1](https://www.paradigm.xyz/2021/05/everlasting-options/#Perpetual_Futures), [2](https://arxiv.org/pdf/2212.06888.pdf).

Perpetual futures are a simple "delta one" product. Mark-to-market settlement occurs with a predefined frequency as per [0003-MTMK-mark_to_market_settlement](0003-MTMK-mark_to_market_settlement.md). Additionally, a settlement using external data is carried out whenever `settlement_schedule` is triggered. Data obtained from the `settlement_data` oracle between two consecutive `settlement_schedule` events is used to calculate the funding payment and exchange cashflows between parties with open positions in the market.

Unlike traditional futures contracts, the perpetual futures never expire. Without the settlement at expiry there would be nothing in the fixed-expiry futures to tether the contract price to the underlying spot market it's based on. To assure that the perpetuals market tracks the underlying spot market sufficiently well a periodic cashflow is exchanged based on the relative prices in the two markets. Such payment covering the time period $t_{i-1}$ to $t_i$ takes the basic form $G_i = \frac{1}{t_i-t_{i-1}} \int_{t_{i-1}}^{t_i}(F_u-S_u)du$, where $F_u$ and $S_u$ are respectively: the perpetual futures price and the spot price at time $u$. We choose to use the mark price to approximate $F_u$ and oracle to approximate $S_u$, so this is effectively the difference between the time-weighted average prices (TWAP) of the two. An optional interest rate and clamp function are included in the funding rate calculation, see the [funding payment calculation](#funding-payment-calculation) section for details.

## 1. Product parameters

1. `settlement_asset (Settlement Asset)`: this is used to specify the single asset that an instrument using this product settles in.
1. `settlement_schedule (Data Source: datetime)`: this data is used to indicate when the next periodic settlement should be carried out.
1. `settlement_data (Data Source: number)`: this data is used by the product to calculate periodic settlement cashflows.
1. `margin_funding_factor`: a parameter controlling how much the upcoming funding payment liability contributes to party's margin.
1. `interest_rate`: a continuously compounded interest rate used in funding rate calculation.
1. `clamp_lower_bound`: a lower bound for the clamp function used as part of the funding rate calculation.
1. `clamp_upper_bound`: an upper bound for the clamp function used as part of the funding rate calculation.

Validation:

- `margin_funding_factor` in range `[0,1]`,
- `interest_rate` in range `[-1,1]`,
- `clamp_lower_bound` in range `[-1,1]`,
- `clamp_upper_bound` in range `[-1,1]`,
- `clamp_upper_bound` >= `clamp_lower_bound`.

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
       settlement_data:
            data_source: SignedMessage{ pubkey=0xA45e...d6 }
            filters:
                - 'timestamp': >= vegaprotocol.builtin.timestamp
                - 'timestamp': <= vegaprotocol.builtin.timestamp + "10s"
                - 'ticker': 'TSLA'
            price:
                field: 'price'
            timestamp:
                field: 'timestamp'
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

No data relating to periodic settlement gets stored by the market prior to a successful uncrossing of the opening auction. Once the auction uncrosses an internal `funding_period_start` field gets populated with the current vega time (`vegaprotocol.builtin.timestamp`)

### 4.1. Periodic settlement data point received

If the periodic settlement data received satisfies all the filters that have been specified for it then a data point containing price (`s`) along with timestamp (`t`) gets stored as the oracle data point within the market. Note that both the price and timestamp should come from the same oracle. The implementation has to allow specifying the following types of timestamps:

- a field on the oracle payload,
- a timestamp from the oracle's blockchain,
- an internal vega time.

### 4.2. Mark to market settlement

Every time a [mark to market settlement](./0003-MTMK-mark_to_market_settlement.md) is carried out the value of mark price (`f`) and the current `vegaprotocol.builtin.timestamp` gets stored as an internal data point within the market.

### 4.3. Periodic settlement

When the `settlement_schedule` event is received we need to calculate the funding payment. Store the current vega time as `funding_period_end`.

The following conditions must all be met for a funding payment within a given funding period to happen:

- there is at least on one oracle data point with timestamp greater than or requal to `funding_period_start` and less than `funding_period_end`,
- there is at least internal data point with timestamp greater than or requal to `funding_period_start` and less than `funding_period_end`.
Otherwise the payment is skipped and the next funding period is entered.

Please refer to the following subsections for the details of calculation of the funding payment if both of the above conditions are met.

#### TWAP calculation

Same methodology applies to spot (external) and perps (internal prices). The available prices (spot and perps considered separately of course) should be used to calculate the time weighted average price within the funding period. If no observations at or prior to the funding period start exist then the start of the period used for calculation should be moved forward to the time of the first observation. An observation is assumed to be applying until a subsequent observation is available. Periods spent in auction should be excluded from the calculation.

#### Funding payment calculation

The next step is to calculate the periodic settlement funding payment. We allow the optional interest rate and clamp component, where $\text{clamp}(a,b;x)=min(b,max(a, x))$. The funding payment then takes the form:

```go
delta_t = funding_period_end - max(funding_period_start, internal_data_points[0].t)
funding_payment = f_twap - s_twap + min(clamp_upper_bound*s_twap,max(clamp_lower_bound*s_twap, (1 + delta_t * interest_rate)*s_twap-f_twap))
```

where `(1 + delta_t * interest_rate)` is the linearisation of  `exp(delta_t*interest_rate)` and `delta_t` is expressed as a year fraction.

#### Funding rate calculation

While not needed for calculation of cashflows to be exchanged by market participants, the funding rate is useful for tracking market's relation to the underlying spot market over time.

Funding rate should be calculated as:

```go
funding_rate = (f_twap - s_twap) / s_twap
```

and emitted as an event.

#### Exchanging funding payments between parties

Last step is to calculate each party's cash flows as $-\text{open volume} * \text{funding payment}$ where cashflows are first collected from parties that are making the payment (negative value of the cashflow, i.e. longs when the funding payment is positive) and distributed to those receiving it. Any shortfall should be made-up from the market's insurance pool and if that's not possible loss socialisation should be applied (exactly as per mark-to-market settlement methodology).

### 4.3.1. Periodic settlement during [auction](0026-AUCT-auctions.md)

Periodic settlement is not allowed during the opening auction and it's extensions.
If periodic settlement data happens whilst market is in auction of any other type then periodic settlement should be carried out as per above methodology and the market should remain in auction until it's allowed to move back into market's default trading mode.

### 5. Margin considerations

To assure adequate solvency we need to include the estimate of the upcoming funding payment in maintenance margin estimate for the party. Let $t_{k-1}$ be the time of the last funding payment. Let $t$ be current time ($t < t_k$).
Calculate $G_t$ as the [funding payment](#43-periodic-settlement) between $t_{k-1}$ and $t$, and consider open volume of the party for which the margin is being calculated.
For perpetual futures markets set the maintenance margin as:

```math
m^{\text{maint (perps)}}_t = m^{\text{maint}}_t + \text{margin funding factor} \cdot \max(0, \text{open volume}\ cdot G_t),
```

where $m^{\text{maint}}_t$ is the current maintenance margin as per the [margin spec](./0019-MCAL-margin_calculator.md)

### 6. Market closure

Should a perpetual futures market get closed using the [governance proposal](./0028-GOVE-governance.md#61-move-market-to-a-closed-state) an final funding payment should be calculated using the data available at that time and exchanged right before the final settlement using the price contained in the proposal is carried out.

### API considerations

For every completed funding period the following data should be emitted:

- funding period start time,
- funding period end time,
- funding rate,
- funding payment,
- external (spot) price TWAP,
- internal (mark) price TWAP.

Furthermore, within the ongoing funding period the following data should be emitted at least every time the mark price is updated:

- funding period start time,
- estimate time,
- funding rate estimate,
- funding payment estimate,
- external (spot) price TWAP to-date,
- internal (mark) price TWAP to-date.

 The estimates are obtained assuming the current period ended now. The time for which the estimate was obtained is recorded as `estimate time`.
 Please note that the above estimates calculated within the ongoing funding period should be available internally for inclusion in the margin calculation as outlined in the [margin considerations](#5-margin-considerations) subsection as well as on the data-node. Only the most recent observation should be kept in both these places.

In both cases the estimates are for a hypothetical position of size 1.

## Acceptance Criteria

1. Create a Cash Settled Perpetual Future with the settlement data provided by an external data source. (<a name="0053-PERP-001" href="#0053-PERP-001">0053-PERP-001</a>)
1. Create a Cash Settled Perpetual Future for any settlement asset that's configured in Vega. (<a name="0053-PERP-002" href="#0053-PERP-002">0053-PERP-002</a>)
1. Any of the data sources used by the product can be changed via governance. (<a name="0053-PERP-003" href="#0053-PERP-003">0053-PERP-003</a>)
1. It is not possible to change settlement asset via governance. (<a name="0053-PERP-004" href="#0053-PERP-004">0053-PERP-004</a>)
1. [Mark to market settlement](./0003-MTMK-mark_to_market_settlement.md) works correctly with a predefined frequency irrespective of the behaviour of any of the oracles specified for the market. (<a name="0053-PERP-005" href="#0053-PERP-005">0053-PERP-005</a>)
1. Receiving an event from the settlement schedule oracle during the opening auction does not cause settlement. (<a name="0053-PERP-006" href="#0053-PERP-006">0053-PERP-006</a>)
1. Receiving correctly formatted data from settlement data oracles and settlement schedule oracles during continuous trading results in periodic settlement. (<a name="0053-PERP-007" href="#0053-PERP-007">0053-PERP-007</a>)
1. Receiving correctly formatted data from the settlement data and settlement schedule oracles during liquidity monitoring auction results in the exchange of periodic settlement cashflows. Market remains in liquidity monitoring auction until enough additional liquidity gets committed to the market. (<a name="0053-PERP-008" href="#0053-PERP-008">0053-PERP-008</a>)
1. Receiving correctly formatted data from the settlement data and settlement schedule oracles during price monitoring auction results in the exchange of periodic settlement cashflows. Market remains in price monitoring auction until its original duration elapses, uncrosses the auction and goes back to continuous trading mode. (<a name="0053-PERP-009" href="#0053-PERP-009">0053-PERP-009</a>)
1. When the funding payment is positive the margin levels of parties with long positions are larger than what the basic margin calculations imply. Parties with short positions are not impacted. (<a name="0053-PERP-015" href="#0053-PERP-015">0053-PERP-015</a>)
1. When the funding payment is negative the margin levels of parties with short positions are larger than what the basic margin calculations imply. Parties with long positions are not impacted. (<a name="0053-PERP-016" href="#0053-PERP-016">0053-PERP-016</a>)
1. An event containing funding rate should be emitted each time the funding payment is calculated (<a name="0053-PERP-017" href="#0053-PERP-017">0053-PERP-017</a>)
1. No data relating to funding payment is available until the perpetual futures market leaves the opening auction. (<a name="0053-PERP-018" href="#0053-PERP-018">0053-PERP-018</a>)
1. For the ongoing period the following data is available via the API: funding period start time, estimate time, funding rate estimate, funding payment estimate, external (spot) price TWAP to-date, internal (mark) price TWAP to-date. (<a name="0053-PERP-019" href="#0053-PERP-019">0053-PERP-019</a>)
1. For each of the fully completed past funding periods the following data is available (subject to data-node's retention settings): funding period start time, funding period end time, funding rate, funding payment, external (spot) price TWAP, internal (mark) price TWAP. (<a name="0053-PERP-020" href="#0053-PERP-020">0053-PERP-020</a>)
1. A perpetual market which is active and has open orders, continues to function after protocol upgrade, and preserves all market settings and statistics. (<a name="0053-PERP-021" href="#0053-PERP-021">0053-PERP-021</a>)
1. A perpetual market which is active and has open orders, after checkpoint restart, is in opening auction. All margin accounts are transferred to general accounts. (<a name="0053-PERP-022" href="#0053-PERP-022">0053-PERP-022</a>)
1. A perpetual market which is active and has open orders. Wait for a new network history snapshot to be created. Load a new data node from network history. All market data is preserved. (<a name="0053-PERP-023" href="#0053-PERP-023">0053-PERP-023</a>)
1. When the funding payment does not coincide with mark to market settlement time, a party has insufficient funds to fully cover their funding payment such that the shortfall amount if $x$ and the balance of market's insurance pool is $\frac{x}{3}$, then the entire insurance pool balance gets used to cover the shortfall and the remaining missing amount $\frac{2x}{3}$ gets dealt with using loss socialisation. (<a name="0053-PERP-024" href="#0053-PERP-024">0053-PERP-024</a>)

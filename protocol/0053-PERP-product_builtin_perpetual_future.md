# Built-in [Product](./0051-PROD-product.md): Cash Settled Perpetual Futures

This built-in product provides perpetual futures contracts that are cash-settled, i.e. they are margined and settled in a single asset, and they never expire.

Background reading: [1](https://www.paradigm.xyz/2021/05/everlasting-options/#Perpetual_Futures), [2](https://arxiv.org/pdf/2212.06888.pdf).

Perpetual futures are a simple "delta one" product. Mark-to-market settlement occurs with a predefined frequency as per [0003-MTMK-mark_to_market_settlement](0003-MTMK-mark_to_market_settlement.md). Additionally, a settlement using external data (funding payment) is carried out whenever `settlement_schedule` is triggered. Data obtained from the `settlement_data` oracle between two consecutive `settlement_schedule` events is used to calculate the funding payment and exchange cashflows between parties with open positions in the market.

Unlike traditional futures contracts, the perpetual futures never expire. Without the settlement at expiry there would be nothing in the fixed-expiry futures to tether the contract price to the underlying spot market it's based on. To assure that the perpetuals market tracks the underlying spot market sufficiently well a periodic cashflow is exchanged based on the relative prices in the two markets. Such payment covering the time period $t_{i-1}$ to $t_i$ takes the basic form $G_i = \frac{1}{t_i-t_{i-1}} \int_{t_{i-1}}^{t_i}(F_u-S_u)du$, where $F_u$ and $S_u$ are respectively: the perpetual futures price and the spot price at time $u$.
We choose to use either:

- the mark price of the market to approximate $F_u$ or
- configure the "market price for funding purposes" as part of the market proposal and use this methodology to approximate $F_u$ and  oracle to approximate $S_u$, so this is effectively the difference between the time-weighted average prices (TWAP) of the two. An optional interest rate and clamp function are included in the funding rate calculation, see the [funding payment calculation](#funding-payment-calculation) section for details.

## 1. Product parameters

1. `settlement_asset (Settlement Asset)`: this is used to specify the single asset that an instrument using this product settles in.
1. `settlement_schedule (Data Source: datetime)`: this data is used to indicate when the next periodic settlement should be carried out.
1. `settlement_data (Data Source: number)`: this data is used by the product to calculate periodic settlement cashflows.
1. `margin_funding_factor`: a parameter controlling how much the upcoming funding payment liability contributes to party's margin.
1. `interest_rate`: a continuously compounded interest rate used in funding rate calculation.
1. `clamp_lower_bound`: a lower bound for the clamp function used as part of the funding rate calculation.
1. `clamp_upper_bound`: an upper bound for the clamp function used as part of the funding rate calculation.
1. `scaling_factor`: optional scaling factor applied to funding payment.
1. `rate_lower_bound`: optional lower bound applied to funding payment such that the resulting funding rate will never be lower than the specified value.
1. `rate_upper_bound`: optional upper bound applied to funding payment such that the resulting funding rate will never be greater than than the specified value.

Validation:

- `margin_funding_factor` in range `[0,1]`,
- `interest_rate` in range `[-1,1]`,
- `clamp_lower_bound` in range `[-1,1]`,
- `clamp_upper_bound` in range `[-1,1]`,
- `scaling_factor` any positive real number,
- `rate_lower_bound` any real number,
- `rate_upper_bound` any real number,
- `clamp_upper_bound` >= `clamp_lower_bound`,
- `rate_upper_bound` >= `rate_lower_bound`.

When migrating legacy markets the following value should be used:

- `scaling_factor` = `1.0`,
- `rate_lower_bound` = -`max supported value`,
- `rate_upper_bound` = `max supported value`.

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

Skip the funding payment calculation (set payment to `0`) if no spot (external) data has been ingested since market was create, otherwise calculate the funding payment as outlined below.

#### TWAP calculation

Same methodology applies to spot (external) and perps (internal). The available prices (spot and perps considered separately of course) should be used to calculate the time weighted average price within the funding period. If no observations at or prior to the funding period start exist then the start of the period used for calculation should be moved forward to the time of the first observation. An observation is assumed to be applying until a subsequent observation is available. Periods spent in auction should be excluded from the calculation. This implies that spot datapoints received during the auction except for the latest one should be disregarded. Please refer to the acceptance criteria for a detailed example.

Calculation of the TWAP is carried out by maintaining the following variables: `numerator`, `denominator`, `previous_price` and `previous_time`. It's also assumed that a function `current_time()` is available which returns the current Vega time, and a function `in_auction()` exists which returns `true` if the market being considered is currently in auction and `false` otherwise.
The variables are maintained as follows.

When a new `price` observation arrives:

```go
if previous_price != nil && in_auction() {
    time_delta = current_time()-previous_time
    numerator += previous_price*time_delta
    denominator += time_delta
}
previous_price = price
previous_time = current_time()
```

When the market goes into auction:

```go
time_delta = current_time()-previous_time
numerator += previous_price*time_delta
denominator += time_delta
```

When the market goes out of auction:

```go
previous_time = current_time()
```

When the funding payment cue arrives TWAP gets calculated and returned as:

```go
if !in_auction() {
    time_delta = current_time()-previous_time
    numerator += previous_price*time_delta
    denominator += time_delta
}
previous_time = current_time
if denominator == 0 {
    return 0
}
return numerator / denominator

```

Note that depending on what type of oracle is used for the spot price it may be that the oracle points only become known shortly before or at the funding payment cue time, so the above pseudocode is just an illustration of how these quantities should be calculated and the implementation will need to be able to apply such calculation retrospectively.

#### Funding payment calculation

The next step is to calculate the periodic settlement funding payment. We allow the optional interest rate and clamp component, where $\text{clamp}(a,b;x)=min(b,max(a, x))$. The funding payment then takes the form:

```go
delta_t = funding_period_end - max(funding_period_start, internal_data_points[0].t)
funding_payment = f_twap - s_twap + min(clamp_upper_bound*s_twap,max(clamp_lower_bound*s_twap, (1 + delta_t * interest_rate)*s_twap-f_twap))
```

where `(1 + delta_t * interest_rate)` is the linearisation of  `exp(delta_t*interest_rate)` and `delta_t` is expressed as a year fraction.

Furthermore, if any time was spent in auction during the funding period then the funding payment should be scaled down by the fraction of the period spent outside of auction:

`period_duration = period_end - period_start`

```go
funding_payment = (period_duration-time_spent_in_auction)/period_duration * funding_payment
```

Please note that this implies no funding payments for periods during which the market has been in auction for their entire duration.

If `scaling_factor` is specified set:

```go
funding_payment = scaling_factor * funding_payment
```

If `rate_lower_bound` is specified set:

```go
funding_payment = max(rate_lower_bound*s_twap, funding_payment)
```

If `rate_upper_bound` is specified set:

```go
funding_payment = min(rate_upper_bound*s_twap, funding_payment)
```

Please note that scaling should happen strictly before any of the bounds are applied, i.e. if all 3 parameters are specified then the resulting funding rate is guaranteed to fall within the specified bounds irrespective of how big the scaling factor may be.

#### Funding rate calculation

While not needed for calculation of cashflows to be exchanged by market participants, the funding rate is useful for tracking market's relation to the underlying spot market over time.

Funding rate should be calculated as:

```go
funding_rate = funding_payment / s_twap
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

1. Assume a market trades steadily generating a stream in mark price observations, but the first spot price observation only arrives during the 4th funding period of that market. Then funding payments for periods 1, 2 and 3 all equal 0. (<a name="0053-PERP-025" href="#0053-PERP-025">0053-PERP-025</a>)

1. Assume the market has been in a long auction so that a funding period has started and ended while the market never went back into continuous trading. In that case the funding payment should be equal to 0 and no transfers should be exchanged. (<a name="0053-PERP-026" href="#0053-PERP-026">0053-PERP-026</a>)

1. Assume a 10 minute funding period. Assume a few funding periods have already passed for this market.

Assume the last known mark price before the start of the period to be `10` and that it gets updated every 2 minutes as follows:
| Time (min) since period start | mark price  |
| ----------------------------- | ----------- |
| 1                             | 11          |
| 3                             | 10          |
| 5                             | 9           |
| 7                             | 8           |
| 9                             | 7           |

Assume the last known spot price before this funding period is `11`. Then assume the subsequent spot price observations get ingested according to the schedule specified below:
| Time (min) since period start | spot price  |
| ----------------------------- | ----------- |
| 1                             | 9           |
| 3                             | 10          |
| 5                             | 12          |
| 6                             | 11          |
| 7                             | 8           |
| 9                             | 14          |

Then, assuming no auctions during the period we get:
$\text{internal TWAP}= \frac{10\cdot(1-0)+11\cdot(3-1)+10\cdot(5-3)+9\cdot(7-5)+8\cdot(9-7)+7\cdot(10-9)}{10}=9.3$,
$\text{external TWAP}=\frac{11\cdot(1-0)+9\cdot(3-1)+10\cdot(5-3)+12\cdot(6-5)+11\cdot(7-6)+8\cdot(9-7)+14\cdot(10-9)}{10}=10.2$. (<a name="0053-PERP-027" href="#0053-PERP-027">0053-PERP-027</a>)

1. Assume a 10 minute funding period. Assume a few funding periods have already passed for this market. Furthermore, assume that in this period that market is in an auction which starts 5 minutes into the period and ends 7 minutes into the period. Assume `interest_rate`=`clamp_lower_bound`=`clamp_upper_bound`=`0`, `scaling_factor`=`1` and no rate upper or lower bound.

Assume the last known mark price before the start of the period to be `10` and that it gets updated as follows:
| Time (min) since period start | mark price  |
| ----------------------------- | ----------- |
| 1                             | 11          |
| 3                             | 11          |
| 7                             | 9           |
| 8                             | 8           |
| 10                            | 30          |

Assume the last known spot price before this funding period is `11`. Then assume the subsequent spot price observations get ingested according to the schedule specified below:
| Time (min) since period start | spot price  |
| ----------------------------- | ----------- |
| 1                             | 9           |
| 3                             | 10          |
| 5                             | 30          |
| 6                             | 11          |
| 8                             | 8           |
| 9                             | 14          |

Then, taking the auction into account we get:
$\text{internal TWAP}=\frac{10\cdot(1-0)+11\cdot(3-1)+11\cdot(5-3)+9\cdot(8-7)+8\cdot(10-8)+30\cdot(10-10)}{8}=9.875$,
$\text{external TWAP}=\frac{11\cdot(1-0)+9\cdot(3-1)+10\cdot(5-3)+11\cdot(8-7)+8\cdot(9-8)+14\cdot(10-9)}{8}=10.25$,
$\text{funding payment}=(10-(7-5))/10 * (9.875 - 10.25) = -0.3$. (<a name="0053-PERP-036" href="#0053-PERP-036">0053-PERP-036</a>)

When $\text{clamp lower bound}=\text{clamp upper bound}=0$, $\text{scaling factor}=2.5$ and the funding period ends with $\text{internal TWAP}=99$, $\text{external TWAP} = 100$ then the resulting funding rate equals $-0.025$. (<a name="0053-PERP-029" href="#0053-PERP-029">0053-PERP-029</a>)

When $\text{clamp lower bound}=\text{clamp upper bound}=0$, $\text{scaling factor}=1$, $\text{rate lower bound}=-0.005$, $\text{rate upper bound}=0.015$ and the funding period ends with $\text{internal TWAP}=99$, $\text{external TWAP} = 100$ then the resulting funding rate equals $-0.005$. (<a name="0053-PERP-030" href="#0053-PERP-030">0053-PERP-030</a>)

When $\text{clamp lower bound}=\text{clamp upper bound}=0$, $\text{scaling factor}=1$, $\text{rate lower bound}=-0.015$, $\text{rate upper bound}=0.005$ and the funding period ends with $\text{internal TWAP}=101$, $\text{external TWAP} = 100$ then the resulting funding rate equals $0.005$. (<a name="0053-PERP-031" href="#0053-PERP-031">0053-PERP-031</a>)

When migrating the market existing prior to introduction of the additional parameters their values get set to:

- $\text{scaling factor}=1$,
- $\text{rate lower bound}= -\text{max supported value}$,
- $\text{rate upper bound}= \text{max supported value}$
(<a name="0053-PERP-032" href="#0053-PERP-032">0053-PERP-032</a>).

It is possible to create a perpetual futures market which uses the last traded price algorithm for its mark price but uses "impact volume of notional of 1000 USDT" for the purpose of calculating the TWAP of the market price for funding payments (<a name="0053-PERP-033" href="#0053-PERP-033">0053-PERP-033</a>).

It is possible to create a perpetual futures market which uses an oracle source (same as that used for funding) for the mark price determining the mark-to-market cashflows and that uses "impact volume of notional of 1000 USDT" for the purpose of calculating the TWAP of the market price for funding payments (<a name="0053-PERP-034" href="#0053-PERP-034">0053-PERP-034</a>).

It is possible to create a perpetual futures market which uses an oracle source (same as that used for funding) for the mark price determining the mark-to-market cashflows and that uses "time-weighted trade prices in over `network.markPriceUpdateMaximumFrequency` if these have been updated within the last 30s but falls back onto impact volume of notional of 1000 USDT" for the purpose of calculating the TWAP of the market price for funding payments (<a name="0053-PERP-035" href="#0053-PERP-035">0053-PERP-035</a>).


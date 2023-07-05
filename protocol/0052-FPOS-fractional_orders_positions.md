# Fractional order sizes and positions

To ensure that Vega markets can be quoted in standardised units but also support a wide variety of trader types and needs, in must be possible to submit orders and therefore hold positions with fractional sizes. For example in a `BTCUSD` market one might take out a position equivalent to 0.02 BTC.

Although prior versions of the specs have not specified a data type, the initial implementation of the Vega protocol accepts only integer sized positions.

The solution to this is to:

- Introduce a new [market framework](./0001-MKTF-market_framework.md) parameter for all markets known as `Position Decimal Places` that specifies the precision allowable on that market.
- Convert at API boundaries OR instruct clients to do so by dividing outputs and multiplying inputs by `10^PDP` where PDP is the configured position decimal places for the market.
- Wherever notional sizes, margins, fees, valuations, etc. are calculated in the core, to also ensure the input quantity if divided by `10^PDP`. This may be done centrally e.g. for positions so that trading/position management are dealing with integer sizes but fees, margins, valuation calculations use the "true" position size.

Specs affected by this change (Note: in many cases the implementation may not change):

- [0001 - Market Framework](./0001-MKTF-market_framework.md)
- [0003 - Mark to mark settlement](./0003-MTMK-mark_to_market_settlement.md)
- [0019 - Margin Caculator](./0019-MCAL-margin_calculator.md)
- [0029 - Fees](./0029-FEES-fees.md)

## Acceptance Criteria

- All proposed markets will have a decimal places property available via the API (<a name="0052-FPOS-001" href="#0052-FPOS-001">0052-FPOS-001</a>) for product spot: (<a name="0052-FPOS-003" href="#0052-FPOS-003">0052-FPOS-003</a>)
- An order created on the client with a price of `1` results in an order being created with a price of `1 * 10^[Market.DecimalPlaces]` (<a name="0052-FPOS-002" href="#0052-FPOS-002">0052-FPOS-002</a>) for product spot: (<a name="0052-FPOS-004" href="#0052-FPOS-004">0052-FPOS-004</a>)
- Fees are calculated as per ([0029-FEES-013](./0029-FEES-fees.md#0029-FEES-013))
- LP order volume is implied correctly using fractional volume amounts as per ([0038-OLIQ-006](./0038-OLIQ-liquidity_provision_order_type.md#0038-OLIQ-006))
- Mark-to-market settlement happens correctly with PDP > 0 ([0003-MTMK-0015](./0003-MTMK-mark_to_market_settlement.md#0003-MTMK-015))
- Margins are correctly calculated for markets with PDP > 0 ([0019-MCAL-008](./0019-MCAL-margin_calculator.md#0019-MCAL-008)).
- Market framework reports position decimal places ([0001-MKTF-001](./0001-MKTF-market_framework.md#0001-MTMF-001)).

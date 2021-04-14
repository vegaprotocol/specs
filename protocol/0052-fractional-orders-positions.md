# Fractional order sizes and positions

To ensure that Vega markets can be quoted in standardised units but also support a wide variety of trader types and needs, in must be possible to submit orders and therefore hold positions with fractional sizes. For example in a BTCUSD market one might take out a position equivalent to 0.02 BTC.

Although prior versions of the specs have not specified a data type, the initial implementastion of the Vega protocol accepts only integer sized positions.

The solution to this is to:

* Introduce a new [market framework](./0001-market-framework.md) parameter for all markets known as `Position Decimal Places` that specifies the precision allowable on that market. 
* Convert at API boundaries OR instruct clients to do so by dividing outputs and multiplying inputs by `10^PDP` where PDP is the configured position decimal places for the market.
* Wherever notional sizes, margins, fees, valuations, etc. are calculated in the core, to also ensure the input quantity if divided by `10^PDP`. This may be done centrally e.g. for positions so that trading/position management are dealing with integer sizes but fees, margins, valuation calculations use the "true" position size.


Specs affected by this change (NB: in many cases the implementation may not change):

- [0001 - Market Framework](./0001-market-framework.md)
- [0003 - Mark to mark settlement](./0003-mark-to-market-settlement.md)
- [0004 - Amends](./00004-amends.md)
- [0006 - Positions](./0006-positions-core.md)
- [0007 - Non-core positions API](./0007-non-core-positions-api.md)
- [0019 - Margin Caculator](./0019-margin-calculator.md)
- [0021 - Market Data](./0021-market-data-spec.md)
- [0025 - Order Submission](./0025-order-submission.md)
- [0029 - Fees](./0029-fees.md)
- [0038 - Liquidity Provision order type](./0038-liquidity-provision-order-type.md)
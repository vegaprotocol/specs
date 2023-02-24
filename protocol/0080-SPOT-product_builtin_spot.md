# Built-in [Product](./0051-PROD-product.md): Spot

This built-in product provides spot contracts which allow the buying and selling of a "base" asset with a "quote" asset for immediate delivery.

When trading Spot products, parties can only use assets they own - there is no leverage or margin.

## 1. Product parameters

1. `base_asset (Asset)`: this is used to specify the asset to be purchased or sold on the market.
1. `quote_asset (Asset)`: this is used to specify the asset which can be exchanged for the base asset.

## 2. Liquidity Monitoring parameters

1. `time_window`: length of rolling window (in seconds) over which the maximum `total_stake` is measured.
1. `target_stake_factor`: fraction of `total_stake` to be selected as the `target_stake`.

## 3. Market parameters

1. `market_decimal_places` should be used to specify the number of decimal places of the `quote_asset` when specifying order price. Future specs could rename `market_decimal_places` to something more general, e.g. `price_decimal_places`.
1. `position_decimal_places` should be used to specify the number of decimal places of the `base_asset` asset when specifying order size. Future iterations of specs could rename `position_decimal_places` to something more general, e.g. `position_decimal_places`.

## 4. Liquidity Commitments

### Submissions

A liquidity provision submitted to a `Spot` market allows a separate commitment amount to be specified for the buy and sell sides of the market. These commitment amounts are specified in the `quote_asset` and `base_asset` respectively.

```psuedo
Example `LiquidityProvisionSubmission` command to an ETH/DAI market:

submission = {
    "liquidityProvisionSubmission": 
    {
        marketId: "abcdefghiklkmnopqrstuvwxyz",
        fee: "0.01",
        buyCommitmentAmount: 15000
        buys: [
            {
                offset: "1"
                proportion: "1"
                reference: "PEGGED_REFERENCE_BEST_BID"
            }
        ]
        sellCommitmentAmount: 10
        sells: [
            {
                offset: "1"
                proportion: "1"
                reference: "PEGGED_REFERENCE_BEST_ASK"
            }
        ]
        reference: "example_liquidity_provision_submission"
    }
}
```

As the LP now has a different commitment amount on each side of the book, the following considerations must be made:

- An LPs `physical_stake` should be treated separately for each side of the book - call these the `buy_physical_stake` and the `sell_physical_stake` where the current `physical_stake` is the smaller of the two values.
- An LPs `virtual_stake` should be treated separately for each side of the book - call these the `buy_virtual_stake` and `sell_virtual_stake` where the current `virtual_stake` for fee splitting is the smaller of the two values.
- An LPs `liquidity_score` should be treated separately for each side of the book - call these the `buy_liquidity_score` and the `sell_liquidity_score` where the current `liquidity_score` for fee splitting is the smaller of the two values.

From the above conditions, an LP is incentivised to provide an equal value of liquidity on each side of the book at comparable levels of competitiveness in order to maximise their share of the liquidity fees. 

It is therefore important LPs are able to freely reduce or increase their commitment amounts to ensure parity between their buy and sell commitments as the `spot_price` moves.

### Amendments and Cancellations

A liquidity amendment or cancellation is determined as valid following spec [0044-LIME](./0044-LIME-lp_mechanics.md) with the following exceptions:

- the `maximum_reduction_amount` should be expressed in the `quote_asset` when reducing the `buy_commitment_amount` and the `base_asset` when reducing the `sell_commitment_amount`.
- the `maximum_reduction_amount` should be `INF` in the case where the liquidity `time_window=Os` (Note: this is not strictly necessary but an LP is effectively able to reduce their commitment to zero anyway in this case through multiple commitments.)

```pseudo
Market Data:

    base_asset: ETH
    quote_asset: DAI

    spot_price = 1000

Market Liquidity:

    total_stake = 100,000 DAI (or 100 ETH)
    target_stake = 25,000 DAI (or 25 ETH)

    maximum_reduction_amount = 1000,000 - 25,0000 = 75,000 DAI (or 75 ETH)
```

`virtual_stake` values should be updated during liquidity amendments or cancellations following the mechanisms detailed in spec [0044-LIME](./0044-LIME-lp_mechanics.md) with the following exceptions:

- reducing the `buy_commitment_amount` only reduces the `buy_virtual_stake`
- reducing the `sell_commitment_amount` only reduces the `sell_virtual_stake`

### Liquidity Shortfalls

If at any point in time, a liquidity provider has insufficient capital in their general accounts to cover a transfer arising from a filled liquidity order, the network will utilise the liquidity commitment, held in the relevant bond account to cover the shortfall.

As there is no market insurance pool, funds from bond slashing in the result of shortfall will be transferred to the global insurance pool for that asset.

## 5. Spot Liquidity Mechanisms
### Market Total Stake

The `total_stake` for a `Spot` market is calculated simply as the sum of each LPs `physical_stake` and should be expressed in the `quote_asset` of the market.

### Market Target Stake

The target stake of a market is calculated as a fraction of the maximum `total_stake` over a rolling time window. The fraction is controlled by the parameter `consensus_factor` and the length of the window is controlled by the parameter `time_window`.

```pseudo
e.g.

Given: the following total_stake values

    [time, total_stake] = [[17:59, 12000], [18:01, 11000], [18:30, 9000], [18:59, 10000]]

If: the time value and market parameters are

    current_time = 19:00

    time_window = 3600s
    target_stake_factor = 0.25

Then: the target stake value is

    target_stake = 0.25 * 11000 = 2750 DAI
```

The above design ensures the `target_stake` of a market is unable to fluctuate dramatically over the window. Controlling the `target_stake` indirectly controls the `total_stake` as the amount an LP is able to reduce their commitment is restricted by the `maximum_reduction_amount`.

### Market Liquidity Fees

The market liquidity fee is calculated using the same mechanism defined in [0042-LIQF](./0042-LIQF-setting_fees_and_rewarding_lps.md) with the exception that an LPs `physical_stake` is the minimum of their `buy_physical_stake` and their `sell_physical_stake` where the later must be expressed in the quote_asset at the current spot_price.

The liquidity fee is re-calculated at the start of a fee distribution epoch and is fixed for that epoch (Note: this may later be applied universally to all products.)


## 7. Trading

When placing an order, the party should have a sufficient amount of the `quote` asset (for "buy" orders) or `base` asset (for "sell" orders) to cover the value of the order as well as any fees incurred from the order trading instantly. For sell orders there is no need for the party to have any `quote` asset as the fees can be subtracted from the general account for their base asset `immediately` after trading.

If the order does not immediately trade (or only trades in part) then the party will have to transfer the amount of the `quote` asset (for "buy" orders) or the `base` asset (for "sell" orders) required to cover the value of the outstanding order as well as possible fees to a `holding` account.

When an order is fulfilled or cancelled any remaining funds in the `holding` account (after the trade has been executed) can be returned to to the parties `general` account.

## 7. Auctions

As there is no margin or leverage when dealing with `Spot` products, there is no need for the supplied liquidity to exceed a threshold to exit an auction. There is therefore no need for liquidity auctions.

Price-monitoring auctions are still required and should be implemented following the [price-monitoring](./0032-PRIM-price_monitoring.md) spec.

## 8. Acceptance Criteria

1. Create a `Spot` for any `quote_asset` / `base_asset` pair that are configured in Vega (<a name="0080-COSMICELEVATOR-001" href="#0080-COSMICELEVATOR-001">0080-COSMICELEVATOR-001</a>)
1. It is not possible to change the `quote_asset` via governance (<a name="0080-COSMICELEVATOR-002" href="#0080-COSMICELEVATOR-002">0080-COSMICELEVATOR-002</a>)
1. It is not possible to change the `base_asset` via governance (<a name="0080-COSMICELEVATOR-003" href="#0080-COSMICELEVATOR-003">0080-COSMICELEVATOR-003</a>)
1. A `Spot` market can be closed through governance (<a name="0080-COSMICELEVATOR-004" href="#0080-COSMICELEVATOR-004">0080-COSMICELEVATOR-004</a>)
1. Parties are unable to place orders they do not have the necessary funds for (<a name="0080-COSMICELEVATOR-005" href="#0080-COSMICELEVATOR-005">0080-COSMICELEVATOR-005</a>)
1. Parties are unable to submit liquidity commitments they do not have the necessary funds for (<a name="0080-COSMICELEVATOR-006" href="#0080-COSMICELEVATOR-006">0080-COSMICELEVATOR-006</a>)
1. Market liquidity fees are calculated correctly (<a name="0080-COSMICELEVATOR-007" href="#0080-COSMICELEVATOR-007">0080-COSMICELEVATOR-007</a>)

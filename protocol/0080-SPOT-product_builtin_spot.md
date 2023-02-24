# Built-in [Product](./0051-PROD-product.md): Spot

This built-in product provides spot contracts which allow the buying and selling of a "base" asset with a "quote" asset for immediate delivery.

When trading Spot products, parties can only use assets they own - there is no leverage or margin.

## 1. Product parameters

1. `base_asset (Asset)`: this is used to specify the asset to be purchased or sold on the market.
1. `quote_asset (Asset)`: this is used to specify the asset which can be exchanged for the base asset.

## 1. Network Parameter

1. `spot_trading_enabled`: parameter defines whether markets using Spot products are enabled on the network.

## 2. Liquidity Monitoring parameters

1. `time_window`: length of rolling window (in seconds) over which the maximum `total_stake` is measured.
1. `target_stake_factor`: fraction of `total_stake` to be selected as the `target_stake`.

## 3. Market parameters

1. `market_decimal_places` should be used to specify the number of decimal places of the `quote_asset` when specifying order price. 

    The Cash Settled Futures spec could rename `market_decimal_places` to something more general, e.g. `price_decimal_places`.

1. `position_decimal_places` should be used to specify the number of decimal places of the `base_asset` asset when specifying order size.

    The Cash Settled Futures spec could rename `position_decimal_places` to something more general, e.g. `size_decimal_places`.

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

- An LPs `physical_stake` should be treated separately for each side of the book - call these the `buy_physical_stake` and the `sell_physical_stake` where the later is expressed in the `quote_asset` converted at the current `mark_price`. The current `physical_stake` is the smaller of the two values.
- An LPs `virtual_stake` should be treated separately for each side of the book - call these the `buy_virtual_stake` and `sell_virtual_stake`. 
- The same growth factor - as specified in the [LIQF spec](0042-LIQF-setting_fees_and_rewarding_lps.md) - derived from the `total value for fee purposes` in the quote asset is used to update both buy/sell virtual stakes (still in their respective assets).  
- The current `virtual_stake` for fee splitting is the smaller of the two values where the `sell_virtual_stake` is converted to `quote_asset` at the current `mark_price`.  
- An LPs `liquidity_score` as in [the liquidity score section of the LIQF spec](0042-LIQF-setting_fees_and_rewarding_lps.md).

From the above conditions, an LP is incentivised to provide a roughly equal value of liquidity on each side of the book at comparable levels of competitiveness in order to maximise their share of the liquidity fees. 

### Amendments and Cancellations

A liquidity amendment or a cancellation is determined as valid following spec [0044-LIME](./0044-LIME-lp_mechanics.md) with the following exceptions:

- the `maximum_reduction_amount` should be expressed in the `quote_asset` when reducing the `buy_commitment_amount` and the `base_asset` when reducing the `sell_commitment_amount`.
- the `maximum_reduction_amount` should be `INF` in the case where the liquidity `time_window=Os` (Note: this is not strictly necessary but an LP is effectively able to reduce their commitment to zero anyway in this case through multiple commitments.)

```pseudo
Market Data:

    base_asset: ETH
    quote_asset: DAI

    mark_price = 1000

Market Liquidity:

    total_stake = 100,000 DAI (or 100 ETH)
    target_stake = 25,000 DAI (or 25 ETH)

    maximum_reduction_amount = 1000,000 - 25,0000 = 75,000 DAI (or 75 ETH)
```

`virtual_stake` values should be updated during liquidity amendments or cancellations following the mechanisms detailed in spec [0044-LIME](./0044-LIME-lp_mechanics.md) with the following exceptions:

- reducing the `buy_commitment_amount` only reduces the `buy_virtual_stake`
- reducing the `sell_commitment_amount` only reduces the `sell_virtual_stake`

A single LP will never be able to reduce their commitment to `0`. They can either keep reducing to a sufficiently small amount they're willing to ignore, or they can submit a governance vote to cancel the market, see the [governance spec](). 
For market cancellation proposal a sole LP in the market holds all the voting power (unless governance token holders override them). 

### Liquidity Shortfalls

If at any point in time, a liquidity provider has insufficient capital in their general accounts to cover a transfer arising from a filled liquidity order, the network will utilise the liquidity commitment, held in the relevant bond account to cover the shortfall, applying the bond penalty factor (slashing the bond).

As there is no market insurance pool, funds from bond slashing in the result of shortfall will be transferred to the global insurance pool for that asset.

## 5. Spot Liquidity Mechanisms
### Market Total Stake

The `total_stake` for a `Spot` market is calculated simply as the sum of each LPs `physical_stake` and should be expressed in the `quote_asset` of the market.

### Market Target Stake

See spec [0041-TSTK](./0041-TSTK-target_stake.md).
### Market Liquidity Fees

The market liquidity fee is calculated using the same mechanism defined in [0042-LIQF](./0042-LIQF-setting_fees_and_rewarding_lps.md).

The liquidity fee is re-calculated at the start of a fee distribution epoch and is fixed for that epoch.
Note: 1. this may later be applied universally to all products. 2. this "fee distribution epoch" is unrelated to blockchain staking and delegation epochs.


## 6. Trading

Both buy and sell orders on a `Spot` market define an amount of the `base_asset` to buy or sell at a given price of the `quote_asset`. 
When placing an order, the party should have a sufficient amount of the `quote` asset (for "buy" orders) or `base` asset (for "sell" orders) in the general accounts for the respective assets to cover the value of the order.

For buy orders the party will also need a sufficient amount of the `quote_asset` to cover any fees incurred as if the order was to trade instantly. 
For sell orders, there is no need for the party to have any `quote_asset` as the fees will be subtracted from the resulting `quote_asset` amount due to the party as a a result from the trade. 

If the order does not immediately trade (or only trades in part) then the party will have to transfer the amount of the `quote` asset (for "buy" orders) or the `base` asset (for "sell" orders) required to cover the value of the outstanding order as well as possible fees to a `holding` accounts for the market. 

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

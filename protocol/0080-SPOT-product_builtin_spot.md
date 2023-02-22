# Built-in [Product](./0051-PROD-product.md): Spot

This built-in product provides spot contracts which allow the buying and selling of a "base" asset with a "quote" asset for immediate delivery.

When trading Spot products, parties can only use assets they own - there is no leverage or margin.

## 1. Product parameters

1. `base_asset (Asset)`: this is used to specify the asset to be purchased or sold on the market.
1. `quote_asset (Asset)`: this is used to specify the asset which can be exchanged for the base asset.

## 2. Network parameters

1. `spot_obligation_calculation_window`: time (in seconds) between recalculation of the amount of the `base_asset` which must be locked in the bond account for the `base_asset`.
1. `spot_commitment_lock_window`: time (in seconds) which a commitment is "locked" after it is submitted or amended before it can be amended or cancelled.
1. `spot_liquidity_fee_consensus`: required fraction of LPs (scaled by their commitments) to propose a liquidity fee (or lower) for it to be accepted.

## 3. Market parameters

1. `market_decimal_places` should be used to specify the number of decimal places of the `quote_asset` when specifying order price. Future specs could rename `market_decimal_places` to something more general, e.g. `price_decimal_places`.
1. `position_decimal_places` should be used to specify the number of decimal places of the `base_asset` asset when specifying order size. Future iterations of specs could rename `position_decimal_places` to something more general, e.g. `position_decimal_places`.

## 4. Liquidity Commitments

A Liquidity Provision submitted to a market must commit liquidity on both sides of the book in a single commitment. The LP can specify a separate commitment amount for the buy side and sell side of the market. These commitment amounts are specified in the `quote_asset` and `base_asset` respectively.

```psuedo
Example `LiquidityProvisionSubmission` command to an ETH/DAI market:

submission = {
    "liquidityProvisionSubmission": 
    {
        marketId: "abcdefghik1lkmopqrstuvwxyz",
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

- An LPs `virtual_stake` should be treated separately for each side of the book - call these the `buy_virtual_stake` and `sell_virtual_stake` where the current `virtual_stake` for fee splitting is the smaller of the two values.
- An LPs `liquidity_score` should be treated separately for each side of the book - call these the `buy_liquidity_score` and the `sell_liquidity_score` where the current `liquidity_score` for fee splitting is the smaller of the two values.

The above conditions will incentivise LPs to provide an equal value of liquidity to both sides of the book at comparable levels of competitiveness.

To prevent LPs frequently reducing or cancelling liquidity commitments; liquidity cancellations or amendments which reduce the committed amount will not be enacted until the end of the current trading window. Liquidity amendments which increase the commitment amount or amend the liquidity shape will be allowed and enacted instantly.

## 5. Liquidity Shortfalls

If at any point in time, a liquidity provider has insufficient capital in their general accounts to cover a transfer arising from a filled liquidity order, the network will utilise the liquidity commitment, held in the relevant bond account to cover the shortfall.

As there is no market insurance pool, funds from bond slashing in the result of shortfall will be transferred to the global insurance pool for that asset.

## 6. Liquidity Fees

As there is no margin or leverage when dealing with `Spot` products there is no need for a certain level of liquidity to ensure distressed parties can be closed out. There is therefore no need to calculate `target_stake`.

In the absence of a `target_stake` value, the liquidity fee should be determined as the lowest possible fee that a fraction of the committed LPs propose (controlled by the network parameter `spot_liquidity_fee_consensus`).

An LPs influence in the "vote" is weighted by their current equity_like_share and liquidity_score.

```psuedo
Example 1:

spot_liquidity_fee_consensus = 0.49

LP1, equity_like_share=0.50 and liquidity_score=0.50, commits @ fee = 0.01
LP2, equity_like_share=0.25 and liquidity_score=0.25, commits @ fee = 0.02
LP3, equity_like_share=0.25 and liquidity_score=0.25, commits @ fee = 0.03

liquidity_fee_factor = 0.01
```

```psuedo
Example 2:

spot_liquidity_fee_consensus = 0.51

LP1, equity_like_share=0.50 and liquidity_score=0.50, commits @ fee = 0.01
LP2, equity_like_share=0.25 and liquidity_score=0.25, commits @ fee = 0.02
LP3, equity_like_share=0.25 and liquidity_score=0.25, commits @ fee = 0.03

liquidity_fee_factor = 0.02
```

To stabilise liquidity fees, liquidity fees are calculated using LPs `equity_like_share` and `liquidity_score` values at the end of the last window. The fee is then locked for the duration of the next window.

## 7. Trading

When placing an order, the party should have a sufficient amount of the `quote` asset (for "buy" orders) or `base` asset (for "sell" orders) to cover the value of the order as well as any fees incurred from the order trading instantly.

If the order does not immediately trade (or only trades in part) then the party will have to transfer the amount of the `quote` asset (for "buy" orders) or the `base` asset (for "sell" orders) required to cover the value of the outstanding order as well as possible fees to a `holding` account.

When an order is fulfilled or cancelled any remaining funds in the `holding` account (after the trade has been executed) can be returned to to the parties `general` account.

## 7. Auctions

As there is no margin or leverage when dealing with `Spot` products, there is no need for the supplied liquidity to exceed a threshold to exit an auction. There is therefore no need for liquidity auctions.

Price-monitoring auctions are still required and should be implemented following the [price-monitoring](./0032-PRIM-price_monitoring.md) spec.

## 8. Acceptance Criteria

1. Create a `Spot` for any `quote_asset` / `base_asset` pair that are configured in Vega (<a name="0080-COSMICELEVATOR-001" href="#0080-COSMICELEVATOR-001">0080-COSMICELEVATOR-001</a>)
1. It is not possible to change the `quote_asset` via governance (<a name="0080-COSMICELEVATOR-002" href="#0080-COSMICELEVATOR-002">0080-COSMICELEVATOR-002</a>)
1. It is not possible to change the `base_asset` via governance (<a name="0080-COSMICELEVATOR-003" href="#0080-COSMICELEVATOR-003">0080-COSMICELEVATOR-003</a>)
1. A `Spot` market can be terminated through governance (<a name="0080-COSMICELEVATOR-004" href="#0080-COSMICELEVATOR-004">0080-COSMICELEVATOR-004</a>)
1. Parties are unable to place orders they do not have the necessary funds for (<a name="0080-COSMICELEVATOR-005" href="#0080-COSMICELEVATOR-005">0080-COSMICELEVATOR-005</a>)
1. Parties are unable to submit liquidity commitments they do not have the necessary funds for (<a name="0080-COSMICELEVATOR-006" href="#0080-COSMICELEVATOR-006">0080-COSMICELEVATOR-006</a>)
1. Market liquidity fees are calculated correctly (<a name="0080-COSMICELEVATOR-007" href="#0080-COSMICELEVATOR-007">0080-COSMICELEVATOR-007</a>)

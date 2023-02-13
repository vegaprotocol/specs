# Built-in [Product](./0051-PROD-product.md): Spot

This built-in product provides spot contracts which allow the buying and selling of a "base" asset with a "quote" asset for immediate delivery.

When trading Spot products, parties can only use assets they own - there is no leverage or margin.

## 1. Product parameters

1. `base_quote_pair (Explicit Value)`: human readable name/abbreviation of the base/quote pair.
1. `base_asset (Asset)`: this is used to specify the asset to be purchased or sold on the market.
1. `quote_asset (Asset)`: this is used to specify the asset which can be exchanged for the base asset.
1. `trading_termination_trigger (Data Source)`: triggers the market to move to `trading terminated` status. This trigger may be a datetime trigger or an oracle. Note: a `Spot` market may also be terminated through governance.

## 2. Network parameters

1. `spot_obligation_calculation_window`: time (in seconds) between recalculation of the amount of the `base_asset` which must be locked in the bond account for the `base_asset`.
1. `spot_commitment_lock_window`: time (in seconds) which a commitment is "locked" after it is submitted or amended before it can be amended or cancelled.
1. `spot_liquidity_fee_consensus`: required fraction of LPs (scaled by their commitments) to propose a liquidity fee (or lower) for it to be accepted.

## 3. Market parameters

1. `base_decimal_places`: sets the number of decimal places of the `base` asset when specifying order size (specified in place of `position_decimal_places`).
1. `quote_decimal_places`: sets the number of decimal places of the `quote` asset when specifying order price (specified in place of `market_decimal_places`).

## 4. Trading

When placing an order, the party should have a sufficient amount of the `quote` asset (for "buy" orders) or `base` asset (for "sell" orders) to cover the value of the order as well as any fees incurred from the order trading instantly.

If the order does not immediately trade (or only trades in part) then the party will have to transfer the amount of the `quote` asset (for "buy" orders) or the `base` asset (for "sell" orders) required to cover the value of the outstanding order as well as possible fees to a `holding` account.

When an order is fulfilled or cancelled any remaining funds in the `holding` account (after the trade has been executed) can be returned to to the parties `general` account.

## 5. Liquidity Commitments

When a Liquidity Provider submits a liquidity commitment to a market, they are able to submit a separate commitment for each side of the market. There is no requirement to submit a commitment on both sides of the market or submit commitments of equal value.

Liquidity commitments on the "BUY" side of the market must be specified in the `quote_asset` and commitments on the "SELL" side of the market must be specified in the `base_asset`. For a commitment to be valid, the LP must have a sufficient amount of the relevant asset. This will be locked in the `bond_account` for that market asset pair.

To prevent LPs frequently reducing or cancelling liquidity commitments; liquidity cancellations or amendments which reduce the committed amount will not be enacted until the end of the current trading window. Liquidity amendments which increase the commitment amount or amend the liquidity shape will be allowed and enacted instantly.

## 6. Liquidity Shortfalls

If at any point in time, a liquidity provider has insufficient capital in their general accounts to cover a transfer arising from a filled liquidity order, the network will utilise the liquidity commitment, held in the relevant bond account to cover the shortfall. As there is no need for an insurance pool in a spot market, there is no need for a bond penalty.

An LPs `quote_commitment_amount` or `base_commitment_amount` must be recalculated whenever funds from a `base_bond_account` or `quote_bond_account` are used to cover a shortfall respectively.

## 7. Liquidity Fees

As there is no margin or leverage when dealing with `Spot` products there is no need for a certain level of liquidity to ensure distressed parties can be closed out. There is therefore no need to calculate `target_stake`.

In the absence of a `target_stake` value, the liquidity fee should be determined as the lowest possible fee that a fraction of the committed LPs propose (controlled by the network parameter `spot_liquidity_fee_consensus`).

```psuedo
Example 1:

spot_liquidity_fee_consensus = 0.49

LP1 commits 2000 USD @ 0.01 fee
LP2 commits 1000 USD @ 0.02 fee
LP3 commits 1000 USD @ 0.03 fee

liquidity_fee_factor = 0.01
```

```psuedo
Example 2:

spot_liquidity_fee_consensus = 0.51

LP1 commits 2000 USD @ 0.01 fee
LP2 commits 1000 USD @ 0.02 fee
LP3 commits 1000 USD @ 0.03 fee

liquidity_fee_factor = 0.02
```

As LPs are able to make un-equal commitments on each side of the book, a separate liquidity fee should be calculated for buy and sell orders.

- liquidity fee for **buy** orders should be calculated from the pool of liquidity committed on the **sell** side.
- the liquidity fee for **sell** orders should be calculated from the pool of liquidity commitments on the **buy** side.

Fees gathered from buy and sell orders should also be transferred to a separate liquidity pool. An LPs share of the buy fees or sell fees is calculating using their **buy** and **sell** commitments respectively.


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

# Built-in [Product](./0051-PROD-product.md): Spot

This built-in product provides spot contracts which allow the buying and selling of a "base" asset with a "quote" asset for immediate delivery.

When trading Spot products, parties can only use assets they own - there is no leverage or margin.

## 1. Product parameters

1. `base_asset (Asset)`: this is used to specify the asset to be purchased or sold on the market.
1. `quote_asset (Asset)`: this is used to specify the asset which can be exchanged for the base asset.

## 2. Network Parameter

1. `spot_trading_enabled`: parameter defines whether markets using Spot products are enabled on the network.

## 3. Liquidity Monitoring parameters

1. `time_window`: length of rolling window (in seconds) over which the maximum `total_stake` is measured.
1. `target_stake_factor`: fraction of `total_stake` to be selected as the `target_stake`.

## 4. Market parameters

1. `market_decimal_places` should be used to specify the number of decimal places of the `quote_asset` when specifying order price.

    The Cash Settled Futures spec could rename `market_decimal_places` to something more general, e.g. `price_decimal_places`.

1. `position_decimal_places` should be used to specify the number of decimal places of the `base_asset` asset when specifying order size.

    The Cash Settled Futures spec could rename `position_decimal_places` to something more general, e.g. `size_decimal_places`.

## 5. Liquidity Commitments

### Submissions

Liquidity commitments to a Spot market are made as detailed in [0044-LIME](./0044-LIME-lp_mechanics.md).

A liquidity provision submitted to a `Spot` market specifies a single commitment amount in the `quote` asset.

```psuedo
Example `LiquidityProvisionSubmission` command to an ETH/DAI market:

submission = {
    "liquidityProvisionSubmission": 
    {
        marketId: "abcdefghiklkmnopqrstuvwxyz",
        fee: "0.01",
        commitmentAmount: 15000 (DAI)
        reference: "example_liquidity_provision_submission"
    }
}
```

To receive rewards for this commitment, An LP is then obligated to provide orders with a total value equalling their commitment amount on both the `buy` and `sell` sides of the market. As orders on a Spot market have their price expressed in the `quote` asset and their size expressed in the `base` asset, a trades value will be expressed in the `quote` asset.

### Amendments and Cancellations

A liquidity amendment or a cancellation is determined as valid following spec [0044-LIME](./0044-LIME-lp_mechanics.md) with the following exceptions:

- the `maximum_reduction_amount` should be `INF` in the case where the liquidity `time_window=Os` (Note: this is not strictly necessary but an LP is effectively able to reduce their commitment to zero anyway in this case through multiple commitment amendments)

As the target stake (and therefore `maximum_reduction_amount`) is some factor of the total stake (see [Target Stake](./0080-SPOT-product_builtin_spot.md#market-target-stake)), a single LP will never be able to reduce their commitment to `0` if they are the only LP in a market. They can either keep reducing to a sufficiently small amount they're willing to ignore, or they can submit a governance vote to cancel the market, see the [governance spec](./0028-GOVE-governance.md).

For market cancellation proposal a sole LP in the market holds all the voting power (unless governance token holders override them).

## 6. Spot Liquidity Mechanisms

### Market Total Stake

The `total_stake` for a `Spot` market is calculated simply as the sum of each LPs `physical_stake` and therefore should be expressed in the `quote_asset` of the market.

### Market Target Stake

See spec [0041-TSTK](./0041-TSTK-target_stake.md).

### Market Liquidity Fees

The market liquidity fee is calculated using the same mechanism defined in [0042-LIQF](./0042-LIQF-setting_fees_and_rewarding_lps.md).

The liquidity fee is re-calculated at the start of a fee distribution epoch and is fixed for that epoch.
Note: 1. this may later be applied universally to all products. 2. this "fee distribution epoch" is unrelated to blockchain staking and delegation epochs.

## 7. Trading

Both buy and sell orders on a `Spot` market define a size (amount of the `base_asset`) to buy or sell at a given price (amount of the `quote_asset`). An orders "value for fee purposes" is always expressed in the `quote_asset`.

### Sell Orders

For a "sell" order to be considered valid, the party must have a sufficient amount of the `base_asset` in the relevant `general_account` to fulfil the size of the order. There is no need to consider trading fees when determining if a "sell" order is valid.

If a "sell" order does not trade immediately (or only trades in part), an amount of the `base_asset` to cover the remaining size of the order should be transferred to a `holding_account` for the `base_asset`. If the order is cancelled or the size is reduced through an order amendment, funds should be released from the `holding_account` and returned to the `general_account`.

If a "sell" order incurs fees through trading (i.e. is the aggressor or trades in an auction), the necessary amount of the `quote_asset` to cover the fees incurred will be deducted from the amount of the `quote_asset` due to the party as a result of the sell of the `base_asset`.

### Buy Orders

As "buy" orders require a party to hold a sufficient amount of the `quote_asset` to cover possible fees, the individual cases where fees can be incurred must be considered.

#### Continuous Trading

For a "buy" order to be considered valid during continuous trading, the party must have a sufficient amount of the `quote_asset` in the `general_account` to cover the value of the trade as well as any possible fees incurred as a result of the order trading immediately (the aggressor).

If a "buy" order does not trade immediately (or only trades in part), the necessary amount of the `quote_asset` to cover only the remaining size of the order should be transferred to a `holding_account` for the `quote_asset`. As the order can no longer be the aggressor during continuous trading there is no requirement to hold funds to cover fees. If the order is cancelled or the size is reduced through an order amendment, funds should be released from the `holding_account` and returned to the `general_account`.

#### Entering an Auction

When entering an auction, for any open "buy" orders, the network must transfer additional funds from the parties `general_account` to the parties `holding_account` to cover any possible fees incurred as a result of the order trading in the auction. If the party does not have sufficient funds in their `general` account to cover this transfer, the order should be cancelled.

For a "buy" order to be considered valid during an auction, the party must have a sufficient amount of the `quote_asset` to cover the size of the order as well as any possible fees occurred as a result of the order trading in the auction.

If the fee rates change for whatever reason within an auction, the amount required to cover fees must be recalculated and the necessary amount transferred to or released from the `holding_account`.

#### Exiting an Auction

When exiting an auction, for any orders which are still open, the funds held in the parties `holding_account` to cover the possible fees can be released to the parties `general_account` so the only amount remaining in the `holding_account` is enough to cover the value of the order.

## 8. Auctions

As there is no margin or leverage when dealing with `Spot` products, there is no need for the supplied liquidity to exceed a threshold to exit an auction. There is therefore no need for liquidity auctions.

Price-monitoring auctions are still required and should be implemented following the [price-monitoring](./0032-PRIM-price_monitoring.md) spec.

## 9. Acceptance Criteria

1. Create a `Spot` for any `quote_asset` / `base_asset` pair that are configured in Vega (<a name="0080-SPOT-001" href="#0080-SPOT-001">0080-SPOT-001</a>)
1. It is not possible to change the `quote_asset` via governance (<a name="0080-SPOT-002" href="#0080-SPOT-002">0080-SPOT-002</a>)
1. It is not possible to change the `base_asset` via governance (<a name="0080-SPOT-003" href="#0080-SPOT-003">0080-SPOT-003</a>)
1. A `Spot` market can be closed through governance (<a name="0080-SPOT-004" href="#0080-SPOT-004">0080-SPOT-004</a>)
1. Parties are unable to place orders they do not have the necessary funds for (<a name="0080-SPOT-005" href="#0080-SPOT-005">0080-SPOT-005</a>)
1. Parties are unable to submit liquidity commitments they do not have the necessary funds for (<a name="0080-SPOT-006" href="#0080-SPOT-006">0080-SPOT-006</a>)
1. Market liquidity fees are calculated correctly (<a name="0080-SPOT-007" href="#0080-SPOT-007">0080-SPOT-007</a>)
1. Spot Order Amend with increase in Size and party has sufficient cover. Given that Market is in Continuous Trading Mode. (<a name="0080-SPOT-008" href="#0080-SPOT-0008">0080-SPOT-008</a>)
   1. Top up Party1 general account by 10,000 ETH (units), Party2 general account by 15 BTC (units) and perform following steps and expected conditions
   2. Submit a buy order as Party1@ETC/BTC@Buy@Size5@Price500.
   3. After order submission, Holding Account is  2,500 ETH (or units).
   4. Amend the order as  Party1@Buy@Size15@Price500.
   5. After amend, the Holding Account balance is 2,500 ETH(units)
   6. Submit Sell order as Party2@Sell@BTC/ETH@Size15@Price500
   7. Trade is matched
   8. Party1 balance 2,500 and Party2 balance 0 BTC
1. Amend by Decreasing the Size in Continuous Trading Mode and party has sufficient cover, given that BTC/ETH Spot Market is in Continuous Trading Mode and maker fee 0.004 and infra fee 0.001  (<a name="0080-SPOT-009" href="#0080-SPOT-0009">0080-SPOT-009</a>)
   1. Party1 has general account balance of 1000 BTC (units) and 9000 ETH(units)
   2. Party2 has general account balance of 100,000 ETH (units)
   3. Submit sell order as Party1@ETH/BTC@100BTC@1000, holding balance after submit is 100 units (BTC)
   4. Submit Buy order as Party2@ETH/BTC@100BTC@800 , holding balance after submit is (80000)
   5. Amend Buy order as Party2@ETH/BTC@70BTC@1000  
   6. Party2 should have general account balance of 29510 for asset "ETH" and 70 for asset "BTC" (maker fee 345 and infra fee 145 )
   7. Party1 should have general account balance of 79450 for asset "ETH" and 900 for asset "BTC"
1. Perform above steps for Order Amend in Opening Auction Trading Mode (<a name="0080-SPOT-010" href="#0080-SPOT-0010">0080-SPOT-010</a>)
1. Perform above steps for Order Amend in Price Monitoring Auction Mode (<a name="0080-SPOT-011" href="#0080-SPOT-0011">0080-SPOT-011</a>)
1. No fees paid when orders are amended in Opening Auction Mode (<a name="0080-SPOT-012" href="#0080-SPOT-0012">0080-SPOT-012</a>)
1. Fee Calculation in Continuous Trading Mode and Buyer is Aggressor (<a name="0080-SPOT-013" href="#0080-SPOT-0013">0080-SPOT-013</a>)
   1. Set default as Infra Fee-10%, Maker Fee 20%
   2. Party1 submits order SELL@BTC/ETH@Volume 5 @Price 100
   3. Party2 submits order BUY@BTC/ETH@Volume 5@ Price 100
   4. Party2 general account balance of ETH is 350  ( infra fee 50, maker fee 100 )
   5. Party1 general account balance of ETH is 600  ( infra fee 50, gets maker fee 100)
   6. Infra Fee is 50
1. Fee calculation in Continuous Trading Mode and Seller is Aggressor (<a name="0080-SPOT-014" href="#0080-SPOT-0014">0080-SPOT-014</a>)
   1. Party1  - BID@BTC/ETH@Volume 5@ Price 100  and account balance as  1000 ETH
   2. Party2  - ASK@BTC/ETH@Volume 5@ Price 100  and account balance as 0 ETH
   3. Infra fee - 10% and Maker fee - 20%
   4. Party 1 - Buyer Account Balance  - 500 + 100 (maker fee ) = 600
   5. Party2 - Seller Account Balance - (500- 100 (maker fee ) - infra free 50 ) = 350  
1. Price monitoring auction - No maker fee during the auction mode and while trading prices move beyond the price monitoring bounds) (<a name="0080-SPOT-015" href="#0080-SPOT-0015">0080-SPOT-015</a>)
   1. Party1 submits order ASK@BTC/ETH@Volume 5@ Price 100  having account balance of 0 ETH
   2. Party2 submits order BID@BTC/ETH@Volume 5@ Price 100  having account balance of  1000 ETH
   3. Infra fee - 10%  (each pay 5% of the fee )
   4. Party 1   - account balance =  500 - 25 = 475 ETH
   5. Party 2   - account balance =  500 - 25 = 475 (totally paid 525) ETH
1. Multiple traders can submit orders at the same time and orders are filled based on the price match.(<a name="0080-SPOT-016" href="#0080-SPOT-0016">0080-SPOT-016</a>)
   1. create spot market with quote and base asset
   2. 3 buy traders and 3 sell traders can submit orders and fill the orders at same time
1. Spot governance proposal fails with asset error, when `quote_asset` and `base_asset` has same assets. Alternatively, it signifies that `quote_asset` is `base_asset` and `base_asset` is also a `base_asset`.(<a name="0080-SPOT-017" href="#0080-SPOT-0017">0080-SPOT-017</a>)

# Built-in [Product](./0051-PROD-product.md): Spot

This built-in product provides spot contracts which allow the buying and selling of a "base" asset with a "quote" asset for immediate delivery.

When trading Spot products, parties can only use assets they own - there is no leverage or margin.


## 1. Product parameters

1. `base_quote_pair (Explicit Value)`: human readable name/abbreviation of the base/quote pair.
1. `base_asset (Settlement Asset)`: this is used to specify the asset to be purchased or sold on the market.
1. `quote_asset (Settlement Asset)`: this is used to specify the asset which can be exchanged for the base asset.
1. `trading_termination_trigger (Data Source)`: triggers the market to move to `trading terminated` status. This trigger would usually be a datetime based trigger but may also use an oracle.

## 2.  Market parameters

1. `base_decimal_places`: sets the number of decimal places of the `base` asset when specifying order size (specified in place of `position_decimal_places`).
1. `quote_decimal_places`: sets the number of decimal places of the `quote` asset when specifying order price (specified in place of `market_decimal_places`).


## 3. Trading

1. When placing an order, the party should have a sufficient amount of the `quote` asset (for "buy" orders) or `base` asset (for "sell" orders) to cover the value of the order as well as any fees incurred from the order trading instantly.

1. If the order does not immediately trade (or only trades in part) then the party will have to transfer the amount of the `quote` asset (for "buy" orders) or the `base` asset (for "sell" orders) required to cover the value of the outstanding order as well as possible fees to a `holding` account.

1. When an order is fulfilled or cancelled any remaining funds in the `holding` account (after the trade has been executed) can be returned to to the parties `general` account.


## 4. Liquidity Fees

As there is no margin or leverage when dealing with `Spot` products there is no need for a certain level of liquidity to ensure distressed parties can be closed out. There is therefore no need to calculate `target_stake` from `max_oi` over a `time_window`.

For `Spot` products either a new method of calculating `target_stake` or an entire new method of determining the market `liquidity_fee` is required.

### 4.2 Option 1

Keeping the current `liquidity_fee` selection method implemented for `future` products, `target_stake` should be calculated as follows:
```
target_stake = volume over time-window * mark price * target_stake_scaling_factor
```
#### Advantages
- Prevents LPs removing a commitment whenever they like, due to mechanics in 0044-LIME.
- The fee is tied to activity in a market, prevents a whale forcing a high fee by providing a large liquidity commitment where it is not needed (need to clarify the need for liquidity in a Spot market).
#### Disadvantages
- Possible there is no need for a high target-stake (and therefore high-fee) just because there has been a high traded volume over the last time-window (again need to clarify the need for liquidity in a Spot market).

### 4.1 Option 2

In the absence of a `target_stake` value, the liquidity fee should be determined as the lowest possible fee that a fraction of the committed LPs propose (controlled by a market parameter).

```
Example 1:

liquidity_fee_consensus = 0.49

LP1 commits 2000 ETH @ 0.01 fee
LP2 commits 1000 ETH @ 0.02 fee
LP3 commits 1000 ETH @ 0.03 fee

liquidity_fee_factor = 0.01
```
```
Example 2:

liquidity_fee_consensus = 0.51

LP1 commits 2000 ETH @ 0.01 fee
LP2 commits 1000 ETH @ 0.02 fee
LP3 commits 1000 ETH @ 0.03 fee

liquidity_fee_factor = 0.02
```
#### Advantages
#### Disadvantages
- With the absence of target-stake, there is nothing currently preventing an LP removing a liquidity commitment (only current reason not to do so is loss of virtual stake from market growth).


## 5. Auctions

As there is no margin or leverage when dealing with `Spot` products, there is no need for the supplied liquidity to exceed a threshold to exit an auction. There is also no need for liquidity auctions.


# Fees on Vega

Fees are incurred on every trade on Vega.

An order may cross with more than one other order, creating multiple trades. Each trade incurs a fee which is always non-negative.

## Calculating fees

The trading fee is:

`total_fee = infrastructure_fee + maker_fee + liquidity_fee + buyback_fee + treasury_fee`

`infrastructure_fee = fee_factor[infrastructure] * trade_value_for_fee_purposes`

`maker_fee =  fee_factor[maker]  * trade_value_for_fee_purposes`

`liquidity_fee = fee_factor[liquidity] * trade_value_for_fee_purposes`

`buyback_fee = fee_factor[buyback] * trade_value_for_fee_purposes`

`treasury_fee = fee_factor[treasury] * trade_value_for_fee_purposes`

Fees are calculated and collected in the settlement currency of the market, collected from the general account. Fees are collected first from the trader's account and then margin from account balance. If the general account doesn't have sufficient balance, then the remaining fee amount is collected from the margin account. If this is still insufficient then different rules apply between continuous trading and auctions (details below).

Note that maker_fee = 0 if there is no maker, taker relationship between the trading parties (in particular auctions).

## Applying benefit factors

Before fees are transferred, if there is an [active referral program](./0083-RFPR-on_chain_referral_program.md) or [volume discount program](./0085-VDPR-volume_discount_program.md), each parties fee components must be modified as follows.

Note, discounts are calculated and applied one after the other and **before** rewards are calculated. Additionally, no benefit discounts can be applied to the treasury or buyback fee components as these may be required for the `high volume market maker rebate`.

1. Calculate any referral discounts due to the party.

    ```pseudo
    infrastructure_fee_referral_discount = floor(original_infrastructure_fee * referral_infrastructure_discount_factor)
    liquidity_fee_referral_discount = floor(original_liquidity_fee * referral_liquidity_discount_factor)
    maker_fee_referral_discount = floor(original_maker_fee * referral_maker_discount_factor)
    ```

1. Apply referral discounts to the original fee.

    ```pseudo
    infrastructure_fee_after_referral_discount = original_infrastructure_fee - infrastructure_fee_referral_discount
    liquidity_fee_after_referral_discount = original_infrastructure_fee - liquidity_fee_referral_discount
    maker_fee_after_referral_discount = original_infrastructure_fee - maker_fee_referral_discount
    ```

1. Calculate any volume discounts due to the party.

    ```pseudo
    infrastructure_fee_volume_discount = floor(infrastructure_fee_after_referral_discount * volume_infrastructure_discount_factor)
    liquidity_fee_volume_discount = floor(liquidity_fee_after_referral_discount * volume_liquidity_discount_factor)
    maker_fee_volume_discount = floor(maker_fee_after_referral_discount * volume_maker_discount_factor)
    ```

1. Apply any volume discounts to the fee after referral discounts.

    ```pseudo
    infrastructure_fee_after_volume_discount = infrastructure_fee_after_referral_discount - infrastructure_fee_volume_discount
    liquidity_fee_after_volume_discount = liquidity_fee_after_referral_discount - liquidity_fee_volume_discount
    maker_fee_after_volume_discount = maker_fee_after_referral_discount - maker_fee_volume_discount
    ```

1. Calculate any referral rewards due to the parties referrer (Note we are using the updated fee components from step 4 and the `referralProgram.maxReferralRewardProportion` is the network parameter described in the [referral program spec](./0083-RFPR-on_chain_referral_program.md#network-parameters))

    ```pseudo
    infrastructure_fee_referral_reward = floor(infrastructure_fee_after_volume_discount * min(referral_infrastructure_reward_factor * referral_reward_multiplier, referralProgram.maxReferralRewardProportion))
    liquidity_fee_referral_reward = floor(liquidity_fee * min(liquidity_fee_after_volume_discount * min(referral_liquidity_reward_factor * referral_reward_multiplier, referralProgram.maxReferralRewardProportion)))
    maker_fee_referral_reward = floor(maker_fee * min(maker_fee_after_volume_discount * min(referral_maker_reward_factor * referral_reward_multiplier, referralProgram.maxReferralRewardProportion)))
    ```

1. Finally, update the fee components by applying the rewards.

    ```pseudo
    final_infrastructure_fee = maker_fee_after_volume_discount - infrastructure_fee_referral_reward
    final_liquidity_fee = maker_fee_after_volume_discount - liquidity_fee_referral_reward
    final_maker_fee = maker_fee_after_volume_discount - maker_fee_referral_reward
    ```

(Note the rewards and discounts are floored rather than raised to ensure the final fees cannot be negative.)

### Factors

- infrastructure: staking/governance system/engine (network wide)
- maker: market framework / market making (network wide)
- liquidity: market making system (per market)
- treasury: Fees sent to network treasury for later usage via governance votes (network wide)
- buyback: Fees used to purchase governance tokens to the protocol via regular auctions (network wide)

The infrastructure fee factor is set by a network parameter `market.fee.factors.infrastructureFee` and a reasonable default value is `fee_factor[infrastructure] = 0.0005 = 0.05%`.
The maker fee factor is set by a network parameter `market.fee.factors.makerFee` and a reasonable default value is `fee_factor[maker] = 0.00025 = 0.025%`.
The liquidity fee factor is set by an auction-like mechanism based on the liquidity provisions committed to the market, see [setting LP fees](./0042-LIQF-setting_fees_and_rewarding_lps.md).

The treasury fee factor is set by the network parameter `market.fee.factors.treasuryFee` can be changed through a network parameter update proposal. It has minimum allowable value of `0` maximum allowable value of `1` and a default of `0`.

The buyback fee factor is set by the network parameter `market.fee.factors.buybackFee` can be changed through a network parameter update proposal. It has minimum allowable value of `0` maximum allowable value of `1` and a default of `0`.

trade_value_for_fee_purposes:

- refers to the amount from which we calculate fee, (e.g. for futures, the trade's notional value = size_of_trade * price_of_trade)
- trade_value_for_fee_purposes is defined on the Product and is a function that may take into account other product parameters

Initially, for futures, the trade_value_for_fee_purposes = notional value of the trade = `size_of_trade` * `price_of_trade`. For other product types, we may want to use something other than the notional value. This is determined by the Product.

NB: size of trade needs to take into account Position Decimal Places specified in the [Market Framework](./0001-MKTF-market_framework.md), and if trade/position sizes are stored as integers will need to divide by `10^PDP` where PDP is the configured number of Position Decimal Places for the market (or this division will need to be abstracted and done global by the position management component of Vega which may expose both a true and an integer position size, or something).

### Collecting and Distributing Fees

We need to calculate the total fee for the transaction (before applying benefit factors).
Attempt to transfer the full fee from the trader into a temporary bucket, one bucket per trade (so we know who the maker is) from the trader general account.
If insufficient, then take the remainder (possibly full fee) from the margin account.
The margin account should have enough left after paying the fees to cover maintenance level of margin for the trades.
If the transfer fails:

1. If we are in continuous trading mode, than trades should be discarded, any orders on the book that would have been hit should remain in place with previous remaining size intact and the incoming order should be rejected (not enough fees error).
This functionality requires to match orders and create trades without changing the state of the order book or passing trades downstream so that the execution of the transaction can be discarded with no impact on the order book if needed.
Other than the criteria whether to proceed or discard, this is exactly the same functionality required to implement [price monitoring](./0032-PRIM-price_monitoring.md).
1. If we are in auction mode, ignore the shortfall (and see more details below).

The transfer of fees must be completed before performing the normal post-trade calculations (MTM Settlement, position resolution etc...). The transfers have to be identifiable as fee transfers and separate for the different components.

Additionally, a `high_volume_market_maker_rebate` may be necessary which will be taken from the `treasury/buyback_fee` components. This will be calculated as:

1. Determine whether the maker party of the trade (if there is one) qualifies for a `high volume market maker rebate` and, if so, at what rate.
1. Calculate the fee that this corresponds to as `high_volume_maker_fee = high_volume_factor * trade_value_for_fee_purposes`.
1. Take this fee from the `treasury_fee` and `buyback_fee` (protocol restrictions on governance changes ensure that `treasury_fee + buyback_fee >= high_volume_maker_fee` is always true) as a proportion of their relative sizes, i.e.:
   1. `high_volume_maker_fee = high_volume_factor * trade_value_for_fee_purposes`
   1. `treasury_fee = treasury_fee * (1 - high_volume_maker_fee / (treasury_fee + buyback_fee))`
   1. `buyback_fee = buyback_fee * (1 - high_volume_maker_fee / (treasury_fee + buyback_fee))`

Now [apply benefit factors](#applying-benefit-factors) and then distribute funds from the "temporary fee bucket" as follows:

1. The `infrastructure_fee` is transferred to infrastructure fee pool for that asset. Its distribution is described in [0061 - Proof of Stake rewards](./0061-REWP-pos_rewards.md). In particular, at the end of each epoch the amount due to each validator and delegator is to be calculated and then distributed subject to validator score and type.
1. The `maker_fee` and any `high_volume_maker_fee` are transferred to the relevant party (the maker).
1. The `liquidity_fee` is distributed as described in [this spec](./0042-LIQF-setting_fees_and_rewarding_lps.md).
1. The `treasury_fee` is transferred to the treasury fee pool for that asset, where it will remain until community governance votes for transfers.
1. The `buyback_fee` is transferred to the buyback fee pool for that asset, where it will remain until community governance votes for transfers or a regular purchase program is set up.
1. The referral fee components (if any) can then be individually transferred to the relevant party (the referee).

### During Continuous Trading

The "aggressor or price taker" of each trade is the participant who submitted / amended the incoming order that caused the trade  (including automatic amendments like pegged orders).

The "aggressor or price taker" pays the fee. The "passive or price maker" party is the participant in the trade whose order was hit (i.e. on the order book prior to the uncrossing that caused this trade)

### Normal Auctions (including market protection and opening auctions)

During normal auctions there is no "price maker" both parties are "takers". Each side in a matched trade should contribute 1/2 of the infrastructure_fee + liquidity_fee + treasury_fee + buyback_fee. Note that this does not include a maker fee.

Fees calculated and collected from general + margin as in continuous trading *but* if a party has insufficient capital to cover the trading fee then in auction the trade *still* *goes* *ahead* as long as the margin account should have enough left after paying the fees to cover maintenance level of margin for the orders and then converted trades. The fee is distributed so that the infrastructure_fee is paid first and only then the liquidity_fee/treasury_fee/buyback_fee.

During an opening auction of a market, no makers fees are collected.

### Frequent Batch Auctions

Order that entered the book in the current batch are considered aggressive orders. This means that in some cases both sides of a trade will be aggressors in which case the fee calculation for normal auctions applies. Otherwise, the fee calculation for continuous trading applies.

### Position Resolution

The trades that were netted off against each other during position resolution incur no fees.
During position resolution all of the parties being liquidated share the total fee for the network order, pro-rated by the size of position.
As for fees in other cases, the fee is taken out of the general + margin account for the liable traders (the market's insurance pool is not used to top up fees that cannot be paid). If the general + margin account is insufficient to cover the fee then the fee (or part of it) is not going to get paid. In this case we first pay out the maker_fee (or as much as possible), then then infrastructure_fee (or as much as possible) and finally the liquidity_fee.

### Rounding

All fees are being rounded up (using `math.Ceil` in most math libraries).
This ensures that any trade in the network will require the party to pay a fee, even in the case that the trade would require a fee smaller than the smallest unit of the asset.
For example, Ether is 18 decimals (wei). The smallest unit, non divisible is 1 wei, so if the fee calculation was to be a fraction of a wei (e.g 0.25 wei), which you cannot represent in this currency, then the Vega network would round it up to 1.

## Acceptance Criteria

- Fees are collected during continuous trading and auction modes and distributed to the appropriate accounts, as described above. (<a name="0029-FEES-001" href="#0029-FEES-001">0029-FEES-001</a>). For product spot: (<a name="0029-FEES-015" href="#0029-FEES-015">0029-FEES-015</a>)
- Fees are debited from the general (+ margin if needed) account on any market orders that during continuous trading, the price maker gets the appropriate fee credited to their general account and the remainder is split between the market making pool and infrastructure (staking) pool. (<a name="0029-FEES-002" href="#0029-FEES-002">0029-FEES-002</a>)
- Fees are debited from the general (+ margin if needed) account on the volume that resulted in a trade on any "aggressive / price taking" limit order that executed during continuous trading, the price maker gets the appropriate fee credited to their general account and the remainder is split between the market making pool and staking pool.  (<a name="0029-FEES-003" href="#0029-FEES-003">0029-FEES-003</a>)
- Fees are debited from the general (+ margin if needed) account on any "aggressive / price taking" pegged order that executed during continuous trading, the price maker gets the appropriate fee credited to their general account and the remainder is split between the market making pool and staking pool. (<a name="0029-FEES-004" href="#0029-FEES-004">0029-FEES-004</a>)
- Fees are collected in one case of amends: you amend the price so far that it causes an immediate trade.  (<a name="0029-FEES-005" href="#0029-FEES-005">0029-FEES-005</a>). For product spot: (<a name="0029-FEES-016" href="#0029-FEES-016">0029-FEES-016</a>)
- During auctions, each side of a trade is debited 1/2 (infrastructure_fee + liquidity_fee) from their general (+ margin if needed) account. The infrastructure_fee fee is credited to the staking pool, the liquidity_fee is credited to the market making pool. (<a name="0029-FEES-006" href="#0029-FEES-006">0029-FEES-006</a>)
- During continuous trading, if a trade is matched and the aggressor / price taker has insufficient balance in their general (+ margin if needed) account, then the trade doesn't execute if maintenance level of trade is not met. (<a name="0029-FEES-007" href="#0029-FEES-007">0029-FEES-007</a>)
- During auctions, if either of the two sides has insufficient balance in their general (+ margin if needed) account, the trade still goes ahead only if the margin account should have enough left after paying the fees to cover maintenance level of margin for the orders and then converted trades. (<a name="0029-FEES-008" href="#0029-FEES-008">0029-FEES-008</a>)
- Changing parameters (via governance votes) does change the fees being collected appropriately even if the market is already running.  (<a name="0029-FEES-009" href="#0029-FEES-009">0029-FEES-009</a>). For product spot: (<a name="0029-FEES-017" href="#0029-FEES-017">0029-FEES-017</a>)
- A "buyer_fee" and "seller_fee" are exposed in APIs for every trade, split into the three components (after the trade definitely happened) (<a name="0029-FEES-010" href="#0029-FEES-010">0029-FEES-010</a>). For product spot: (<a name="0029-FEES-018" href="#0029-FEES-018">0029-FEES-018</a>)
- Users should be able to understand the breakdown of the fee to the three components (by querying for fee payment transfers by trade ID, this requires enough metadata in the transfer API to see the transfer type and the associated trade.) (<a name="0029-FEES-011" href="#0029-FEES-011">0029-FEES-011</a>). For product spot: (<a name="0029-FEES-019" href="#0029-FEES-019">0029-FEES-019</a>)
- The three component fee rates (fee_factor[infrastructure], fee_factor[maker], fee_factor[liquidity]) are available via an API such as the market data API or market framework. (<a name="0029-FEES-012" href="#0029-FEES-012">0029-FEES-012</a>). For product spot: (<a name="0029-FEES-020" href="#0029-FEES-020">0029-FEES-020</a>)
- A market is set with [Position Decimal Places" (PDP)](0052-FPOS-fractional_orders_positions.md) set to 2. A market order of size 1.23 is placed which is filled at VWAP of 100. We have fee_factor[infrastructure] = 0.001, fee_factor[maker] = 0.002, fee_factor[liquidity] = 0.05. The total fee charged to the party that placed this order is `1.23 x 100 x (0.001 + 0.002 + 0.05) = 6.519` and is correctly transferred to the appropriate accounts / pools. (<a name="0029-FEES-013" href="#0029-FEES-013">0029-FEES-013</a>). For product spot: (<a name="0029-FEES-021" href="#0029-FEES-021">0029-FEES-021</a>)
- A market is set with [Position Decimal Places" (PDP)](0052-FPOS-fractional_orders_positions.md) set to -2. A market order of size 12300 is placed which is filled at VWAP of 0.01. We have fee_factor[infrastructure] = 0.001, fee_factor[maker] = 0.002, fee_factor[liquidity] = 0.05. The total fee charged to the party that placed this order is `12300 x 0.01 x (0.001 + 0.002 + 0.05) = 6.519` and is correctly transferred to the appropriate accounts / pools. (<a name="0029-FEES-014" href="#0029-FEES-014">0029-FEES-014</a>). For product spot: (<a name="0029-FEES-022" href="#0029-FEES-022">0029-FEES-022</a>)

- During opening auction, there should be no maker fees collected.(<a name="0029-FEES-036" href="#0029-FEES-036">0029-FEES-036</a>)
- During normal auction (including market protection and opening auctions), each side in a matched trade should contribute `0.5*(infrastructure_fee + liquidity_fee + treasury_fee + buyback_fee)`(<a name="0029-FEES-037" href="#0029-FEES-037">0029-FEES-037</a>)
- In a matched trade, if the price taker has enough asset to cover the total fee in their general account, then the total fee should be taken from their general account. The total fee should be `infrastructure_fee + maker_fee + liquidity_fee + treasury_fee + buyback_fee`.(<a name="0029-FEES-038" href="#0029-FEES-038">0029-FEES-038</a>)
- In a matched trade, if the price taker has insufficient asset to cover the total fee in their general account (but has enough in general + margin account), then the remainder will be taken from their margin account. (<a name="0029-FEES-039" href="#0029-FEES-039">0029-FEES-039</a>)
- In continuous trading mode, if the price taker has insufficient asset to cover the total fee in their general + margin account, then the trade should be discarded, the orders on the book that would have been hit should remain in place with previous remaining size intact and the incoming order should be rejected (not enough fees error).(<a name="0029-FEES-040" href="#0029-FEES-040">0029-FEES-040</a>)
- In auction mode, if the price taker has insufficient asset to cover the total fee in their general + margin account, then the shortfall should be ignored, the orders should remain (instead of being rejected)(<a name="0029-FEES-041" hre1f="#0029-FEES-041">0029-FEES-041</a>)

- When there is `high_volume_market_maker_rebate`, `high_volume_maker_fee` should be taken from the `treasury/buyback_fee` components with value `high_volume_maker_fee = high_volume_factor * trade_value_for_fee_purposes`(<a name="0029-FEES-042" href="#0029-FEES-042">0029-FEES-042</a>)
- When there is `high_volume_market_maker_rebate`, treasury fee will be updated to: `treasury_fee = treasury_fee * (1 - high_volume_maker_fee / (treasury_fee + buyback_fee))`(<a name="0029-FEES-043" href="#0029-FEES-043">0029-FEES-043</a>)
- When there is `high_volume_market_maker_rebate`, buyback fee will be updated to: `buyback_fee = buyback_fee * (1 - high_volume_maker_fee / (treasury_fee + buyback_fee))`(<a name="0029-FEES-044" href="#0029-FEES-044">0029-FEES-044</a>)

- Once total fee is collected, `infrastructure_fee = fee_factor[infrastucture]  * trade_value_for_fee_purposes` is transferred to infrastructure fee pool for that asset at the end of fee distribution time. (<a name="0029-FEES-045" href="#0029-FEES-045">0029-FEES-045</a>)
- Once total fee is collected, `maker_fee = fee_factor[maker]  * trade_value_for_fee_purposes` is transferred to maker at the end of fee distribution time. (<a name="0029-FEES-046" href="#0029-FEES-046">0029-FEES-046</a>)
- Once total fee is collected, the `high_volume_maker_fee` is transferred to maker at the end of fee distribution time. (<a name="0029-FEES-047" href="#0029-FEES-047">0029-FEES-047</a>)
- Once total fee is collected, `liquidity_fee = fee_factor[liquidity] * trade_value_for_fee_purposes` is distributed to liquidity providers as described in [this spec](./0042-LIQF-setting_fees_and_rewarding_lps.md).(<a name="0029-FEES-048" href="#0029-FEES-048">0029-FEES-048</a>)
- Once total fee is collected, `treasury_fee = fee_factor[treasury] * trade_value_for_fee_purposes` (with appropriate fraction of `high_volume_maker_fee` deducted) is transferred to the treasury fee pool for that asset, where it will remain until community governance votes for transfers.(<a name="0029-FEES-049" href="#0029-FEES-049">0029-FEES-049</a>)
- Once total fee is collected, `buyback_fee = fee_factor[buyback] * trade_value_for_fee_purposes` (with with appropriate fraction of `high_volume_maker_fee` deducted) is transferred to the buyback fee pool for that asset, where it will remain until community governance votes for transfers or a regular purchase program is set up.(<a name="0029-FEES-050" href="#0029-FEES-050">0029-FEES-050</a>)
- Once a change to `market.fee.factors.treasuryFee` is enacted, all future trades will apply the updated fee factor and cap high volume maker rebates where necessary using the updated factor. (<a name="0029-FEES-051" href="#0029-FEES-051">0029-FEES-051</a>)
- Once a change to `market.fee.factors.buybackFee` is enacted, all future trades will apply the updated fee factor and cap high volume maker rebates where necessary using the updated factor. (<a name="0029-FEES-052" href="#0029-FEES-052">0029-FEES-052</a>)

### Applying benefit factors

1. Referee discounts are correctly calculated and applied for each taker fee component during continuous trading (assuming no volume discounts due to party) (<a name="0029-FEES-053" href="#0029-FEES-053">0029-FEES-053</a>)
    - `infrastructure_fee_referral_discount`
    - `liquidity_fee_referral_discount`
    - `maker_fee_referral_discount`
1. Referee discounts with differing discounts across the three factors are correctly calculated and applied for each taker fee component during continuous trading (assuming no volume discounts due to party) (<a name="0029-FEES-034" href="#0029-FEES-034">0029-FEES-034</a>)
    - `infrastructure_fee_referral_discount`
    - `liquidity_fee_referral_discount`
    - `maker_fee_referral_discount`
1. Referee discounts are correctly calculated and applied for each fee component when exiting an auction (assuming no volume discounts due to party) (<a name="0029-FEES-024" href="#0029-FEES-024">0029-FEES-024</a>)
    - `infrastructure_fee_referral_discount`
    - `liquidity_fee_referral_discount`
1. Referrer rewards are correctly calculated and transferred for each fee component during continuous trading (assuming no volume discounts due to party) (<a name="0029-FEES-025" href="#0029-FEES-025">0029-FEES-025</a>)
    - `infrastructure_fee_referral_reward`
    - `liquidity_fee_referral_reward`
    - `maker_fee_referral_reward`
1. Referrer rewards with differing reward factors are correctly calculated and transferred for each fee component during continuous trading (assuming no volume discounts due to party) (<a name="0029-FEES-035" href="#0029-FEES-035">0029-FEES-035</a>)
    - `infrastructure_fee_referral_reward`
    - `liquidity_fee_referral_reward`
    - `maker_fee_referral_reward`
1. Referrer rewards are correctly calculated and transferred for each fee component when exiting an auction (assuming no volume discounts due to party) (<a name="0029-FEES-026" href="#0029-FEES-026">0029-FEES-026</a>)
    - `infrastructure_fee_referral_reward`
    - `liquidity_fee_referral_reward`
1. If the referral reward due to the referrer is strictly less than `1`, no reward is transferred (<a name="0029-FEES-029" href="#0029-FEES-029">0029-FEES-029</a>).
1. If the referral discount due to the referee is strictly less than `1`, no discount is applied (<a name="0029-FEES-030" href="#0029-FEES-030">0029-FEES-030</a>).
1. The proportion of fees transferred to the referrer as a reward cannot be greater than the network parameter `referralProgram.maxReferralRewardProportion` (<a name="0029-FEES-031" href="#0029-FEES-031">0029-FEES-031</a>).
1. Volume discount rewards are correctly calculated and transferred for each taker fee component during continuous trading (assuming no referral discounts due to party) (<a name="0029-FEES-027" href="#0029-FEES-027">0029-FEES-027</a>)
    - `infrastructure_fee_volume_discount`
    - `liquidity_fee_volume_discount`
    - `maker_fee_volume_discount`
1. Volume discount rewards are correctly calculated and transferred for each fee component when exiting an auction (assuming no referral discounts due to party) (<a name="0029-FEES-028" href="#0029-FEES-028">0029-FEES-028</a>)
    - `infrastructure_fee_volume_discount`
    - `liquidity_fee_volume_discount`
1. During continuous trading, discounts from multiple sources are correctly calculated and applied one after the other, each time using the resulting fee component after the previous discount was applied. (<a name="0029-FEES-032" href="#0029-FEES-032">0029-FEES-032</a>).
1. When exiting an auction, discounts from multiple sources are correctly calculated and applied one after the other, each time using the resulting fee component after the previous discount was applied. (<a name="0029-FEES-033" href="#0029-FEES-033">0029-FEES-033</a>).

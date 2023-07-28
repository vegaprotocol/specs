# Settlement

Settlement is the process of moving collateral between accounts when a position is closed,  the market expires or if there is an interim settlement action defined in the product.

Further to this, the protocol may elect to settle a market at a point in time by carrying out [mark to market settlement](./0003-MTMK-mark_to_market_settlement.md). This is helpful for maintaining lower margins requirements.

## Overview

Vega operates as a decentralised "Central Counterparty" (CCP) and facilitates the settlement of markets at various stages of its lifecycle.

Settlement on markets occurs when:

1. **A position is fully or partially closed** - An open position is closed when the owner of the open position enters into a counter trade (including if that trade is created as part of a forced risk management closeout). Settlement occurs for the closed volume / contracts.
1. **[An instrument expires](#settlement-at-instrument-expiry)** - all open positions in the market are settled. After settlement at expiry, all positions are closed and collateral is released.
1. **Interim cash flows are generated** - not relevant for first instruments launched on Vega. Will be potentially relevant for perpetual futures with periodic settlement.
1. **Mark to market event** - when the protocol runs [mark to market settlement](./0003-MTMK-mark_to_market_settlement.md).

## Moving collateral

Settlement calculation logic is defined on the product (for example, see the spec for [cash settled direct futures](./0016-PFUT-product_builtin_future.md)).

Settlement adheres to double entry accounting.

Settlement instructions contain information regarding the accounts from which collateral should be sourced and deducted (in order of preference) and accounts to which the collateral should be deposited.

Vega executes settlement with a two step process:

### Step 1: collection

Vega *collects* from the margin accounts of those who, according to the settlement formula, are liable to pay collateral.  The collection instruction should first collect as much as possible from the trader's margin account for the market, then the trader's general account, then the market's insurance pool. If the full required amount cannot be collected from these accounts then as much as possible is collected.

This will result in ledger entries being formulated ( see [collateral](./0005-COLL-collateral.md) ) which adhere to double entry accounting and record the actual transfers that occurred on the ledger. The destination account is the *market settlement account* for the market. This may be a persistent account or can be created for each settlement process run-through and destroyed after the process completes, but either way, **the *market settlement account* must have a zero balance before the settlement process begins and after it completes**.

### Step 2: distribution

#### Normal

If all requested amounts are successfully transferred to the *market settlement account*, then the amount collected will match the amount to be distributed and the settlement function will formulate instructions to *distribute* to the margin accounts of those whose moves have been positive according to the amount they are owed. These transfers will debit from the market's *market settlement account* and credited to the margin accounts of traders who have are due to receive a "cash / asset flow" as a result of the settlement.

#### Loss socialisation

If some of the collection transfers are not able to supply the full amount to the *market settlement account* due to some traders having insufficient collateral in their margin account and general account to handle the price / position (mark to market) move, and if the insurance pool can't cover the shortfall for some of these, then not enough funds will have been collected to distribute the full amount of the mark to market gains made by traders on the other side. Therefore, settlement needs to decide how to fairly distribute the funds that have been collected. This is called *loss socialisation*.

In future, a more sophisticated algorithm may be used for this (perhaps taking into account a trader's overall profit on their positions, for example) but initially this will be implemented by reducing the amount to distribute to each trader with an MTM gain pro-rata by relative position size:

```go
distribute_amount[trader] = mtm_gain[trader] * ( actual_collected_amount / target_collect_amount )

```

### Network orders

When a trader is distressed their position is closed out by the network placing an order to bring their position back to 0. This [network order](../protocol/0014-ORDT-order_types.md) will match against normal orders in the order book and will be part of a [mark-to-market settlement](./0003-MTMK-mark_to_market_settlement.md) action. As [the network user is a virtual user](./0017-PART-party.md#network-party) it does not have collateral accounts from which to provide or collect wins and loses. The [market insurance account](./0015-INSR-market_insurance_pool_collateral.md) is used in place of these. If a network order is settled as a win, the collateral will be transferred from the matched trader directly into the insurance account for the market. If the network order is a loss, the insurance pool will be used to pay the matched traders. [Loss socialisation](#loss-socialisation) is used if the insurance pool does not have enough collateral to cover the loss situation.

## Settlement at instrument expiry

Some markets on Vega will be trading instruments that "expire" (i.e. they are instruments based on non-perpetual products). Settlement at instrument expiry is the final settlement of such markets.

### When does a market settle at instrument expiry

The expiry of a market happens when an oracle publishes data that meets the filter requirements as defined on the Product (see [Market Framework](./0001-MKTF-market_framework.md)).

The [market lifecycle spec](./0043-MKTL-market_lifecycle.md) provides detail on all the potential paths of a market nearing expiry and should be consulted as the source of truth.

## Acceptance Criteria

### The typical "Happy Path" case (Expiring Future: <a name="0002-STTL-001" href="#0002-STTL-001">0002-STTL-001</a>, Perpetual Future: <a name="0002-STTL-011" href="#0002-STTL-011">0002-STTL-011</a>)

- With a market configured to take an oracle termination time and settlement price and put into continuous trading mode. When there are traders with open positions on the market and the termination trigger from oracle is sent so the market is terminated. Send market settlement price and assert that it is no longer possible to trade on this market.

### Example 1 - A typical path of a cash settled futures market nearing expiry when market is trading in continuous session (Expiring Future: <a name="0002-STTL-002" href="#0002-STTL-002">0002-STTL-002</a>, Perpetual Future: <a name="0002-STTL-012" href="#0002-STTL-012">0002-STTL-012</a>)

1. Market has a status of ACTIVE and is trading in default trading mode
1. The product's [trading terminated trigger is hit](./0016-PFUT-product_builtin_future.md#41-termination-of-trading)
1. The market's status is set to [TRADING TERMINATED](./0043-MKTL-market_lifecycle.md) and accepts no trading but retains the positions and margin balances that were in place after processing the trading terminated trigger. No margin recalculations or mark-to-market settlement occurs.
1. An [oracle event occurs](./0045-DSRC-data_sourcing.md) that is eligible to settle the market, as defined on the [Product](./0001-MKTF-market_framework.md) (see also [cash settled futures spec](./0016-PFUT-product_builtin_future.md))
1. Final cashflow is calculated according to the valuation formula defined on the product (see [cash settled direct futures product](./0016-PFUT-product_builtin_future.md#42-final-settlement-expiry))
1. Accounts are settled as per collection and distribution methods described above.
1. Any remaining balances in parties' margin and LP bond accounts are moved to their general account.
1. The margin accounts and LP bond accounts for these markets are no longer required.
1. Positions can be left as open, or set to zero (this isn't important for the protocol but should be made clear on the API either way).
1. The market's insurance pool is [redistributed](./0015-INSR-market_insurance_pool_collateral.md) to the on-chain treasury for the settlement asset of the market and other insurance pools using the same asset.
1. Market status is now set to [SETTLED](./0043-MKTL-market_lifecycle.md).
1. Now the market can be deleted.
1. This mechanism does not incur fees to traders that have open positions that are settled at expiry. (Expiring Future: <a name="0002-STTL-003" href="#0002-STTL-003">0002-STTL-003</a>, Perpetual Future: <a name="0002-STTL-013" href="#0002-STTL-013">0002-STTL-013</a>)

### Example 2 - A less typical path of such a futures market nearing expiry when market is suspended (Expiring Future: <a name="0002-STTL-004" href="#0002-STTL-004">0002-STTL-004</a>, Perpetual Future: <a name="0002-STTL-014" href="#0002-STTL-014">0002-STTL-014</a>)

1. Market has a status of SUSPENDED and in a protective auction
1. The product's [trading terminated trigger is hit](./0016-PFUT-product_builtin_future.md#41-termination-of-trading)
1. The market's status is set to [TRADING TERMINATED](./0043-MKTL-market_lifecycle.md) and accepts no trading but retains the positions and margin balances that were in place after processing the trading terminated trigger. No margin recalculations or mark-to-market settlement occurs. No uncrossing of the auction.
1. An [oracle event occurs](./0045-DSRC-data_sourcing.md) that is eligible to settle the market, as defined on the [Product](./0001-MKTF-market_framework.md) (see also [cash settled futures spec](./0016-PFUT-product_builtin_future.md))
1. Final cashflow is calculated according to the valuation formula defined on the product (see [cash settled direct futures product](./0016-PFUT-product_builtin_future.md#42-final-settlement-expiry))
1. Accounts are settled as per collection and distribution methods described above.
1. Any remaining balances in parties' margin and LP bond accounts are moved to their general account.
1. The margin accounts and LP bond accounts for these markets are no longer required.
1. Positions can be left as open, or set to zero (this isn't important for the protocol but should be made clear on the API either way).
1. The market's insurance pool is [redistributed](./0015-INSR-market_insurance_pool_collateral.md) to the on-chain treasury for the settlement asset of the market and other insurance pools using the same asset.
1. Market status is now set to [SETTLED](./0043-MKTL-market_lifecycle.md).
1. Now the market can be deleted.
1. This mechanism does not incur fees to traders that have open positions that are settled at expiry. (<a name="0002-STTL-005" href="#0002-STTL-005">0002-STTL-005</a>)

### Collateral movements

1. For settlement at expiry scenarios, transfers for collateral should be attempted by accessing the trader's margin account first and foremost. (<a name="0002-STTL-006" href="#0002-STTL-006">0002-STTL-006</a>)
1. If margin account of trader is insufficient to cover collateral transfers, then trade's general account is accessed next. (<a name="0002-STTL-007" href="#0002-STTL-007">0002-STTL-007</a>)
1. If margin and general account of trader are insufficient to cover collateral transfers, then collateral is attempted to be taken from market's insurance pool. (<a name="0002-STTL-008" href="#0002-STTL-008">0002-STTL-008</a>)
1. If the full required amount for collateral cannot be collected from individual or combination of these accounts, then as much as possible in the above sequence of accounts is collected and loss socialisation occurs. (<a name="0002-STTL-009" href="#0002-STTL-009">0002-STTL-009</a>)

### Example 3 - Settlement data to cash settled future is submitted before trading is terminated (<a name="0002-STTL-010" href="#0002-STTL-010">0002-STTL-010</a>)(Expiring Future: <a name="0002-STTL-010" href="#0002-STTL-010">0002-STTL-010</a>, Perpetual Future: <a name="0002-STTL-015" href="#0002-STTL-015">0002-STTL-015</a>)

1. A [cash settled futures](0016-PFUT-product_builtin_future.md) market has a status of ACTIVE and is trading in default trading mode (continuous trading)
1. An [oracle event occurs](./0045-DSRC-data_sourcing.md) that is eligible to settle the market, as defined on the [Product](./0001-MKTF-market_framework.md) (see also [cash settled futures spec](./0016-PFUT-product_builtin_future.md)). In other words the settlement price is submitted to the market before trading is terminated.
This oracle input retained and market is in the default trading mode (continuous trading).
1. At least one party places an order that triggers a trade (just to prove that we can).
1. An [oracle event occurs *again*](./0045-DSRC-data_sourcing.md) that is eligible to settle the market, as defined on the [Product](./0001-MKTF-market_framework.md) (see also [cash settled futures spec](./0016-PFUT-product_builtin_future.md)). In other words the settlement price is submitted to the market before trading is terminated.
This oracle input retained and market is in the default trading mode (continuous trading).
1. At least one party places an order that triggers a trade (just to prove that we can again).
1. The product's [trading terminated trigger is hit](./0016-PFUT-product_builtin_future.md#41-termination-of-trading)
The market's status is set to [TRADING TERMINATED](./0043-MKTL-market_lifecycle.md) and accepts no trading but retains the positions and margin balances that were in place after processing the trading terminated trigger. No margin recalculations or mark-to-market settlement occurs.
Final cashflow is calculated according to the valuation formula defined on the product (see [cash settled direct futures product](./0016-PFUT-product_builtin_future.md#42-final-settlement-expiry)) using the *most recent* retained settlement price input.
All of that happens while processing the trading terminated transaction.
1. Accounts are settled as per collection and distribution methods described above.
1. Any remaining balances in parties' margin and LP bond accounts are moved to their general account.
1. The margin accounts and LP bond accounts for these markets are no longer required.
1. Positions can be left as open, or set to zero (this isn't important for the protocol but should be made clear on the API either way).
1. The market's insurance pool is [redistributed](./0015-INSR-market_insurance_pool_collateral.md) to the on-chain treasury for the settlement asset of the market and other insurance pools using the same asset.
1. Market status is now set to [SETTLED](./0043-MKTL-market_lifecycle.md).
1. Now the market can be deleted.

# Settlement

Settlement is the process of moving collateral between accounts when a position is closed,  the market expires or if there is an interim settlement action defined in the product.

Further to this, the protocol may elect to settle a market at a point in time by carrying out [mark to market settlement](./0003-mark-to-market-settlement.md). This is helpful for maintaining lower margins requirements.

## Overview

Vega operates as a decentralised "Central Counterparty" (CCP) and facilitates the settlement of markets at various stages of its lifecyle.

Settlement on markets occurs when:

1. **A position is fully or partially closed** - An open position is closed when the owner of the open position enters into a counter trade (including if that trade is created as part of a forced risk management closeout). Settlement occurs for the closed volume / contracts.
1. **[An instrument expires](#settlement-at-instrument-expiry)** - all open positions in the market are settled. After settlement at expiry, all positions are closed and collateral is released.
1. **Interim cash flows are generated** - not relevant for first instruments launched on Vega. Will be potentially relevant for perpetual futures with periodic settlement.
1. **Mark to market event** - when the protocol runs [mark to market settlement](./0003-mark-to-market-settlement.md).

## Moving collateral

Settlement calculation logic is defined on the product (for example, see the spec for [cash settled direct futures](./0016-product-builtin-future.md)).

Settlement adheres to double entry accounting.

Settlement instructions contain information regarding the accounts from which collateral should be sourced and deducted (in order of preference) and accounts to which the collateral should be deposited.

Vega executes settlement with a two step process:

### Step 1: collection

Vega *collects* from the margin accounts of those who, according to the settlement formula, are liable to pay collateral.  The collection instruction should first collect as much as possible from the trader's margin account for the market, then the trader's general account, then the market's insurance pool. If the full required amount cannot be collected from these accounts then as much as possible is collected.

This will result in ledger entries being formulated ( see [collateral](./0005-collateral.md) ) which adhere to double entry accounting and record the actual transfers that occurred on the ledger. The destination account is the *market settlement account* for the market. This may be a persistent account or can be created for each settlement process run-through and destroyed after the process completes, but either way, **the *market settlement account* must have a zero balance before the settlement process begins and after it completes**.


### Step 2: distribution

#### Normal

If all requested amounts are succesfully transferred to the *market settlement account*, then the amount collected will match the amount to be distributed and the settlement function will formulate instructions to *distribute* to the margin accounts of those whose moves have been positive according to the amount they are owed. These transfers will debit from the market's *market settlement account* and credited to the margin accounts of traders who have are due to receive a "cash / asset flow" as a result of the settlement.

#### Loss socialisation

If some of the collection transfers are not able to supply the full amount to the *market settlement account* due to some traders having insufficient collateral in their margin account and general account to handle the price / position (mark to market) move, and if the insurance pool can't cover the shortfall for some of these, then not enough funds will have been collected to distribute the full amount of the mark to market gains made by traders on the other side. Therefore, settlement needs to decide how to fairly distribute the funds that have been collected. This is called *loss socialisation*. 

In future, a more sophisticated algorithm may be used for this (perhaps taking into account a trader's overall profit on their positions, for example) but initially this will be implemented by reducing the amount to distribute to each trader with an MTM gain pro-rata by relative position size:

```
distribute_amount[trader] = mtm_gain[trader] * ( actual_collected_amount / target_collect_amount )

```


## Settlement at instrument expiry

Some markets on Vega will be trading instruments that "expire" (i.e. they are instruments based on non-perpetual products). Settlement at instrument expiry is the final settlement of such markets.


### When does a market settle at instrument expiry
The expiry of a market happens when an oracle publishes data that meets the filter requirements as defined on the Product (see [Market Framework](./0001-market-framework.md)).

The [market lifecycle spec](./0043-market-lifecycle.md) provides detail on all the potential paths of a market nearing expiry and should be consulted as the source of truth. The below example is illustrative of market for a cash settled future where default trading is continuous.

### Example - a typical path of a cash settled futures market nearing expiry

1. Market has a status of ACTIVE and is trading in default trading mode
1. The product's [trading terminated trigger is hit](./0016-product-builtin-future.md#41-termination-of-trading)
1. The market's status is set to [TRADING TERMINATED](./0043-market-lifecycle.md) and accepts no trading but retains the positions and margin balances that were in place after processing the trading terminated trigger. No margin recalculations or mark-to-market settlement occurs.
1. An [oracle event occurs](./0045-data-sourcing.md) that is eligible to settle the market, as defined on the [Product](./0001-market-framework.md) (see also [cash settled futures spec](./0016-product-builtin-future.md))
1. Final cashflow is calculated according to the valuation formula defined on the product (see [cash settled direct futures product](./0016-product-builtin-future.md#42-final-settlement-expiry))
1. Accounts are settled as per collection and distribution methods described above.
1. Any remaining balances in parties' margin and LP bond accounts are moved to their general account.
1. The margin accounts and LP bond accounts for these markets are no longer required.
1. Positions can be left as open, or set to zero (this isn't important for the protocol but should be made clear on the API either way).
1. The market's insurance pool is [redistributed](./0015-market-insurance-pool-collateral.md) to the on-chain treasury for the settlement asset of the market.
1. Market status is now set to [SETTLED](./0043-market-lifecycle.md).
1. Now the market can be deleted.

Note, this mechanism does not incur fees to traders that have open positions that are settled at expiry.

### Example 2 - a less typical path of such a futures market nearing expiry

1. Market has a status of SUSPENDED and in a protective auction
1. The product's [trading terminated trigger is hit](./0016-product-builtin-future.md#41-termination-of-trading)
1. The market's status is set to [TRADING TERMINATED](./0043-market-lifecycle.md) and accepts no trading but retains the positions and margin balances that were in place after processing the trading terminated trigger. No margin recalculations or mark-to-market settlement occurs. No uncrossing of the auction.

Example 2 follows the remaining path (from the TRADING TERMINATED step) described in Example 1.


### Collateral movements

For settlement at expiry scenarios, transfers should attempt to access 
1. the trader's margin account for the market, 
1. the trader's general collateral account for that asset, 
1. the insurance pool.

Feature name: building-trader-accounts
Start date: 2019-10-01
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Acceptance Criteria
* [ ]  Every party that deposits an asset on Vega will have a _general account_ created for that asset.
*  [ ] Only one _general account_ exists per party per asset.
*  [ ] When a party deposits collateral onto Vega, the _general account_ for that asset will increase in balance by the same amount. 
*  [ ] When a party withdraws collateral onto Vega, the _general account_ for that asset will decrease in balance by the same amount. 
* [ ]  Every party that submits an order on a market will have a margin account for that market created.
* [ ]  Each party should only have one margin account per market.
* [ ] Double entry accounting is maintained at all points.
*  [ ] Only transfer requests move money between accounts.

# Summary
When a participant deposits collateral to Vega, they need a general account created for those assets.  When a trader places an order, they need a margin account for the market they have placed an order into.

# Guide-level explanation


# Reference-level explanation

## Collateral Accounts for Parties

### *General account* for an asset

Every trader will have one "main" collateral account *for each asset* that they have deposited to the Vega network. This account is referred to as a _general account_ for the trader (for that asset).   The _general account_:

    *  is where their trading profits for that asset will be eventually distributed back to. 
    * is also where the protocol searches for collateral if the trader has entered a collateral search margin zone.  
    * will be the _general account_ for all Vega markets that use that asset as the settlement asset.
    * will have it's balance increased or decreased when a party deposits or withdraws that asset from Vega.

### *Margin account* for a party 

For each market that a trader places an order on, there will need to be a _margin account_ created for the trader. The _margin account_:

*  The margin account will hold the trader's margin, which will include the unrealised PnL (or "mark to market").  When the margin account is above a certain level, the protocol should automatically transfer back to the trader's general account the excess capital.  This will naturally include when a market expires / is closed, due to the fact that this market will no longer require margin from the trader, they should receive all their funds back in their main account.

* When the _margin account's_ collateral falls below certain levels, the protocol acts in various ways to protect the network.  This includes: 

1. sending a collateral search request to the "main" collateral account for more collateral when below a certain level.
2. instantiating position resolution (which includes cancelling a trader's orders, closing trades out etc.)

NB: These actions will happen as a result of risk and settlement functions in the protocol and the implementation of these are outside the scope of this ticket.

## Nicenet Implementation

We are launching three markets for Nicenet with three different assets.  See: https://www.notion.so/vegalearn/Identify-nicenet-launch-products-a0ee41803d5b46f08abf3c80a5360b6d

When a Nicenet user is instantiated they should have 3 _general accounts_ with the three assets in them (in an amount that will be specified here: https://www.notion.so/vegalearn/Collateral-per-trader-22b7de0ff30b4375993a3f5a28f95cd2 )

When a trader puts an order into a market, they will need a margin account to exist for that market. 

# Pseudo-code / Examples

# Test cases



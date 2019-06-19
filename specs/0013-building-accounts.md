## Collateral Accounts for Traders

* Every trader will have one "main" collateral account *for each asset* that they have made a smart contract deposit to. It will also be where their trading profits for that asset will be eventually distributed back to. This account isn't scoped to a market as multiple markets may have the same settlement asset.

* For each market that a trader places an order on, there will need to be a "margin account" created for the trader. This is scoped to that market. 

* The margin account will hold the trader's margin, which will include the unrealised PnL (or "mark to market").  When the margin account is above a certain level, the protocol should automatically transfer back to the trader's general account the excess capital.  This will naturally include when a market expires / is closed, due to the fact that this market will no longer require margin from the trader, they should receive all their funds back in their main account.

* When the margin's collateral falls below certain levels, the protocol acts in various ways to protect the network.  This includes: 

1. sending a collateral search request to the "main" collateral account for more collateral when below a certain level.
2. instantiating position resolution (which includes cancelling a trader's orders, closing trades out etc.)

Note, these actions should all occur via transfer requests sent to the collateral engine.  The collateral engine will return a list of the ledger entries which affected that transfer request. 

### Acceptance Criteria

TODO - complete this.

* [ ]  Every party that deposits collateral in the Vega smart contract/s will have a main collateral account created.
* [ ]  Every party that submits an order on a market will have a margin account for that market created.
* [ ]  Each party should only have one margin account per market.
* [ ]  Each party should only have one main account which holds a record of all of their balances that are net of any deployed to any market.

### Tests

TBA

## Nicenet Implementation

We are launching three markets for Nicenet with three different assets.  See: https://www.notion.so/vegalearn/Identify-nicenet-launch-products-a0ee41803d5b46f08abf3c80a5360b6d

When a Nicenet user is instantiated they should have 3 main accounts with the three assets in them (in an amount that will be specified here: https://www.notion.so/vegalearn/Collateral-per-trader-22b7de0ff30b4375993a3f5a28f95cd2 )

When a trader puts an order into a market, they will need a margin account to exist for that market. 

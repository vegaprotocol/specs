When a market is created, the collateral engine needs to create an insurance pool account for it.

The insurance pool account will be instantiated in the settlement asset/s of the market, with a balance of zero (across all asset/s).

Only transfer requests can move collateral to or from the insurance account.

When a market is finalised / closed remaining funds are distributed to other same-currency insurance pools as per white paper section 6.4.  This occurs using ledger entries to preserve double entry accounting records within the collateral engine.


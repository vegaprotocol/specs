Feature name: market-insurance-pool
Start date: 2019-02-12

# Summary
Every market will have an insurance pool that stores collateral that can be used to cover losses in case of unreasonable market events.

# Guide-level explanation

# Reference-level explanation
The insurance pool account will be instantiated in the settlement asset/s of the market, with a balance of zero (across all asset/s).

Only transfer requests can move collateral to or from the insurance account.

When a market is finalised / closed remaining funds are distributed to other same-currency insurance pools as per white paper section 6.4.  This occurs using ledger entries to preserve double entry accounting records within the collateral engine.

# Pseudo-code / Examples

# Test cases



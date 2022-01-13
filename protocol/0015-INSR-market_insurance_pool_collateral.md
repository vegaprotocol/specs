Feature name: market-insurance-pool

# Acceptance Criteria
- [ ] When a market opens for trading, there an insurance account that is able to be used by that market for every settlement asset of that market.
- [ ] Only transfer requests move money in or out of the insurance account.
- [ ] When all markets of a risk universe expire and/or are closed, the insurance pool account has its outstanding funds transferred to the on-chain treasury.


# Summary
Every market will have at least one insurance pool account that holds collateral that can be used to cover losses in case of unreasonable market events.

# Guide-level explanation

# Reference-level explanation

Every [tradeable instrument](./0001-MKTF-market_framework.md) has one or more settlement assets defined for that market. The market requires an insurance pool account for every settlement asset of the market.

If no insurance pool account already exists in the risk universe that the tradeable instrument sits within, then an insurance pool account needs to be created for all settlement assets of the market. These new insurance pool accounts will be instantiated in the settlement asset/s of the market, with a balance of zero (across all asset/s).

Only transfer requests can move collateral to or from the insurance account.

When a market is finalised / closed remaining funds are distributed to other same-currency insurance pools as per white paper section 6.4.  This occurs using ledger entries to preserve double entry accounting records within the collateral engine.

# Pseudo-code / Examples

# Test cases



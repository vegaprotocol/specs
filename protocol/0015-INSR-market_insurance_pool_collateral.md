# Market insurance pool

## Summary

Every market will have at least one insurance pool account that holds collateral that can be used to cover losses in case of unreasonable market events.

## Guide-level explanation

## Reference-level explanation

Every [tradable instrument](./0001-MKTF-market_framework.md) has one or more settlement assets defined for that market. The market requires an insurance pool account for every settlement asset of the market.

If no insurance pool account already exists in the risk universe that the tradable instrument sits within, then an insurance pool account needs to be created for all settlement assets of the market. These new insurance pool accounts will be instantiated in the settlement asset/s of the market, with a balance of zero (across all assets).

Only transfer requests can move collateral to or from the insurance account.

When a market is finalised / closed remaining funds are distributed equally among other same-currency insurance pools (including the on-chain treasury for the asset, if no such treasury exists it gets created at this point). This occurs using ledger entries to preserve double entry accounting records within the collateral engine.

## Acceptance Criteria

- When a market proposal gets accepted and the opening auction commences, there is an insurance account that is available for use by that market for the settlement asset of that market and its balance is zero. (<a name="0015-INSR-001" href="#0015-INSR-001">0015-INSR-001</a>)
- After the market enters transitions from "trading terminated state" to "settled" state (see [market lifecyle](0043-MKTL-market_lifecycle.md)), and `network.liquidity.successorLaunchWindowLength` has elapsed from the settlement time, the insurance pool account has its balance[redistributed](./0015-INSR-market_insurance_pool_collateral.md) to the on-chain treasury for the settlement asset of the market and other insurance pools using the same asset. (<a name="0015-INSR-002" href="#0015-INSR-002">0015-INSR-002</a>)
- The [insurance pool feature test](https://github.com/vegaprotocol/vega/blob/develop/core/integration/features/verified/0015-INSR-insurance_pool_balance_test.feature) is passing. (<a name="0015-INSR-003" href="#0015-INSR-003">0015-INSR-003</a>)

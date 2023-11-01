# Insurance pools

## Market insurance pool

Every market will have at least one insurance pool account that holds collateral that can be used to cover losses in case of unreasonable market events.

Every [tradable instrument](./0001-MKTF-market_framework.md) has one or more settlement assets defined for that market. The market requires an insurance pool account for every settlement asset of the market.

If no insurance pool account already exists in the risk universe that the tradable instrument sits within, then an insurance pool account needs to be created for all settlement assets of the market. These new insurance pool accounts will be instantiated in the settlement asset/s of the market, with a balance of zero (across all assets).

Only transfer requests can move collateral to or from the market's insurance account.

When a market is finalised / closed remaining funds are distributed equally among other same-currency insurance pools (including the on-chain treasury for the asset, if no such treasury exists it gets created at this point). This occurs using ledger entries to preserve double entry accounting records within the collateral engine.

## Global insurance pool

One global insurance pool per each of the settlement asset in which markets were terminated with remaining market-level insurance pool funds exists. It receives a portion of the funds from market's insurance pool upon its closure (funds get distributed equally between the global insurance pool and remaining active markets using the same settlement asset, e.g. if there are 4 such markets then the global insurance pool receives 1/5 of the funds).

Global insurance pool is not included in the margin search process when party is insolvent - only the insurance pool of the market in which the insolvent party's liabilities are considered gets searched, if funds therein are insufficient then the remaining shortfall gets dealt with using loss socialisation.

Funds can only be withdrawn from the global insurance pool via a [governance initiated transfer](./0028-GOVE-governance.md).

## Acceptance Criteria

- When a market proposal gets accepted and the opening auction commences, there is an insurance account that is available for use by that market for the settlement asset of that market and its balance is zero. (<a name="0015-INSR-001" href="#0015-INSR-001">0015-INSR-001</a>)
- After the market enters transitions from "trading terminated state" to "settled" state (see [market lifecyle](0043-MKTL-market_lifecycle.md)), and `market.liquidity.successorLaunchWindowLength` has elapsed from the settlement time, the insurance pool account has its balance[redistributed](./0015-INSR-market_insurance_pool_collateral.md) to the on-chain treasury for the settlement asset of the market and other insurance pools using the same asset. (<a name="0015-INSR-002" href="#0015-INSR-002">0015-INSR-002</a>)
- The [insurance pool feature test](https://github.com/vegaprotocol/vega/blob/develop/core/integration/features/verified/0015-INSR-insurance_pool_balance_test.feature) is passing. (<a name="0015-INSR-003" href="#0015-INSR-003">0015-INSR-003</a>)
- When global insurance pool has positive balance for the settlement asset used by market with insolvent party, and that market's insurance pool has insufficient balance to cover the shortfall, the global insurance pool balance does NOT get used and the remaining balances are dealt with using the loss socialisation mechanism. (<a name="0015-INSR-004" href="#0015-INSR-004">0015-INSR-004</a>)

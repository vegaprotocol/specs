# Network wide limits

This spec describes network wide limits aimed at keeping the overall system performant and responsive.
Vega has been designed with low-latency in mind so that the responsiveness of the network doesn't unduly impact the trading experience. Furthermore, the current implementation relies on an interplay between the execution layer (`core`) and the data consumption layer (`data node`). For these reasons limits allowing to exercise a degree of control over the computational and data generation loads need to be put in place. These limits need to be adjustable so that each network/shard can be setup for maximum accessibility (hardware constraints permitting) while preserving the desirable user experience and system stability, and mitigating the possibility of a malicious actor trying to deliberately disrupt the system by flooding it with superfluous requests.

## Pegged orders on a market

Introduce a new network parameter `limits.markets.maxPeggedOrders` controlling the maximum number of pegged orders that can be active across all active markets.
Default value: `1,500`.

### Change of `limits.markets.maxPeggedOrders` network parameter

If the network parameter gets increased via a governance vote no further actions are needed.
If it gets decreased below the current total number of pegged orders across all active markets then no further actions are needed. Specifically: all pegged orders already present in the markets remain unaffected, but no new pegged orders are allowed until the **total pegged order count** drops below the new limit.

[Liquidity provision orders](./0038-OLIQ-liquidity_provision_order_type.md) do not get counted towards the limit.

## Acceptance Criteria

### Pegged order tests

- Attempt to place an additional pegged order by a party already active in the market when the number of pegged orders on the book is equal to `limits.markets.maxPeggedOrders` results in a rejection. Error message attributes the rejection to the limit. (<a name="0078-NWLI-001" href="#0078-NWLI-001">0078-NWLI-001</a>)
- Attempt to place a pegged order by a new party in a new market when the number of pegged orders on the book is equal to `limits.markets.maxPeggedOrders` results in a rejection. Error message attributes the rejection to the limit. (<a name="0078-NWLI-002" href="#0078-NWLI-002">0078-NWLI-002</a>)
- Lowering `limits.markets.maxPeggedOrders` to the number number of pegged orders on the book minus 2 results in no changes to the order book composition. Once 2 of the orders get filled and 1 gets cancelled in one market it is possible to successfully submit one additional pegged order in any of the active markets. (<a name="0078-NWLI-003" href="#0078-NWLI-003">0078-NWLI-003</a>)
- When the limit is reached [API](./0020-APIS-core_api.md#network-wide-limits) correctly indicates that. (<a name="0078-NWLI-004" href="#0078-NWLI-004">0078-NWLI-004</a>)

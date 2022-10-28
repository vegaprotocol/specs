# Network wide limits

This spec describes network wide limits aimed at keeping the overall system performant and responsive.
Vega has been designed with low-latency in mind so that the responsiveness of the network doesn't unduly impact the trading experience. Furthermore, the current implementation relies on an interplay between the execution layer (`core`) and the data consumption layer (`data node`). For these reasons limits allowing to exercise a degree of control over the computational and data generation loads need to be put in place. These limits need to be adjustable so that each network/shard can be setup for maximum accessibility (hardware constraints permitting) while preserving the desirable user experience and system stability, and mitigating the possibility of a malicious actor trying to deliberately disrupt the system by flooding it with superfluous requests.

## Number of markets

Introduce a new network parameter `limits.markets.max` controlling the maximum number of markets allowed within a network.\
Default value: `50`.

Each market in a `Pending` [state](./0043-MKTL-market_lifecycle.md) should increment the **total market count** by 1. If a market reaches a `Rejected`, `Cancelled`, `Closed` or `Settled` state the total market count should be decremented by 1.
As soon as the total market count reaches the value specified by `limits.markets.max` parmeter no other further market proposals should be accepted. Any markets in a `Proposed` state at that stage they should get rejected. If the total market count drops below `limits.markets.max` the network should start accepting market proposals again.

### Change of network parameter

If the network parameter gets increased via a governance vote no further actions are needed.\
If it gets decreased below the current total market count then no further actions are needed. Specifically: all existing markets continue functioning in their respective states, but no further proposals are accepted until the count drops below the new limit.

## Parties in a market

Introduce a new network parameter `limits.markets.maxParties` controlling the maximum number of parties allowed within any given market. Default value: `100,000`.

A party gets counted towards the limit if it has either open orders or open positions in the market. Once party has no open orders and no open positions it gets removed from a **total party count** within the market. Once the limit gets reached the market accepts no further orders from parties that are not already in the market.
Once the total party count drops below the limit market accepts orders from any party again (provided its [state](./0043-MKTL-market_lifecycle.md#market-lifecycle-statuses) allows that).

The limit does not apply to liquidity providers.

### Change of network parameter

If the network parameter gets increased via a governance vote no further actions are needed.\
If it gets decreased below the current total party count in any given market then no further actions are needed. Specifically: all parties in that market remain unaffected (their positions and orders remain open), but no new parties are allowed to participate in the market until the total party count drops below the new limit.

## Limit orders on a book

Introduce a new network parameter `limits.markets.maxLimitOrders` controlling the maximum number of limit orders that can rest on a book in any given market.\
Default value: `1,000,000`.

A limit order of arbitrary volume which gets placed on the book (doesn't trade in full on entry) contributes +1 to the count. If an order already on the book gets cancelled or filled in full (so that it's remaining size is 0) the count should be decreased by 1. If the count reaches `limits.markets.maxLimitOrders` limit orders can still be submitted, but:

* if the order is aggressive (results in a trade) the trade proceeds as normal,
* if the order or its part is passive (it doesn't match in full on entry to the matching engine) and would get added to the order book (it's a persistent order) it gets rejected.

Pegged orders and [liquidity provision orders](./0038-OLIQ-liquidity_provision_order_type.md) do not get counted towards the limit.

### Change of network parameter

If the network parameter gets increased via a governance vote no further actions are needed.\
If it gets decreased below the current total number of orders on the book in any given market then no further actions are needed. Specifically: all open orders in that market remain unaffected, but no new orders are allowed until the **total open order count** drops below the new limit.

## Pegged orders on a market

Introduce a new network parameter `limits.markets.maxPeggedOrders` controlling the maximum number of pegged orders that can be active in any given market.\
Default value: `10,000`.

### Change of network parameter

If the network parameter gets increased via a governance vote no further actions are needed.\
If it gets decreased below the current total number of orders on the book in any given market then no further actions are needed. Specifically: all pegged orders already present in that market remain unaffected, but no new pegged orders are allowed until the **total pegged order count** drops below the new limit.

[Liquidity provision orders](./0038-OLIQ-liquidity_provision_order_type.md) do not get counted towards the limit.

## LP order shapes

Each [LP order shape](./0038-OLIQ-liquidity_provision_order_type.md#how-they-are-submitted) has a hardcoded limit of at most 20 entries (offsets).

## LPs in a market

Introduce a new network parameter `limits.markets.maxLPs` controlling the maximum number of liquidity providers that can be active in any market.\
Default value: `1000`.

Each liquidity provider that successfully submits a liquidity provision transaction for a given market gets counted towards the **active LP count** for that market. When an LP in a given market reduces their commitment amount to 0 or gets closed out the LP count for that market gets decremented by 1.

Once the active LP count in a given market reaches the limit only the LP transactions with commitment amount larger then the lowest commitment already active in that market are accepted. If such a situation occurs the existing LP commitment with the lowest value which has been in the market the shortest should get forcibly cancelled.\
Once the count drops below the limit the LP commitments from any party submitting a valid commitment transaction are accepted again.

### Change of network parameter

If the network parameter gets increased via a governance vote no further actions are needed.\
If it gets decreased below the current total number of LPs in the market then no further actions are needed. Specifically: all LPs active in the market remain unaffected, however no new liquidity provisions are accepted until the total LP count drops below the new limit.

## Acceptance Criteria

### Markets

* Attempt to submit a new market proposal when the number of markets in a `Pending` and `Active` state is equal to `limits.markets.max` results in a rejection of the proposal. Error message attributes the rejection to the limit. (<a name="0078-NWLI-001" href="#0078-NWLI-001">0078-NWLI-001</a>)
* Once one of the markets from the above AC reaches a `Settled` state a new market proposal gets accepted and the proposed market reaches a `Pending` state. (<a name="0078-NWLI-002" href="#0078-NWLI-002">0078-NWLI-002</a>)
* Lowering `limits.markets.max` to the number number of markets in a `Pending` and `Active` minus 2 results in no changes to the number of markets. Markets in a `Pending` state successfully exit the opening auction and continue in an `Active` state. Once 3 of the `Active` markets reach a `Settled` state a single new market proposal gets accepted and the proposed market reaches a `Pending` state. (<a name="0078-NWLI-003" href="#0078-NWLI-003">0078-NWLI-003</a>)

### Parties

* Attempt to place a market order when the number of parties with active orders and/or positions in the market is at `limits.markets.maxParties` results in a rejection. Error message attributes the rejection to the limit. (<a name="0078-NWLI-004" href="#0078-NWLI-004">0078-NWLI-004</a>)
* Reaching a limit in one of the markets doesn't affect the ability to place the orders in other markets which are still below the limit. (<a name="0078-NWLI-005" href="#0078-NWLI-005">0078-NWLI-005</a>)
* Lowering `limits.markets.maxParties` to the number number of parties in the market with open orders and/or positions minus 2 results in no changes to the number of active parties or their orders/positions. Once 2 of the parties active in the market with no positions cancel their orders and 1 party with a position closes it out and is left without any orders a single new party can enter the market. The parties that left the market now cannot re-enter it as the limit is now reached. (<a name="0078-NWLI-006" href="#0078-NWLI-006">0078-NWLI-006</a>)
* When the limit is reached in the market the [market data](./0021-MDAT-market_data_spec.md) API correctly indicates that. (<a name="0078-NWLI-021" href="#0078-NWLI-021">0078-NWLI-021</a>)

### Limit orders

* Attempt to place an additional limit order by a party already active in the market when the number of orders on the book is equal to `limits.markets.maxLimitOrders` results in a rejection. Error message attributes the rejection to the limit. (<a name="0078-NWLI-007" href="#0078-NWLI-007">0078-NWLI-007</a>)
* Reaching a limit in one of the markets doesn't affect the ability to place the orders in other markets which are still below the limit. (<a name="0078-NWLI-008" href="#0078-NWLI-008">0078-NWLI-008</a>)
* Lowering `limits.markets.maxLimitOrders` to the number number of limit orders on the book minus 2 results in no changes to the order book composition. Once 2 of the orders get filled and 1 gets cancelled it is possible to successfully submit one additional limit order (<a name="0078-NWLI-009" href="#0078-NWLI-009">0078-NWLI-009</a>)
* Once market has reached `limits.markets.maxLimitOrders` a [batch transaction](./0074-BTCH-batch-market-instructions.md) with 1 cancellation, 1 amendent and 1 submission succeeds in full (<a name="0078-NWLI-010" href="#0078-NWLI-010">0078-NWLI-0010</a>)
* When the limit is reached in the market the [market data](./0021-MDAT-market_data_spec.md) API correctly indicates that. (<a name="0078-NWLI-022" href="#0078-NWLI-022">0078-NWLI-022</a>)

### Pegged orders

* Attempt to place an additional pegged order by a party already active in the market when the number of pegged orders on the book is equal to `limits.markets.maxPeggedOrders` results in a rejection. Error message attributes the rejection to the limit. (<a name="0078-NWLI-011" href="#0078-NWLI-011">0078-NWLI-011</a>)
* Reaching a limit in one of the markets doesn't affect the ability to place the orders in other markets which are still below the limit. (<a name="0078-NWLI-012" href="#0078-NWLI-012">0078-NWLI-012</a>)
* Lowering `limits.markets.maxPeggedOrders` to the number number of pegged orders on the book minus 2 results in no changes to the order book composition. Once 2 of the orders get filled and 1 gets cancelled it is possible to successfully submit one additional pegged order (<a name="0078-NWLI-013" href="#0078-NWLI-013">0078-NWLI-013</a>)
* When the limit is reached in the market the [market data](./0021-MDAT-market_data_spec.md) API correctly indicates that. (<a name="0078-NWLI-023" href="#0078-NWLI-023">0078-NWLI-023</a>)

### LP order shapes

* Submitting a [liquidity provision order](./0038-OLIQ-liquidity_provision_order_type.md) with 20 buy shapes and 20 sell shapes proceeds without any errors and liquidity provision becomes active. (<a name="0078-NWLI-014" href="#0078-NWLI-014">0078-NWLI-014</a>)
* Submitting a liquidity provision order with 21 buy shapes and 20 sell shapes results in a failure. Error message attributes the rejection to the limit. (<a name="0078-NWLI-015" href="#0078-NWLI-015">0078-NWLI-015</a>)
* Submitting a liquidity provision order with 20 buy shapes and 21 sell shapes results in a failure. Error message attributes the rejection to the limit. (<a name="0078-NWLI-016" href="#0078-NWLI-016">0078-NWLI-016</a>)

### LPs

* Attempt to place an additional liquidity provision with valid commitment amount below the lowest one in the market when the number of liquidity provisions in the market is equal to `limits.markets.maxLPs` results in a rejection. Error message attributes the rejection to the limit. (<a name="0078-NWLI-017" href="#0078-NWLI-017">0078-NWLI-017</a>)
* When market is in continuous trading and `limits.markets.maxLPs` is reached then submitting a new liquidity provision order with commitment amount higher than the lowest commitment active in the market results in a success and a forced cancellation of the lowest and shortest-lived commitment in the market.(<a name="0078-NWLI-018" href="#0078-NWLI-018">0078-NWLI-018</a>)
* When market is in liquidity monitoring auction and `limits.markets.maxLPs` is reached then submitting a new liquidity provision order with commitment amount higher than the lowest commitment active and in the market results in a success and a forced cancellation of the lowest and shortest-lived commitment in the market. The amount submitted should be such that the market can now leave the liquidity auction and go back to continuous trading mode.(<a name="0078-NWLI-019" href="#0078-NWLI-019">0078-NWLI-019</a>)
* Reaching a limit in one of the markets doesn't affect the ability to place the orders with any valid commitment amount in other markets which are still below the limit. (<a name="0078-NWLI-020" href="#0078-NWLI-020">0078-NWLI-020</a>)
* Lowering `limits.markets.maxLPs` to the number number of active liquidity provisions in the market minus 2 results in no changes to the order book composition. Once 2 of the LPs cancel their commitments and 1 gets closed out it is possible to successfully submit one additional liquidity provision order (<a name="0078-NWLI-020" href="#0078-NWLI-020">0078-NWLI-020</a>)
* When the limit is reached in the market the [market data](./0021-MDAT-market_data_spec.md) API correctly indicates that. (<a name="0078-NWLI-024" href="#0078-NWLI-024">0078-NWLI-024</a>)

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
Once the total party count drops below the limit market accepts orders from any party again (provided its [state](./0043-MKTL-market_lifecycle.md) allows that).

The limit does not apply to liquidity providers.

### Change of network parameter

If the network parameter gets increased via a governance vote no further actions are needed.\
If it gets decreased below the current total party count in any given market then no further actions are needed. Specifically: all parties in that market remain unaffected (their positions and orders remain open), but no new parties are allowed to participate in the market until the total party count drops below the new limit.

## Limit orders on a book

Introduce a new network parameter `limits.markets.maxLimitOrders` controlling the maximum number of limit orders that can rest on a book in any given market.\
Default value: `1,000,000`.

A limit order of arbitrary volume which gets placed on the book (doesn't trade in full on entry) contributes +1 to the count. If an order already on the book gets cancelled or filled in full (so that it's remaining size is 0) the count should be decreased by 1. If the count reaches `limits.markets.maxLimitOrders` limit orders can still be submitted, but:

* if the order is aggressive (results in a trade) the trade proceeds as normal,
* if the order is passive (it doesn't match on entry) and would get added to the order book (it's a persistent order) it gets rejected.

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

* (<a name="0078-NWLI-001" href="#0078-NWLI-001">0078-NWLI-001</a>)

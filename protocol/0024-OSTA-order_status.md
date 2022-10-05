Feature name: order-status

# Summary
Orders have a status field. This specification details a set of situations and the expected status for an order.

# Reference-level explanation
For the definition of each Time In Force option, see [the Order Types spec](./0014-ORDT-order_types.md#time-in-force--validity)

## Parked orders
Pegged orders can be parked under certain circumstances:
- When a market moves in to an auction
- When a pegged orders need to be repriced and can't be
- When a reference for a pegged order does not exist

For a full outline of these behaviours, see [0037-OPEG-pegged_orders](./0037-OPEG-pegged_orders.md#guide-level-explanation). When an order has a status of parked:

- Only pegged orders can be parked
- Parked pegged orders are inactive - i.e. are not on the book and will never match.
- Parked pegged orders can be [amended](./0004-AMND-amends.md) as normal
- Parked pegged orders can [cancelled](./0033-OCAN-cancel_orders.md) as normal (see [0068-MATC](./0068-MATC-matching_engine.md#0068-MATC-033))
- If the market is in continuous trading, pegged orders are repriced as normal

## All order types
* Orders can have a status of REJECTED if there is insufficient margin to place the order
* [Order Pricing methods](./0014-ORDT-order_types.md) are not listed below as they don't change the status outcome
* `Stopped` and `Cancelled` are used to determine whether an order was closed as a result of a user action (`Cancelled`) or by the system (`Stopped`) as a result of, for example, insufficient margin (see [Position Resolution](./0012-POSR-position_resolution.md#position-resolution-algorithm))
* A pegged order that is unable to reprice or during an auction will have a status of PARKED. This indicates that the order in not on the order book but can re-enter it once the conditions change

## Wash trading
If, during continuous trading, an order would be filled or partially filled with an existing order from the same [party](./0017-PART-party.md) aka "wash" trade, the order is rejected. Any existing fills that happen before the wash trade is identified will be kept. FOK rules still apply for wash trading so if a wash trade is identified before the full amount of the order is complete, the order will be stopped and nothing filled.
Wash trading is allowed on [auction](0026-AUCT-auctions.md) uncrossing. 

| Filled State | Resulting status | Reason |
|--------------|------------------|--------|
|   Unfilled   |     Stopped     | Order would match with an order with the same partyID |
|   Partially  |     Partially Filled     | Order has been partially filled but the next partial fill would be with an order with the same partyID |

# Acceptance Criteria

## Fill or Or Kill (<a name="0024-OSTA-001" href="#0024-OSTA-001">0024-OSTA-001</a>)
| Time In Force | Filled | Resulting status |
|---------------|--------|------------------|
|      FOK      |   No   |      Stopped     |
|      FOK      |   Yes  |      Filled      |


## Immediate Or Cancel (<a name="0024-OSTA-002" href="#0024-OSTA-002">0024-OSTA-002</a>)
| Time In Force | Filled  | Resulting status |
|---------------|---------|------------------|
|      IOC      |    No   |      Stopped     |
|      IOC      | Partial |      Partially Filled      |
|      IOC      |   Yes   |  Filled |


## Good ’Til Cancelled (<a name="0024-OSTA-003" href="#0024-OSTA-003">0024-OSTA-003</a>)
| Time In Force | Filled  | Cancelled by user | Stopped by system | Resulting status |
|---------------|---------|-------------------|-------------------|------------------|
|      GTC      |    No   |         No        |         No        |      Active      |
|      GTC      |    No   |         No        |        Yes        |      Rejected     |
|      GTC      |    No   |        Yes        |         No        |     Cancelled    |
|      GTC      | Partial |         No        |         No        |      Active      |
|      GTC      | Partial |        Yes        |         No        |     Cancelled    |
|      GTC      | Partial |         No        |        Yes        |      Rejected     |
|      GTC      |   Yes   |         No        |         No        |      Filled      |

## Good ’Til Time (<a name="0024-OSTA-004" href="#0024-OSTA-004">0024-OSTA-004</a>)

| Time In Force | Filled  | Expired | Cancelled by user | Stopped by system | Resulting status |
|---------------|---------|---------|-------------------|-------------------|------------------|
|      GTT      |    No   |    No   |         No        |         No        |      Active      |
|      GTT      |    No   |   Yes   |         No        |         No        |      Expired     |
|      GTT      |    No   |    No   |        Yes        |         No        |     Cancelled    |
|      GTT      |    No   |    No   |         No        |        Yes        |      Stopped     |
|      GTT      | Partial |    No   |         No        |         No        |      Active      |
|      GTT      | Partial |   Yes   |         No        |         No        |      Expired     |
|      GTT      | Partial |    No   |        Yes        |         No        |     Cancelled    |
|      GTT      | Partial |    No   |         No        |        Yes        |      Stopped     |
|      GTT      |   Yes   |    No   |         No        |         No        |      Filled      |
|      GTT      |   Yes   |   Yes   |         No        |         No        | not possible (see note) |

Note: The last row in the table above is added for clarity. If the order was filled, it is marked as Filled and it is removed from the book, so it can't expire after being filled.

## Wash trading ACs 
- If, during continuous trading, an order would be filled or partially filled with an existing order from the same [party](./0017-PART-party.md) aka "wash" trade, the order is rejected. The reason for rejection should be clear on the order status: "rejected to prevent a wash trade". (<a name="0024-OSTA-005" href="#0024-OSTA-005">0024-OSTA-005</a>)
- Any existing fills that happen before the wash trade is identified will be kept. The order should be market both "partially filled" and "rejected to prevent wash trade" (<a name="0024-OSTA-006" href="#0024-OSTA-006">0024-OSTA-006</a>)
- FOK rules still apply for wash trading so if a wash trade is identified before the full amount of the order is complete, the order will be stopped and nothing filled. (<a name="0024-OSTA-007" href="#0024-OSTA-007">0024-OSTA-007</a>)
- Wash trading is allowed on [auction](0026-AUCT-auctions.md) uncrossing. (<a name="0024-OSTA-008" href="#0024-OSTA-008">0024-OSTA-008</a>)


## Impact of order types on settlement
- Test that market settlement cashflows only depend on parties positions and is independent of what order types there are on the book. (<a name="0024-OSTA-009" href="#0024-OSTA-009">0024-OSTA-009</a>) 
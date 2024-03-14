# Order status

## Summary

Orders have a status field. This specification details a set of situations and the expected status for an order.

## Reference-level explanation

For the definition of each Time In Force option, see [the Order Types spec](./0014-ORDT-order_types.md#time-in-force--validity)

### Parked orders

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

### All order types

- Orders can have a status of REJECTED if there is insufficient margin to place the order
- [Order Pricing methods](./0014-ORDT-order_types.md) are not listed below as they don't change the status outcome
- `Stopped` and `Cancelled` are used to determine whether an order was closed as a result of a user action (`Cancelled`) or by the system (`Stopped`) as a result of, for example, insufficient margin (see [Position Resolution](./0012-POSR-position_resolution.md#position-resolution-algorithm))
- A pegged order that is unable to reprice or during an auction will have a status of PARKED. This indicates that the order in not on the order book but can re-enter it once the conditions change

### Wash trading

If, during continuous trading, an order would be filled or partially filled with an existing order from the same [party](./0017-PART-party.md) aka "wash" trade, the order is rejected. Any existing fills that happen before the wash trade is identified will be kept. FOK rules still apply for wash trading so if a wash trade is identified before the full amount of the order is complete, the order will be stopped and nothing filled.
Wash trading is allowed on [auction](0026-AUCT-auctions.md) uncrossing.

| Filled State | Resulting status | Reason |
|--------------|------------------|--------|
|   Unfilled   |     Stopped     | Order would match with an order with the same `partyID` |
|   Partially  |     Partially Filled     | Order has been partially filled but the next partial fill would be with an order with the same `partyID` |

## Acceptance Criteria

### Fill or Or Kill (<a name="0024-OSTA-001" href="#0024-OSTA-001">0024-OSTA-001</a>)

For product spot: (<a name="0024-OSTA-030" href="#0024-OSTA-030">0024-OSTA-030</a>)

| Time In Force | Filled | Resulting status |
|---------------|--------|------------------|
|      FOK      |   No   |      Stopped     |
|      FOK      |   Yes  |      Filled      |

### Immediate Or Cancel (<a name="0024-OSTA-002" href="#0024-OSTA-002">0024-OSTA-002</a>)

For product spot: (<a name="0024-OSTA-031" href="#0024-OSTA-031">0024-OSTA-031</a>)

| Time In Force | Filled  | Resulting status |
|---------------|---------|------------------|
|      IOC      |    No   |      Stopped     |
|      IOC      | Partial |      Partially Filled      |
|      IOC      |   Yes   |  Filled |

### Good ’Til Cancelled (<a name="0024-OSTA-003" href="#0024-OSTA-003">0024-OSTA-003</a>)

For product spot: (<a name="0024-OSTA-032" href="#0024-OSTA-032">0024-OSTA-032</a>)

| Time In Force | Filled  | Cancelled by user | Stopped by system | Resulting status |
|---------------|---------|-------------------|-------------------|------------------|
|      GTC      |    No   |         No        |         No        |      Active      |
|      GTC      |    No   |         No        |        Yes        |      Rejected     |
|      GTC      |    No   |        Yes        |         No        |     Cancelled    |
|      GTC      | Partial |         No        |         No        |      Active      |
|      GTC      | Partial |        Yes        |         No        |     Cancelled    |
|      GTC      | Partial |         No        |        Yes        |      Rejected     |
|      GTC      |   Yes   |         No        |         No        |      Filled      |

### Good ’Til Time (<a name="0024-OSTA-004" href="#0024-OSTA-004">0024-OSTA-004</a>)

For product spot: (<a name="0024-OSTA-033" href="#0024-OSTA-033">0024-OSTA-033</a>)

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

### Wash trading Acceptance Criteria

- If, during continuous trading, an order would be filled or partially filled with an existing order from the same [party](./0017-PART-party.md) aka "wash" trade, the order is rejected. The reason for rejection should be clear on the order status: "rejected to prevent a wash trade". (<a name="0024-OSTA-005" href="#0024-OSTA-005">0024-OSTA-005</a>). For product spot: (<a name="0024-OSTA-034" href="#0024-OSTA-034">0024-OSTA-034</a>)
- Any existing fills that happen before the wash trade is identified will be kept. The order should be market both "partially filled" and "rejected to prevent wash trade" (<a name="0024-OSTA-006" href="#0024-OSTA-006">0024-OSTA-006</a>). For product spot: (<a name="0024-OSTA-035" href="#0024-OSTA-035">0024-OSTA-035</a>)
- FOK rules still apply for wash trading so if a wash trade is identified before the full amount of the order is complete, the order will be stopped and nothing filled. (<a name="0024-OSTA-007" href="#0024-OSTA-007">0024-OSTA-007</a>). For product spot: (<a name="0024-OSTA-036" href="#0024-OSTA-036">0024-OSTA-036</a>)
- Wash trading is allowed on [auction](0026-AUCT-auctions.md) uncrossing. (<a name="0024-OSTA-008" href="#0024-OSTA-008">0024-OSTA-008</a>). For product spot: (<a name="0024-OSTA-037" href="#0024-OSTA-037">0024-OSTA-037</a>)

### Impact of order types on settlement

- Test that market settlement cashflows only depend on parties positions and is independent of what order types there are on the book. (<a name="0024-OSTA-009" href="#0024-OSTA-009">0024-OSTA-009</a>)

### Reject reasons

- Order reason of `ORDER_ERROR_INSUFFICIENT_ASSET_BALANCE` is given if a position is closed out because they do now have enough margin to cover the position (<a name="0024-OSTA-010" href="#0024-OSTA-010">0024-OSTA-010</a>)
- Order reason of `ORDER_ERROR_MARGIN_CHECK_FAILED` is given if a new order is placed and the user does not have enough collateral to cover the initial margin requirements (<a name="0024-OSTA-011" href="#0024-OSTA-011">0024-OSTA-011</a>)
- Order reason of `ORDER_ERROR_NON_PERSISTENT_ORDER_OUT_OF_PRICE_BOUNDS` when a non persistent order would cause the price to move outside of the price bounds (<a name="0024-OSTA-012" href="#0024-OSTA-012">0024-OSTA-012</a>). For product spot: (<a name="0024-OSTA-038" href="#0024-OSTA-038">0024-OSTA-038</a>)
- Order reason of `ORDER_ERROR_GFN_ORDER_DURING_AN_AUCTION` when the market is in auction and a GFN order is sent in (<a name="0024-OSTA-013" href="#0024-OSTA-013">0024-OSTA-013</a>). For product spot: (<a name="0024-OSTA-039" href="#0024-OSTA-039">0024-OSTA-039</a>)
- Order reason of `ORDER_ERROR_CANNOT_SEND_IOC_ORDER_DURING_AUCTION` when trying to send an IOC order during auction (<a name="0024-OSTA-014" href="#0024-OSTA-014">0024-OSTA-014</a>).. For product spot: (<a name="0024-OSTA-040" href="#0024-OSTA-040">0024-OSTA-040</a>)
- Order reason of `ORDER_ERROR_CANNOT_SEND_FOK_ORDER_DURING_AUCTION` when trying to send a FOK order during auction (<a name="0024-OSTA-015" href="#0024-OSTA-015">0024-OSTA-015</a>). For product spot: (<a name="0024-OSTA-041" href="#0024-OSTA-041">0024-OSTA-041</a>)
- Order reason of `ORDER_ERROR_GFA_ORDER_DURING_CONTINUOUS_TRADING` when trying to send a GFA order during normal trading (<a name="0024-OSTA-016" href="#0024-OSTA-016">0024-OSTA-016</a>). For product spot: (<a name="0024-OSTA-042" href="#0024-OSTA-042">0024-OSTA-042</a>)
- Order reason of `ORDER_ERROR_INVALID_EXPIRATION_DATETIME` when sending a GTT with the expiry is before the creation time (<a name="0024-OSTA-017" href="#0024-OSTA-017">0024-OSTA-017</a>). For product spot: (<a name="0024-OSTA-043" href="#0024-OSTA-043">0024-OSTA-043</a>)
- Order reason of `ORDER_ERROR_MARKET_CLOSED` when trying to send an order when the market is closed (<a name="0024-OSTA-018" href="#0024-OSTA-018">0024-OSTA-018</a>). For product spot the transaction result will be `Invalid Market ID` instead (<a name="0024-OSTA-044" href="#0024-OSTA-044">0024-OSTA-044</a>) 
- Order reason of `ORDER_ERROR_INVALID_MARKET_ID` when sending an order with an invalid market ID (<a name="0024-OSTA-020" href="#0024-OSTA-020">0024-OSTA-020</a>). For product spot: (<a name="0024-OSTA-046" href="#0024-OSTA-046">0024-OSTA-046</a>)
- Order reason of `ORDER_ERROR_MUST_BE_LIMIT_ORDER` when sending a pegged order that is not a LIMIT order (<a name="0024-OSTA-021" href="#0024-OSTA-021">0024-OSTA-021</a>)
- Order reason of `ORDER_ERROR_MUST_BE_GTT_OR_GTC` pegged order must be either GTC or GTT (<a name="0024-OSTA-022" href="#0024-OSTA-022">0024-OSTA-022</a>)
- Order reason of `ORDER_ERROR_WITHOUT_REFERENCE_PRICE` pegged order must have a reference field (<a name="0024-OSTA-023" href="#0024-OSTA-023">0024-OSTA-023</a>)
- Order reason of `ORDER_ERROR_BUY_CANNOT_REFERENCE_BEST_ASK_PRICE` buy pegged order cannot reference the ask price (<a name="0024-OSTA-024" href="#0024-OSTA-024">0024-OSTA-024</a>)
- Order reason of `ORDER_ERROR_OFFSET_MUST_BE_GREATER_THAN_ZERO` pegged order offset must be > 0 when referencing `MID` price (<a name="0024-OSTA-025" href="#0024-OSTA-025">0024-OSTA-025</a>)
- Order reason of `ORDER_ERROR_SELL_CANNOT_REFERENCE_BEST_BID_PRICE` sell pegged order cannot reference the bid price (<a name="0024-OSTA-026" href="#0024-OSTA-026">0024-OSTA-026</a>)
- Order reason of `ORDER_ERROR_INSUFFICIENT_ASSET_BALANCE` user does not have enough of the asset or does not have an account at all (<a name="0024-OSTA-027" href="#0024-OSTA-027">0024-OSTA-027</a>). For product spot: (<a name="0024-OSTA-047" href="#0024-OSTA-047">0024-OSTA-047</a>)
- Order reason of `ORDER_ERROR_SELF_TRADING` when the order would match with one from the same user while not in auction (<a name="0024-OSTA-029" href="#0024-OSTA-029">0024-OSTA-029</a>). For product spot: (<a name="0024-OSTA-048" href="#0024-OSTA-048">0024-OSTA-048</a>)

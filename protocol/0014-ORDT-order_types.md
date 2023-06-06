# Order types

## Summary

A market using a limit order book will permit orders of various types to be submitted depending on the market's current *trading mode* (see [Market Framework](./0001-MKTF-market_framework.md)). This specification encompasses multiple configurable aspects of an order including: triggering, time in force, price type, and execution constraints. It defines the allowable values for each, valid combinations of these, and their behaviour.

Notes on scope of current version of this spec:

- Includes only detailed specification for orders valid for *continuous trading*, does not specify behaviour of these order types in an auction.

## Guide-level explanation

### Types of order

1. **Immediate:** order is evaluated immediately (this is the default)
2. **Stop:** order is only evaluated if and when the *stop price* is reached
3. **Network:** an order triggered by the network. See [Network Orders](#network-orders)

### Order pricing methods

*Price type and associated data if required (i.e. limit price, peg reference and offset) must be explicitly provided as one of the below three options and required data, there is no default.*

1. **Limit (+ limit price):** the order is priced with a static limit price, which is the worst price (i.e. highest buy price / lowest sell price) at which the order can trade. If the order has a persistent validity type it will remain on the order book until it fully executes, expires (as defined by the specific validity type), or is cancelled.
1. **Pegged (+ reference, price offset):** the order is priced relative to a reference price in the market (i.e. best bid, mid, or best offer price) and is automatically repriced (losing time priority) when the reference price changes. Execution is as for a limit order at that price, including on entry and repricing. The order is removed from the book and 'parked' (in entry time priority) if the reference price is undefined, including during an auction. See the [Pegged Orders](./0037-OPEG-pegged_orders.md) spec for more detail.
1. **Market:** the order is not priced and will take volume at any price (i.e. equivalent to a zero priced sell order or an infinitely priced buy order). Only valid on non-persistent validity types.

### Time in Force / validity

*Time in force must be explicitly provided, there is no default.*

**Persistent:**

1. **Good 'Til Time (GTT):** order is valid until the supplied expiry time, which may be supplied either as an absolute date/time or a relative offset from the  timestamp on the order (i.e. the timestamp added by the core when it receives the order, which is deterministically the same on all nodes)
1. **Good 'Til Cancelled (GTC):** order is valid indefinitely.

**Non-persistent:**

1. **Immediate Or Cancel (IOC):** an order that trades as much of its volume as possible with passive orders already on the order book (assuming it is crossed with them) and then stops execution. It is never placed on the book even if it is not completely filled immediately, instead it is stopped/cancelled.
1. **Fill Or Kill (FOK):** an order that either trades all of its volume immediately on entry or is stopped/cancelled immediately without trading anything. That is, unless the order can be completely filled immediately, it does not trade at all. It is never placed on the book, even if it does not trade.

**Market-state:**

1. **Good For Auction (GFA):** This order will only be accepted by the system if it arrives during an auction period, otherwise it will be rejected. The order can act like either a GTC or GTT order depending on whether the `expiresAt` field is set.
2. **Good For Normal (GFN):** This order will only be accepted by the system if it arrived during normal trading, otherwise it will be rejected. Normal trading is defined as either continuous trading on a normal market or auction trading in a frequent batch auction market. The order can act like either a GTC or GTT order depending on whether the `expiresAt` field is set.

### Execution flags

1. **Post-Only (True/False):** Only valid for Limit orders. Cannot be True at the same time as Reduce-Only. If set to true, once order reaches the orderbook, this order acts identically to a limit order set at the same price. However, prior to being placed a check is run to ensure that the order will not (neither totally nor in any part) immediately cross with anything already on the book. If the order would immediately trade, it is instead immediately `Stopped` with a reason informing the trader that the order was stopped to avoid a trade occurring. As a result, placing a Post-Only order will never incur taker fees, and will not incur fees in general if executed in continuous trading. It is possible for some liquidity and infrastructure fees to be paid if the resultant limit order trades at the uncrossing of an auction, as specified in [0029-FEES](https://github.com/vegaprotocol/specs/blob/master/protocol/0029-FEES-fees.md#normal-auctions-including-market-protection-and-opening-auctions).

1. **Reduce-Only (True/False):** Only valid for Non-Persistent orders. Cannot be True at the same time as Post-Only. If set, order will only be executed if the outcome of the trade moves the trader's position closer to 0. In addition, a Reduce-Only order will not move a position to the opposite side to the trader's current position (e.g. if short, a Reduce-Only order cannot make the trader long as a result). If submitted as IOC, where the full volume would switch sides, only the amount required to move the position to 0 will be executed.


### Stop orders

In addition to normal immediately executing order, Vega should accept the submission of stop orders.
These differ from normal orders in that they sit off the order book until triggered, when they are entered as normal.
These are generally used to exit positions under pre-defined conditions, either as a "stop loss" order that controls the maximum losses a position may take, a "take profit" order that closes a position once a defined level of profit has been made, or both.
To prevent traders from "hiding" order book depth behind conditional orders, stop orders can only be used to close some or all of a trader's position, and therefore must be "reduce only" orders.

A stop order submission can be made (stop loss or take profit are probably both just called a stop order internally).

- Stop order submissions must include either a trigger price OR trailing stop distance as a % move from the reference price in addition to a normal order submission.

- Stop order submissions must include a trigger direction.
Direction may be **rises above** or **falls below**.
**Rises above** stops trigger if the last traded price is higher than the trigger level, and **falls below** stops trigger if the last traded price is lower than the trigger level.

- A stop trigger can have an optional expiry date/time.
If it has an expiry then it can be set either to cancel on expiry (i.e. it is deleted at that time) or trigger on expiry (i.e. the order wrapped in the submission is placed whether or not the trigger level is breached).

- It is possible to make a single stop order submission or an OCO (One Cancels the Other) stop order submission.
An OCO contains TWO stop order submissions, and must include one in each trigger direction.
OCOs work exactly like two separate stop orders except that if one of the pair is triggered, cancelled, deleted, or rejected, the other one is automatically cancelled.
An OCO submission allows a user to have a stop loss and take profit applied to the same amount of their position without the risk of both trading and reducing their position by more than intended.

- The stop order submission wraps a normal order submission.

- The order within the stop order submission must be reduce only.

- The submission is validated when it is received but does not initially interact with the order book unless it is triggered immediately (see below).

- If and when the trigger price is breached in the specified direction the order provided in the stop order submission is created and enters the book or trades as normal, as if it was just submitted.

- The order contained in a stop order submission is entered immediately if the trigger price is already breached on entry, except during an auction. (TODO: confirm we do this and don't just always wait for a trade price)

- When the stop order is a trailing stop, the price at which it is triggered is calculated as the defined distance as a percentage from the highest price achieved since the order was entered if the direction is to trigger on price below the specified level, or the lowest price achieved since the order was entered if the direction is to trigger above the level.
Therefore the trigger level of a stop order moves with the market allowing the trader to lock in some amount of gains.

- The order can't be triggered or trade at all during an auction (even if the current price would normally trigger it immediately on entry).

- A stop order can be entered during an auction, and can then be triggered by the auction uncrossing price if the auction results in a trade, as well as any trades (including auction uncrossing trades) after that.

- GFA is not a valid TIF for a stop order submission.

- Spam prevention:

  - Stop orders will only be accepted from keys with either a non-zero open position or at least one active order.

  - A network parameter will control the maximum number of stop orders per party (suggested initial value: between 4 and 10).

  - If the trader's position size moves to zero exactly, and they have no open orders, all stop orders will be cancelled.


### Valid order entry combinations

#### Continuous trading

| Pricing method | GTT | GTC | IOC | FOK | GFA | GFN |
| -------------- |:---:|:---:|:---:|:---:|:---:|:---:|
| Limit          | Y   | Y   | Y*  | Y*  | N   | Y   |
| Pegged         | Y   | Y   | N** | N** | N   | Y   |
| Market         | N   | N   | Y   | Y   | N   | N   |

\* IOC/FOK LIMIT orders never rest on the book, if they do not match immediately they are cancelled/stopped.<br>
\** IOC/FOK PEGGED orders are not currently supported as they will always result in the cancelled/stopped state. This may change in the future if pegged orders are allowed to have negative offsets that can result in an immediate match.

#### Auction

| Pricing method | GTT | GTC | IOC | FOK | GFA | GFN |
| -------------- |:---:|:---:|:---:|:----|:---:|:---:|
| Limit          | Y   | Y   | N   | N   | Y   | N   |
| Pegged         | Y*  | Y*  | N   | N   | Y*  | N   |
| Market         | N   | N   | N   | N   | N   | N   |

\* Pegged orders will be [parked](./0024-OSTA-order_status.md#parked-orders) if placed during [an auction](./0026-AUCT-auctions.md), with time priority preserved. See also [0024-OSTA](./0024-OSTA-order_status.md#parked-orders)<br>

### Network orders

Network orders are used during [position resolution](./0012-POSR-position_resolution.md#position-resolution-algorithm). Network orders are orders triggered by Vega to close out positions for distressed traders.

- Network orders have a counterparty of `Network`
- Network orders are a Fill Or Kill, Market orders
- Network orders cannot be submitted by any party, they are created during transaction processing.

## Acceptance Criteria

- Immediate orders, continuous trading:
  - An aggressive persistent (GTT, GTC) limit order that is not crossed with the order book is included on the order book at limit order price at the back of the queue of orders at that price. No trades are generated. (<a name="0014-ORDT-001" href="#0014-ORDT-001">0014-ORDT-001</a>)
  - An aggressive persistent (GTT, GTC) limit order that crosses with trades >= to its volume is filled completely and does not appear on the order book or in the order book volume. Trades are atomically generated for the full volume. (<a name="0014-ORDT-002" href="#0014-ORDT-002">0014-ORDT-002</a>)
  - An aggressive persistent (GTT, GTC) limit order that is partially filled generates trades commensurate with the filled volume. The remaining volume is placed on the order book at the limit order price, at the back of the queue of orders at that price. (<a name="0014-ORDT-003" href="#0014-ORDT-003">0014-ORDT-003</a>)
  - Any GTT limit order that [still] resides on the order book at its expiry time is cancelled and removed from the book before any events are processed that rely on its being present on the book, including any calculation that incorporate its volume and/or price level. (<a name="0014-ORDT-004" href="#0014-ORDT-004">0014-ORDT-004</a>)
  - A GTT order submitted at a time >= its expiry time is rejected. (<a name="0014-ORDT-005" href="#0014-ORDT-005">0014-ORDT-005</a>)
- No party can submit a [network order type](#network-orders)  (<a name="0014-ORDT-006" href="#0014-ORDT-006">0014-ORDT-006</a>)

### Stop orders

- A stop order containing both a trigger price and a trailing stop distance will be rejected.(<a name="0014-ORDT-007" href="#0014-ORDT-007">0014-ORDT-007</a>)
- A stop order with reduce only set to false will be rejected. (<a name="0014-ORDT-008" href="#0014-ORDT-008">0014-ORDT-008</a>)
- Once triggered, a stop order is removed from the book and cannot be triggered again. (<a name="0014-ORDT-009" href="#0014-ORDT-009">0014-ORDT-009</a>)
- A stop order placed by a key with a zero position and no open orders will be rejected. (<a name="0014-ORDT-010" href="#0014-ORDT-010">0014-ORDT-010</a>)
- A stop order placed by a key with a zero position but open orders will be accepted. (<a name="0014-ORDT-011" href="#0014-ORDT-011">0014-ORDT-011</a>)
- Attempting to create more stop orders than is allowed by the relevant network parameter will result in the transaction failing to execute. (<a name="0014-ORDT-012" href="#0014-ORDT-012">0014-ORDT-012</a>)

- A stop order wrapping a limit order will, once triggered, place the limit order as if it just arrived as an order without the stop order wrapping. (<a name="0014-ORDT-013" href="#0014-ORDT-013">0014-ORDT-013</a>)
- A stop order wrapping a market order will, once triggered, place the market order as if it just arrived as an order without the stop order wrapping. (<a name="0014-ORDT-014" href="#0014-ORDT-014">0014-ORDT-014</a>)

- With a last traded price at 50, a stop order placed with `Rises Above` setting at 75 will be triggered by any trade at price 75 or higher. (<a name="0014-ORDT-015" href="#0014-ORDT-015">0014-ORDT-015</a>)
- With a last traded price at 50, a stop order placed with `Rises Above` setting at 25 will be triggered immediately (before another trade is even necessary). (<a name="0014-ORDT-016" href="#0014-ORDT-016">0014-ORDT-016</a>)
- With a last traded price at 50, a stop order placed with `Falls Below` setting at 25 will be triggered by any trade at price 25 or lower. (<a name="0014-ORDT-017" href="#0014-ORDT-017">0014-ORDT-017</a>)
- With a last traded price at 50, a stop order placed with `Falls Below` setting at 75 will be triggered immediately (before another trade is even necessary). (<a name="0014-ORDT-018" href="#0014-ORDT-018">0014-ORDT-018</a>)

- With a last traded price at 50, a stop order placed with any trigger price which does not trigger immediately will trigger as soon as a trade occurs at a trigger price, and will not wait until the next mark price update to trigger. (<a name="0014-ORDT-019" href="#0014-ORDT-019">0014-ORDT-019</a>)
- A stop order with expiration time `T` set to expire at that time will expire at time `T` if reached without being triggered. (<a name="0014-ORDT-020" href="#0014-ORDT-020">0014-ORDT-020</a>)
- A stop order with expiration time `T` set to execute at that time will execute at time `T` if reached without being triggered. (<a name="0014-ORDT-021" href="#0014-ORDT-021">0014-ORDT-021</a>)
  - If the order is triggered before reaching time `T`, the order will have been removed and will *not* trigger at time `T`. (<a name="0014-ORDT-022" href="#0014-ORDT-022">0014-ORDT-022</a>)

- A stop order set to trade volume `x` with a trigger set to `Rises Above` at a given price will trigger at the first trade at or above that price. At this time the order will be placed on the book if and only if it would reduce the trader's absolute position (buying if they are short or selling if they are long) if executed (i.e. will execute as a reduce-only order).  (<a name="0014-ORDT-023" href="#0014-ORDT-023">0014-ORDT-023</a>)
- If a pair of stop orders are specified as OCO, one being triggered also removes the other from the book. (<a name="0014-ORDT-024" href="#0014-ORDT-024">0014-ORDT-024</a>)
- If a pair of stop orders are specified as OCO with the same trigger conditions and directions, if that trigger is hit one will execute and the other will expire. The exact choice of which will execute should not be assumed by the trader. (<a name="0014-ORDT-025" href="#0014-ORDT-025">0014-ORDT-025</a>)
- If a pair of stop orders are specified as OCO and one triggers but is invalid at time of triggering (e.g. a buy when the trader is already long) the other will still be cancelled. (<a name="0014-ORDT-026" href="#0014-ORDT-026">0014-ORDT-026</a>)

- A trailing stop order for a 5% drop placed when the price is `50`, followed by a price rise to `60` will:
  - Be triggered by a fall to `57`. (<a name="0014-ORDT-027" href="#0014-ORDT-027">0014-ORDT-027</a>)
  - Not be triggered by a fall to `58`. (<a name="0014-ORDT-036" href="#0014-ORDT-036">0014-ORDT-036</a>)
- A trailing stop order for a 5% rise placed when the price is `50`, followed by a drop to `40` will:
  - Be triggered by a rise to `42`. (<a name="0014-ORDT-028" href="#0014-ORDT-028">0014-ORDT-028</a>)
  - Not be triggered by a rise to `41`. (<a name="0014-ORDT-029" href="#0014-ORDT-029">0014-ORDT-029</a>)
- A trailing stop order for a 25% drop placed when the price is `50`, followed by a price rise to `60`, then to `50`, then another rise to `57` will:
  - Be triggered by a fall to `45`. (<a name="0014-ORDT-030" href="#0014-ORDT-030">0014-ORDT-030</a>)
  - Not be triggered by a fall to `46`. (<a name="0014-ORDT-031" href="#0014-ORDT-031">0014-ORDT-031</a>)

- A stop order placed either prior to or during an auction will not execute during an auction, nor will it participate in the uncrossing. (<a name="0014-ORDT-032" href="#0014-ORDT-032">0014-ORDT-032</a>)
- A stop order placed either prior to or during an auction, where the uncrossing price is within the triggering range, will immediately execute following uncrossing. (<a name="0014-ORDT-033" href="#0014-ORDT-033">0014-ORDT-033</a>)

- If a trader has open stop orders and their position moves to zero whilst they still have open limit orders their stop orders will remain active. (<a name="0014-ORDT-034" href="#0014-ORDT-034">0014-ORDT-034</a>)
- If a trader has open stop orders and their position moves to zero with no open limit orders their stop orders are cancelled. (<a name="0014-ORDT-035" href="#0014-ORDT-035">0014-ORDT-035</a>)


### See also

- [0068-MATC-Matching engine](./0068-MATC-matching_engine.md)

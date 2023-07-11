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

1. **Post-Only (True/False):** Only valid for Limit orders. Cannot be True at the same time as Reduce-Only. If set to true, once an order reaches the orderbook, this order acts identically to a limit order set at the same price. However, prior to being placed a check is run to ensure that the order will not (neither totally nor in any part) immediately cross with anything already on the book. If the order would immediately trade, it is instead immediately `Stopped` with a reason informing the trader that the order was stopped to avoid a trade occurring. As a result, placing a Post-Only order will never incur taker fees, and will not incur fees in general if executed in continuous trading. It is possible for some liquidity and infrastructure fees to be paid if the resultant limit order trades at the uncrossing of an auction, as specified in [0029-FEES](https://github.com/vegaprotocol/specs/blob/master/protocol/0029-FEES-fees.md#normal-auctions-including-market-protection-and-opening-auctions).
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
  - An OCO submission cannot be set to execute at expiry.

- The stop order submission wraps a normal order submission.

- The order within the stop order submission must be reduce only.

- The submission is validated when it is received but does not initially interact with the order book unless it is triggered immediately (see below).

- If and when the trigger price is breached in the specified direction the order provided in the stop order submission is created and enters the book or trades as normal, as if it was just submitted.

- The order contained in a stop order submission is entered immediately if the trigger price is already breached on entry, except during an auction.

- When the stop order is a trailing stop, the price at which it is triggered is calculated as the defined distance as a percentage from the highest price achieved since the order was entered if the direction is to trigger on price below the specified level, or the lowest price achieved since the order was entered if the direction is to trigger above the level.
Therefore the trigger level of a stop order moves with the market allowing the trader to lock in some amount of gains.

- The order can't be triggered or trade at all during an auction (even if the current price would normally trigger it immediately on entry).

- A stop order can be entered during an auction, and can then be triggered by the auction uncrossing price if the auction results in a trade, as well as any trades (including auction uncrossing trades) after that.

- GFA is not a valid TIF for a stop order submission.

- Spam prevention:

  - Stop orders will only be accepted from keys with either a non-zero open position or at least one active order.

  - A network parameter will control the maximum number of stop orders per party (suggested initial value: between 4 and 10).

  - If the trader's position size moves to zero exactly, and they have no open orders, all stop orders will be cancelled.


### Iceberg / transparent iceberg orders

On centralised exchanges, icebergs are a type of order that enables a trader to make an order with a relatively small visible "display quantity" and a larger hidden total size.

Like an iceberg, most of the order is not visible to other traders.

After the full size of the visible portion of the order has traded away, the order is "refreshed" and reappears with its maximum display quantity.

This is repeated until the order is cancelled or expires, or its full volume trades away.

Some platforms also allow the display quantity to be randomised on each refresh to further frustrate traders trying to identify the existence of the iceberg order).

Vega, being a decentralised and fully transparent protocol, cannot (in its current form) achieve the hidden characteristic of iceberg orders. But it can do the rest.

Iceberg orders (or in other words, transparent iceberg orders) are still helpful, especially for market makers and in combination with pegged orders, as they allow a trader to remain competitively present on the order book through the refresh facility without needing to supply excessive volume into a large aggressive order.


#### Definitions

These terms are used to refer to fields on an order:

- `quantity` - the full initial size of the order on entry.

- `displayed quantity` - the current displayed quantity, i.e. the amount of the remaining quantity that is active on the book and can be hit.
Note that for a non-iceberg order, `displayed quantity == remaining`.

- `remaining` - the total quantity of the order remaining that could trade.


#### Creating iceberg orders

Iceberg orders are created by populating three additional fields on any valid persistent limit order:

- `initial peak size` - this specifies the amount displayed and available on the order book for a new or newly refreshed iceberg order.

- `minimum peak size` - this determines when an iceberg order is eligible for refresh.
The iceberg is refreshed any time the order's displayed quantity is less than the minimum peak size.


#### Validity

- The order's non-iceberg-related fields must be set so as to make a valid order.

- Any persistent TIF (GTC, GTT, GFA, GFN) can be an iceberg order.

- An iceberg order may have either an ordinary or pegged limit price.
Market iceberg orders are not supported, even if with a persistent TIF.

- Icebergs may be post only.

- `initial peak size` must be greater than or equal to minimum position size (i.e. minimum order size).

- `minimum peak size` must be `>` 0 and `≤ initial peak size`


#### Execution and subsequent refresh

- On entry, if an iceberg order is crossed with the best bid/ask, it trades first with its **full quantity**, i.e. the peak sizes do not come into play during aggressive execution.
This is to prevent an iceberg order ever being crossed after refreshing.

- Once they enter the book passively, iceberg orders trade just like non-iceberg persistent order, as if the order entered the book with `quantity = initial peak size` on submission, and again each time they are refreshed until `remaining == 0` (or they are cancelled or expired, etc.).
That is:

  - On entry, unlike normal orders, `displayed quantity` is set to `initial peak size` not `quantity`.

  - As for any other order, `remaining == quantity` on entry.

- When an iceberg order trades, both `remaining` and `displayed quantity` are reduced by the trade size.

- Iceberg orders can trade many times without refresh, reducing `displayed quantity` each time.
The order will not be refreshed after each trade while `displayed quantity ≥ minimum peak size`.

- When `displayed quantity < minimum peak size` and `remaining > displayed quantity` the order will be refreshed:

  - The refresh happens at the end of the transaction when the order becomes eligible for refresh.

  - On refresh `display quantity` is set to `min(remaining, initial peak size)`.

  - A refresh simulates a cancel/replace, which means that on refresh an iceberg order will always lose time priority relative to other orders at the same price.

  - If multiple iceberg orders need to be refreshed at the same time, they are refreshed in the order that their eligibility for refresh was triggered, so the iceberg that dropped below its `minimum peak size` first is refreshed first (even during the same transaction the sequence of execution must be respected).

- Once the remaining quantity is equal to the displayed quantity, no further refresh is possible.
The order now behaves like a normal limit order and will leave the book if it trades away completely.

- For an incoming order with size larger than the total displayed quantity at a given price level, the following procedure should be followed:

  - The incoming order trades with all visible volume at the price level, whether an iceberg order or a vanilla limit order

  - If there is still remaining volume in the order once all visible volume at the price level is used up, the remaining quantity is split between the non-visible components of all iceberg orders at this level according to their remaining volumes. For example if there are three iceberg orders with remaining volume 200 lots, 100 lots and 100 lots, an order for 300 lots would be split 150 to the first order and 75 to the two 100 lot orders. If the distribution doesn't divide exactly stick the extra onto the iceberg which is first in terms of time priority.

  - If there are still remaining iceberg orders at this point, refresh their volumes and continue trading. If the incoming order uses up all iceberg orders at this level, continue with any remaining volume to the next price level.


#### Amendment

- Amending the size of an iceberg order amends the total `remaining` quantity and leaves the `displayed quantity` unaffected unless the new remaining quantity is smaller than the current displayed quantity, in which case the displayed quantity is reduced to the total remaining quantity.

- Amending the size/quantity of an iceberg order does not cause it to lose time priority.
This is because the increase applies to the `remaining` quantity and not to the `displayed quantity`.
This is allowed because the order will lose time priority on refresh, i.e. before the increased quantity is available to trade.


#### Auctions

- Icebergs can be entered or carried into auctions if the underlying TIF is supported.

- Icebergs can trade in the auction uncrossing up to their full `remaining` amount as for any other transaction that would cause a trade with an iceberg order.
If the remainders of multiple icebergs sit at the same price and are not fully used up, the traded volume should be split between them pro-rata by their total total size. Any integer remainder should be allocated to the iceberg with the highest time priority.

- Icebergs are refreshed after an auction uncrossing if they traded to below their `minimum peak size`, according to the same rules as for normal execution.


#### APIs

- The fields `displayed quantity`, `remaining`, `quantity`, `initial peak size`, `minimum peak size`, `refresh policy` must be exposed by data node APIs in addition to all normal fields for an order.

- An iceberg order refresh must generate an event of the event bus.

- Any API that returns information about market-depth or the orderbook volume will include an iceberg order's full volume and not just its `display quantity`.


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
  - An aggressive persistent (GTT, GTC) limit order that is not crossed with the order book is included on the order book at limit order price at the back of the queue of orders at that price. No trades are generated. (<a name="0014-ORDT-001" href="#0014-ORDT-001">0014-ORDT-001</a>)(<a name="0014-SP-ORDT-001" href="#0014-SP-ORDT-001">0014-SP-ORDT-001</a>)
  - An aggressive persistent (GTT, GTC) limit order that crosses with trades >= to its volume is filled completely and does not appear on the order book or in the order book volume. Trades are atomically generated for the full volume. (<a name="0014-ORDT-002" href="#0014-ORDT-002">0014-ORDT-002</a>)(<a name="0014-SP-ORDT-002" href="#0014-SP-ORDT-002">0014-SP-ORDT-002</a>)
  - An aggressive persistent (GTT, GTC) limit order that is partially filled generates trades commensurate with the filled volume. The remaining volume is placed on the order book at the limit order price, at the back of the queue of orders at that price. (<a name="0014-ORDT-003" href="#0014-ORDT-003">0014-ORDT-003</a>)(<a name="0014-SP-ORDT-003" href="#0014-SP-ORDT-003">0014-SP-ORDT-003</a>)
  - Any GTT limit order that [still] resides on the order book at its expiry time is cancelled and removed from the book before any events are processed that rely on its being present on the book, including any calculation that incorporates its volume and/or price level. (<a name="0014-ORDT-004" href="#0014-ORDT-004">0014-ORDT-004</a>)(<a name="0014-SP-ORDT-004" href="#0014-SP-ORDT-004">0014-SP-ORDT-004</a>)
  - A GTT order submitted at a time >= its expiry time is rejected. (<a name="0014-ORDT-005" href="#0014-ORDT-005">0014-ORDT-005</a>)(<a name="0014-SP-ORDT-005" href="#0014-SP-ORDT-005">0014-SP-ORDT-005</a>)
- No party can submit a [network order type](#network-orders)  (<a name="0014-ORDT-006" href="#0014-ORDT-006">0014-ORDT-006</a>)(<a name="0014-SP-ORDT-006" href="#0014-SP-ORDT-006">0014-SP-ORDT-006</a>)
- A pegged order (including iceberg pegged orders) never has its price updated during the execution of an incoming aggressive order (even as price levels get consumed so that its reference price changes after the execution). (<a name="0014-ORDT-039" href="#0014-ORDT-039">0014-ORDT-039</a>)

### Iceberg Orders AC's

#### Iceberg Order Submission

1. A persistent (GTC, GTT, GFA, GFN) iceberg order that is not crossed with the order book is included in the order book with order book volume == initial peak size. No trades are generated (<a name="0014-ORDT-007" href="#0014-ORDT-007">0014-ORDT-007</a>)(<a name="0014-ORDT-007" href="#0014-ORDT-007">0014-ORDT-007</a>)
2. An iceberg order with either an ordinary or pegged limit price can be submitted (<a name="0014-ORDT-008" href="#0014-ORDT-008">0014-ORDT-008</a>)(<a name="0014-ORDT-008" href="#0014-ORDT-008">0014-ORDT-008</a>)
3. An iceberg post only order can be submitted  (<a name="0014-ORDT-009" href="#0014-ORDT-009">0014-ORDT-009</a>)(<a name="0014-ORDT-009" href="#0014-ORDT-009">0014-ORDT-009</a>)
4. An iceberg reduce only order is rejected (<a name="0014-ORDT-010" href="#0014-ORDT-010">0014-ORDT-010</a>)(<a name="0014-ORDT-010" href="#0014-ORDT-010">0014-ORDT-010</a>)
5. For an iceberg order that is submitted with total size x and display size y the margin taken should be identical to a regular order of size `x` rather than one of size `y` (<a name="0014-ORDT-011" href="#0014-ORDT-011">0014-ORDT-011</a>)
In Spot market, for an iceberg order that is submitted with total size x and display size y the holding asset taken should be identical to a regular order of size `x` rather than one of size `y` (<a name="0014-SP-ORDT-011" href="#0014-SP-ORDT-011">0014-SP-ORDT-011</a>)
6. For an iceberg order, the orders are refreshed immediately after producing a trade. Every time volume is taken from the displayed quantity , the order is refreshed if display quantity < minimum peak size (<a name="0014-ORDT-012" href="#0014-ORDT-012">0014-ORDT-012</a>)(<a name="0014-SP-ORDT-012" href="#0014-SP-ORDT-012">0014-SP-ORDT-012</a>)
   - If the order is successfully refreshed , then the order loses its time priority and is pushed to the back of the queue
7. For an iceberg order that's submitted when the market is in auction, iceberg orders trade according to their behaviour if they were already on the book (trading first the visible size, then additional if the full visible price level is exhausted in the uncrossing) (<a name="0014-ORDT-013" href="#0014-ORDT-013">0014-ORDT-013</a>)(<a name="0014-SP-ORDT-013" href="#0014-SP-ORDT-013">0014-SP-ORDT-013</a>)

#### Iceberg Order Batch Submission

1. For multiple iceberg orders submitted as a batch of orders with a mix of ordinary limit orders and market orders, the iceberg orders are processed atomically and the order book volume and price, margin calculations , order status are all correct (<a name="0014-ORDT-014" href="#0014-ORDT-014">0014-ORDT-014</a>)
In Spot market, for multiple iceberg orders submitted as a batch of orders with a mix of ordinary limit orders and market orders, the iceberg orders are processed atomically and the order book volume and price, holding calculations , order status are all correct. (<a name="0014-SP-ORDT-014" href="#0014-SP-ORDT-014">0014-SP-ORDT-014</a>)
2. For an iceberg order submitted in a batch that trades against multiple other orders sitting on the book, the iceberg order refreshes between each order in the batch (<a name="0014-ORDT-015" href="#0014-ORDT-015">0014-ORDT-015</a>)(<a name="0014-SP-ORDT-015" href="#0014-SP-ORDT-015">0014-SP-ORDT-015</a>)

#### Iceberg Order Submission - Negative tests

1. An iceberg order with a non persistent TIF (IOC, FOK) is rejected with a valid error message (<a name="0014-ORDT-016" href="#0014-ORDT-016">0014-ORDT-016</a>)(<a name="0014-SP-ORDT-016" href="#0014-SP-ORDT-016">0014-SP-ORDT-016</a>)
2. An iceberg market order with any TIF is rejected with a valid error message (<a name="0014-ORDT-017" href="#0014-ORDT-017">0014-ORDT-017</a>)(<a name="0014-SP-ORDT-017" href="#0014-SP-ORDT-017">0014-SP-ORDT-017</a>)
3. A reduce-only iceberg order with any TIF is rejected with a valid error message (<a name="0014-ORDT-018" href="#0014-ORDT-018">0014-ORDT-018</a>)(<a name="0014-SP-ORDT-018" href="#0014-SP-ORDT-018">0014-SP-ORDT-018</a>)
4. An iceberg order with initial peak size greater than the total order size is rejected with a valid error message (<a name="0014-ORDT-020" href="#0014-ORDT-020">0014-ORDT-020</a>)(<a name="0014-SP-ORDT-020" href="#0014-SP-ORDT-020">0014-SP-ORDT-020</a>)
5. An iceberg order with minimum peak size less than 0 is rejected with a valid error message (<a name="0014-ORDT-021" href="#0014-ORDT-021">0014-ORDT-021</a>)(<a name="0014-SP-ORDT-021" href="#0014-SP-ORDT-021">0014-SP-ORDT-021</a>)
6. An iceberg order with minimum peak size greater than initial peak size is rejected with a valid error message (<a name="0014-ORDT-022" href="#0014-ORDT-022">0014-ORDT-022</a>)(<a name="0014-SP-ORDT-022" href="#0014-SP-ORDT-022">0014-SP-ORDT-022</a>)

#### Iceberg Order Amendment

1. Amending an iceberg order to increase size will increase the total and remaining quantities of the order and time priority of the order is not lost (<a name="0014-ORDT-023" href="#0014-ORDT-023">0014-ORDT-023</a>)(<a name="0014-SP-ORDT-023" href="#0014-SP-ORDT-023">0014-SP-ORDT-023</a>)
2. Amending an iceberg order to decrease size will decrease the total and remaining quantities and time priority of the order is not lost (<a name="0014-ORDT-024" href="#0014-ORDT-024">0014-ORDT-024</a>)(<a name="0014-SP-ORDT-024" href="#0014-SP-ORDT-024">0014-SP-ORDT-024</a>)
3. Amend an iceberg order to decrease size so that the displayed quantity is decreased. Total, displayed and remaining quantity is decreased, margin is recalculated and released and time priority is not lost (<a name="0014-ORDT-025" href="#0014-ORDT-025">0014-ORDT-025</a>)
4. In Spot market, amend an iceberg order to decrease size so that the displayed quantity is decreased. Total, displayed and remaining quantity is decreased, margin is recalculated and released and time priority is not lost. (<a name="0014-SP-ORDT-025" href="#0014-SP-ORDT-025">0014-SP-ORDT-025</a>)

#### Iceberg Order Cancellation

1. Cancelling an iceberg order will cancel the order, remove it from the order book , release margin and update order book to reflect the change (<a name="0014-ORDT-026" href="#0014-ORDT-026">0014-ORDT-026</a>)
1. In Spot market, cancelling an iceberg order will cancel the order, remove it from the order book , release holding asset and update order book to reflect the change (<a name="0014-SP-ORDT-026" href="#0014-SP-ORDT-026">0014-SP-ORDT-026</a>)

#### Iceberg Order Execution

1. An aggressive iceberg order that crosses with an order where volume > iceberg volume, the iceberg order gets fully filled on entry, the iceberg order status is filled, the remaining quantity = 0. Atomic trades are generated if matched against multiple orders (<a name="0014-ORDT-027" href="#0014-ORDT-027">0014-ORDT-027</a>)(<a name="0014-SP-ORDT-027" href="#0014-SP-ORDT-027">0014-SP-ORDT-027</a>)
2. An aggressive iceberg order that crosses with an order where volume < iceberg volume. The initial display quantity is filled and the remaining volume is unfilled. Status of iceberg order is active , the volume remaining = (quantity - initial volume) and the remaining volume sits on the book. When additional orders are submitted which consume the remaining volume on the iceberg order , the volume of the iceberg order is refreshed as and when the volume dips below the minimum peak size (<a name="0014-ORDT-028" href="#0014-ORDT-028">0014-ORDT-028</a>)(<a name="0014-SP-ORDT-028" href="#0014-SP-ORDT-028">0014-SP-ORDT-028</a>)
3. A passive iceberg order (the only order at a particular price level) when crossed with another order that comes in which consumes the full volume of the iceberg order is fully filled. Status of iceberg order is filled and the remaining = 0. Atomic trades are produced (<a name="0014-ORDT-029" href="#0014-ORDT-029">0014-ORDT-029</a>)(<a name="0014-SP-ORDT-029" href="#0014-SP-ORDT-029">0014-SP-ORDT-029</a>)
4. A passive iceberg order with a couple of order that sit behind the iceberg order at the same price that crosses with an order where volume > display quantity of iceberg order. After the first trade is produced , the iceberg order is pushed to the back of the queue and gets filled only when the other orders in front get fully filled (<a name="0014-ORDT-030" href="#0014-ORDT-030">0014-ORDT-030</a>)(<a name="0014-SP-ORDT-030" href="#0014-SP-ORDT-030">0014-SP-ORDT-030</a>)
5. Submit an aggressive iceberg order for size 100. There are multiple matching orders of size 30,40,50. Ensure the orders are matched and filled in time priority of the orders and any remaining volume on the orders is correctly left behind. (<a name="0014-ORDT-031" href="#0014-ORDT-031">0014-ORDT-031</a>)(<a name="0014-SP-ORDT-031" href="#0014-SP-ORDT-031">0014-SP-ORDT-031</a>)
6. Submit an aggressive iceberg order for size 100. There are multiple matching orders of size 20,30. Ensure the orders are matched and filled in time priority of the orders. Ensure remaining volume on the iceberg order is (100 - (20+30)) (<a name="0014-ORDT-032" href="#0014-ORDT-032">0014-ORDT-032</a>)(<a name="0014-SP-ORDT-032" href="#0014-SP-ORDT-032">0014-SP-ORDT-032</a>)
7. When a non iceberg order sitting on the book is amended such that it trades with with an iceberg order, then the iceberg order is refreshed (<a name="0014-ORDT-033" href="#0014-ORDT-033">0014-ORDT-033</a>)(<a name="0014-SP-ORDT-033" href="#0014-SP-ORDT-033">0014-SP-ORDT-033</a>)
8. Wash trading is not permitted for iceberg orders. The same party has one iceberg order that sits at the back of the queue, another normal order in opposite direction, when the iceberg at the back comes in front the normal order should be stopped. ( <a name="0014-ORDT-034" href="#0014-ORDT-034">0014-ORDT-034</a>)( <a name="0014-SP-ORDT-034" href="#0014-SP-ORDT-034">0014-SP-ORDT-034</a>)
9. For a price level with multiple iceberg orders, if an aggressive order hits this price level, any volume greater than the displayed volume at a level is split proportionally between the hidden components of iceberg orders at that price level
   1. If there are three iceberg orders with remaining volume 200 lots, 100 lots and 100 lots, an order for 300 lots would be split 150 to the first order and 75 to the two 100 lot orders. (<a name="0014-ORDT-037" href="#0014-ORDT-037">0014-ORDT-037</a>)(<a name="0014-SP-ORDT-037" href="#0014-SP-ORDT-037">0014-SP-ORDT-037</a>)
   1. If there are three iceberg orders with remaining volume 200 lots, 100 lots and 100 lots, an order for 600 lots would be split 200 to the first order and 100 to the two 100 lot orders, with 200 lots then taking farther price levels. (<a name="0014-ORDT-038" href="#0014-ORDT-038">0014-ORDT-038</a>)(<a name="0014-SP-ORDT-038" href="#0014-SP-ORDT-038">0014-SP-ORDT-038</a>)

### Snapshots

1. All data pertaining to iceberg orders is saved and can be restored using the snapshot (<a name="0014-ORDT-035" href="#0014-ORDT-035">0014-ORDT-035</a>)(<a name="0014-SP-ORDT-035" href="#0014-SP-ORDT-035">0014-SP-ORDT-035</a>)

### API

1. API end points should be available to query initial peak size, minimum peak size, quantity, displayed quantity and remaining (<a name="0014-ORDT-036" href="#0014-ORDT-036">0014-ORDT-036</a>)(<a name="0014-SP-ORDT-036" href="#0014-SP-ORDT-036">0014-SP-ORDT-036</a>)
2. The additional fields relating to iceberg orders should be available in the streaming api end points (<a name="0014-ORDT-069" href="#0014-ORDT-069">0014-ORDT-069</a>)(<a name="0014-SP-ORDT-069" href="#0014-SP-ORDT-069">0014-SP-ORDT-069</a>)
3. API end points showing market-depth or price-level volume should include the full volume of iceberg orders (<a name="0014-ORDT-070" href="#0014-ORDT-070">0014-ORDT-070</a>)(<a name="0014-SP-ORDT-070" href="#0014-SP-ORDT-070">0014-SP-ORDT-070</a>)

### Stop orders

- A stop order with reduce only set to false will be rejected. (<a name="0014-ORDT-040" href="#0014-ORDT-040">0014-ORDT-040</a>)
- Once triggered, a stop order is removed from the book and cannot be triggered again. (<a name="0014-ORDT-041" href="#0014-ORDT-041">0014-ORDT-041</a>)
- A stop order placed by a key with a zero position and no open orders will be rejected. (<a name="0014-ORDT-042" href="#0014-ORDT-042">0014-ORDT-042</a>)
- A stop order placed by a key with a zero position but open orders will be accepted. (<a name="0014-ORDT-043" href="#0014-ORDT-043">0014-ORDT-043</a>)
- Attempting to create more stop orders than is allowed by the relevant network parameter will result in the transaction failing to execute. (<a name="0014-ORDT-044" href="#0014-ORDT-044">0014-ORDT-044</a>)

- A stop order wrapping a limit order will, once triggered, place the limit order as if it just arrived as an order without the stop order wrapping. (<a name="0014-ORDT-045" href="#0014-ORDT-045">0014-ORDT-045</a>)
- A stop order wrapping a market order will, once triggered, place the market order as if it just arrived as an order without the stop order wrapping. (<a name="0014-ORDT-046" href="#0014-ORDT-046">0014-ORDT-046</a>)

- With a last traded price at 50, a stop order placed with `Rises Above` setting at 75 will be triggered by any trade at price 75 or higher. (<a name="0014-ORDT-047" href="#0014-ORDT-047">0014-ORDT-047</a>)
- With a last traded price at 50, a stop order placed with `Rises Above` setting at 25 will be triggered immediately (before another trade is even necessary). (<a name="0014-ORDT-048" href="#0014-ORDT-048">0014-ORDT-048</a>)
- With a last traded price at 50, a stop order placed with `Falls Below` setting at 25 will be triggered by any trade at price 25 or lower. (<a name="0014-ORDT-049" href="#0014-ORDT-049">0014-ORDT-049</a>)
- With a last traded price at 50, a stop order placed with `Falls Below` setting at 75 will be triggered immediately (before another trade is even necessary). (<a name="0014-ORDT-050" href="#0014-ORDT-050">0014-ORDT-050</a>)

- With a last traded price at 50, a stop order placed with any trigger price which does not trigger immediately will trigger as soon as a trade occurs at a trigger price, and will not wait until the next mark price update to trigger. (<a name="0014-ORDT-051" href="#0014-ORDT-051">0014-ORDT-051</a>)
- A stop order with expiration time `T` set to expire at that time will expire at time `T` if reached without being triggered. (<a name="0014-ORDT-052" href="#0014-ORDT-052">0014-ORDT-052</a>)
- A stop order with expiration time `T` set to execute at that time will execute at time `T` if reached without being triggered. (<a name="0014-ORDT-053" href="#0014-ORDT-053">0014-ORDT-053</a>)
  - If the order is triggered before reaching time `T`, the order will have been removed and will *not* trigger at time `T`. (<a name="0014-ORDT-054" href="#0014-ORDT-054">0014-ORDT-054</a>)

- A stop order set to trade volume `x` with a trigger set to `Rises Above` at a given price will trigger at the first trade at or above that price. At this time the order will be placed on the book if and only if it would reduce the trader's absolute position (buying if they are short or selling if they are long) if executed (i.e. will execute as a reduce-only order).  (<a name="0014-ORDT-055" href="#0014-ORDT-055">0014-ORDT-055</a>)
- If a pair of stop orders are specified as OCO, one being triggered also removes the other from the book. (<a name="0014-ORDT-056" href="#0014-ORDT-056">0014-ORDT-056</a>)
- If a pair of stop orders are specified as OCO and one triggers but is invalid at time of triggering (e.g. a buy when the trader is already long) the other will still be cancelled. (<a name="0014-ORDT-058" href="#0014-ORDT-058">0014-ORDT-058</a>)

- A trailing stop order for a 5% drop placed when the price is `50`, followed by a price rise to `60` will:
  - Be triggered by a fall to `57`. (<a name="0014-ORDT-059" href="#0014-ORDT-059">0014-ORDT-059</a>)
  - Not be triggered by a fall to `58`. (<a name="0014-ORDT-060" href="#0014-ORDT-060">0014-ORDT-060</a>)
- A trailing stop order for a 5% rise placed when the price is `50`, followed by a drop to `40` will:
  - Be triggered by a rise to `42`. (<a name="0014-ORDT-061" href="#0014-ORDT-061">0014-ORDT-061</a>)
  - Not be triggered by a rise to `41`. (<a name="0014-ORDT-062" href="#0014-ORDT-062">0014-ORDT-062</a>)
- A trailing stop order for a 25% drop placed when the price is `50`, followed by a price rise to `60`, then to `50`, then another rise to `57` will:
  - Be triggered by a fall to `45`. (<a name="0014-ORDT-063" href="#0014-ORDT-063">0014-ORDT-063</a>)
  - Not be triggered by a fall to `46`. (<a name="0014-ORDT-064" href="#0014-ORDT-064">0014-ORDT-064</a>)

- A stop order placed either prior to or during an auction will not execute during an auction, nor will it participate in the uncrossing. (<a name="0014-ORDT-065" href="#0014-ORDT-065">0014-ORDT-065</a>)
- A stop order placed either prior to or during an auction, where the uncrossing price is within the triggering range, will immediately execute following uncrossing. (<a name="0014-ORDT-066" href="#0014-ORDT-066">0014-ORDT-066</a>)

- If a trader has open stop orders and their position moves to zero whilst they still have open limit orders their stop orders will remain active. (<a name="0014-ORDT-067" href="#0014-ORDT-067">0014-ORDT-067</a>)
- If a trader has open stop orders and their position moves to zero with no open limit orders their stop orders are cancelled. (<a name="0014-ORDT-068" href="#0014-ORDT-068">0014-ORDT-068</a>)

- A Stop order that hasn't been triggered can be cancelled. (<a name="0014-ORDT-071" href="#0014-ORDT-071">0014-ORDT-071</a>)
- All stop orders for a specific party can be cancelled by a single stop order cancellation. (<a name="0014-ORDT-072" href="#0014-ORDT-072">0014-ORDT-072</a>)
- All stop orders for a specific party for a specific market can be cancelled by a single stop order cancellation. (<a name="0014-ORDT-073" href="#0014-ORDT-073">0014-ORDT-073</a>)

## Stop Orders - Negative Cases

- Stop orders submitted with post_only=True are rejected. (<a name="0014-ORDT-074" href="#0014-ORDT-074">0014-ORDT-074</a>)
- Stop orders submitted with invalid values for trigger price (0, negative values) and trailing percentage (0, negative values) are rejected. (<a name="0014-ORDT-075" href="#0014-ORDT-075">0014-ORDT-075</a>)
- Stop orders submitted with expiry in the past are rejected. (<a name="0014-ORDT-076" href="#0014-ORDT-076">0014-ORDT-076</a>)
- GFA Stop orders submitted are rejected. (<a name="0014-ORDT-077" href="#0014-ORDT-077">0014-ORDT-077</a>)
- Stop orders once triggered can not be cancelled. (<a name="0014-ORDT-078" href="#0014-ORDT-078">0014-ORDT-078</a>)

## Stop Orders - Snapshots

- Stop orders are saved and can be restored using the snapshot and will be triggered once the trigger conditions are met. (<a name="0014-ORDT-079" href="#0014-ORDT-079">0014-ORDT-079</a>)

## Stop Orders - API

- API end points should be available to query stop orders with all relevant fields. (<a name="0014-ORDT-080" href="#0014-ORDT-080">0014-ORDT-080</a>)

### See also

- [0068-MATC-Matching engine](./0068-MATC-matching_engine.md)

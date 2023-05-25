# Order types

## Summary

A market using a limit order book will permit orders of various types to be submitted depending on the market's current *trading mode* (see [Market Framework](./0001-MKTF-market_framework.md)). This specification encompasses multiple configurable aspects of an order including: triggering, time in force, price type, and execution constraints. It defines the allowable values for each, valid combinations of these, and their behaviour.

Notes on scope of current version of this spec:

- Includes only detailed specification for orders valid for *continuous trading*, does not specify behaviour of these order types in an auction.
- Does not include detailed specification for **stop** orders. Inclusion of stops in guide level explanation is a placeholder/indicator of future requirements.

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

### Iceberg Orders AC's

### Iceberg Order Submission

1. A persistent (GTC, GTT, GFA, GFN) iceberg order that is not crossed with the order book is included in the order book with order book volume == initial peak size. No trades are generated.
2. An iceberg order with either an ordinary or pegged limit price can be submitted.
3. An iceberg post only order can be submitted.
4. An iceberg reduce only order is rejected.
5. Margin requirement for iceberg order - is it based on initial peak size i.e. displayed quantity OR actual quantity ? Assume its displayed quantity - needs confirmation.
6. For a persistent (GTC, GTT, GFA, GFN) iceberg order that's submitted margin is calculated and deducted correctly both during submission as well as during subsequent refreshes.
7. For an iceberg order, the orders are refreshed immediately after producing a trade. Every time volume is taken from the displayed quantity , ensure the order is refreshed if if display quantity < minimum peak size.
   If the order is successfully refreshed , then the order loses its time priority and is pushed to the back of the queue.
8. For an iceberg order that's submitted when the market is in auction, only the displayed quantity is filled when coming out of auction. What other attributes need to be checked here ?

### Iceberg Order Batch Submission

1. For multiple iceberg orders submitted as a batch of orders with a mix of ordinary limit orders and market orders, the iceberg orders are processed atomically and the order book volume and price, margin calculations , order status are all correct - What else needs checking ?
2. What other scenarios need testing ?

### Iceberg Order Submission - Negative tests

1. An iceberg order with a non persistent TIF (IOC, FOK) is rejected with a valid error message.
2. An iceberg market order with any TIF is rejected with a valid error message.
3. A reduce-only iceberg order with any TIF is rejected with a valid error message.
4. An iceberg order with initial peak size less than the minimum order size rejected with a valid error message.
5. An iceberg order with initial peak size greater than the total order size is rejected with a valid error message.
6. An iceberg order with minimum peak size less than 0 is rejected with a valid error message.
7. An iceberg order with minimum peak size greater than initial peak size is rejected with a valid error message.

### Iceberg Order Amendment

1. Amending an iceberg order to increase size will increase the total and remaining quantities of the order and time priority of the order is not lost.
2. Amending an iceberg order to decrease size will decrease the total and remaining quantities and time priority of the order is not lost.
3. Amend an iceberg order to decrease size so that the displayed quantity is decreased. Total and remaining quantity is decreased, margin is recalculated and released and time priority is not lost.
4. What other scenarios do we need to consider here ?

### Iceberg Order Cancellation

1. Cancelling an iceberg order will cancel the order, remove it from the order book , release margin and update order book to reflect the change.

### Iceberg Order Execution

1. An aggressive iceberg order that crosses with an order where volume > iceberg volume, the iceberg order gets fully filled on entry, the iceberg order status is filled, the remaining quantity = 0. Are atomic trades generated OR one single trade for each display quantity volume ???
2. An aggressive iceberg order that crosses with an order where volume < iceberg volume. The initial display quantity is filled and the remaining volume is unfilled. Status of iceberg order is partially filled , the volume remaining = (quantity - initial volume) and the remaining volume sits on the book. When additional orders thar are submitted which consume the remaining volume on the iceberg order , the volume of the iceberg order is refreshed as and when the volume dips below the minimum peak size.
3. A passive iceberg order (the only order at a particular price level) when crossed with another order that comes in which consumes the full volume of the iceberg order is fully filled. Status of iceberg order is filled and the remaining = 0. Atomic trades are produced.
4. A passive iceberg order with a couple of order that sit behind the iceberg order at the same price that crosses with an order where volume > display quantity of iceberg order. After the first trade is produced , the iceberg order is pushed to the back of the queue and gets filled only when the other orders in front get fully filled.
5. Submit an aggressive iceberg order for say size 100. There are multiple matching orders of size 30,40,50. Ensure the orders are matched and filled in time priority of the orders and any remaining volume on the orders is correctly left behind.
6. Submit an aggressive iceberg order for say size 100. There are multiple matching orders of size 20,30. Ensure the orders are matched and filled in time priority of the orders. Ensure remaining volume on the iceberg order is (100 - (20+30))
7. When a non iceberg order sitting on the book is amended such that it trades with with an iceberg order, then the iceberg order is refreshed.
8. Try for scenarios for wash trading of iceberg orders - is that even possible ? Or some complex scenarios - same party , one iceberg order that sits at the back of the queue , another normal order in opposite direction , the iceberg at the back slowly comes in front and matches either fully OR partially - is this possible ?
9. What other cases need adding ?

### Snapshots

1. All data pertaining to iceberg orders is saved and can be restored using the snapshot.

### API

1. API end points should be available to query initial peak size, minimum peak size, quantity, displayed quantity and remaining.
2. The additional fields relating to iceberg orders should be available in the streaming api end points

### Protocol Upgrade

1. ???

### Regression

1. All other order types should behave as they were


### See also

- [0068-MATC-Matching engine](./0068-MATC-matching_engine.md)

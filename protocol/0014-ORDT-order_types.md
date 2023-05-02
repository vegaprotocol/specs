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


### 'Glassberg' transparent iceberg orders

On centralised exchanges, icebergs are a type of order that enables a trader to make an order with a relatively small visible "display quantity" and a larger hidden total size.
Like an iceberg, most of the order is not visible to other traders.
After the full size of the visible portion of the order has traded away, the order is "refreshed" and reappears with its maximum display quantity.
This is repeated until the order is cancelled or expires, or its full volume trades away.
Some platforms also allow the display quantity to be randomised on each refresh to further frustrate traders trying to identify the existence of the iceberg ordeer).

Vega, being a decentralised and fully transparent protocol, cannot (in its current form) achieve the hidden characteristic of iceberg orders.
But it can do the rest hence, _glassberg_ orders.
These are still helpful, especially for market makers and in combination with pegged orders, as they allow a trader to remain competitively present on the order book through the refresh facility without needing to supply excessive volume into a large aggressive order.


#### Definitions

These terms are used to refer to fields on an order:

* `quantity` - the full initial size of the order on entry.

* `displayed quantity` - the current displayed quantity, i.e. the amount of the remaining quantity that is active on the book and can be hit.
Note that for a non-glassberg order, `displayed quantity == remaining`.

* `remaining` - the total quantity of the order remaining that could trade.


#### Creating glassberg orders

Glassberg orders are created by populating three additional fields on any valid persistent limit order:

* `initial peak size` - this specifies the amount displayed and available on the order book for a new or newly refreshed glassberg order.

* `minimum peak size` - this determines when a glassberg order is eligible for refresh.
The glassberg is refreshed any time the order's displayed quantity less than the minimum peak size.

* `refresh policy` - this specifies when a glassberg order that is eligible for refresh and has remaining volume >0 is refreshed:

    * `IMMEDIATE` - the refresh occurs _after_ processing the transaction that depleted the display quantity to zero.

    * `BLOCK_END` - the rerresh occurs after processing the _entire block_ containing the transaction that depleted the display quantity to less than minimum peak size.


#### Validity

* The order's non-glassberg-related fields must be set so as to make a valid order.

* Any persistent TIF (GTC, GTT, GFA, GFN) can be a glassberg order.

* A glassberg order may have either an ordinary or pegged limit price. 
Market glassberg orders are not supported, even if with a persistent TIF.

* Glassbergs may be post only.

* `initial peak size` must be greater than TODO

* `minimum peak size` must be `>` 0 and `≤ initial peak size`


#### Execution and subsequent refresh

* Glassberg orders trade just like non-glassberg persistent order, as if the order entered the book with quantity = initial peak size on submission and again each time they are refreshed.
That is:

    * On entry, unlike normal orders, `displayed quantity` is set to `initial peak size` not `quantity`.
    
    * As for any other order, `remaning == quantity` on entry.

* The maximum size for a trade involving a glassberg order is the `displayed quantity` immediataly prior to the trade.
(This is technically also true for a normal order, given that for non-glassberg orders `displayed quantity == remaining`.)

* When a glassberg order trades, both `remaining` and `displayed quantity` are reduced by the trade size.

* Glassberg orders can trade many times without refresh, reducing `displayed quantity` each time.
The order will not be refreshed after each trade while `displayed quantity ≥ minimum peak size`.

* The order will also not be refreshed within a block even if multiple trades occur or `displayed quantity == 0` if the refresh policy is set to `BLOCK_END`. 

* Glassberg orders never trade more than their `displayed quantity` at the start of the transaction, as the result of any one transaction.

* When `displayed quantity < minimum peak size` and `remaining > displayed quantity` the order will be refreshed:

    * The refresh either happens at the end of the transaction when the order became eligible for refresh, if the `refresh policy == IMMEDIATE`; or at the end of the block containing that transaction if the `refresh policy == BLOCK_END`

    * On refresh `display quantity` is set to `min(remaining, initial peak size)`.

    * A refresh simulate a cancel/replace, which means that on refresh a glassberg order will always lose time priority relative to other orders at the same price.

    * If multiple glassberg orders need to be refresh at the same time:

        * `refresh policy == IMMEDIATE` glassbergs are _always_ refreshed before those with `refresh policy == BLOCK_END`

        * within the same `refresh policy`, glassbergs are refreshed in the order that their eligibility for refresh was triggered, so the glassberg that dropped below its `minimum peak size` first is refreshed first (even during the same transaction the sequence of execution must be respected).

* Once the remaning quantity is equal to the displayed quantity, no further refresh is possible.
The order now behaves like a normal limit order and will leave the book if it trades away completely.


#### Amendment

* Amending the size of a glassberg order amends the total `remaining` quantity and leaves the `displayed quantity` unaffected unless the new remaining quanity is smaller than the current displayed quantity, in which case the displayed quantity is reduced to the total remaining quantity.

* Amending the size/quantity of a glassberg order does not cause it to lose time priority. 
This is because the increase applies to the `remaining` quantity and not to the `displayed quantity`.
This is allowed because the order will lose time priority on refresh, i.e. before the increased quantity is available to trade.


#### Auctions

* Glassbergs can be entered or carried into auctions if the underlying TIF is supported. 

* Glassbergs can trade in the auction uncrossing up to their current size as for any other transaxction that would cause a trade.

* Glassbergs are refreshed after an auction uncrossing if they traded away, according to the same rules for the refresh policy as for normal execution.


#### APIs

* The fields `displayed quantity`, `remaining`, `quantity`, `initial peak size`, `minimum peak size`, `refresh policy` must be exposed by data node APIs in addition to all normal fields for an order.

* Glassberg refresh must generate an event bus event.



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

### See also

- [0068-MATC-Matching engine](./0068-MATC-matching_engine.md)

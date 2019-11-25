# Order types

## Acceptance Critieria

- Immediate orders, continuous trading:
	- [ ] An aggressive persistent (GTT, GTC) limit order that is not crossed with the order book is included on the orderbook at limit order price at the back of the queue of orders at that price. No trades are generated.
	- [ ] An aggressive persistent (GTT, GTC) limit order that crosses with trades >= to its volume is filled completely and does not appear on the order book or in the order book volume. Trades are atomically generated for the full volume.
	- [ ] An aggressive persistent (GTT, GTC) limit order that is partially filled generates trades commensurate with the filled volume. The remaining volume is placed on the order book at the limit order price, at the back of the queue of orders at that price.
	- [ ] Any GTT limit order that [still] resides on the order book at its expiry time is cancelled and removed from the book before any events are processed that rely on its being present on the book, including any calculation that incorporate its volume and/or price level.
	- [ ] A GTT order submitted at a time >= its expiry time is rejected.

- *Criteria for stop orders TBD*

## Summary

A market using a limit order book will permit orders of various types to be submitted depending on the market's current *trading mode* (see [Market Framework](0001-market-framework.md)). This specification encompasses multiple configurable aspects of an order including: triggering, time in force, price type, and execution constraints. It defines the allowable values for each, valid combinations of these, and their behaviour.

Notes on scope of current version of this spec:
- Includes only detailed specification for orders valid for *continuous trading*, does not specify behaviour of these order types in an auction.
- Does not include detailed specification for **stop** orders. Inclusion of stops in guide level explanation is a placeholder/indicator of future requirements.


## Guide-level explanation

### Order types:
1. **Immediate:** order is evaluated immediately (this is the default)
1. **Stop:** order is only evaluated if and when the _stop price_ is reached 

### Order pricing methods:

*Price type and associated data if required (i.e. limit price, peg reference and offset) must be explicitly provided as one of the below three options and required data, there is no default.*

1. **Limit (+ limit price):** the order is priced with a static limit price, which is the worst price (i.e. highest buy price / lowest sell price) at which the order can trade. If the order has a persistent validity type it will remain on the order book until it fully executes, expires (as defined by the specific validity type), or is cancelled. 
1. **Pegged (+ reference, price offset):** the order is priced relative to a reference price in the market (i.e. best bid, mid, or best offer price) and is automatically repriced (losing time priority) when the reference price changes. Execution is as for a limit order at that price, including on entry and repricing. The order is removed from the book and 'parked' (in entry time priority) if the reference price is undefined, including during an auction.
1. **Market:** the order is not priced and will take volume at any price (i.e. equivalent to a zero priced sell order or an infinitely priced buy order). Only valid on non-persistent validity types.

### Time in Force / validity:

*Time in force must be explicitly provided, there is no default.*

 - **Persistent:**
	1. **Good 'Til Time (GTT):** order is valid until the supplied expiry time, which may be supplied either as an absolute date/time or a relative offset from the  timestamp on the order (i.e. the timestamp added by the core when it receives the order, which is deterministically the same on all nodes)
	1. **Good 'Til Cancelled (GTC):** order is valid indefinitely. 
- **Non-persistent:**
	1. **Immediate Or Cancel (IOC):** an order that trades as much of its volume as possible with passive orders already on the order book (assuming it is crossed with them) and then stops execution. It is never placed on the book even if it is not completely filled immediately, instead it is stopped/cancelled.
	1. **Fill Or Kill (FOK):** an order that either trades all of its volume immediately on entry or is stopped/cancelled immediately without trading anything. That is, unless the order can be completely filled immediately, it does not trade at all. It is never placed on the book, even if it does not trade.


### Valid order combinations

##### Continuous trading

| Pricing method | GTT | GTC | IOC | FOK |
| -------------- |:---:|:---:|:---:|:----|
| Limit          | Y   | Y   | Y   | Y   |
| Pegged         | Y   | Y   | Y   | Y   | 
| Market         | N   | N   | Y   | Y   |


##### Auction

GFA (Good for auction) not shown, spec. will be updated when auctions are adced.

| Pricing method | GTT | GTC | IOC | FOK |
| -------------- |:---:|:---:|:---:|:----|
| Limit          | Y   | Y   | N   | N   |
| Pegged         | N*  | N*  | N*  | N*  | 
| Market         | N   | N   | Y   | Y   |

\* Pegged orders will be parked during an auction, with time priority preserved

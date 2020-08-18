Feature name: Pegged and Market Maker Orders
Start date: 2020-02-10
Specification PR: https://github.com/vegaprotocol/product/pull/262

# Pegged and Market Maker orders

## Acceptance Criteria
- [ ] Pegged orders can only be LIMIT orders, all other types are rejected.
- [ ] Pegged orders can only be GTT and GTC orders. IOC and FOK will be added in the second phase of pegged orders.
- [ ] All markets must be able to handle pegged orders.
- [ ] Pegged orders are removed from the order book when going into an auction and are parked.
- [ ] Parked orders are returned to the order book in entry order once continuous trading is resumed.
- [ ] Pegged orders are repriced when their reference price moves.
- [ ] Cancelling a pegged order removes it from the book and the pegged/parked slice.
- [ ] An expired pegged order is removed from the book and the pegged/parked slice.
- [ ] A filled pegged order is removed from the book and the pegged/parked slice.
- [ ] Pegged orders are not repriced and do not lose time priority when their specific reference price is unchanged, even if other peg reference prices move.
- [ ] If the midprice is calculated to be a fraction (e.g. 102.5), it should be rounded up for a buy and rounded down for a sell.

## Summary

Market Makers and some other market participants are interested in maintaining limit orders on the order book that are a defined distance from a reference price (i.e. best bid, mid and best offer/ask) rather than at a specific limit price. In addition to being impossible to achieve perfectly through simple Amend commands, this method also creates many additional transactions. These problems are enough of an issue for centralised exchanges that many implement pegged orders, which are automatically repriced when the reference price moves. For decentralised trading with greater constraints on throughput and potentially orders of magnitude higher latency, pegged orders are all but essential to maintain a healthy and liquid order book.

Pegged orders are limit orders where the price is specified of the form `REFERENCE +/- OFFSET`, therefore 'pegged' is a _price type_, and can be used for any limit order that is valid during continuous trading. A pegged order's price is calculated from the value of the reference price on entry to the order book. Pegged orders that are persistent will be repriced, losing time priority, _after processing any event_ which causes the `REFERENCE` price to change. Pegged orders are not permitted in some trading period types, most notably auctions, and pegged orders that are on the book at the start of such a period will be parked (moved to a separate off-book area) in time priority until they are cancelled or expire, or the market enters a period that allows pegs, in which case they are re-priced and added back to the order book. Pegged orders entered during a period that does not accept them will be added to the parked area. Pegged orders submitted to a market with a main trading mode that does not support pegged orders will be rejected. All pegged orders in the system are held in a sorted by entry time list so that actions like re-pricing and parking/unparking are performed in the same order as which the orders were entered into the system.

## Guide-level explanation

**Reference Price:** This is the price against which the final order priced is calculated. Possible options are best bid/ask and mid price.

**Offset:** This is a value added to the reference price. It can be negative and must be a multiple of the tick size.

When a party submits a new pegged order, only a LIMIT order is accepted. The party also specifies the reference price to which the order will be priced along with an offset to apply to this price. The reference price is looked up from the live market and the final price is calculated and used to insert the new order. The order is placed on the book at the back of the calculated price level.

Whenever the reference price changes all the pegged orders that rely on it need to be repriced. We run through a time sorted list of all the pegged orders that match the moved reference price and remove each order from the book, recalculate it's price and then reinsert it into the orderbook at the back of the price queue. Pegged orders which reference a price that has not changed are untouched. Following a price move margin checks take place on the positions of the parties. If a pegged order is to be inserted at a price level that does not currently exist, that price level is created. Likewise if a pegged order is the only order at a price level and it is removed, the price level is removed as well.

Pegged orders can be GTC or GTC TIF orders with IOC and FOK being added in the second phase of pegged orders. This means they might never land on the book or they can hit the book and be cancelled at any time and in the case of GTT they can expire and be removed from the book in the same way that normal GTT orders can.

If the reference point does not exist (e.g no best bid) or moves to such a value that it would create an invalid order once the offset was applied, the pegged order is parked. As the reference price moves, any orders on the parked list will be evaluated to see if they can come back into the order book.

When a pegged order is removed from the book due to cancelling, expiring or filling, the order details are removed from the pegged/parked orders list.

Pegged orders being added back into the book after being parked (either due to an auction or their reference price not being available) are treated the same as any other order being added to the book and therefore come after all persistent orders at that price level that are already on the book (i.e. the pegs are added to the end/back of the price level as if new incoming orders). This is also true if a pegged order is re-priced and its price changes, as price amendments are equivalent to a cancel/replace so the order enters at the back of its new price level.

When there are multiple pegged orders needing reprice, they must be repriced in order of entry (note: certain types of amend are considered amend in place and others as cancel/replace, for the cancel replace type, the entry time becomes the time of the amend, i.e. a pegged order loses its reprice ordering priority). Generally the way I’ve seen this is to maintain an ordered list of pegged orders for use in re-pricing (and parking/unparking), with new pegged orders added to the end of this list and cancel/replace amends causing the order to be removed from the list and re-added at the end.
# Reference-level explanation

Pegged orders are restricted in what values can be used when they are created, these can be defined by a list of rules each order must abide with.

| Type	                          | Side  |   Bid Peg   | Mid Peg |  Offer Peg  |
|---------------------------------|-------|-------------|---------|-------------|
| Persistent (GTC, GTT, etc.)	  | Buy	  | <= 0        | < 0     | Not allowed |
| Persistent (GTC, GTT, etc.)	  | Sell  | Not allowed | > 0     | >= 0        |
| Non persistent (IOC, FOK, etc.) |	Buy   | > 0         | > 0     | >= 0        |
| Non persistent (IOC, FOK, etc.) |	Sell  | <= 0        | < 0	  | < 0         |

As the calculation of mid price can result in an invalid result due to precision, the value will be rounded depending on which side of the book is being handled.

For persistent pegged orders:

Best bid = 100, best offer = 105 => mid = **102.5**<br>
A buy pegged to Mid - 1 should take the mid as 103, and thus be at 102<br>
A sell pegged to Mid + 1 should take the mid as 102, and thus be at 103

Pegged orders which are entered during an auction are placed directly on the parked queue. No margin checks will take place in this case even to validate the order would be allowed during normal trading. The margin checks will take place when the order is added to the live orderbook.


# Pseudo-code / Examples
Each market has a slice containing all the pegged orders. New pegged orders are added to the end of the slice to maintain time ordering.

    PeggedOrder{
        PeggedType type
        int64      offset
        OrderID    orderID
    }
    PeggedOrders []PeggedOrder

When a reference price is changed we scan through the pegged orders to update them

    for each item in the PeggedOrders slice
    { 
        if type is equal to the reference price change type
        {
            Remove order from the orderbook
            Update the order price
            Insert the order back into the orderbook at the back of the new price level
        }
    }

Extra functionality will be added to the expiring and cancelling steps

    for each order to cancel/expire
    {
        cancel/expire the order
        if order is pegged
        {
            remove order details from pegged list
        }
        if order is parked
        {
            remove order from parked list
        }
    }

# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.
* Insert a pegged order using all of the available reference types and an offset to make the order persistent.
* Insert a pegged order using all of the available reference types and an offset to make the order fill.
* Insert a pegged order using all of the available reference types and an offset to make the order partially fill.
* Insert a pegged order with TIF=GTT and let the order expire while still on the book.
* Insert all the pegged order types and cancel them.
* Insert a pegged order with a large negative offset and drive the price low to make the pegged price <= 0, verify that the order is parked. Move the price higher and verify that the order is unparked.
* Try to submit valid pegged orders during auction.
* Switch a market to auction and make sure the pegged orders are parked.
* Switch a market from auction to continuous trading to make sure the orders are unparked.
* Try to insert non LIMIT orders and make sure they are rejected.
* Test where both buy and sell orders are pegged against a mid which is not a whole number.

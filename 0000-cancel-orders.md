Feature name: feature-name
Start date: YYYY-MM-DD
Specification PR: https://gitlab.com/vega-protocol/product/pull/301

# Acceptance Criteria

- An order cancelled by orderID+marketID+partyID will be removed from the order book and an order update message will be emitted
- All orders for a given partyID will be removed from a single market if a cancel all party orders per market message is sent
- All orders for a given party across all markets will be removed from the vega system when a cancel all orders message is sent
- Orders which are not currently on the orderbook but are being held `offline` due to being in auction should also be affected by cancels.


# Summary

Orders stay on the order book until they are filled, expired or cancelled. A client can cancel orders in 3 ways, either directly given an orderID+marketID+partyID, cancel all orders for the partyID in a given market, or cancel all orders in the vega system for a given partyID. Each of these ways will remove the orders from the order book, and push out order update messages via the eventbus


# Guide-level explanation 

When an order is placed into the vega system, it is uniquely identified by it's orderID, marketID and traderID. The client has 3 ways to cancel orders which they have placed:

- Cancel by orderID, marketID and partyID - This removes at most one order from the order book
- Cancel by partyID and marketID - This removes all the orders for a given party in the given market.
- Cancel by partyID - This removes every order for that given party in the vega system. 

Parked orders are affected as part of direct cancels or cancels that sweep over a market/system.


# Reference-level explanation

## Cancel by orderID, partyID and marketID
The orderbook is looked up using the marketID and then we issue a cancel on that orderbook. Validation takes place to make sure the partyID supplied matches the partyID stored with the order. At most a single order will be cancelled using this method. As the order price is not supplied in the cancel and the order book stores all the orders via price level, the market has a separate map linking all orderIDs to their position in the order book. This allows cancellations to be performed efficiently.

## Cancel by partyID and marketID
The orderbook is looked up using the marketID. We then scan through all the orders on that orderbook looking for orders which match the partyID. Depending on the number of orders in the orderbook, this might be an inefficient operation. Each matching order is cancelled.

## Cancel by partyID
We iterate over every market in the system, getting the orderbook and scanning each order for a match with the partyID supplied. This process will touch every order in the vega system. It is much more efficient for the client to keep a record of their live orders and cancel them individually.

When sweeps are taking place across an orderbook the sweep must also include any offline or parked orders. Orders can be parked when the market has entered auction but the client should still be able to cancel these orders so that they are not added back to the orderbook once the auction is ended.

## Margin calculations
Cancelling an order does not trigger a margin recalculation for a party. This is true for all 3 ways of cancelling orders.

# Pseudo-code / Examples

## Cancel by orderID, partyID and marketID

    Lookup the orderbook by marketID
    Lookup up the order in that orderbook via the orderID
    If partyID matches
       Cancel the order and remove from the orderbook
    End

## Cancel by partyID and marketID

    Lookup up the orderbook by marketID
    For each order on the orderbook and parked storage
        If order.partyID == partyID
            Cancel the order and remove from the orderbook
        EndIf
    EndFor

## Cancel by partyID

    For each market
        For each orderbook
            For each order on the orderbook and parked storage
                If order.partyID == partyID
                    Cancel the order and remove from the orderbook
                EndIf
            EndFor
        EndFor
    EndFor


# Test cases

- Insert a single order and cancel it via orderID+marketID+partyID
- Insert a single order and cancel it via marketID+partyID
- Insert a single order and cancel it via partyID
- Insert a single order from 2 different traders and cancel one via orderID+marketID+partyID
- Insert a single order from 2 different traders and cancel one via partyID
- Insert a single order from 2 different traders and cancel one via marketID+partyID and MarketID
- Insert an order which is not for auction and enter into an auction to force the order to be parked. Cancel the order using all three methods and validate the order is cancelled.
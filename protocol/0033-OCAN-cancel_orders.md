# Cancel orders

## Acceptance Criteria

- An order cancelled by `orderID+marketID+partyID` will be removed from the order book and an order update message will be emitted (<a name="0033-OCAN-001" href="#0033-OCAN-001">0033-OCAN-001</a>). For product spot: (<a name="0033-OCAN-011" href="#0033-OCAN-011">0033-OCAN-011</a>)
- All orders for a given `partyID` will be removed from a single market if a cancel all party orders per market message is sent (<a name="0033-OCAN-002" href="#0033-OCAN-002">0033-OCAN-002</a>). For product spot: (<a name="0033-OCAN-012" href="#0033-OCAN-012">0033-OCAN-012</a>)
- All orders for a given party across all markets will be removed from the vega system when a cancel all orders message is sent (<a name="0033-OCAN-003" href="#0033-OCAN-003">0033-OCAN-003</a>). For product spot: (<a name="0033-OCAN-013" href="#0033-OCAN-013">0033-OCAN-013</a>)
- Orders which are not currently on the orderbook but are `parked` due to being in auction should also be affected by cancels. (<a name="0033-OCAN-004" href="#0033-OCAN-004">0033-OCAN-004</a>). For product spot: (<a name="0033-OCAN-014" href="#0033-OCAN-014">0033-OCAN-014</a>)
- A cancellation for a party that does not match the party on the order will be rejected (<a name="0033-OCAN-005" href="#0033-OCAN-005">0033-OCAN-005</a>). For product spot: (<a name="0033-OCAN-015" href="#0033-OCAN-015">0033-OCAN-015</a>)
- Margins must be recalculated after a cancel event (<a name="0033-OCAN-007" href="#0033-OCAN-007">0033-OCAN-007</a>)
- An order which is partially traded (has remaining volume), but still active, can be cancelled. (<a name="0033-OCAN-008" href="#0033-OCAN-008">0033-OCAN-008</a>)
- Cancelling an order for a party leaves its other orders on the current market unaffected. (<a name="0033-OCAN-009" href="#0033-OCAN-009">0033-OCAN-009</a>). For product spot: (<a name="0033-OCAN-016" href="#0033-OCAN-016">0033-OCAN-016</a>)
- Cancelling all orders on a market for a party by the "cancel all party orders per market message" leaves orders on other markets unaffected. (<a name="0033-OCAN-010" href="#0033-OCAN-010">0033-OCAN-010</a>). For product spot: (<a name="0033-OCAN-017" href="#0033-OCAN-017">0033-OCAN-017</a>)

## Summary

Orders stay on the order book until they are filled, expired or cancelled. A client can cancel orders in 3 ways, either directly given an `orderID+marketID`, cancel all orders in a given market, or cancel all orders in the vega system. Each of these ways will remove the orders from the order book, and push out order update messages via the eventbus

## Guide-level explanation

When an order is placed into the vega system, it is uniquely identified by it's `orderID`, `marketID` and `partyID`. The `partyID` is owned by the signer of the cancel transaction. The client has 3 ways to cancel orders which they have placed:

- Cancel by `orderID` and `marketID` - This removes at most one order from the order book
- Cancel by `marketID` - This removes all the orders for a given party in the given market.
- Cancel with no arguments - This removes every order for that given party in the Vega system.

Parked orders are affected as part of direct cancels or cancels that sweep over a market/system.

## Reference-level explanation

### Cancel by `orderID`, `partyID` and `marketID`

The orderbook is looked up using the `marketID` and then we issue a cancel on that orderbook. Validation takes place to make sure the `partyID` supplied matches the `partyID` stored with the order. At most a single order will be cancelled using this method. As the order price is not supplied in the cancel and the order book stores all the orders via price level, the market has a separate map linking all `orderIDs` to their position in the order book. This allows cancellations to be performed efficiently.

### Cancel by `partyID` and `marketID`

The orderbook is looked up using the `marketID`. We have a lookup table for each `partyID` that returns all the orders they have in the book. Each order for the `partyID` is cancelled.

### Cancel by `partyID`

We iterate over every market in the system. In each market we have a lookup table for each `partyID` that returns all the orders they have in the book. Each order for the `partyID` is cancelled.

When sweeps are taking place across an orderbook the sweep must also include any offline or parked orders. Orders can be parked when the market has entered auction but the client should still be able to cancel these orders so that they are not added back to the orderbook once the auction is ended.

### Margin calculations

Cancelling an order triggers a margin recalculation for a party. This is true for all 3 ways of cancelling orders.

## Pseudo-code / Examples

### Cancel by `orderID`, `partyID` and `marketID` example

    Lookup the orderbook by marketID
    Lookup up the order in that orderbook via the orderID
    If partyID matches
       Cancel the order and remove from the orderbook
    End

### Cancel by `partyID` and `marketID` example

    Lookup up the orderbook by marketID
    For each order in the market level lookup table
        If order.partyID == partyID
            Cancel the order and remove from the orderbook
        EndIf
    EndFor

### Cancel by `partyID` example

    For each market
        For each orderbook
            For each order in the market level lookup table
                If order.partyID == partyID
                    Cancel the order and remove from the orderbook
                EndIf
            EndFor
        EndFor
    EndFor

## Test cases

- Insert a single order and cancel it via `orderID+marketID+partyID`
- Insert a single order and cancel it via `marketID+partyID`
- Insert a single order and cancel it via `partyID`
- Insert a single order from 2 different traders and cancel one via `orderID+marketID+partyID`
- Insert a single order from 2 different traders and cancel one via `partyID`
- Insert a single order from 2 different traders and cancel one via `marketID+partyID` and `MarketID`
- Insert an order which is not for auction and enter into an auction to force the order to be parked. Cancel the order using all three methods and validate the order is cancelled.

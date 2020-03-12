Feature name: amends <br>
Start date: 2020-03-12 <br>
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests <br>

# Acceptance Criteria
- Only LIMIT orders can be amended, any attempt to amend a non LIMIT order will be rejected
- Price change amends will remove the order from the book and insert the order at the back of the queue at the new price level
- Reducing the quantity will leave the order in it's current spot but will reduce the remaining amount accordingly
- Increasing the quantity will cause the order to be removed from the book and inserted at the back of the price level queue with the updated quantity
- Changing the TIF can only occur between GTC and GTT. Any attempt to amend an another TIF flag will be rejected.
- All updated to an existing order will update the UpdatedAt timestamp field in the order
- The orderID remains the same after an amend
- Amends can occur in continuous trading or in an auction
- All historic alteration to an order can be viewed from the order storage system


# Summary
Amends can be sent into the VEGA system to alter fields on all persistent orders held within the order book.
The amend order will be able to alter the quantity, price and expiry time/TIF type. The altered order will still use the same orderID and creation time of the original order.


# Guide-level explanation
Explain the specification as if it was already included and you are explaining it to another developer working on Vega. This generally means:
- Introducing new named concepts
- Explaining the features, providing some simple high level examples
- If applicable, provide migration guidance

The amend order message is a custom message containing the orderID of the original order and optional fields that can be altered. Prices can be changed with a new absolute value, quantity can be reduced or increased from their current remaining size. Expiry time can be set to a new value and the TIF type can be toggled between GTC and GTT.

Some examples: <br>
A LIMIT order sitting on the bid side of the order book: <br>
Bids: 100@1000 GTC (OrderID V0000000001-0000000001) <br>

If I send an amend with the following details: <br>
amendOrder{ <br>
    orderID: "V0000000001-0000000001" <br>
    size: 200 <br>
} <br>

This will be the resulting order book: <br>
Bids: 200@1000 GTC (OrderID V0000000001-0000000001) <br>

Sending this amend order: <br>
amendOrder{ <br>
    orderID: "V0000000001-0000000001" <br>
    price: 1005 <br>
} <br>

Will result in this order book: <br>
Bids: 200@1005 GTC (OrderID V0000000001-0000000001) <br>

Unlike the message sent for a new order or a cancel, the amend message will only contain the fields that can be altered along with the orderID which is used to locate the original order.


# Reference-level explanation
The idea behind amends is to allow the client to alter an existing order atomically preserving order priority where possible.
Amending an order does not alter the orderID and creation time of the original order.
The fields which can be altered are:
- Price
  * Amending the price will cause the order to be removed from the book and re-inserted at the new price level. This can result in the order being filled if the price is moved to a level that would cross.
- Size
  * A size change is specified as a reduce-by or increase-by amount. This will be applied to both the Size and Remaining part of the order. In the case that the remining amount it reduced to zero or less, the order is cancelled.
- TimeInForce
  * The TIF enum can only be toggled between GTT and GTC. Amending to GTT will require an expiryTime value to be set. Amending to GTC will remove the expiryTime value.
- ExpiryTime
  * The Expiry time can be amended to any time in the future but only for orders that have a TIF set to GTT. Attempting to set the expiryTime to a time in the past will cause the amend to be rejected.


## Version numbering
To keep all versions of an order available for historic lookup, when an order is amended the new version of the order will have a new version number so we can correctly identify when fields have changed. Each version of the order will be stored in the storage system and the key will need to use the version number to prevent newer orders overwriting orders that have the same orderID


# Pseudo-code / Examples

message amendOrder { <br>
    orderID string <br>
    price   uint64 <br>
    size    uint64 <br>
    TIF     enum <br>
    expiryTime uint64 <br>
}

# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.

Test cases that need to be implemented to cover most of the edge cases are:
- Attempt to amend an order that does not exist. The amend should be rejected.
- Amend an order but using the same values as the original order. No order book actions should take place.
- Reduce-by the size of an order and verify that the order does not lose it's queue position.
- Reduce-by the size of an order so that the remaining is <=0. The order should be cancelled.
- Increase the price of a bid order to make it cross the book. The order should be fully/partially filled
- Amend the price of an order and validate that the order is updated, the orderID and createdAt are the same and the UpdatedAt field is correct.
- Attempt to amend an order to a TIF that is not GTC or GTT. The amend will be rejected.
- Attempt to amend a GTC order to GTT without setting an expiry time. The amend will be rejected.
- Attempt to amend the expiry time on an order to a time in the past. The amend will be rejected.

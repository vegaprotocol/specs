# Amends

## Acceptance Criteria

- Only LIMIT or PEGGED orders can be amended. Any attempt to amend a MARKET order is rejected (<a name="0004-AMND-001" href="#0004-AMND-001">0004-AMND-001</a>) for product spot: (<a name="0004-AMND-030" href="#0004-AMND-030">0004-AMND-030</a>)
- Price change amends remove the order from the book and insert the order at the back of the queue at the new price level (<a name="0004-AMND-002" href="#0004-AMND-002">0004-AMND-002</a>) for product spot: (<a name="0004-AMND-031" href="#0004-AMND-031">0004-AMND-031</a>)
- Reducing the quantity leaves the order in its current spot but reduces the remaining amount accordingly (<a name="0004-AMND-003" href="#0004-AMND-003">0004-AMND-003</a>) for product spot: (<a name="0004-AMND-032" href="#0004-AMND-032">0004-AMND-032</a>)
- Quantity after amendment must be a multiple of the smallest increment possible given the `Position Decimal Places` (PDP) specified in the [Market Framework](./0001-MKTF-market_framework.md), i.e. is PDP = 2 then quantity must be a whole multiple of 0.01. (<a name="0004-AMND-004" href="#0004-AMND-004">0004-AMND-004</a>) for product spot: (<a name="0004-AMND-032" href="#0004-AMND-032">0004-AMND-032</a>)
- Increasing the quantity causes the order to be removed from the book and inserted at the back of the price level queue with the updated quantity (<a name="0004-AMND-005" href="#0004-AMND-005">0004-AMND-005</a>) for product spot: (<a name="0004-AMND-033" href="#0004-AMND-033">0004-AMND-033</a>)
- Changing the `TIF` can only occur between `GTC` and `GTT`. Any attempt to amend to another `TIF` flag is rejected. A `GTT` must have an `expiresAt` value but a `GTC` must not have one.  (<a name="0004-AMND-006" href="#0004-AMND-006">0004-AMND-006</a>) for product spot: (<a name="0004-AMND-034" href="#0004-AMND-034">0004-AMND-034</a>)
- Any attempt to amend to or from the `TIF` values `GFA` and `GFN` will result in a rejected amend. (<a name="0004-AMND-007" href="#0004-AMND-007">0004-AMND-007</a>) for product spot: (<a name="0004-AMND-035" href="#0004-AMND-035">0004-AMND-035</a>)
- All updates to an existing order update the `UpdatedAt` time stamp field in the order (<a name="0004-AMND-008" href="#0004-AMND-008">0004-AMND-008</a>) for product spot: (<a name="0004-AMND-036" href="#0004-AMND-036">0004-AMND-036</a>)
- The `orderID` remains the same after an amend (<a name="0004-AMND-009" href="#0004-AMND-009">0004-AMND-009</a>) for product spot: (<a name="0004-AMND-037" href="#0004-AMND-037">0004-AMND-037</a>)
- Amends can occur in continuous trading or in an auction (<a name="0004-AMND-010" href="#0004-AMND-010">0004-AMND-010</a>) for product spot: (<a name="0004-AMND-038" href="#0004-AMND-038">0004-AMND-038</a>)
- All historic alteration to an order can be viewed from the order storage system (<a name="0004-AMND-011" href="#0004-AMND-011">0004-AMND-011</a>) for product spot: (<a name="0004-AMND-039" href="#0004-AMND-039">0004-AMND-039</a>)
- All amendable fields can be amended in the same amend message (<a name="0004-AMND-012" href="#0004-AMND-012">0004-AMND-012</a>) for product spot: (<a name="0004-AMND-040" href="#0004-AMND-040">0004-AMND-040</a>)
- Fields left with default values (0) are not handled as part of the amend action (<a name="0004-AMND-013" href="#0004-AMND-013">0004-AMND-013</a>) for product spot: (<a name="0004-AMND-041" href="#0004-AMND-041">0004-AMND-041</a>)
- An amend with only the same values as the order still cause the `UpdateAt` field to update but nothing else (<a name="0004-AMND-014" href="#0004-AMND-014">0004-AMND-014</a>) for product spot: (<a name="0004-AMND-042" href="#0004-AMND-042">0004-AMND-042</a>)
- Amending a pegged orders offset or reference will force a reprice (<a name="0004-AMND-015" href="#0004-AMND-015">0004-AMND-015</a>) for product spot: (<a name="0004-AMND-043" href="#0004-AMND-043">0004-AMND-043</a>)
- Attempting to alter pegged details on a non pegged or will cause the amend to be rejected (<a name="0004-AMND-016" href="#0004-AMND-016">0004-AMND-016</a>) for product spot: (<a name="0004-AMND-044" href="#0004-AMND-044">0004-AMND-044</a>)
- A parked pegged order can be amended. (<a href="./0037-OPEG-pegged_orders.md#0037-OPEG-014">0037-OPEG-014</a>) for product spot: (<a href="./0037-OPEG-pegged_orders.md#0037-OPEG-019">0037-OPEG-019</a>)
- Attempting to alter details on a filled order will cause the amend to be rejected (<a name="0004-AMND-017" href="#0004-AMND-017">0004-AMND-017</a>) for product spot: (<a name="0004-AMND-045" href="#0004-AMND-045">0004-AMND-045</a>)
- Attempting to alter details on a cancelled order will cause the amend to be rejected (<a name="0004-AMND-018" href="#0004-AMND-018">0004-AMND-018</a>) for product spot: (<a name="0004-AMND-046" href="#0004-AMND-046">0004-AMND-046</a>)
- Attempting to alter details on an expired order will cause the amend to be rejected (<a name="0004-AMND-019" href="#0004-AMND-019">0004-AMND-019</a>) for product spot: (<a name="0004-AMND-047" href="#0004-AMND-047">0004-AMND-047</a>)
- Amending expiry time of an active GTT order to a past time whilst also simultaneously amending the price of the order will cause the order to immediately expire with the order details updated to reflect the order details requiring amendment (<a name="0004-AMND-029" href="#0004-AMND-029">0004-AMND-029</a>) for product spot: (<a name="0004-AMND-048" href="#0004-AMND-048">0004-AMND-048</a>)

For a party with no position on a given market:

- Amending an order in a way that increases the volume sufficiently leads to margin account balance increasing (<a name="0004-AMND-021" href="#0004-AMND-021">0004-AMND-021</a>)
- In Spot market amending an order in a way that increases the volume sufficiently leads to holding account balance increasing (<a name="0004-AMND-049" href="#0004-AMND-049">0004-AMND-049</a>)
- Amending an order in a way that decreases the volume sufficiently leads to margin account balance decreasing (<a name="0004-AMND-022" href="#0004-AMND-022">0004-AMND-022</a>)
- In Spot market amending an order in a way that decreases the volume sufficiently leads to holding account balance decreasing (<a name="0004-AMND-050" href="#0004-AMND-050">0004-AMND-050</a>)
- It is possible to amend a fractional size order (<a name="0004-AMND-025" href="#0004-AMND-025">0004-AMND-025</a>) for product spot: (<a name="0004-AMND-051" href="#0004-AMND-051">0004-AMND-051</a>)
- It is possible to amend a partially filled limit order (<a name="0004-AMND-026" href="#0004-AMND-026">0004-AMND-026</a>) for product spot: (<a name="0004-AMND-052" href="#0004-AMND-052">0004-AMND-052</a>)
- It is possible to amend a versioned order (already amended several times) (<a name="0004-AMND-027" href="#0004-AMND-027">0004-AMND-027</a>) for product spot: (<a name="0004-AMND-053" href="#0004-AMND-053">0004-AMND-053</a>)
- Attempts to amend order fields not in scope are rejected (<a name="0004-AMND-028" href="#0004-AMND-028">0004-AMND-028</a>) for product spot: (<a name="0004-AMND-054" href="#0004-AMND-054">0004-AMND-054</a>)

## Summary

Amends are sent into the VEGA system to alter fields on all persistent orders held within the order book.
The amend order can alter the quantity, price and expiry time/`TIF` type. For pegged orders they can also alter the reference and the offset value. The altered order still uses the same `orderID` and creation time of the original order. Every valid amend will cause the `UpdatedAt` field to be updated.

## Guide-level explanation

The amend order message is a custom message containing the `orderID` of the original order and optional fields that can be altered. Prices can be changed with a new absolute value, quantity can be reduced or increased from their current remaining size. Expiry time can be set to a new value and the `TIF` type can be toggled between `GTC` and `GTT`. Changing the `TIF` field will impact the value in the `ExpiryTime` field as it will either be blanked or set to a new valid value.

Some examples:
A LIMIT order sitting on the bid side of the order book:

`Bids: 100@1000 GTC (OrderID V0000000001-0000000001)`

If I send an amend with the following details:

```json
amendOrder{
    orderID: "V0000000001-0000000001"
    sizeDelta: 200
}
```

This will be the resulting order book:

`Bids: 300@1000 GTC (OrderID V0000000001-0000000001)`

Sending this amend order:

```json
amendOrder{
    orderID: "V0000000001-0000000001"
    price: 1005
}
```

Will result in this order book:

`Bids: 300@1005 GTC (OrderID V0000000001-0000000001)`

Unlike the message sent for a new order or a cancel, the amend message only contains the fields that can be altered along with the `orderID` which is used to locate the original order.

## Reference-level explanation

The idea behind amends is to allow the client to alter an existing order atomically preserving order priority where possible. Multiple fields can be amended at the same time inside the same amend order message. Fields not specified in the amend message will not be handled as part of the amend.
Amending an order does not alter the `orderID` and creation time of the original order.
The fields which can be altered are:

- `Price`
  - Amending the price causes the order to be removed from the book and re-inserted at the new price level. This can result in the order being filled if the price is moved to a level that would cross.
- `SizeDelta`
  - A size change is specified as a delta to the current amount. This will be applied to both the `Size` and `Remaining` part of the order. In the case that the remaining amount it reduced to zero or less, the order is cancelled. This must be a multiple of the smallest value allowed by the `Position Decimal Places` (PDP) specified in the [Market Framework](./0001-MKTF-market_framework.md), i.e. is PDP = 2 then `SizeDelta` must be a whole multiple of 0.01. (NB: `SizeDelta` may use an int64 where the int value 1 is the smallest multiple allowable given the configured dp). In case PDP is negative this again applies e.g. if PDP = -1 then `SizeDelta` must be a whole multiple of 10.
- `TimeInForce`
  - The `TIF` enumeration can only be toggled between `GTT` and `GTC`. Amending to `GTT` requires an `expiryTime` value to be set. Amending to `GTC` removes the `expiryTime` value.
- `ExpiryTime`
  - The Expiry time can be amended to any time in the future but only for orders that have a `TIF` set to `GTT`. Attempting to set the `expiryTime` to a time before the `creationTime` causes the amend to be rejected. Setting the `expiryTime` to a value after `creationTime` but before the current time will cause it to expire.
- `PeggedOrder.Reference`
  - The reference peg to which the order is related
- `PeggedOrder.Offset`
  - The offset of the order from the reference price

## Version numbering

To keep all versions of an order available for historic lookup, when an order is amended the new version of the order has a new version number so we can correctly identify when fields have changed. Each version of the order is stored in the storage system and the key will need to use the version number to prevent newer orders overwriting orders that have the same `orderID`. No-op amends that only update the `UpdatedAt` timestamp do not increment the version number.

## Pseudo-code / Examples

```json
message amendOrder {
    string orderID 1 [(validator.field) = {string_not_empty : true}];
    uint64 price 2;
    int64  sizeDelta 3;
    enum   TIF 4;
    int64  expiryTime 5;
    PeggedOrder *peggedOrder 6;
}
```

An example of using a negative size is shown below:

`Bids: 100@1000 GTC (OrderID V0000000001-0000000001)`

If we send the following `amendOrder`:

```json
amendOrder{ orderID:"V0000000001-0000000001",
            sizeDelta: -50 }
```

The resulting order book will be:

`Bids: 50@1000 GTC (OrderID V0000000001-0000000001)`

## Test cases

Test cases that need to be implemented to cover most of the edge cases are:

- Attempt to amend an order that does not exist. The amend is rejected.
- Amend an order but using the same values as the original order. No order book actions takes place.
- Reduce-by the size of an order and verify that the order does not lose it's queue position.
- Reduce-by the size of an order so that the remaining is less than or equal to zero. The order is cancelled.
- Increase the price of a bid order to make it cross the book. The order is fully/partially filled
- Amend the price of an order and validate that the order is updated, the `orderID` and `createdAt` are the same and the `updatedAt` field is correct.
- Attempt to amend an order to a `TIF` that is not `GTC` or `GTT`. The amend is rejected.
- Attempt to amend a `GTC` order to `GTT` without setting an expiry time. The amend is rejected.
- Attempt to amend the expiry time on an order to a time in the past. The amend is rejected.
- Attempt to amend all of the amendable fields at the same time with valid values.
- Attempt to amend all of the amendable fields at the same time but with one invalid value which should force the amend to be rejected.
- Send amends with only one amendable field specified with the current value in it. The amend will be accepted but nothing apart from the `updatedAt` field will be changed.
- Attempt to amend a pegged order to use a different reference price
- Attempt to amend a pegged order to use a different offset value
- Attempt to add pegged details to a non pegged order to make sure the amend is rejected

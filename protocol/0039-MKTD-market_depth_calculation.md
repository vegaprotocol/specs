# Market depth calculations

## Acceptance Criteria

- The market depth builder must be able to handle all available order types (<a name="0039-MKTD-001" href="#0039-MKTD-001">0039-MKTD-001</a>) for product spot: (<a name="0039-MKTD-020" href="#0039-MKTD-020">0039-MKTD-020</a>)
- Entering and leaving auctions must be handled correctly (<a name="0039-MKTD-003" href="#0039-MKTD-003">0039-MKTD-003</a>) for product spot: (<a name="0039-MKTD-021" href="#0039-MKTD-021">0039-MKTD-021</a>)
- All subscribed clients must receive all the data necessary to build their own view of the market depth (<a name="0039-MKTD-004" href="#0039-MKTD-004">0039-MKTD-004</a>) for product spot: (<a name="0039-MKTD-022" href="#0039-MKTD-022">0039-MKTD-022</a>)
- Adding a new limit order to the book updates the market depth at the corresponding price and volume (<a name="0039-MKTD-005" href="#0039-MKTD-005">0039-MKTD-005</a>) for product spot: (<a name="0039-MKTD-023" href="#0039-MKTD-023">0039-MKTD-023</a>)
- Cancelling an existing order reduces the volume in the market depth view and removes the price level if the volume reaches zero (<a name="0039-MKTD-006" href="#0039-MKTD-006">0039-MKTD-006</a>) for product spot: (<a name="0039-MKTD-024" href="#0039-MKTD-024">0039-MKTD-024</a>)
- Fully or partially filling an order will reduce the market depth volume at that given price level (<a name="0039-MKTD-007" href="#0039-MKTD-007">0039-MKTD-007</a>) for product spot: (<a name="0039-MKTD-025" href="#0039-MKTD-025">0039-MKTD-025</a>)
- A GTT order that expires will cause the volume at its price to be reduced in the market depth view (<a name="0039-MKTD-008" href="#0039-MKTD-008">0039-MKTD-008</a>) for product spot: (<a name="0039-MKTD-026" href="#0039-MKTD-026">0039-MKTD-026</a>)
- Amending an order in place (price stays the same but the volume is reduced) will cause the volume at the given price to be reduced in the market depth view (<a name="0039-MKTD-009" href="#0039-MKTD-009">0039-MKTD-009</a>) for product spot: (<a name="0039-MKTD-027" href="#0039-MKTD-027">0039-MKTD-027</a>)
- Amending an order such that a cancel replace is performed will cause the volume in the market depth to be updated correctly (<a name="0039-MKTD-010" href="#0039-MKTD-010">0039-MKTD-010</a>) for product spot: (<a name="0039-MKTD-028" href="#0039-MKTD-028">0039-MKTD-028</a>)
- Entering an auction will cause any GFN orders to be removed from the market depth volume view (<a name="0039-MKTD-012" href="#0039-MKTD-012">0039-MKTD-012</a>) for product spot: (<a name="0039-MKTD-029" href="#0039-MKTD-029">0039-MKTD-029</a>)
- Market depth will show a crossed book if the market is in auction and the book is crossed (<a name="0039-MKTD-013" href="#0039-MKTD-013">0039-MKTD-013</a>) for product spot: (<a name="0039-MKTD-030" href="#0039-MKTD-030">0039-MKTD-030</a>)
- Leaving an auction will cause any GFA orders to be removed from the market depth view (<a name="0039-MKTD-014" href="#0039-MKTD-014">0039-MKTD-014</a>) for product spot: (<a name="0039-MKTD-033" href="#0039-MKTD-033">0039-MKTD-033</a>)
- Pegged orders are part of the market depth view and should update the view when their orders are repriced (<a name="0039-MKTD-015" href="#0039-MKTD-015">0039-MKTD-015</a>)
- Each delta update will have the new sequence number along with the previous sequence number which will match the previous delta update (<a name="0039-MKTD-018" href="#0039-MKTD-018">0039-MKTD-018</a>) for product spot: (<a name="0039-MKTD-031" href="#0039-MKTD-031">0039-MKTD-031</a>)
- The sequence number received as part of the market depth snapshot will match the sequence number of a delta update (<a name="0039-MKTD-019" href="#0039-MKTD-019">0039-MKTD-019</a>) for product spot: (<a name="0039-MKTD-032" href="#0039-MKTD-032">0039-MKTD-032</a>)

## Summary

The market depth builder receives a stream of events from the core from which it builds up a market depth structure for each given market. This structure is used to provide a market depth stream and full market depth dump to any clients which have requested/subscribed to it.

## Guide-level explanation

When the core processes an external action such as an order, cancel, amend or changing auction state, it generates one or more events which are sent out via the event-bus.

The market depth module subscribes to all the event types in the market-event and order-event streams. From the events received from these event streams, we build up a market depth structure for each market which will be a representation of the orderbook stored in the core.

Clients connect to a vega node and subscribe to a `MarketDepth` stream via gRPC or GraphQL for a specific market. This stream will contain all the updates occurring to the market depth structure and will contain a current and previous sequence number with each update. The client then makes a request to get a snapshot dump of the market depth state. This dump will contain the full market depth structure at the current time along with a sequence number for the current state. The client will then apply all updates that have a sequence number higher than the original dump to the market depth structure to keep it up to date. The client will be able to use the current and previous sequence numbers to confirm all messages are received.

The market depth information should include pegged order volume.

The volume at each level is the combined volume for all normal, pegged and market making orders. In the future they may be split up to allow clients to see a more detailed view of each level.

`Cumulative volume` is the total volume in the book between the current price level and top of the book. The market depth service will not build this information, instead we will rely on the client building it.

Updates should be sent as soon as they are ready and not batched up. This increases the data rate for clients, but ensures the updates are sent as quickly as possible.

## Reference-level explanation

The market depth builder needs to receive enough information from the core to be able to build the market depth structure to have exactly the same price and volume details as the order book stored in the matching-engine. Therefore any change to the order book in the matching engine must generate one or more events that can be used to update the market depth order book in the same way. After the market depth structure is updated we increment the sequence number. Therefore every sequence number reflects a single update in the market depth structure.

The possible actions we know that can happen in the market engine are:

- Create a new order on the book
  - Send the order details in a new order event
- Cancel an existing order
  - Send the cancel details in an order event
- Fully/Partially fill an order on the book
  - Send the order update details in an order event
- Expire an order
  - Send the expire details in an order event
- Amend an order in place
  - Send an order event with the new details in
- Cancel/Replace amend an order
  - Send an order event with the new details in
- Enter auction
  - Send cancels/new order events for all orders that change
- Leave auction
  - Send cancels/new order events for all orders that change
- Pegged orders
  - Send cancels/new order events for all orders that change

Market depth information is not as detailed as the full orderbook. We have no need to store the individual orders, order ids and order types. The only information needed is the book side, price level, the number of orders at that level and the total volume at that level.

Clients are able to subscribe to a market to receive the market depth information. To enable a better experience in the GUI and to prevent the concept of blocks from affecting the client we will send updates as they occur and not at the end of each block.

When a new event arrives at the market depth builder, we apply the change to our market depth structure and then send a copy of the price level details for the affected price level. The client is responsible for applying that update to their copy of market depth structure.

### Cumulative Volume

The cumulative volume at each level is a useful thing for clients to know but it is difficult for the service to keep up to date in a live system. Therefore this calculation will not be performed by the market depth system. The client will be responsible for generating this data if and when they need it.

## Pseudo-code / Examples

The definition of the market depth structure is:

    type MarketDepth struct {
        MarketID    string
        Buy         []PriceLevel
        Sell        []PriceLevel
        SequenceNum uint64
    }

    type PriceLevel struct {
        Price             int64
        Volume            uint64
        NumOfOrders       uint64
        Side              bool
    }

An update message is:

    type UpdateMarketDepth struct {
        SequenceNum uint64
        PrevSeqNum  uint64
        Price       int64
        Volume      uint64
        NumOfOrders uint64
    }

The server side process to handle updates can be described as such:

    Forever
        Receive update from matching engine
        Apply update to the market depth structure and record which price levels have been touched
        Send updates to all subscribers for price levels that changed
    End

The client side will perform the following steps to build and keep an up to date market depth structure

    Subscribe to market depth updates
    Request current market depth structure
    Forever
        Receive market depth update
        Verify that the prevSeqNum of this message matches the SeqNum of the previous message
        If update sequence number is above current sequence number
            Apply update to the market depth structure
        Else
            Old update, ignore it
        End
    End

## Test cases

- Create a new order in an empty order book, verify MD
- Cancel an existing order, verify MD
- Amend an existing order for both price and quantity, verify MD
- Cancel an order and replace it with the same order values, verify the MD sees an update
- Do nothing for many minutes, make sure subscribers do not timeout/fail
- Send a large spike of order updates, make sure the system does not stall
- Sequence number is larger for each emitted book update

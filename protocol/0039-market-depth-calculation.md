# Acceptance Criteria
- The market depth builder must be able to handle all available order types
- The construction of the market depth structure must not impact the core performance.
- Entering and leaving auctions must be handled correctly
- All subscribed clients must receive all the data necessary to build their own view of the market depth
- There should be no batching in sending out market depth updates


# Summary
The market depth builder receives a stream of events from the core from which it builds up a market depth structure for each given market. This structure is used to provide a market depth stream and full market depth dump to any clients which have requested/subscribed to it. 

# Guide-level explanation
When the core processes an external action such as an order, cancel, amend or changing auction state, it generates one or more events which are sent out via the event-bus. 

The market depth module subscribes to all the event types in the market-event and order-event streams. From the events received from these event streams, we build up a market depth structure for each market which will be a representation of the orderbook stored in the core. When the market is created the sequence number of the market depth structure is set to zero. Every update from then onwards increments the sequence number by one.

Clients connect to a vega node and subscribe to a MarketDepth stream via gRPC or GraphQL for a specific market. This stream will contain all the updates occurring to the market depth structure and will contain a sequence number with each update. The client then makes a request to get a snapshot dump of the market depth state. This dump will contain the full market depth structure at the current time along with a sequence number for the current state. The client will then apply all updates that have a sequence number higher than the original dump to the market depth structure to keep it up to date.

The market depth information should include pegged order volume.

The volume at each level should be split into normal, pegged and market making order volumes to allow them to be drawn with different attributes in the console.

Best bid/ask pairs should be generated for all orders and for all orders excluding pegged.

`Cumulative volume` is the total volume in the book between the current price level and top of the book. The market depth service will not build this information, instead we will rely on the client building it.


# Reference-level explanation

The market depth builder needs to receive enough information from the core to be able to build the market depth structure to have exactly the same price and volume details as the order book stored in the matching-engine. Therefore any change to the order book in the matching engine must generate one or more events that can be used to update the market depth order book in the same way. After the market depth structure is updated we increment the sequence number. Therefore every sequence number reflects a single update in the market depth structure.

The possible actions we know that can happen in the market engine are:

- Create a new order on the book
  * Send the order details in a new order event
- Cancel an existing order
  * Send the cancel details in an order event
- Fully/Partially fill an order on the book
  * Send the order update details in an order event
- Expire an order
  * Send the expire details in an order event
- Amend an order in place
  * Send an order event with the new details in
- Cancel/Replace amend an order
  * Send an order event with the new details in
- Enter auction
  * Send cancels/new order events for all orders that change
- Leave auction
  * Send cancels/new order events for all orders that change
- Pegged orders
  * Send cancels/new order events for all orders that change

Market depth information is not as detailed as the full orderbook. We have no need to store the individual orders, order ids and order types. The only information needed is the book side, price level, the number of orders at that level and the total volume at that level.

Clients are able to subscribe to a market to receive the market depth information. To enable a better experience in the GUI and to prevent the concept of blocks from affecting the client we will send updates as they occur and not at the end of each block. 

When a new event arrives at the market depth builder, we apply the change to our market depth structure and then send a copy of the price level details for the affected price level. The client is responsible for applying that update to their copy of market depth structure.

## Cumulative Volume

The cumulative volume at each level is a useful thing for clients to know but it is difficult for the service to keep up to date in a live system. Therefore this calculation will not be performed by the market depth system. The client will be responsible for generating this data if and when they need it.

# Pseudo-code / Examples

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
        CumulativeVolume  uint64
        NumOfOrders       uint64
        Side              bool
    }

An update message is:

    type UpdateMarketDepth struct {
        SequenceNum uint64
        Price       int64
        Volume      uint64
        NumOfOrders uint64
        Delta       int64
        Direction   bool // bid or ask
        Reason      action enum // Cancel, fill, amend etc
    }


The server side process to handle updates can be described as such:

    Forever
        Receive update from matching engine
        Apply update to the market depth structure and record which price levels have been touched
        Increment market depth sequence number
        Send updates to all subscribers for price levels that changed
    End


The client side will perform the following steps to build and keep an up to date market depth structure

    Subscribe to market depth updates
    Request current market depth structure
    Forever
        Receive market depth update
        If update sequence number in one above current sequence number
            Apply update to the market depth structure
            Increment the sequence number
        Else
            If update sequence number > market depth sequence number+1
                We are missing an update, throw an error 
            Else
  	            Old update, ignore it
            End
        End
    End


# Test cases

* Create a new order in an empty order book, verify MD
* Cancel an existing order, verify MD
* Amend an existing order for both price and quantity, verify MD
* Cancel an order and replace it with the same order values, verify the MD sees an update
* Enter into auction
* Leave auction
* Do nothing for many minutes, make sure subscribers do not timeout/fail
* Send a large spike of order updates, make sure the system does not stall
* Sequence number increments for each emitted book update
* Updates that are not received/processed by the client are not buffered on their behalf


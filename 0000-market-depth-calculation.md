Feature name: feature-name
Start date: 2020-06-10
Specification PR: https://gitlab.com/vega-protocol/product/pull/300

# Acceptance Criteria
- The market depth builder must be able to handle all available order types
- The construction of the market depth structure must not impact the core performance.
- Entering and leaving auctions must be handled correctly
- All subscribed clients must receive all the data neccessary to build their own view of the market depth
- There should be no batching in sending out market depth updates


# Summary
The market depth builder receives a stream of events from the core from which it builds up an market depth structure for each given market. This structure is used to provide a market depth stream and full market depth dump to any clients which has requested/subscribed to it. 

# Guide-level explanation
When the core processes orders, cancels, amends or auction states, it generates one or more events which are sent out via the event-bus. 

The market depth module subscribes to all the event types in the market-event and order-event streams. From the events received from these event streams, we build up a market depth structure for each market which will be a representation of the orderbook stored in the core. 

Clients connect to a vega node and subscribe to a MarketDepth stream via gRPC or GraphQL for a specific market. This stream will contain all the updates occuring to the market depth structure and will contain a sequence number with each update. The client then makes a request to get a snapshot dump of the market depth state. This dump will contain the full market depth structure at the current time along with a sequence number for the current state. The client will then apply all updates that have a sequence number higher than the original dump to the market depth structure to keep it up to date.


# Reference-level explanation (This is the main portion of the specification. Break it up as required.)

The market depth builder needs to receive enough information from the core to be able to build the market depth structure to have exactly the same price and volume details as the order book stored in the matching-engine. Therefore any change to the order book in the matching engine must generate one or more events that can be used to update the market depth order book in the same way.

The possible actions we know that can happen in the market engine are:

- Create a new order on the book
  * Send the order details in a new order event
- Cancel an existing order
  * Send the cancel details in a cancel event
- Fully/Partially fill an order on the book
  * Send the order update details in an order event
- Expire an order
  * Treat like a cancel
- Amend an order in place
  * Send an amend order event
- Cancel/Replace amend an order
  * Send a cancel and a replace event
- Enter auction
  * Send an entering auction event **OR**
  * Send cancels/new order events for all orders that change
- Leave auction
  * Send a leaving auction event **OR**
  * Send cancels/new order events for all orders that change
- Pegged orders
  * Generate cancel/new when orders move **OR**
  * Generate amends for changed orders **OR**
  * Send price change to the MarketDepth system to handle

Market depth information is not as detailed as the full orderbook. We have no need to store the individual orders, order ids and order types. The only information needed is the book side, price level, the number of orders at that level and the total volume at that level.

Clients are able to subscribe to a market to receive the market depth information. To enable a better experience in the GUI and to prevent the concept of blocks from affecting the client we will send updates as they occur and not at the end of each block. 

When a new event arrives at the market depth builder, we apply the change to our market depth structure and then send a copy of the price level details for the affected price level. The client is responsible for applying that update to their copy of market depth structure.


# Pseudo-code / Examples

The definition of the market depth structure is:

    type MarketDepth struct {
        MarketID string
	    Buy      []PriceLevel
	    Sell     []PriceLevel
    }

    type PriceLevel struct {
        Price       int64
        Volume      uint64
        NumOfOrders uint64
		Side        bool
    }

An update message is:

    type UpdateMarketDepth struct {
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


Feature name: feature-name
Start date: 2020-06-10
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Acceptance Criteria
- The market depth must be able to handle all available order types
- The construction of the market depth must not impact the core performance.
- Entering and leaving auctions must be handled correctly


# Summary
The market depth builder receives a stream of events from the core from which it builds up an order book for each given market. This order book is used to provide a market depth stream to any clients which have subscribed to it. The entire market depth data is pushed to each subscriber at the end of every block.

# Guide-level explanation
When the core processes orders, cancels, amends or auction states, it generates one or more events which are sent out via the event-bus. 

The market depth module subscribes to all the event types in the market-event and order-event streams. From the events received from these event streams, we build up an order book for each market which will be an exact copy of the orderbook stored in the core. 

Clients connect to a vega node and subscribe to MarketDepth data via gRPC or GraphQL for a specific market, we use the constructed order book to send data to each subscriber when the order book changes.


# Reference-level explanation (This is the main portion of the specification. Break it up as required.)

The market depth builder needs to receive enough information from the core to be able to build the order book to be exactly the same as the order book stored in the matching-engine. Therefore any change to the order book in the matching engine must generate one or more events that can be used to update the market depth order book in the same way.

The possible actions we know that can happen in the market engine are:

- Create a new order on the book
- Cancel an existing order
- Fully/Partially fill an order on the book
- Expire an order
- Amend an order in place
- Cancel/Replace amend an order
- Enter auction
- Leave auction

# Pseudo-code / Examples (If you have some data types, or sample code to show interactions, put it here)

The structure of the market depth order book is:

type MarketDepth struct {
	MarketID string
	Buy  	 []PriceLevel
	Sell 	 []PriceLevel
}

type PriceLevel struct {
	Price 		int64
	Volume 		uint64
	NumOfOrders uint64
}


# Test cases (Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.)
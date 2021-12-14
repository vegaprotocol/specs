Feature name: matching-engine
Start date: 2021-12-14

# Acceptance Criteria
 * The matching engine co-ordinates the trading of incoming orders with existing orders already on an order book.
 * The matching engine will place orders onto the order book if they are persistent and do not match an existing order.
 * The matching engine can be run in either auction mode or continuous trading mode.
 * The matching engine allows orders on the book to be removed.
 * The matching engine allows orders on the book to be amended.
 * The matching engine can supply information about best prices/volumes and indicative uncrossing prices/volumes.

# Summary
The matching engine is responsible for updating and maintaining the state of the order book. The order book contains two lists of orders in price and time order, one for the buy side and one for the sell side. As new orders come into the matching engine, they are analysed to see if they will match against current orders to create trades or will be placed in the order book if they are persistent order types. If the matching engine is running in continuous trading mode, the matching will take place as the orders arrive. If it is running in auction mode, all the orders are placed on the order book and are only matched when we attempt to leave the auction. Indicative price and volume details are generated during an auction after each new order is added.

# Guide-level explanation
The machine engine consists of an order book and the logic to handle new orders arriving into the engine. The matching engine can be in one of two possible states, continuous trading or auction trading. In continuous trading the incoming orders are processed immediately. In auction mode incoming orders are placed on the order book and are not processed for matching until we attempt to uncross. 

## Continuous Mode
New orders arrive at the engine and are checked for validity including if they are of the right type (not GFA). If the order can be matched to an order already on the book, that matching will take place. If the order does not match against an existing order and the order type is persistent, we place the order into the correct side of the order book at the price level given by the order. If there are already orders in the book at the same price level, the new order will be added after all existing orders at that price to keep the time ordering correct. If a cancel order is received, we remove the existing order from the order book. If an amend order is received we remove the existing order and re-insert the amended version.

## Auction Mode
New orders arrive at the engine and no matching is performed. Instead the order is checked for validity (GFA) and then placed directly onto the order book in price and time priority. When the auction is uncrossed, orders which are in the crossed range are matched until there are no further orders crossed.



# Reference-level explanation
This is the main portion of the specification. Break it up as required.

# Pseudo-code / Examples
If you have some data types, or sample code to show interactions, put it here

# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.

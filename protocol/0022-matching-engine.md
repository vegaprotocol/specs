Feature name: matching-engine
Start date: 2021-12-14

# Acceptance Criteria
 * The matching engine co-ordinates the trading of incoming orders with existing orders already on an order book.
   * Continuous Trading 
     * IOC
       * Incoming MARKET orders will be matched against the opposite side of the book, if not enough volume is available to fully fill the order, the remaining will be cancelled.
       * Incoming LIMIT orders will be matched against the opposite side of the book, if there is no match the order will be cancelled. If there is a partial match then the remaining will be cancelled.
       * Incoming PEGGED orders will be repriced and placed on the book if possible. If the price is invalid it will be parked.
     * FOK
       * Incoming MARKET orders will be matched fully if the volume is available, otherwise the order is cancelled.
       * Incoming LIMIT orders will be matched if possible to the other side of the book, if a complete fill is not possible the order is cancelled.
       * Incoming PEGGED orders will be repriced and placed on the book if possible. If the price is invalid it will be parked.
     * GTC/GTT/GFN
       * Incoming MARKET orders are rejected.
       * Incoming LIMIT orders match if possible, any remaining is placed on the book.
       * Incoming PEGGED orders are repriced and placed on the book if the price is valid, otherwise they are parked.
     * Entering auction is possible if the volume on either side of the book is empty.
     * Entering auction is possible if the mark price moves by a larger amount than the price monitoring settings allow.
     * All attempts to self trade are prevented and any partially filled orders are STOPPED
   * Auction Trading
     * IOC/FOK/GFN
       * Incoming orders are all rejected
     * GTC/GTT/GFA
       * All MARKET orders are rejected
       * LIMIT orders are placed into the book and no matching takes place.
       * The indicative price and volume values are updated after every change to the order book.
       * PEGGED orders are parked.
   * Moving to auction
     * All GFN orders are cancelled
     * Pegged orders are parked
   * Moving out of auction
     * The book is uncrossed.
     * Self trading is allowed.
     * All GFA orders are cancelled.
     * Pegged orders are repriced where possible.
  * Any persistent order can be deleted.
  * The price of any persistent order can be updated
  * The size of any persistent order can be updated
  * The TIF of any persistent order can be updated

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


## Order books construction

An order book is made up of two halves, the buy and the sell side. Each side contains all the persistent orders which have not yet been fully matched. They are sorted in price and then time first order. This ensures that when we are looking for matches we can search through the opposite side of the book and know that the closest match will be top of the list and if there are multiple orders at that price level they will be ordered in the time that they arrived.

Given an order book that looks like this in the market display:

| Ask Quantity | Price | Bid Quantity |
|--------------|-------|--------------|
| 10 | 120 | |
| 20 | 110 | |
| 5  | 100 | |
| | 90 | 10 |
| | 80 | 15 |



# Pseudo-code / Examples
If you have some data types, or sample code to show interactions, put it here

# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.

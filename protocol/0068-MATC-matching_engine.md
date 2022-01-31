Feature name: matching-engine
Start date: 2021-12-14

# Acceptance Criteria
 * The matching engine co-ordinates the trading of incoming orders with existing orders already on an order book.
   * In a market that is in [Continuous Trading](./0001-MKTF-market-framework.md#trading-mode---continuous-trading) 
     * An [Immediate or Cancel (IOC)](./0014-ORDT-order-types.md#time-in-force---validity) order:
       * Incoming [MARKET](./0014-ORDT-order_types.md#order-pricing-methods) orders will be matched against the opposite side of the book (<a name="0068-MATC-001" href="#0068-MATC-001">0068-MATC-001</a>) 
         * If not enough volume is available to **fully** fill the order, the remaining will be cancelled (<a name="0068-MATC-002" href="#0068-MATC-002">0068-MATC-002</a>) 
       * Incoming [LIMIT](./0014-ORDT-order_types.md#order-pricing-methods) orders will be matched against the opposite side of the book, (<a name="0068-MATC-003" href="#0068-MATC-003">0068-MATC-003</a>) 
         * If there is no match the order will be cancelled. (<a name="0068-MATC-004" href="#0068-MATC-004">0068-MATC-004</a>) 
         * If there is a partial match then the remaining will be cancelled. (<a name="0068-MATC-005" href="#0068-MATC-005">0068-MATC-005</a>) 
 
       * Incoming [PEGGED](./0014-ORDT-order_types.md#order-pricing-methods) orders will be repriced and placed on the book if possible. (<a name="0068-MATC-006" href="#0068-MATC-006">0068-MATC-006</a>) 
         * If the price is invalid it will be parked (and have it's status set to PARKED). (<a name="0068-MATC-007" href="#0068-MATC-007">0068-MATC-007</a>) 
     * A [Fill or KILL (FOK)](./0014-ORDT-order-types.md#time-in-force---validity) order:
       * Incoming [MARKET](./0014-ORDT-order_types.md#order-pricing-methods) MARKET orders will be matched fully if the volume is available, otherwise the order is cancelled. (<a name="0068-MATC-008" href="#0068-MATC-008">0068-MATC-008</a>) 
       * Incoming [LIMIT](./0014-ORDT-order_types.md#order-pricing-methods) orders will either be:
         * fully matched if possible to the other side of the book    (<a name="0068-MATC-009" href="#0068-MATC-009">0068-MATC-009</a>) 
         * if a complete fill is not possible the order is cancelled without trading at all. (<a name="0068-MATC-010" href="#0068-MATC-010">0068-MATC-010</a>) 
       * Incoming [PEGGED](./0014-ORDT-order_types.md#order-pricing-methods) orders will be repriced and placed on the book if possible. (<a name="0068-MATC-011" href="#0068-MATC-011">0068-MATC-011</a>) 
         * If the price is invalid it will be parked. (<a name="0068-MATC-012" href="#0068-MATC-012">0068-MATC-012</a>) 
     * For [Good 'Til Time (GTT) / Good 'Till Cancelled (GTC) / Good For Normal (GFN)](./0014-ORDT-order-types.md#time-in-force---validity) orders:
       * Incoming [MARKET](./0014-ORDT-order_types.md#order-pricing-methods) orders are marked as rejected. (<a name="0068-MATC-013" href="#0068-MATC-013">0068-MATC-013</a>) 
       * Incoming [LIMIT](./0014-ORDT-order_types.md#order-pricing-methods) orders match if possible, any remaining is placed on the book. (<a name="0068-MATC-014" href="#0068-MATC-014">0068-MATC-014</a>) 
       * Incoming [PEGGED](./0014-ORDT-order_types.md#order-pricing-methods) orders are repriced and placed on the book if the price is valid, (<a name="0068-MATC-015" href="#0068-MATC-015">0068-MATC-015</a>) 
         * otherwise they are parked. (<a name="0068-MATC-016" href="#0068-MATC-016">0068-MATC-016</a>) 
     * A market will enter auction if the volume on either side of the book is empty. (<a name="0068-MATC-017" href="#0068-MATC-017">0068-MATC-017</a>) 
     * A market will enter auction if the mark price moves by a larger amount than the price monitoring settings allow. (<a name="0068-MATC-018" href="#0068-MATC-018">0068-MATC-018</a>) 
     * All attempts to [self trade](./0024-OSTA-order_status.md#wash-trading) are prevented and the aggressive side is STOPPED even if partially filled. The passive side is left untouched. (<a name="0068-MATC-019" href="#0068-MATC-019">0068-MATC-019</a>) 
   * In a market that is currently in [Auction Trading](./0026-AUCT-auctions.md) (<a name="0068-MATC-020" href="#0068-MATC-020">0068-MATC-020</a>) 
     * [IOC/FOK/GFN](./0014-ORDT-order-types.md#time-in-force---validity)  
       * Incoming orders have their status set to REJECTED and are not processed further. (<a name="0068-MATC-021" href="#0068-MATC-021">0068-MATC-021</a>) 
     * [GTC/GTT/GFA](./0014-ORDT-order-types.md#time-in-force---validity)
       * All [MARKET](./0014-ORDT-order_types.md#order-pricing-methods) orders are rejected. (<a name="0068-MATC-022" href="#0068-MATC-022">0068-MATC-022</a>) 
       * [LIMIT](./0014-ORDT-order_types.md#order-pricing-methods) orders are placed into the book and no matching takes place. (<a name="0068-MATC-023" href="#0068-MATC-023">0068-MATC-023</a>) 
       * The indicative price and volume values are updated after every change to the order book. (<a name="0068-MATC-024" href="#0068-MATC-024">0068-MATC-024</a>) 
       * [PEGGED](./0014-ORDT-order_types.md#order-pricing-methods) orders are parked (and have their status set to PARKED). (<a name="0068-MATC-025" href="#0068-MATC-025">0068-MATC-025</a>) 
   * When a [market moves into an auction](./0026-auctions.md#upon-entering-auction-mode):
     * All [PEGGED](./0014-ORDT-order_types.md#auction) orders are parked (and have their status set to PARKED). (<a name="0068-MATC-026" href="#0068-MATC-026">0068-MATC-026</a>) 
     * All [GFN](./0014-ORDT-order-types.md#time-in-force---validity) orders are cancelled. (<a name="0068-MATC-027" href="#0068-MATC-027">0068-MATC-027</a>) 
     * All [GTC/GTT](./0014-ORDT-order-types.md#time-in-force---validity) orders remain on the book untouched. (<a name="0068-MATC-028" href="#0068-MATC-028">0068-MATC-028</a>) 
   * When a market [market exits an auction](./0026-auctions.md#upon-exiting-auction-mode):
     * The book is uncrossed. (<a name="0068-MATC-029" href="#0068-MATC-029">0068-MATC-029</a>) 
       * Self trading is allowed during uncrossing. (<a name="0068-MATC-030" href="#0068-MATC-030">0068-MATC-030</a>) 
     * All [GFA](./0014-ORDT-order-types.md#time-in-force---validity) orders are cancelled. (<a name="0068-MATC-031" href="#0068-MATC-031">0068-MATC-031</a>) 
     * [PEGGED](./0014-ORDT-order_types.md#order-pricing-methods) orders are repriced where possible. (<a name="0068-MATC-032" href="#0068-MATC-032">0068-MATC-032</a>) 
  * Any persistent order that is currently [ACTIVE or PARKED](./0024-OSTA-order_status.md) can be [canceled](./0033-CANC-cancel-orders.md). (<a name="0068-MATC-033" href="#0068-MATC-033">0068-MATC-033</a>) 
  * The price of any persistent order can be updated (<a name="0068-MATC-034" href="#0068-MATC-034">0068-MATC-034</a>) 
  * The size of any persistent order can be updated (<a name="0068-MATC-035" href="#0068-MATC-035">0068-MATC-035</a>) 
  * The TIF of any persistent order can be updated (<a name="0068-MATC-036" href="#0068-MATC-036">0068-MATC-036</a>) 
  * An update to an order that is not [ACTIVE or PARKED](./0024-OSTA-order_status.md) (Stopped, Cancelled, Expired, Filled) will be rejected (<a name="0068-MATC-037" href="#0068-MATC-037">0068-MATC-037</a>) 

# Summary
The matching engine is responsible for updating and maintaining the state of the order book. The order book contains two lists of orders in price and time order, one for the buy side and one for the sell side. As new orders come into the matching engine, they are analysed to see if they will match against current orders to create trades or will be placed in the order book if they are persistent order types. If the matching engine is running in continuous trading mode, the matching will take place as the orders arrive. If it is running in auction mode, all the orders are placed on the order book and are only matched when we attempt to leave the auction. Indicative price and volume details are generated during an auction after each new order is added.

# Guide-level explanation
The machine engine consists of an order book and the logic to handle new orders arriving into the engine. The matching engine can be in one of two possible states, continuous trading or auction trading. In continuous trading the incoming orders are processed immediately. In auction mode incoming orders are placed on the order book and are not processed for matching until we attempt to uncross. 

## Continuous Mode
New orders arrive at the engine and are checked for validity including if they are of the right type (not GFA). If the order can be matched to an order already on the book, that matching will take place. If the order does not match against an existing order and the order type is persistent, we place the order into the correct side of the order book at the price level given by the order. If there are already orders in the book at the same price level, the new order will be added after all existing orders at that price to keep the time ordering correct. If a cancel order is received, we remove the existing order from the order book. If an amend order is received we remove the existing order and re-insert the amended version.

## Auction Mode
New orders arrive at the engine and no matching is performed. Instead the order is checked for validity (GFA) and then placed directly onto the order book in price and time priority. When the auction is uncrossed, orders which are in the crossed range are matched until there are no further orders crossed.

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

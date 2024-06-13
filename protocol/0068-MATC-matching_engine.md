# Matching engine

## Acceptance Criteria

The matching engine co-ordinates the trading of incoming orders with existing orders already on an order book.

### In a market that is in [Continuous Trading](./0001-MKTF-market_framework.md#trading-mode---continuous-trading)

An [Immediate or Cancel (IOC)](./0014-ORDT-order_types.md#time-in-force--validity) order:

- Incoming [MARKET](./0014-ORDT-order_types.md#order-pricing-methods) orders will be matched against the opposite side of the book (<a name="0068-MATC-001" href="#0068-MATC-001">0068-MATC-001</a>). For product spot: (<a name="0068-MATC-061" href="#0068-MATC-061">0068-MATC-061</a>)
  - If not enough volume is available to **fully** fill the order, the remaining will be cancelled (<a name="0068-MATC-002" href="#0068-MATC-002">0068-MATC-002</a>). For product spot: (<a name="0068-MATC-062" href="#0068-MATC-062">0068-MATC-062</a>)
- Incoming [LIMIT](./0014-ORDT-order_types.md#order-pricing-methods) orders will be matched against the opposite side of the book, (<a name="0068-MATC-003" href="#0068-MATC-003">0068-MATC-003</a>). For product spot: (<a name="0068-MATC-063" href="#0068-MATC-063">0068-MATC-063</a>)
  - If there is no match the order will be cancelled. (<a name="0068-MATC-004" href="#0068-MATC-004">0068-MATC-004</a>). For product spot: (<a name="0068-MATC-064" href="#0068-MATC-064">0068-MATC-064</a>)
  - If there is a partial match then the remaining will be cancelled. (<a name="0068-MATC-005" href="#0068-MATC-005">0068-MATC-005</a>). For product spot: (<a name="0068-MATC-065" href="#0068-MATC-065">0068-MATC-065</a>)
- Incoming [PEGGED](./0014-ORDT-order_types.md#order-pricing-methods) orders will be rejected by the wallet as they are not valid. (<a name="0068-MATC-006" href="#0068-MATC-006">0068-MATC-006</a>)
- Incoming [LIMIT: POST-ONLY TRUE](./0014-ORDT-order_types.md#order-pricing-methods) orders will be rejected by the wallet as they are not valid. (<a name="0068-MATC-057" href="#0068-MATC-057">0068-MATC-057</a>). For product spot: (<a name="0068-MATC-066" href="#0068-MATC-066">0068-MATC-066</a>)

- For Reduce-Only = True orders:
  - Incoming [MARKET](./0014-ORDT-order_types.md#order-pricing-methods) orders which reduce the trader's absolute position will be matched against the opposite side of the book (<a name="0068-MATC-056" href="#0068-MATC-056">0068-MATC-056</a>)
    - If not enough volume is available to **fully** fill the order, the remaining will be cancelled (<a name="0068-MATC-043" href="#0068-MATC-043">0068-MATC-043</a>)
  - Incoming [MARKET](./0014-ORDT-order_types.md#order-pricing-methods) orders which increase the trader's absolute position will be stopped (<a name="0068-MATC-044" href="#0068-MATC-044">0068-MATC-044</a>)
  - Incoming [LIMIT](./0014-ORDT-order_types.md#order-pricing-methods) orders which reduce the trader's absolute position will be matched against the opposite side of the book (<a name="0068-MATC-045" href="#0068-MATC-045">0068-MATC-045</a>)
  - Incoming [LIMIT](./0014-ORDT-order_types.md#order-pricing-methods) orders which increase the trader's absolute position will be stopped (<a name="0068-MATC-046" href="#0068-MATC-046">0068-MATC-046</a>)
  - Incoming [PEGGED](./0014-ORDT-order_types.md#order-pricing-methods) orders will be rejected by the wallet as they are not valid. (<a name="0068-MATC-058" href="#0068-MATC-058">0068-MATC-058</a>)
  - Incoming [LIMIT: POST-ONLY TRUE](./0014-ORDT-order_types.md#order-pricing-methods) orders will be rejected by the wallet as they are not valid. (<a name="0068-MATC-059" href="#0068-MATC-059">0068-MATC-059</a>)

A [Fill or KILL (FOK)](./0014-ORDT-order_types.md#time-in-force--validity) order:

- Incoming [MARKET](./0014-ORDT-order_types.md#order-pricing-methods) MARKET orders will be matched fully if the volume is available, otherwise the order is cancelled. (<a name="0068-MATC-008" href="#0068-MATC-008">0068-MATC-008</a>). For product spot: (<a name="0068-MATC-067" href="#0068-MATC-067">0068-MATC-067</a>)
- Incoming [LIMIT](./0014-ORDT-order_types.md#order-pricing-methods) orders will either be:
  - Fully matched if possible to the other side of the book    (<a name="0068-MATC-009" href="#0068-MATC-009">0068-MATC-009</a>). For product spot: (<a name="0068-MATC-068" href="#0068-MATC-068">0068-MATC-068</a>)
  - if a complete fill is not possible the order is stopped without trading at all. (<a name="0068-MATC-010" href="#0068-MATC-010">0068-MATC-010</a>). For product spot: (<a name="0068-MATC-069" href="#0068-MATC-069">0068-MATC-069</a>)
- Incoming [PEGGED](./0014-ORDT-order_types.md#order-pricing-methods) orders will be rejected by the wallet as they are not valid. (<a name="0068-MATC-011" href="#0068-MATC-011">0068-MATC-011</a>)
- Incoming [LIMIT: POST-ONLY TRUE](./0014-ORDT-order_types.md#order-pricing-methods) orders will be rejected by the wallet as they are not valid. (<a name="0068-MATC-039" href="#0068-MATC-039">0068-MATC-039</a>). For product spot: (<a name="0068-MATC-070" href="#0068-MATC-070">0068-MATC-070</a>)

- For Reduce-Only = TRUE orders:
  - Incoming [MARKET](./0014-ORDT-order_types.md#order-pricing-methods) orders which reduce the trader's absolute position will be matched against the opposite side of the book (<a name="0068-MATC-047" href="#0068-MATC-047">0068-MATC-047</a>)
    - If not enough volume is available to **fully** fill the order, the order will be cancelled(<a name="0068-MATC-048" href="#0068-MATC-048">0068-MATC-048</a>)
  - Incoming [MARKET](./0014-ORDT-order_types.md#order-pricing-methods) orders which increase the trader's absolute position will be stopped (<a name="0068-MATC-049" href="#0068-MATC-049">0068-MATC-049</a>)
  - Incoming [LIMIT](./0014-ORDT-order_types.md#order-pricing-methods) orders which reduce the trader's absolute position will be matched against the opposite side of the book (<a name="0068-MATC-050" href="#0068-MATC-050">0068-MATC-050</a>)
  - Incoming [LIMIT](./0014-ORDT-order_types.md#order-pricing-methods) orders which increase the trader's absolute position will be stopped (<a name="0068-MATC-051" href="#0068-MATC-051">0068-MATC-051</a>)
  - Incoming [PEGGED](./0014-ORDT-order_types.md#order-pricing-methods) orders will be rejected by the wallet as they are not valid. (<a name="0068-MATC-052" href="#0068-MATC-052">0068-MATC-052</a>)
  - Incoming [LIMIT: POST-ONLY TRUE](./0014-ORDT-order_types.md#order-pricing-methods) orders will be rejected by the wallet as they are not valid. (<a name="0068-MATC-053" href="#0068-MATC-053">0068-MATC-053</a>)

For [Good 'Til Time (GTT) / Good 'Till Cancelled (GTC) / Good For Normal (GFN)](./0014-ORDT-order_types.md#time-in-force--validity) orders:

- Incoming [MARKET](./0014-ORDT-order_types.md#order-pricing-methods) orders are rejected by the wallet validation layer. (<a name="0068-MATC-013" href="#0068-MATC-013">0068-MATC-013</a>). For product spot: (<a name="0068-MATC-071" href="#0068-MATC-071">0068-MATC-071</a>)
- Incoming [LIMIT](./0014-ORDT-order_types.md#order-pricing-methods) orders match if possible, any remaining is placed on the book. (<a name="0068-MATC-014" href="#0068-MATC-014">0068-MATC-014</a>). For product spot: (<a name="0068-MATC-072" href="#0068-MATC-072">0068-MATC-072</a>)
- Incoming [PEGGED](./0014-ORDT-order_types.md#order-pricing-methods) orders are repriced and placed on the book if the price is valid, except GFN which are rejected by the wallet validation layer. (<a name="0068-MATC-015" href="#0068-MATC-015">0068-MATC-015</a>)
  - otherwise they are parked. (<a name="0068-MATC-016" href="#0068-MATC-016">0068-MATC-016</a>)
- Incoming [LIMIT: POST-ONLY TRUE](./0014-ORDT-order_types.md#order-pricing-methods) orders will be placed fully on the book if no orders currently cross. (<a name="0068-MATC-040" href="#0068-MATC-040">0068-MATC-040</a>). For product spot: (<a name="0068-MATC-073" href="#0068-MATC-073">0068-MATC-073</a>)
  - An order which totally crosses with an existing order on the book will be STOPPED in full with none executed.  (<a name="0068-MATC-041" href="#0068-MATC-041">0068-MATC-041</a>). For product spot: (<a name="0068-MATC-074" href="#0068-MATC-074">0068-MATC-074</a>)
  - An order partially crossing with an existing order on the book will be STOPPED in full with none executed.  (<a name="0068-MATC-042" href="#0068-MATC-042">0068-MATC-042</a>). For product spot: (<a name="0068-MATC-075" href="#0068-MATC-075">0068-MATC-075</a>)
- A market will enter auction if the volume on either side of the book is empty. (<a name="0068-MATC-017" href="#0068-MATC-017">0068-MATC-017</a>)
- A market will enter auction if the mark price moves by a larger amount than the price monitoring settings allow. (<a name="0068-MATC-018" href="#0068-MATC-018">0068-MATC-018</a>). For product spot: (<a name="0068-MATC-076" href="#0068-MATC-076">0068-MATC-076</a>)
- All attempts to [self trade](./0024-OSTA-order_status.md#wash-trading) are prevented and the aggressive side is STOPPED if completely unfilled or PARTIALLY_FILLED if some matching occurred before the self trade. The passive side is left untouched. (<a name="0068-MATC-019" href="#0068-MATC-019">0068-MATC-019</a>). For product spot: (<a name="0068-MATC-077" href="#0068-MATC-077">0068-MATC-077</a>)
- All orders with Reduce-Only set to TRUE are rejected as invalid. (<a name="0068-MATC-054" href="#0068-MATC-054">0068-MATC-054</a>)

In a market that is currently in [Auction Trading](./0026-AUCT-auctions.md):

- [IOC/FOK/GFN](./0014-ORDT-order_types.md#time-in-force--validity)
  - Incoming orders have their status set to REJECTED and are not processed further. (<a name="0068-MATC-021" href="#0068-MATC-021">0068-MATC-021</a>). For product spot: (<a name="0068-MATC-078" href="#0068-MATC-078">0068-MATC-078</a>)
- [GTC/GTT/GFA](./0014-ORDT-order_types.md#time-in-force--validity)
  - All [MARKET](./0014-ORDT-order_types.md#order-pricing-methods) orders are rejected. (<a name="0068-MATC-022" href="#0068-MATC-022">0068-MATC-022</a>). For product spot: (<a name="0068-MATC-079" href="#0068-MATC-079">0068-MATC-079</a>)
  - [LIMIT](./0014-ORDT-order_types.md#order-pricing-methods) orders are placed into the book and no matching takes place. (<a name="0068-MATC-023" href="#0068-MATC-023">0068-MATC-023</a>). For product spot: (<a name="0068-MATC-080" href="#0068-MATC-080">0068-MATC-080</a>)
  - [LIMIT: POST-ONLY TRUE](./0014-ORDT-order_types.md#order-pricing-methods) orders are placed into the book and no matching takes place. (<a name="0068-MATC-055" href="#0068-MATC-055">0068-MATC-055</a>). For product spot: (<a name="0068-MATC-081" href="#0068-MATC-081">0068-MATC-081</a>)
  - The indicative price and volume values are updated after every change to the order book. (<a name="0068-MATC-024" href="#0068-MATC-024">0068-MATC-024</a>). For product spot: (<a name="0068-MATC-082" href="#0068-MATC-082">0068-MATC-082</a>)
  - [PEGGED](./0014-ORDT-order_types.md#order-pricing-methods) orders are parked (and have their status set to PARKED). (<a name="0068-MATC-025" href="#0068-MATC-025">0068-MATC-025</a>)
  - It is possible to [self trade](./0024-OSTA-order_status.md#wash-trading) to uncross an auction. (<a name="0068-MATC-038" href="#0068-MATC-038">0068-MATC-038</a>). For product spot: (<a name="0068-MATC-083" href="#0068-MATC-083">0068-MATC-083</a>)

When a [market moves into an auction](./0026-AUCT-auctions.md#upon-entering-auction-mode):

- All [PEGGED](./0014-ORDT-order_types.md#auction) orders are parked (and have their status set to PARKED). (<a name="0068-MATC-026" href="#0068-MATC-026">0068-MATC-026</a>)
- All [GFN](./0014-ORDT-order_types.md#time-in-force---validity) orders are cancelled. (<a name="0068-MATC-027" href="#0068-MATC-027">0068-MATC-027</a>). For product spot: (<a name="0068-MATC-084" href="#0068-MATC-084">0068-MATC-084</a>)
- All [GTC/GTT](./0014-ORDT-order_types.md#time-in-force---validity) orders remain on the book untouched. (<a name="0068-MATC-028" href="#0068-MATC-028">0068-MATC-028</a>). For product spot: (<a name="0068-MATC-085" href="#0068-MATC-085">0068-MATC-085</a>)

When a market [market exits an auction](./0026-AUCT-auctions.md#upon-exiting-auction-mode):

- The book is uncrossed. (<a name="0068-MATC-029" href="#0068-MATC-029">0068-MATC-029</a>). For product spot: (<a name="0068-MATC-086" href="#0068-MATC-086">0068-MATC-086</a>)
  - Self trading is allowed during uncrossing. (<a name="0068-MATC-030" href="#0068-MATC-030">0068-MATC-030</a>). For product spot: (<a name="0068-MATC-087" href="#0068-MATC-087">0068-MATC-087</a>)
- All [GFA](./0014-ORDT-order_types.md#time-in-force---validity) orders are cancelled. (<a name="0068-MATC-031" href="#0068-MATC-031">0068-MATC-031</a>). For product spot: (<a name="0068-MATC-088" href="#0068-MATC-088">0068-MATC-088</a>)
- [PEGGED](./0014-ORDT-order_types.md#order-pricing-methods) orders are repriced where possible. (<a name="0068-MATC-032" href="#0068-MATC-032">0068-MATC-032</a>)

- Any persistent order that is currently [ACTIVE or PARKED](./0024-OSTA-order_status.md) can be [cancelled](./0033-OCAN-cancel_orders.md). (<a name="0068-MATC-033" href="#0068-MATC-033">0068-MATC-033</a>). For product spot: (<a name="0068-MATC-060" href="#0068-MATC-060">0068-MATC-060</a>)
- The price of any persistent order can be updated (<a name="0068-MATC-034" href="#0068-MATC-034">0068-MATC-034</a>). For product spot: (<a name="0068-MATC-089" href="#0068-MATC-089">0068-MATC-089</a>)
- The size of any persistent order can be updated (<a name="0068-MATC-035" href="#0068-MATC-035">0068-MATC-035</a>). For product spot: (<a name="0068-MATC-090" href="#0068-MATC-090">0068-MATC-090</a>)
- The TIF of any persistent order can be updated to and from GTC and GTT only. Expiry time is required if amending to GTT and must not be given if amending to GTC. (<a name="0068-MATC-036" href="#0068-MATC-036">0068-MATC-036</a>). For product spot: (<a name="0068-MATC-092" href="#0068-MATC-092">0068-MATC-092</a>)
- An update to an order that is not [ACTIVE or PARKED](./0024-OSTA-order_status.md) (Stopped, Cancelled, Expired, Filled) will be rejected (<a name="0068-MATC-037" href="#0068-MATC-037">0068-MATC-037</a>). For product spot: (<a name="0068-MATC-091" href="#0068-MATC-091">0068-MATC-091</a>)

## Summary

The matching engine is responsible for updating and maintaining the state of the order book. The order book contains two lists of orders in price and time order, one for the buy side and one for the sell side. As new orders come into the matching engine, they are analysed to see if they will match against current orders to create trades or will be placed in the order book if they are persistent order types. If the matching engine is running in continuous trading mode, the matching will take place as the orders arrive. If it is running in auction mode, all the orders are placed on the order book and are only matched when we attempt to leave the auction. Indicative price and volume details are generated during an auction after each new order is added.

## Guide-level explanation

The matching engine consists of an order book and the logic to handle new orders arriving into the engine. The matching engine can be in one of two possible states, continuous trading or auction trading. In continuous trading the incoming orders are processed immediately. In auction mode incoming orders are placed on the order book and are not processed for matching until we attempt to uncross.

### Continuous Mode

New orders arrive at the engine and are checked for validity including if they are of the right type (not GFA). If the order can be matched to an order already on the book, that matching will take place. If the order does not match against an existing order and the order type is persistent, we place the order into the correct side of the order book at the price level given by the order. If there are already orders in the book at the same price level, the new order will be added after all existing orders at that price to keep the time ordering correct. If a cancel order is received, we remove the existing order from the order book. If an [amend order](./0004-AMND-amends.md) is received we remove the existing order and re-insert the amended version.

### [Auction](./0026-AUCT-auctions.md) Mode

New orders arrive at the engine and no matching is performed. Instead the order is checked for validity (GFA) and then placed directly onto the order book in price and time priority. When the auction is uncrossed, orders which are in the crossed range are matched until there are no further orders crossed.

### Order books construction

An order book is made up of two halves, the buy and the sell side. Each side contains all the persistent orders which have not yet been fully matched. They are sorted in price and then time first order. This ensures that when we are looking for matches we can search through the opposite side of the book and know that the closest match will be top of the list and if there are multiple orders at that price level they will be ordered in the time that they arrived.

Given an order book that looks like this in the market display:

| Ask Quantity | Price | Bid Quantity |
|--------------|-------|--------------|
| 10 | 120 | |
| 20 | 110 | |
| 5  | 100 | |
| | 90 | 10 |
| | 80 | 15 |

## See also

- [0008-TRAD-Trading Workflow](./0008-TRAD-trading_workflow.md)
- [0029-FEES-Fees](./0029-FEES-fees.md)

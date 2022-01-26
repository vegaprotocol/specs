# Positions API

## Acceptance Criteria

The Position API stores a net position for each trader who has ever traded in a market. Specifically, 

- [ ] Stores all traders’ net open volume by market in which they have an open position. (<a name="0007-POSN-001" href="#0007-POSN-001">0007-POSN-001</a>)
- [ ] Updates the open volumes after a new trade (<a name="0007-POSN-002" href="#0007-POSN-002">0007-POSN-002</a>)
- [ ] Stores all traders’ volume weighted average entry prices for the net open volume for every market. (<a name="0007-POSN-003" href="#0007-POSN-003">0007-POSN-003</a>)
- [ ] Uses VW methodology to adjust the volume weighted average entry prices for open position. (<a name="0007-POSN-004" href="#0007-POSN-004">0007-POSN-004</a>)
- [ ] Stores all traders’ realised PnL for every market. (<a name="0007-POSN-005" href="#0007-POSN-005">0007-POSN-005</a>)
- [ ] Uses VW methodology to adjust the realised PnL resulting from any trade that caused volume to have been closed out. (<a name="0007-POSN-006" href="#0007-POSN-006">0007-POSN-006</a>)
- [ ] Stores all traders’ realised PnL for every trade that caused volume to have been closed out.  (<a name="0007-POSN-007" href="#0007-POSN-007">0007-POSN-007</a>)
- [ ] Stores all traders' total realised PnL (<a name="0007-POSN-008" href="#0007-POSN-008">0007-POSN-008</a>)

## Summary

## Reference-level explanation

The Positions API requires additional position data for each trader, on top of that calculated by the Position Engine in the core, including:

* A view of the "profit and loss" that a trader has incurred by fully closing out a position.
* The portion of profit/loss (P&L) that has been "locked in" by partly closing out a position, i.e. "Realised P&L" (this is a cumulative of the per trade realised P&L)
* The [volume weighted average entry price](../glossaries/trading-and-protocol-glossary.md#average-entry-price) of an open position.
* The portion of profit/loss (P&L) that continuously changes when the _mark price_ changes, i.e. "Open P&L".
* The per trade realised P&L for the buyer and seller 

Note: A trade (and therefore a position) may be of any size that is a multiple of the smallest number that can be represented given the `Position Decimal Places` specified in the [Market Framework](./0001-MKTF-market_framework.md).

Note: it is possible to calculate valuation / P&L using various methodologies (e.g. Average cost, FIFO, LIFO) when a position has been only partially closed out. These are well known alternative accounting methods that can be used when account for profit/loss on selling 'inventory' of a product. In this case, we can consider a trader's open position as their inventory. We will be outlining the average cost methodology in this API as described at https://www.investopedia.com/terms/a/averagecostmethod.asp, however we may also add others in future and the API should be designed to allow for multiple such approaches to be used simultaneously.

Note, fully closed positions only have one possible calculation as the set of trades that both opened and closed the position is known and unambiguous, so there is only one correct P&L once a position is fully closed. We may choose to make the valuation methodology for open/partially closed positions configurable in the future.

## API 

The API is expected to expose:

### Position

* Open volume (this is a core API)
* Unrealised P&L (method = averaged)
* Realised P&L (method = averaged)
* Open volume average entry price (method = averaged)

### Trade

* Buyer P&L (0 if buyer is not closing volume)
* Seller P&L (0 if seller is not closing volume)


## Definitions / glossary

| Term        | Definition           |
| ------------- |-------------| 
| Open Volume     | Traded volume that hasn't been closed out with an offsetting trade, this is positive for a long position and negative for a short position. |
| Closing Out     | Entering a trade that reduces the absolute size of the open volume (i.e. takes it closer to zero) or switches the sign of the volume (i.e. a net long position (+'ve) becomes a net short position (-'ve)). Close out trades will generate a non-zero P&L if the Trade Price differs from the Open Volume Entry Price. |
| Unrealised P&L      | The profit/loss on the open volume (dependent on the P&L calculation methodology): `Unrealised P&L [averaged] = (Product.value(Open Volume Entry Price) - Product.Value(mark_price)) *  open volume` |
| Realised P&L | The total P&L realised across all trades (dependent on the P&L calculation methodology). Note: only trades that close out volume can realise a P&L.  |
| Trade Realised P&L | The change in Realised P&L caused by a single trade that closes volume (dependent on the P&L calculation methodology) - *this can/will be different for the buyer and seller and must be calculated for each side of the trade*: `Trade Realised P&L [averaged] = Trade Volume * (Product.value(Trade Price) - Product.value(Open Volume Entry Price))`    |
| Total Profit & Loss | Unrealised P&L + Realised P&L      |
| Open Volume Entry Price | The average entry price of the currently open volume. `New Open Volume Entry Price = (Prev Open Volume Entry Price * Prev Open Volume + New Trade Price * New Trade Volume) / (Prev Open Volume + New Trade Volume)` |
| Averaged price P&L calculation method | The accounting method whereby entry price for P&L calculation is averaged across all open volume, i.e. the open volume is considered fungible and close out trades are not matched with previous trades that opened volume to determine the entry price used for P&L calculations. |
| FIFO (not used) | The accounting method whereby Realised P&L is allocated an entry price for purposes of calculating the profit/loss by comparing the trade price of the exit volume to the volume weighted average price of the oldest equivalent open trades (i.e. trades that have not already been 'matched' by closed volume.)  |


## Formulae (Python notebook)

Averaged method: https://colab.research.google.com/drive/1GpiNQUF6qt4rCMUJRAiXkcHjXxlGP-YB

FIFO method (unused currently, for reference): https://colab.research.google.com/drive/1QLBcf4HSQNDFOIbN3TMX-YyqJWmfuH_d

## Test cases

[See spreadsheet here](https://docs.google.com/spreadsheets/d/1XJESwh5cypALqlYludWobAOEH1Pz-1xS/edit#gid=1136043307) for examples (Please don't edit)




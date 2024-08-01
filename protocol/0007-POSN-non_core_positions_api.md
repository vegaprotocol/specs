# Positions API

## Acceptance Criteria

The Position API provides access to net position per party per market. Specifically,

- Stores all traders’ net open volume by market in which they have an open position. (<a name="0007-POSN-001" href="#0007-POSN-001">0007-POSN-001</a>)
- Updates the open volumes after a new trade. (<a name="0007-POSN-002" href="#0007-POSN-002">0007-POSN-002</a>)
- Stores all traders’ volume weighted average entry prices for the net open volume for every market. (<a name="0007-POSN-003" href="#0007-POSN-003">0007-POSN-003</a>)
- Uses VW methodology to adjust the volume weighted average entry prices for open position. (<a name="0007-POSN-004" href="#0007-POSN-004">0007-POSN-004</a>)
- Stores all traders’ realised PnL for every market. (<a name="0007-POSN-005" href="#0007-POSN-005">0007-POSN-005</a>)
- Uses VW methodology to adjust the realised PnL resulting from any trade that caused volume to have been closed out. (<a name="0007-POSN-006" href="#0007-POSN-006">0007-POSN-006</a>)
- Stores all traders’ realised PnL for every trade that caused volume to have been closed out. (<a name="0007-POSN-007" href="#0007-POSN-007">0007-POSN-007</a>)
- Stores all traders' total realised PnL. (<a name="0007-POSN-008" href="#0007-POSN-008">0007-POSN-008</a>)
- Stores a status field for all the traders, the status field will be set to ORDERS_CLOSED if a trader was distressed based on the margin requirements for their worst possible long/short, but their margin balance was sufficient to maintain their open position. They have active orders, their active orders will be removed from the book, after which the party was no longer distressed. (<a name="0007-POSN-015" href="#0007-POSN-015">0007-POSN-015</a>)
- The status field will be set to DISTRESSED if a trader was distressed based on the margin requirements for their worst possible long/short and they do not have active orders to be closed, however the book currently does not have enough volume to close them out, and will close them out when there is enough volume.(<a name="0007-POSN-017" href="#0007-POSN-017">0007-POSN-017</a>)
- The status field will be set to CLOSED_OUT if the party was closed out (<a name="0007-POSN-016" href="#0007-POSN-016">0007-POSN-016</a>)

## Summary

## Reference-level explanation

The Positions API requires additional position data for each trader, on top of that calculated by the Position Engine in the core, including:

- A view of the "profit and loss" that a trader has incurred by fully closing out a position.
- The portion of profit/loss (P&L) that has been "locked in" by partly closing out a position, i.e. "Realised P&L" (this is a cumulative of the per trade realised P&L)
- The [volume weighted average entry price](../glossaries/trading-and-protocol-glossary.md#average-entry-price) of an open position.
- The portion of profit/loss (P&L) that continuously changes when the _mark price_ changes, i.e. "Open P&L".
- The per trade realised P&L for the buyer and seller

Note: A trade (and therefore a position) may be of any size that is a multiple of the smallest number that can be represented given the `Position Decimal Places` specified in the [Market Framework](./0001-MKTF-market_framework.md).

Note: it is possible to calculate valuation / P&L using various methodologies (e.g. Average cost, FIFO, LIFO) when a position has been only partially closed out. These are well known alternative accounting methods that can be used when account for profit/loss on selling 'inventory' of a product. In this case, we can consider a trader's open position as their inventory. We will be outlining the average cost methodology in this API as described at [investopedia](https://www.investopedia.com/terms/a/averagecostmethod.asp), however we may also add others in future and the API should be designed to allow for multiple such approaches to be used simultaneously.

Note, fully closed positions only have one possible calculation as the set of trades that both opened and closed the position is known and unambiguous, so there is only one correct P&L once a position is fully closed. We may choose to make the valuation methodology for open/partially closed positions configurable in the future.

### Loss socialisation

When a party is subject to [loss socialisation](./0002-STTL-settlement.md#loss-socialisation), that is their [mark-to-market](./0003-MTMK-mark_to_market_settlement.md) gains get scaled down the amount forgone (calculated MTM gains minus the actual amount received) should get recorded in the realised PnL figure.

## API

The API is expected to expose:

### Position

The following must be available for each market and for each key using the P&L method "averaged" (as opposed to FIFO):

- Position volume (this is a core API).
- Position average entry price.
- Unrealised P&L.
- Realised P&L.
- Realised P&L since the last time the position changed from 0 or flipped sign.
- Realised P&L including fees.
- Realised P&L including fees since the last time the position changed from 0 or flipped sign.
- Realised P&L including funding.
- Realised P&L including funding since the last time the position changed from 0 or flipped sign.
- Realised P&L including both fees and funding.
- Realised P&L including both fees and funding since the last time the position changed from 0 or flipped sign.
- Taker fees paid.
- Taker fees paid since the last time the position changed from 0 or flipped sign.
- Maker fees received.
- Maker fees received since the last time the position changed from 0 or flipped sign.
- Funding total.
- Funding total since the last time the position changed from 0 or flipped sign.

### Trade

- Buyer P&L (0 if buyer is not closing volume)
- Seller P&L (0 if seller is not closing volume)

## Position and PnL test

- When a party has never had a position, the realised PnL and unrealised PnL should be 0 (<a name="0007-POSN-009" href="#0007-POSN-009">0007-POSN-009</a>)
- When a party has a non-zero position, and has not closed any part of it, only the unrealised PnL should be changed by increase in position or change of mark price while realised PnL should stay constant in absence of loss socialisation (<a name="0007-POSN-010" href="#0007-POSN-010">0007-POSN-010</a>)
- When a party has a position which gets (partially) closed-out, the unrealised PnL should reflect the change of position while the realised PnL reflect the closed-out position (<a name="0007-POSN-011" href="#0007-POSN-011">0007-POSN-011</a>)
- During settlement, all the parties' position should become 0, unrealised PnL should become 0 and realised PnL should update based on settlement price (<a name="0007-POSN-012" href="#0007-POSN-012">0007-POSN-012</a>)
- If a party is subject to loss socialisation (its MTM gains get scaled down) the loss amount (forgone profit) should get recorded in realised PnL(<a name="0007-POSN-013" href="#0007-POSN-013">0007-POSN-013</a>)
- If a party is subject to loss socialisation, the profits that could not be paid out due to loss socialisation is logged as "loss socialisation amount" which is accessible from API (<a name="0007-POSN-014" href="#0007-POSN-014">0007-POSN-014</a>)
- Position volume should be accessible from API.(<a name="0007-POSN-018" href="#0007-POSN-018">0007-POSN-018</a>)
- Position average entry price should be accessible from API.(<a name="0007-POSN-019" href="#0007-POSN-019">0007-POSN-019</a>)
- Unrealised P&L should be accessible from API.(<a name="0007-POSN-020" href="#0007-POSN-020">0007-POSN-020</a>)
- Realised P&L should be accessible from API.(<a name="0007-POSN-021" href="#0007-POSN-021">0007-POSN-021</a>)
- Realised P&L since the last time the position changed from 0 or flipped sign should be accessible from API.(<a name="0007-POSN-022" href="#0007-POSN-022">0007-POSN-022</a>)
- Realised P&L including fees should be accessible from API.(<a name="0007-POSN-023" href="#0007-POSN-023">0007-POSN-023</a>)
- Realised P&L including fees since the last time the position changed from 0 or flipped sign should be accessible from API.(<a name="0007-POSN-024" href="#0007-POSN-024">0007-POSN-024</a>)
- Realised P&L including funding should be accessible from API.(<a name="0007-POSN-025" href="#0007-POSN-025">0007-POSN-025</a>)
- Realised P&L including funding since the last time the position changed from 0 or flipped sign should be accessible from API.(<a name="0007-POSN-026" href="#0007-POSN-026">0007-POSN-026</a>)
- Realised P&L including both fees and funding should be accessible from API.(<a name="0007-POSN-027" href="#0007-POSN-027">0007-POSN-027</a>)
- Realised P&L including both fees and funding since the last time the position changed from 0 or flipped sign should be accessible from API .(<a name="0007-POSN-028" href="#0007-POSN-028">0007-POSN-028</a>)
- Taker fees paid should be accessible from API .(<a name="0007-POSN-029" href="#0007-POSN-029">0007-POSN-029</a>)
- Taker fees paid since the last time the position changed from 0 or flipped sign should be accessible from AP.(<a name="0007-POSN-030" href="#0007-POSN-030">0007-POSN-030</a>)
- Maker fees received should be accessible from API .(<a name="0007-POSN-031" href="#0007-POSN-031">0007-POSN-031</a>)
- Maker fees received since the last time the position changed from 0 or flipped sign should be accessible from API .(<a name="0007-POSN-032" href="#0007-POSN-032">0007-POSN-032</a>)
- Funding total should be accessible from API .(<a name="0007-POSN-033" href="#0007-POSN-033">0007-POSN-033</a>)
- Funding total since the last time the position changed from 0 or flipped sign should be accessible from API.(<a name="0007-POSN-034" href="#0007-POSN-034">0007-POSN-034</a>)

## Definitions / glossary

| Term        | Definition           |
| ------------- |-------------|
| Open Volume     | Traded volume that hasn't been closed out with an offsetting trade, this is positive for a long position and negative for a short position. |
| Closing Out     | Entering a trade that reduces the absolute size of the open volume (i.e. takes it closer to zero) or switches the sign of the volume (i.e. a net long position (`+'ve`) becomes a net short position (`-'ve`)). Close out trades will generate a non-zero P&L if the Trade Price differs from the Open Volume Entry Price. |
| Unrealised P&L      | The profit/loss on the open volume (dependent on the P&L calculation methodology): `Unrealised P&L [averaged] = (Product.value(Open Volume Entry Price) - Product.Value(mark_price)) *  open volume` |
| Realised P&L | The total P&L realised across all trades (dependent on the P&L calculation methodology). Note: only trades that close out volume can realise a P&L.  |
| Trade Realised P&L | The change in Realised P&L caused by a single trade that closes volume (dependent on the P&L calculation methodology) - _this can/will be different for the buyer and seller and must be calculated for each side of the trade_: `Trade Realised P&L [averaged] = Trade Volume * (Product.value(Trade Price) - Product.value(Open Volume Entry Price))`    |
| Total Profit & Loss | Unrealised P&L + Realised P&L      |
| Open Volume Entry Price | The average entry price of the currently open volume. `New Open Volume Entry Price = (Prev Open Volume Entry Price * Prev Open Volume + New Trade Price * New Trade Volume) / (Prev Open Volume + New Trade Volume)` |
| Averaged price P&L calculation method | The accounting method whereby entry price for P&L calculation is averaged across all open volume, i.e. the open volume is considered fungible and close out trades are not matched with previous trades that opened volume to determine the entry price used for P&L calculations. |
| FIFO (not used) | The accounting method whereby Realised P&L is allocated an entry price for purposes of calculating the profit/loss by comparing the trade price of the exit volume to the volume weighted average price of the oldest equivalent open trades (i.e. trades that have not already been 'matched' by closed volume.)  |

## Formulae (Python notebook)

[Averaged method](https://colab.research.google.com/drive/1GpiNQUF6qt4rCMUJRAiXkcHjXxlGP-YB)

[FIFO method](https://colab.research.google.com/drive/1QLBcf4HSQNDFOIbN3TMX-YyqJWmfuH_d) (unused currently, for reference).

## Test cases

[See spreadsheet here](https://docs.google.com/spreadsheets/d/1XJESwh5cypALqlYludWobAOEH1Pz-1xS/edit#gid=1136043307) for examples (Please don't edit)

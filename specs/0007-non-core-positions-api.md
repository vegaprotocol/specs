# Positions API

## Acceptance Criteria

The Position API stores a net position for each trader who has ever traded in a market. Specifically, 

- [ ] Stores all traders’ net open volume by market in which they have an open position.
- [ ] Updates the open volumes after a new trade
- [ ] Stores all traders’ volume weighted average entry prices for the net open volume for every market.
- [ ] Uses VW methodology to adjust the volume weighted average entry prices for open position.
- [ ] Stores all traders’ realised PnL for every market.
- [ ] Uses VW methodology to adjust the realised PnL resulting from any trade that causes a reduction in the absolute size of open volume on every market (i.e. when volume has been closed out)
- [ ] Stores all traders’ realised PnL for every trade that causes a reduction in the absolute size of open volume on every market (i.e. when volume has been closed out)

Yeah we should have one criteria for storing the PnL realised with that trade, on the trade (in stores, not core) and one for storing the total realised PnL for the market

## Summary

## Reference-level explanation

The Positions API requires additional position data for each trader, on top of that calculated by the Position Engine in the core, including:

* A view of the "profit and loss" that a trader has incurred by fully closing out a position.
* The portion of profit/loss (P&L) that has been "locked in" by partly closing out a position, i.e. "Realised P&L" (this is a cumulative of the per trade realised P&L)
* The [volume weighted average entry price](https://gitlab.com/vega-protocol/product/wikis/Trading-and-Protocol-Glossary#average-entry-price) of an open position.
* The portion of profit/loss (P&L) that continuously changes when the _mark price_ changes, i.e. "Open P&L".
* The per trade realised P&L for the buyer and seller 

Implementation note: For performance reasons, this data can be stored, and updated with each new trade or change in mark price.

Note: it is possible to calculate valuation / P&L using various methodologies (e.g. Volume Weighted, FIFO) when a position has been only partially closed out. We will be outlining the Volume Weighted methodology in this API, however there may be additional methodologies specified down the track.

Note, fully closed positions only have one possible calculation as the set of trades that both opened and closed the position is known and unambiguous, so there is only one correct P&L once a position is fully closed. We may choose to make the valuation methodology for open/partially closed positions configurable in future.


## Definitions / glossary

| Term        | Scope        | Definition           | Link  |
| ------------- |:-------------:|-------------| -----:|
| open volume     | Trader | Traded volume that hasn't been closed out |  |
| closing out     | Trader | Entering a trade that reduces the open volume | |
| Open P&L      | Trader | ( Open Volume Weighted Average Price - Product.Value(mark_price) ) *  open volume  |    |
| Realised P&L | Trader | The total value of the close out trades measured using a FIFO or Volume Weighted methodology     |    |
| Trade Realised P&L | Trader | The change in Realised P&L caused by a single trade      |     |
| Profit & Loss | Trader | Open P&L + Realised P&L      |     |
| Open Volume Weighted Average Price | Trader | The average of the trade prices (since the last time the Open P&L was zero) weighted by the volume of those trades  |     |
| Volume Weighted method | Market | The accounting method whereby Realised P&L is allocated a profit/loss movement by comparing the trade price of the exit volume to the previous Volume Weighted Price       |     |
| FIFO (not used) | Market | The accounting method whereby Realised P&L is allocated a profit/loss movement by comparing the trade price of the exit volume to the volume weighted average price of the oldest equivalent open trade volume      |    $1 |


### Formulae (Python notebook)

https://colab.research.google.com/drive/1GpiNQUF6qt4rCMUJRAiXkcHjXxlGP-YB

## Test cases

[See spreadsheet here](https://docs.google.com/spreadsheets/d/1XJESwh5cypALqlYludWobAOEH1Pz-1xS/edit#gid=1136043307) for examples (Please don't edit)




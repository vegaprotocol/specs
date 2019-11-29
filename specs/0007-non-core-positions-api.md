# Positions API

## Acceptance Criteria

The Position API stores a net position for each trader who has ever traded in a market. Specifically, 

- [ ] Stores all traders’ net open volume by market in which they have an open position.
- [ ] Updates the open volumes after a new trade
- [ ] Stores all traders’ volume weighted average entry prices for the net open volume for every market.
- [ ] Uses VW methodology to adjust the volume weighted average entry prices for open position.
- [ ] Stores all traders’ realised PnL for every market.
- [ ] Uses VW methodology to adjust the realised PnL resulting from any trade that causes a reduction in the absolute size of open volume on every market (i.e. when volume has been closed out) 

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


## Formulae and test cases

[See spreadsheet here](https://docs.google.com/spreadsheets/d/10rfu4ayyy-EgTRsVHqazdXLUWPPLV0VnPzcMfXDM0go/edit) for examples

### Python notebook

https://colab.research.google.com/drive/1GpiNQUF6qt4rCMUJRAiXkcHjXxlGP-YB


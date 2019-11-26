# Positions API

## Acceptance Criteria

The Position API stores a net position for each trader who has ever traded in a market. Specifically, 

- [ ] Stores all traders’ net open volume by market in which they have an open position.
- [ ] Stores all traders’ volume weighted average entry prices for the net open volume for every market.
- [ ] Stores all traders’ net closed volume by market for each closed position. (Note that once a position is closed, the volume is recorded as a positive number by convention.) **TODO: confirm this is what we will store… it means separately storing long/short and for consistency using negative size for short and *displaying* long and short labels plus the absolute size may be better?**
- [ ] Stores the state of a trader’s net open position and closed positions by market. **TODO: what do we mean by this?**
- [ ] Updates the open and closed volumes when a new trade is ingested as needed.
- [ ] Creates new closed positions after net open volume reaches or passes 0. **TODO: confirm this**
- [ ] Uses FIFO to adjust the volume weighted average entry prices for open and closed positions.
- [ ] Updates the volume weighted close price for closed positions **TODO: confirm this is needed/wanted**
- [ ] Does not reload/re-process all individual trades to calculate the new values
- [ ]

## Summary

The Positions API requires additional position data for each trader, on top of that calculated by the Position Engine in the core, including:

* A view of the "profit and loss" that a trader has incurred by fully closing out a position.
* The portion of profit/loss (P&L) that has been "locked in" by partly closing out a position, i.e. "Closed P&L"
* The [average entry price](https://gitlab.com/vega-protocol/product/wikis/Trading-and-Protocol-Glossary#average-entry-price) of an open position.
* The portion of profit/loss (P&L) that continuously changes when the _mark price_ changes, i.e. "Open P&L".
* The per trade closed P&L for the buyer and seller


## Reference-level explanation

The Positions API requires additional position data for each trader, on top of that calculated by the Position Engine in the core. This includes average entry price using [FIFO (first in first out)](https://gitlab.com/vega-protocol/product/wikis/Trading-and-Protocol-Glossary#fifo-first-in-first-out) trade matching methodology and P&L. 

Implementation note: For performance reasons, this data can be stored, and updated with each new trade or change in mark price.

Note: it is possible to calculate valuation / P&L using other methodologies (e.g. VWAP only, not fifo) when a position has been only partially closed out. However, fully closed positions only have one possible calculation as the set of trades that both opened and closed the position is known and unambiguous, so there is only one correct P&L once a position is fully closed. We may choose to make the valuation methodology for open/partially closed positions configurable in future.

### **FIFO**
[FIFO ](https://gitlab.com/vega-protocol/product/wikis/Trading-and-Protocol-Glossary#fifo-first-in-first-out) is a methodology used for sorting a list of a single trader's trades into _closed out_ trades and _open_ trades. It is a matching methodology which prioritises older volume as an offset when counter volume is added to the ledger (of the trader's trades).  A worked example may be found [here](https://gitlab.com/vega-protocol/product/wikis/Trading-and-Protocol-Glossary#fifo-first-in-first-out).

### **Incrementing the records**

For each new trade:

1. If the buyer and seller are the same (wash trade), do nothing.

1. Turn the scalar size from the trade into a directional size specific to the party for whom positions are being updated (negative for the seller, positive for the buyer).

1. Calculate the opened and closed sizes. Opened size is zero if the trade only closes out volume and does not reverse the direction of the position. Closed size is zero if the position starts at zero or the trade is in the same direction as the position.

1. Determine whether we are finalising the current closed position record and creating a new one for future closed volume. This happens when the open position size reaches or crosses zero.

1. If there is some closed volume:

	1. Calculate the entry VWAP of the volume being closed, using the fifo methodology and remove that amount of volume from the first entry/ies in the fifo queue.
	
	1. Update the closed position:
		1. Update the fifo average entry price to add the newly closed volume at the fifo entry VWAP calculated above.
		1. Update the average close price (VWAP) by incorporating the closed volume and trade price (note close price is the same independent of whether fifo or other valuation methodology is being used.)
		1. **Subtract** the (directional) closed size from the closed position’s size. We subtract as the directional size closes *open* volume and therefore needs to be negated to increase the closed position volume in the correct direction.
		1. Calculate the closed position’s fifo valuation as the difference between the product’s valuation at the close price and the fifo average entry price, multiplied by the closed position’s size.

1. If there is some opened volume, append the opened size and price to the fifo queue. Note: if the last entry in the queue has the same price, the size of the last entry should be incremented rather than adding a new entry.

1. Update the open position:
	1. If there is closed volume, update the position’s fifo average entry price to remove the closed volume, by using the closed size and the fifo entry VWAP calculated above.
	1. If there is opened volume, update the position’s fifo average entry price to add the opened volume, using the opened size and the trade price.
	1. Add both the opened size and the closed size to the open positions size. This should work even if the position crosses 0.
	1. Calculate the open position’s fifo valuation as the difference between the market’s current mark price and the fifo average entry price, multiplied by the open position’s size.




## Examples / test cases

### Python notebook

https://colab.research.google.com/drive/1GpiNQUF6qt4rCMUJRAiXkcHjXxlGP-YB

### Showing closed and open volume changes
[See spreadsheet here](https://docs.google.com/spreadsheets/d/10rfu4ayyy-EgTRsVHqazdXLUWPPLV0VnPzcMfXDM0go/edit) for examples
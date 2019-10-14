Feature name: feature-name
Start date: YYYY-MM-DD
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Acceptance Criteria

- Given the following scenarios, applies the rules described in functionality to update the position size (check new position size is as expected given the rules and the old position size):
  - [ ] Open long position, trades occur increasing long position
  - [ ] Open long position, trades occur decreasing long position
  - [ ] Open short position, trades occur increasing (greater abs(size)) short position
  - [ ] Open short position, trades occur decreasing (smaller abs(size)) short position
  - [ ] Open short position, trades occur taking position to zero (closing it)
  - [ ] Open long position, trades occur taking position to zero (closing it)
  - [ ] Open short position, trades occur closing the short position and opening a long position
  - [ ] Open long position, trades occur closing the long position and opening a short position
  - [ ] No position, trades occur opening a long position
  - [ ] No position, trades occur opening a short position
  - [ ] Open position, trades occur that close it (take it to zero), in a separate transaction, trades occur and that opens a new position
- [ ] Opening and closing positions for multiple traders, maintains position size for all open (non-zero) positions
- [ ] Maintains separate position data for each market a trader is active in
- [ ] Does not store data for positions that are reduced to size == 0
- [ ] Does not change position size for a wash trade (buyer = seller)

# Summary

Vega needs to keep track of positions for two purposes:

- The **Position Engine** needs to keep basic position data for each trader in each market where they have a *non-zero net open position*:
	- Position size (net volume: positive for long positions, negative for short positions)
	- Net active long orders: the sum of the long volume for all the trader's active order (will always be >= 0)
	- Net active short orders: the sum of the short volume for all the trader's active order (will always be <= 0)

- The **Positions API**, for all practical purpose (to achieve reasonable performance) needs to maintain records of both open and closed positions for all traders, including:
	- Position size (net volume: positive for long positions, negative for short positions)
	- Volume weighted average entry price see [average price](https://gitlab.com/vega-protocol/product/wikis/Trading-and-Protocol-Glossary#average-entry-price)
	- Volume weighted average closing price (for closed positions)
	- Valuation / P&L (a.k.a. unrealised P&L for open positions, realised P&L for closed)

Both components work by processing each Trade occurring in Vega in order, as they occur, and updating the required position record. As long as the right data is stored, this can be done in both cases without re-iterating over prior trades when ingesting a new trade.

# Guide-level explanation

# Reference-level explanation

The Position Engine processes each trade in the following way:

1. If the buyer and seller are the same (wash trade), do nothing.

1. For each of the buyer and seller, look for a position record for the current market. If either record is not found, create it.

1. Update the position size for each record:
	- BuyerPosition.size += Trade.size
	- SellerPosition.size -= Trade.size

1. If either position record has Position.size == 0, delete it, otherwise save the updated record.
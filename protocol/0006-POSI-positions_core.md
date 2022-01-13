# Positions Core

# Acceptance Criteria

## Open position data
- Given the following scenarios, applies the rules described in functionality to update the open position size (check new open position size is as expected given the rules and the old open position size):
  - [ ] Open long position, trades occur increasing long position
  - [ ] Open long position, trades occur decreasing long position
  - [ ] Open short position, trades occur increasing (greater abs(size)) short position
  - [ ] Open short position, trades occur decreasing (smaller abs(size)) short position
  - [ ] Open short position, trades occur taking position to zero (closing it)
  - [ ] Open long position, trades occur taking position to zero (closing it)
  - [ ] Open short position, trades occur closing the short position and opening a long position
  - [ ] Open long position, trades occur closing the long position and opening a short position
  - [ ] No open position, trades occur opening a long position
  - [ ] No open position, trades occur opening a short position
  - [ ] Open position, trades occur that close it (take it to zero), in a separate transaction, trades occur that open a new position
- [ ] Opening and closing positions for multiple traders, maintains position size for all open (non-zero) positions

- [ ] Does not change position size for a wash trade (buyer = seller)

## Open orders data
- Given the following scenarios, applies the rules described in functionality to update the net buy order amounts (check new size is as expected given the rules and the old size).
  - [ ] No active buy orders, a new buy order is added to the order book
  - [ ] Active buy orders, a new buy order is added to the order book
  - [ ] Active buy orders, an existing buy order is amended which increases its size.
  - [ ] Active buy orders, an existing buy order is amended which decreases its size.
  - [ ] Active buy orders, an existing buy order's price is amended such that it trades a partial amount.
  - [ ] Active buy orders, an existing buy order's price is amended such that it trades in full.
  - [ ] Active buy order, an order initiated by another trader causes a partial amount of the existing buy order to trade.
  - [ ] Active buy order, an order initiated by another trader causes the full amount of the existing buy order to trade.
  - [ ] Active buy orders, an existing order is cancelled
  - [ ] Active buy orders, an existing order expires

- Repeat the above but for sell orders.

## General

- [ ] Maintains separate position data for each market a trader is active in
- [ ] If there is either one or more of the position record's fields is non zero (i.e. open position size, active buy order size, active sell order size), the position record exists.
- [ ] Does not store data for positions that are reduced to size == 0 for all 3 data components (i.e. open position, active buy orders and active sell orders)
- [ ] All of a trader's orders are cancelled

# Summary

**Vega core** needs to keep basic position data for each trader in each market where they have a *non-zero net open position* and/or *non-zero net active buy orders* and/or *non-zero net active sell orders*.

A position record is comprised of:

	- Position size, decimal (net volume: positive for long positions, negative for short positions)
	- Net active long orders: the sum of the long volume for all the trader's active order (will always be >= 0)
	- Net active short orders: the sum of the short volume for all the trader's active order (will always be <= 0)

This core processes each relevant transaction (in sequential order, as they occur):
- trades
- new orders
- size updates to orders
- cancellation or expiry of orders

and updates the required position record. 

In the case of trades, as long as the right data is stored, this can be done in both cases without re-iterating over prior trades when ingesting a new trade.

# Reference-level explanation

## Updating position size

Position size is a number that represents the net transacted volume of a trader in the market. The position size is therefore only ever updated when a trader is party to a trade. A trade (and therefore a position) may be of any size that is a multiple of the smallest number that can be represented given the `Position Decimal Places` specified in the [Market Framework](./0001-MKTF-market_framework.md).

The Position core functionality processes each trade in the following way:

1. If the buyer and seller are the same (wash trade), do nothing.

1. For each of the buyer and seller, look for a position record for the current market. If either record is not found, create it.

1. Update the position size for each record:
	- BuyerPosition.size += Trade.size
	- SellerPosition.size -= Trade.size

1. If either position record has Position.size == 0 and no active orders, delete it, otherwise save the updated record.

## Updating net active buy and sell order sizes

Net active buy size (and net active sell) size refer to the aggregated size of buy (and sell) orders that a trader has active on the order book at a point in time. 

These numbers are affected by any transaction that alters the net sum of a trader's open orders on the order book, including:

- trades that a trader is party to
- a trader's new order (which will increase or decrease the net buy or sell volume)
- a trader's size updates to existing orders
- a trader's cancellation of an order
- expiry of a trader's existing order

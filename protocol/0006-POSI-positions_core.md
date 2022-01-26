# Positions Core

# Acceptance Criteria

## Open position data
- Given the following scenarios, applies the rules described in functionality to update the open position size (check new open position size is as expected given the rules and the old open position size):
  - [ ] Open long position, trades occur increasing long position (<a name="0006-POSI-001" href="#0006-POSI-001">0006-POSI-001</a>)
  - [ ] Open long position, trades occur decreasing long position (<a name="0006-POSI-002" href="#0006-POSI-002">0006-POSI-002</a>)
  - [ ] Open short position, trades occur increasing (greater abs(size)) short position(<a name="0006-POSI-003" href="#0006-POSI-003">0006-POSI-003</a>)
  - [ ] Open short position, trades occur decreasing (smaller abs(size)) short position (<a name="0006-POSI-004" href="#0006-POSI-004">0006-POSI-004</a>)
  - [ ] Open short position, trades occur taking position to zero (closing it) (<a name="0006-POSI-005" href="#0006-POSI-005">0006-POSI-005</a>)
  - [ ] Open long position, trades occur taking position to zero (closing it) (<a name="0006-POSI-007" href="#0006-POSI-007">0006-POSI-007</a>)
  - [ ] Open short position, trades occur closing the short position and opening a long position(<a name="0006-POSI-008" href="#0006-POSI-008">0006-POSI-008</a>)
  - [ ] Open long position, trades occur closing the long position and opening a short position (<a name="0006-POSI-009" href="#0006-POSI-009">0006-POSI-009</a>)
  - [ ] No open position, trades occur opening a long position (<a name="0006-POSI-010" href="#0006-POSI-010">0006-POSI-010</a>)
  - [ ] No open position, trades occur opening a short position (<a name="0006-POSI-011" href="#0006-POSI-011">0006-POSI-011</a>)
  - [ ] Open position, trades occur that close it (take it to zero), in a separate transaction, trades occur that open a new position (<a name="0006-POSI-012" href="#0006-POSI-012">0006-POSI-012</a>)
- [ ] Opening and closing positions for multiple traders, maintains position size for all open (non-zero) positions (<a name="0006-POSI-013" href="#0006-POSI-013">0006-POSI-013</a>)
- [ ] Does not change position size for a wash trade (buyer = seller) (<a name="0006-POSI-014" href="#0006-POSI-014">0006-POSI-014</a>)

## Open orders data
- Given the following scenarios, applies the rules described in functionality to update the net buy order amounts (check new size is as expected given the rules and the old size).
  - [ ] No active buy orders, a new buy order is added to the order book (<a name="0006-POSI-016" href="#0006-POSI-016">0006-POSI-016</a>)
  - [ ] Active buy orders, a new buy order is added to the order book (<a name="0006-POSI-017" href="#0006-POSI-017">0006-POSI-017</a>)
  - [ ] Active buy orders, an existing buy order is amended which increases its size. (<a name="0006-POSI-018" href="#0006-POSI-018">0006-POSI-018</a>)
  - [ ] Active buy orders, an existing buy order is amended which decreases its size.  (<a name="0006-POSI-019" href="#0006-POSI-019">0006-POSI-019</a>)
  - [ ] Active buy orders, an existing buy order's price is amended such that it trades a partial amount. (<a name="0006-POSI-020" href="#0006-POSI-020">0006-POSI-020</a>)
  - [ ] Active buy orders, an existing buy order's price is amended such that it trades in full. (<a name="0006-POSI-021" href="#0006-POSI-021">0006-POSI-021</a>)
  - [ ] Active buy order, an order initiated by another trader causes a partial amount of the existing buy order to trade. (<a name="0006-POSI-022" href="#0006-POSI-022">0006-POSI-022</a>)
  - [ ] Active buy order, an order initiated by another trader causes the full amount of the existing buy order to trade. (<a name="0006-POSI-023" href="#0006-POSI-023">0006-POSI-023</a>)
  - [ ] Active buy orders, an existing order is cancelled (<a name="0006-POSI-024" href="#0006-POSI-024">0006-POSI-024</a>)
  - [ ] Active buy orders, an existing order expires (<a name="0006-POSI-025" href="#0006-POSI-025">0006-POSI-025</a>)

- Repeat the above but for sell orders.

## General

- [ ] Maintains separate position data for each market a trader is active in (<a name="0006-POSI-026" href="#0006-POSI-026">0006-POSI-026</a>)
- [ ] If there is either one or more of the position record's fields is non zero (i.e. open position size, active buy order size, active sell order size), the position record exists. (<a name="0006-POSI-027" href="#0006-POSI-027">0006-POSI-027</a>)
- [ ] Does not store data for positions that are reduced to size == 0 for all 3 data components (i.e. open position, active buy orders and active sell orders)  (<a name="0006-POSI-028" href="#0006-POSI-028">0006-POSI-028</a>)
- [ ] All of a trader's orders are cancelled  (<a name="0006-POSI-029" href="#0006-POSI-029">0006-POSI-029</a>)

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

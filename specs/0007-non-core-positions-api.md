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

## Summary

The Positions API requires additional position data for each trader, one top of that calculated by the Position Engine in the core. This includes average entry price using ‘fifo’ (first in first out) methodology and P&L. Additionally, the Positions API also needs to be able to provide historic (closed) position data. For performance reasons, this data should be stored, and updated with each new trade or change in mark price.

Note: it is possible to calculate valuation / P&L using other methodologies (e.g. VWAP only, no fifo) *for open and partially closed positions*, but fully closed positions only have one possible calculation as the set of trades that both opened and closed the position is known and unambiguous, so there is only one correct P&L once a position is fully closed. We may choose to make the valuation methodology for open/partially closed positions configurable in future.


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
		1. Finalise the closed position if needed (as determined in 4, above) and create a new ‘active’ closed position. Note: when the position is finalised the fifo average entry price will agree with any other definition of the entry price for the set of trades included in the position (we can see this is true, as the gain/loss on the total position is now known and the close price can only be determined in one way.)

1. If there is some opened volume, append the opened size and price to the fifo queue. Note: if the last entry in the queue has the same price, the size of the last entry should be incremented rather than adding a new entry.

1. Update the open position:
	1. If there is closed volume, update the position’s fifo average entry price to remove the closed volume, by using the closed size and the fifo entry VWAP calculated above.
	1. If there is opened volume, update the position’s fifo average entry price to add the opened volume, using the opened size and the trade price.
	1. Add both the opened size and the closed size to the open positions size. This should work even if the position crosses 0.
	1. Calculate the open position’s fifo valuation as the difference between the market’s current mark price and the fifo average entry price, multiplied by the open position’s size.


See https://docs.google.com/spreadsheets/d/10rfu4ayyy-EgTRsVHqazdXLUWPPLV0VnPzcMfXDM0go/edit for examples


### Data model

**NOTES:**
- P&L / position ‘value’ also needs to be calculated. If we wish to store this with the position (as shown in the pseudocode), in option 1 we’d add a single field for the position value, and in option 2 we’d add one each of open and closed volume. Alternatively we could calculate the value only when requested, potentially saving a lot of calls to Product.value(), which in some products could be somewhat expensive.
- Positions are attached to a market and party, which may be stored with the position or not as needed, and may be required to be returned with a position record in some APIs  //TODO: determine actual API requirements
- The downside of option 2 is that over time most positions will be fully closed (and probably the majority of open positions will have no closed volume, but len(closed) will dwarf len(open) over time), so we would potentially be allocating space to store zero values for the unused open (or closed) component of the structure in every case.

```rust
// Option 1 — open and closed volume are different position records:
struct Position {
    type: PositionType = Open | Closed,
    size: SignedInteger,  // +ve for long, -ve for short
    entry_vwap_fifo: Decimal,  // Or whatever type we’re doing prices in (OR float ?????) //TODO: decide this
    close_price: (as above - price type),
    value/pnl: number - decimal?
}

// Option 2 — open and closed volume are on same record
struct Position {
    open_size: SignedInteger,  // +ve for long, -ve for short
    closed_size: SignedInteger,  // +ve for long, -ve for short
    open_entry_vwap_fifo: Decimal,  // Or whatever type we’re doing prices in (OR float ?????) //TODO: decide this
    closed_entry_vwap_fifo: (as above - price type),
    close_vwap: (as above - price type),
    open_value/pnl: number - decimal?,
    closed_value/pnl: number - decimal?,
}
```


### Pseudocode example algorithm

**NOTE:** this example uses the data model option 1 above. If we go with option 2 we just pass one ‘active position’ to each function and refer to the appropriate open/closed fields as needed.

```rust
// closed_pos is the active closed position
// fifo_queue (a.k.a. ‘[fifo] open volume curve’) could be stored on the open position or in a map or something, there is one such queue per non-zero open position
fn update_positions(party, open_pos, closed_pos, trade, fifo_queue) {

	if trade.buyer == trade.seller return  // wash trade

	let size = party == trade.buyer ? trade.size : -trade.size	
	let closed_size = closed_size(open_pos, size)
	let opened_size = size - closed_size
	let finalise_closed = closed_size >= open_pos.size
	
	if closed_size > 0 {
		let closed_entry_vwap_fifo = fifo_close(fifo_queue, closed_size)
		update_closed(closed_pos, closed_size, closed_entry_vwap_fifo, trade.price, finalise_closed)
	}
	
	if opened_size > 0 {
		fifo_open(fifo_queue, opened_size, trade.price)
	}
	
	// This next step happens even if opened_size == 0!
	update_open(open_pos, opened_size, trade.price, closed_size, closed_entry_vwap_fifo)
}

fn closed_size(open_pos, size) {
	if open_pos.size != 0 && (open_pos.size > 0 != size > 0) {
		return abs(size) > abs(open_pos.size) ? open_pos.size : size
	}
	return 0
}

fn fifo_close(fifo_queue, size) {
	let vwap, done_size = 0, 0
	while fifo_queue[0].size < size - done_size {
		let out = fifo_queue.remove_at(0)
		vwap = update_vwap(vwap, done_size, out.size, out.price)
		done_size += out.size
	}
	let fst = fifo_queue[0]
	vwap = update_vwap(vwap, done_size, size - done_size, fst.price)
	fst.size -= size - done_size
	
	return vwap
}

fn update_vwap(vwap, size, add_price, add_size) {
	return (vwap * size + add_price * add_size) / (size + add_size)
}

fn update_closed(closed_pos, closed_size, closed_entry_vwap_fifo, close_price, finalise_closed) {	
	closed_pos.entry_vwap_fifo = update_vwap(closed_pos.entry_vwap_fifo, closed_pos.size, closed_entry_vwap_fifo, closed_size)	
	closed_pos.close_vwap = update_vwap(closed_pos.close_vwap, closed_pos.size, close_price, closed_size)
	closed_pos.size -= closed_size
	
	// Work out gain/loss
	closed_pos.value_fifo = closed_pos.size * (Product.value(closed_pos.close_vwap) - Product.value(closed_pos.entry_vwap_fifo))

	// Finalise position when an open position is fully closed, including when a position is reversed. As it is no longer the active closed position, it should be saved and a new active closed position (size = 0) created.
	if finalise_closed { 
		// Also, once we fully close a position, all valuation (P&L calculation) methodologies must give the same number, so we could do something like:
		closed_pos.final_value = closed_pos.value_fifo
	}
}

fn fifo_open(fifo_queue, size, price) {
	if fifo_queue[:last-item].price = price {
		fifo_queue[:last-item].size += size
	} 
	else {
		fifo_queue.append({ size, price })
	}
}

fn update_open(open_pos, opened_size, price, closed_size, closed_entry_vwap) {
	open_pos.entry_vwap_fifo = update_vwap(open_pos.entry_vwap_fifo, open_pos.size, closed_entry_vwap, closed_size)
	open_pos.entry_vwap_fifo = update_vwap(open_pos.entry_vwap_fifo, open_pos.size, price, opened_size)
	open_pos.size += (closed_size + opened_size)
	
	// Work out gain/loss
	open_pos.value = open_pos.size * (Product.value(market.mark_price) - Product.value(open_pos.entry_vwap_fifo))
}
```


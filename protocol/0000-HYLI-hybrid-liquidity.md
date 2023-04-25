# WIP Hybrid Liquidity

Two components initially, will be separate specs:

1. Hybrid Order Books / Liquidity Sourcing

2. Simple Algortihmic Spot Liquidity



## Hybrid Order Books / Liquidity Sourcing

Currently an aggressive order is compared against the prices on the order book when trading.
All orders that are active and eligible (in future this may depend on filtering logic but for now this is all active, non-parked orders) and crossed are eligible for trading.
Orders are matched in price, time priority until there are no more crossed orders of the agressive order has fully traded.

Pseudocode:

```
while (incoming_order.remaining > 0) 
	and (incoming_order is crossed with book.best_price_on_other_side) {

		trades << make_trade(incoming_order, book.top_order_on_other_side)
}

```


With liquidity sourcing, instead of comparing agsint only the top of the order book, we will be comparing against the best price from all available liquidity sources (pools and order book).
All orders from the best liquidity source by price, time that are better priced than the next source are eligible for trading, if they are crossed with the incoming order.


```
//pool1 = SimpleSpotPool(params, initial_balance_asset1, initial_balance_asset2)
//pool2 = SimpleSpotPool(params, initial_balance_asset1, initial_balance_asset2)

assert(get_liquidity_sources() = [
	order_book,
	pool1,
	pool2,
	pool3,
	...etc.
])


while incoming_order.remaining > 0 {

		// probably these should be in a sorted data structure, but for simplicity:
		sources = sort(get_liquidity_sources(), x => [x.best_price, x.update_time])

		if sources[0].best_price is not crossed with incoming_order: break
		
		top_orders = sources[0].orders_better_priced_than([sources[1].best_price, incoming_order.price])
		for o in top_orders {
			trades << make_trade(incoming_order, o)
		}
}

```


## Simple Algortihmic Spot Liquidity

TBD!

This will be similar to Uniswap pools.
User can supply funds in each asset along with parameters for their liquidity.
Their liquidity is then added as a liquidity source.


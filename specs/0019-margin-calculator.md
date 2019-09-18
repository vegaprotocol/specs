Feature name: margin-calculator
Start date: YYYY-MM-DD
Whitepaper section: 6.1, section "Margin Calculation"

# Summary

The _margin calculator_ returns the set of relevant margin levels for a given position and entry price:
1. Maintenance margin
1. Collateral search level
1. Initial margin
1. Collateral release level

# Guide Level Explanation

# Reference Level Explanation

The calculator takes as inputs:
- ```size of position_on_market``` (this is net volume of transacted positions rather than orders)
- ```price of position_on_market``` (this is the volume weighted entry price)
- ```position size of buy OR sell orders``` (positive for buys, negative for sells)

## Simple calculation for limit order book

In this simple methodology, a linearised margin formula is used to return the maintenance margin, using risk factors returned by the [quantitative model](./0018-quant-calculator.md).

The maintenance margin is calculated using the following formula:

```margin_maintenance = close-out-pnl + (position_size_on_market + position_size_on_order) * [ quantitative_model.risk_factors ] . [ Product.market_observables ] ```

If position_size_on_market = 0, ```close-out-pnl = 0```

If position_size_on_market <> 0, 

```close-out-pnl = position_size_on_market * (Product.value(closeout_price) - Product.value(position_price)) ```

where ```closeout_price``` is the price that would be achieved on the order book if the trader's position size on market  were exited.   This is by 'exiting' a long position through the bids on the order book, or for a short position through the asks on the order book.

Note, if there is insufficient order book volume for this ```closeout_price``` to be calculated (per position), the ```closeout_price``` is the price that would be achieved for as much of the volume that could theoretically be closed (in general we expect market protection mechanisms make this unlikely to occur).

## Scaling other margin levels

The other three margin levels are scaled relative to the maintenance margin level, using scaling levels defined in the risk parameters for a market.

```search_level = margin_maintenance * search_level_scaling_factor```

```initial_margin = margin_maintenance * initial_margin_scaling_factor```

```collateral_release_level = margin_maintenance * collateral_release_scaling_factor```

where the scaling factors are set as risk parameters ( see [market framework](./0001-market-framework.md) ).


## Positive and Negative numbers

Positive margin numbers represent a liability for a trader. Therefore, if comparing two margin numbers, the greatest liability (i.e. 'worst' margin number for the trader) is the most positive number.


# Pseudo-code / Examples

```
Current order book:

asks: [
    {volume: 3, price: $258},
    {volume: 5, price: $240},
    {volume: 3, price: $188}
]

bids: [
    {volume: 1, price: $120},
    {volume: 4, price: $240},
    {volume: 7, price: $258}
]

risk_factor_short = 0.11
risk_factor_long = 0.1

last_trade = $144

Trader1_futures_position = {open: 10, buys: 4,  sells: 8, price: $103.28}

```
```
Case 1 - protocol seeks margin calculation for Trader1's open position

closeout_price = ( 1*$120 + 4*$240 + 5*$258 ) / 10 = $237
close-out-pnl = 10 * ($237 - $103.28) = $1,337.2

getMargins(Trader1_position.open) =  $1,337.2 + 10 * 0.1 * $144 = $1481.2
```

```
Case 2 - protocol seeks margin calculation for Trader1's net long position

closeout_price = ( 1*$120 + 4*$240 + 5*$258 ) / 10 = $237
close-out-pnl = 10 * ($237 - $103.28) = $1,337.2

getMargins(Trader1_position.netLong) =  $1,337.2 + 10 * 0.1 * $144 = $1481.2


```


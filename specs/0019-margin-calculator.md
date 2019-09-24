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

* position record = [```open_volume```, ```buy_orders```, ```sell_orders```] where ```open_position``` refers to size of open position (+ve is long, -ve is short), ```buy_orders``` / ```sell_orders``` refer to size of all orders on the buy / sell side.
- ```mark price```

and returns 4 margin requirement levels

1. Maintenance margin
1. Collateral search level
1. Initial margin
1. Collateral release level

## Steps to calculate margins

1. Calculate the maintenance margin for the riskiest long position.
1. Calculate the maintenance margin for the riskiest short position.
1. Select the maintenance margin that is highest out of steps 1 & 2.
1. Scale this maintenance margin by the margin level scaling factors.
1. Return 4 numbers: the maintenance margin, collateral search level, initial margin and collateral release level.


## Calculation of riskiest long and short positions

The protocol calculates the margin requirements for the ```riskiest long``` and ```riskiest short``` positions.

```riskiest long```  = max( ```open_volume``` + ```buy_orders``` , 0 )

```riskiest short``` = min( ```open_volume``` + ```sell_orders```, 0 )

## Limit order book linearised calculation

In this simple methodology, a linearised margin formula is used to return the margin requirement levels, using risk factors returned by the [quantitative model](./0018-quant-calculator.md).

**Step 1** 

If ```riskiest long == 0``` then ```maintenance_margin_long = 0```.

Else

```maintenance_margin_long = slippage_volume * ( slippage_per_unit + [ quantitative_model.risk_factors_long ] . [ Product.market_observables ] ) + buy_orders * [ quantitative_model.risk_factors_long ] . [ Product.market_observables ]  ```,

where

```slippage_per_unit =  Product.value(exit_price) - Product.value(mark_price) ```,

```slippage_volume =  max( open_volume, 0 ) ```,

where ```mark price``` used is the last one used for the last settlement and ```exit_price``` is the price that would be achieved on the order book if the trader's position size on market were exited.
This is by 'exiting' a long position through the bids on the order book, or for a short position through the asks on the order book.

Note, if there is insufficient order book volume for this ```exit_price``` to be calculated (per position), the ```exit_price``` is the price that would be achieved for as much of the volume that could theoretically be closed (in general we expect market protection mechanisms make this unlikely to occur).

**Step 2** 

If ```riskiest short == 0``` then ```maintenance_margin_short = 0```.

Else

```maintenance_margin_short = abs(slippage_volume) * ( slippage_per_unit + [ quantitative_model.risk_factors_short ] . [ Product.market_observables ] ) + sell_orders * [ quantitative_model.risk_factors_short ] . [ Product.market_observables ]  ```,

where meanings of terms in Step 1 apply except for:

```slippage_volume =  min( open_volume, 0 ) ```,

**Step 3** 

```maintenance_margin = max ( maintenance_margin_long, maintenance_margin_short)```

## Scaling other margin levels

**Step 4** 

The other three margin levels are scaled relative to the maintenance margin level, using scaling levels defined in the risk parameters for a market.

```search_level = margin_maintenance * search_level_scaling_factor```

```initial_margin = margin_maintenance * initial_margin_scaling_factor```

```collateral_release_level = margin_maintenance * collateral_release_scaling_factor```

where the scaling factors are set as risk parameters ( see [market framework](./0001-market-framework.md) ).

## Positive and Negative numbers

Positive margin numbers represent a liability for a trader. Therefore, if comparing two margin numbers, the greatest liability (i.e. 'worst' margin number for the trader) is the most positive number. All margin levels returned are positive numbers.


# Pseudo-code / Examples

## EXAMPLE 1 - full worked example


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

search_level_scaling_factor = 1.1
initial_margin_scaling_factor = 1.2
collateral_release_scaling_factor = 1.3

Trader1_futures_position = {open_volume: 10, buys: 4,  sells: 8}

getMargins(Trader1_position) 

# Step 1
riskiest long  = max( open_volume + buy_orders, 0 ) = max( 10 + 4, 0 ) = 14
riskiest short = min( open_volume + sell_orders, 0 ) =  min( 10 - 8, 0 ) = 0

# Step 2

## exit price considers what selling the open position (10) on the order book would achieve. 

slippage_per_unit =  Product.value(exit_price) - Product.value(mark_price) = Product.value((1*120 + 4*240 + 5*258)/10) - Product.value($144) = 237 - 144 = 93

slippage_volume =  max( open_volume, 0 ) = max ( 10, 0 ) = 10


maintenance_margin_long = slippage_volume * ( slippage_per_unit + [ quantitative_model.risk_factors_long ] . [ Product.market_observables ] ) + buy_orders * [ quantitative_model.risk_factors_long ] . [ Product.market_observables ]

= 10 * (93 + 0.1 * 144) + 4 * 0.1 * 144
= 1131.6

# Step 3

Since riskiest short == 0 then maintenance_margin_short = 0

# Step 4

maintenance_margin = max ( 1131.6, 0) = 1131.6

# Step 4

collateral_release_level = 1131.6 * collateral_release_scaling_factor = 1131.6 * 1.1
initial_margin = 1131.6 * initial_margin_scaling_factor = 1131.6 * 1.2
search_level = 1131.6 * search_level_scaling_factor = 1131.6 * 1.3



```

## EXAMPLE 2 - calculating correct slippage volume

Given the following trader positions:

| Tables        | Open           | Buys  | Sells |
| ------------- |:-------------:| -----:| -----:|
| case-1      | 1 | 1 | -2
| case-2      | -1 | 2| 0
| case-3 | 1 | 0 | -2


*case-1*

riskiest long: 2

riskiest short: -1

slippage volume long: 1

slippage volume short: 0

*case-2*

riskiest long: 1

riskiest short: -1

slippage volume long: 0

slippage volume short: -1

*case-3*

riskiest long: 1

riskiest short: -1

slippage volume long: 1

slippage volume short: 0


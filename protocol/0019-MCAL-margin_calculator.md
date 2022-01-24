# Margin Calculator

# Acceptance Criteria

1. [ ] Get four margin levels for one or more parties (<a name="0019-MCAL-001" href="#0019-MCAL-001">0019-MCAL-001</a>)
  1. [ ] Margin levels are correctly calculated against riskiest long and short positions (<a name="0019-MCAL-002" href="#0019-MCAL-002">0019-MCAL-002</a>)
2. [ ] Zero position and zero orders results in all zero margin levels (<a name="0019-MCAL-003" href="#0019-MCAL-003">0019-MCAL-003</a>)
3. [ ] If ```riskiest long > 0``` and there are no bids on the order book, the ```exit price``` is equal to the initial mark price, as set by a market parameter. (<a name="0019-MCAL-004" href="#0019-MCAL-004">0019-MCAL-004</a>)  
4. [ ] If ```riskiest long > 0``` && ```0 <``` *sum of volume of order book bids* ```< riskiest long```, the ```exit price``` is equal to the *volume weighted price of the order book bids*.  (<a name="0019-MCAL-005" href="#0019-MCAL-005">0019-MCAL-005</a>)
5. [ ] If ```riskiest short < 0``` and there are no offers on the order book, the ```exit price``` is equal to the initial mark price, as set by a market parameter. (<a name="0019-MCAL-006" href="#0019-MCAL-006">0019-MCAL-006</a>)
6. [ ] If ```riskiest short < 0``` && ```0 <``` *sum of absolute volume of order book offers* ```< riskiest short```, the ```exit price``` is equal to the *volume weighted price of the order book offers*.  (<a name="0019-MCAL-007" href="#0019-MCAL-007">0019-MCAL-007</a>)
7. [ ] Example 1, 2 and scenarios are tested in core 

# Summary

The _margin calculator_ returns the set of relevant margin levels for a given position and entry price:
1. ***Maintenance margin***
1. ***Collateral search level***
1. ***Initial margin***
1. ***Collateral release level***

The protocol is designed such that ***Maintenance margin < Collateral search level < Initial margin < Collateral release level***.

Margin levels are used by the protocol to ascertain whether a trader has sufficient collateral to maintain a margined trade. When the trader enters an open position, this required amount is equal to the *initial margin*. Subsequently, throughout the life of this open position, the minimum required amount is the *maintenance margin*. As a trader's collateral level dips below the *collateral search level* the protocol will automatically search for more collateral to be assigned to support this open position from the trader's general collateral accounts. In the event that a trader has collateral that is above the *collateral release level* the protocol will automatically release collateral to a trader's general collateral account for the relevant asset.

**Whitepaper reference:** 6.1, section "Margin Calculation"

In future there can be multiple margin calculator implementations that would be configurable in the market framework. This spec describes one implementation.

# Reference Level Explanation

The calculator takes as inputs:

* position record = [```open_volume```, ```buy_orders```, ```sell_orders```] where ```open_volume``` refers to size of open position (+ve is long, -ve is short), ```buy_orders``` / ```sell_orders``` refer to size of all orders on the buy / sell side (+ve is long, -ve is short).  See [positions core specification](./0006-POSI-positions_core.md).
- ```mark price```
- ```scaling levels``` defined in the risk parameters for a market
- ```quantitative risk factors```

Note: `open_volume` may be fractional, depending on the `Position Decimal Places` specified in the [Market Framework](./0001-MKTF-market_framework.md). If this is the case, it may also be that order/positions sizes and open volume are stored as ints (i.e. int64). In this case, **care must be taken** to ensure that the acutal fractional sizes are used when calculating margins. For example, if Position Decimals Places (PDP) = 3, then an open volume of 12345 is actualy 12.345 (`12345 / 10^3`). This is important to avoid margins being off by orders of magnitude. It is notable becuae outside of margin calculations, and display to end users, the integer values can generally be used as-is.

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

In this simple methodology, a linearised margin formula is used to return the margin requirement levels, using risk factors returned by the [quantitative model](./0018-RSKM-quant_risk_models.ipynb).

**Step 1** 

If ```riskiest long == 0``` then ```maintenance_margin_long = 0```.

In this simple methodology, a linearised margin formula is used to return the maintenance margin, using risk factors returned by the [quantitative model](./0018-RSKM-quant_risk_models.ipynb).

```maintenance_margin_long = maintenance_margin_long_open_position + maintenance_margin_long_open_orders```

with

```maintenance_margin_long_open_position = max(slippage_volume * slippage_per_unit, 0) + slippage_volume * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ]```,

```maintenance_margin_long_open_orders = buy_orders * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ]  ```,

where

```slippage_volume =  max( open_volume, 0 ) ```,

and

if ```open_volume > 0```  then 

```slippage_per_unit =  Product.value(market_observable) - Product.value(exit_price) ```, 

else ```slippage_per_unit = 0```.


where 

```market_observable``` = ```settlement_mark_price``` if in continuous trading and ```indicative_uncrossing_price``` if in an auction

```settlement_mark_price``` refers to the mark price most recently utilised in [mark to market settlement](./0003-MTMK-mark_to_market_settlement.md). If no previous mark to market settlement has occurred, the initial mark price, as defined by a market parameter, should be used.

```exit_price``` is the price that would be achieved on the order book if the trader's position size on market were exited. Specifically:

* **Long positions** are exited by the system considering what the volume weighted price of **selling** the size of the open long position (not riskiest long position) on the order book (i.e. by selling to the bids on the order book). If there is no open long position, the slippage per unit is zero.

* **Short positions** are exited by the system considering what the volume weighted price of **buying** the size of the open short position (not riskiest short position) on the order book (i.e. by buying from the offers (asks) on the order book). If there is no open short position, the slippage per unit is zero.

Note, if there is insufficient order book volume for this ```exit_price``` to be calculated (per position), the ```exit_price``` is the price that would be achieved for as much of the volume that could theoretically be closed (in general we expect market protection mechanisms make this unlikely to occur).

If there is zero order book volume on the relevant side of the order book to calculate the ```exit_price```, the most recent calculation of the mark price, should be used instead.

**Step 2** 

If ```riskiest short == 0``` then ```maintenance_margin_short = 0```.

Else

```maintenance_margin_short = maintenance_margin_short_open_position + maintenance_margin_short_open_orders```

with 

```maintenance_margin_short_open_position = max(abs(slippage_volume) * slippage_per_unit, 0) + abs(slippage_volume) * [ quantitative_model.risk_factors_short ] . [ Product.value(market_observable) ]```

```maintenance_margin_short_open_orders = abs(sell_orders) * [ quantitative_model.risk_factors_short ] . [ Product.value(market_observable) ]  ```,

where meanings of terms in Step 1 apply except for:

```slippage_volume =  min( open_volume, 0 ) ```,

```slippage_per_unit =  -1 * (Product.value(market_observable) - Product.value(exit_price) ) ```

**Step 3** 

```maintenance_margin = max ( maintenance_margin_long, maintenance_margin_short)```

## Margin calculation for auctions

We are assuming that:
- `indicative_uncrossing_price` is *not* the mark price, so no mark-to-market transfers happen (update mark-to-market spec)
- mark price never changes during an auction, so it's the last mark price from before auction,
- during an auction we never release money from the margin account, however we top-it-up as required,
- no closeouts during auctions

Use the same calculation as above with the following re-defined: 
- in `slippage_per_unit` we use `indicative_uncrossing_price` instead of `exit_price`. If there is no `indicative_uncrossing_price` then use `slippage_per_unit = 0`.
- For the open position part of the margin: `market_observable = indicative_uncrossing_price`. If there is no current `indicative_uncrossing_price`, then use the previous value for `market_observable` whatever it was (i.e. the last `indicative_uncrossing_price` or `mark_price`).
- For the orders part of the margin: `market_observable = indicative_uncrossing_price`. If there is no current `indicative_uncrossing_price`, then use the volume weighted average price of the party's long / short orders. 


## Scaling other margin levels

**Step 4** 

The other three margin levels are scaled relative to the maintenance margin level, using scaling levels defined in the risk parameters for a market.

```search_level = margin_maintenance * search_level_scaling_factor```

```initial_margin = margin_maintenance * initial_margin_scaling_factor```

```collateral_release_level = margin_maintenance * collateral_release_scaling_factor```

where the scaling factors are set as risk parameters ( see [market framework](./0001-MKTF-market_framework.md) ).

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
    {volume: 4, price: $110},
    {volume: 7, price: $108}
]

risk_factor_short = 0.11
risk_factor_long = 0.1

last_trade = $144

search_level_scaling_factor = 1.1
initial_margin_scaling_factor = 1.2
collateral_release_scaling_factor = 1.3

Trader1_futures_position = {open_volume: 10, buys: 4,  sells: 8}

getMargins(Trader1_position) 

riskiest long  = max( open_volume + buy_orders, 0 ) = max( 10 + 4, 0 ) = 14
riskiest short = min( open_volume + sell_orders, 0 ) =  min( 10 - 8, 0 ) = 0

# Step 1

## exit price considers what selling the open position (10) on the order book would achieve. 

slippage_per_unit =  Product.value(previous_mark_price) - Product.value(exit_price) = Product.value($144) - Product.value((1*120 + 4*110 + 5*108)/10) = 144 - 110  = 34

slippage_volume =  max( open_volume, 0 ) = max ( 10, 0 ) = 10


maintenance_margin_long = max(slippage_volume * slippage_per_unit, 0) + slippage_volume * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ] + buy_orders * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ]  

= max(10 * 34, 0) +  10 * 0.1 * 144 + 4 * 0.1 * 144 =  541.6

# Step 2

Since riskiest short == 0 then maintenance_margin_short = 0

# Step 3

maintenance_margin = max ( 541.6, 0) = 541.6

# Step 4

collateral_release_level = 541.6 * collateral_release_scaling_factor = 541.6 * 1.1
initial_margin = 541.6 * initial_margin_scaling_factor = 541.6 * 1.2
search_level = 541.6 * search_level_scaling_factor = 541.6 * 1.3



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



## SCENARIOS

Scenarios found [here](https://docs.google.com/spreadsheets/d/1VXMdpgyyA9jp0hoWcIQTUFrhOdtu-fak/edit#gid=1586131462)


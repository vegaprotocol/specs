# Margin Calculator

## Acceptance Criteria

- Get four margin levels for one or more parties (<a name="0019-MCAL-001" href="#0019-MCAL-001">0019-MCAL-001</a>)

- Margin levels are correctly calculated against riskiest long and short positions (<a name="0019-MCAL-002" href="#0019-MCAL-002">0019-MCAL-002</a>)

- Zero position and zero orders results in all zero margin levels (<a name="0019-MCAL-003" href="#0019-MCAL-003">0019-MCAL-003</a>)

- If `riskiest long > 0` and there are no bids on the order book, the `exit price` is equal to infinity and hence the slippage cap is used as the slippage component of the margin calculation. (<a name="0019-MCAL-014" href="#0019-MCAL-014">0019-MCAL-014</a>)

- If `riskiest long > 0 && 0 < *sum of volume of order book bids* < riskiest long`, the `exit price` is equal to infinity.  (<a name="0019-MCAL-015" href="#0019-MCAL-015">0019-MCAL-015</a>)

- If `riskiest short < 0 && 0 < *sum of absolute volume of order book offers* < abs(riskiest short)`, the `exit price` is equal to infinity. (<a name="0019-MCAL-016" href="#0019-MCAL-016">0019-MCAL-016</a>)

- If `riskiest long > 0 &&  riskiest long < *sum of volume of order book bids*`, the `exit price` is equal to the *volume weighted price of the order book bids* with cumulative volume equal to the riskiest long, starting from best bid.  (<a name="0019-MCAL-017" href="#0019-MCAL-017">0019-MCAL-017</a>)

- If `riskiest short < 0 && 0 abs(riskiest short) == *sum of absolute volume of order book offers* <`, the `exit price` is equal to the *volume weighted price of the order book offers*.  (<a name="0019-MCAL-018" href="#0019-MCAL-018">0019-MCAL-018</a>)

- A feature test that checks margin in case market PDP > 0 is created and passes. (<a name="0019-MCAL-008" href="#0019-MCAL-008">0019-MCAL-008</a>)

- For each market and each party which has either orders or positions on the market, the API provides the 4 margin levels.  (<a name="0019-MCAL-009" href="#0019-MCAL-009">0019-MCAL-009</a>)

- A feature test that checks margin in case market PDP < 0 is created and passes. (<a name="0019-MCAL-010" href="#0019-MCAL-010">0019-MCAL-010</a>)

- If a party is short `1` unit and the mark price is `15 900` and `market.maxSlippageFraction[1] = 0.25`, `market.maxSlippageFraction[2] = 0.25` and `RF short = 0.1` and order book is

    ```book
    buy 1 @ 15 000 
    buy 10 @ 14 900 
    and
    sell 1 @ 100 000
    sell 10 @ 100 100 
    ```

    then the maintenance margin for the party is `15 900 x (0.25 x 1 + 0.25 x 1 x 1) + 0.1 x 1 x 15 900 = 9 540`. (<a name="0019-MCAL-011" href="#0019-MCAL-011">0019-MCAL-011</a>)

- In the same situation as above, if `market.maxSlippageFraction[1] = 100`, `market.maxSlippageFraction[2] = 100` (i.e. 10 000% for both) instead, then the margin for the party is `84 100 + 0.1 x 1 x 15900 = 85 690`. (<a name="0019-MCAL-012" href="#0019-MCAL-012">0019-MCAL-012</a>)

- If the `market.maxSlippageFraction` is updated via governance then it will be used at the next margin evaluation i.e. at the first mark price update following the parameter update. (<a name="0019-MCAL-013" href="#0019-MCAL-013">0019-MCAL-013</a>)


## Summary

The *margin calculator* returns the set of margin levels for a given _actual position_, along with the amount of additional margin (if any) required to support the party's _potential position_ (i.e. active orders including any that are parked/untriggered/undeployed).


### Margining modes

The system can operate in one of two margining modes for each position.
The current mode will be stored alongside of party's position record.

1. **Cross-margin mode (default)**: this is the mode used by all newly created positions.
When in cross-margin mode, margin is dynamically acquired and released as a position is marked to market, allowing profitable positions to offset losing positions for higher capital efficiency (especially with e.g. pairs trades).

1. **Isolated margin mode**: this mode sacrifices capital efficiency for predictability and risk management by segregating positions.
In this mode, the entire margin for any newly opened position volume is transferred to the margin account when the trade is executed. 
This includes completely new positions and increases to position size.


### Actual position margin levels:

1. **Maintenance margin**: the minimum margin a party must have in their margin account to avoid the position being liquidated.

1. **Collateral search level**: when in cross-margin mode, the margin account balance below which the system will seek to recollateralise the margin account back to the initial margin level.

1. **Initial margin**: when in cross-margin mode, the margin account balance initially allocated for the position, and the balance to which the margin account will be returned after collateral search and release, if possible.

1. **Collateral release level**: when in cross-margin mode, the margin account balance above which the system will return collateral from a profitable position to the party's general account for potential use elsewhere.


It is always the case that:

```
maintenance margin < collateral search level < initial margin < collateral release level
```


### Potential position margin level:

1. **Order margin**: the amouht of additional margin on top of the amount in the margin account that is required for the party's current active orders.
Note that this may be zero if the active orders can only decrease the position size. 



Margin levels are used by the protocol to ascertain whether a trader has sufficient collateral to maintain a margined trade. When the trader enters an open position, this required amount is equal to the *initial margin*. Subsequently, throughout the life of this open position, the minimum required amount is the *maintenance margin*. As a trader's collateral level dips below the *collateral search level* the protocol will automatically search for more collateral to be assigned to support this open position from the trader's general collateral accounts. In the event that a trader has collateral that is above the *collateral release level* the protocol will automatically release collateral to a trader's general collateral account for the relevant asset.

**Whitepaper reference:** 6.1, section "Margin Calculation"

In future there can be multiple margin calculator implementations that would be configurable in the market framework. This spec describes one implementation.



## Isolated margin mode

When in isolated margin mode, the position on the market has an associated margin factor.
The margin factor must be greater than 0 and less than or equal to 1.

Isolated margin mode can be enabled by placing an _update margin mode_ transaction.
This transaction may be placed as a standalone transaction or may be included with an order.
The default when placing an order with no change to margin mode specifid must be to retain the current margin mode of the position.

When submitting, amending, or deleting an order in isolated margin mode, the worst case order margin for the current open orders must be calculated.
This is the largest amount of the extra margin required if all the party's bids or asks were to trade simultaneously at their limit price.

If the worst case order margin does not cover the initial margin for any additional volume then an order cannot be placed

TODO: margin factor must cover at least initial margin - is this correct, what happens when flipping a position? how do we accont for margin account balance as well as order margin balance? 

The balance of the order account must be made equal to this worst case margin amount by transferring to or from the general account.

In isolated margin mode when, trades occur that open a new position — including by flipping the direction of the position — or increase the absolute position size, the margin to add is calculated:

```math
margin to add = margin factor * VWAP of new trades * total size of new trades
```

This `margin to add` amount is transferred from the order margin account to the margin account.
NB: In implementation, for any volume that trades immediately on entry, the additional margin may be transferred directly from the general account to the margin account.

TODO: when reducing a position's size, how much margin to return to general




### Setting margin mode



When isolated margin mode is enabled,  amount to be transferred is a fraction of the position's notional size that must be specified by the user when enabling isolated margin mode.



## Reference Level Explanation

The calculator takes as inputs:

- position record = [`open_volume`, `buy_orders`, `sell_orders`] where `open_volume` refers to size of open position (`+ve` is long, `-ve` is short), `buy_orders` / `sell_orders` refer to size of all orders on the buy / sell side (`+ve` is long, `-ve` is short). See [positions core specification](./0006-POSI-positions_core.md).
- `mark price`
- `scaling levels` defined in the risk parameters for a market
- `quantitative risk factors`
- `market.maxSlippageFactors` which is a 2 dimensional decimal optional market creation parameter with a default of `[0.1,0.1]` i.e. `[10%,10%]` with the following validation: `0 <= market.maxSlippageFactors[1] <= 1 000 000` and `0 <= market.maxSlippageFactors[2] <= 1 000 000`.

Note: `open_volume` may be fractional, depending on the `Position Decimal Places` specified in the [Market Framework](./0001-MKTF-market_framework.md). If this is the case, it may also be that order/positions sizes and open volume are stored as integers (i.e. int64). In this case, **care must be taken** to ensure that the actual fractional sizes are used when calculating margins. For example, if Position Decimals Places (PDP) = 3, then an open volume of 12345 is actually 12.345 (`12345 / 10^3`). This is important to avoid margins being off by orders of magnitude. It is notable because outside of margin calculations, and display to end users, the integer values can generally be used as-is.
Note also that if PDP is negative e.g. PDP = -2 then an integer open volume of 12345  is actually 1234500.

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

The protocol calculates the margin requirements for the `riskiest long` and `riskiest short` positions.

`riskiest long` = max( `open_volume` + `buy_orders` , 0 )

`riskiest short` = min( `open_volume` + `sell_orders`, 0 )

## Limit order book linearised calculation

In this simple methodology, a linearised margin formula is used to return the margin requirement levels, using risk factors returned by the [quantitative model](./0018-RSKM-quant_risk_models.ipynb).

### **Step 1**

If `riskiest long == 0` then `maintenance_margin_long = 0`.

In this simple methodology, a linearised margin formula is used to return the maintenance margin, using risk factors returned by the [quantitative model](./0018-RSKM-quant_risk_models.ipynb).

with

```formula
maintenance_margin_long 
    = max(min(riskiest_long * slippage_per_unit, product.value(market_observable)  * (riskiest_long * market.maxSlippageFraction[1] + riskiest_long^2 * market.maxSlippageFraction[2])), 0) 
    +  max(open_volume, 0) * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ] + buy_orders * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ]`,
```

where

`slippage_volume =  max( open_volume, 0 )`,

and

if `open_volume > 0` then

`slippage_per_unit = max(0, Product.value(market_observable) - Product.value(exit_price))`,

else `slippage_per_unit = 0`.

where

`market_observable` = `settlement_mark_price` if in continuous trading, refer to [auction subsection](#margin-calculation-for-auctions) for details of the auction behaviour.

`settlement_mark_price` refers to the mark price most recently utilised in [mark to market settlement](./0003-MTMK-mark_to_market_settlement.md). If no previous mark to market settlement has occurred, the initial mark price, as defined by a market parameter, should be used.

`exit_price` is the price that would be achieved on the order book if the trader's position size on market were exited. Specifically:

- **Long positions** are exited by the system considering what the volume weighted price of **selling** the size of the open long position (not riskiest long position) on the order book (i.e. by selling to the bids on the order book). If there is no open long position, the slippage per unit is zero.

- **Short positions** are exited by the system considering what the volume weighted price of **buying** the size of the open short position (not riskiest short position) on the order book (i.e. by buying from the offers (asks) on the order book). If there is no open short position, the slippage per unit is zero.

If there is zero or insufficient order book volume on the relevant side of the order book to calculate the `exit_price`, then take `slippage_per_unit = +Infinity` which means that `min(slippage_volume * slippage_per_unit, mark_price * (slippage_volume * market.maxSlippageFraction[1] + slippage_volume^2 * market.maxSlippageFraction[2])) = mark_price * (slippage_volume * market.maxSlippageFraction[1] + slippage_volume^2 * market.maxSlippageFraction[2])` above.  

### **Step 2**

If `riskiest short == 0` then `maintenance_margin_short = 0`.

Else

```formula
maintenance_margin_short 
    = max(min(abs(riskiest short) * slippage_per_unit, mark_price * (abs(riskiest short) *  market.maxSlippageFraction[1] + abs(slippage_volume)^2 * market.maxSlippageFraction[2])),  0) 
    + abs(min( open_volume, 0 )) * [ quantitative_model.risk_factors_short ] . [ Product.value(market_observable) ] + abs(sell_orders) * [ quantitative_model.risk_factors_short ] . [ Product.value(market_observable) ]`
```

where meanings of terms in Step 1 apply except for:

`slippage_volume = min( open_volume, 0 )`,

`slippage_per_unit = max(0, Product.value(exit_price)-Product.value(market_observable))`

### **Step 3**

`maintenance_margin = max ( maintenance_margin_long, maintenance_margin_short)`

## Margin calculation for auctions

We are assuming that:

- mark price never changes during an auction, so it's the last mark price from before auction,
- during an auction we never release money from the margin account, however we top-it-up as required,
- no closeouts during auctions

Use the same calculation as above with the following re-defined:

- For the orders part of the margin: use `market_observable` =  volume weighted average price of the party's long / short orders.

Note that because the order book is empty during auctions we will always end up with the slippage value implied by the the slippage cap.

## Scaling other margin levels

### **Step 4**

The other three margin levels are scaled relative to the maintenance margin level, using scaling levels defined in the risk parameters for a market.

`search_level = margin_maintenance * search_level_scaling_factor`

`initial_margin = margin_maintenance * initial_margin_scaling_factor`

`collateral_release_level = margin_maintenance * collateral_release_scaling_factor`

where the scaling factors are set as risk parameters ( see [market framework](./0001-MKTF-market_framework.md) ).

## Positive and Negative numbers

Positive margin numbers represent a liability for a trader. Therefore, if comparing two margin numbers, the greatest liability (i.e. 'worst' margin number for the trader) is the most positive number. All margin levels returned are positive numbers.

## Pseudo-code / Examples

### EXAMPLE 1 - full worked example

```go
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

market.maxSlippageFraction[1] = 0.25
market.maxSlippageFraction[2] = 0.001

risk_factor_short = 0.11
risk_factor_long = 0.1

mark_price = $144

search_level_scaling_factor = 1.1
initial_margin_scaling_factor = 1.2
collateral_release_scaling_factor = 1.3

Trader1_futures_position = {open_volume: 10, buys: 4,  sells: 8}

getMargins(Trader1_position)

riskiest_long  = max( open_volume + buy_orders, 0 ) = max( 10 + 4, 0 ) = 14
riskiest_short = min( open_volume + sell_orders, 0 ) =  min( 10 - 8, 0 ) = 0

# Step 1

## exit price considers what selling the open position (10) on the order book would achieve.

slippage_per_unit =  max(0, Product.value(previous_mark_price) - Product.value(exit_price)) = max(0, Product.value($144) - Product.value((1*120 + 4*110 + 5*108)/10)) = max(0, 144 - 110)  = 34


maintenance_margin_long =max(min(riskiest_long * slippage_per_unit, product.value(market_observable)  * (riskiest_long * market.maxSlippageFraction[1] + riskiest_long^2 * market.maxSlippageFraction[2])), 0) 
 + max(open_volume, 0 ) * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ] + buy_orders * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ]


=  max(min(14 * 34, 144*(14 * 0.25 + 14 * 14 * 0.001), 0) + 10 * 0.1 * 144 + 4 * 0.1 * 144 = max(min(476, 532.224), 0) + 10 * 0.1 * 144 + 4 * 0.1 * 144 = 677.6

# Step 2

Since riskiest short == 0 then maintenance_margin_short = 0

# Step 3

maintenance_margin = max ( 677.6, 0) = 677.6

# Step 4

collateral_release_level = 677.6 * collateral_release_scaling_factor = 677.6 * 1.1
initial_margin = 677.6 * initial_margin_scaling_factor = 677.6 * 1.2
search_level = 677.6 * search_level_scaling_factor = 677.6 * 1.3

```

### EXAMPLE 2 - calculating correct slippage volume

Given the following trader positions:

| Tables        | Open           | Buys  | Sells |
| ------------- |:-------------:| -----:| -----:|
| case-1      | 1 | 1 | -2
| case-2      | -1 | 2| 0
| case-3 | 1 | 0 | -2

#### *case-1*

riskiest long: 2

riskiest short: -1

#### *case-2*

riskiest long: 1

riskiest short: -1

#### *case-3*

riskiest long: 1

riskiest short: -1

## SCENARIOS

Scenarios found [here](https://docs.google.com/spreadsheets/d/1VXMdpgyyA9jp0hoWcIQTUFrhOdtu-fak/edit#gid=1586131462)

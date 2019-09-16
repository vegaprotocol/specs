Feature name: margin-calculator
Start date: YYYY-MM-DD
Whitepaper section: 6.1, section "Margin Calculation"

The _margin calculator_ returns the set of relevant margin levels for a trader:
1. Maintenance margin
1. Collateral search level
1. Initial margin
1. Collateral release level



## Simple calculation for limit order book

In this simple methodology, a linearised margin formula is used to return the maintenance margin, using risk factors returned by the [quantitative model](./0018-quant-calculator.md).

The maintenance margin is calculated using the following formula:

```margin_maintenance = close-out-pnl + position_size * [ quantitative_model.risk_factors ] . [ Product.market_observables ] ```

where 

```close-out-pnl = position_size * (Product.value(closeout_price) - Product.value(current_price)) ```

where ```closeout_price``` is the price that would be achieved on the order book if the trader's position were exited.   Note, if there is insufficient order book volume for this ```closeout_price``` to be calculated for an individual trader, the ```closeout_price``` is the price that would be achieved for as much of the volume that could theoretically be closed (in general we expect market protection mechanisms make this unlikely to occur).

We will use the notation
X(t) := (a(t); b(t)) := (a<sub>1</sub>(t), . . . , a<sub>K</sub>(t); b<sub>1</sub>(t)(t), . . . , b<sub>K</sub>(t)) , where a := (a<sub>1</sub>, . . . , a<sub>K</sub>) designates the ask side of the order book and ai the number of contracts available i ticks away from the best opposite quote, and b := (b<sub>1</sub>, . . . , b<sub>K</sub>) designates the bid side of the book.

Definition. The depth profile at price p and at time t, denoted n(p, t), is the density of the total volume of
the asset being traded that is offered via limit orders at price p and at time t.

Definition. The quantity available at price p and at time t, denoted N(p, t), is the amount available in the
limit order book L(t) at price p. Hence, N(p, t) = n(p, t)dp.
We adopt the convention that the depth profile (and quantity available) is negative for buy orders and
positive for sell orders.

Definition. The minimum order size, denoted σ, is the smallest quantity of the asset that can be traded. All
orders must be for sizes that are integer multiples of σ – i.e., ω ∈ {kσ| k ∈ Z} (where k is negative for buy
orders).

Definition. The bid price at time t, denoted b(t), is equal to the highest stated price among “buy” limit
orders in the limit order book L(t).

Definition. The ask price at time t, denoted a(t), is equal to the lowest stated price among “sell” limit
orders in the limit order book L(t).

In a limit order market, b(t) is precisely the highest price at which it is possible to sell a quantity of at least
σ of the asset being traded, and a(t) is precisely the lowest price at which it is possible to buy a quantity of
at least σ of the asset being traded, at time t







Specifically, if position_size < 0 (short position), 

```closeout_price = Sum(price(i) * volume(i) ```




## Scaling other margin levels

The other three margin levels are scaled relative to the maintenance margin level, using scaling levels defined in the risk parameters for a market.

```search_level = margin_maintenance * search_level_scaling_factor```

```initial_margin = margin_maintenance * initial_margin_scaling_factor```

```collateral_release_level = margin_maintenance * collateral_release_scaling_factor```

where the scaling factors are set as risk parameters ( see [market framework](./0001-market-framework.md) ).


## Positive and Negative numbers

Positive margin numbers represent a liability for a trader. Therefore, if comparing two margin numbers, the greatest liability (i.e. 'worst' margin number for the trader) is the most positive number.
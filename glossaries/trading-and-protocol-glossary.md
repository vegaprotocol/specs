# Trading and protocol glossary

## A

### Average Entry Price

This is the **volume weighted price** of a trader's [Open Volume](#open-volume).  The open volume will always be comprised of all buys or all sells.

**Example 1 - all buys:**

A trader has 3 price levels at which their open volume was purchased:

1. Long 3 contracts @ $100
1. Long 2 contracts @ $80
1. Long 5 contracts @ $150

**Average Entry Price** = `(3 * $100 + 2 * $80 + 5 * $150)/(3 + 2 + 5) = ($300 + $160 + $750) / 10 = $121`

**Example 2 - all sells:**

A trader has 3 price levels at which their open volume was sold:

1. Short -3 contracts @ $100
1. Short -2 contracts @ $80
1. Short -5 contracts @ $150

Note, with position management we treat the volume of sells as negative for calculation purposes (not necessarily display purposes to users). Note, that in this calculation however, the negatives cancel each other out.

**Average Entry Price** = `(-3 * $100 + -2 * $80 + -5 * $150)/(-3 - 2 - 5) = (-$300 - $160 - $750) / -10 = $121`

The Average Entry Price is useful when calculating [Unrealised P&L](#unrealised-pnl) or [Realised P&L](#realised-pnl)

## B

### Base currency

The currency used for settlement and margining.

## C

### Creation period

During the creation an instrument, the length of time that the proposing participant must commit their stake.

### Close out threshold

The amount of margin that a trader must maintain in collateral in order to keep their positions open.  Below this threshold, their open positions will be closed out in the market.

### Close out trades

When a trader's collateral level in the risk universe drops below the [close out threshold](#close-out-threshold), their positions in that risk universe are closed out in the market by Vega.

### Closed position

The set of long and short contracts with price and volume specified that are matched as offset volume during the [FIFO](#fifo-first-in-first-out) netting process.

### Closed volume

The volume that is matched into [closed volume](#closed-volume) during the [FIFO](#fifo-first-in-first-out) netting process.  It is measured as the sum of the buys of the matched volume.  So, if 2 long (or +2) contracts are netted with 2 short (or -2) contracts, the **Closed Volume** = 2.

The profit or loss that a trader locks in when they close volume is called the [Realised P&L](#realised-pnl) and is not affected by future price moves in the instrument.

## D

### Delegation

See: [Staking](#staking).

## E

### ENE - Execute and Eliminate

Any order that trades any amount and as much as possible but does not remain on the book (whether it trades or not)

## F

### Fees

Fees are incurred on trades in Vega. There are three categories of fee, each of which is paid out to different participants:

- Infrastructure fee: paid to [validators](#validators),
- Maker fee: paid to the price maker,
- Liquidity fee: paid to [Liquidity Providers](#liquidity-providers)

See [the fees specification](../protocol/0029-FEES-fees.md) for more detail.

### FIFO (First In, First Out)

A matching methodology which prioritises older volume as an offset when counter volume is added to the ledger.  The ledger may be a market order book (used for matching orders into trades), or a record of an individual trader's trades (used for calculating their open and closed positions).

Use Case 2 - Calculating a trader's open and closed position.

**Example - FIFO on an individual trader's trades:**

1. 24-July-07:00 Buy 3 contracts @ $100
1. 24-July-07:10 Sell 1 contract @ $400
1. 24-July-07:14 Sell 6 contracts @ $370
1. 24-July-07:15 Buy 2 contracts @ $80
1. 24-July-07:46 Buy 5 contracts @ $150
1. 24-July-09:00 Sell 2 contracts @ $300
1. 24-July-10:10 Sell 2 contract @ $ 320
1. 24-July-10:10 Sell 3 contract @ $ 379

**Fifo matching - calculating [closed position](#open-position)s**:

- -1 contract @ $400
- +1 contract @ $100
- -2 contract @ $370
- +2 contract @ $100
- +2 contract @ $80
- -2 contract @ $370
- +2 contract @ $150
- -2 contract @ $370
- -2 contract @ $300
- +2 contract @ $150
- -1 contract @ $320
- +1 contract @ $150

The above represent the [closed position](#closed-position) which can be inputted into the [Realised P&L](#realised-pnl) calculation to determine how profitable these trades were.  The [closed volume](#closed-volume) is considered to be 9 (offset) contracts.

**Fifo matching - remainder [open position](#open-position)**:

The remainder (unmatched) positions are comprised of:

- -1 contract @ $320
- -3 contract @ $379

The above represent the [open position](#open-position) which can be inputted into the [Unrealised P&L](#unrealised-pnl) and the [Average Entry Price](#average-entry-price) calculations.

The [open volume](#open-volume) in this example is net short 4 contracts.

### Fills

Fill is the term used to refer to the satisfying of an order to trade a financial asset. It is the basic act of any market transaction – when an order has been completed, it is often referred to as ‘filled’ or as the order having been executed. However, it is worth noting that there is no guarantee that every trade will become filled.

[IG Index: Fill Definition](https://www.ig.com/uk/glossary-trading-terms/fill-definition)

### FOK - Fill or kill

An order that either trades completely until the remaining size is 0, or not at all, and does not remain on the book if it doesn't trade

### FOREX - FX

The market in which currencies are traded. The largest and most liquid market.

## G

### Governance Asset

A running Vega network will have an asset specified as the Governance Asset. This can be any asset that has been proposed and accepted through governance. See the [governance spec](../protocol/0028-GOVE-governance.md) for more detail.

### GTC - Good 'til close

An order that trades any amount and as much as possible and remains on the book until it either trades completely or is cancelled

### GTT - Good 'til time

An order that trades any amount and as much as possible and remains on the book until they either trade completely, are cancelled, or expires at a set time

## I

### Instrument

An instance of a **smart product** that can be traded on Vega network with all parameters required for settlement and / or margin requirements specified.

Parameters:

- Name:  Example: `BTCUSD` Dec 2018 Future.
- Underlying
- Base currency
- Tick size
- Expiry
- Payoff / settlement formula
- Minimum contract size

### Insurance Pool

A store of capital instantiated with the order book into which fines are contributed.  It is utilised for financially covering [close out trades](#close-out-trades).

## L

### Liable position

The net riskiest composition of a trader's open positions and live orders.  For example if a trader holds +10 contracts and has buy orders of +10 and sell orders of +10, the liable position would be +20 contracts for margin calculation purposes.

### Liquidity Providers

Liquidity providers commit a bond which specifies their SLA obligations. In return for meeting these the liquidity providers earn a portion of the trading [fees](#fees) from the market in which they operate. See [the liquidity provision spec](./../protocol/0044-LIME-lp_mechanics.md) for more detail.

## M

### Margin

The amount of collateral (due in the base currency of the product) that a trader must deposit to maintain their position. This will be an amount greater than the [minimum risk margin](#minimum-risk-margin)

### Mark Price

An instrument's market valuation at any point in time.  This will be set to the higher / lower of the:

- last traded price;
- bid / offer

### Mark to Market

Another name for the [unrealised profit and loss](#unrealised-pnl)

### Market

An instrument that is trading on the Vega network may be called a market.

### Market Depth (Depth of Market)

Market Depth is a measure of the number of open buy and sell orders for a market at different prices. The depth measure provides an indication of the liquidity.

### Minimum Risk Margin

The margin amount that is calculated by the [Risk Model](#risk-model) as the minimum amount of collateral (in the base currency of the product) that a trader must hold.  Below this level, the position is considered to be unsafe for the Vega system.

Traders will be required to provide a margin amount greater than the Minimum Risk Margin, called the [Margin](#margin).

### Minimum Stake

The minimum amount of collateral required to launch trading on an instrument.

### Minimum Stake Lockup Period

The minimum stake lockup period is the minimum time that market maker collateral is required to be locked up.

## N

### Net Position

This describes an implementation methodology for calculating positions and P&L for an individual trader.  Refer to Trading and Protocol Glossary for definitions of unspecified terms.

Assume an individual has a set of trades which they have executed on one market.

Calculate:

1. Open Volume Sign:  If sum of the long volume > sum of the short volume, trader's open position is net long (and vice versa).

1. Closed Volume Amount:  If Open Volume Sign > 0, the **Closed Volume Amount** is the sum of the short volume of the trades (and vice versa).

1. Closed Long Contracts - **the first n volume**, where n is the **Closed Volume Amount** (note this methodology is a shortcut way to implementing FIFO at any point in time).

1. Closed Short Contracts - **the first n volume**, where n is the **Closed Volume Amount** (note this methodology is a shortcut way to implementing FIFO at any point in time).

1. Open Contracts - whatever is left of the volume that isn't in **Closed Long Contracts** or **Closed Short Contracts**.  These will always be either long contracts OR short contracts but never both (else they'd have been matched off).  Contracts specify a price level and a volume.  They are not trades, as they may be residual volume from a trade that has been partially matched.

- **Realised Volume** is the **Closed Volume Amount**

- **Realised PnL** = **Closed Volume Amount** * (**Average Entry Price** (of Closed Short Contracts)  - [Average Entry Price](#average-entry-price) (of Closed Long Contracts))

- **Unrealised Volume** is the sum of the volume of all the **Open Contracts**

- **Unrealised PnL** = **Unrealised Volume** * (**Mark Price** - **Average Entry Price**(of Open Contracts))

### Notional Value

The multiplication of a contract's volume by market price.  This may be used in various contexts - i.e. across the whole market or for an individual trader.  A typical application is for a trade, to multiply the [trade volume](#trade-volume) by the [trade entry price](#trade-entry-price) to give the notional value of that trade. It is common to report a market's total daily notional volume which is simply the addition of all the notional volume for all trades that have transacted in a market on a given day.

## O

### Open Interest

Reported for a market / instrument, this is the sum of [Open Volume](#open-volume) of all long positions open on that [instrument](#instrument) at any point in time.

Example (assume zero trading in the market so far):

1. Candida buys 4 contracts from David.  The Open Interest is 4.
1. Candida then sells her 4 contracts back to David.  The Open Interest is 0.
1. Rather than selling back to David, Candida sells to Chris.  The Open Interest is 4.

### Open position

The set of long OR short contracts with price and volume specified that are NOT matched as offset volume during the [FIFO](#fifo-first-in-first-out) netting process.  They are the residual contracts that have exposure to the market price changes and require margin to be deposited.

### Open Volume

This the total volume of long OR short [open position](#open-position).

Example, if an individual trader's [open position](#open-position) on an instrument is:

- +1 @ $100
- +4 @ 109

The **Open Volume** = 1 + 4 = 5 contracts

The exposure that a trader has on their Open Volume to the market's price moves is called the [unrealised P&L](#unrealised-pnl)

### Open Value

[Open interest](#open-interest) x [mark price](#mark-price)

```math
Open interest: 100 orders for 1
Mark price: Last trade was at 5
Open Value: 500
```

### Open Risk Value

The risk value of the total open interest for an instrument calculated by the risk engine which takes into account the volatility of the instrument and calculates the worst expected move over a specified period of time (the time period used to calculate this is a network parameter).

### Oracle Feed

A definite source of price information for an underlying (could come from another instrument's market activity (e.g. trading or prices) on the Vega network, or from an external source).

### Order Book

The collection of live, open bids and offers for an instrument.

## P

### Party

An entity that is trading on the VEGA network.  Each order has one party who submits the order.  Each trade has two parties - a buyer and a seller.  Note that the buyer and the seller may be the same entity (unless we choose to design it otherwise).

### Pegged order

Pegged orders are limit orders where the price is specified of the form `REFERENCE +/- OFFSET`, therefore 'pegged' is a _price type_, and can be used for any limit order that is valid during continuous trading.

A pegged order's price is calculated from the value of the reference price on entry to the order book. Pegged orders that are persistent will be repriced, losing time priority, _after processing any event_ which causes the `REFERENCE` price to change.

### Position resolution

The methodology by which distressed trades are unwound through deleveraging market positions.

### Proposal period

For the creation an instrument, the time between the initial proposal period and the successful vote for the instrument.  This is a network parameter that will default to 5 days.

## R

### Realised PnL

The **Realised PnL** calculates the profitability that has been locked in by a trader who exits an existing [open position](#open-position).
The inputs to a **Realised PnL** calculation is the set of positions, including specification of volume and price, that are the result of matched volume, calculated by [FIFO](#fifo-first-in-first-out).

Example:

A trader's closed position is comprised of the following:

1. +3 contracts @ $100
1. +2 contracts @ $80
1. +5 contracts @ $150
1. -1 contract @ $400
1. -6 contracts @ $370
1. -2 contracts @ $300
1. -1 contract @ $ 320

Note, for closed positions, the number of longs and number of shorts should equal each other (in this case we are 10 long and 10 short).  Short positions are represented by `-ve` numbers for volume.

**Realised PnL** = `Total Volume * (Average Entry Price (sells) - Average Entry Price (buys))
=  10 ( (-1 * $400 + -6 * $370 + -2 * $300 + -1 * $320 )/-10  - (3 * $100 + $2 * 80 + 5 * $150)/10 )
= 10 ($354 - $121) = $2330`

### Risk Engine

The part of the code base that deals with all the logic surrounding margin calculations, close out trades and collateral searches.  The Risk Engine will be triggered every x seconds.

### Risk Model

The part of the code base that calculates a pair of risk factors - one for a short position, one for a long position that will be combined to calculate the total [Minimum Risk Margin](#minimum-risk-margin)

### Risk Universe

A collection of one or more order books on the same underlying which are able to offset each other for margining purposes.
For example, for Futures the risk universe will typically consist of one order book only.
For European Options, the risk universe will be all the order books for one underlying and one exercise date across a range of strikes.
Importantly, each risk universe specifies the risk model, acceptable collateral
and the oracle for underlying.  Instruments within a risk universe must belong to the same Market.

## S

### Slippage

This is when the there is difference between the price of a trade and the price at which the trade is actually executed. For example, Jim puts an order for 10 BTC @ market price, but in the time the order is on the books the market price goes up to $5100 and Jim actually ends up trading at this price. Slippage refers to this difference in price. This works both positively and negatively.

### Smart Product Language

A language for creating smart financial products on Vega.

### Smart Product

A financial agreement which involves transfer of value (in digital currency) between two counterparts at a specified time, according to specified conditions which must be specified digitally. Example: Future, European Options, CFD

### Staking

Staking is the act of committing a governance asset balance to a validator node in order to earn a portion of the [infrastructure fee](#fees).

Staking and delegation are used relatively interchangeably as in Vega, staking has the same meaning as self-delegation.

## T

### Trade Volume

The number of contracts multiplied by the size of each contract for each market.  For example, the market may have a contract size of $1USD and one trade may be for 10 contracts.  The _trade volume_ then equals $1 x 10 = $10.

### Trade Entry Price

The quote price which a buyer and seller are matched at.

## U

### Unrealised PnL

The **Unrealised PnL** calculates the profitability that a trader would receive if they were able to close their open positions at the current market price, as measured by the [mark price](#mark-price).  It is sometimes referred to as [mark to market](#mark-to-market).  It helps traders to understand what the 'value' of their portfolio is. Also they are required to cover any unrealised losses in their margin requirements.

The inputs to a **Unrealised PnL** calculation is the set of trades (or partial trades) which specify volume and price, that are the result of unmatched volume, calculated by [FIFO](#fifo-first-in-first-out). This will always be either all buys or all sells.

**Example 1 (trader has a net long open position):**

A trader's open volume is comprised of the following:

1. +3 contracts @ $100
1. +2 contracts @ $80
1. +5 contracts @ $150

Let's assume the latest [mark price](#mark-price) is set by the last trade in this market at $120.

**Unrealised PnL** = `Total Volume * ([mark price](#mark-price) - [average entry price](#average-entry-price))
=  10 ( $120 - (3 * $100 + $2 * 80 + 5 * $150)/Abs(10) )
= 10 ($120 - $121) = - $10`

The trader has made a loss of -$10 across their trades.  However, this isn't locked in (realised) and the market may still move back in their favour.

**Example 2 (trader has a net short open position):**

A trader's open volume is comprised of the following:

1. -1 contract @ $750
1. -6 contracts @ $330
1. -2 contracts @ $999

Let's assume the latest [mark price](#mark-price) is set by the last trade in this market at $666.

_Unrealised PnL_ = `Total Volume * ([mark price](#mark-price) - [average entry price](#average-entry-price))
=  -9 * ( $666 - (-1 * $750 + -6 * $330 + -2 * $999)/-9 )
= -9 * ($666 - $525.33) = - $140.67`

The trader has made a loss of -$140.67 across their trades.  However, this isn't locked in (realised) and the market may still move back in their favour.

## V

### Validators

Validators are the nodes that run Vega and participate in the creation of the blocks. See [the distributed ledger glossary](distributed-ledger-glossary.md#validators) for more information on validators.

### Vega time

Vega time is the current time of the chain (decided through consensus); it's based on the timestamp* agreed by the nodes.
Vega needs validators to have a share idea of what time it is, regardless of their location or their clock being incorrect.
Vega time is determined in Tendermint: ["Tendermint provides a deterministic, Byzantine fault-tolerant, source of time. Time in Tendermint is defined with the Time field of the block header."](https://docs.tendermint.com/master/spec/consensus/bft-time.html)

*The timestamp is an integer that represents the number of seconds elapsed since January 1st 1970 (UTC).

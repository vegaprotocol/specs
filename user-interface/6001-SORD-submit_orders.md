# Submit order
As a user I want change my exposure on a market (e.g. open a position, increase or decrease my open volume), I want to submit an order with instructions for how my order should be executed so I have some control over the price that I get, as well as if when/my order should stay on the book. See [specs about orders](../protocol#orders) for more info.

When populating a deal ticket I...

- **must** see/select the [Market](./7001-DATA-data_display.md#market) I am submitting the order for <a name="6001-SORD-001" href="#6001-SORD-001">6001-SORD-001</a>
  - **must** see the current market trading mode (Continuous, Auction etc) <a name="6001-SORD-002" href="#6001-SORD-002">6001-SORD-002</a>

- If I have a 0 total balance of the settlement asset: **must** be warned that I have insufficient collateral (but also allow you to populate ticket because I might want to try before I deposit) <a name="6001-SORD-003" href="#6001-SORD-003">6001-SORD-003</a>
  - **should** see a link to deposit the required collateral <a name="6001-SORD-050" href="#6001-SORD-050">6001-SORD-050</a>

- **must** select a side/direction e.g. long/short (note: some implementations may do this with two different submit buttons long/short rather than a toggle) <a name="6001-SORD-004" href="#6001-SORD-004">6001-SORD-004</a>

- **must** be able to select the [order type](../protocol/0014-ORDT-order_types.md) that I wish to submit <a name="6001-SORD-005" href="#6001-SORD-005">6001-SORD-005</a>
  - **must** see limit order <a name="6001-SORD-006" href="#6001-SORD-006">6001-SORD-006</a>
  - **must** see market order <a name="6001-SORD-007" href="#6001-SORD-007">6001-SORD-007</a>
  - **should** see pegged order <!-- <a name="6001-SORD-008" href="#6001-SORD-008">6001-SORD-008</a> -->
  - **should** see liquidity provision <!-- <a name="6001-SORD-009" href="#6001-SORD-009">6001-SORD-009</a> -->

## Order size

...need to select a size, when selecting a size for my order, I...

- **must** input an order [size](7001-DATA-data_display.md#size) (aka amount or contracts) <a name="6001-SORD-010" href="#6001-SORD-010">6001-SORD-010</a>
  - **should** have the previous value for the selected market pre-populated (last submitted or last changed) <a name="6001-SORD-012" href="#6001-SORD-012">6001-SORD-012</a>
  - **should** be able to hit up/down on the keyboard to increase the size by the market's min-contract size <a name="6001-SORD-013" href="#6001-SORD-013">6001-SORD-013</a>
    - **should** be able to use modifier keys (SHIFT, ALT etc) to increase/decrease in larger increments with arrows <a name="6001-SORD-054" href="#6001-SORD-054">6001-SORD-054</a>
    - **would like to** be able to enter a number followed be "k" or "m" or "e2" etc. to make it thousands or millions or hundreds, etc. <a name="6001-SORD-056" href="#6001-SORD-056">6001-SORD-056</a>
  - TODO **would** like to be able to use use a leverage slider to determine a size based on how much leverage I wish to use (given general balance, price input/current price) <!-- <a name="6001-SORD-015" href="#6001-SORD-015">6001-SORD-015</a> -->
- **must** be warned (pre-submit) if input has too many decimal places for the market's ["position" decimal places](7001-DATA-data_display.md#size) <a name="6001-SORD-016" href="#6001-SORD-016">6001-SORD-016</a> 

... so I get the size of exposure (open volume that I want)

## Price - Limit order

... if wanting to place a limit on the price that I trade at, I...

- **must** enter a [price](7001-DATA-data_display.md#quote-price). <a name="6001-SORD-017" href="#6001-SORD-017">6001-SORD-017</a> 
- **must** see the price unit (as defined in market) <a name="6001-SORD-018" href="#6001-SORD-018">6001-SORD-018</a>
  - **should** be able quickly pre-populate the price with the current mark price (if there is one, 0 if not) e.g. by focusing the input and hitting up/down <a name="6001-SORD-011" href="#6001-SORD-011">6001-SORD-011</a>
  - **should** have the previous value for the selected market pre-populated (last submitted or last changed) <a name="6001-SORD-014" href="#6001-SORD-014">6001-SORD-014</a>
  - **should** be able to hit up/down on the keyboard to increase the price by the market's tick size (if set, or smallest increment) <a name="6001-SORD-051" href="#6001-SORD-051">6001-SORD-051</a>
    - **should** be able to use modifier keys (SHIFT, ALT etc) to increase/decrease in larger increments with arrows <a name="6001-SORD-055" href="#6001-SORD-055">6001-SORD-055</a>
    - **would like to** be able to enter a number followed be "k" or "m" or "e2" etc. to make it thousands or millions or hundreds, etc. <a name="6001-SORD-057" href="#6001-SORD-057">6001-SORD-057</a>

... so that my order only trades at up/down to a particular price

## Market order

... if wanting to trade regardless of price (or assuming that the market is liquid enough that the current best prices are enough of an indication of the price I'll get)...

- **must not** see a price input <a name="6001-SORD-019" href="#6001-SORD-019">6001-SORD-019</a>
- **should** be warning if the market is in auction and the market order may be rejected <a name="6001-SORD-052" href="#6001-SORD-052">6001-SORD-052</a>

... so I cen quickly submit an order without populating the ticket with elements I don't care about

## Pegged

... submit an order where the price is offset from a price in system (best bid etc)

- TODO

... so my order will move with the market

## Time in force

... should to select a time in force, when selecting a time in force, I...

- **must** select a time in force
  - Good till canceled `GTC` - not applicable to Market orders <a name="6001-SORD-023" href="#6001-SORD-023">6001-SORD-023</a>
  - Good till time `GTT` - not applicable to Market orders <a name="6001-SORD-024" href="#6001-SORD-024">6001-SORD-024</a>
  - Fill or kill `FOK` <a name="6001-SORD-025" href="#6001-SORD-025">6001-SORD-025</a>
  - Immediate or cancel `IOC` <a name="6001-SORD-026" href="#6001-SORD-026">6001-SORD-026</a>
  - Good for normal trading only `GFN` - not applicable to Market orders <a name="6001-SORD-027" href="#6001-SORD-027">6001-SORD-027</a>
  - Good for auction only `GFA` - not applicable to Market orders <a name="6001-SORD-028" href="#6001-SORD-028">6001-SORD-028</a>
- **should** only be warned if the time in force is not applicable to the order type I have selected <a name="6001-SORD-029" href="#6001-SORD-029">6001-SORD-029</a>
- **should** only be warned if the time in force is not applicable to current period's trading mode <a name="6001-SORD-058" href="#6001-SORD-058">6001-SORD-058</a>
- if the user has not set a preference: market orders **should** default to `IOC` <a name="6001-SORD-030" href="#6001-SORD-030">6001-SORD-030</a>
- if the user has not set a preference: limit orders **should** default to `GTC` <a name="6001-SORD-031" href="#6001-SORD-031">6001-SORD-031</a>

... so I can control if and how my order stays on the order book

## Auto Populating a deal ticket non-manual methods

- TODO Populate by selecting a size/price in the order book
- TODO Populate by selecting a size/price in the chart
- TODO Populate by selecting a size/price in the depth chart
- TODO Input price as a % of account, given the current price field

## See the potential consequences of an order before it is submit
... based on the current inputs I'd like an indication of the consequences of my order based on my position and the state of the market, I...

- **could** see my resulting open volume <a name="6001-SORD-032" href="#6001-SORD-032">6001-SORD-032</a>
- **could** see the amount this order might move the market in percentage terms
- **could** see what the new best prices of the market would be after placing this order (assuming my order moves the market)
- **could** see new volume weighted average entry price if not 0<a name="6001-SORD-033" href="#6001-SORD-033">6001-SORD-033</a>
- **could** see and indication the volume weighted price that this particular order 
- **could** see an indication of how much of the order will trade when it hits the book and how much might remain passive
- **could** see a new liquidation level <a name="6001-SORD-034" href="#6001-SORD-034">6001-SORD-034</a>
- **could** see an estimate of the fees that will be paid (if any) <a name="6001-SORD-035" href="#6001-SORD-035">6001-SORD-035</a>
- **could** see my "position leverage" TODO - define this
- **could** see my "account leverage" TODO - define this 
- **could** see an amount of realized Profit / Loss <a name="6001-SORD-036" href="#6001-SORD-036">6001-SORD-036</a>
- **could** see any change in margin requirements (if more or less margin will be required) <a name="6001-SORD-037" href="#6001-SORD-037">6001-SORD-037</a>
- **could** see the notional value of my order <a name="6001-SORD-038" href="#6001-SORD-038">6001-SORD-038</a>

... so that I can adjust my inputs before submitting

## Submit an order

... need to submit my order, when submitting my order, I... 

- **must** submit the [Vega submit order transaction](0013-WTXN-submit_vega_transaction.md). <a name="6001-SORD-039" href="#6001-SORD-039">6001-SORD-039</a>

- **must** see feedback on my order [status](https://docs.vega.xyz/docs/mainnet/grpc/vega/vega.proto#orderstatus) (not just transaction status above) <a name="6001-SORD-040" href="#6001-SORD-040">6001-SORD-040</a>
  - Active (aka Open) <a name="6001-SORD-041" href="#6001-SORD-041">6001-SORD-041</a>
  - Expired <a name="6001-SORD-042" href="#6001-SORD-042">6001-SORD-042</a>
  - Cancelled. Should see the txn that cancelled it and a link to the block explorer, if cancelled by a user transaction. <a name="6001-SORD-043" href="#6001-SORD-043">6001-SORD-043</a>
  - Stopped. **should** see an explanation of why stopped <a name="6001-SORD-044" href="#6001-SORD-044">6001-SORD-044</a>
  - Partially filled. **should** see how much of the [size](7001-DATA-data_display.md#size) if filled/remaining <a name="6001-SORD-045" href="#6001-SORD-045">6001-SORD-045</a>
  - Filled. Must be able to see/link to all trades that were created from this order. <a name="6001-SORD-046" href="#6001-SORD-046">6001-SORD-046</a>
  - Rejected: **must** see the reason it was rejected <a name="6001-SORD-047" href="#6001-SORD-047">6001-SORD-047</a>
  - Parked: **should** see an explanation of why parked orders happen <a name="6001-SORD-048" href="#6001-SORD-048">6001-SORD-048</a>
- All feedback must be a subscription so is updated as the status changes <a name="6001-SORD-053" href="#6001-SORD-053">6001-SORD-053</a>
 - **could** repeat the values that were submitted (order type + all fields) <a name="6001-SORD-049" href="#6001-SORD-049">6001-SORD-049</a>

... so that I am aware of the status of my order before seeing it in the [orders table](6002-MORD-manage_orders.md).

... so I get the sort of order, and price, I wish.

## Manage positions and order
After submitting orders I'll want to **manage orders** (TODO). If my orders resulted in a position I may wish to **manage positions** (TODO).

_____

# Typical order scenarios to design/test for

Market in continuous trading:
- Limit order, Long, GTC, with a price that is lower than the current price
- Limit order, Short, GFN, that crosses the book but only gets a partial fill when order is processed
- Market order, IOC, that increases open volume (aka size of position)
- a limit order GFA when market is in Auction
- an limit that reduces exposure from something to 0
- a limit order, FOK, that squares and reverses e.g. I'm long 10, I short 20 to end short 10

Market in auction:
- Attempt Market order in Auction mode: should warn order is invalid
- Attempt limit order GFN when market is normally Continuos, should warn
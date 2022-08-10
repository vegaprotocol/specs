# Submit order
As a user I want change my exposure on a market (e.g. open a position, increase or decrease my open volume), I want to submit an order with instructions for how my order should be executed so I have some control over the price that I get and if when my order should stay on the book. See various [specs to do with submitting orders](../protocol#orders) for more info.

When populating a deal ticket I...

- **must** see/select the [Market](./7001-DATA-data_display.md#market) I am submitting the order for <a name="yyyy-xxx-001" href="#yyyy-xxx-001">yyyy-xxx-001</a>
  - **must** see the current market status (Continuous, Auction etc) <a name="yyyy-xxx-002" href="#yyyy-xxx-002">yyyy-xxx-002</a>

- If I have a 0 total balance of the settlement asset in any account: **must** see be warned that I have insufficient collateral (but also allow you to populate ticket because I might want to try before I deposit) <a name="yyyy-xxx-003" href="#yyyy-xxx-003">yyyy-xxx-003</a>
  - **should** see a link to deposit the required collateral <a name="yyyy-xxx-050" href="#yyyy-xxx-050">yyyy-xxx-050</a>

- **must** select a side/direction e.g. long/short (note: some implementations may do this with two different submit buttons long/short rather than a toggle) <a name="yyyy-xxx-004" href="#yyyy-xxx-004">yyyy-xxx-004</a>

- **must** be able to select the [order type](../protocol/0014-ORDT-order_types.md) that I wish to submit <a name="yyyy-xxx-005" href="#yyyy-xxx-005">yyyy-xxx-005</a>
  - **must** see limit order <a name="yyyy-xxx-006" href="#yyyy-xxx-006">yyyy-xxx-006</a>
  - **must** see market order <a name="yyyy-xxx-007" href="#yyyy-xxx-007">yyyy-xxx-007</a>
  - **should** see pegged order <!-- <a name="yyyy-xxx-008" href="#yyyy-xxx-008">yyyy-xxx-008</a> -->
  - **should** see liquidity provision <!-- <a name="yyyy-xxx-009" href="#yyyy-xxx-009">yyyy-xxx-009</a> -->

## Order size

...need to select a size, when selecting a size for my order, I...

- **must** input an order [size](7001-DATA-data_display.md#size) (aka amount or contracts) <a name="yyyy-xxx-010" href="#yyyy-xxx-010">yyyy-xxx-010</a>
  - **should** have the previous value pre-populated (last submitted or last changed) <a name="yyyy-xxx-012" href="#yyyy-xxx-012">yyyy-xxx-012</a>
  - **should** be able to hit up/down on the keyboard to increase the size by the market's min-contract size <a name="yyyy-xxx-013" href="#yyyy-xxx-013">yyyy-xxx-013</a>
  - TODO **would** like to be able to use use a leverage slider to determine a size based on how much leverage I wish to use (given general balance, price input/current price) <!-- <a name="yyyy-xxx-015" href="#yyyy-xxx-015">yyyy-xxx-015</a> -->
- **must** be warned (pre-submit) if input has too many decimal places for the market's ["position" decimal places](7001-DATA-data_display.md#size) <a name="yyyy-xxx-016" href="#yyyy-xxx-016">yyyy-xxx-016</a> 

... so I get the size of exposure (open volume that I want)

## Price - Limit order

... if wanting to place a limit on the price that I trade at, I...

- **must** enter a [price](7001-DATA-data_display.md#quote-price) <a name="yyyy-xxx-17" href="#yyyy-xxx-17">yyyy-xxx-017</a> 
- **must** see the price unit (as defined in market) <a name="yyyy-xxx-018" href="#yyyy-xxx-018">yyyy-xxx-018</a>
  - if the input field is empty: with the input focused: **should** be able to hit up/down to populate the input with the current mark price (if there is one) <a name="yyyy-xxx-011" href="#yyyy-xxx-011">yyyy-xxx-011</a>
  - **should** have the previous value pre-populated (last submitted or last changed) <a name="yyyy-xxx-014" href="#yyyy-xxx-014">yyyy-xxx-014</a>
  - **should** be able to hit up/down on the keyboard to increase the price by the market's tick size (if set) or smallest increment <a name="yyyy-xxx-051" href="#yyyy-xxx-051">yyyy-xxx-051</a>

... so that my order only trades at up/down to a particular price

## Market order

... if wanting to trade regardless of price (or in the assumption that the market is liquid enough that the current best prices are enough of an indication of the price I'll get)...

- **must not** see a price input <a name="yyyy-xxx-019" href="#yyyy-xxx-019">yyyy-xxx-019</a>
- **should** be warning if the market is in auction and the market order will not work <a name="yyyy-xxx-052" href="#yyyy-xxx-052">yyyy-xxx-052</a>

... so I cen quickly submit an order without populating the ticket with elements I don't care about

## Pegged

... submit an order where the price is offset from a price in system (best bid etc)

- TODO

... so my order will move with the market

## Time in force

... should to select a time in force, when selecting a time in force, I...

- **must** select a time in force
  - Good till canceled `GTC` - not applicable to Market orders <a name="yyyy-xxx-023" href="#yyyy-xxx-023">yyyy-xxx-023</a>
  - Good till time `GTT` - not applicable to Market orders <a name="yyyy-xxx-024" href="#yyyy-xxx-024">yyyy-xxx-024</a>
  - Fill or kill `FOC` <a name="yyyy-xxx-025" href="#yyyy-xxx-025">yyyy-xxx-025</a>
  - Immediate or cancel `IOC` <a name="yyyy-xxx-026" href="#yyyy-xxx-026">yyyy-xxx-026</a>
  - Good for normal trading only `GFN` - not applicable to Market orders <a name="yyyy-xxx-027" href="#yyyy-xxx-027">yyyy-xxx-027</a>
  - Good for auction only `GFA` - not applicable to Market orders <a name="yyyy-xxx-028" href="#yyyy-xxx-028">yyyy-xxx-028</a>
- **should** only be warned if the time in force is not applicable to the order type I have selected <a name="yyyy-xxx-029" href="#yyyy-xxx-029">yyyy-xxx-029</a>
- if the user has not set a preference: market orders **should** default to `IOC` <a name="yyyy-xxx-030" href="#yyyy-xxx-030">yyyy-xxx-030</a>
- if the user has not set a preference: limit orders **should** default to `GTC` <a name="yyyy-xxx-031" href="#yyyy-xxx-031">yyyy-xxx-031</a>

... so I can control if and how my order stays on the order book

## Auto Populating a deal ticket non-manual methods

- TODO Populate by selecting a size/price in the order book
- TODO Populate by selecting a size/price in the chart
- TODO Populate by selecting a size/price in the depth chart
- TODO Input price as a % of account, given the current price field

## See the potential consequences of an order before it is submit
... based on the current inputs i'd like indication of the consequences of what might happen based on my position and the state of the market, I...

- **could** see my new open volume <a name="yyyy-xxx-032" href="#yyyy-xxx-032">yyyy-xxx-032</a>
- **could** see new volume weighted average entry price <a name="yyyy-xxx-033" href="#yyyy-xxx-033">yyyy-xxx-033</a>
- **could** see a new liquidation level <a name="yyyy-xxx-034" href="#yyyy-xxx-034">yyyy-xxx-034</a>
- **could** see an estimate of the fees that will be paid (if any) <a name="yyyy-xxx-035" href="#yyyy-xxx-035">yyyy-xxx-035</a>
- **could** see my "position leverage" TODO - define this
- **could** see my "account leverage" TODO - define this 
- **could** see an amount of realized Profit / Loss <a name="yyyy-xxx-036" href="#yyyy-xxx-036">yyyy-xxx-036</a>
- **could** see any change in margin requirements (if more or less margin will be required) <a name="yyyy-xxx-037" href="#yyyy-xxx-037">yyyy-xxx-037</a>
- **could** see the notional value of my order <a name="yyyy-xxx-038" href="#yyyy-xxx-038">yyyy-xxx-038</a>

... so that I can adjust my inputs before submitting

## Submit an order

... need to submit my order, when submitting my order, I... 

- **must** submit the [Vega submit order transaction](0013-WTXN-submit_vega_transaction.md) <a name="yyyy-xxx-039" href="#yyyy-xxx-039">yyyy-xxx-039</a>

- **must** see feedback on their order [status](https://docs.vega.xyz/docs/mainnet/grpc/vega/vega.proto#orderstatus) (not just transaction status above) <a name="yyyy-xxx-040" href="#yyyy-xxx-040">yyyy-xxx-040</a>
  - Active (aka Open) <a name="yyyy-xxx-041" href="#yyyy-xxx-041">yyyy-xxx-041</a>
  - Expired <a name="yyyy-xxx-042" href="#yyyy-xxx-042">yyyy-xxx-042</a>
  - Cancelled <a name="yyyy-xxx-043" href="#yyyy-xxx-043">yyyy-xxx-043</a>
  - Stopped. **should** see an explanation of why stopped <a name="yyyy-xxx-044" href="#yyyy-xxx-044">yyyy-xxx-044</a>
  - Partially filled. **should** see how much of the [size](7001-DATA-data_display.md#size) if filled/remaining <a name="yyyy-xxx-045" href="#yyyy-xxx-045">yyyy-xxx-045</a>
  - Filled <a name="yyyy-xxx-046" href="#yyyy-xxx-046">yyyy-xxx-046</a>
  - Rejected: **must** see the reason it was rejected <a name="yyyy-xxx-047" href="#yyyy-xxx-047">yyyy-xxx-047</a>
  - Parked: **should** see an explanation of why parked orders happen <a name="yyyy-xxx-048" href="#yyyy-xxx-048">yyyy-xxx-048</a>
- All feedback must be a subscription so is updated as the status changes <a name="yyyy-xxx-053" href="#yyyy-xxx-053">yyyy-xxx-053</a>
 - **could** repeat the values that were submitted (order type + all fields) <a name="yyyy-xxx-049" href="#yyyy-xxx-049">yyyy-xxx-049</a>

... so that I am aware of the status of my order before seeing it in the [orders table](6002-MORD-manage_orders.md).

... so I get the sort of order, and consistently price, I wish.

## Manage positions and order
After submitting orders I'll want to [manage orders](6002-MORD-manage_orders.md). If my my orders resulted in a position I may wish to [manage positions](6003-POSI-positions.md).

_____

# Typical order scenarios to design/test for

Market in continuous trading:
- Limit order, GTC, with a price that is lower than the current price
- Limit order, GFN, that crosses the book but only gets a partial fill when order is processed
- Market order, IOC, that increases open volume (aka size of position)
- a limit order GFA when market is in Auction
- an limit that reduces exposure from something to 0
- a limit order, FOK, that squares and reverses e.g. I'm long 10, I short 20 to end short 10

Market in auction:
- Attempt Market order in Auction mode: should warn order is invalid
- Attempt limit order GFN when market is normally Continuos, should warn
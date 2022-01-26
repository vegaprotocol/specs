# Auctions

Auctions are a trading mode that 'collect' orders during an *auction call period* which may end at a specified time or be of indefinite length, ending when some condition is met. During the call period, no trades are created. At the conclusion of the call period, trades are produced in a single action known as an auction *uncrossing*. Auctions always try to maximise the traded volume (subject to the requirements of the orders placed) during the uncrossing. The price at which uncrossing occurs, and therefore the price assigned to the trades created during it can be determined via a number of algorithms. This spec described auction types, configuration and mechanics on Vega.


# Guide-level explanation

In comparison to continuous trading, the auction mode for a market, is a state of the orderbook where each order placed is just sitting on the book, for a given period of time or until some requirements are met (called `call period`), then the matching orders are uncrossed.

They are mostly useful in less liquid markets, or in specific scenarios where a price must be determined, i.e. at opening of a market, when a potentially excessively large price move might occur (price monitoring) or when liquidity needs to be sourced and aggregated (liquidity monitoring). In traditional markets (where markets open and close every day) we can run an open and closing auction for the price to stabilise at both ends.


# Reference-level explanation

As mentioned earlier, this specification introduces new trading modes. 

1. General auctions
1. Opening auctions: purpose is to calibrate a market / help with price discovery when a new market is started.
1. Frequent batch auctions: a trading mode that may be set as the default / normal mode that has trading occur only through repeated auctions (as opposed to continuous trading)

## Auction config

All auctions have a `min_auction_length` (which is a single network parameter for all auctions), which defines the minimum `call period` for an auction.

* Any auction that would be less than `min_auction_length` seconds (network parameter) should not be started (e.g. if the market is nearing the end of its open period / active trading). This is to prevent auction calls that are too short given the network latency/granularity, so should be some multiple of the worst case expected block time at some confidence level, which is best maintained by governance voting (hence being a network parameter).
* a proposal should be rejected if it would require an auction shorter `min_auction_length`
* for price/liquidity monitoring, etc. the auction must last for at least the `min_auction_length` and therefore we can avoid checking other conditions until that length is reached
* if the parameter is changed it needs to be re-applied to any current auctions, this means that shortening it could trigger an auction ending


## Opening auctions (at creation of the market)

A market that has passed the governance vote and is in Pending state will be in an auction period. The auction will never uncross while the market is in a Pending state, and only does so when it moves to another state (i.e. becomes Active, see [Market Lifecycle](./0043-MKTL-market_lifecycle.md) for criteria for transition out of Pending state).

A market cannot be in multiple trading modes at the same time so if it is in an opening auction that will be the trading mode.

The enactment period of the governance proposal refers to the time between the proposal being accepted and active trading commencing, therefore inclusive of the Pending state of the market (see [market lifecycle spec](./0043-MKTL-market_lifecycle.md)). A governance network parameter will set the minimum allowable enactment period for new market proposals.


## Frequent batch auction

The frequent batch auction mode is a trading mode in perpetual auction, meaning that all uncrossing on the book is done at the end of auction period, then once this is done, and trades happen, a new auction period is started, and this continues forever until the market close.

e.g: auctions could be set to last 10 minutes, then every 10 minutes the book would uncross, potentially generating trades.

Note that FBAs will still have an opening auction (which must have a duration equal to or greater than the minimum batch auction duration, as well as meeting the minimum opening auction duration. Price and liquidity monitoring will be able to override the trading mode and push the market into longer auctions to resolve the triggering event.

### Duration of frequent batch auctions

As part of the market framework, we need to be able to specify the duration of auctions period. This should be added as a new network setting to the trading modes, and can be changed through governance.
We can also imagine that an auction period could come to an end once a give number of orders have been placed on the system.


## Volume maximising prices

Once the auction period finishes, vega needs to figure out the best price for the order range in the book which can be uncrossed. The first stage in this is to calculate the Volume Maximising Price Range - the range of prices (which will be a contiguous range in an unconstrained order book) at which the highest total quantity of trades can occur.

Initially we will use the mid price within this range. For example, if the volume maximising range is 98-102, we would price all trades in the uncrossing at 100 ((minimum price of range+maximum price of range)/2). In future there will be other options, which will be selectable via a network parameter specified at market creation, and changeable through governance. These other options are not yet specified.


## APIs related to auctions

### New APIs

These new APIs need to expose data, some of which will be re-calculated each time the state of the book changes and will expose information about the market in auction mode:
- how long the market has been in auction mode
- when does the next auction period start
- how long is a period
- the indicative uncrossing price
- indicative uncrossing volume

The Indicative Uncrossing Price is the price at which all trades would occur if we uncrossed the order book now. This will need to be streamed like a normal price, but API users will need a way to know it's an *indicative* uncrossing price and **not** a last traded or mid price. This will likely be a new field.

### Existing APIs

Unlike in traditional centralised trading venues, we will continue to calculate and emit Market Depth events which will contain the shape of the entire book, as it normally does during [continuous trading](./0001-MKTF-market_framework.md#trading-mode---continuous-trading). This is because the orders are already public, and calculating the Market Depth based on already-available orders would be trivial.


## Restriction on orders in auction mode

Market orders are not permitted while a market is in auction mode.

Pegged orders are accepted but are immediately parked and do not enter the live order book.

Good for normal trading (GFN) orders are rejected during an auction.


### Upon entering auction mode

- Pegged orders get parked (see pegged orders spec for details).
- Limit orders stay on the book (unless they have a TIF:GFN only good for normal trading, in this case they get cancelled).
- Cannot accept non-persistent orders (Fill Or Kill and Immediate Or Cancel)
- Any auction that would be less than (network parameter) `min_auction_length` seconds should not be started.


### Upon exiting auction mode

- Pegged orders (all kinds, including MM ones) get reinstated in the order book they were originally submitted in.
- Limit orders stay on the book (unless they have a TIF:GFA only good for auction, in this case they are cancelled).


## Exiting the auction mode

Auction periods may be ended with an uncrossing and the creation of any resulting trades due to:

- the auction call period end time being reached (if such a time is set); or 
- other functionality (related to the type of auction period) that triggers the end of auction.

Auction periods do not end if the resulting state would immediately cause another auction to occur. Instead the current auction gets extended. For example, if a liquidity monitoring auction would be triggered at the end of an opening auction, then the opening auction continues and the _auction extension trigger_ field in the [market data API](./0021-MDAT-market_data_spec.md) is updated to account for the fact that the opening auction has been extended due to insufficent liquidity.

### Ending when a market is going to enter Trading Terminated status

If the auction period specifies an end time and the market is about to transition to the "Trading Terminated" status before the auction end time or conditions are reached, then the auction must uncross immediately before the transition occurs, and the market would not in this case transition back to its normal trading mode.


### Ending an auction due to functional triggers

Functionality that either triggers the end of an auction or delays the auction ending until conditions are met, even if the end time is otherwise met is defined in the relevant specs that detail the various period types that use auctions, and how their entry/exit is triggered:

- opening auction (market creation): [governance](./0028-GOVE-governance.md)
- [price monitoring](./0032-PRIM-price_monitoring.md)
- [liquidity monitoring](./0035-LIQM-liquidity_monitoring.md)


## First/Naive implementation

As a first version we expect:

- A market in continuous trading mode, to be configured so it can start with an auction for a given period of time, then switch to continuous trading for the rest of the life of the market.
- A market to be configured to run in frequent batch auction mode, which could not be changed to a continuous trading later on.


# Network Parameters

`min_auction_length`: any auction that would be less than `min_auction_length` seconds (network parameter) should not be started.

# Pseudo-code / Examples

Possible changes for the TradingMode configuration.
```
enum PricingAlgorithm {
	VolumeAveragePrice = 1,
	// etc ...
}

message AuctionConfig {
	int64 callPeriodDuration = 1;
	PricingAlgorithm algo = 2;
}

message ContinuousTrading {
  bool hasOpeningAuction = 1;
  AuctionConfig config = 2;
}

message FrequentBatchAuction {
	AuctionConfig config = 1;
}

message Market {
  // common market fields
  oneof tradingMode {
    ContinuousTrading continuous = 100;
    FrequentBatchAuction auctions = 101;
  }
}
```
# Acceptance Criteria
- [] As a user, I can configure a market through the market configuration to use auction mode
  - [] I can define an opening auction for a continuous trading market, and the duration of the call period. (<a name="0026-AUCT-001" href="#0026-AUCT-001">0026-AUCT-001</a>)
  - [] The duration of the auction period at market creation cannot be below the minimum auction period defined within the network (<a name="0026-AUCT-002" href="#0026-AUCT-002">0026-AUCT-002</a>)
  - [] I can define a market to operate as Frequent Batch Auction, and the duration of the call period. (<a name="0026-AUCT-003" href="#0026-AUCT-003">0026-AUCT-003</a>)
  - [] I can choose what algorithm is used to decided the pricing at the end of the auction period. (<a name="0026-AUCT-004" href="#0026-AUCT-004">0026-AUCT-004</a>)
- [] As the Vega network, in auction mode, all orders are placed in the book but never uncross until the end of the auction period. (<a name="0026-AUCT-005" href="#0026-AUCT-005">0026-AUCT-005</a>)
- [] As a user, I can place an order when the market is in auction mode, but it will not trade immediately. (<a name="0026-AUCT-006" href="#0026-AUCT-006">0026-AUCT-006</a>)
- [] As a user, I can cancel an order that it either live on the order book or parked. (<a name="0026-AUCT-007" href="#0026-AUCT-007">0026-AUCT-007</a>)
- [] As a user, I can amend orders that are on the order book. Specifics can be found in the [amends](./0004-AMND-amends.md) spec 
- [] As a user, I cannot place a Market order, or and order using FOK or IOC time in force. (<a name="0026-AUCT-008" href="#0026-AUCT-008">0026-AUCT-008</a>)
- [] As a user, I can get information about the trading mode of the market (through the [market framework](./0001-MKTF-market_framework.md))
- [] As a user, I can get real time information through the API about a market in auction mode: indicative crossing price, indicative crossing volume.  (<a name="0026-AUCT-009" href="#0026-AUCT-009">0026-AUCT-009</a>)
- [] As a user, the market depth API provides the same data that would be sent during continuous trading (<a name="0026-AUCT-010" href="#0026-AUCT-010">0026-AUCT-010</a>)
- [] As an API user, I can identify: (<a name="0026-AUCT-011" href="#0026-AUCT-011">0026-AUCT-011</a>)
  - If a market is temporarily in an auction period
  - Why it is in that period (e.g. Auction at open, liquidity sourcing)
  - What price mode that auction will use when the auction is over
  - When the auction mode ends

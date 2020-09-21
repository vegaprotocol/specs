Feature name: auctions\
Start date: 2019-12-13\
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Summary

As of right now, vega implements continuous trading, in fact every time an order is placed, vega evaluates it with the other side of the book and if the order crosses, a trade will result from it. This specification will introduce new trading modes for vega as auctions.

# Guide-level explanation

In comparison to continuous trading, the auction mode for a market, is a state of the orderbook where each order placed are just sitting on the book, for a given period of time or until some requirements are met (called `call period`), then the matching orders are uncrossed.

They are mostly useful in less liquid markets, or in specific scenarios where a price must be determined, i.e. at opening of a market, when a potentially excessively large price move might occur (price monitoring) or when liquidity needs to be sourced and aggregated (liquidity monitoring). In traditional markets (where markets open and close every day) we can run an open and closing auction for the price to stabilise at both ends.

# Reference-level explanation

As mentioned earlier, this specification introduces new trading modes. A first one which purpose is to calibrate a market / help with price discovery when a new market is started. A second one meant to be trading only through auction called `Frequent batch auction`.

## Auction period at market creation

This trading mode is very similar to the Continuous trading mode for a market. In this configuration, a market will start in auction mode, then once the auction comes to an end the market will switch back to the continuous trading mode, and will stay like until there's a need for it to go in auction mode again (e.g: based on the price changes).
A market cannot be in both mode at the same time and will trade ever in a auction or continuous trading. There will be the normal trading mode, configured in the market framework, and a period mode which temporarily overrides it. For example a market may be configured to be a Frequent Batch Auction market, but be in an Auction Period triggered by liquidity monitoring.

In the first implementation, auction periods will be used at opening only as price monitoring will not exist.

There will be a network parameter that sets the minimum allowable duation of the auction period at market creation. New market proposals must specify a period of at least this duration.

## Frequent batch auction

The frequent batch auction mode is a trading mode in perpetual auction, meaning that all uncrossing on the book is done at the end of auction period, then once this is done, and trades happen, a new auction period is started, and this forever until the market close.

e.g: auctions could be set to last 10 minutes, then every 10 minutes the book would be uncrossing, and generating trades.

Note that FBAs will still have an opening auction (which must have a duration equal to or greater than the minimum batch auction duration, as well as meeting the minimum opening auction duration. Price and liquidity monitoring will be able to override the trading mode and push the market into longer auctions to resolve the triggering event.

## Duration of frequent batch auctions

As part of the market framework, we need to be able to specify the duration of auctions period. This should be added as a new network setting to the trading modes, and can be changed through governance.
We can also imagine that an auction period could come to an end once a give number of orders have been placed on the system.

### Volume maximising prices

Once the auction period finishs, vega needs to figure out the best price for the order range in the book which can be uncrossed. The first stage in this is to calculate the Volume Maximising Price Range - the range of prices (which will be a contiguous range in an unconstrained order book) at which the highest total quantity of trades can occur.

Initially we will use the mid price within this range. For example, if the volume maximising range is 98-102, we would price all trades in the uncrossing at 100. In future there will be other options, which will be selectable via a network parameter specified at market creation, and changeable through governance. These other options are not yet specified.

## New core APIs related to auctions

These new APIs need to expose data, some of which will be re-calculated each time the state of the book changes and will expose information about the market in auction mode:
- how long the market has been in auction mode
- when does the next auction period start
- how long is a period
- the indicative uncrossing price
- indicative uncrossing volume

The Indicative Uncrossing Price is the price at which all trades would occur if we uncrossed the auction now. This will need to be streamed like a normal price, but API users will need a way to know it's an *indicative* uncrossing price and **not** a last traded or mid price. This will likely be a new field.

## Restriction on orders in auction mode

Market orders are not permitted while a market is in auction mode.

Additional Time in Force order options need to be added: only good for normal trading and only good for auction.

### Upon entering auction mode

- Pegged orders get parked (see pegged orders spec for details).
- Limit orders stay on the book (unless they have a TIF: only good for normal trading, in this case they get cancelled).
- Cannot accept non-persistent orders (Fill Or Kill and Immediate Or Cancel)

### Upon exiting auction mode

- Pegged orders (all kinds, inclucing MM ones) get reinstated in the order they were originally submitted in.
- Limit orders stay on the book (unless they have a TIF: only good for auction).

## Exiting the auction mode

Please note auction should only ever be exitted if doing so wouldn't trigger entry triggers of any other auction types defined for the market (e.g. price monitoring auction, liquidity monitoring auction). Otherwise the auction gets extended by the period prescribed by the appropriate trigger(s).

## Market end

Auction mode must be exited at or before market end time. Furthermore, `min_auction_length` parameter should be added and used to determine if the auction can be started close to market market end time. If time left to market end is less than `min_auction_length` the auction should not be entered.

## First/Naive implementation

As a first version we expect:

- A market in continuous trading mode, to be configured so it can start with an auction for a given period of time, then switch to continuous trading for the rest of the life of the market.
- A market to be configured to run in frequent batch auction mode, which could not be changed to a continuous trading later on.

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
  - [] I can define an opening auction for a continuous trading market, and the duration of the call period.
  - [] The duration of the auction period at market creation cannot be below the minimum auction period defined within the network
  - [] I can define a market to operate as Frequent Batch Auction, and the duration of the call period.
  - [] I can choose what algorithm is used to decided the pricing at the end of the auction period.
- [] As the Vega network, in auction mode, all orders are placed in the book but never uncross until the end of the auction period.
- [] As a user, I can place an order when the market is in auction mode, but it will not trade immediately.
- [] As a user, I cannot place a Market order, or and order using FOK or IOC time in force.
- [] As a user, I can get information about the trading mode of the market (through the market framework)
- [] As a user, I can get real time information throught the API about a market in auction mode: indicative crossing price, indicative crossing volume.
- [] As an API user, I can identify:
  - If a market is temporarily in an auction period
  - Why it is in that period (e.g. Auction at open, liquididty sourcing)
  - What price mode that auction will use when the auction is over
  - When the auction mode ends
